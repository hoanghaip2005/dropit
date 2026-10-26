import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { randomUUID } from 'node:crypto';
import { startServer, type TestServer } from './helpers.js';
import { simulateSession } from './sim.js';
import { vnDay } from '../../src/shared/time.js';

let t: TestServer;
beforeAll(async () => { t = await startServer({ coinsDailyCap: 77 }); });
afterAll(async () => t?.close());

describe('History result and daily reward contracts', () => {
  it('returns authenticated own reward-day total, not balance, created date or history page', async () => {
    expect((await t.api('GET', '/v1/me/rewards/today')).status).toBe(401);
    const u = await t.user('RewardHistory');
    const other = await t.user('OtherRewardHistory');
    const day = vnDay(new Date());
    const yesterday = new Date(Date.now() - 86400e3);
    expect((await t.api('GET', '/v1/me/rewards/today', u.token)).body)
      .toEqual({ reward_date: day, coins_awarded: 0, daily_cap: 77 });
    for (const entry of [
      { user_id: u.id, amount: 10, type: 'SESSION_REWARD' as const, reward_date: day, created_at: yesterday },
      { user_id: u.id, amount: 25, type: 'SESSION_REWARD' as const, reward_date: day, created_at: new Date() },
      { user_id: u.id, amount: 20, type: 'SESSION_REWARD' as const, reward_date: vnDay(yesterday), created_at: new Date() },
      { user_id: u.id, amount: 5, type: 'ADMIN_ADJUST' as const, reward_date: null, created_at: new Date() },
      { user_id: other.id, amount: 50, type: 'SESSION_REWARD' as const, reward_date: day, created_at: new Date() },
    ]) {
      await t.db.insertInto('coin_ledger').values({ ...entry, ref_id: randomUUID(), reason: 'CONTRACT_TEST',
        idempotency_key: randomUUID(), balance_after: 0,
        created_by: entry.type === 'ADMIN_ADJUST' ? u.id : null }).execute();
    }
    expect((await t.api('GET', '/v1/me/rewards/today', u.token)).body)
      .toEqual({ reward_date: day, coins_awarded: 35, daily_cap: 77 });
    expect((await t.api('GET', '/v1/me/rewards/today', other.token)).body.coins_awarded).toBe(50);
  });

  it('keeps one-participant group sessions SQUAD and returns exact own nullable timestamps', async () => {
    const { owner, members, groupId } = await t.groupWith(1);
    const u = members[0];
    const start = new Date(Date.now() - 3600e3);
    const { sessionId } = await simulateSession(t, {
      groupId, ownerId: owner.id, startedAt: start, members: [{ id: u.id, state: 'EXITED', exitAtMin: 7 }],
    });
    const sm = await t.db.selectFrom('session_members').selectAll()
      .where('session_id', '=', sessionId).where('user_id', '=', u.id).executeTakeFirstOrThrow();
    const expected = { session_mode: 'SQUAD', joined_at: sm.joined_at!.toISOString(),
      exited_at: sm.exited_at!.toISOString(), ended_at: sm.ended_at!.toISOString() };
    expect((await t.api('GET', `/v1/sessions/${sessionId}/result`, u.token)).body).toMatchObject(expected);
    const session = await t.db.selectFrom('sessions').select('ends_at')
      .where('id', '=', sessionId).executeTakeFirstOrThrow();
    expect((await t.api('GET', `/v1/sessions/${sessionId}/result`, u.token)).body).toMatchObject({
      reward_daily_cap: 77, has_explanation: false,
      explanation_submit_deadline: new Date(session.ends_at.getTime() + t.cfg.explanationSubmitDays * 86400e3).toISOString(),
    });
    const submitted = await t.api('PUT', `/v1/sessions/${sessionId}/explanation`, u.token, { body: 'Lý do cá nhân' });
    expect(submitted.status).toBe(200);
    expect(submitted.body).toMatchObject({ can_edit: true, body: 'Lý do cá nhân', history: [] });
    expect(submitted.body.edit_deadline).toBe(new Date(Date.parse(submitted.body.submitted_at) + t.cfg.explanationEditH * 3600e3).toISOString());
    expect(typeof submitted.body.version).toBe('number');
    const edited = await t.api('PUT', `/v1/sessions/${sessionId}/explanation`, u.token, { body: 'Lý do bổ sung' });
    expect(edited.body.history).toHaveLength(1);
    expect(edited.body.history[0].body).toBe('Lý do cá nhân');
    expect(edited.body.can_edit).toBe(true);
    expect((await t.api('GET', `/v1/sessions/${sessionId}/result`, u.token)).body.has_explanation).toBe(true);
    const history = await t.api('GET', '/v1/me/sessions?limit=1', u.token);
    expect(history.body.items[0]).toMatchObject({ session_id: sessionId, ...expected });
    expect((await t.api('GET', `/v1/me/sessions/${sessionId}`, owner.token)).status).toBe(403);

    const absent = await simulateSession(t, { groupId, ownerId: owner.id,
      startedAt: new Date(start.getTime() - 3600e3), members: [{ id: u.id, state: 'ABSENT' }] });
    expect((await t.api('GET', `/v1/me/sessions/${absent.sessionId}`, u.token)).body)
      .toMatchObject({ session_mode: 'SQUAD', joined_at: null, exited_at: null,
        ended_at: new Date(Math.floor((start.getTime() - 3600e3) / 1000) * 1000).toISOString() });

    const sessionStart = new Date(Math.floor(start.getTime() / 1000) * 1000);
    const range = `from=${encodeURIComponent(sessionStart.toISOString())}&to=${encodeURIComponent(new Date(sessionStart.getTime() + 1).toISOString())}`;
    const bounded = await t.api('GET', `/v1/me/sessions?limit=1&${range}`, u.token);
    expect(bounded.body.items.map((item: { session_id: string }) => item.session_id)).toEqual([sessionId]);
    expect(bounded.body.next_cursor).toBeNull();
    const before = `from=${encodeURIComponent(new Date(sessionStart.getTime() - 1).toISOString())}&to=${encodeURIComponent(sessionStart.toISOString())}`;
    expect((await t.api('GET', `/v1/me/sessions?${before}`, u.token)).body.items).toEqual([]);
    const both = `from=${encodeURIComponent(new Date(sessionStart.getTime() - 3600e3).toISOString())}&to=${encodeURIComponent(new Date(sessionStart.getTime() + 1).toISOString())}`;
    const firstPage = await t.api('GET', `/v1/me/sessions?limit=1&${both}`, u.token);
    expect(firstPage.body.items[0].session_id).toBe(sessionId);
    expect(firstPage.body.next_cursor).toEqual(expect.any(String));
    const secondPage = await t.api('GET', `/v1/me/sessions?limit=1&${both}&cursor=${encodeURIComponent(firstPage.body.next_cursor)}`, u.token);
    expect(secondPage.body.items.map((item: { session_id: string }) => item.session_id)).toEqual([absent.sessionId]);
    expect(secondPage.body.next_cursor).toBeNull();
    const outsider = await t.user('HistoryOutsider');
    expect((await t.api('GET', `/v1/me/sessions?${range}`, outsider.token)).body.items).toEqual([]);
    for (const invalid of ['from=no-date', `from=${sessionStart.toISOString()}&to=${sessionStart.toISOString()}`]) {
      expect((await t.api('GET', `/v1/me/sessions?${invalid}`, u.token)).status).toBe(400);
    }
  });
});
