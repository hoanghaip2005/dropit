// Các việc "làm local" trong ba/review/doi-chieu-code.md §3: sửa/hủy lịch, rút đồng ý, xóa thành viên, hồ sơ công khai,
// Dữ liệu của tôi, báo cáo nhóm giải tán, lịch sử giải trình, phòng chờ có tên, tiến độ huy hiệu, Nhóm của tôi.
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startServer, emit, sleep, waitFor, findSensitiveKeys, type TestServer } from './helpers.js';
import { simulateSession, pastSlots } from './sim.js';
import { retryDeadline } from '../../src/modules/jobs/cron.js';
import { generateGroupReport, prevMonth } from '../../src/modules/reports/service.js';
import { vnDay } from '../../src/shared/time.js';

let t: TestServer;
const slot = pastSlots(1400);
beforeAll(async () => {
  t = await startServer(); // grace 300ms, countdown 300ms, 1 "phút" = 60ms → phiên 25' = 1,5s
});
afterAll(async () => t?.close());

const sess = (sid: string) => t.db.selectFrom('sessions').selectAll().where('id', '=', sid).executeTakeFirstOrThrow();
const finished = (sid: string) =>
  waitFor(async () => ['COMPLETED', 'CANCELLED'].includes((await sess(sid)).status) && !t.srv.ctx.sessions.runtimes.has(sid), 15000);
const smRow = (sid: string, uid: string) => t.db.selectFrom('session_members').selectAll().where('session_id', '=', sid).where('user_id', '=', uid).executeTakeFirst();
const inbox = async (token: string) => (await t.api('GET', '/v1/me/notifications', token)).body.items as { type: string; body: string; data: Record<string, unknown> }[];
const membership = (gid: string, uid: string) => t.db.selectFrom('group_members').selectAll().where('group_id', '=', gid).where('user_id', '=', uid).orderBy('joined_at', 'desc').executeTakeFirstOrThrow();

/** Vào phòng chờ cho cả nhóm, chờ ACTIVE + FOCUSING. */
async function runningSession(n: number, duration = 25) {
  const g = await t.groupWith(n);
  const sid = await t.schedule(g.owner.token, g.groupId, 1500, duration);
  await waitFor(() => t.srv.ctx.sessions.runtimes.has(sid));
  const socks = await Promise.all(g.members.map((m) => t.sock(m.token)));
  for (const s of socks) expect(await emit(s, 'session:join', { session_id: sid })).toMatchObject({ ok: true, state: 'WAITING' });
  await waitFor(async () => (await sess(sid)).status === 'ACTIVE');
  await waitFor(() => socks.every((s) => s.events.some((e) => e.type === 'member:state' && e.payload.my_state === 'FOCUSING')));
  return { ...g, sid, socks };
}
async function exitByGrace(sock: Awaited<ReturnType<TestServer['sock']>>, sid: string) {
  expect(await emit(sock, 'member:left_app', { session_id: sid })).toMatchObject({ ok: true, state: 'GRACE' });
  await sleep(450);
  expect((await emit(sock, 'member:returned', { session_id: sid })).state).toBe('EXITED');
}

