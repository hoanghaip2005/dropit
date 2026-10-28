import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { randomUUID } from 'node:crypto';
import { startServer, findSensitiveKeys, type TestServer } from './helpers.js';

let t: TestServer;
beforeAll(async () => {
  t = await startServer();
});
afterAll(async () => t?.close());

describe('Nhóm, mã mời, đồng ý (EP-02, BR-74/75/76, D-21, D-25)', () => {
  it('tạo nhóm → 201 GroupOwnerView, mã mời 8 ký tự đúng bảng mã', async () => {
    const o = await t.user('Chủ nhóm');
    const r = await t.api('POST', '/v1/groups', o.token, { name: 'Nhóm A', report_purpose: 'Mục đích' });
    expect(r.status).toBe(201);
    expect(r.body).toMatchObject({ name: 'Nhóm A', member_count: 0, below_minimum: true, status: 'ACTIVE', consent_version: 1 });
    expect(r.body.invite_code).toMatch(/^[A-HJKMNP-Z2-9]{8}$/);
    const mine = await t.api('GET', '/v1/me/groups', o.token);
    expect(mine.body.items.map((g: { role: string }) => g.role)).toEqual(['OWNER']);
  });

  it('thiếu Idempotency-Key → 400; gửi lại cùng khóa → phản hồi cũ; khác thân → 422 IDEMPOTENCY_MISMATCH', async () => {
    const o = await t.user('Chủ');
    const none = await t.api('POST', '/v1/groups', o.token, { name: 'X', report_purpose: 'Y' }, null);
    expect(none.status).toBe(400);
    const key = randomUUID();
    const a = await t.api('POST', '/v1/groups', o.token, { name: 'X', report_purpose: 'Y' }, key);
    const b = await t.api('POST', '/v1/groups', o.token, { name: 'X', report_purpose: 'Y' }, key);
    expect(b.status).toBe(201);
    expect(b.body.group_id).toBe(a.body.group_id);
    const c = await t.api('POST', '/v1/groups', o.token, { name: 'Z', report_purpose: 'Y' }, key);
    expect(c.status).toBe(422);
    expect(c.body.code).toBe('IDEMPOTENCY_MISMATCH');
  });

  it('tên nhóm > 60 ký tự → 400 (DQ-D10)', async () => {
    const o = await t.user('Chủ');
    const r = await t.api('POST', '/v1/groups', o.token, { name: 'x'.repeat(61), report_purpose: 'Y' });
    expect(r.status).toBe(400);
    expect(r.body.code).toBe('VALIDATION_FAILED');
  });

  it('xem mã → đồng ý → thành viên; thành viên không xem được mã mời (NOT_GROUP_OWNER)', async () => {
    const { owner, groupId, inviteCode } = await t.groupWith(0);
    const m = await t.user('Minh');
    const pv = await t.api('GET', `/v1/invites/${inviteCode}`, m.token);
    expect(pv.status).toBe(200);
    expect(pv.body).toMatchObject({ group_id: groupId, consent_version: 1, is_full: false });
    expect(pv.body.items.some((i: { code: string }) => i.code === 'RULE_D05')).toBe(true);
    const c = await t.api('POST', `/v1/groups/${groupId}/consent`, m.token, { consent_version: 1, invite_code: inviteCode, accepted_items: pv.body.items.map((i: { code: string }) => i.code) });
    expect(c.status).toBe(201);
    expect(c.body.role).toBe('MEMBER');
    expect((await t.api('GET', `/v1/groups/${groupId}/invite-code`, m.token)).body.code).toBe('NOT_GROUP_OWNER');
    expect((await t.api('GET', `/v1/groups/${groupId}/invite-code`, owner.token)).body.code).toBe(inviteCode);
  });

  it('chủ nhóm đồng ý vào nhóm mình → 409 OWNER_OF_THIS_GROUP (D-25)', async () => {
    const { owner, groupId, inviteCode } = await t.groupWith(0);
    const r = await t.api('POST', `/v1/groups/${groupId}/consent`, owner.token, { consent_version: 1, invite_code: inviteCode });
    expect(r.status).toBe(409);
    expect(r.body.code).toBe('OWNER_OF_THIS_GROUP');
  });

  it('đang ở nhóm A vào nhóm B → 409 ALREADY_IN_GROUP có tên nhóm A (BR-75, D-21)', async () => {
    const A = await t.groupWith(1);
    const B = await t.groupWith(0);
    const r = await t.api('POST', `/v1/groups/${B.groupId}/consent`, A.members[0].token, { consent_version: 1, invite_code: B.inviteCode });
    expect(r.status).toBe(409);
    expect(r.body.code).toBe('ALREADY_IN_GROUP');
    expect(r.body.detail).toContain('Nhóm');
  });

  it('consent_version cũ → 409 CONSENT_VERSION_STALE; sai mã → 404 INVITE_CODE_INVALID', async () => {
    const { groupId, inviteCode } = await t.groupWith(0);
    const m = await t.user('Nam');
    expect((await t.api('POST', `/v1/groups/${groupId}/consent`, m.token, { consent_version: 2, invite_code: inviteCode })).body.code).toBe('CONSENT_VERSION_STALE');
    expect((await t.api('POST', `/v1/groups/${groupId}/consent`, m.token, { consent_version: 1, invite_code: 'ABCDEFGH' })).body.code).toBe('INVITE_CODE_INVALID');
  });

  it('nhóm đủ 10 → người thứ 11 nhận 409 GROUP_FULL (BR-74)', async () => {
    const { groupId, inviteCode } = await t.groupWith(10);
    const m = await t.user('Người 11');
    const r = await t.api('POST', `/v1/groups/${groupId}/consent`, m.token, { consent_version: 1, invite_code: inviteCode });
    expect(r.status).toBe(409);
    expect(r.body.code).toBe('GROUP_FULL');
  });

  it('nhập sai mã 5 lần → lần 6 bị 429 INVITE_CODE_LOCKED kèm Retry-After (BR-76)', async () => {
    const m = await t.user('Sai Mã');
    for (let i = 0; i < 5; i++) expect((await t.api('GET', '/v1/invites/ZZZZZZZZ', m.token)).status).toBe(404);
    const r = await t.api('GET', '/v1/invites/ZZZZZZZZ', m.token);
    expect(r.status).toBe(429);
    expect(r.body.code).toBe('INVITE_CODE_LOCKED');
    expect(Number(r.headers.get('retry-after'))).toBeGreaterThan(0);
  });

  it('danh sách thành viên: sắp theo tên (BR-115), không Coins/chuỗi (BR-53); người ngoài → 403 FORBIDDEN_GROUP', async () => {
    const { owner, groupId, members } = await t.groupWith(4);
    const r = await t.api('GET', `/v1/groups/${groupId}/members`, owner.token);
    expect(r.status).toBe(200);
    expect(r.body.members.map((m: { display_name: string }) => m.display_name)).toEqual(['An', 'Bình', 'Chi', 'Dũng']);
    expect(r.body.member_count).toBe(4);
    expect(r.body.below_minimum).toBe(false);
    expect(findSensitiveKeys(r.body)).toEqual([]);
    const asMember = await t.api('GET', `/v1/groups/${groupId}/members`, members[0].token);
    expect(asMember.body.below_minimum).toBeNull();
    const outsider = await t.user('Ngoài');
    const f = await t.api('GET', `/v1/groups/${groupId}`, outsider.token);
    expect(f.status).toBe(403);
    expect(f.body.code).toBe('FORBIDDEN_GROUP');
  });

  it('không token → 401 UNAUTHENTICATED (problem+json)', async () => {
    const r = await t.api('GET', '/v1/me');
    expect(r.status).toBe(401);
    expect(r.headers.get('content-type')).toContain('application/problem+json');
    expect(r.body.code).toBe('UNAUTHENTICATED');
  });
});

