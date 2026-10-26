import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { sql } from 'kysely';
import type { Ctx } from '../../context.js';
import { currentUser, parse } from '../../shared/http.js';
import { AppError, E } from '../../shared/errors.js';
import { sortPeople } from '../../shared/sort.js';
import { activeMembership, roleIn } from '../groups/service.js';
import { sessionCols, toSummary } from './summary.js';
import { decodeCursor, encodeCursor } from '../../shared/cursor.js';
import { iso } from '../../shared/time.js';

const SessionId = z.object({ session_id: z.string().uuid() });

async function loadSession(ctx: Ctx, sessionId: string) {
  const s = await ctx.db.selectFrom('sessions').innerJoin('groups', 'groups.id', 'sessions.group_id')
    .select([...sessionCols, 'groups.name as group_name', 'groups.owner_id', 'sessions.forfeit_trigger_user_id', 'sessions.forfeited_at', 'sessions.cancelled_at'])
    .where('sessions.id', '=', sessionId).executeTakeFirst();
  if (!s) throw E.notFound('Không tìm thấy phiên');
  return s;
}

/** MySessionResult của chính người gọi (BR-41) — dùng cho /result và lịch sử. */
export async function myResult(ctx: Ctx, userId: string, sessionId: string) {
  const s = await loadSession(ctx, sessionId);
  if (s.owner_id === userId) throw new AppError(403, 'OWNER_CANNOT_JOIN_SESSION', 'Chủ nhóm xem chi tiết phiên ở owner-detail', 'BR-114');
  const sm = await ctx.db.selectFrom('session_members').selectAll().where('session_id', '=', sessionId).where('user_id', '=', userId).executeTakeFirst();
  if (!sm) throw E.forbiddenGroup();
  if (s.status !== 'COMPLETED' && s.status !== 'CANCELLED') throw new AppError(409, 'SESSION_NOT_FINISHED', 'Phiên chưa chốt', 'BR-23');
  const people = await ctx.db.selectFrom('session_members').innerJoin('users', 'users.id', 'session_members.user_id')
    .select(['users.id as user_id', 'users.display_name', 'session_members.state', 'session_members.joined_at'])
    .where('session_members.session_id', '=', sessionId).execute();
  const trig = s.forfeit_trigger_user_id ? people.find((p) => p.user_id === s.forfeit_trigger_user_id) : null;
  const logs = await ctx.db.selectFrom('achievement_log').select(['kind', 'ref_badge_id'])
    .where('user_id', '=', userId).where('ref_session_id', '=', sessionId).execute();
  const broke = logs.some((l) => l.kind === 'STREAK_BREAK') && !logs.some((l) => l.kind === 'STREAK_RESTORE');
  const u = await ctx.db.selectFrom('users').select('current_streak').where('id', '=', userId).executeTakeFirstOrThrow();
  const base = s.duration_min === 25 ? ctx.cfg.engine.coins25 : ctx.cfg.engine.coins50;
  const appeal = await ctx.db.selectFrom('appeals').select('id').where('session_id', '=', sessionId).where('user_id', '=', userId).executeTakeFirst();
  const explanation = await ctx.db.selectFrom('explanations').select('id')
    .where('session_id', '=', sessionId).where('user_id', '=', userId).executeTakeFirst();
  const now = Date.now();
  const exited = sm.state === 'EXITED';
  return {
    session_id: sessionId,
    // This endpoint currently contains group sessions only, regardless of attendance.
    session_mode: 'SQUAD',
    group_name: s.group_name,
    started_at: s.started_at.toISOString(),
    joined_at: iso(sm.joined_at),
    exited_at: iso(sm.exited_at),
    ended_at: iso(sm.ended_at),
    duration_min: s.duration_min,
    final_state: sm.state,
    focus_seconds: sm.focus_seconds,
    late_join: sm.late_join,
    forfeited: s.forfeited,
    forfeit_trigger_display_name: trig?.display_name ?? null,
    cancelled_outage_exited: s.status === 'CANCELLED' && s.cancel_reason === 'SERVER_OUTAGE' && exited,
    coins_awarded: sm.coins_awarded,
    reward_cap_reached: s.status === 'COMPLETED' && (sm.state === 'COMPLETED' || sm.exempted) && !s.forfeited && sm.coins_awarded < base,
    reward_daily_cap: ctx.cfg.engine.coinsDailyCap,
    explanation_submit_deadline: new Date(s.ends_at.getTime() + ctx.cfg.explanationSubmitDays * 86400e3).toISOString(),
    has_explanation: !!explanation,
    streak_after: u.current_streak,
    streak_broken: broke,
    new_badges: logs.filter((l) => l.kind === 'BADGE_AWARD' && l.ref_badge_id).map((l) => l.ref_badge_id!),
    exempted: sm.exempted,
    // BR-85: gửi đến ends_at + explanation_submit_days
    can_explain: exited && now < s.ends_at.getTime() + ctx.cfg.explanationSubmitDays * 86400e3,
    // BR-86: phiên đã chốt, chưa khiếu nại, trong ends_at + appeal_window_h
    can_appeal: exited && !sm.exempted && !appeal && s.status === 'COMPLETED' && now < s.ends_at.getTime() + ctx.cfg.appealWindowH * 3600e3,
    participants: sortPeople(people).map((p) => ({ display_name: p.display_name, final_state: p.state })),
  };
}

