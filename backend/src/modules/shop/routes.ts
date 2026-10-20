// Shop (EP-06): giá cố định, không cơ chế ngẫu nhiên (BR-121); mua là giao dịch nguyên tử (BR-94).
import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import type { ItemKind } from '../../shared/db.js';
import { pgCode } from '../../shared/db.js';
import { currentUser, idempotent, parse } from '../../shared/http.js';
import { AppError } from '../../shared/errors.js';
import { meProfile } from '../auth/routes.js';

const Kind = z.enum(['AVATAR_FRAME', 'BACKGROUND', 'TITLE']);
const previewUrl = (ctx: Ctx, key: string) => `${ctx.cfg.publicBaseUrl}/assets/shop/${encodeURIComponent(key)}`;

export async function purchase(ctx: Ctx, userId: string, itemId: string, expectedPrice: number) {
  try {
    return await ctx.db.transaction().execute(async (tx) => {
      await tx.selectFrom('users').select('id').where('id', '=', userId).forUpdate().execute(); // tuần tự theo người
      const it = await tx.selectFrom('shop_items').selectAll().where('id', '=', itemId).executeTakeFirst();
      if (!it || it.status !== 'ON_SALE' || it.is_default || it.price === null)
        throw new AppError(422, 'ITEM_UNAVAILABLE', 'Món không còn bán', 'BR-96');
      const owned = await tx.selectFrom('user_items').select('id').where('user_id', '=', userId).where('item_id', '=', itemId).executeTakeFirst();
      if (owned) throw new AppError(409, 'ALREADY_OWNED', 'Bạn đã sở hữu món này', 'BR-94');
      if (it.price !== expectedPrice) throw new AppError(409, 'PRICE_CHANGED', `Giá đã thay đổi: ${it.price} Coins. Xác nhận lại.`, 'BR-94');
      const bal = await tx.selectFrom('user_coin_balance').select('balance').where('user_id', '=', userId).executeTakeFirst();
      if ((bal?.balance ?? 0) < it.price) throw new AppError(422, 'INSUFFICIENT_COINS', `Không đủ Coins (cần ${it.price}, có ${bal?.balance ?? 0})`, 'BR-45');
      const userItemId = randomUUID();
      const led = await tx.insertInto('coin_ledger').values({
        user_id: userId, amount: -it.price, type: 'SHOP_PURCHASE', ref_id: userItemId, reward_date: null,
        reason: `SHOP_PURCHASE:${it.id}`, idempotency_key: `SHOP_PURCHASE:${userId}:${it.id}`, balance_after: 0, created_by: null,
      }).returning(['entry_id', 'balance_after']).executeTakeFirstOrThrow();
      await tx.insertInto('user_items').values({ id: userItemId, user_id: userId, item_id: it.id, price_paid: it.price, ledger_entry_id: led.entry_id }).execute();
      return { item_id: it.id, balance: led.balance_after };
    });
  } catch (e) {
    if (e instanceof AppError) throw e;
    if (pgCode(e) === '23505') throw new AppError(409, 'ALREADY_OWNED', 'Bạn đã sở hữu món này', 'BR-94');
    if (pgCode(e) === '23514') throw new AppError(422, 'INSUFFICIENT_COINS', 'Không đủ Coins', 'BR-45'); // trigger số dư âm
    throw e;
  }
}

/** Món đang trang bị theo loại; không có dòng → món mặc định (BR-95). */
export async function equipped(ctx: Ctx, userId: string): Promise<Record<ItemKind, string | null>> {
  const rows = await ctx.db.selectFrom('user_equipped').select(['kind', 'item_id']).where('user_id', '=', userId).execute();
  const defs = await ctx.db.selectFrom('shop_items').select(['kind', 'id']).where('is_default', '=', true).execute();
  const out = { AVATAR_FRAME: null, BACKGROUND: null, TITLE: null } as Record<ItemKind, string | null>;
  for (const d of defs) out[d.kind] = d.id;
  for (const r of rows) out[r.kind] = r.item_id;
  return out;
}

