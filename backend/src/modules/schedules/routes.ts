// Module schedules: đặt lịch một lần (US-02.10, Must) và lịch lặp (US-02.10b, Should, BR-113).
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { currentUser, idempotent, parse } from '../../shared/http.js';
import { AppError, E } from '../../shared/errors.js';
import { pgCode } from '../../shared/db.js';
import { vnDay } from '../../shared/time.js';
import { requireOwner, roleIn } from '../groups/service.js';
import { decodeCursor, encodeCursor } from '../../shared/cursor.js';
import { validateDuration } from '../../shared/session-policy.js';
import { sessionCols, toSummary } from '../sessions/summary.js';

const hhmmDdmm = (d: Date) => {
  const v = new Date(d.getTime() + 7 * 3600e3).toISOString();
  return `${v.slice(11, 16)} ${v.slice(8, 10)}/${v.slice(5, 7)}`;
};

/** Phiên của nhóm do người gọi làm chủ, còn sửa/hủy được: SCHEDULED và trước mốc COUNTDOWN (started_at − countdown, BR-04/BR-65). */
async function editableSession(ctx: Ctx, userId: string, sessionId: string) {
  const s = await ctx.db.selectFrom('sessions').innerJoin('groups', 'groups.id', 'sessions.group_id')
    .select([...sessionCols, 'groups.name as group_name', 'groups.status as group_status'])
    .where('sessions.id', '=', sessionId).executeTakeFirst();
  if (!s) throw E.notFound('Không tìm thấy phiên');
  await requireOwner(ctx, userId, s.group_id);
  return s;
}
function assertBeforeCountdown(ctx: Ctx, s: { id: string; status: string; started_at: Date }, now = Date.now()) {
  const rt = ctx.sessions.runtimeStatus(s.id);
  // nửa mở: t < started_at − countdown còn SCHEDULED; t = mốc → đã COUNTDOWN (AC-02.11.4)
  if (s.status !== 'SCHEDULED' || (rt && rt !== 'SCHEDULED') || now >= s.started_at.getTime() - ctx.cfg.engine.countdownMs)
    throw new AppError(409, 'SESSION_ALREADY_STARTED', 'Phiên đã bắt đầu đếm ngược — không sửa hoặc hủy được', 'BR-29');
}
async function groupMemberIds(ctx: Ctx, groupId: string) {
  return (await ctx.db.selectFrom('group_members').select('user_id').where('group_id', '=', groupId).where('left_at', 'is', null).execute()).map((m) => m.user_id);
}

/** US-02.11: chủ nhóm hủy phiên SCHEDULED → CANCELLED (OWNER_CANCEL), không ghi dữ liệu; người đang WAITING → VOID (AC-03.01.4). */
export async function cancelSession(ctx: Ctx, userId: string, sessionId: string) {
  const s = await editableSession(ctx, userId, sessionId);
  assertBeforeCountdown(ctx, s);
  const waiting = ctx.sessions.cancelLoaded(sessionId); // đồng bộ ngay sau khi kiểm mốc
  await ctx.sessions.cancelInDb(sessionId, 'OWNER_CANCEL');
  const to = await groupMemberIds(ctx, s.group_id);
  await ctx.notifications.notify([...new Set([...to, ...waiting])], {
    type: 'SESSION_CANCELLED', title: s.group_name, body: `Phiên lúc ${hhmmDdmm(s.started_at)} đã bị chủ nhóm hủy. Không có dữ liệu nào được ghi.`,
    data: { session_id: sessionId, group_id: s.group_id }, dedupeKey: `SESSION_CANCELLED:${sessionId}`,
  });
}