export function sessionRoutes(app: FastifyInstance, ctx: Ctx) {
  app.get('/v1/sessions/:session_id', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { session_id } = parse(SessionId, req.params);
    const s = await loadSession(ctx, session_id);
    const { role } = await roleIn(ctx, me.id, s.group_id);
    if (!role) {
      const sm = await ctx.db.selectFrom('session_members').select('state').where('session_id', '=', session_id).where('user_id', '=', me.id).executeTakeFirst();
      if (!sm) throw E.forbiddenGroup();
    }
    return toSummary(ctx, s);
  });

  app.get('/v1/me/sessions/upcoming', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const m = await activeMembership(ctx, me.id); // BR-114: chỉ nhóm tôi là thành viên
    if (!m) return null;
    const s = await ctx.db.selectFrom('sessions').innerJoin('groups', 'groups.id', 'sessions.group_id')
      .select([...sessionCols, 'groups.name as group_name'])
      .where('sessions.group_id', '=', m.group_id).where('sessions.status', 'in', ['SCHEDULED', 'COUNTDOWN', 'ACTIVE'])
      .where('sessions.ends_at', '>', new Date()).orderBy('sessions.started_at', 'asc').limit(1).executeTakeFirst();
    return s ? toSummary(ctx, s) : null;
  });
  // Kết quả của CHÍNH người gọi — có Coins/chuỗi (BR-41, MySessionResult)
  app.get('/v1/sessions/:session_id/result', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { session_id } = parse(SessionId, req.params);
    return myResult(ctx, me.id, session_id);
  });

  // Lịch sử phiên của tôi (US-03.14, Should) — mới nhất trước, chỉ phiên đã chốt mà tôi có trạng thái
  app.get('/v1/me/sessions', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const q = parse(z.object({
      cursor: z.string().optional(),
      limit: z.coerce.number().int().min(1).max(100).default(20),
      from: z.string().datetime({ offset: true }).optional(),
      to: z.string().datetime({ offset: true }).optional(),
    }).refine((value) => !value.from || !value.to || Date.parse(value.from) < Date.parse(value.to), {
      message: 'from must be earlier than to', path: ['to'],
    }), req.query);
    let qb = ctx.db.selectFrom('session_members').innerJoin('sessions', 'sessions.id', 'session_members.session_id')
      .select(['sessions.id', 'sessions.started_at'])
      .where('session_members.user_id', '=', me.id).where('sessions.status', 'in', ['COMPLETED', 'CANCELLED']);
    if (q.from) qb = qb.where('sessions.started_at', '>=', new Date(q.from));
    if (q.to) qb = qb.where('sessions.started_at', '<', new Date(q.to));
    const c = decodeCursor(q.cursor);
    if (c) qb = qb.where((eb) => eb.or([eb('sessions.started_at', '<', c.t), eb.and([eb('sessions.started_at', '=', c.t), eb('sessions.id', '<', c.id)])]));
    const rows = await qb.orderBy('sessions.started_at', 'desc').orderBy('sessions.id', 'desc').limit(q.limit + 1).execute();
    const page = rows.slice(0, q.limit);
    const items = [];
    for (const r of page) items.push(await myResult(ctx, me.id, r.id));
    return { next_cursor: rows.length > q.limit ? encodeCursor(page[page.length - 1].started_at, page[page.length - 1].id) : null, items };
  });

  // Chi tiết một mục lịch sử (ngoài openapi — bí danh của /sessions/{id}/result)
  app.get('/v1/me/sessions/:session_id', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { session_id } = parse(SessionId, req.params);
    return myResult(ctx, me.id, session_id);
  });

  // Chi tiết phiên cho chủ nhóm (V-46) — KHÔNG Coins/chuỗi, chỉ dữ liệu đã chốt (BR-53, BR-116)
  app.get('/v1/sessions/:session_id/owner-detail', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { session_id } = parse(SessionId, req.params);
    const s = await loadSession(ctx, session_id);
    const { role } = await roleIn(ctx, me.id, s.group_id);
    if (role === 'MEMBER') throw E.notOwner();
    if (role !== 'OWNER') throw E.forbiddenGroup();
    const finished = s.status === 'COMPLETED' || s.status === 'CANCELLED';
    // Đọc qua view owner_session_member_view (không có cột Coins/chuỗi)
    const rows = finished
      ? (await sql<{ user_id: string; display_name: string; state: string; late_join: boolean; pause_count: number; exited_at: Date | null; joined_at: Date | null; exempted: boolean }>`
          SELECT v.user_id, v.display_name, v.state::text AS state, v.late_join, v.pause_count, v.exited_at, sm.joined_at, sm.exempted
          FROM owner_session_member_view v JOIN session_members sm ON sm.session_id = v.session_id AND sm.user_id = v.user_id
          WHERE v.session_id = ${session_id} AND v.group_id = ${s.group_id}`.execute(ctx.db)).rows
      : [];
    const expl = await ctx.db.selectFrom('explanations').select('user_id').where('session_id', '=', session_id).execute();
    const appeals = await ctx.db.selectFrom('appeals').select(['user_id', 'status']).where('session_id', '=', session_id).execute();
    const exits = await ctx.db.selectFrom('session_members').innerJoin('users', 'users.id', 'session_members.user_id')
      .select(['users.display_name', 'session_members.exited_at'])
      .where('session_members.session_id', '=', session_id).where('session_members.state', '=', 'EXITED')
      .orderBy('session_members.exited_at', 'asc').execute();
    const trig = s.forfeit_trigger_user_id
      ? await ctx.db.selectFrom('users').select('display_name').where('id', '=', s.forfeit_trigger_user_id).executeTakeFirst()
      : null;
    // P12: chủ nhóm xem dữ liệu thành viên → access_logs (BR-73)
    if (rows.length)
      await ctx.db.insertInto('access_logs').values(rows.map((r) => ({
        viewer_id: me.id, viewer_role: 'OWNER' as const, subject_user_id: r.user_id, object_type: 'SESSION', object_id: session_id, group_id: s.group_id, purpose: null,
      }))).execute();
    return {
      session_id,
      status: s.status,
      started_at: s.started_at.toISOString(),
      ends_at: s.ends_at.toISOString(),
      forfeited: s.forfeited,
      forfeit_trigger_display_name: trig?.display_name ?? null,
      cancel_reason: s.cancel_reason,
      cancelled_at: s.cancelled_at ? s.cancelled_at.toISOString() : null, // AC-08.10.10 "Phiên đã hủy lúc hh:mm"
      fetched_at: new Date().toISOString(),
      members: sortPeople(rows).map((r) => ({
        user_id: r.user_id,
        display_name: r.display_name,
        final_state: r.state,
        late_join: r.late_join,
        pause_count: r.pause_count,
        pause_reasons: [],
        exited_at: r.exited_at ? r.exited_at.toISOString() : null,
        has_explanation: expl.some((x) => x.user_id === r.user_id),
        appeal_status: appeals.find((a) => a.user_id === r.user_id)?.status ?? null,
        exempted: r.exempted, // AC-08.10.11 nhãn "Đã miễn trừ"
      })),
      exit_events: exits.map((x) => ({ display_name: x.display_name, server_ts: x.exited_at!.toISOString() })),
    };
  });
}