describe('US-02.11 Sửa / hủy lịch (+ AC-03.01.4)', () => {
  it('sửa giờ/thời lượng phiên SCHEDULED → lưu, TV được báo; quá khứ → 422; thành viên → 403; trùng phiên → 409', async () => {
    const { owner, members, groupId } = await t.groupWith(2);
    const start = new Date(Math.ceil((Date.now() + 3 * 3600e3) / 1000) * 1000);
    const r = await t.api('POST', `/v1/groups/${groupId}/schedules`, owner.token, { start_time: start.toISOString(), duration_min: 25 });
    const sid = r.body.sessions[0].session_id;
    const newStart = new Date(start.getTime() + 3600e3);
    const p = await t.api('PATCH', `/v1/sessions/${sid}`, owner.token, { started_at: newStart.toISOString(), duration_min: 50 });
    expect(p.status).toBe(200);
    expect(p.body).toMatchObject({ session_id: sid, status: 'SCHEDULED', duration_min: 50, started_at: newStart.toISOString() });
    expect((await sess(sid)).ends_at.getTime()).toBe(newStart.getTime() + 50 * 60000);
    const n = (await inbox(members[0].token)).find((x) => x.type === 'SESSION_UPDATED');
    expect(n?.data).toMatchObject({ session_id: sid, duration_min: 50 });
    // BR-79: giờ mới < giờ server + lead → 422
    expect((await t.api('PATCH', `/v1/sessions/${sid}`, owner.token, { started_at: new Date(Date.now() - 60000).toISOString() })).body.code).toBe('START_IN_PAST');
    expect((await t.api('PATCH', `/v1/sessions/${sid}`, owner.token, { duration_min: 241 })).body.code).toBe('DURATION_OUT_OF_RANGE');
    // NFR-11 / D-10
    expect((await t.api('PATCH', `/v1/sessions/${sid}`, members[0].token, { duration_min: 25 })).body.code).toBe('NOT_GROUP_OWNER');
    expect((await t.api('DELETE', `/v1/sessions/${sid}`, members[0].token)).body.code).toBe('NOT_GROUP_OWNER');
    // BR-78: chồng phiên khác của nhóm
    const other = await t.api('POST', `/v1/groups/${groupId}/schedules`, owner.token, { start_time: new Date(newStart.getTime() + 2 * 3600e3).toISOString(), duration_min: 25 });
    expect(other.status).toBe(201);
    const clash = await t.api('PATCH', `/v1/sessions/${other.body.sessions[0].session_id}`, owner.token, { started_at: new Date(newStart.getTime() + 10 * 60000).toISOString() });
    expect(clash.status).toBe(409);
    expect(clash.body.code).toBe('SCHEDULE_OVERLAP');
  });

  it('hủy phiên SCHEDULED → CANCELLED OWNER_CANCEL, không ghi dữ liệu; người đang WAITING → VOID + thông báo (AC-03.01.4)', async () => {
    const { owner, members, groupId } = await t.groupWith(2);
    const sid = await t.schedule(owner.token, groupId, 4000);
    await waitFor(() => t.srv.ctx.sessions.runtimes.has(sid));
    const s0 = await t.sock(members[0].token);
    const s1 = await t.sock(members[1].token);
    expect(await emit(s0, 'session:join', { session_id: sid })).toMatchObject({ ok: true, state: 'WAITING' });
    // phòng chờ có tên người đang WAITING (session:state.lobby_members)
    expect(await emit(s1, 'session:join', { session_id: sid })).toMatchObject({ ok: true });
    const lobby = await waitFor(() => s0.events.filter((e) => e.type === 'session:state').map((e) => e.payload.lobby_members).find((l) => l?.length === 2));
    expect(lobby).toEqual(['An', 'Bình']);
    const d = await t.api('DELETE', `/v1/sessions/${sid}`, owner.token);
    expect(d.status).toBe(204);
    const s = await sess(sid);
    expect(s).toMatchObject({ status: 'CANCELLED', cancel_reason: 'OWNER_CANCEL', forfeited: false });
    expect(t.srv.ctx.sessions.runtimes.has(sid)).toBe(false);
    await waitFor(async () => (await smRow(sid, members[0].id))?.state === 'VOID');
    expect((await smRow(sid, members[1].id))?.state).toBe('VOID');
    expect(await t.db.selectFrom('coin_ledger').select('entry_id').where('ref_id', '=', sid).execute()).toHaveLength(0);
    await waitFor(() => s0.events.some((e) => e.type === 'session:state' && e.payload.status === 'CANCELLED'));
    expect((await inbox(members[0].token)).some((x) => x.type === 'SESSION_CANCELLED')).toBe(true);
    // hủy lại → 409 (đã CANCELLED)
    expect((await t.api('DELETE', `/v1/sessions/${sid}`, owner.token)).body.code).toBe('SESSION_ALREADY_STARTED');
    s0.close();
    s1.close();
  });

  it('từ mốc COUNTDOWN (started_at − 5s) không sửa/hủy được (AC-02.11.3/.4)', async () => {
    const { owner, groupId } = await t.groupWith(1);
    const sid = await t.schedule(owner.token, groupId, 1000);
    await waitFor(async () => ['COUNTDOWN', 'ACTIVE', 'CANCELLED'].includes((await sess(sid)).status) || ['COUNTDOWN', 'ACTIVE'].includes(t.srv.ctx.sessions.runtimeStatus(sid) ?? ''));
    expect((await t.api('PATCH', `/v1/sessions/${sid}`, owner.token, { duration_min: 50 })).body.code).toBe('SESSION_ALREADY_STARTED');
    expect((await t.api('DELETE', `/v1/sessions/${sid}`, owner.token)).body.code).toBe('SESSION_ALREADY_STARTED');
    await finished(sid);
  });
});

