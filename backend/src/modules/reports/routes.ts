import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { currentUser, parse } from '../../shared/http.js';
import { AppError, E } from '../../shared/errors.js';
import { vnDay } from '../../shared/time.js';

import { MonthStr } from '../achievements/routes.js';
import { periodRange, prevMonth, rowView, runMonthlyReportJob, sortRows } from './service.js';

const GroupId = z.object({ group_id: z.string().uuid() });
const GroupMonth = GroupId.extend({ month: MonthStr });

async function loadReport(ctx: Ctx, groupId: string, month: string) {
  const r = await ctx.db.selectFrom('monthly_reports').selectAll()
    .where('group_id', '=', groupId).where('period', '=', periodRange(month).period).where('expires_at', '>', new Date()).executeTakeFirst();
  if (!r) throw E.notFound('Không có báo cáo kỳ này');
  if (r.status !== 'GENERATED') throw new AppError(404, 'REPORT_NOT_READY', 'Báo cáo đang được tạo', 'BR-101');
  return r;
}

type ExplItem = { session_id: string; exited_at: string; body: string; added_after_report: boolean; edited_at: string | null };

/**
 * Vai trò khi xem báo cáo (BR-103): như roleIn nhưng nhóm ĐÃ GIẢI TÁN vẫn mở cho người từng là chủ nhóm (BR-62, AC-08.01.8)
 * và thành viên cũ (chỉ dòng của mình). Không ném 404 cho nhóm giải tán.
 */
async function reportRole(ctx: Ctx, userId: string, groupId: string) {
  const g = await ctx.db.selectFrom('groups').selectAll().where('id', '=', groupId).executeTakeFirst();
  if (!g) throw E.notFound('Không tìm thấy nhóm');
  if (g.owner_id === userId) return { g, role: 'OWNER' as const };
  if (g.status === 'DISSOLVED') return { g, role: null };
  const m = await ctx.db.selectFrom('group_members').select('id')
    .where('group_id', '=', groupId).where('user_id', '=', userId).where('left_at', 'is', null).executeTakeFirst();
  return { g, role: m ? ('MEMBER' as const) : null };
}

/** Giải trình EXITED của người đó trong nhóm/kỳ (BR-61; giải trình thêm sau vẫn hiện trong app — BR-102). */
async function explanationsOf(ctx: Ctx, groupId: string, month: string, userIds: string[]) {
  if (!userIds.length) return new Map<string, ExplItem[]>();
  const { start, end } = periodRange(month);
  const rows = await ctx.db.selectFrom('explanations').innerJoin('sessions', 'sessions.id', 'explanations.session_id')
    .innerJoin('session_members as sm', (j) => j.onRef('sm.session_id', '=', 'explanations.session_id').onRef('sm.user_id', '=', 'explanations.user_id'))
    .select(['explanations.user_id', 'explanations.session_id', 'explanations.body', 'explanations.added_after_report', 'explanations.edited_at', 'sm.exited_at'])
    .where('sessions.group_id', '=', groupId).where('sessions.started_at', '>=', start).where('sessions.started_at', '<', end)
    .where('explanations.user_id', 'in', userIds).orderBy('sm.exited_at').execute();
  const m = new Map<string, ExplItem[]>();
  for (const r of rows)
    m.set(r.user_id, [...(m.get(r.user_id) ?? []), {
      session_id: r.session_id, exited_at: r.exited_at!.toISOString(), body: r.body,
      added_after_report: r.added_after_report, // BR-102: nhãn "thêm sau khi tạo báo cáo"
      edited_at: r.edited_at ? r.edited_at.toISOString() : null,
    }]);
  return m;
}

