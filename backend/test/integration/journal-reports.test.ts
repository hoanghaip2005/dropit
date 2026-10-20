import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { startServer, findSensitiveKeys, type TestServer } from './helpers.js';
import { simulateSession, pastSlots } from './sim.js';
import { vnDay } from '../../src/shared/time.js';
import { runMonthlyReportJob } from '../../src/modules/reports/service.js';

let t: TestServer;
const slot = pastSlots(700);
beforeAll(async () => {
  t = await startServer();
});
afterAll(async () => t?.close());

describe('Nhật ký (US-07.07, US-07.10, BR-100)', () => {
  it('viết hôm nay, lưu mã hóa (DB không có bản rõ), đọc lại đúng; sửa; xóa', async () => {
    const u = await t.user('Viết');
    const today = vnDay(new Date());
    const text = 'Hôm nay tập trung tốt — bí mật số 42 🌱';
    const put = await t.api('PUT', `/v1/me/journal/${today}`, u.token, { text });
    expect(put.status).toBe(200);
    expect(put.body).toMatchObject({ date: today, text });
    const row = await t.db.selectFrom('journals').selectAll().where('user_id', '=', u.id).executeTakeFirstOrThrow();
    expect(row.ciphertext.toString('utf8')).not.toContain('bí mật');
    expect(row.ciphertext.includes(Buffer.from('42 '))).toBe(false);
    expect(row.encrypted_dek.length).toBeGreaterThan(32);
    expect(row.char_count).toBe([...text].length);
    const list = await t.api('GET', '/v1/me/journal', u.token);
    expect(list.body.items).toEqual([expect.objectContaining({ date: today, text })]);
    const edit = await t.api('PUT', `/v1/me/journal/${today}`, u.token, { text: 'Sửa lại' });
    expect(edit.body.text).toBe('Sửa lại');
    expect(await t.db.selectFrom('journals').select('id').where('user_id', '=', u.id).execute()).toHaveLength(1); // 1 mục/ngày
    expect((await t.api('GET', `/v1/me/journal/${today}`, u.token)).body.text).toBe('Sửa lại');
    expect((await t.api('DELETE', `/v1/me/journal/${today}`, u.token)).status).toBe(204);
    expect((await t.api('DELETE', `/v1/me/journal/${today}`, u.token)).status).toBe(404);
    expect((await t.api('GET', '/v1/me/journal', u.token)).body.items).toEqual([]);
  });

  it('≤ 5000 ký tự (đếm theo ký tự Unicode), ngày khác hôm nay cho mục mới → 422', async () => {
    const u = await t.user('Dài');
    const today = vnDay(new Date());
    expect((await t.api('PUT', `/v1/me/journal/${today}`, u.token, { text: 'a'.repeat(5001) })).body.code).toBe('JOURNAL_TOO_LONG');
    expect((await t.api('PUT', `/v1/me/journal/${today}`, u.token, { text: '🌱'.repeat(5000) })).status).toBe(200);
    expect((await t.api('PUT', '/v1/me/journal/2020-01-01', u.token, { text: 'x' })).body.code).toBe('JOURNAL_DATE_INVALID');
    expect((await t.api('PUT', `/v1/me/journal/${today}`, u.token, { text: '   ' })).status).toBe(400);
  });

  it('chủ nhóm / người khác không đọc được nhật ký của thành viên → 403; mỗi người chỉ thấy của mình', async () => {
    const { owner, members, groupId } = await t.groupWith(2);
    const today = vnDay(new Date());
    await t.api('PUT', `/v1/me/journal/${today}`, members[0].token, { text: 'riêng tư của An' });
    expect((await t.api('GET', `/v1/users/${members[0].id}/journal`, owner.token)).status).toBe(403);
    expect((await t.api('GET', `/v1/users/${members[0].id}/journal/${today}`, owner.token)).status).toBe(403);
    expect((await t.api('GET', `/v1/groups/${groupId}/members/${members[0].id}/journal`, owner.token)).status).toBe(403);
    expect((await t.api('GET', `/v1/users/${members[0].id}/journal`, members[1].token)).status).toBe(403);
    const ownerList = await t.api('GET', '/v1/me/journal', owner.token);
    expect(JSON.stringify(ownerList.body)).not.toContain('riêng tư');
    expect((await t.api('GET', `/v1/me/journal/${today}`, members[1].token)).status).toBe(404);
  });
});

