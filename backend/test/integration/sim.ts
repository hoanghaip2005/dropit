// Dựng nhanh một phiên đã diễn ra (không qua socket): chèn phiên ACTIVE + trạng thái cuối, ngắt chuỗi/MEMBER_EXITED
// như manager làm lúc EXITED, rồi chốt bằng finalizeSession thật (Coins/điểm danh/chuỗi/huy hiệu).
import type { TestServer } from './helpers.js';
import { finalizeSession, breakStreak } from '../../src/modules/rewards/service.js';
import { vnDay } from '../../src/shared/time.js';

export type SimMember = { id: string; state: 'COMPLETED' | 'EXITED' | 'LOST' | 'ABSENT'; exitAtMin?: number; name?: string };

export async function simulateSession(t: TestServer, o: { groupId: string; ownerId: string; startedAt: Date; duration?: 25 | 50; members: SimMember[] }) {
  const db = t.db;
  const dur = o.duration ?? 25;
  const st = new Date(Math.floor(o.startedAt.getTime() / 1000) * 1000);
  const ends = new Date(st.getTime() + dur * 60000);
  const day = vnDay(st);
  const exits = o.members.filter((m) => m.state === 'EXITED').map((m) => ({ ...m, at: new Date(st.getTime() + (m.exitAtMin ?? 5) * 60000) }))
    .sort((a, b) => a.at.getTime() - b.at.getTime());
  const s = await db.insertInto('sessions').values({
    group_id: o.groupId, schedule_id: null, duration_min: dur, started_at: st, ends_at: ends, session_day: day, status: 'ACTIVE',
    forfeited: exits.length > 0, forfeited_at: exits[0]?.at ?? null, forfeit_trigger_user_id: exits[0]?.id ?? null,
    cancel_reason: null, cancelled_at: null, completed_at: null, created_by: o.ownerId,
  }).returning('id').executeTakeFirstOrThrow();
  for (const m of o.members) {
    const ex = exits.find((e) => e.id === m.id);
    const end = ex ? ex.at : m.state === 'LOST' ? new Date(st.getTime() + 10 * 60000) : m.state === 'ABSENT' ? st : ends;
    const focus = m.state === 'ABSENT' ? 0 : Math.round((end.getTime() - st.getTime()) / 1000);
    await db.insertInto('session_members').values({
      session_id: s.id, user_id: m.id, state: m.state,
      end_reason: m.state === 'COMPLETED' ? 'TIME_UP' : m.state === 'EXITED' ? 'GRACE_EXPIRED' : m.state === 'LOST' ? 'DISCONNECT_TIMEOUT' : 'NO_SHOW',
      joined_at: m.state === 'ABSENT' ? null : new Date(st.getTime() - 60000), exited_at: ex ? ex.at : null, ended_at: end, focus_seconds: focus,
    }).execute();
  }
  const members = await db.selectFrom('group_members').select('user_id').where('group_id', '=', o.groupId).where('left_at', 'is', null).execute();
  for (const ex of exits) {
    await breakStreak(db, ex.id, day, s.id, 'EXITED');
    const rec = [o.ownerId, ...members.map((m) => m.user_id)].filter((u) => u !== ex.id);
    await t.srv.ctx.notifications.saveInbox(rec, {
      type: 'MEMBER_EXITED', title: 'Nhóm', body: `${ex.name ?? 'Ai đó'} đã rời phiên.`,
      data: { session_id: s.id, group_id: o.groupId, exited_display_name: ex.name ?? '', exited_user_id: ex.id, forfeited: true },
      dedupeKey: `sim-exit-${s.id}-${ex.id}`,
    });
  }
  const results = await finalizeSession(db, t.cfg.engine, s.id);
  return { sessionId: s.id, day, results, endsAt: ends };
}

/** Thời điểm quá khứ riêng cho mỗi lần gọi để không chồng phiên trong nhóm (BR-78). */
export function pastSlots(startMinAgo = 600) {
  let k = 0;
  return () => new Date(Date.now() - (startMinAgo - 30 * k++) * 60000);
}