describe('US-01.07 Rút đồng ý / rời nhóm (BR-26, BR-37, D-23)', () => {
  it('ngoài phiên: rời ngay, bản ghi WITHDRAW, chủ nhóm chỉ nhận "X đã rời nhóm" + cảnh báo dưới 4; chủ nhóm không rút được', async () => {
    const { owner, members, groupId } = await t.groupWith(4);
    const r = await t.api('DELETE', `/v1/groups/${groupId}/consent`, members[0].token);
    expect(r.status).toBe(200);
    expect(r.body).toMatchObject({ group_id: groupId, sessions: [] });
    expect(await membership(groupId, members[0].id)).toMatchObject({ leave_reason: 'CONSENT_WITHDRAWN' });
    const c = await t.db.selectFrom('consents').select('action').where('user_id', '=', members[0].id).where('group_id', '=', groupId).orderBy('created_at', 'desc').executeTakeFirstOrThrow();
    expect(c.action).toBe('WITHDRAW');
    const n = (await inbox(owner.token)).find((x) => x.type === 'MEMBER_LEFT_GROUP')!;
    expect(n.body).toBe('An đã rời nhóm. Nhóm dưới 4 người — mời thêm.');
    expect((await t.api('GET', `/v1/groups/${groupId}/members`, owner.token)).body).toMatchObject({ member_count: 3, below_minimum: true });
    // không còn quyền với nhóm; gọi lại → 403
    expect((await t.api('GET', `/v1/groups/${groupId}/members`, members[0].token)).status).toBe(403);
    expect((await t.api('DELETE', `/v1/groups/${groupId}/consent`, members[0].token)).status).toBe(403);
    expect((await t.api('DELETE', `/v1/groups/${groupId}/consent`, owner.token)).body.code).toBe('OWNER_OF_THIS_GROUP');
    // vào nhóm khác được ngay (D-21)
    const other = await t.groupWith(0);
    expect((await t.api('POST', `/v1/groups/${other.groupId}/consent`, members[0].token, { consent_version: 1, invite_code: other.inviteCode })).status).toBe(201);
  });

  it('trong phiên, trước forfeited_at: WITHDRAWN ngay, không MEMBER_EXITED/forfeited; người khác thoát sau đó không ngắt chuỗi của X (AC-01.07.2, .7)', async () => {
    const { owner, members, sid, socks } = await runningSession(3);
    const ack = await emit(socks[1], 'member:withdraw', { session_id: sid });
    expect(ack).toMatchObject({ ok: true, state: 'WITHDRAWN', left_group: true, after_forfeit: false });
    expect((await sess(sid)).forfeited).toBe(false);
    await sleep(100);
    expect(socks[0].events.some((e) => e.type === 'MEMBER_EXITED')).toBe(false);
    await exitByGrace(socks[0], sid); // An thoát → forfeited
    await finished(sid);
    expect(await smRow(sid, members[1].id)).toMatchObject({ state: 'WITHDRAWN', end_reason: 'CONSENT_WITHDRAWN', coins_awarded: 0 });
    expect(socks[1].events.some((e) => e.type === 'MEMBER_EXITED')).toBe(false); // đã rút → không nhận
    const br = await t.db.selectFrom('achievement_log').select('user_id').where('ref_session_id', '=', sid).where('kind', '=', 'STREAK_BREAK').execute();
    expect(br.map((b) => b.user_id)).not.toContain(members[1].id);
    expect((await inbox(owner.token)).filter((x) => x.type === 'MEMBER_EXITED').map((x) => x.data.exited_display_name)).toEqual(['An']);
    for (const s of socks) s.close();
  });

  it('trong phiên, sau forfeited_at: WITHDRAWN, 0 Coins, vẫn bị ngắt chuỗi tại ends_at (AC-01.07.5, D-23)', async () => {
    const { members, groupId, sid, socks } = await runningSession(3);
    await exitByGrace(socks[0], sid);
    await waitFor(async () => (await sess(sid)).forfeited);
    const r = await t.api('DELETE', `/v1/groups/${groupId}/consent`, members[1].token);
    expect(r.status).toBe(200);
    expect(r.body.sessions).toEqual([{ session_id: sid, state: 'WITHDRAWN', after_forfeit: true }]);
    await finished(sid);
    expect(await smRow(sid, members[1].id)).toMatchObject({ state: 'WITHDRAWN', coins_awarded: 0 });
    const br = await t.db.selectFrom('achievement_log').select(['user_id', 'reason']).where('ref_session_id', '=', sid).where('kind', '=', 'STREAK_BREAK').execute();
    expect(br.find((b) => b.user_id === members[1].id)?.reason).toBe('WITHDRAWN_AFTER_FORFEIT');
    // AC-08.03.4: dữ liệu cũ vẫn xem được ở Dữ liệu của tôi sau khi rời
    const data = await t.api('GET', `/v1/me/data?group_id=${groupId}`, members[1].token);
    expect(data.body.sessions[0]).toMatchObject({ session_id: sid, final_state: 'WITHDRAWN', forfeited: true, forfeit_trigger_display_name: 'An' });
    for (const s of socks) s.close();
  });
});

