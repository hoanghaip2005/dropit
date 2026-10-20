// Báo cáo tháng (EP-08): bản chụp bất biến (BR-56), idempotent theo (nhóm, kỳ) (BR-101), không Coins/chuỗi (BR-53).
// Email tóm tắt (BR-105) ghi ra thư mục outbox + console, không gửi thật; không ảnh/link theo dõi (D-27).
import { mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { sql } from 'kysely';
import type { Ctx } from '../../context.js';
import { sortPeople } from '../../shared/sort.js';

const VN = 7 * 3600e3;
/** [start, end) của tháng theo Asia/Ho_Chi_Minh (BR-55). */
export function periodRange(month: string) {
  const [y, m] = month.split('-').map(Number);
  const start = new Date(Date.UTC(y, m - 1, 1) - VN);
  const end = new Date(Date.UTC(y, m, 1) - VN);
  const lastDay = new Date(Date.UTC(y, m, 0)).toISOString().slice(0, 10);
  return { start, end, period: `${month}-01`, lastDay };
}
export const prevMonth = (month: string) => {
  const [y, m] = month.split('-').map(Number);
  return m === 1 ? `${y - 1}-12` : `${y}-${String(m - 1).padStart(2, '0')}`;
};
export const rate = (num: number, den: number) => (den > 0 ? Math.round((num / den) * 1000) / 10 : null);

export type RowMetrics = {
  joined_at: string;
  joined_on: string | null; // "vào ngày" nếu vào giữa kỳ (BR-59)
  left_on: string | null;
  expected_sessions: number;
  completed_sessions: number;
  rewarded_sessions: number;
  completion_rate: number | null;
  exited_count: number;
  lost_count: number;
  absent_count: number;
  late_count: number;
  pause_count: number;
  forfeit_trigger_count: number;
  forfeited_participated: number;
  focus_minutes: number;
  attendance_days: number;
};

type SessRow = { id: string; started_at: Date; session_day: string; forfeited: boolean; forfeit_trigger_user_id: string | null };
type SmRow = { session_id: string; user_id: string; state: string; late_join: boolean; pause_count: number; focus_seconds: number; exempted: boolean };

/** Tính dòng một thành viên theo §Báo cáo §2 — hàm thuần để test unit. */
export function memberMetrics(
  member: { user_id: string; joined_at: Date; left_at: Date | null },
  range: { start: Date; end: Date },
  sessions: SessRow[],
  sm: Map<string, SmRow>, // khóa session_id cho người này
): RowMetrics {
  const from = Math.max(range.start.getTime(), member.joined_at.getTime());
  const to = Math.min(range.end.getTime(), member.left_at ? member.left_at.getTime() : Infinity);
  const mine = sessions.filter((s) => s.started_at.getTime() >= from && s.started_at.getTime() < to);
  const m: RowMetrics = {
    joined_at: member.joined_at.toISOString(),
    joined_on: member.joined_at > range.start ? new Date(member.joined_at.getTime() + VN).toISOString().slice(0, 10) : null,
    left_on: member.left_at && member.left_at < range.end ? new Date(member.left_at.getTime() + VN).toISOString().slice(0, 10) : null,
    expected_sessions: 0, completed_sessions: 0, rewarded_sessions: 0, completion_rate: null, exited_count: 0, lost_count: 0,
    absent_count: 0, late_count: 0, pause_count: 0, forfeit_trigger_count: 0, forfeited_participated: 0, focus_minutes: 0, attendance_days: 0,
  };
  const days = new Set<string>();
  let focus = 0;
  for (const s of mine) {
    const r = sm.get(s.id);
    const st = r?.state ?? 'ABSENT'; // không có dòng → vắng (lượt dự kiến vẫn tính)
    if (st === 'WITHDRAWN' || st === 'VOID') continue; // trừ khỏi lượt dự kiến (§3)
    m.expected_sessions++;
    if (st === 'COMPLETED') {
      m.completed_sessions++;
      days.add(s.session_day);
      if (!s.forfeited) m.rewarded_sessions++;
    }
    if (st === 'EXITED') m.exited_count++;
    if (st === 'LOST') m.lost_count++;
    if (st === 'ABSENT') m.absent_count++;
    if (r?.late_join) m.late_count++;
    m.pause_count += r?.pause_count ?? 0;
    if (s.forfeit_trigger_user_id === member.user_id) m.forfeit_trigger_count++;
    if (s.forfeited && ['COMPLETED', 'EXITED', 'LOST'].includes(st)) m.forfeited_participated++;
    if (['COMPLETED', 'EXITED', 'LOST'].includes(st)) focus += r?.focus_seconds ?? 0; // gồm phần trước EXITED/LOST (giả định §2)
  }
  m.focus_minutes = Math.floor(focus / 60);
  m.attendance_days = days.size;
  m.completion_rate = rate(m.completed_sessions, m.expected_sessions);
  return m;
}

export function groupSummary(rows: RowMetrics[], sessions: SessRow[], prev: Record<string, unknown> | null) {
  const expected = rows.reduce((a, r) => a + r.expected_sessions, 0);
  const completed = rows.reduce((a, r) => a + r.completed_sessions, 0);
  const rewarded = rows.reduce((a, r) => a + r.rewarded_sessions, 0);
  const forfeitedN = sessions.filter((s) => s.forfeited).length;
  const sum = {
    sessions_held: sessions.length,
    expected_slots: expected,
    completion_rate: rate(completed, expected),
    rewarded_completion_rate: rate(rewarded, expected),
    forfeited_sessions: forfeitedN,
    forfeited_rate: rate(forfeitedN, sessions.length),
    focus_minutes_total: rows.reduce((a, r) => a + r.focus_minutes, 0),
  };
  const delta = (k: keyof typeof sum) => {
    const a = sum[k];
    const b = prev?.[k];
    return typeof a === 'number' && typeof b === 'number' ? Math.round((a - b) * 10) / 10 : null;
  };
  return {
    ...sum,
    prev_month_delta: prev
      ? { sessions_held: delta('sessions_held'), completion_rate_pp: delta('completion_rate'), rewarded_completion_rate_pp: delta('rewarded_completion_rate'),
          forfeited_sessions: delta('forfeited_sessions'), focus_minutes_total: delta('focus_minutes_total') }
      : null,
  };
}

/** Tạo báo cáo cho một nhóm/kỳ. Đã GENERATED → bỏ qua (idempotent). */
export async function generateGroupReport(ctx: Ctx, groupId: string, month: string): Promise<{ id: string; created: boolean } | null> {
  const range = periodRange(month);
  const db = ctx.db;
  const g = await db.selectFrom('groups').selectAll().where('id', '=', groupId).executeTakeFirstOrThrow();
  if (g.created_at >= range.end) return null; // nhóm chưa tồn tại trong kỳ
  const existing = await db.selectFrom('monthly_reports').select(['id', 'status']).where('group_id', '=', groupId).where('period', '=', range.period).executeTakeFirst();
  if (existing?.status === 'GENERATED') return { id: existing.id, created: false };

  const id = await db.transaction().execute(async (tx) => {
    const rep = existing
      ? await tx.updateTable('monthly_reports').set({ attempts: sql`attempts + 1` }).where('id', '=', existing.id).returning('id').executeTakeFirstOrThrow()
      : await tx.insertInto('monthly_reports').values({
          group_id: groupId, period: range.period, period_end: range.lastDay, owner_id_snapshot: g.owner_id, attempts: 1,
          member_count: null, group_visible: null, group_summary: null, pdf_key: null, emailed_at: null, generated_at: null,
          expires_at: sql<Date>`(${range.period}::date + interval '13 months')` as never,
        }).returning('id').executeTakeFirstOrThrow();
    await tx.deleteFrom('monthly_report_rows').where('report_id', '=', rep.id).execute(); // lần thử trước (chưa GENERATED)
    const sessions = await tx.selectFrom('sessions').select(['id', 'started_at', 'session_day', 'forfeited', 'forfeit_trigger_user_id'])
      .where('group_id', '=', groupId).where('status', '=', 'COMPLETED') // BR-58: bỏ phiên CANCELLED
      .where('started_at', '>=', range.start).where('started_at', '<', range.end).orderBy('started_at').execute();
    const members = await tx.selectFrom('group_members').innerJoin('users', 'users.id', 'group_members.user_id')
      .select(['group_members.user_id', 'group_members.joined_at', 'group_members.left_at', 'users.display_name'])
      .where('group_members.group_id', '=', groupId).where('group_members.user_id', '!=', g.owner_id) // BR-60
      .where('group_members.joined_at', '<', range.end)
      .where((eb) => eb.or([eb('group_members.left_at', 'is', null), eb('group_members.left_at', '>=', range.start)])).execute();
    const sms = sessions.length
      ? await tx.selectFrom('session_members').select(['session_id', 'user_id', 'state', 'late_join', 'pause_count', 'focus_seconds', 'exempted'])
          .where('session_id', 'in', sessions.map((s) => s.id)).execute()
      : [];
    // Một người có thể vào/rời nhóm nhiều lần: gộp theo user_id (lấy lần vào sớm nhất trong kỳ)
    const byUser = new Map<string, (typeof members)[number]>();
    for (const m of members) {
      const cur = byUser.get(m.user_id);
      if (!cur || m.joined_at < cur.joined_at) byUser.set(m.user_id, { ...m, left_at: cur && (!cur.left_at || !m.left_at) ? null : m.left_at });
    }
    const rows: { user_id: string; display_name: string; metrics: RowMetrics }[] = [];
    for (const m of byUser.values()) {
      const mine = new Map(sms.filter((x) => x.user_id === m.user_id).map((x) => [x.session_id, x as SmRow]));
      rows.push({ user_id: m.user_id, display_name: m.display_name, metrics: memberMetrics(m, range, sessions, mine) });
    }
    if (rows.length)
      await tx.insertInto('monthly_report_rows').values(rows.map((r) => ({
        report_id: rep.id, user_id: r.user_id, display_name_snapshot: r.display_name, metrics: JSON.stringify(r.metrics),
      }))).execute();
    const prev = await tx.selectFrom('monthly_reports').select('group_summary').where('group_id', '=', groupId)
      .where('period', '=', periodRange(prevMonth(month)).period).where('status', '=', 'GENERATED').executeTakeFirst();
    const summary = groupSummary(rows.map((r) => r.metrics), sessions, prev?.group_summary ?? null);
    // BR-104: đếm thành viên (không gồm chủ nhóm) đang trong nhóm lúc tạo
    const cnt = await tx.selectFrom('group_members').select((eb) => eb.fn.countAll<string>().as('n'))
      .where('group_id', '=', groupId).where('left_at', 'is', null).executeTakeFirstOrThrow();
    const memberCount = Number(cnt.n);
    await tx.updateTable('monthly_reports').set({
      status: 'GENERATED', generated_at: new Date(), group_summary: JSON.stringify(summary), member_count: memberCount,
      group_visible: memberCount >= 5, owner_id_snapshot: g.owner_id,
    }).where('id', '=', rep.id).execute();
    return rep.id;
  });

  await sendReportEmail(ctx, id).catch((e) => console.error('[reports] ghi email lỗi', e));
  await ctx.notifications.saveInbox([g.owner_id], {
    type: 'REPORT_READY', title: g.name, body: `Báo cáo tháng ${month.slice(5)}/${month.slice(0, 4)} đã sẵn sàng.`,
    data: { group_id: groupId, month }, dedupeKey: `REPORT_READY:${groupId}:${month}`,
  });
  return { id, created: true };
}

/** Email tóm tắt cho chủ nhóm (BR-105): không dòng thành viên, không Coins/chuỗi, không PDF, không theo dõi (D-27). */
export async function sendReportEmail(ctx: Ctx, reportId: string) {
  const r = await ctx.db.selectFrom('monthly_reports').innerJoin('groups', 'groups.id', 'monthly_reports.group_id')
    .innerJoin('users', 'users.id', 'monthly_reports.owner_id_snapshot')
    .select(['monthly_reports.id', 'monthly_reports.group_id', 'monthly_reports.period', 'monthly_reports.group_summary', 'monthly_reports.emailed_at',
      'groups.name', 'groups.report_purpose', 'users.email', 'users.display_name'])
    .where('monthly_reports.id', '=', reportId).executeTakeFirstOrThrow();
  if (r.emailed_at) return null;
  const s = (r.group_summary ?? {}) as Record<string, any>;
  const month = r.period.slice(0, 7);
  const pct = (v: unknown) => (typeof v === 'number' ? `${String(v).replace('.', ',')}%` : 'không có dữ liệu');
  const pp = (v: unknown) => (typeof v === 'number' ? `${v >= 0 ? '+' : ''}${String(v).replace('.', ',')} đpt` : 'không có dữ liệu so sánh');
  const d = s.prev_month_delta as Record<string, number | null> | null;
  const lines = [
    `To: ${r.email ?? '(chưa có email)'}`,
    `Subject: [DropIt!] Báo cáo tháng ${month} — ${r.name}`,
    'Content-Type: text/plain; charset=utf-8',
    '',
    `Chào ${r.display_name},`,
    '',
    `Báo cáo tháng ${month} của nhóm "${r.name}" đã sẵn sàng.`,
    `Mục đích sử dụng báo cáo: ${r.report_purpose}`,
    '',
    ...(s.sessions_held
      ? [
          `- Số phiên đã diễn ra: ${s.sessions_held}`,
          `- Tỉ lệ hoàn thành phiên: ${pct(s.completion_rate)} (so với tháng trước: ${d ? pp(d.completion_rate_pp) : 'không có dữ liệu so sánh'})`,
          `- Tỉ lệ hoàn thành có thưởng: ${pct(s.rewarded_completion_rate)} (so với tháng trước: ${d ? pp(d.rewarded_completion_rate_pp) : 'không có dữ liệu so sánh'})`,
          `- Số phiên bị mất thưởng tập thể: ${s.forfeited_sessions}`,
        ]
      : ['Không có phiên trong kỳ.']),
    '',
    `Mở báo cáo trong ứng dụng (cần đăng nhập): dropit://groups/${r.group_id}/reports/${month}`,
    '',
    '— DropIt! (email chỉ có tóm tắt; chi tiết từng thành viên xem trong ứng dụng)',
  ];
  const text = lines.join('\n');
  await mkdir(ctx.cfg.outboxDir, { recursive: true });
  const file = join(ctx.cfg.outboxDir, `report-${month}-${r.group_id}.eml`);
  await writeFile(file, text, 'utf8');
  if (ctx.cfg.nodeEnv !== 'test') console.log(`[email:outbox] → ${r.email} | báo cáo ${month} ${r.name} | ${file}`);
  await ctx.db.updateTable('monthly_reports').set({ emailed_at: new Date() }).where('id', '=', reportId).execute();
  return { file, text };
}

/** Job monthly-report: mọi nhóm chưa giải tán (hoặc chỉ groupIds), ghi job_runs. */
export async function runMonthlyReportJob(ctx: Ctx, month: string, groupIds?: string[]) {
  const run = await ctx.db.insertInto('job_runs').values({ job: 'monthly-report', run_key: month + (groupIds ? `:${groupIds.join(',').slice(0, 80)}` : ''), status: 'RUNNING', finished_at: null, error: null, attempt: sql`(SELECT COALESCE(max(attempt),0)+1 FROM job_runs WHERE job = 'monthly-report' AND run_key = ${month + (groupIds ? `:${groupIds.join(',').slice(0, 80)}` : '')})` as never })
    .returning('id').executeTakeFirstOrThrow();
  const out: { group_id: string; report_id: string | null; created: boolean; error?: string }[] = [];
  // BR-62: nhóm giải tán trong kỳ vẫn có báo cáo phần tháng đến ngày giải tán, gửi người từng là chủ nhóm
  const range = periodRange(month);
  let qb = ctx.db.selectFrom('groups').select('id')
    .where((eb) => eb.or([eb('status', '!=', 'DISSOLVED'), eb('dissolved_at', '>=', range.start)]));
  if (groupIds?.length) qb = qb.where('id', 'in', groupIds);
  for (const g of await qb.execute()) {
    try {
      const r = await generateGroupReport(ctx, g.id, month);
      out.push({ group_id: g.id, report_id: r?.id ?? null, created: !!r?.created });
    } catch (e) {
      out.push({ group_id: g.id, report_id: null, created: false, error: String((e as Error).message) });
    }
  }
  const failed = out.filter((o) => o.error);
  await ctx.db.updateTable('job_runs').set({ status: failed.length ? 'FAILED' : 'SUCCEEDED', finished_at: new Date(), error: failed.length ? JSON.stringify(failed).slice(0, 2000) : null })
    .where('id', '=', run.id).execute();
  return { month, results: out };
}

export function rowView(
  r: { user_id: string | null; display_name_snapshot: string | null; metrics: Record<string, unknown> },
  explanations: { session_id: string; exited_at: string; body: string; added_after_report: boolean; edited_at: string | null }[],
) {
  const m = r.metrics as unknown as RowMetrics;
  return {
    user_id: r.user_id,
    display_name: r.display_name_snapshot ?? '(đã xóa tài khoản)',
    expected_sessions: m.expected_sessions,
    completed_sessions: m.completed_sessions,
    completion_rate: m.completion_rate,
    exited_count: m.exited_count,
    lost_count: m.lost_count,
    absent_count: m.absent_count,
    focus_minutes: m.focus_minutes,
    attendance_days: m.attendance_days,
    explanations,
    prev_month_delta: null,
  };
}

export const sortRows = <T extends { display_name: string; joined_at: string; user_id: string }>(xs: T[]) => sortPeople(xs);