describe('Hồ sơ (US-01.03, US-07.03)', () => {
  it('sửa tên (BR-97) và tải avatar lưu local; sai định dạng/quá 5 MB → 422', async () => {
    const u = await t.user('Hồ Sơ');
    expect((await t.api('PATCH', '/v1/me', u.token, { display_name: '  Tên Mới  ' })).body.display_name).toBe('Tên Mới');
    expect((await t.api('PATCH', '/v1/me', u.token, { display_name: 'A' })).status).toBe(422);
    const intent = await t.api('PUT', '/v1/me/avatar', u.token, { content_type: 'image/png', size_bytes: 1000 });
    expect(intent.body.upload_url).toContain('/v1/me/avatar/content');
    expect((await t.api('PUT', '/v1/me/avatar', u.token, { content_type: 'image/gif', size_bytes: 10 })).status).toBe(422);
    expect((await t.api('PUT', '/v1/me/avatar', u.token, { content_type: 'image/png', size_bytes: 5 * 1024 * 1024 + 1 })).status).toBe(422);
    const base = `http://127.0.0.1:${(t.srv.app.server.address() as { port: number }).port}`;
    const png = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(64, 1)]);
    const up = await fetch(`${base}/v1/me/avatar/content`, { method: 'PUT', headers: { authorization: `Bearer ${u.token}`, 'content-type': 'image/png' }, body: png });
    expect(up.status).toBe(200);
    const me = await up.json();
    expect(me.avatar_url).toMatch(/\/uploads\/avatars\/.+\.png$/);
    const key = me.avatar_url.split('/uploads/')[1];
    expect(existsSync(join(t.cfg.uploadsDir, key))).toBe(true);
    const got = await fetch(`${base}/uploads/${key}`);
    expect(got.headers.get('content-type')).toBe('image/png');
    const fake = await fetch(`${base}/v1/me/avatar/content`, { method: 'PUT', headers: { authorization: `Bearer ${u.token}`, 'content-type': 'image/png' }, body: Buffer.from('not an image') });
    expect(fake.status).toBe(422);
    const big = await fetch(`${base}/v1/me/avatar/content`, { method: 'PUT', headers: { authorization: `Bearer ${u.token}`, 'content-type': 'image/jpeg' }, body: Buffer.concat([Buffer.from([0xff, 0xd8, 0xff]), Buffer.alloc(5 * 1024 * 1024)]) });
    expect(big.status).toBe(422);
    expect((await t.api('DELETE', '/v1/me/avatar', u.token)).status).toBe(204);
    expect(existsSync(join(t.cfg.uploadsDir, key))).toBe(false);
  });
});

