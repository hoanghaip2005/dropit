// Module rewards: chốt phiên trong MỘT transaction (D-05, 01 §2.2) — trạng thái cuối, Coins
// (D-09: 25'→10, 50'→25, trần 100/ngày VN), điểm danh (BR-46), chuỗi (BR-47…BR-50).
import { sql, type Transaction } from 'kysely';
import type { Database, DB } from '../../shared/db.js';
import type { EngineConfig } from '../../config.js';
import { awardBadges } from '../achievements/service.js';

export type MemberResult = {
  user_id: string;
  state: string;
  coins_awarded: number;
  reward_cap_reached: boolean;
  streak_after: number;
  streak_broken: boolean;
  focus_seconds: number;
  new_badges: string[];
};

/** Ngắt chuỗi (BR-47) — dùng ngay khi EXITED và khi chốt phiên forfeited. */
export async function breakStreak(tx: Transaction<Database> | DB, userId: string, day: string, sessionId: string, reason: string) {
  const u = await tx.selectFrom('users').select(['current_streak']).where('id', '=', userId).forUpdate().executeTakeFirstOrThrow();
  await tx.updateTable('users').set({ current_streak: 0 }).where('id', '=', userId).execute();
  await tx.insertInto('achievement_log').values({
    user_id: userId, kind: 'STREAK_BREAK', value_before: u.current_streak, value_after: 0, day,
    ref_session_id: sessionId, ref_badge_id: null, reason,
  }).execute();
}

export async function finalizeSession(db: DB, cfg: EngineConfig, sessionId: string): Promise<MemberResult[]> {
  return db.transaction().execute(async (tx) => {
    const s = await tx.selectFrom('sessions').selectAll().where('id', '=', sessionId).forUpdate().executeTakeFirstOrThrow();
    if (s.status === 'COMPLETED' || s.status === 'CANCELLED') return [];
    const rows = await tx.selectFrom('session_members').selectAll().where('session_id', '=', sessionId).execute();
    const day = s.session_day;
    const base = s.duration_min === 25 ? cfg.coins25 : cfg.coins50;
    const out: MemberResult[] = [];

    for (const r of rows) {
      let coins = 0;
      let capReached = false;
      let broken = false;
      const rewarded = r.state === 'COMPLETED' && !s.forfeited; // "hoàn thành có thưởng" (D-11)

      if (r.state === 'COMPLETED') {
        // BR-46: điểm danh kể cả phiên forfeited; tối đa 1/ngày (PK user, day)
        await tx.insertInto('daily_attendance')
          .values({ user_id: r.user_id, day, group_id: s.group_id, first_session_id: s.id, focus_minutes: Math.floor(r.focus_seconds / 60) })
          .onConflict((oc) => oc.columns(['user_id', 'day']).doUpdateSet({
            sessions_completed: sql`daily_attendance.sessions_completed + 1`,
            focus_minutes: sql`daily_attendance.focus_minutes + ${Math.floor(r.focus_seconds / 60)}`,
          }))
          .execute();
      }

      if (rewarded) {
        // BR-43: trần ngày; khóa dòng users để tuần tự theo người (trigger cũng kiểm)
        await tx.selectFrom('users').select('id').where('id', '=', r.user_id).forUpdate().execute();
        const daySum = await tx.selectFrom('coin_ledger').select((eb) => eb.fn.coalesce(eb.fn.sum<string>('amount'), sql<string>`0`).as('s'))
          .where('user_id', '=', r.user_id).where('type', '=', 'SESSION_REWARD').where('reward_date', '=', day).executeTakeFirstOrThrow();
        const remaining = Math.max(0, cfg.coinsDailyCap - Number(daySum.s));
        coins = Math.min(base, remaining);
        capReached = coins < base;
        if (coins > 0) {
          await tx.insertInto('coin_ledger').values({
            user_id: r.user_id, amount: coins, type: 'SESSION_REWARD', ref_id: s.id, reward_date: day,
            reason: 'SESSION_COMPLETE', idempotency_key: `SESSION_REWARD:${s.id}:${r.user_id}`, balance_after: 0, created_by: null,
          }).onConflict((oc) => oc.column('idempotency_key').doNothing()).execute();
        }
        await tx.updateTable('session_members').set({ coins_awarded: coins }).where('session_id', '=', s.id).where('user_id', '=', r.user_id).execute();
        // BR-49: chuỗi +1 tối đa 1 lần/ngày
        const u = await tx.selectFrom('users').select(['current_streak', 'streak_last_inc_day']).where('id', '=', r.user_id).executeTakeFirstOrThrow();
        if (u.streak_last_inc_day !== day) {
          const next = u.current_streak + 1;
          await tx.updateTable('users')
            .set({ current_streak: next, longest_streak: sql`GREATEST(longest_streak, ${next})`, streak_last_inc_day: day })
            .where('id', '=', r.user_id).execute();
          await tx.insertInto('achievement_log').values({
            user_id: r.user_id, kind: 'STREAK_INC', value_before: u.current_streak, value_after: next, day,
            ref_session_id: s.id, ref_badge_id: null, reason: 'SESSION_REWARDED',
          }).onConflict((oc) => oc.doNothing()).execute();
        }
      } else if (s.forfeited && (r.state === 'COMPLETED' || r.state === 'LOST')) {
        // BR-37/BR-47(b): phạm vi forfeited bị ngắt chuỗi tại ends_at (EXITED đã ngắt lúc thoát)
        await breakStreak(tx, r.user_id, day, s.id, 'SESSION_FORFEITED');
        broken = true;
      } else if (s.forfeited && s.forfeited_at && r.state === 'WITHDRAWN' && r.end_reason === 'CONSENT_WITHDRAWN'
        && r.ended_at && r.ended_at.getTime() >= s.forfeited_at.getTime()) {
        // D-23/BR-37: rút đồng ý từ forfeited_at trở đi vẫn bị ngắt chuỗi (đúng mốc = "sau"); rút trước không ảnh hưởng
        await breakStreak(tx, r.user_id, day, s.id, 'WITHDRAWN_AFTER_FORFEIT');
        broken = true;
      }
      if (r.state === 'EXITED') broken = true;

      const newBadges = r.state === 'COMPLETED' ? await awardBadges(tx, r.user_id, day, s.id) : [];
      const u2 = await tx.selectFrom('users').select('current_streak').where('id', '=', r.user_id).executeTakeFirstOrThrow();
      out.push({ user_id: r.user_id, state: r.state, coins_awarded: coins, reward_cap_reached: capReached, streak_after: u2.current_streak, streak_broken: broken, focus_seconds: r.focus_seconds, new_badges: newBadges });
    }

    await tx.updateTable('sessions').set({ status: 'COMPLETED', completed_at: new Date() }).where('id', '=', s.id).execute();
    return out;
  });
}
