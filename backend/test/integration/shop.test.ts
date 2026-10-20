import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { randomUUID } from 'node:crypto';
import { startServer, type TestServer } from './helpers.js';
import { simulateSession, pastSlots } from './sim.js';
import { awardBadges } from '../../src/modules/achievements/service.js';
import { vnDay } from '../../src/shared/time.js';

let t: TestServer;
const slot = pastSlots(800);
beforeAll(async () => {
  t = await startServer();
});
afterAll(async () => t?.close());

const tag = randomUUID().slice(0, 6);
async function item(kind: 'AVATAR_FRAME' | 'BACKGROUND' | 'TITLE', price: number, status: 'ON_SALE' | 'HIDDEN' = 'ON_SALE') {
  return (await t.db.insertInto('shop_items').values({ kind, name: `Test ${tag} ${kind} ${price}`, preview_key: `test_${tag}`, price, status }).returning('id').executeTakeFirstOrThrow()).id;
}
async function grant(userId: string, amount: number) {
  await t.db.insertInto('coin_ledger').values({
    user_id: userId, amount, type: 'SESSION_REWARD', ref_id: randomUUID(), reward_date: vnDay(new Date()), reason: 'TEST_GRANT',
    idempotency_key: `test:${randomUUID()}`, balance_after: 0, created_by: null,
  }).execute();
}
const balance = async (token: string) => (await t.api('GET', '/v1/me/coins', token)).body.balance as number;