describe('US-02.08 Chủ nhóm xóa thành viên (BR-77)', () => {
  it('ngoài phiên: hiệu lực ngay + thông báo; thành viên gọi → 403; tự xóa → 409; người ngoài nhóm → 404', async () => {
    const { owner, members, groupId } = await t.groupWith(4);
    expect((await t.api('DELETE', `/v1/groups/${groupId}/members/${members[1].id}`, members[0].token)).body.code).toBe('NOT_GROUP_OWNER');
    expect((await t.api('DELETE', `/v1/groups/${groupId}/members/${owner.id}`, owner.token)).body.code).toBe('CANNOT_REMOVE_SELF');
    const stranger = await t.user('Lạ');
    expect((await t.api('DELETE', `/v1/groups/${groupId}/members/${stranger.id}`, owner.token)).status).toBe(404);
    const d = await t.api('DELETE', `/v1/groups/${groupId}/members/${members[0].id}`, owner.token);
    expect(d.status).toBe(204);
    expect(await membership(groupId, members[0].id)).toMatchObject({ leave_reason: 'REMOVED' });
    expect((await inbox(members[0].token)).find((x) => x.type === 'REMOVED_FROM_GROUP')?.body).toContain('Bạn không còn trong nhóm');
    expect((await t.api('GET', `/v1/groups/${groupId}/members`, owner.token)).body).toMatchObject({ member_count: 3, below_minimum: true });
  });

  it('đang trong phiên: 202, kết quả phiên giữ nguyên (không WITHDRAWN), hiệu lực sau ends_at (AC-02.08.4)', async () => {
    const { owner, members, groupId, sid, socks } = await runningSession(2);
    const d = await t.api('DELETE', `/v1/groups/${groupId}/members/${members[0].id}`, owner.token);
    expect(d.status).toBe(202);
    expect(d.body).toMatchObject({ effective: 'AFTER_SESSION', session_id: sid });
    expect((await membership(groupId, members[0].id)).left_at).toBeNull();
    await finished(sid);
    expect(await smRow(sid, members[0].id)).toMatchObject({ state: 'COMPLETED' });
    await waitFor(async () => (await membership(groupId, members[0].id)).leave_reason === 'REMOVED');
    for (const s of socks) s.close();
  });
});

