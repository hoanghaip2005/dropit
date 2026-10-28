import { beforeAll, afterAll, describe, expect, it } from 'vitest';
import { startServer, emit, waitFor, sleep, type TestServer } from './helpers.js';

let t: TestServer;
beforeAll(async () => { t = await startServer({ lateJoinMs: 700, minuteMs: 2000 }); });
afterAll(async () => t?.close());

describe('Group management and custom schedules', () => {
  it('accepts 1..240 minutes, rejects invalid durations and paginates without duplicates', async () => {
    const { owner, groupId } = await t.groupWith(0);
    const start = new Date(Date.now() + 86400000);
    for (const [i, duration] of [1, 17, 240].entries()) {
      const response = await t.api('POST', `/v1/groups/${groupId}/schedules`, owner.token,
        { start_time: new Date(start.getTime() + i * 86400000).toISOString(), duration_min: duration });
      expect(response.status).toBe(201);
      expect(response.body.sessions[0].duration_min).toBe(duration);
    }
    for (const duration of [0, 241, 1.5]) {
      expect([400, 422]).toContain((await t.api('POST', `/v1/groups/${groupId}/schedules`, owner.token,
        { start_time: start.toISOString(), duration_min: duration })).status);
    }
    const first = await t.api('GET', `/v1/groups/${groupId}/schedules?limit=2`, owner.token);
    expect(first.body.items.map((s: { duration_min: number }) => s.duration_min)).toEqual([240, 17]);
    expect(first.body.next_cursor).toBeTypeOf('string');
    const second = await t.api('GET', `/v1/groups/${groupId}/schedules?limit=2&cursor=${first.body.next_cursor}`, owner.token);
    expect(second.body.items.map((s: { duration_min: number }) => s.duration_min)).toEqual([1]);
    expect(second.body.next_cursor).toBeNull();
    expect((await t.api('GET', `/v1/groups/${groupId}/schedules?limit=51`, owner.token)).status).toBe(400);
    expect((await t.api('GET', `/v1/groups/${groupId}/schedules?cursor=garbage`, owner.token)).status).toBe(422);
  });

  it('only owner can dissolve; closes memberships/invite, cancels future schedules, retains history', async () => {
    const { owner, members, groupId, inviteCode } = await t.groupWith(1);
    const sid = await t.schedule(owner.token, groupId, 3600000, 17);
    expect((await t.api('DELETE', `/v1/groups/${groupId}`, members[0].token)).status).toBe(403);
    const idem = crypto.randomUUID();
    expect((await t.api('DELETE', `/v1/groups/${groupId}`, owner.token, undefined, idem)).status).toBe(204);
    expect((await t.api('DELETE', `/v1/groups/${groupId}`, owner.token, undefined, idem)).status).toBe(204);
    expect((await t.api('DELETE', `/v1/groups/${groupId}`, owner.token)).status).toBe(204);
    expect((await t.api('GET', '/v1/me/groups', owner.token)).body.items).toEqual([]);
    expect((await t.api('GET', '/v1/me/groups', members[0].token)).body.items).toEqual([]);
    expect((await t.api('GET', `/v1/invites/${inviteCode}`, members[0].token)).status).toBe(404);
    expect((await t.api('GET', `/v1/groups/${groupId}`, owner.token)).status).toBe(404);
    const session = await t.db.selectFrom('sessions').selectAll().where('id', '=', sid).executeTakeFirstOrThrow();
    expect(session).toMatchObject({ status: 'CANCELLED', cancel_reason: 'GROUP_DISSOLVED' });
    const membership = await t.db.selectFrom('group_members').selectAll().where('group_id', '=', groupId).executeTakeFirstOrThrow();
    expect(membership.leave_reason).toBe('GROUP_DISSOLVED');
    expect(membership.left_at).not.toBeNull();
  });

  it('allows first attendee after start during admission window; active group cannot be dissolved', async () => {
    const { owner, members, groupId } = await t.groupWith(1);
    const sid = await t.schedule(owner.token, groupId, 1000, 1);
    await waitFor(async () => (await t.db.selectFrom('sessions').select('status').where('id', '=', sid).executeTakeFirst())?.status === 'ACTIVE');
    const before = await t.api('GET', `/v1/sessions/${sid}`, members[0].token);
    expect(before.body.status).toBe('ACTIVE');
    expect(before.body.late_join_deadline).toBeTypeOf('string');
    const sock = await t.sock(members[0].token);
    expect(await emit(sock, 'session:join', { session_id: sid })).toMatchObject({ ok: true, state: 'FOCUSING' });
    expect((await t.api('DELETE', `/v1/groups/${groupId}`, owner.token)).body.code).toBe('SESSION_IN_PROGRESS');
    await waitFor(async () => (await t.db.selectFrom('sessions').select('status').where('id', '=', sid).executeTakeFirst())?.status === 'COMPLETED');
    const member = await t.db.selectFrom('session_members').selectAll().where('session_id', '=', sid).executeTakeFirstOrThrow();
    expect(member).toMatchObject({ state: 'COMPLETED', late_join: true });
    sock.disconnect();
  });

  it('does not cancel at start with no attendees, cancels only after admission deadline', async () => {
    const { owner, members, groupId } = await t.groupWith(1);
    const sid = await t.schedule(owner.token, groupId, 1000, 1);
    await waitFor(async () => (await t.db.selectFrom('sessions').select('status').where('id', '=', sid).executeTakeFirst())?.status === 'ACTIVE');
    await sleep(150);
    expect((await t.db.selectFrom('sessions').select('status').where('id', '=', sid).executeTakeFirstOrThrow()).status).toBe('ACTIVE');
    await waitFor(async () => (await t.db.selectFrom('sessions').select('status').where('id', '=', sid).executeTakeFirst())?.status === 'CANCELLED');
    expect((await t.db.selectFrom('sessions').select('cancel_reason').where('id', '=', sid).executeTakeFirstOrThrow()).cancel_reason).toBe('NO_ATTENDEE');
    const sock = await t.sock(members[0].token);
    expect(await emit(sock, 'session:join', { session_id: sid })).toMatchObject({ ok: false, code: 'SESSION_NOT_ACTIVE' });
    sock.disconnect();
  });
});
