import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { startServer, type TestServer } from './helpers.js';
let t: TestServer;
beforeAll(async () => { t = await startServer(); });
afterAll(async () => { await t?.close(); });
describe('account erasure', () => {
  it('requires explicit confirmation and rejects the stale token after erasure without recreating a user', async () => {
    const owner = await t.user('Erase owner');
    expect((await t.api('DELETE', '/v1/me/account', owner.token, {})).status).toBe(400);
    const group = await t.api('POST', '/v1/groups', owner.token, { name: 'Erase group', report_purpose: 'Erase purpose' });
    const socket = await t.sock(owner.token);
    expect((await t.api('DELETE', '/v1/me/account', owner.token, { confirmation: 'DELETE' })).status).toBe(204);
    expect((await t.api('GET', '/v1/me', owner.token)).status).toBe(401);
    expect((await t.api('DELETE', '/v1/me/account', owner.token, { confirmation: 'DELETE' })).status).toBe(204);
    const user = await t.db.selectFrom('users').selectAll().where('id', '=', owner.id).executeTakeFirstOrThrow();
    expect(user).toMatchObject({ status: 'DELETED', email: null, avatar_key: null, display_name: 'Người dùng đã xóa' });
    expect(user.cognito_sub).toMatch(/^deleted:/);
    expect((await t.db.selectFrom('groups').selectAll().where('id', '=', group.body.group_id).executeTakeFirstOrThrow()).status).toBe('DISSOLVED');
    await new Promise(r => setTimeout(r, 50));
    expect(socket.connected).toBe(false);
    socket.disconnect();
  });
  it('purges private journal/coin content and permits retry when Cognito is unavailable', async () => {
    const member = await t.user('Erase private');
    await t.db.insertInto('journals').values({user_id: member.id, day: '2026-10-31', ciphertext: Buffer.from('private'), nonce: Buffer.alloc(12), encrypted_dek: Buffer.from('key'), kms_key_id: 'test', char_count: 7}).execute();
    const realFetch = globalThis.fetch;
    const remote = vi.spyOn(globalThis, 'fetch').mockImplementation((input, init) => {
      if (String(input).startsWith('https://cognito-idp.')) return Promise.resolve(new Response(null, {status: 503}));
      return realFetch(input, init);
    });
    t.cfg.cognitoRegion = 'ap-southeast-1';
    try {
      const response = await t.api('DELETE', '/v1/me/account', member.token, {confirmation:'DELETE'});
      expect(response.status).toBe(503);
      expect(response.body.code).toBe('IDENTITY_DELETION_UNAVAILABLE');
      expect((await t.api('GET', '/v1/me', member.token)).status).toBe(401);
      expect(await t.db.selectFrom('journals').selectAll().where('user_id', '=', member.id).execute()).toEqual([]);
      remote.mockImplementation((input, init) => String(input).startsWith('https://cognito-idp.')
        ? Promise.resolve(new Response(null, {status:200})) : realFetch(input, init));
      expect((await t.api('DELETE', '/v1/me/account', member.token, {confirmation:'DELETE'})).status).toBe(204);
    } finally {
      t.cfg.cognitoRegion = undefined;
      remote.mockRestore();
    }
  });});