describe('Hồ sơ công khai GET /users/{id}/public-profile (US-01.03, US-06.05, US-07.04)', () => {
  it('người cùng nhóm xem được (không Coins/chuỗi trừ khi tự bật); chủ nhóm không thấy chuỗi; người ngoài 403', async () => {
    const { owner, members } = await t.groupWith(2);
    const [a, b] = members;
    const p = await t.api('GET', `/v1/users/${a.id}/public-profile`, b.token);
    expect(p.status).toBe(200);
    expect(p.body).toMatchObject({ user: { user_id: a.id, display_name: 'An' }, role: 'MEMBER', shown_badges: [], shown_streak: null });
    expect(findSensitiveKeys(p.body).filter((k) => k !== 'shown_streak')).toEqual([]);
    expect(p.body.user.frame_item_id).toBeTruthy(); // khung mặc định/đang trang bị (AC-07.04.1)
    // tự bật hiện chuỗi
    expect((await t.api('PATCH', '/v1/me', a.token, { show_streak: true })).body.show_streak).toBe(true);
    await t.db.updateTable('users').set({ current_streak: 4, longest_streak: 4 }).where('id', '=', a.id).execute();
    expect((await t.api('GET', `/v1/users/${a.id}/public-profile`, b.token)).body.shown_streak).toBe(4);
    expect((await t.api('GET', `/v1/users/${a.id}/public-profile`, owner.token)).body.shown_streak).toBeNull(); // BR-53b
    expect((await t.api('GET', `/v1/users/${owner.id}/public-profile`, a.token)).body.role).toBe('OWNER');
    const stranger = await t.user('Lạ');
    expect((await t.api('GET', `/v1/users/${a.id}/public-profile`, stranger.token)).status).toBe(403);
    // danh sách thành viên có khung đang trang bị
    const list = await t.api('GET', `/v1/groups/${(await t.api('GET', '/v1/me/groups', a.token)).body.items[0].group_id}/members`, b.token);
    expect(list.body.members[0].frame_item_id).toBeTruthy();
  });
});

describe('US-01.08 Dữ liệu của tôi (GET /me/data)', () => {
  it('đủ mục, cùng trường chủ nhóm thấy; tên người khởi phát nhưng không dữ liệu khác của họ; user_id khác → 403; chưa có nhóm → mục cá nhân', async () => {
    const { owner, members, groupId } = await t.groupWith(2);
    const [a, b] = members;
    const s = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: [{ id: a.id, state: 'EXITED', name: 'An' }, { id: b.id, state: 'COMPLETED' }] });
    await t.api('PUT', `/v1/sessions/${s.sessionId}/explanation`, a.token, { body: 'Mẹ gọi' });
    const mine = await t.api('GET', '/v1/me/data', a.token);
    expect(mine.status).toBe(200);
    expect(mine.body.categories.map((c: { code: string }) => c.code)).toEqual(expect.arrayContaining(['EXIT_EVENTS', 'SESSION_RESULTS', 'EXPLANATIONS', 'COINS', 'JOURNAL', 'CONSENTS']));
    expect(mine.body.exit_events[0]).toMatchObject({ session_id: s.sessionId, explanation: { body: 'Mẹ gọi', edited_at: null } });
    expect(mine.body.consents[0]).toMatchObject({ group_id: groupId, action: 'GRANT' });
    // AC-01.08.2: trường chủ nhóm thấy ở owner-detail đều có ở màn của tôi
    const od = await t.api('GET', `/v1/sessions/${s.sessionId}/owner-detail`, owner.token);
    const ownerRow = od.body.members.find((m: { user_id: string }) => m.user_id === a.id);
    const myRow = mine.body.sessions.find((x: { session_id: string }) => x.session_id === s.sessionId);
    expect(myRow).toMatchObject({ final_state: ownerRow.final_state, late_join: ownerRow.late_join, pause_count: ownerRow.pause_count, exited_at: ownerRow.exited_at, exempted: false });
    // AC-01.08.4: B thấy tên người khởi phát, không thấy giải trình/Coins của A
    const bd = await t.api('GET', '/v1/me/data', b.token);
    expect(bd.body.sessions[0]).toMatchObject({ forfeited: true, forfeit_trigger_display_name: 'An', forfeit_triggered_by_me: false });
    expect(JSON.stringify(bd.body)).not.toContain('Mẹ gọi');
    expect(bd.body.exit_events).toEqual([]);
    // AC-01.08.3
    expect((await t.api('GET', `/v1/me/data?user_id=${a.id}`, b.token)).status).toBe(403);
    // AC-01.08.5
    const lone = await t.user('Một');
    const ld = await t.api('GET', '/v1/me/data', lone.token);
    expect(ld.body).toMatchObject({ sessions: [], groups: [], coins: { balance: 0 }, journal: { entry_count: 0 } });
  });
});