describe('Đặt lịch một lần (US-02.10, BR-02, BR-78, BR-79)', () => {
  const at = (h: number) => new Date(Date.now() + h * 3600e3).toISOString();

  it('25 phút → 201; trùng giờ → 409 SCHEDULE_OVERLAP; sát sau phiên trước → 201 (biên nửa mở)', async () => {
    const { owner, groupId } = await t.groupWith(1);
    const start = new Date(Math.ceil(Date.now() / 3600e3) * 3600e3 + 2 * 3600e3);
    const a = await t.api('POST', `/v1/groups/${groupId}/schedules`, owner.token, { start_time: start.toISOString(), duration_min: 25 });
    expect(a.status).toBe(201);
    expect(a.body.sessions[0]).toMatchObject({ status: 'SCHEDULED', duration_min: 25 });
    const overlap = await t.api('POST', `/v1/groups/${groupId}/schedules`, owner.token, { start_time: new Date(start.getTime() + 10 * 60e3).toISOString(), duration_min: 50 });
    expect(overlap.status).toBe(409);
    expect(overlap.body.code).toBe('SCHEDULE_OVERLAP');
    const after = await t.api('POST', `/v1/groups/${groupId}/schedules`, owner.token, { start_time: new Date(start.getTime() + 25 * 60e3).toISOString(), duration_min: 50 });
    expect(after.status).toBe(201);
    const list = await t.api('GET', `/v1/groups/${groupId}/schedules`, owner.token);
    expect(list.body.items).toHaveLength(2);
  });

  it('241 phút → 422 DURATION_OUT_OF_RANGE; giờ quá khứ → 422 START_IN_PAST', async () => {
    const { owner, groupId } = await t.groupWith(0);
    expect((await t.api('POST', `/v1/groups/${groupId}/schedules`, owner.token, { start_time: at(3), duration_min: 241 })).body.code).toBe('DURATION_OUT_OF_RANGE');
    expect((await t.api('POST', `/v1/groups/${groupId}/schedules`, owner.token, { start_time: at(-1), duration_min: 25 })).body.code).toBe('START_IN_PAST');
  });

  it('thành viên đặt lịch → 403 NOT_GROUP_OWNER', async () => {
    const { members, groupId } = await t.groupWith(1);
    const r = await t.api('POST', `/v1/groups/${groupId}/schedules`, members[0].token, { start_time: at(5), duration_min: 25 });
    expect(r.status).toBe(403);
    expect(r.body.code).toBe('NOT_GROUP_OWNER');
  });
});
