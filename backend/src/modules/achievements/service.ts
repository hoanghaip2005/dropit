// Huy hiệu theo mốc (BR-52, BR-89) và phát lại nhật ký chuỗi (BR-88, BR-92).
import { sql, type Transaction } from 'kysely';
import type { Database, DB } from '../../shared/db.js';

type Tx = Transaction<Database> | DB;

export type BadgeMetrics = { STREAK_DAYS: number; REWARDED_SESSIONS: number; FOCUS_HOURS: number };

/** Số đo cấp người dùng cho huy hiệu — chỉ dữ liệu đã chốt. */
export async function badgeMetrics(tx: Tx, userId: string): Promise<BadgeMetrics> {
  const u = await tx.selectFrom('users').select(['longest_streak']).where('id', '=', userId).executeTakeFirstOrThrow();
  // phiên đang chốt (finalizeSession) vẫn ACTIVE trong transaction → tính cả ACTIVE có trạng thái cuối
  // "hoàn thành có thưởng" (D-11): COMPLETED ở phiên không forfeited; EXITED được miễn trừ ở phiên đã gỡ forfeited (BR-87)
  const r = await sql<{ rewarded: string; focus: string }>`
    SELECT
      count(*) FILTER (WHERE s.status IN ('COMPLETED','ACTIVE') AND NOT s.forfeited AND (sm.state = 'COMPLETED' OR (sm.state = 'EXITED' AND sm.exempted))) AS rewarded,
      COALESCE(sum(sm.focus_seconds) FILTER (WHERE s.status IN ('COMPLETED','ACTIVE') AND sm.state = 'COMPLETED'), 0) AS focus
    FROM session_members sm JOIN sessions s ON s.id = sm.session_id
    WHERE sm.user_id = ${userId}`.execute(tx);
  const row = r.rows[0];
  return {
    STREAK_DAYS: u.longest_streak,
    REWARDED_SESSIONS: Number(row?.rewarded ?? 0),
    FOCUS_HOURS: Math.floor(Number(row?.focus ?? 0) / 3600), // BR-89: chỉ phiên COMPLETED, kể cả forfeited
  };
}

/** Cấp huy hiệu đạt mốc (một lần, không thu hồi). Ghi BADGE_AWARD + hộp thông báo trong app (BR-91: không push). */
export async function awardBadges(tx: Tx, userId: string, day: string, sessionId: string | null): Promise<string[]> {
  const m = await badgeMetrics(tx, userId);
  const all = await tx.selectFrom('badges').selectAll().where('retired_at', 'is', null).execute();
  const owned = new Set((await tx.selectFrom('user_badges').select('badge_id').where('user_id', '=', userId).execute()).map((b) => b.badge_id));
  const due = all.filter((b) => !owned.has(b.id) && m[b.metric] >= b.threshold).sort((a, b) => a.id.localeCompare(b.id));
  const got: string[] = [];
  for (const b of due) {
    const ins = await tx.insertInto('user_badges').values({ user_id: userId, badge_id: b.id, showcase_slot: null })
      .onConflict((oc) => oc.columns(['user_id', 'badge_id']).doNothing()).returning('badge_id').executeTakeFirst();
    if (!ins) continue;
    got.push(b.id);
    await tx.insertInto('achievement_log').values({
      user_id: userId, kind: 'BADGE_AWARD', value_before: null, value_after: b.threshold, day,
      ref_session_id: sessionId, ref_badge_id: b.id, reason: b.metric,
    }).execute();
    await tx.insertInto('notifications').values({
      user_id: userId, type: 'BADGE_EARNED', title: 'Huy hiệu mới', body: `Bạn vừa đạt huy hiệu “${b.name}”.`,
      data: JSON.stringify({ badge_code: b.id, session_id: sessionId }), dedupe_key: `BADGE_EARNED:${userId}:${b.id}`, read_at: null,
    }).onConflict((oc) => oc.columns(['user_id', 'dedupe_key']).doNothing()).execute();
  }
  return got;
}

// ---------------- phát lại chuỗi (BR-88, BR-92) ----------------

export type LogEvent = {
  kind: 'CHECKIN' | 'STREAK_INC' | 'STREAK_BREAK' | 'STREAK_RESTORE' | 'BADGE_AWARD';
  day: string;
  ref_session_id: string | null;
  reason: string;
  at: number; // created_at ms
};
export type RestoreMark = { sessionId: string; day: string; inc: boolean; at: number };

