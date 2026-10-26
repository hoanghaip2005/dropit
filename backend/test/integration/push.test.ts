import { randomUUID } from 'node:crypto';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { startServer, waitFor, type TestServer } from './helpers.js';
import { ConsoleNotificationSender, NotificationService } from '../../src/modules/notifications/service.js';
import { SnsNotificationSender, type SnsTransport } from '../../src/modules/notifications/sns.js';

describe('authenticated SNS registration and durable push', () => {
  let s: TestServer;
  let failure: string | null = null;
  const published: string[] = [];
  const transport: SnsTransport = {
    endpoint: async token => `arn:test:${token}`,
    enable: async () => {},
    publish: async (_, message) => {
      if (failure) throw Object.assign(new Error('redacted'), { name: failure });
      published.push(message);
    },
  };
  beforeAll(async () => {
    s = await startServer();
    const nsp = s.srv.ctx.notifications.nsp;
    s.srv.ctx.notifications = new NotificationService(s.db, new SnsNotificationSender(s.db, transport));
    s.srv.ctx.notifications.nsp = nsp;
  });
  afterAll(async () => { await s?.close(); });
  it('requires authentication and binds registration to current user; late logout cannot delete a new owner', async () => {
    const a = await s.user('PushA'); const b = await s.user('PushB');
    const id = randomUUID(); const token = `fake-fcm-${randomUUID()}`;
    const path = `/v1/me/devices/${id}/push`;
    expect((await s.api('PUT', path, undefined, { token, platform: 'ANDROID' })).status).toBe(401);
    expect((await s.api('PUT', path, a.token, { token, platform: 'ANDROID', user_id: b.id })).status).toBe(400);
    expect((await s.api('PUT', path, a.token, { token, platform: 'ANDROID' })).status).toBe(204);
    expect((await s.api('PUT', path, b.token, { token, platform: 'IOS' })).status).toBe(204);
    expect((await s.api('DELETE', path, a.token)).status).toBe(204);
    const bound = await s.db.selectFrom('device_tokens').selectAll().where('device_id', '=', id).execute();
    expect(bound).toHaveLength(1); expect(bound[0].user_id).toBe(b.id);
    const rotated = `rotated-fcm-${randomUUID()}`;
    await s.api('PUT', path, b.token, { token: rotated, platform: 'IOS' });
    expect(await s.db.selectFrom('device_tokens').selectAll().where('token', '=', token).execute()).toHaveLength(0);
    await s.api('DELETE', path, b.token);
    await s.api('DELETE', path, b.token);
    expect(await s.db.selectFrom('device_tokens').selectAll().where('device_id', '=', id).execute()).toHaveLength(0);
  });
  it('persists transient failures, retries once and retains inbox', async () => {
    const u = await s.user('PushRetry'); const id = randomUUID(); const event = randomUUID();
    await s.api('PUT', `/v1/me/devices/${id}/push`, u.token, { token: `fcm-${randomUUID()}`, platform: 'ANDROID' });
    failure = 'ThrottlingException';
    await s.srv.ctx.notifications.notify([u.id], { type: 'SESSION_RESULT', title: 'private', body: 'private', data: {}, dedupeKey: event });
    await s.srv.ctx.notifications.flushPush();
    await waitFor(async () => (await s.db.selectFrom('notifications').select('push_attempts').where('dedupe_key', '=', event).executeTakeFirst())?.push_attempts === 1);
    let n = await s.db.selectFrom('notifications').selectAll().where('dedupe_key', '=', event).executeTakeFirstOrThrow();
    expect(n.push_status).toBe('PENDING'); expect(n.push_attempts).toBe(1);
    failure = null;
    await s.db.updateTable('notifications').set({ push_next_at: new Date(0) }).where('id', '=', n.id).execute();
    // A new service instance can resume persisted work after restart.
    await new NotificationService(s.db, new SnsNotificationSender(s.db, transport)).flushPush();
    await waitFor(async () => {
      await s.srv.ctx.notifications.flushPush();
      return (await s.db.selectFrom('notifications').select('push_status').where('id', '=', n.id).executeTakeFirst())?.push_status === 'SENT';
    });
    n = await s.db.selectFrom('notifications').selectAll().where('id', '=', n.id).executeTakeFirstOrThrow();
    expect(n.push_status).toBe('SENT'); expect(n.push_attempts).toBe(2);
    expect(published.at(-1)).not.toContain('private');
    expect((await s.api('GET', '/v1/me/notifications', u.token)).body.items[0].event_id).toBe(event);
  });
  it('removes disabled endpoint and stops bounded failures without dropping inbox', async () => {
    const u = await s.user('PushInvalid'); const device = randomUUID();
    await s.api('PUT', `/v1/me/devices/${device}/push`, u.token, { token: `fcm-${randomUUID()}`, platform: 'ANDROID' });
    failure = 'EndpointDisabledException';
    await s.srv.ctx.notifications.notify([u.id], { type: 'NEW', title: '', body: '', data: {}, dedupeKey: randomUUID() });
    await s.srv.ctx.notifications.flushPush();
    await waitFor(async () => !(await s.db.selectFrom('device_tokens').select('id').where('device_id', '=', device).executeTakeFirst()));
    expect(await s.db.selectFrom('device_tokens').selectAll().where('device_id', '=', device).execute()).toHaveLength(0);
    await s.api('PUT', `/v1/me/devices/${device}/push`, u.token, { token: `fcm-${randomUUID()}`, platform: 'ANDROID' });
    failure = 'ThrottlingException'; const event = randomUUID();
    await s.srv.ctx.notifications.notify([u.id], { type: 'NEW', title: '', body: '', data: {}, dedupeKey: event });
    await s.srv.ctx.notifications.flushPush();
    await waitFor(async () => (await s.db.selectFrom('notifications').select('push_attempts').where('dedupe_key', '=', event).executeTakeFirst())?.push_attempts === 1);
    await s.db.updateTable('notifications').set({ push_next_at: new Date(0) }).where('dedupe_key', '=', event).execute();
    await s.srv.ctx.notifications.flushPush();
    await waitFor(async () => {
      await s.srv.ctx.notifications.flushPush();
      return (await s.db.selectFrom('notifications').select('push_status').where('dedupe_key', '=', event).executeTakeFirst())?.push_status === 'FAILED';
    });
    expect((await s.db.selectFrom('notifications').selectAll().where('dedupe_key', '=', event).executeTakeFirstOrThrow()).push_status).toBe('FAILED');
    failure = null;
  });
  it('suppresses lockscreen delivery during an active session and retains inbox', async () => {
    const { owner, members, groupId } = await s.groupWith(1, 'PushOwner');
    const u = members[0]; const sessionId = await s.schedule(owner.token, groupId, 3600000);
    await s.db.insertInto('session_members').values({ session_id: sessionId, user_id: u.id,
      state: 'WAITING', joined_at: new Date(), exited_at: null, ended_at: null, end_reason: null }).execute();
    const socket = await s.sock(u.token);
    const before = published.length; const event = randomUUID();
    await s.srv.ctx.notifications.notify([u.id], { type: 'NEW', title: 'private', body: 'private', data: {}, dedupeKey: event });
    await s.srv.ctx.notifications.flushPush();
    expect(published).toHaveLength(before);
    expect(await s.db.selectFrom('notifications').select('id').where('dedupe_key', '=', event).execute()).toHaveLength(1);
    expect((await s.db.selectFrom('notifications').select('push_status').where('dedupe_key', '=', event).executeTakeFirstOrThrow()).push_status).toBe('PENDING');
    expect(socket.events.find(e => e.payload.event_id === event)).toBeUndefined();
    socket.disconnect();
    await s.db.updateTable('sessions').set({ status: 'CANCELLED', cancelled_at: new Date(), cancel_reason: 'ADMIN' })
      .where('id', '=', sessionId).execute();
  });
  it('does not mark an absent device as sent and recovers an expired lease', async () => {
    const u = await s.user('NoPushDevice'); const event = randomUUID();
    await s.srv.ctx.notifications.notify([u.id], { type: 'NEW', title: '', body: '', data: {}, dedupeKey: event });
    const before = published.length;
    await s.db.updateTable('notifications').set({ push_lease_until: new Date(0), push_next_at: new Date(0) })
      .where('dedupe_key', '=', event).execute();
    await s.srv.ctx.notifications.flushPush();
    await waitFor(async () => {
      await s.srv.ctx.notifications.flushPush();
      return (await s.db.selectFrom('notifications').select('push_status').where('dedupe_key', '=', event).executeTakeFirst())?.push_status === 'NONE';
    });
    const row = await s.db.selectFrom('notifications').selectAll().where('dedupe_key', '=', event).executeTakeFirstOrThrow();
    expect(row.push_status).toBe('NONE'); expect(row.push_lease_until).toBeNull();
    expect(published).toHaveLength(before);
  });
  it('delivers queued work via socket when the user comes online instead of push', async () => {
    const u = await s.user('PushOnline'); const event = randomUUID();
    await s.srv.ctx.notifications.saveInbox([u.id], { type: 'NEW', title: '', body: '', data: {}, dedupeKey: event });
    await s.db.updateTable('notifications').set({ push_status: 'PENDING', push_payload: JSON.stringify({
      title: 'DropIt!', body: '', data: { type: 'NEW', event_id: event } }), push_next_at: new Date(Date.now() + 60000) })
      .where('dedupe_key', '=', event).execute();
    const socket = await s.sock(u.token);
    try {
      const before = published.length;
      await s.db.updateTable('notifications').set({ push_next_at: new Date(0) }).where('dedupe_key', '=', event).execute();
      await s.srv.ctx.notifications.flushPush();
      await waitFor(() => socket.events.find(e => e.payload.event_id === event));
      expect(published).toHaveLength(before);
      expect((await s.db.selectFrom('notifications').select('push_status').where('dedupe_key', '=', event).executeTakeFirstOrThrow()).push_status).toBe('NONE');
    } finally { socket.disconnect(); }
  });
  it('keeps login and inbox usable while registration is unavailable', async () => {
    const u = await s.user('PushUnconfigured'); const existing = s.srv.ctx.notifications;
    s.srv.ctx.notifications = new NotificationService(s.db, new ConsoleNotificationSender(true));
    try {
      const response = await s.api('PUT', `/v1/me/devices/${randomUUID()}/push`, u.token,
        { token: `fcm-${randomUUID()}`, platform: 'ANDROID' });
      expect(response.status).toBe(503); expect(response.body.code).toBe('PUSH_UNAVAILABLE');
      expect((await s.api('GET', '/v1/me', u.token)).status).toBe(200);
      expect((await s.api('GET', '/v1/me/notifications', u.token)).status).toBe(200);
    } finally { s.srv.ctx.notifications = existing; }
  });
});