export function shopRoutes(app: FastifyInstance, ctx: Ctx) {
  app.get('/v1/shop/items', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const q = parse(z.object({ kind: Kind.optional() }), req.query);
    let qb = ctx.db.selectFrom('shop_items').selectAll().where('status', '=', 'ON_SALE').where('is_default', '=', false);
    if (q.kind) qb = qb.where('kind', '=', q.kind);
    const rows = await qb.orderBy('kind').orderBy('price').orderBy('name').execute();
    const owned = new Set((await ctx.db.selectFrom('user_items').select('item_id').where('user_id', '=', me.id).execute()).map((r) => r.item_id));
    return {
      items: rows.map((r) => ({
        item_id: r.id, kind: r.kind, name: r.name, price: r.price, preview_url: previewUrl(ctx, r.preview_key), status: r.status, owned: owned.has(r.id),
      })),
    };
  });

  app.post('/v1/shop/purchases', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const body = parse(z.object({ item_id: z.string().uuid(), expected_price: z.number().int().min(0) }), req.body);
    return idempotent(req, reply, ctx.db, me.id, async () => ({ status: 201, body: await purchase(ctx, me.id, body.item_id, body.expected_price) }));
  });

  app.get('/v1/me/inventory', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const eq = await equipped(ctx, me.id);
    const u = await ctx.db.selectFrom('users').select('created_at').where('id', '=', me.id).executeTakeFirstOrThrow();
    const bought = await ctx.db.selectFrom('user_items').innerJoin('shop_items', 'shop_items.id', 'user_items.item_id')
      .select(['shop_items.id', 'shop_items.kind', 'shop_items.name', 'user_items.acquired_at'])
      .where('user_items.user_id', '=', me.id).orderBy('user_items.acquired_at', 'desc').execute();
    const defs = await ctx.db.selectFrom('shop_items').select(['id', 'kind', 'name']).where('is_default', '=', true).execute();
    return {
      items: [
        ...bought.map((b) => ({ item_id: b.id, kind: b.kind, name: b.name, equipped: eq[b.kind] === b.id, acquired_at: b.acquired_at.toISOString(), is_default: false })),
        ...defs.map((d) => ({ item_id: d.id, kind: d.kind, name: d.name, equipped: eq[d.kind] === d.id, acquired_at: u.created_at.toISOString(), is_default: true })),
      ],
    };
  });

  app.put('/v1/me/equipment', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const Id = z.string().uuid().nullable().optional();
    const body = parse(z.object({ frame_item_id: Id, background_item_id: Id, title_item_id: Id }).strict(), req.body);
    const wanted: [ItemKind, string | null | undefined][] = [
      ['AVATAR_FRAME', body.frame_item_id], ['BACKGROUND', body.background_item_id], ['TITLE', body.title_item_id],
    ];
    await ctx.db.transaction().execute(async (tx) => {
      for (const [kind, id] of wanted) {
        if (id === undefined) continue;
        if (id === null) { // gỡ → về món mặc định (BR-95)
          await tx.deleteFrom('user_equipped').where('user_id', '=', me.id).where('kind', '=', kind).execute();
          continue;
        }
        const it = await tx.selectFrom('shop_items').select(['kind', 'is_default']).where('id', '=', id).executeTakeFirst();
        const mine = it && (it.is_default || (await tx.selectFrom('user_items').select('id').where('user_id', '=', me.id).where('item_id', '=', id).executeTakeFirst()));
        if (!it || it.kind !== kind || !mine) throw new AppError(422, 'ITEM_NOT_OWNED', 'Chỉ trang bị món đã sở hữu hoặc mặc định, đúng loại', 'BR-95');
        await tx.insertInto('user_equipped').values({ user_id: me.id, kind, item_id: id })
          .onConflict((oc) => oc.columns(['user_id', 'kind']).doUpdateSet({ item_id: id, equipped_at: new Date() })).execute();
      }
    });
    return meProfile(ctx, me.id);
  });
}