describe('Shop (EP-06, BR-93…96, BR-121)', () => {
  it('danh mục chỉ món ĐANG BÁN, lọc theo loại, cờ owned; không món mặc định/ẩn', async () => {
    const u = await t.user('Mua');
    const frame = await item('AVATAR_FRAME', 30);
    const hidden = await item('BACKGROUND', 40, 'HIDDEN');
    const all = await t.api('GET', '/v1/shop/items', u.token);
    expect(all.status).toBe(200);
    const ids = all.body.items.map((i: { item_id: string }) => i.item_id);
    expect(ids).toContain(frame);
    expect(ids).not.toContain(hidden);
    expect(all.body.items.every((i: { status: string; price: number }) => i.status === 'ON_SALE' && i.price > 0)).toBe(true);
    const frames = await t.api('GET', '/v1/shop/items?kind=AVATAR_FRAME', u.token);
    expect(frames.body.items.every((i: { kind: string }) => i.kind === 'AVATAR_FRAME')).toBe(true);
    expect(frames.body.items.find((i: { item_id: string }) => i.item_id === frame)).toMatchObject({ owned: false, price: 30, preview_url: expect.stringContaining('/assets/shop/') });
  });

  it('mua: thiếu Coins 422 → đủ thì 201, ghi SHOP_PURCHASE âm + sở hữu; idempotency; đã sở hữu 409; đổi giá 409; ẩn 422', async () => {
    const u = await t.user('Mua');
    const frame = await item('AVATAR_FRAME', 30);
    const r0 = await t.api('POST', '/v1/shop/purchases', u.token, { item_id: frame, expected_price: 30 });
    expect(r0).toMatchObject({ status: 422, body: { code: 'INSUFFICIENT_COINS' } });
    await grant(u.id, 50);
    const key = randomUUID();
    const r1 = await t.api('POST', '/v1/shop/purchases', u.token, { item_id: frame, expected_price: 30 }, key);
    expect(r1).toMatchObject({ status: 201, body: { item_id: frame, balance: 20 } });
    const again = await t.api('POST', '/v1/shop/purchases', u.token, { item_id: frame, expected_price: 30 }, key);
    expect(again.status).toBe(201);
    expect(again.headers.get('idempotent-replayed')).toBe('true');
    expect(await balance(u.token)).toBe(20); // không trừ hai lần
    expect((await t.api('POST', '/v1/shop/purchases', u.token, { item_id: frame, expected_price: 30 })).body.code).toBe('ALREADY_OWNED');
    const led = await t.db.selectFrom('coin_ledger').selectAll().where('user_id', '=', u.id).where('type', '=', 'SHOP_PURCHASE').execute();
    expect(led).toEqual([expect.objectContaining({ amount: -30, balance_after: 20 })]);
    const own = await t.db.selectFrom('user_items').selectAll().where('user_id', '=', u.id).execute();
    expect(own).toEqual([expect.objectContaining({ item_id: frame, price_paid: 30, ledger_entry_id: led[0].entry_id })]); // BR-121: đúng 1 item_id
    // đổi giá
    const bg = await item('BACKGROUND', 15);
    await t.db.updateTable('shop_items').set({ price: 18 }).where('id', '=', bg).execute();
    expect((await t.api('POST', '/v1/shop/purchases', u.token, { item_id: bg, expected_price: 15 })).body.code).toBe('PRICE_CHANGED');
    expect(await balance(u.token)).toBe(20);
    // ẩn / không tồn tại
    const hid = await item('TITLE', 10, 'HIDDEN');
    expect((await t.api('POST', '/v1/shop/purchases', u.token, { item_id: hid, expected_price: 10 })).body.code).toBe('ITEM_UNAVAILABLE');
    expect((await t.api('POST', '/v1/shop/purchases', u.token, { item_id: randomUUID(), expected_price: 10 })).body.code).toBe('ITEM_UNAVAILABLE');
    // thiếu Idempotency-Key
    expect((await t.api('POST', '/v1/shop/purchases', u.token, { item_id: bg, expected_price: 18 }, null)).status).toBe(400);
    const list = await t.api('GET', '/v1/shop/items?kind=AVATAR_FRAME', u.token);
    expect(list.body.items.find((i: { item_id: string }) => i.item_id === frame).owned).toBe(true);
  });

  it('mua đồng thời hai món khi chỉ đủ tiền một món → đúng một thành công, số dư không âm (BR-45)', async () => {
    const u = await t.user('Đua');
    const a = await item('BACKGROUND', 40);
    const b = await item('BACKGROUND', 41);
    await grant(u.id, 50);
    const rs = await Promise.all([
      t.api('POST', '/v1/shop/purchases', u.token, { item_id: a, expected_price: 40 }),
      t.api('POST', '/v1/shop/purchases', u.token, { item_id: b, expected_price: 41 }),
    ]);
    expect(rs.map((r) => r.status).sort()).toEqual([201, 422]);
    expect(await balance(u.token)).toBeGreaterThanOrEqual(0);
  });

  it('trang bị món đã sở hữu; chưa sở hữu/sai loại 422 ITEM_NOT_OWNED; gỡ về mặc định; đồ của tôi', async () => {
    const u = await t.user('Mặc');
    const frame = await item('AVATAR_FRAME', 20);
    const other = await item('AVATAR_FRAME', 21);
    await grant(u.id, 20);
    await t.api('POST', '/v1/shop/purchases', u.token, { item_id: frame, expected_price: 20 });
    expect((await t.api('PUT', '/v1/me/equipment', u.token, { frame_item_id: other })).body.code).toBe('ITEM_NOT_OWNED');
    expect((await t.api('PUT', '/v1/me/equipment', u.token, { background_item_id: frame })).body.code).toBe('ITEM_NOT_OWNED');
    const eq = await t.api('PUT', '/v1/me/equipment', u.token, { frame_item_id: frame });
    expect(eq.status).toBe(200);
    expect(eq.body.frame_item_id).toBe(frame);
    const inv = await t.api('GET', '/v1/me/inventory', u.token);
    expect(inv.body.items.find((i: { item_id: string }) => i.item_id === frame)).toMatchObject({ equipped: true, kind: 'AVATAR_FRAME' });
    const off = await t.api('PUT', '/v1/me/equipment', u.token, { frame_item_id: null });
    const def = await t.db.selectFrom('shop_items').select('id').where('kind', '=', 'AVATAR_FRAME').where('is_default', '=', true).executeTakeFirst();
    expect(off.body.frame_item_id).toBe(def?.id ?? null); // BR-95: gỡ → món mặc định
    expect((await t.api('PUT', '/v1/me/equipment', u.token, { bogus: 1 })).status).toBe(400);
  });
});