/**
 * Tính lại chuỗi từ nhật ký chỉ-thêm. Lần ngắt của phiên đã được khôi phục (dòng STREAK_RESTORE) bị bỏ qua;
 * nếu người đó "hoàn thành có thưởng" nhờ khôi phục thì thêm một lần +1 ảo tại vị trí lần ngắt — trừ khi ngày đó
 * đã có STREAK_INC thật (BR-49: tối đa 1 lần/ngày).
 */
export function replayStreak(events: LogEvent[], restores: RestoreMark[]): { current: number; longest: number; lastIncDay: string | null } {
  const restored = new Map(restores.map((r) => [r.sessionId, r]));
  const incDays = new Set(events.filter((e) => e.kind === 'STREAK_INC').map((e) => e.day));
  type Step = { t: number; op: 'INC' | 'BREAK'; day: string; order: number };
  const steps: Step[] = [];
  const virtualDone = new Set<string>();
  events.forEach((e, i) => {
    if (e.kind === 'STREAK_INC') steps.push({ t: e.at, op: 'INC', day: e.day, order: i });
    if (e.kind === 'STREAK_BREAK') {
      const r = e.ref_session_id ? restored.get(e.ref_session_id) : undefined;
      if (!r) steps.push({ t: e.at, op: 'BREAK', day: e.day, order: i });
      else if (r.inc && !incDays.has(r.day) && !virtualDone.has(r.day)) {
        virtualDone.add(r.day);
        steps.push({ t: e.at, op: 'INC', day: r.day, order: i });
      }
    }
  });
  // khôi phục không có lần ngắt tương ứng (hiếm): +1 ảo theo thời điểm khôi phục
  for (const r of restores)
    if (r.inc && !incDays.has(r.day) && !virtualDone.has(r.day)) {
      virtualDone.add(r.day);
      steps.push({ t: r.at, op: 'INC', day: r.day, order: Number.MAX_SAFE_INTEGER });
    }
  steps.sort((a, b) => a.t - b.t || a.order - b.order);
  let cur = 0;
  let longest = 0;
  let lastIncDay: string | null = null;
  for (const s of steps) {
    if (s.op === 'BREAK') cur = 0;
    else {
      cur += 1;
      longest = Math.max(longest, cur);
      if (!lastIncDay || s.day > lastIncDay) lastIncDay = s.day;
    }
  }
  return { current: cur, longest, lastIncDay };
}

/** Ghi STREAK_RESTORE cho một phiên và đặt lại current/longest bằng phát lại (longest chỉ tăng). */
export async function restoreStreak(tx: Tx, userId: string, sessionId: string, day: string, inc: boolean) {
  const u = await tx.selectFrom('users').select(['current_streak', 'longest_streak', 'streak_last_inc_day']).where('id', '=', userId).forUpdate().executeTakeFirstOrThrow();
  const had = await tx.selectFrom('achievement_log').select('entry_id').where('user_id', '=', userId)
    .where('kind', '=', 'STREAK_RESTORE').where('ref_session_id', '=', sessionId).executeTakeFirst();
  if (had) return u.current_streak;
  const reason = inc ? 'APPEAL_RESTORE' : 'APPEAL_RESTORE_NO_INC';
  const logs = await tx.selectFrom('achievement_log').select(['kind', 'day', 'ref_session_id', 'reason', 'created_at'])
    .where('user_id', '=', userId).where('kind', 'in', ['STREAK_INC', 'STREAK_BREAK', 'STREAK_RESTORE'])
    .orderBy('created_at', 'asc').orderBy('entry_id', 'asc').execute();
  const events: LogEvent[] = logs.map((l) => ({ kind: l.kind, day: l.day, ref_session_id: l.ref_session_id, reason: l.reason, at: l.created_at.getTime() }));
  const restores: RestoreMark[] = events.filter((e) => e.kind === 'STREAK_RESTORE' && e.ref_session_id)
    .map((e) => ({ sessionId: e.ref_session_id!, day: e.day, inc: e.reason === 'APPEAL_RESTORE', at: e.at }));
  restores.push({ sessionId, day, inc, at: Date.now() });
  const r = replayStreak(events, restores);
  const longest = Math.max(u.longest_streak, r.longest);
  const lastInc = [u.streak_last_inc_day, r.lastIncDay].filter(Boolean).sort().pop() ?? null;
  await tx.updateTable('users').set({ current_streak: r.current, longest_streak: longest, streak_last_inc_day: lastInc }).where('id', '=', userId).execute();
  await tx.insertInto('achievement_log').values({
    user_id: userId, kind: 'STREAK_RESTORE', value_before: u.current_streak, value_after: r.current, day,
    ref_session_id: sessionId, ref_badge_id: null, reason,
  }).execute();
  return r.current;
}
