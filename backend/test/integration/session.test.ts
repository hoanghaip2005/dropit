import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { randomUUID } from 'node:crypto';
import { startServer, emit, sleep, waitFor, findSensitiveKeys, type TestServer } from './helpers.js';

let t: TestServer;
beforeAll(async () => {
  t = await startServer(); // grace 300ms, countdown 300ms, 1 "phút" = 60ms → phiên 25' = 1,5s
});
afterAll(async () => t?.close());

const status = async (sid: string) =>
  (await t.db.selectFrom('sessions').select(['status', 'forfeited', 'forfeit_trigger_user_id']).where('id', '=', sid).executeTakeFirstOrThrow());
const finished = (sid: string) => waitFor(async () => ['COMPLETED', 'CANCELLED'].includes((await status(sid)).status) && t.srv.ctx.sessions.runtimes.get(sid) === undefined, 15000);
const rows = (sid: string) => t.db.selectFrom('session_members').selectAll().where('session_id', '=', sid).execute();

describe('Phiên thời gian thực end-to-end (EP-03, D-05, D-09)', () => {
  it('một người rời app > 3s (khoan hồng) → EXITED, cả phiên mất thưởng, MEMBER_EXITED có tên tới nhóm + chủ nhóm', async () => {
    const { owner, members, groupId } = await t.groupWith(3);
    const sid = await t.schedule(owner.token, groupId);
    await waitFor(() => t.srv.ctx.sessions.runtimes.has(sid));
    const ownerSock = await t.sock(owner.token);
    const socks = await Promise.all(members.map((m) => t.sock(m.token)));
    // chủ nhóm không vào phiên được (D-25, BR-114)
    expect(await emit(ownerSock, 'session:join', { session_id: sid })).toMatchObject({ ok: false, code: 'OWNER_CANNOT_JOIN_SESSION' });
    for (const s of socks) expect(await emit(s, 'session:join', { session_id: sid })).toMatchObject({ ok: true, state: 'WAITING' });

    await waitFor(async () => (await status(sid)).status === 'ACTIVE');
    await waitFor(() => socks[0].events.some((e) => e.type === 'member:state' && e.payload.my_state === 'FOCUSING'));
    // An rời app quá hạn khoan hồng
    expect(await emit(socks[0], 'member:left_app', { session_id: sid })).toMatchObject({ ok: true, state: 'GRACE' });
    await sleep(450);
    const late = await emit(socks[0], 'member:returned', { session_id: sid });
    expect(late.state).toBe('EXITED');

    // Bình, Chi nhận MEMBER_EXITED có tên + forfeited; chủ nhóm nhận qua room user:{id}
    for (const s of [socks[1], socks[2], ownerSock]) {
      const ev = await waitFor(() => s.events.find((e) => e.type === 'MEMBER_EXITED'));
      expect(ev.payload).toMatchObject({ exited_display_name: 'An', group_id: groupId, session_id: sid, forfeited: { display_name: 'An' } });
      expect(findSensitiveKeys(ev.payload)).toEqual([]);
    }
    expect(socks[0].events.some((e) => e.type === 'MEMBER_EXITED')).toBe(false); // trừ người thoát

    await finished(sid);
    const s = await status(sid);
    expect(s).toMatchObject({ status: 'COMPLETED', forfeited: true, forfeit_trigger_user_id: members[0].id });
    const r = await rows(sid);
    const by = (u: string) => r.find((x) => x.user_id === u)!;
    expect(by(members[0].id)).toMatchObject({ state: 'EXITED', end_reason: 'GRACE_EXPIRED', coins_awarded: 0 });
    expect(by(members[1].id)).toMatchObject({ state: 'COMPLETED', coins_awarded: 0 });
    expect(by(members[2].id)).toMatchObject({ state: 'COMPLETED', coins_awarded: 0 });
    // BR-41: không ghi dòng sổ cái nào
    const ledger = await t.db.selectFrom('coin_ledger').select('entry_id').where('ref_id', '=', sid).execute();
    expect(ledger).toHaveLength(0);
    // BR-46: điểm danh kể cả phiên forfeited; BR-47: ngắt chuỗi cho phạm vi BR-37
    const att = await t.db.selectFrom('daily_attendance').select('user_id').where('first_session_id', '=', sid).execute();
    expect(att.map((a) => a.user_id).sort()).toEqual([members[1].id, members[2].id].sort());
    const breaks = await t.db.selectFrom('achievement_log').select('user_id').where('ref_session_id', '=', sid).where('kind', '=', 'STREAK_BREAK').execute();
    expect(new Set(breaks.map((b) => b.user_id))).toEqual(new Set(members.map((m) => m.id)));

    // Hộp thông báo: chủ nhóm + Bình + Chi có MEMBER_EXITED, An không
    const inbox = await t.api('GET', '/v1/me/notifications', owner.token);
    expect(inbox.body.items.find((n: { type: string }) => n.type === 'MEMBER_EXITED').body).toContain('An đã rời phiên');
    const anInbox = await t.api('GET', '/v1/me/notifications', members[0].token);
    expect(anInbox.body.items.some((n: { type: string }) => n.type === 'MEMBER_EXITED')).toBe(false);

    // Kết quả của tôi (có Coins/chuỗi) vs chi tiết của chủ nhóm (không Coins/chuỗi, BR-116)
    const mine = await t.api('GET', `/v1/sessions/${sid}/result`, members[1].token);
    expect(mine.body).toMatchObject({ final_state: 'COMPLETED', forfeited: true, forfeit_trigger_display_name: 'An', coins_awarded: 0, streak_broken: true });
    expect(mine.body.participants.map((p: { display_name: string }) => p.display_name)).toEqual(['An', 'Bình', 'Chi']);
    const od = await t.api('GET', `/v1/sessions/${sid}/owner-detail`, owner.token);
    expect(od.status).toBe(200);
    expect(od.body.members).toHaveLength(3);
    expect(od.body.exit_events).toEqual([expect.objectContaining({ display_name: 'An' })]);
    expect(od.body.forfeit_trigger_display_name).toBe('An');
    expect(findSensitiveKeys(od.body)).toEqual([]);
    expect((await t.api('GET', `/v1/sessions/${sid}/owner-detail`, members[1].token)).body.code).toBe('NOT_GROUP_OWNER');
    expect((await t.api('GET', `/v1/sessions/${sid}/result`, owner.token)).body.code).toBe('OWNER_CANNOT_JOIN_SESSION');
    const al = await t.db.selectFrom('access_logs').select('subject_user_id').where('object_id', '=', sid).execute();
    expect(al.length).toBe(3); // P12 / BR-73

    for (const s of [...socks, ownerSock]) s.close();
  });

  it('mọi người hoàn thành → mỗi người +10 Coins (25 phút), chuỗi +1, trần 100/ngày cắt phần dư (D-09, BR-43)', async () => {
    const { owner, members, groupId } = await t.groupWith(3);
    // Dũng đã có 95 Coins thưởng hôm nay → phiên này chỉ còn 5
    const day = new Date(Date.now() + 7 * 3600e3 + 5000).toISOString().slice(0, 10);
    await t.db.insertInto('coin_ledger').values({
      user_id: members[2].id, amount: 95, type: 'SESSION_REWARD', ref_id: randomUUID(), reward_date: day,
      reason: 'SEED_TEST', idempotency_key: `seed:${randomUUID()}`, balance_after: 0, created_by: null,
    }).execute();
    const sid = await t.schedule(owner.token, groupId);
    await waitFor(() => t.srv.ctx.sessions.runtimes.has(sid));
    const socks = await Promise.all(members.map((m) => t.sock(m.token)));
    for (const s of socks) await emit(s, 'session:join', { session_id: sid });
    await waitFor(async () => (await status(sid)).status === 'ACTIVE');
    // khóa màn hình không phạt (BR-15)
    await emit(socks[0], 'member:screen_locked', { session_id: sid });
    // rời app rồi quay lại trong 3s → không phạt (BR-12)
    await emit(socks[1], 'member:left_app', { session_id: sid });
    await sleep(100);
    expect((await emit(socks[1], 'member:returned', { session_id: sid })).state).toBe('FOCUSING');
    await emit(socks[0], 'member:screen_unlocked', { session_id: sid });

    await finished(sid);
    expect((await status(sid))).toMatchObject({ status: 'COMPLETED', forfeited: false });
    const r = await rows(sid);
    expect(r.map((x) => x.state)).toEqual(['COMPLETED', 'COMPLETED', 'COMPLETED']);
    const coinsOf = (u: string) => r.find((x) => x.user_id === u)!.coins_awarded;
    expect([coinsOf(members[0].id), coinsOf(members[1].id), coinsOf(members[2].id)]).toEqual([10, 10, 5]);

    const c0 = await t.api('GET', '/v1/me/coins', members[0].token);
    expect(c0.body.balance).toBe(10);
    expect(c0.body.items[0]).toMatchObject({ amount: 10, type: 'SESSION_REWARD', ref_id: sid, reason: 'SESSION_COMPLETE', balance_after: 10 });
    const c2 = await t.api('GET', '/v1/me/coins', members[2].token);
    expect(c2.body.balance).toBe(100);
    const res2 = await t.api('GET', `/v1/sessions/${sid}/result`, members[2].token);
    expect(res2.body).toMatchObject({ coins_awarded: 5, reward_cap_reached: true, streak_after: 1, streak_broken: false });
    const me0 = await t.api('GET', '/v1/me', members[0].token);
    expect(me0.body).toMatchObject({ coins_balance: 10, current_streak: 1, longest_streak: 1 });
    // SESSION_RESULT qua socket cho chính người đó
    const sr = await waitFor(() => socks[0].events.find((e) => e.type === 'SESSION_RESULT'));
    expect(sr.payload).toMatchObject({ final_state: 'COMPLETED', coins_awarded: 10 });
    // Chủ nhóm không nhận Coins/chuỗi (BR-116)
    const meOwner = await t.api('GET', '/v1/me', owner.token);
    expect(meOwner.body).toMatchObject({ coins_balance: 0, current_streak: 0, longest_streak: 0 });
    expect((await t.api('GET', '/v1/me/coins', owner.token)).body.balance).toBe(0);
    // Chủ nhóm: không có trường Coins/chuỗi ở mọi API của chủ nhóm
    for (const path of [`/v1/sessions/${sid}/owner-detail`, `/v1/groups/${groupId}/members`, `/v1/groups/${groupId}`, `/v1/sessions/${sid}`])
      expect(findSensitiveKeys((await t.api('GET', path, owner.token)).body)).toEqual([]);
    for (const s of socks) s.close();
  });

  it('mất kết nối quá hạn → LOST, KHÔNG forfeited, người khác vẫn nhận thưởng (D-19); session:leave ở phòng chờ → ABSENT (BR-118)', async () => {
    const { owner, members, groupId } = await t.groupWith(4);
    const sid = await t.schedule(owner.token, groupId);
    await waitFor(() => t.srv.ctx.sessions.runtimes.has(sid));
    const socks = await Promise.all(members.slice(0, 3).map((m) => t.sock(m.token)));
    for (const s of socks) await emit(s, 'session:join', { session_id: sid });
    // Chi bấm "Rời phiên" ở phòng chờ
    expect(await emit(socks[2], 'session:leave', { session_id: sid })).toMatchObject({ ok: true, state: 'ABSENT' });
    // event_id trùng → ack cũ, duplicate (BR-31)
    const eid = randomUUID();
    const a1 = await socks[1].timeout(5000).emitWithAck('member:screen_locked', { event_id: eid, session_id: sid });
    const a2 = await socks[1].timeout(5000).emitWithAck('member:screen_locked', { event_id: eid, session_id: sid });
    expect(a2).toMatchObject({ ok: true, duplicate: true, state: a1.state });
    await emit(socks[1], 'member:screen_unlocked', { session_id: sid });

    await waitFor(async () => (await status(sid)).status === 'ACTIVE');
    await sleep(100);
    socks[0].disconnect(); // An mất mạng, không nối lại
    await finished(sid);
    const r = await rows(sid);
    const by = (u: string) => r.find((x) => x.user_id === u)!;
    expect(by(members[0].id)).toMatchObject({ state: 'LOST', end_reason: 'DISCONNECT_TIMEOUT', coins_awarded: 0 });
    expect(by(members[1].id)).toMatchObject({ state: 'COMPLETED', coins_awarded: 10 });
    expect(by(members[2].id)).toMatchObject({ state: 'ABSENT', end_reason: 'LOBBY_LEAVE' });
    expect(by(members[3].id)).toMatchObject({ state: 'ABSENT', end_reason: 'NO_SHOW' }); // DQ-F01 + BR-08
    expect((await status(sid)).forfeited).toBe(false);
    const exitedNoti = await t.db.selectFrom('notifications').select('id').where('type', '=', 'MEMBER_EXITED').where('user_id', '=', owner.id).execute();
    expect(exitedNoti).toHaveLength(0); // LOST không báo ai
    for (const s of socks) s.close();
  });

  it('nối lại trong hạn giữ chỗ bằng session:resume cùng device → FOCUSING; thiết bị khác bị từ chối (DQ-A07)', async () => {
    const { owner, members, groupId } = await t.groupWith(1);
    const sid = await t.schedule(owner.token, groupId);
    await waitFor(() => t.srv.ctx.sessions.runtimes.has(sid));
    const s1 = await t.sock(members[0].token, 'device-1');
    await emit(s1, 'session:join', { session_id: sid });
    await waitFor(async () => (await status(sid)).status === 'ACTIVE');
    s1.disconnect();
    await sleep(80);
    const other = await t.sock(members[0].token, 'device-2');
    expect(await emit(other, 'session:resume', { session_id: sid })).toMatchObject({ ok: false, code: 'SESSION_ALREADY_JOINED_ELSEWHERE' });
    const s2 = await t.sock(members[0].token, 'device-1');
    expect(await emit(s2, 'session:resume', { session_id: sid })).toMatchObject({ ok: true, state: 'FOCUSING' });
    await finished(sid);
    const r = await rows(sid);
    expect(r[0]).toMatchObject({ state: 'COMPLETED', coins_awarded: 10 });
    other.close();
    s2.close();
  });

  it('không ai vào phòng chờ → mọi người ABSENT rồi phiên CANCELLED NO_ATTENDEE (BR-30)', async () => {
    const { owner, groupId } = await t.groupWith(2);
    const sid = await t.schedule(owner.token, groupId);
    await finished(sid);
    const s = await t.db.selectFrom('sessions').select(['status', 'cancel_reason']).where('id', '=', sid).executeTakeFirstOrThrow();
    expect(s).toEqual({ status: 'CANCELLED', cancel_reason: 'NO_ATTENDEE' });
    expect((await rows(sid)).map((x) => x.state)).toEqual(['ABSENT', 'ABSENT']);
  });
});