describe('Báo cáo tháng (EP-08)', () => {
  it('bản chụp: chủ nhóm xem mọi dòng sắp theo tên, không Coins/chuỗi; thành viên chỉ dòng mình; idempotent; email outbox không theo dõi', async () => {
    const { owner, members, groupId } = await t.groupWith(3);
    await t.db.updateTable('group_members').set({ joined_at: new Date(Date.now() - 3 * 86400e3) }).where('group_id', '=', groupId).execute(); // BR-59
    const [an, binh, chi] = members; // tên An, Bình, Chi
    const s1 = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: [{ id: an.id, state: 'COMPLETED' }, { id: binh.id, state: 'COMPLETED' }, { id: chi.id, state: 'ABSENT' }] });
    const s2 = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: [{ id: an.id, state: 'COMPLETED' }, { id: binh.id, state: 'EXITED', name: 'Bình' }, { id: chi.id, state: 'LOST' }] });
    await t.api('PUT', `/v1/sessions/${s2.sessionId}/explanation`, binh.token, { body: 'Con ốm' });
    const month = s1.day.slice(0, 7);
    expect(s2.day.slice(0, 7)).toBe(month);

    const run1 = await runMonthlyReportJob(t.srv.ctx, month, [groupId]);
    expect(run1.results).toEqual([expect.objectContaining({ group_id: groupId, created: true })]);
    const run2 = await runMonthlyReportJob(t.srv.ctx, month, [groupId]);
    expect(run2.results[0].created).toBe(false); // BR-101 idempotent

    const list = await t.api('GET', `/v1/groups/${groupId}/reports`, owner.token);
    expect(list.body.items[0]).toMatchObject({ month, status: 'GENERATED' });
    const rep = await t.api('GET', `/v1/groups/${groupId}/reports/${month}`, owner.token);
    expect(rep.status).toBe(200);
    expect(rep.body.view).toBe('OWNER');
    expect(findSensitiveKeys(rep.body)).toEqual([]);
    expect(rep.body.rows.map((r: { display_name: string }) => r.display_name)).toEqual(['An', 'Bình', 'Chi']); // BR-115
    const row = (n: string) => rep.body.rows.find((r: { display_name: string }) => r.display_name === n);
    expect(row('An')).toMatchObject({ expected_sessions: 2, completed_sessions: 2, completion_rate: 100, attendance_days: 1, exited_count: 0 });
    expect(row('Bình')).toMatchObject({ completed_sessions: 1, exited_count: 1, completion_rate: 50, explanations: [expect.objectContaining({ session_id: s2.sessionId, body: 'Con ốm' })] });
    expect(row('Chi')).toMatchObject({ absent_count: 1, lost_count: 1, completed_sessions: 0, completion_rate: 0 });
    expect(rep.body.group_totals).toMatchObject({ sessions_held: 2, expected_slots: 6, completion_rate: 50, rewarded_completion_rate: 33.3, forfeited_sessions: 1 });
    expect(rep.body.rows.some((r: { user_id: string }) => r.user_id === owner.id)).toBe(false); // BR-60
    const al = await t.db.selectFrom('access_logs').select('subject_user_id').where('object_type', '=', 'REPORT').where('group_id', '=', groupId).execute();
    expect(al.length).toBeGreaterThanOrEqual(3);

    // thành viên: chỉ dòng của mình, không có tổng nhóm khi < 5 thành viên (BR-104)
    const mine = await t.api('GET', `/v1/groups/${groupId}/reports/${month}`, an.token);
    expect(mine.body).toMatchObject({ view: 'MEMBER', my_row: { display_name: 'An', completed_sessions: 2 }, group_totals: null });
    expect(JSON.stringify(mine.body)).not.toContain('Bình');
    expect((await t.api('GET', `/v1/groups/${groupId}/reports/${month}/members/${binh.id}`, an.token)).body.code).toBe('NOT_GROUP_OWNER');
    expect((await t.api('GET', `/v1/groups/${groupId}/reports/${month}/members/${binh.id}`, owner.token)).body).toMatchObject({ display_name: 'Bình', exited_count: 1 });
    const stranger = await t.user('Lạ');
    expect((await t.api('GET', `/v1/groups/${groupId}/reports/${month}`, stranger.token)).body.code).toBe('FORBIDDEN_GROUP');
    expect((await t.api('GET', `/v1/groups/${groupId}/reports`, stranger.token)).body.code).toBe('FORBIDDEN_GROUP');
    expect((await t.api('GET', `/v1/groups/${groupId}/reports/2001-01`, owner.token)).status).toBe(404);

    // bản chụp bất biến (BR-56): DB chặn sửa dòng
    const rid = (await t.db.selectFrom('monthly_reports').select('id').where('group_id', '=', groupId).executeTakeFirstOrThrow()).id;
    await expect(t.db.updateTable('monthly_report_rows').set({ metrics: '{}' }).where('report_id', '=', rid).execute()).rejects.toThrow();

    // email tóm tắt: ghi outbox, không dòng thành viên, không Coins/chuỗi, không ảnh/link theo dõi (D-27)
    const file = join(t.cfg.outboxDir, `report-${month}-${groupId}.eml`);
    const mail = readFileSync(file, 'utf8');
    expect(mail).toContain('Tỉ lệ hoàn thành phiên: 50%');
    expect(mail).not.toMatch(/<img|https?:\/\/|coin|chuỗi|Bình/i);
    const inbox = await t.api('GET', '/v1/me/notifications', owner.token);
    expect(inbox.body.items.some((n: { type: string }) => n.type === 'REPORT_READY')).toBe(true);
  });

  it('nhóm ≥ 5 thành viên → thành viên xem được tổng nhóm (BR-104)', async () => {
    const { owner, members, groupId } = await t.groupWith(5);
    await t.db.updateTable('group_members').set({ joined_at: new Date(Date.now() - 3 * 86400e3) }).where('group_id', '=', groupId).execute(); // BR-59
    const s = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: members.map((m) => ({ id: m.id, state: 'COMPLETED' as const })) });
    await runMonthlyReportJob(t.srv.ctx, s.day.slice(0, 7), [groupId]);
    const mine = await t.api('GET', `/v1/groups/${groupId}/reports/${s.day.slice(0, 7)}`, members[0].token);
    expect(mine.body.group_totals).toMatchObject({ sessions_held: 1, completion_rate: 100 });
    expect(findSensitiveKeys(mine.body)).toEqual([]);
  });
});