/** US-02.11: sửa giờ/thời lượng phiên SCHEDULED; kiểm lại BR-78 (chỉ trong nhóm) và BR-79. */
export async function updateSession(ctx: Ctx, userId: string, sessionId: string, input: { started_at?: string; duration_min?: number }) {
  const s = await editableSession(ctx, userId, sessionId);
  assertBeforeCountdown(ctx, s);
  if (s.group_status !== 'ACTIVE') throw new AppError(409, 'SESSION_IN_PROGRESS', 'Nhóm không ở trạng thái HOẠT ĐỘNG — không đổi lịch được', 'BR-108');
  const duration = input.duration_min ?? s.duration_min;
  validateDuration(duration);
  const start = input.started_at ? new Date(input.started_at) : new Date(s.started_at);
  if (input.started_at) {
    if (start.getTime() < Date.now() + ctx.cfg.scheduleMinLeadMs)
      throw new AppError(422, 'START_IN_PAST', 'Giờ bắt đầu phải sau thời điểm hiện tại ít nhất 1 phút', 'BR-79');
    start.setMilliseconds(0);
  }
  if (start.getTime() === s.started_at.getTime() && duration === s.duration_min) return toSummary(ctx, s);
  const waiting = ctx.sessions.unloadForReschedule(sessionId);
  let row;
  try {
    row = await ctx.db.transaction().execute(async (tx) => {
      // người đang ở phòng chờ của giờ cũ: bỏ dòng WAITING (chưa có dữ liệu phiên), vào lại theo giờ mới
      await tx.deleteFrom('session_members').where('session_id', '=', sessionId).where('state', '=', 'WAITING').execute();
      return tx.updateTable('sessions')
        .set({ started_at: start, duration_min: duration, ends_at: new Date(start.getTime() + duration * 60000), session_day: vnDay(start) })
        .where('id', '=', sessionId).where('status', '=', 'SCHEDULED').returning([...sessionCols]).executeTakeFirst();
    });
  } catch (e) {
    if (pgCode(e) === '23P01') throw new AppError(409, 'SCHEDULE_OVERLAP', 'Trùng phiên khác của nhóm', 'BR-78');
    if (pgCode(e) === '23514') throw new AppError(409, 'SESSION_ALREADY_STARTED', 'Phiên đã bắt đầu — không sửa được', 'BR-79');
    throw e;
  } finally {
    ctx.sessions.onScheduled(sessionId); // nạp lại theo giờ mới (hoặc giờ cũ nếu lỗi)
  }
  if (!row) throw new AppError(409, 'SESSION_ALREADY_STARTED', 'Phiên đã bắt đầu — không sửa được', 'BR-79');
  const to = await groupMemberIds(ctx, s.group_id);
  await ctx.notifications.notify([...new Set([...to, ...waiting])], {
    type: 'SESSION_UPDATED', title: s.group_name,
    body: `Phiên lúc ${hhmmDdmm(s.started_at)} đổi thành ${hhmmDdmm(start)}, ${duration} phút.`,
    data: { session_id: sessionId, group_id: s.group_id, started_at: start.toISOString(), duration_min: duration },
    dedupeKey: `SESSION_UPDATED:${sessionId}:${Date.now()}`,
  });
  return toSummary(ctx, { ...row, group_name: s.group_name });
}

const GroupId = z.object({ group_id: z.string().uuid() });
const ScheduleInput = z.object({
  start_time: z.string().datetime({ offset: true }),
  duration_min: z.number().int(),
  recurrence: z.unknown().optional(),
});

