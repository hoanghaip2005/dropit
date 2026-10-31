import { blockedIds, isBlocked } from '../moderation/service.js';
import { sessionReward } from '../../shared/session-policy.js';
// Giải trình (BR-85) & khiếu nại (BR-86…BR-88, máy trạng thái T-BA-37).
import { sql, type Transaction } from 'kysely';
import type { Ctx } from '../../context.js';
import type { AppealStatus, Database } from '../../shared/db.js';
import { AppError, E } from '../../shared/errors.js';
import { roleIn } from '../groups/service.js';
import { awardBadges, restoreStreak } from '../achievements/service.js';
import { iso } from '../../shared/time.js';

const vnPeriod = (day: string) => `${day.slice(0, 7)}-01`;

async function sessionOf(ctx: Ctx, sessionId: string) {
  const s = await ctx.db.selectFrom('sessions').innerJoin('groups', 'groups.id', 'sessions.group_id')
    .select(['sessions.id', 'sessions.group_id', 'sessions.status', 'sessions.ends_at', 'sessions.session_day', 'sessions.forfeited',
      'sessions.duration_min', 'groups.owner_id', 'groups.name as group_name'])
    .where('sessions.id', '=', sessionId).executeTakeFirst();
  if (!s) throw E.notFound('Không tìm thấy phiên');
  return s;
}

/** Người gọi phải có sự kiện EXITED của chính mình trong phiên (BR-85, BR-86). */
async function requireOwnExit(ctx: Ctx, userId: string, sessionId: string) {
  const s = await sessionOf(ctx, sessionId);
  const sm = await ctx.db.selectFrom('session_members').select(['state', 'exited_at', 'exempted'])
    .where('session_id', '=', sessionId).where('user_id', '=', userId).executeTakeFirst();
  if (!sm) {
    if (s.owner_id === userId) throw new AppError(403, 'NOT_EXITED_IN_SESSION', 'Chủ nhóm không tham gia phiên (D-25)', 'BR-114');
    throw E.forbiddenGroup();
  }
  if (sm.state !== 'EXITED') throw new AppError(400, 'NOT_EXITED_IN_SESSION', 'Chỉ giải trình/khiếu nại sự kiện rời phiên (EXITED) của chính bạn', 'BR-85');
  return { s, sm };
}

const version = (d: Date) => d.getTime();

// ---------------- giải trình ----------------