describe('Báo cáo: nhóm đã giải tán, nhãn "thêm sau khi tạo báo cáo", thử lại đến 06:00 (US-08.01, US-08.02)', () => {
  it('BR-102: nhãn theo bản gửi đầu — gửi sau lúc tạo báo cáo có nhãn; gửi trước rồi sửa sau không đổi nhãn', async () => {
    const { owner, members, groupId } = await t.groupWith(2);
    const [a, b] = members;
    // phiên trong tháng hiện tại (ngày hôm nay, vài giờ trước) để giải trình còn hạn
    const s1 = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: new Date(Date.now() - 200 * 60000), members: [{ id: a.id, state: 'EXITED', name: 'An' }, { id: b.id, state: 'COMPLETED' }] });
    const s2 = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: new Date(Date.now() - 150 * 60000), members: [{ id: a.id, state: 'COMPLETED' }, { id: b.id, state: 'EXITED', name: 'Bình' }] });
    const month = vnDay(new Date(Date.now() - 200 * 60000)).slice(0, 7);
    expect((await t.api('PUT', `/v1/sessions/${s1.sessionId}/explanation`, a.token, { body: 'Bản đầu' })).status).toBe(200);
    await t.db.updateTable('groups').set({ created_at: new Date(Date.now() - 40 * 86400e3) }).where('id', '=', groupId).execute();
    await t.db.updateTable('group_members').set({ joined_at: new Date(Date.now() - 40 * 86400e3) }).where('group_id', '=', groupId).execute();
    const rep = await generateGroupReport(t.srv.ctx, groupId, month);
    expect(rep?.created).toBe(true);
    expect((await t.api('PUT', `/v1/sessions/${s1.sessionId}/explanation`, a.token, { body: 'Bản sửa' })).body).toMatchObject({ added_after_report: false });
    expect((await t.api('PUT', `/v1/sessions/${s2.sessionId}/explanation`, b.token, { body: 'Gửi sau' })).body).toMatchObject({ added_after_report: true });
    const view = await t.api('GET', `/v1/groups/${groupId}/reports/${month}`, owner.token);
    expect(view.status).toBe(200);
    const ex = (uid: string) => view.body.rows.find((r: { user_id: string }) => r.user_id === uid).explanations[0];
    expect(ex(a.id)).toMatchObject({ body: 'Bản sửa', added_after_report: false });
    expect(ex(a.id).edited_at).toBeTruthy();
    expect(ex(b.id)).toMatchObject({ body: 'Gửi sau', added_after_report: true, edited_at: null });
  });

  it('nhóm ĐÃ GIẢI TÁN: người từng là chủ nhóm vẫn xem được báo cáo; thành viên cũ chỉ dòng của mình (BR-62, BR-103)', async () => {
    const { owner, members, groupId } = await t.groupWith(2);
    const month = prevMonth(vnDay(new Date()).slice(0, 7));
    await t.db.updateTable('groups').set({ created_at: new Date(Date.now() - 70 * 86400e3) }).where('id', '=', groupId).execute();
    await t.db.updateTable('group_members').set({ joined_at: new Date(Date.now() - 70 * 86400e3) }).where('group_id', '=', groupId).execute();
    await generateGroupReport(t.srv.ctx, groupId, month);
    await t.db.updateTable('group_members').set({ left_at: new Date(), leave_reason: 'GROUP_DISSOLVED' }).where('group_id', '=', groupId).where('left_at', 'is', null).execute();
    await t.db.updateTable('groups').set({ status: 'DISSOLVED', dissolved_at: new Date() } as never).where('id', '=', groupId).execute();
    const v = await t.api('GET', `/v1/groups/${groupId}/reports/${month}`, owner.token);
    expect(v.status).toBe(200);
    expect(v.body.view).toBe('OWNER');
    expect((await t.api('GET', `/v1/groups/${groupId}/reports`, owner.token)).body.items[0].month).toBe(month);
    const m = await t.api('GET', `/v1/groups/${groupId}/reports/${month}`, members[0].token);
    expect(m.body).toMatchObject({ view: 'MEMBER', my_row: { user_id: members[0].id } });
    const stranger = await t.user('Lạ');
    expect((await t.api('GET', `/v1/groups/${groupId}/reports/${month}`, stranger.token)).status).toBe(403);
  });

  it('BR-101: hạn thử lại = 06:00 giờ VN của ngày chạy lượt đầu', () => {
    const first = new Date('2026-10-31T19:00:00Z'); // 02:00 VN 01/11
    expect(new Date(retryDeadline(first)).toISOString()).toBe('2026-10-31T23:00:00.000Z'); // 06:00 VN 01/11
  });
});