export function reportRoutes(app: FastifyInstance, ctx: Ctx) {
  // Danh sách kỳ: chủ nhóm mọi kỳ còn hạn; thành viên (kể cả đã rời) chỉ kỳ có dòng của mình (BR-103)
  app.get('/v1/groups/:group_id/reports', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id } = parse(GroupId, req.params);
    const { role } = await reportRole(ctx, me.id, group_id);
    let qb = ctx.db.selectFrom('monthly_reports').select(['monthly_reports.period', 'monthly_reports.status', 'monthly_reports.generated_at'])
      .where('monthly_reports.group_id', '=', group_id).where('monthly_reports.expires_at', '>', new Date());
    if (role !== 'OWNER') {
      qb = qb.innerJoin('monthly_report_rows as r', 'r.report_id', 'monthly_reports.id').where('r.user_id', '=', me.id);
      const any = await qb.select('monthly_reports.id').limit(1).execute();
      if (!any.length && !role) throw E.forbiddenGroup();
    }
    const rows = await qb.orderBy('monthly_reports.period', 'desc').execute();
    return { items: rows.map((r) => ({ month: r.period.slice(0, 7), status: r.status, generated_at: r.generated_at?.toISOString() ?? null })) };
  });

  app.get('/v1/groups/:group_id/reports/:month', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id, month } = parse(GroupMonth, req.params);
    const { g, role } = await reportRole(ctx, me.id, group_id);
    const rep = await loadReport(ctx, group_id, month);
    const rows = await ctx.db.selectFrom('monthly_report_rows').selectAll().where('report_id', '=', rep.id).execute();
    const base = { group_id, month, report_purpose: g.report_purpose, generated_at: rep.generated_at!.toISOString() };
    const totals = (() => {
      const s = { ...(rep.group_summary ?? {}) } as Record<string, unknown>;
      return s;
    })();
    if (role === 'OWNER') {
      const ex = await explanationsOf(ctx, group_id, month, rows.map((r) => r.user_id).filter((x): x is string => !!x));
      // P12/BR-73: chủ nhóm mở báo cáo → access_logs cho từng thành viên có dòng
      const subjects = rows.filter((r) => r.user_id);
      if (subjects.length)
        await ctx.db.insertInto('access_logs').values(subjects.map((r) => ({
          viewer_id: me.id, viewer_role: 'OWNER' as const, subject_user_id: r.user_id!, object_type: 'REPORT', object_id: rep.id, group_id, purpose: null,
        }))).execute();
      const sorted = sortRows(rows.map((r) => ({
        ...r, display_name: r.display_name_snapshot ?? '', joined_at: String((r.metrics as Record<string, unknown>).joined_at ?? ''), user_id: r.user_id ?? '',
      })));
      return { view: 'OWNER', ...base, rows: sorted.map((r) => rowView(r, ex.get(r.user_id) ?? [])), group_totals: totals };
    }
    const mine = rows.find((r) => r.user_id === me.id);
    if (!mine) throw role ? E.notFound('Bạn không có dòng trong báo cáo kỳ này') : E.forbiddenGroup();
    const ex = await explanationsOf(ctx, group_id, month, [me.id]);
    return { view: 'MEMBER', ...base, my_row: rowView(mine, ex.get(me.id) ?? []), group_totals: rep.group_visible ? totals : null };
  });

  // V-49: chi tiết dòng một thành viên (chủ nhóm)
  app.get('/v1/groups/:group_id/reports/:month/members/:user_id', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id, month, user_id } = parse(GroupMonth.extend({ user_id: z.string().uuid() }), req.params);
    const { role } = await reportRole(ctx, me.id, group_id);
    if (role === 'MEMBER') throw E.notOwner();
    if (role !== 'OWNER') throw E.forbiddenGroup();
    const rep = await loadReport(ctx, group_id, month);
    const row = await ctx.db.selectFrom('monthly_report_rows').selectAll().where('report_id', '=', rep.id).where('user_id', '=', user_id).executeTakeFirst();
    if (!row) throw E.notFound('Không có dòng của người này');
    await ctx.db.insertInto('access_logs').values({ viewer_id: me.id, viewer_role: 'OWNER', subject_user_id: user_id, object_type: 'REPORT', object_id: rep.id, group_id, purpose: null }).execute();
    const ex = await explanationsOf(ctx, group_id, month, [user_id]);
    return rowView(row, ex.get(user_id) ?? []);
  });

  // Chạy tay job báo cáo (chỉ NODE_ENV=development) — mặc định kỳ trước
  if (ctx.cfg.devAuth) {
    app.post('/dev/jobs/monthly-report', async (req) => {
      const body = parse(z.object({ month: MonthStr.optional(), group_id: z.string().uuid().optional() }), req.body ?? {});
      const month = body.month ?? prevMonth(vnDay(new Date()).slice(0, 7));
      return runMonthlyReportJob(ctx, month, body.group_id ? [body.group_id] : undefined);
    });
  }
}
