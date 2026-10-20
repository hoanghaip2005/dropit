import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { randomUUID } from 'node:crypto';
import { startServer, findSensitiveKeys, type TestServer } from './helpers.js';
import { simulateSession, pastSlots } from './sim.js';

let t: TestServer;
const slot = pastSlots(900);
beforeAll(async () => {
  t = await startServer();
});
afterAll(async () => t?.close());

const ledger = (uid: string, sid: string) => t.db.selectFrom('coin_ledger').selectAll().where('user_id', '=', uid).where('ref_id', '=', sid).execute();
const streak = async (uid: string) => (await t.db.selectFrom('users').select(['current_streak', 'longest_streak']).where('id', '=', uid).executeTakeFirstOrThrow());

describe('Lịch sử phiên của tôi (US-03.14)', () => {
  it('liệt kê mới nhất trước, phân trang, có Coins của chính mình; chủ nhóm/khác nhóm bị chặn', async () => {
    const { owner, members, groupId } = await t.groupWith(3);
    const [a, b, c] = members;
    const s1 = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: [{ id: a.id, state: 'COMPLETED' }, { id: b.id, state: 'COMPLETED' }, { id: c.id, state: 'ABSENT' }] });
    const s2 = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: [{ id: a.id, state: 'COMPLETED' }, { id: b.id, state: 'EXITED', name: 'Bình' }, { id: c.id, state: 'COMPLETED' }] });
    const p1 = await t.api('GET', '/v1/me/sessions?limit=1', a.token);
    expect(p1.status).toBe(200);
    expect(p1.body.items).toHaveLength(1);
    expect(p1.body.items[0]).toMatchObject({ session_id: s2.sessionId, final_state: 'COMPLETED', forfeited: true, forfeit_trigger_display_name: 'Bình', coins_awarded: 0 });
    expect(p1.body.next_cursor).toBeTruthy();
    const p2 = await t.api('GET', `/v1/me/sessions?limit=1&cursor=${p1.body.next_cursor}`, a.token);
    expect(p2.body.items[0]).toMatchObject({ session_id: s1.sessionId, final_state: 'COMPLETED', coins_awarded: 10, forfeited: false });
    expect(p2.body.next_cursor).toBeNull();
    // chi tiết (bí danh /result) + quyền
    const d = await t.api('GET', `/v1/me/sessions/${s2.sessionId}`, b.token);
    expect(d.body).toMatchObject({ final_state: 'EXITED', can_explain: true, can_appeal: true, streak_broken: true });
    expect((await t.api('GET', `/v1/me/sessions/${s2.sessionId}`, owner.token)).body.code).toBe('OWNER_CANNOT_JOIN_SESSION');
    const stranger = await t.user('Lạ');
    expect((await t.api('GET', `/v1/me/sessions/${s2.sessionId}`, stranger.token)).status).toBe(403);
    expect((await t.api('GET', '/v1/me/sessions', stranger.token)).body.items).toEqual([]);
    expect((await t.api('GET', '/v1/me/sessions', owner.token)).body.items).toEqual([]); // chủ nhóm không có phiên (D-25)
  });
});