describe('Thành tích (EP-05)', () => {
  it('chuỗi/điểm danh/lịch sử chỉ của chính tôi; huy hiệu theo mốc; trưng bày tối đa 3', async () => {
    const { owner, members, groupId } = await t.groupWith(2);
    const [a, b] = members;
    const s = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: [{ id: a.id, state: 'COMPLETED' }, { id: b.id, state: 'ABSENT' }] });
    const ach = await t.api('GET', '/v1/me/achievements', a.token);
    expect(ach.body).toMatchObject({ current_streak: 1, longest_streak: 1, next_milestone: 3 });
    const att = await t.api('GET', `/v1/me/attendance?month=${s.day.slice(0, 7)}`, a.token);
    expect(att.body.days.find((d: { date: string }) => d.date === s.day)).toEqual({ date: s.day, attended: true });
    expect(att.body.days.length).toBeGreaterThanOrEqual(28);
    const attB = await t.api('GET', `/v1/me/attendance?month=${s.day.slice(0, 7)}`, b.token);
    expect(attB.body.days.some((d: { attended: boolean }) => d.attended)).toBe(false);
    expect((await t.api('GET', '/v1/me/attendance?month=2026-13', a.token)).status).toBe(400);
    const hist = await t.api('GET', '/v1/me/achievements/history', a.token);
    expect(hist.body.items[0]).toMatchObject({ kind: 'STREAK_UP', value: 1 });

    // mốc chuỗi 3 & 7 ngày (BR-52): cấp một lần, có thông báo trong app
    await t.db.updateTable('users').set({ longest_streak: 7 }).where('id', '=', a.id).execute();
    expect(await awardBadges(t.db, a.id, s.day, null)).toEqual(['STREAK_3', 'STREAK_7']);
    expect(await awardBadges(t.db, a.id, s.day, null)).toEqual([]);
    const ach2 = await t.api('GET', '/v1/me/achievements', a.token);
    expect(ach2.body.badges.map((x: { code: string }) => x.code)).toEqual(expect.arrayContaining(['STREAK_3', 'STREAK_7']));
    expect((await t.api('GET', '/v1/me/notifications', a.token)).body.items.filter((n: { type: string }) => n.type === 'BADGE_EARNED')).toHaveLength(2);
    // trưng bày
    expect((await t.api('PUT', '/v1/me/badges/STREAK_7/display', a.token, { visible: true })).status).toBe(204);
    expect((await t.api('GET', '/v1/me/achievements', a.token)).body.badges.find((x: { code: string }) => x.code === 'STREAK_7').visible_on_profile).toBe(true);
    expect((await t.api('PUT', '/v1/me/badges/STREAK_30/display', a.token, { visible: true })).status).toBe(404);
    await t.db.insertInto('user_badges').values([{ user_id: a.id, badge_id: 'STREAK_14', showcase_slot: 2 }, { user_id: a.id, badge_id: 'STREAK_30', showcase_slot: 3 }]).execute();
    expect((await t.api('PUT', '/v1/me/badges/STREAK_3/display', a.token, { visible: true })).status).toBe(422);
    expect((await t.api('PUT', '/v1/me/badges/STREAK_7/display', a.token, { visible: false })).status).toBe(204);
    expect((await t.api('PUT', '/v1/me/badges/STREAK_3/display', a.token, { visible: true })).status).toBe(204);
  });

  it('huy hiệu số phiên có thưởng được cấp lúc chốt phiên và hiện trong kết quả (new_badges)', async () => {
    const { owner, members, groupId } = await t.groupWith(1);
    const [a] = members;
    for (let i = 0; i < 9; i++) await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: [{ id: a.id, state: 'COMPLETED' }] });
    // phiên thứ 10 vượt trần ngày cũng được tính là "hoàn thành có thưởng" (D-11)
    const s10 = await simulateSession(t, { groupId, ownerId: owner.id, startedAt: slot(), members: [{ id: a.id, state: 'COMPLETED' }] });
    expect(s10.results[0].new_badges).toContain('SESS_10');
    const r = await t.api('GET', `/v1/sessions/${s10.sessionId}/result`, a.token);
    expect(r.body.new_badges).toContain('SESS_10');
  });
});