describe('Lịch lặp (US-02.10b, BR-113)', () => {
  it('tạo chuỗi theo thứ trong tuần; quá 12 tuần → 422; một lần lặp trùng → 409 cả chuỗi kèm ngày trùng', async () => {
    const { owner, groupId } = await t.groupWith(0);
    const start = new Date(Math.ceil((Date.now() + 2 * 86400e3) / 60000) * 60000);
    const startDay = vnDay(start);
    const end = vnDay(new Date(start.getTime() + 13 * 86400e3));
    const r = await t.api('POST', `/v1/groups/${groupId}/schedules`, owner.token, { start_time: start.toISOString(), duration_min: 25, recurrence: { weekdays: [1, 2, 3, 4, 5, 6, 7], end_date: end } });
    expect(r.status).toBe(201);
    expect(r.body.schedule_id).toBeTruthy();
    expect(r.body.sessions).toHaveLength(14);
    expect(r.body.sessions[0].started_at).toBe(start.toISOString());
    const sch = await t.db.selectFrom('schedules').selectAll().where('id', '=', r.body.schedule_id).executeTakeFirstOrThrow();
    expect(sch).toMatchObject({ start_date: startDay, end_date: end, duration_min: 25 });
    const tooLong = vnDay(new Date(start.getTime() + 85 * 86400e3));
    expect((await t.api('POST', `/v1/groups/${groupId}/schedules`, owner.token, { start_time: start.toISOString(), duration_min: 25, recurrence: { weekdays: [1], end_date: tooLong } })).status).toBe(422);
    const clash = await t.api('POST', `/v1/groups/${groupId}/schedules`, owner.token, { start_time: new Date(start.getTime() + 10 * 60000).toISOString(), duration_min: 50, recurrence: { weekdays: [1, 2, 3, 4, 5, 6, 7], end_date: end } });
    expect(clash.status).toBe(409);
    expect(clash.body.code).toBe('SCHEDULE_OVERLAP');
    expect(clash.body.detail).toContain(startDay);
    // chỉ T2/T4: số phiên đúng số ngày khớp
    const { owner: o2, groupId: g2 } = await t.groupWith(0);
    const r2 = await t.api('POST', `/v1/groups/${g2}/schedules`, o2.token, { start_time: start.toISOString(), duration_min: 50, recurrence: { weekdays: [1, 3], end_date: end } });
    expect(r2.status).toBe(201);
    const wd = (iso: string) => ((new Date(new Date(iso).getTime() + 7 * 3600e3).getUTCDay() + 6) % 7) + 1;
    expect(r2.body.sessions.every((s: { started_at: string }) => [1, 3].includes(wd(s.started_at)))).toBe(true);
    expect(r2.body.sessions.length).toBe(4);
    // thành viên không đặt lịch được
    const m = await t.groupWith(1);
    expect((await t.api('POST', `/v1/groups/${m.groupId}/schedules`, m.members[0].token, { start_time: start.toISOString(), duration_min: 25, recurrence: { weekdays: [1], end_date: end } })).body.code).toBe('NOT_GROUP_OWNER');
  });
});