const Recurrence = z.object({
  weekdays: z.array(z.number().int().min(1).max(7)).min(1).max(7),
  end_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

const addDays = (d: string, n: number) => new Date(Date.parse(`${d}T00:00:00Z`) + n * 86400e3).toISOString().slice(0, 10);
const isoWeekday = (d: string) => ((new Date(`${d}T00:00:00Z`).getUTCDay() + 6) % 7) + 1;

/** Các lần lặp (US-02.10b, BR-113): giờ VN của start_time, từ ngày bắt đầu đến end_date, theo thứ ISO. */
export function occurrences(startIso: string, weekdays: number[], endDate: string): Date[] {
  const start = new Date(startIso);
  start.setMilliseconds(0);
  const vn = new Date(start.getTime() + 7 * 3600e3);
  const startDate = vn.toISOString().slice(0, 10);
  const tod = vn.toISOString().slice(11, 19);
  const out: Date[] = [];
  for (let d = startDate; d <= endDate; d = addDays(d, 1))
    if (weekdays.includes(isoWeekday(d))) out.push(new Date(Date.parse(`${d}T${tod}Z`) - 7 * 3600e3));
  return out;
}

export async function createRecurring(ctx: Ctx, userId: string, groupId: string, startIso: string, duration: number, rec: z.infer<typeof Recurrence>) {
  const g = await requireOwner(ctx, userId, groupId);
  if (g.status !== 'ACTIVE') throw new AppError(409, 'SESSION_IN_PROGRESS', 'Nhóm không ở trạng thái HOẠT ĐỘNG, không đặt lịch được', 'BR-108');
  validateDuration(duration);
  const start = new Date(startIso);
  if (start.getTime() < Date.now() + ctx.cfg.scheduleMinLeadMs)
    throw new AppError(422, 'START_IN_PAST', 'Giờ bắt đầu phải sau giờ server ít nhất 1 phút', 'BR-79');
  const startDate = vnDay(start);
  if (rec.end_date < startDate) throw new AppError(422, 'VALIDATION_FAILED', 'Ngày kết thúc phải sau ngày bắt đầu', 'BR-113');
  if (rec.end_date > addDays(startDate, ctx.cfg.recurrenceMaxWeeks * 7))
    throw new AppError(422, 'VALIDATION_FAILED', `Chuỗi lặp tối đa ${ctx.cfg.recurrenceMaxWeeks} tuần`, 'BR-113');
  const weekdays = [...new Set(rec.weekdays)].sort();
  const occ = occurrences(startIso, weekdays, rec.end_date).filter((t) => t.getTime() >= start.getTime() - 999);
  if (!occ.length) throw new AppError(422, 'VALIDATION_FAILED', 'Không có ngày nào khớp thứ đã chọn trong khoảng', 'BR-113');
  // BR-78 + Q-78 (đề xuất): một lần lặp trùng → từ chối cả chuỗi, kèm danh sách ngày trùng
  const clashes: string[] = [];
  for (const t of occ) {
    const end = new Date(t.getTime() + duration * 60000);
    const hit = await ctx.db.selectFrom('sessions').select('id').where('group_id', '=', groupId).where('status', '!=', 'CANCELLED')
      .where('started_at', '<', end).where('ends_at', '>', t).executeTakeFirst();
    if (hit) clashes.push(vnDay(t));
  }
  if (clashes.length) throw new AppError(409, 'SCHEDULE_OVERLAP', `Trùng phiên khác của nhóm vào các ngày: ${clashes.join(', ')}`, 'BR-78');
  try {
    const { schedule, sessions } = await ctx.db.transaction().execute(async (tx) => {
      const vnStart = new Date(start.getTime() + 7 * 3600e3).toISOString().slice(11, 19);
      const schedule = await tx.insertInto('schedules').values({
        group_id: groupId, created_by: userId, start_time: vnStart, duration_min: duration, weekdays, start_date: startDate, end_date: rec.end_date, cancelled_at: null,
      }).returning('id').executeTakeFirstOrThrow();
      const sessions = await tx.insertInto('sessions').values(occ.map((t) => ({
        group_id: groupId, schedule_id: schedule.id, duration_min: duration, started_at: t, ends_at: new Date(t.getTime() + duration * 60000),
        session_day: vnDay(t), created_by: userId, forfeited_at: null, forfeit_trigger_user_id: null, cancel_reason: null, cancelled_at: null, completed_at: null,
      }))).returning([...sessionCols]).execute();
      return { schedule, sessions };
    });
    ctx.sessions.onScheduled(sessions[0].id);
    sessions.sort((a, b) => a.started_at.getTime() - b.started_at.getTime());
    return { schedule_id: schedule.id, group_id: groupId, sessions: sessions.map((s) => toSummary(ctx, { ...s, group_name: g.name })) };
  } catch (e) {
    if (pgCode(e) === '23P01') throw new AppError(409, 'SCHEDULE_OVERLAP', 'Trùng phiên khác của nhóm', 'BR-78');
    throw e;
  }
}

export async function createOneOffSession(ctx: Ctx, userId: string, groupId: string, startIso: string, duration: number) {
  const g = await requireOwner(ctx, userId, groupId);
  if (g.status !== 'ACTIVE') throw new AppError(409, 'SESSION_IN_PROGRESS', 'Nhóm không ở trạng thái HOẠT ĐỘNG, không đặt lịch được', 'BR-108');
  validateDuration(duration);
  const start = new Date(startIso);
  if (start.getTime() < Date.now() + ctx.cfg.scheduleMinLeadMs)
    throw new AppError(422, 'START_IN_PAST', 'Giờ bắt đầu phải sau giờ server ít nhất 1 phút', 'BR-79');
  start.setMilliseconds(0);
  const ends = new Date(start.getTime() + duration * 60000);
  try {
    const s = await ctx.db
      .insertInto('sessions')
      .values({
        group_id: groupId, schedule_id: null, duration_min: duration, started_at: start, ends_at: ends,
        session_day: vnDay(start), created_by: userId, forfeited_at: null, forfeit_trigger_user_id: null,
        cancel_reason: null, cancelled_at: null, completed_at: null,
      })
      .returning([...sessionCols])
      .executeTakeFirstOrThrow();
    ctx.sessions.onScheduled(s.id);
    return toSummary(ctx, { ...s, group_name: g.name });
  } catch (e) {
    if (pgCode(e) === '23P01') throw new AppError(409, 'SCHEDULE_OVERLAP', 'Trùng phiên khác của nhóm', 'BR-78');
    throw e;
  }
}

export function scheduleRoutes(app: FastifyInstance, ctx: Ctx) {
  app.post('/v1/groups/:group_id/schedules', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id } = parse(GroupId, req.params);
    const body = parse(ScheduleInput, req.body);
    if (body.recurrence !== undefined && body.recurrence !== null) {
      const rec = parse(Recurrence, body.recurrence);
      return idempotent(req, reply, ctx.db, me.id, async () => ({ status: 201, body: await createRecurring(ctx, me.id, group_id, body.start_time, body.duration_min, rec) }));
    }
    return idempotent(req, reply, ctx.db, me.id, async () => {
      const s = await createOneOffSession(ctx, me.id, group_id, body.start_time, body.duration_min);
      return { status: 201, body: { schedule_id: null, group_id, sessions: [s] } };
    });
  });

  app.get('/v1/groups/:group_id/schedules', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id } = parse(GroupId, req.params);
    const q = parse(z.object({ from: z.string().datetime({ offset: true }).optional(), to: z.string().datetime({ offset: true }).optional(), limit: z.coerce.number().int().min(1).max(50).default(10), cursor: z.string().optional() }), req.query);
    const cursor = decodeCursor(q.cursor);
    if (q.cursor && (!cursor || !z.string().uuid().safeParse(cursor.id).success)) throw new AppError(422, 'INVALID_CURSOR', 'Con trỏ phân trang không hợp lệ');
    const { g, role } = await roleIn(ctx, me.id, group_id);
    if (!role) throw E.forbiddenGroup();
    let qb = ctx.db.selectFrom('sessions').select([...sessionCols]).where('group_id', '=', group_id);
    if (q.from) qb = qb.where('started_at', '>=', new Date(q.from));
    if (q.to) qb = qb.where('started_at', '<', new Date(q.to));
    if (cursor) qb = qb.where((eb) => eb.or([eb('started_at', '<', cursor.t), eb.and([eb('started_at', '=', cursor.t), eb('id', '<', cursor.id)])]));
    const rows = await qb.orderBy('started_at', 'desc').orderBy('id', 'desc').limit(q.limit + 1).execute();
    const page = rows.slice(0, q.limit);
    const last = page.at(-1);
    return { items: page.map((r) => toSummary(ctx, { ...r, group_name: g.name })), next_cursor: rows.length > q.limit && last ? encodeCursor(last.started_at, last.id) : null };
  });

  // US-02.11 (openapi updateSession / cancelSession)
  app.patch('/v1/sessions/:session_id', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { session_id } = parse(z.object({ session_id: z.string().uuid() }), req.params);
    const body = parse(z.object({ started_at: z.string().datetime({ offset: true }).optional(), duration_min: z.number().int().optional() }).strict(), req.body);
    return updateSession(ctx, me.id, session_id, body);
  });

  app.delete('/v1/sessions/:session_id', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { session_id } = parse(z.object({ session_id: z.string().uuid() }), req.params);
    return idempotent(req, reply, ctx.db, me.id, async () => {
      await cancelSession(ctx, me.id, session_id);
      return { status: 204 };
    });
  });
}