describe('Hộp thông báo (US-04.01)', () => {
  it('danh sách mới nhất trước + unread_count; đánh dấu theo ids, up_to, tất cả; không đụng của người khác', async () => {
    const { owner, members, groupId } = await t.groupWith(2);
    for (let i = 0; i < 3; i++)
      await t.srv.ctx.notifications.saveInbox([owner.id, members[0].id], { type: 'SESSION_REMINDER', title: `T${i}`, body: `b${i}`, data: { group_id: groupId }, dedupeKey: `n-${randomUUID()}` });
    const l = await t.api('GET', '/v1/me/notifications?limit=2', owner.token);
    expect(l.body.unread_count).toBe(3);
    expect(l.body.items.map((n: { title: string }) => n.title)).toEqual(['T2', 'T1']);
    expect(l.body.items[0]).toMatchObject({ read: false, group_id: groupId });
    const more = await t.api('GET', `/v1/me/notifications?limit=2&cursor=${l.body.next_cursor}`, owner.token);
    expect(more.body.items.map((n: { title: string }) => n.title)).toEqual(['T0']);
    // An cố đánh dấu id của chủ nhóm → không ảnh hưởng
    expect((await t.api('POST', '/v1/me/notifications/read', members[0].token, { ids: [l.body.items[0].notification_id] })).status).toBe(204);
    expect((await t.api('GET', '/v1/me/notifications', owner.token)).body.unread_count).toBe(3);
    await t.api('POST', '/v1/me/notifications/read', owner.token, { ids: [l.body.items[0].notification_id] });
    expect((await t.api('GET', '/v1/me/notifications', owner.token)).body.unread_count).toBe(2);
    await t.api('POST', '/v1/me/notifications/read', owner.token, { up_to: more.body.items[0].server_ts });
    expect((await t.api('GET', '/v1/me/notifications', owner.token)).body.unread_count).toBe(1);
    await t.api('POST', '/v1/me/notifications/read', owner.token, {});
    expect((await t.api('GET', '/v1/me/notifications', owner.token)).body.unread_count).toBe(0);
    expect((await t.api('GET', '/v1/me/notifications', members[0].token)).body.unread_count).toBe(3);
  });
});

describe('Giải trình (US-04.05/04.06, BR-85)', () => {
  it('EXITED gửi/sửa; chủ nhóm xem (ghi access_logs); người khác 403; hết hạn 409', async () => {
    const { owner, members, groupId } = await t.groupWith(3);
    const [a, b] = members;
    const s = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: [{ id: a.id, state: 'EXITED', name: 'An' }, { id: b.id, state: 'COMPLETED' }, { id: members[2].id, state: 'COMPLETED' }] });
    const put = await t.api('PUT', `/v1/sessions/${s.sessionId}/explanation`, a.token, { body: 'Có cuộc gọi khẩn của sếp' });
    expect(put.status).toBe(200);
    expect(put.body).toMatchObject({ user_id: a.id, display_name: 'An', body: 'Có cuộc gọi khẩn của sếp', added_after_report: false });
    // sửa với If-Match sai → VERSION_CONFLICT; đúng → OK
    const bad = await fetch(`${(t.srv.app.server.address() as { port: number }).port ? `http://127.0.0.1:${(t.srv.app.server.address() as { port: number }).port}` : ''}/v1/sessions/${s.sessionId}/explanation`, {
      method: 'PUT', headers: { authorization: `Bearer ${a.token}`, 'content-type': 'application/json', 'if-match': '"1"' }, body: JSON.stringify({ body: 'x' }),
    });
    expect((await bad.json()).code).toBe('VERSION_CONFLICT');
    const edit = await t.api('PUT', `/v1/sessions/${s.sessionId}/explanation`, a.token, { body: 'Sửa: cuộc gọi khẩn' });
    expect(edit.body.body).toBe('Sửa: cuộc gọi khẩn');
    // chủ nhóm nhận thông báo trong app
    const inbox = await t.api('GET', '/v1/me/notifications', owner.token);
    expect(inbox.body.items.some((n: { type: string }) => n.type === 'EXPLANATION_SUBMITTED')).toBe(true);
    // COMPLETED / người ngoài / chủ nhóm không gửi được
    expect((await t.api('PUT', `/v1/sessions/${s.sessionId}/explanation`, b.token, { body: 'x' })).body.code).toBe('NOT_EXITED_IN_SESSION');
    const stranger = await t.user('Lạ');
    expect((await t.api('PUT', `/v1/sessions/${s.sessionId}/explanation`, stranger.token, { body: 'x' })).body.code).toBe('FORBIDDEN_GROUP');
    expect((await t.api('PUT', `/v1/sessions/${s.sessionId}/explanation`, a.token, { body: 'x'.repeat(501) })).status).toBe(422);
    // chủ nhóm xem; thành viên/chủ nhóm khác bị chặn
    const list = await t.api('GET', `/v1/sessions/${s.sessionId}/explanations`, owner.token);
    expect(list.status).toBe(200);
    expect(list.body.items).toEqual([expect.objectContaining({ display_name: 'An', body: 'Sửa: cuộc gọi khẩn' })]);
    expect(findSensitiveKeys(list.body)).toEqual([]);
    const al = await t.db.selectFrom('access_logs').select('object_type').where('object_id', '=', s.sessionId).where('subject_user_id', '=', a.id).execute();
    expect(al.map((x) => x.object_type)).toContain('EXPLANATION');
    expect((await t.api('GET', `/v1/sessions/${s.sessionId}/explanations`, b.token)).body.code).toBe('NOT_GROUP_OWNER');
    const other = await t.groupWith(0, 'Chủ khác');
    expect((await t.api('GET', `/v1/sessions/${s.sessionId}/explanations`, other.owner.token)).body.code).toBe('FORBIDDEN_GROUP');
    // quá 24 giờ kể từ lần gửi đầu → không sửa được
    await t.db.updateTable('explanations').set({ created_at: new Date(Date.now() - 25 * 3600e3) }).where('session_id', '=', s.sessionId).execute();
    expect((await t.api('PUT', `/v1/sessions/${s.sessionId}/explanation`, a.token, { body: 'muộn' })).body.code).toBe('EXPLANATION_WINDOW_CLOSED');
  });

  it('gửi mới sau ends_at + 7 ngày → EXPLANATION_WINDOW_CLOSED', async () => {
    const { owner, members, groupId } = await t.groupWith(2);
    const s = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: new Date(Date.now() - 8 * 86400e3), members: [{ id: members[0].id, state: 'EXITED' }, { id: members[1].id, state: 'COMPLETED' }] });
    expect((await t.api('PUT', `/v1/sessions/${s.sessionId}/explanation`, members[0].token, { body: 'muộn' })).body.code).toBe('EXPLANATION_WINDOW_CLOSED');
    expect((await t.api('POST', `/v1/sessions/${s.sessionId}/appeals`, members[0].token, { body: 'muộn' })).body.code).toBe('APPEAL_WINDOW_CLOSED');
  });
});

