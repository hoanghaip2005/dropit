import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { currentUser, parse } from '../../shared/http.js';
import { decodeCursor, encodeCursor } from '../../shared/cursor.js';

export function rewardRoutes(app: FastifyInstance, ctx: Ctx) {
  // Coins của chính tôi (US-06.02) — chỉ qua /me, không đọc chéo được (P3, BR-53)
  app.get('/v1/me/coins', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const q = parse(z.object({ cursor: z.string().optional(), limit: z.coerce.number().int().min(1).max(100).default(20) }), req.query);
    const bal = await ctx.db.selectFrom('user_coin_balance').select('balance').where('user_id', '=', me.id).executeTakeFirst();
    let qb = ctx.db.selectFrom('coin_ledger').selectAll().where('user_id', '=', me.id);
    const c = decodeCursor(q.cursor);
    if (c) qb = qb.where((eb) => eb.or([eb('created_at', '<', c.t), eb.and([eb('created_at', '=', c.t), eb('entry_id', '<', c.id)])]));
    const rows = await qb.orderBy('created_at', 'desc').orderBy('entry_id', 'desc').limit(q.limit + 1).execute();
    const page = rows.slice(0, q.limit);
    return {
      balance: bal?.balance ?? 0,
      next_cursor: rows.length > q.limit ? encodeCursor(page[page.length - 1].created_at, page[page.length - 1].entry_id) : null,
      items: page.map((e) => ({
        entry_id: e.entry_id, amount: e.amount, type: e.type, reason: e.reason, balance_after: e.balance_after,
        ref_id: e.ref_id, reward_date: e.reward_date, created_at: e.created_at.toISOString(),
      })),
    };
  });
}