describe('US-04.05 / US-04.06 Giải trình: lịch sử bản cũ, đọc lại của mình, "đã sửa lúc"', () => {
  it('sửa trong hạn lưu bản cũ; thành viên đọc lại kèm lịch sử; chủ nhóm thấy edited_at; loại sự kiện khác EXITED → 400', async () => {
    const { owner, members, groupId } = await t.groupWith(2);
    const [a, b] = members;
    const s = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: [{ id: a.id, state: 'EXITED', name: 'An' }, { id: b.id, state: 'COMPLETED' }] });
    expect((await t.api('GET', `/v1/sessions/${s.sessionId}/explanation`, a.token)).status).toBe(404);
    await t.api('PUT', `/v1/sessions/${s.sessionId}/explanation`, a.token, { body: 'Một' });
    await sleep(5);
    await t.api('PUT', `/v1/sessions/${s.sessionId}/explanation`, a.token, { body: 'Hai' });
    await sleep(5);
    await t.api('PUT', `/v1/sessions/${s.sessionId}/explanation`, a.token, { body: 'Ba' });
    const g = await t.api('GET', `/v1/sessions/${s.sessionId}/explanation`, a.token);
    expect(g.status).toBe(200);
    expect(g.body).toMatchObject({ body: 'Ba', can_edit: true });
    expect(g.body.edited_at).toBeTruthy();
    expect(g.body.history.map((h: { body: string }) => h.body)).toEqual(['Hai', 'Một']);
    // lịch sử chỉ thêm
    await expect(t.db.deleteFrom('explanation_revisions').execute()).rejects.toThrow();
    const o = await t.api('GET', `/v1/sessions/${s.sessionId}/explanations`, owner.token);
    expect(o.body.items[0]).toMatchObject({ body: 'Ba' });
    expect(o.body.items[0].edited_at).toBe(g.body.edited_at);
    expect(o.body.items[0].history).toBeUndefined(); // chủ nhóm chỉ thấy bản mới nhất
    const bad = await t.api('PUT', `/v1/sessions/${s.sessionId}/explanation`, b.token, { body: 'x' });
    expect(bad.status).toBe(400);
    expect((await t.api('GET', `/v1/sessions/${s.sessionId}/explanation`, owner.token)).status).toBe(403);
  });
});

describe('Thành tích + Nhóm của tôi', () => {
  it('/me/achievements có tiến độ huy hiệu số phiên/số giờ và cờ "hôm nay đã cộng chuỗi"', async () => {
    const { owner, members, groupId } = await t.groupWith(1);
    const [a] = members;
    const before = await t.api('GET', '/v1/me/achievements', a.token);
    expect(before.body).toMatchObject({ streak_counted_today: false });
    const sessions = before.body.badge_progress.find((p: { metric: string }) => p.metric === 'REWARDED_SESSIONS');
    expect(sessions).toMatchObject({ value: 0 });
    expect(sessions.next_threshold).toBeGreaterThan(0);
    await simulateSession(t, { groupId, ownerId: owner.id, startedAt: new Date(Date.now() - 60 * 60000), members: [{ id: a.id, state: 'COMPLETED' }] });
    const after = await t.api('GET', '/v1/me/achievements', a.token);
    expect(after.body.streak_counted_today).toBe(vnDay(new Date(Date.now() - 60 * 60000)) === vnDay(new Date()));
    expect(after.body.badge_progress.find((p: { metric: string }) => p.metric === 'REWARDED_SESSIONS').value).toBe(1);
  });

  it('/me/groups: trạng thái nhóm, sắp theo tên (BR-117), tỉ lệ hoàn thành riêng từng nhóm', async () => {
    const owner = await t.user('Chủ nhiều nhóm');
    for (const name of ['bê', 'An', 'Ân']) await t.api('POST', '/v1/groups', owner.token, { name, report_purpose: 'x' });
    const r = await t.api('GET', '/v1/me/groups', owner.token);
    expect(r.body.items.map((g: { name: string }) => g.name)).toEqual(['An', 'Ân', 'bê']);
    expect(r.body.items[0]).toMatchObject({ role: 'OWNER', status: 'ACTIVE', below_minimum: true, month_completion_rate: null });
  });
});