describe('Khiếu nại (US-04.07/04.08, BR-86…BR-88)', () => {
  it('miễn trừ người duy nhất rời → gỡ forfeited, bù SESSION_REWARD (APPEAL_RESTORE) theo trần ngày, khôi phục chuỗi, EXEMPTION_GRANTED 2 bản', async () => {
    const { owner, members, groupId } = await t.groupWith(3);
    const [a, b, c] = members;
    // Chi đã có 95 Coins thưởng trong ngày của phiên → chỉ được bù 5 (BR-43 của ngày phiên)
    const start = slot();
    const { vnDay } = await import('../../src/shared/time.js');
    await t.db.insertInto('coin_ledger').values({
      user_id: c.id, amount: 95, type: 'SESSION_REWARD', ref_id: randomUUID(), reward_date: vnDay(start), reason: 'SEED_TEST',
      idempotency_key: `seed:${randomUUID()}`, balance_after: 0, created_by: null,
    }).execute();
    const s = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: start, members: [{ id: a.id, state: 'EXITED', name: 'An' }, { id: b.id, state: 'COMPLETED' }, { id: c.id, state: 'COMPLETED' }] });
    expect(await ledger(b.id, s.sessionId)).toHaveLength(0);
    expect((await streak(b.id)).current_streak).toBe(0);

    const idem = randomUUID();
    const ap = await t.api('POST', `/v1/sessions/${s.sessionId}/appeals`, a.token, { body: 'Máy tự khóa, tôi không rời app' }, idem);
    expect(ap.status).toBe(201);
    expect(ap.body).toMatchObject({ status: 'PENDING', suspect_system_error: false, decided_at: null });
    const replay = await t.api('POST', `/v1/sessions/${s.sessionId}/appeals`, a.token, { body: 'Máy tự khóa, tôi không rời app' }, idem);
    expect(replay.status).toBe(201);
    expect(replay.headers.get('idempotent-replayed')).toBe('true');
    expect((await t.api('POST', `/v1/sessions/${s.sessionId}/appeals`, a.token, { body: 'lần 2' })).body.code).toBe('APPEAL_EXISTS');
    expect((await t.api('POST', `/v1/sessions/${s.sessionId}/appeals`, b.token, { body: 'x' })).body.code).toBe('NOT_EXITED_IN_SESSION');
    // chủ nhóm có thông báo kèm appeal_id
    const inbox = await t.api('GET', '/v1/me/notifications', owner.token);
    expect(inbox.body.items.find((n: { type: string }) => n.type === 'APPEAL_CREATED').data.appeal_id).toBe(ap.body.appeal_id);

    // quyền quyết định: thành viên / chủ nhóm khác / thiếu lý do
    expect((await t.api('POST', `/v1/appeals/${ap.body.appeal_id}/decision`, b.token, { decision: 'EXEMPT', decision_reason: 'x' })).body.code).toBe('NOT_GROUP_OWNER');
    expect((await t.api('POST', `/v1/appeals/${ap.body.appeal_id}/decision`, a.token, { decision: 'EXEMPT', decision_reason: 'x' })).body.code).toBe('NOT_GROUP_OWNER');
    const other = await t.groupWith(0, 'Chủ khác');
    expect((await t.api('POST', `/v1/appeals/${ap.body.appeal_id}/decision`, other.owner.token, { decision: 'EXEMPT', decision_reason: 'x' })).body.code).toBe('FORBIDDEN_GROUP');
    expect((await t.api('POST', `/v1/appeals/${ap.body.appeal_id}/decision`, owner.token, { decision: 'EXEMPT' })).body.code).toBe('VALIDATION_FAILED');

    // chủ nhóm mở ca → ĐANG XỬ LÝ + access_logs
    const open = await t.api('GET', `/v1/appeals/${ap.body.appeal_id}`, owner.token);
    expect(open.body).toMatchObject({ status: 'IN_REVIEW', display_name: 'An' });
    expect(findSensitiveKeys(open.body)).toEqual([]);

    const dec = await t.api('POST', `/v1/appeals/${ap.body.appeal_id}/decision`, owner.token, { decision: 'EXEMPT', decision_reason: 'Xác nhận lỗi máy' });
    expect(dec.status).toBe(200);
    expect(dec.body).toMatchObject({ status: 'EXEMPTED', decision_reason: 'Xác nhận lỗi máy' });
    expect(dec.body.decided_at).toBeTruthy();

    const sess = await t.db.selectFrom('sessions').select(['forfeited', 'forfeited_at', 'forfeit_trigger_user_id']).where('id', '=', s.sessionId).executeTakeFirstOrThrow();
    expect(sess).toEqual({ forfeited: false, forfeited_at: null, forfeit_trigger_user_id: null });
    // Coins bù (BR-88): An (miễn trừ, như COMPLETED) 10, Bình 10, Chi 5 do trần ngày
    for (const [u, amt] of [[a.id, 10], [b.id, 10], [c.id, 5]] as const) {
      const l = await ledger(u, s.sessionId);
      expect(l).toEqual([expect.objectContaining({ type: 'SESSION_REWARD', amount: amt, reason: 'APPEAL_RESTORE', reward_date: s.day })]);
    }
    // chuỗi khôi phục như thể không ngắt
    expect((await streak(a.id)).current_streak).toBe(1);
    expect((await streak(b.id)).current_streak).toBe(1);
    const restoreLog = await t.db.selectFrom('achievement_log').select('kind').where('user_id', '=', b.id).where('ref_session_id', '=', s.sessionId).where('kind', '=', 'STREAK_RESTORE').execute();
    expect(restoreLog).toHaveLength(1);
    // kết quả của tôi phản ánh miễn trừ
    const mine = await t.api('GET', `/v1/sessions/${s.sessionId}/result`, a.token);
    expect(mine.body).toMatchObject({ exempted: true, forfeited: false, coins_awarded: 10, can_appeal: false, streak_broken: false });
    // điểm danh cho người được miễn trừ (Q-124)
    expect(await t.db.selectFrom('daily_attendance').select('day').where('user_id', '=', a.id).where('day', '=', s.day).executeTakeFirst()).toBeTruthy();

    // EXEMPTION_GRANTED: An có coins_refunded; chủ nhóm + Bình + Chi nhận bản đính chính KHÔNG Coins
    const aIn = await t.api('GET', '/v1/me/notifications', a.token);
    const own = aIn.body.items.find((n: { type: string }) => n.type === 'EXEMPTION_GRANTED');
    expect(own.data).toMatchObject({ coins_refunded: 10, appeal_id: ap.body.appeal_id });
    for (const u of [owner, b, c]) {
      const n = (await t.api('GET', '/v1/me/notifications', u.token)).body.items.find((x: { type: string }) => x.type === 'EXEMPTION_GRANTED');
      expect(n.data).toMatchObject({ exempted_display_name: 'An', forfeited: false });
      expect(findSensitiveKeys(n)).toEqual([]);
    }
    // đã quyết → 409; bù không lặp lại
    expect((await t.api('POST', `/v1/appeals/${ap.body.appeal_id}/decision`, owner.token, { decision: 'REJECT', decision_reason: 'x' })).body.code).toBe('APPEAL_ALREADY_DECIDED');
    expect(await ledger(b.id, s.sessionId)).toHaveLength(1);
    // chủ nhóm xem chi tiết phiên: appeal_status, không Coins/chuỗi
    const od = await t.api('GET', `/v1/sessions/${s.sessionId}/owner-detail`, owner.token);
    expect(od.body.members.find((m: { user_id: string }) => m.user_id === a.id).appeal_status).toBe('EXEMPTED');
    expect(findSensitiveKeys(od.body)).toEqual([]);
  });

  it('còn người rời khác chưa miễn trừ → vẫn forfeited, người khởi phát chuyển sang người kế; không bù Coins', async () => {
    const { owner, members, groupId } = await t.groupWith(3);
    const [a, b, c] = members;
    const s = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: [
      { id: a.id, state: 'EXITED', exitAtMin: 3, name: 'An' }, { id: b.id, state: 'EXITED', exitAtMin: 9, name: 'Bình' }, { id: c.id, state: 'COMPLETED' }] });
    const ap = await t.api('POST', `/v1/sessions/${s.sessionId}/appeals`, a.token, { body: 'lỗi' });
    const dec = await t.api('POST', `/v1/appeals/${ap.body.appeal_id}/decision`, owner.token, { decision: 'EXEMPT', decision_reason: 'đồng ý' });
    expect(dec.body.status).toBe('EXEMPTED');
    const sess = await t.db.selectFrom('sessions').select(['forfeited', 'forfeit_trigger_user_id']).where('id', '=', s.sessionId).executeTakeFirstOrThrow();
    expect(sess).toEqual({ forfeited: true, forfeit_trigger_user_id: b.id });
    expect(await t.db.selectFrom('coin_ledger').select('entry_id').where('ref_id', '=', s.sessionId).execute()).toHaveLength(0);
    const n = (await t.api('GET', '/v1/me/notifications', c.token)).body.items.find((x: { type: string }) => x.type === 'EXEMPTION_GRANTED');
    expect(n.data).toMatchObject({ exempted_display_name: 'An', forfeited: true });
    // Bình khiếu nại, bị bác → APPEAL_DECIDED
    const ap2 = await t.api('POST', `/v1/sessions/${s.sessionId}/appeals`, b.token, { body: 'cũng lỗi' });
    const rej = await t.api('POST', `/v1/appeals/${ap2.body.appeal_id}/decision`, owner.token, { decision: 'REJECT', decision_reason: 'Có log rời app rõ ràng' });
    expect(rej.body.status).toBe('REJECTED');
    expect((await t.api('GET', '/v1/me/notifications', b.token)).body.items.some((x: { type: string }) => x.type === 'APPEAL_DECIDED')).toBe(true);
  });

  it('nghi lỗi hệ thống → CHUYỂN QUẢN TRỊ; chủ nhóm không xử lý được nữa (BR-110)', async () => {
    const { owner, members, groupId } = await t.groupWith(2);
    const s = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: [{ id: members[0].id, state: 'EXITED' }, { id: members[1].id, state: 'COMPLETED' }] });
    const ap = await t.api('POST', `/v1/sessions/${s.sessionId}/appeals`, members[0].token, { body: 'app treo', suspect_system_error: true });
    expect(ap.body.status).toBe('ESCALATED');
    const dec = await t.api('POST', `/v1/appeals/${ap.body.appeal_id}/decision`, owner.token, { decision: 'EXEMPT', decision_reason: 'ok' });
    expect(dec.status).toBe(403);
  });
});