export async function upsertExplanation(ctx: Ctx, userId: string, sessionId: string, body: string, ifMatch?: string) {
  const { s, sm } = await requireOwnExit(ctx, userId, sessionId);
  const text = body.trim();
  if (!text.length) throw E.validation('Giải trình không được trống');
  if ([...text].length > 500) throw new AppError(422, 'VALIDATION_FAILED', 'Giải trình tối đa 500 ký tự', 'BR-85');
  const now = Date.now();
  const prev = await ctx.db.selectFrom('explanations').selectAll().where('session_id', '=', sessionId).where('user_id', '=', userId).executeTakeFirst();
  let row;
  if (!prev) {
    if (now > s.ends_at.getTime() + ctx.cfg.explanationSubmitDays * 86400e3)
      throw new AppError(409, 'EXPLANATION_WINDOW_CLOSED', `Hết hạn gửi giải trình (${ctx.cfg.explanationSubmitDays} ngày sau phiên)`, 'BR-85');
    const report = await ctx.db.selectFrom('monthly_reports').select('id')
      .where('group_id', '=', s.group_id).where('period', '=', vnPeriod(s.session_day)).where('status', '=', 'GENERATED').executeTakeFirst();
    row = await ctx.db.insertInto('explanations')
      .values({ session_id: sessionId, user_id: userId, body: text, added_after_report: !!report, edited_at: null })
      .onConflict((oc) => oc.columns(['session_id', 'user_id']).doNothing()).returningAll().executeTakeFirst();
    if (!row) throw new AppError(409, 'VERSION_CONFLICT', 'Giải trình vừa được gửi từ yêu cầu khác');
    // BR-85: chủ nhóm nhận thông báo trong app (không push)
    const me = await ctx.db.selectFrom('users').select('display_name').where('id', '=', userId).executeTakeFirstOrThrow();
    await ctx.notifications.saveInbox([s.owner_id], {
      type: 'EXPLANATION_SUBMITTED', title: s.group_name, body: `${me.display_name} đã gửi giải trình cho lần rời phiên.`,
      data: { session_id: sessionId, group_id: s.group_id }, dedupeKey: `EXPLANATION:${sessionId}:${userId}`,
    });
  } else {
    if (now > prev.created_at.getTime() + ctx.cfg.explanationEditH * 3600e3)
      throw new AppError(409, 'EXPLANATION_WINDOW_CLOSED', `Chỉ sửa được trong ${ctx.cfg.explanationEditH} giờ kể từ lần gửi đầu`, 'BR-85');
    if (ifMatch !== undefined && ifMatch.replace(/^W\//, '').replace(/"/g, '') !== String(version(prev.updated_at)))
      throw new AppError(409, 'VERSION_CONFLICT', 'Giải trình đã được sửa ở nơi khác, tải lại rồi sửa');
    if (prev.body === text) row = prev; // không đổi nội dung → không tạo bản lịch sử
    else {
      // BR-102 (giả định, ghi README): nhãn "thêm sau khi tạo báo cáo" chỉ theo BẢN GỬI ĐẦU — sửa sau không đổi nhãn.
      // AC-04.05.5: lưu bản cũ vào explanation_revisions trong cùng giao dịch.
      row = await ctx.db.transaction().execute(async (tx) => {
        const r = await tx.updateTable('explanations').set({ body: text, edited_at: new Date(now) })
          .where('id', '=', prev.id).where(sql`date_trunc('milliseconds', updated_at)`, '=', prev.updated_at).returningAll().executeTakeFirst();
        if (!r) return undefined;
        await tx.insertInto('explanation_revisions').values({ explanation_id: prev.id, body: prev.body, written_at: prev.edited_at ?? prev.created_at }).execute();
        return r;
      });
    }
    if (!row) throw new AppError(409, 'VERSION_CONFLICT', 'Giải trình đã được sửa ở nơi khác, tải lại rồi sửa');
  }
  // Return the same authoritative edit deadline, permission and revision list
  // as GET, so clients cannot briefly unlock a stale or expired editor.
  return getMyExplanation(ctx, userId, sessionId);
}

type ExplRow = { session_id: string; user_id: string; body: string; added_after_report: boolean; created_at: Date; edited_at: Date | null; updated_at: Date };
function toExplanation(r: ExplRow, name: string, exitedAt: Date) {
  return {
    session_id: r.session_id, user_id: r.user_id, display_name: name, exited_at: exitedAt.toISOString(), body: r.body,
    added_after_report: r.added_after_report, submitted_at: r.created_at.toISOString(),
    edited_at: r.edited_at ? r.edited_at.toISOString() : null, // AC-04.06.6 nhãn "đã sửa lúc …"
    updated_at: r.updated_at.toISOString(), version: version(r.updated_at),
  };
}

/** US-04.05: thành viên đọc lại giải trình của CHÍNH mình (kèm lịch sử bản cũ và hạn sửa). 404 nếu chưa gửi. */
export async function getMyExplanation(ctx: Ctx, userId: string, sessionId: string) {
  const { sm } = await requireOwnExit(ctx, userId, sessionId);
  const r = await ctx.db.selectFrom('explanations').selectAll().where('session_id', '=', sessionId).where('user_id', '=', userId).executeTakeFirst();
  if (!r) throw new AppError(404, 'NOT_FOUND', 'Bạn chưa gửi giải trình', 'BR-85');
  const u = await ctx.db.selectFrom('users').select('display_name').where('id', '=', userId).executeTakeFirstOrThrow();
  const hist = await ctx.db.selectFrom('explanation_revisions').select(['body', 'written_at', 'replaced_at'])
    .where('explanation_id', '=', r.id).orderBy('replaced_at', 'desc').orderBy('id', 'desc').execute();
  const editDeadline = new Date(r.created_at.getTime() + ctx.cfg.explanationEditH * 3600e3);
  return {
    ...toExplanation(r, u.display_name, sm.exited_at!),
    edit_deadline: editDeadline.toISOString(),
    can_edit: Date.now() < editDeadline.getTime(),
    history: hist.map((h) => ({ body: h.body, written_at: h.written_at.toISOString(), replaced_at: h.replaced_at.toISOString() })),
  };
}

/** Chủ nhóm xem giải trình (V-47) — theo giờ sự kiện (ngoại lệ 2 BR-115), ghi access_logs (BR-73). */
export async function listExplanationsForOwner(ctx: Ctx, userId: string, sessionId: string) {
  const s = await sessionOf(ctx, sessionId);
  const { role } = await roleIn(ctx, userId, s.group_id);
  if (role === 'MEMBER') throw E.notOwner();
  if (role !== 'OWNER') throw E.forbiddenGroup();
  const rows = await ctx.db.selectFrom('explanations')
    .innerJoin('session_members as sm', (j) => j.onRef('sm.session_id', '=', 'explanations.session_id').onRef('sm.user_id', '=', 'explanations.user_id'))
    .innerJoin('users', 'users.id', 'explanations.user_id')
    .select(['explanations.session_id', 'explanations.user_id', 'explanations.body', 'explanations.added_after_report', 'explanations.created_at', 'explanations.edited_at', 'explanations.updated_at', 'users.display_name', 'sm.exited_at'])
    .where('explanations.session_id', '=', sessionId).orderBy('sm.exited_at', 'asc').execute();
  if (rows.length)
    await ctx.db.insertInto('access_logs').values(rows.map((r) => ({
      viewer_id: userId, viewer_role: 'OWNER' as const, subject_user_id: r.user_id, object_type: 'EXPLANATION', object_id: sessionId, group_id: s.group_id, purpose: null,
    }))).execute();
  const blocked = await blockedIds(ctx, userId);
  return { items: rows.filter((r) => !blocked.has(r.user_id)).map((r) => toExplanation(r, r.display_name, r.exited_at!)) };
}

// ---------------- khiếu nại ----------------

type AppealRow = { id: string; session_id: string; status: AppealStatus; body: string; suspect_system_error: boolean; decision_reason: string | null; decided_at: Date | null };
export const toAppeal = (a: AppealRow) => ({
  appeal_id: a.id, session_id: a.session_id, status: a.status, body: a.body, suspect_system_error: a.suspect_system_error,
  decision_reason: a.decision_reason, decided_at: iso(a.decided_at),
});

export async function createAppeal(ctx: Ctx, userId: string, sessionId: string, body: string, suspect: boolean) {
  const { s } = await requireOwnExit(ctx, userId, sessionId);
  const text = body.trim();
  if (!text.length) throw E.validation('Nội dung khiếu nại không được trống');
  if (s.status !== 'COMPLETED') throw new AppError(409, 'SESSION_NOT_FINISHED', 'Chỉ khiếu nại sau khi phiên đã chốt', 'BR-86');
  const exists = await ctx.db.selectFrom('appeals').select('id').where('session_id', '=', sessionId).where('user_id', '=', userId).executeTakeFirst();
  if (exists) throw new AppError(409, 'APPEAL_EXISTS', 'Bạn đã khiếu nại sự kiện này', 'BR-86');
  if (Date.now() >= s.ends_at.getTime() + ctx.cfg.appealWindowH * 3600e3)
    throw new AppError(409, 'APPEAL_WINDOW_CLOSED', `Hết hạn khiếu nại (${ctx.cfg.appealWindowH} giờ sau khi phiên kết thúc)`, 'BR-86');
  const a = await ctx.db.insertInto('appeals').values({
    session_id: sessionId, user_id: userId, group_id: s.group_id, body: text, suspect_system_error: suspect,
    status: suspect ? 'ESCALATED' : 'PENDING', escalated_at: suspect ? new Date() : null,
    handler_id: null, decision_reason: null, opened_at: null, decided_at: null,
  }).onConflict((oc) => oc.columns(['session_id', 'user_id']).doNothing()).returningAll().executeTakeFirst();
  if (!a) throw new AppError(409, 'APPEAL_EXISTS', 'Bạn đã khiếu nại sự kiện này', 'BR-86');
  if (!suspect) {
    const me = await ctx.db.selectFrom('users').select('display_name').where('id', '=', userId).executeTakeFirstOrThrow();
    await ctx.notifications.saveInbox([s.owner_id], { // báo chủ nhóm trong app, không push
      type: 'APPEAL_CREATED', title: s.group_name, body: `${me.display_name} khiếu nại một lần rời phiên. Mở để xử lý.`,
      data: { session_id: sessionId, group_id: s.group_id, appeal_id: a.id }, dedupeKey: `APPEAL_CREATED:${a.id}`,
    });
  }
  return toAppeal(a);
}

/** Quá appeal_escalate_h chưa có kết quả → CHUYỂN QUẢN TRỊ (kiểm tra lười khi đọc/ghi; job định kỳ chưa làm). */
async function maybeEscalate<T extends AppealRow & { created_at: Date }>(ctx: Ctx, a: T): Promise<T> {
  if ((a.status === 'PENDING' || a.status === 'IN_REVIEW') && Date.now() >= a.created_at.getTime() + ctx.cfg.appealEscalateH * 3600e3) {
    await ctx.db.updateTable('appeals').set({ status: 'ESCALATED', escalated_at: new Date() }).where('id', '=', a.id).where('status', 'in', ['PENDING', 'IN_REVIEW']).execute();
    a.status = 'ESCALATED';
  }
  return a;
}

async function loadAppeal(ctx: Ctx, appealId: string) {
  const a = await ctx.db.selectFrom('appeals').selectAll().where('id', '=', appealId).executeTakeFirst();
  if (!a) throw E.notFound('Không tìm thấy khiếu nại');
  return maybeEscalate(ctx, a);
}

/** Xem một khiếu nại (ngoài openapi): người khiếu nại xem của mình; chủ nhóm mở ca → ĐANG XỬ LÝ + access_logs. */
export async function getAppeal(ctx: Ctx, userId: string, appealId: string) {
  const a = await loadAppeal(ctx, appealId);
  if (a.user_id === userId) return toAppeal(a);
  const { role } = await roleIn(ctx, userId, a.group_id);
  if (role === 'MEMBER') throw E.notOwner();
  if (role !== 'OWNER') throw E.forbiddenGroup();
  if (a.status === 'PENDING') {
    await ctx.db.updateTable('appeals').set({ status: 'IN_REVIEW', opened_at: new Date(), handler_id: userId }).where('id', '=', a.id).where('status', '=', 'PENDING').execute();
    a.status = 'IN_REVIEW';
  }
  await ctx.db.insertInto('access_logs').values({
    viewer_id: userId, viewer_role: 'OWNER', subject_user_id: a.user_id, object_type: 'APPEAL', object_id: a.id, group_id: a.group_id, purpose: null,
  }).execute();
  const sm = await ctx.db.selectFrom('session_members').innerJoin('users', 'users.id', 'session_members.user_id')
    .select(['users.display_name', 'session_members.exited_at', 'session_members.end_reason'])
    .where('session_id', '=', a.session_id).where('user_id', '=', a.user_id).executeTakeFirstOrThrow();
  if (await isBlocked(ctx, userId, a.user_id)) return { ...toAppeal(a), body: 'Nội dung đã ẩn do chặn', decision_reason: null, display_name: 'Người dùng đã chặn', exited_at: iso(sm.exited_at), end_reason: sm.end_reason };
  return { ...toAppeal(a), display_name: sm.display_name, exited_at: iso(sm.exited_at), end_reason: sm.end_reason };
}

export type Decision = 'EXEMPT' | 'REJECT' | 'ESCALATE';

export async function decideAppeal(ctx: Ctx, userId: string, appealId: string, decision: Decision, reason?: string) {
  const a0 = await loadAppeal(ctx, appealId);
  const { role } = await roleIn(ctx, userId, a0.group_id);
  if (role === 'MEMBER') throw E.notOwner();
  if (role !== 'OWNER') throw E.forbiddenGroup();
  if (a0.status === 'EXEMPTED' || a0.status === 'REJECTED') throw new AppError(409, 'APPEAL_ALREADY_DECIDED', 'Khiếu nại đã có kết quả', 'BR-86');
  if (a0.status === 'ESCALATED') throw new AppError(403, 'NOT_GROUP_OWNER', 'Ca đã chuyển quản trị, chủ nhóm không xử lý được nữa', 'BR-110');
  if (decision !== 'ESCALATE' && !reason?.trim()) throw E.validation('decision_reason bắt buộc khi miễn trừ hoặc bác');

  if (decision === 'ESCALATE') {
    const a = await ctx.db.updateTable('appeals').set({ status: 'ESCALATED', escalated_at: new Date(), handler_id: userId })
      .where('id', '=', appealId).where('status', 'in', ['PENDING', 'IN_REVIEW']).returningAll().executeTakeFirst();
    if (!a) throw new AppError(409, 'APPEAL_ALREADY_DECIDED', 'Khiếu nại vừa đổi trạng thái');
    return toAppeal(a);
  }

  const out = await ctx.db.transaction().execute(async (tx) => {
    const a = await tx.selectFrom('appeals').selectAll().where('id', '=', appealId).forUpdate().executeTakeFirstOrThrow();
    if (a.status !== 'PENDING' && a.status !== 'IN_REVIEW') throw new AppError(409, 'APPEAL_ALREADY_DECIDED', 'Khiếu nại vừa đổi trạng thái');
    if (a.status === 'PENDING') // mở thẳng và quyết định: qua ĐANG XỬ LÝ trong cùng thao tác
      await tx.updateTable('appeals').set({ status: 'IN_REVIEW', opened_at: new Date(), handler_id: userId }).where('id', '=', a.id).execute();
    const decided = await tx.updateTable('appeals').set({
      status: decision === 'EXEMPT' ? 'EXEMPTED' : 'REJECTED', decision_reason: reason!.trim(), decided_at: new Date(), handler_id: userId,
    }).where('id', '=', a.id).returningAll().executeTakeFirstOrThrow();
    const restore = decision === 'EXEMPT' ? await applyExemption(ctx, tx, a.session_id, a.user_id) : null;
    return { decided, restore };
  });
  await notifyDecision(ctx, out.decided, out.restore);
  return toAppeal(out.decided);
}

type Tx = Transaction<Database>;
type Restore = { forfeited: boolean; coins: Map<string, number>; exemptedName: string; groupId: string; groupName: string; sessionId: string };

/** BR-87 + BR-88: gắn cờ miễn trừ, tính lại cờ phiên, khôi phục hồi tố khi gỡ forfeited. */
async function applyExemption(ctx: Ctx, tx: Tx, sessionId: string, userId: string): Promise<Restore> {
  const s = await tx.selectFrom('sessions').innerJoin('groups', 'groups.id', 'sessions.group_id')
    .select(['sessions.id', 'sessions.group_id', 'sessions.session_day', 'sessions.duration_min', 'sessions.forfeited', 'groups.name'])
    .where('sessions.id', '=', sessionId).forUpdate().executeTakeFirstOrThrow();
  await tx.updateTable('session_members').set({ exempted: true }).where('session_id', '=', sessionId).where('user_id', '=', userId).execute();
  const rows = await tx.selectFrom('session_members').selectAll().where('session_id', '=', sessionId).execute();
  const remaining = rows.filter((r) => r.state === 'EXITED' && !r.exempted).sort((a, b) => a.exited_at!.getTime() - b.exited_at!.getTime());
  const day = s.session_day;
  const coins = new Map<string, number>();
  const me = rows.find((r) => r.user_id === userId)!;
  // Q-124: người được miễn trừ có điểm danh (cả khi phiên vẫn forfeited)
  await tx.insertInto('daily_attendance')
    .values({ user_id: userId, day, group_id: s.group_id, first_session_id: s.id, focus_minutes: Math.floor(me.focus_seconds / 60) })
    .onConflict((oc) => oc.columns(['user_id', 'day']).doUpdateSet({ sessions_completed: sql`daily_attendance.sessions_completed + 1` }))
    .execute();

  if (remaining.length) {
    const first = remaining[0];
    await tx.updateTable('sessions').set({ forfeited: true, forfeited_at: first.exited_at!, forfeit_trigger_user_id: first.user_id }).where('id', '=', sessionId).execute();
  } else {
    await tx.updateTable('sessions').set({ forfeited: false, forfeited_at: null, forfeit_trigger_user_id: null }).where('id', '=', sessionId).execute();
    if (s.forfeited) {
      const base = sessionReward(s.duration_min, ctx.cfg.engine);
      for (const r of rows) {
        const eligible = r.state === 'COMPLETED' || (r.state === 'EXITED' && r.exempted);
        if (eligible) {
          await tx.selectFrom('users').select('id').where('id', '=', r.user_id).forUpdate().execute();
          const daySum = await tx.selectFrom('coin_ledger').select((eb) => eb.fn.coalesce(eb.fn.sum<string>('amount'), sql<string>`0`).as('s'))
            .where('user_id', '=', r.user_id).where('type', '=', 'SESSION_REWARD').where('reward_date', '=', day).executeTakeFirstOrThrow();
          const amount = Math.min(base, Math.max(0, ctx.cfg.engine.coinsDailyCap - Number(daySum.s))); // trần của ngày phiên (BR-43)
          if (amount > 0) {
            const ins = await tx.insertInto('coin_ledger').values({
              user_id: r.user_id, amount, type: 'SESSION_REWARD', ref_id: s.id, reward_date: day, reason: 'APPEAL_RESTORE',
              idempotency_key: `SESSION_REWARD:${s.id}:${r.user_id}`, balance_after: 0, created_by: null,
            }).onConflict((oc) => oc.doNothing()).returning('amount').executeTakeFirst();
            if (ins) {
              coins.set(r.user_id, ins.amount);
              await tx.updateTable('session_members').set({ coins_awarded: ins.amount }).where('session_id', '=', s.id).where('user_id', '=', r.user_id).execute();
            }
          }
        }
        // Chuỗi: gỡ lần ngắt do phiên này; người hoàn thành có thưởng được +1 như thể không ngắt
        const hadBreak = await tx.selectFrom('achievement_log').select('entry_id').where('user_id', '=', r.user_id)
          .where('ref_session_id', '=', s.id).where('kind', '=', 'STREAK_BREAK').executeTakeFirst();
        if (hadBreak || eligible) await restoreStreak(tx, r.user_id, s.id, day, eligible);
        if (eligible) await awardBadges(tx, r.user_id, day, s.id);
      }
    }
  }
  const nm = await tx.selectFrom('users').select('display_name').where('id', '=', userId).executeTakeFirstOrThrow();
  return { forfeited: remaining.length > 0, coins, exemptedName: nm.display_name, groupId: s.group_id, groupName: s.name, sessionId };
}

async function notifyDecision(ctx: Ctx, a: AppealRow & { user_id: string; group_id: string }, r: Restore | null) {
  const g = await ctx.db.selectFrom('groups').select('name').where('id', '=', a.group_id).executeTakeFirstOrThrow();
  const now = new Date().toISOString();
  if (!r) {
    const env = { type: 'APPEAL_DECIDED', event_id: `APPEAL_DECIDED:${a.id}`, session_id: a.session_id, server_ts: now, ...{ appeal_id: a.id, status: a.status } };
    await ctx.notifications.saveInbox([a.user_id], {
      type: 'APPEAL_DECIDED', title: g.name, body: `Khiếu nại bị bác: ${a.decision_reason}`,
      data: { session_id: a.session_id, group_id: a.group_id, appeal_id: a.id, status: a.status }, dedupeKey: env.event_id,
    });
    await ctx.notifications.deliverOutside(a.user_id, env, { title: g.name, body: 'Khiếu nại đã có kết quả', data: { type: 'APPEAL_DECIDED', event_id: env.event_id, session_id: a.session_id } });
    return;
  }
  // Bản cho người được miễn trừ (được có Coins của chính mình)
  const mine = r.coins.get(a.user_id) ?? 0;
  const ownEvent = `EXEMPTION_GRANTED:${a.id}:self`;
  await ctx.notifications.saveInbox([a.user_id], {
    type: 'EXEMPTION_GRANTED', title: g.name,
    body: `Khiếu nại được chấp nhận — bạn được miễn trừ.${mine ? ` +${mine} Coins.` : ''}`,
    data: { session_id: a.session_id, group_id: a.group_id, appeal_id: a.id, coins_refunded: mine, forfeited: r.forfeited }, dedupeKey: ownEvent,
  });
  await ctx.notifications.deliverOutside(a.user_id,
    { type: 'EXEMPTION_GRANTED', event_id: ownEvent, session_id: a.session_id, server_ts: now, ...{ appeal_id: a.id, coins_refunded: mine } },
    { title: g.name, body: 'Khiếu nại được chấp nhận', data: { type: 'EXEMPTION_GRANTED', event_id: ownEvent, session_id: a.session_id } });
  // Bản đính chính — đúng những người đã nhận MEMBER_EXITED của sự kiện này (BR-87, Q-138), KHÔNG Coins (BR-53)
  const got = await sql<{ user_id: string }>`
    SELECT DISTINCT user_id FROM notifications
    WHERE type = 'MEMBER_EXITED' AND data->>'session_id' = ${a.session_id}
      AND (data->>'exited_user_id' = ${a.user_id} OR (data->>'exited_user_id' IS NULL AND data->>'exited_display_name' = ${r.exemptedName}))`.execute(ctx.db);
  const others = got.rows.map((x) => x.user_id).filter((u) => u !== a.user_id);
  if (!others.length) return;
  const evId = `EXEMPTION_GRANTED:${a.id}:fix`;
  const body = `${r.exemptedName} được miễn trừ lần rời phiên.` + (r.forfeited ? ' Phiên vẫn mất thưởng tập thể.' : ' Phiên không còn mất thưởng tập thể.');
  await ctx.notifications.saveInbox(others, {
    type: 'EXEMPTION_GRANTED', title: g.name, body,
    data: { session_id: a.session_id, group_id: a.group_id, exempted_display_name: r.exemptedName, forfeited: r.forfeited }, dedupeKey: evId,
  });
  for (const u of others)
    await ctx.notifications.deliverOutside(u,
      { type: 'EXEMPTION_GRANTED', event_id: evId, session_id: a.session_id, server_ts: now, ...{ exempted_display_name: r.exemptedName, forfeited: r.forfeited } },
      { title: g.name, body, data: { type: 'EXEMPTION_GRANTED', event_id: evId, session_id: a.session_id } });
}
