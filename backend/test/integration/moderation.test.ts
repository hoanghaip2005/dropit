import { redactBlockedText } from '../../src/modules/moderation/redaction.js';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { randomUUID } from 'node:crypto';
import { startServer, type TestServer } from './helpers.js';
let t: TestServer;
beforeAll(async () => { t = await startServer(); });
afterAll(async () => { await t?.close(); });
describe('UGC reports and blocking', () => {
  it('requires shared group, validates subject/reason, retains report privately and replays safely', async () => {
    const { owner, members, groupId } = await t.groupWith(1);
    const outsider = await t.user('Outsider');
    const input = { user_id: owner.id, group_id: groupId, reason: 'HARASSMENT', details: 'Test-only report' };
    expect((await t.api('POST', '/v1/moderation/reports', outsider.token, input)).status).toBe(403);
    expect((await t.api('POST', '/v1/moderation/reports', owner.token, input)).status).toBe(400);
    expect((await t.api('POST', '/v1/moderation/reports', members[0].token, {...input, reason:'INVALID'})).status).toBe(400);
    const key = randomUUID();
    const a = await t.api('POST', '/v1/moderation/reports', members[0].token, input, key);
    const b = await t.api('POST', '/v1/moderation/reports', members[0].token, input, key);
    expect(a.status).toBe(201); expect(b.body.report_id).toBe(a.body.report_id);
    expect((await t.db.selectFrom('moderation_reports').selectAll().where('id','=',a.body.report_id).executeTakeFirst())?.reporter_id).toBe(members[0].id);
    expect((await t.api('GET', '/v1/moderation/reports', owner.token)).status).toBe(404);
  });
  it('infers shared group; block persists, hides profile both ways and redacts roster; unblock restores', async () => {
    const { owner, members, groupId } = await t.groupWith(1);
    const m=members[0];
    expect((await t.api('PUT', `/v1/me/blocks/${owner.id}`, m.token, {})).status).toBe(200);
    expect((await t.api('GET','/v1/me/blocks',m.token)).body.items[0].user_id).toBe(owner.id);
    expect((await t.api('GET',`/v1/users/${owner.id}/public-profile`,m.token)).status).toBe(404);
    expect((await t.api('GET',`/v1/users/${m.id}/public-profile`,owner.token)).status).toBe(404);
    const roster=await t.api('GET',`/v1/groups/${groupId}/members`,m.token);
    expect(roster.body.owner.display_name).toBe('Người dùng đã chặn');
    expect(roster.body.owner.avatar_url).toBeNull();    const env = await redactBlockedText(t.db,m.id,{lobby_members:[owner.name],forfeit_trigger_display_name:owner.name,user_id:owner.id,coins_awarded:17});
    expect(env.lobby_members[0]).not.toBe(owner.name);
    expect(env.forfeit_trigger_display_name).not.toBe(owner.name);
    expect(env.user_id).toBe(owner.id); expect(env.coins_awarded).toBe(17);
    await t.srv.ctx.notifications.notify([m.id],{type:'TEST',title:owner.name,body:`${owner.name} test`,data:{user_id:owner.id},dedupeKey:randomUUID()});
    const inbox=await t.api('GET','/v1/me/notifications',m.token);
    expect(inbox.body.items[0].title).not.toBe(owner.name);
    expect(inbox.body.items[0].body).not.toContain(owner.name);
    expect((await t.api('DELETE',`/v1/me/blocks/${owner.id}`,m.token)).status).toBe(204);
    expect((await t.api('GET',`/v1/users/${owner.id}/public-profile`,m.token)).status).toBe(200);
  });
});

