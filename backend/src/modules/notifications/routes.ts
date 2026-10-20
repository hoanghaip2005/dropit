import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { sql } from 'kysely';
import type { Ctx } from '../../context.js';
import { currentUser, parse } from '../../shared/http.js';
import { decodeCursor, encodeCursor } from '../../shared/cursor.js';

export function notificationRoutes(app: FastifyInstance, ctx: Ctx) {
  app.get('/v1/me/notifications', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const q = parse(z.object({ cursor: z.string().optional(), limit: z.coerce.number().int().min(1).max(100).default(20) }), req.query);
    let qb = ctx.db.selectFrom('notifications').selectAll().where('user_id', '=', me.id);
    const c = decodeCursor(q.cursor);
    if (c) qb = qb.where((eb) => eb.or([eb('created_at', '<', c.t), eb.and([eb('created_at', '=', c.t), eb('id', '<', c.id)])]));
    const rows = await qb.orderBy('created_at', 'desc').orderBy('id', 'desc').limit(q.limit + 1).execute();
    const page = rows.slice(0, q.limit);
    const unread = await ctx.db.selectFrom('notifications').select((eb) => eb.fn.countAll<string>().as('n'))
      .where('user_id', '=', me.id).where('read_at', 'is', null).executeTakeFirstOrThrow();
    return {
      next_cursor: rows.length > q.limit ? encodeCursor(page[page.length - 1].created_at, page[page.length - 1].id) : null,
      unread_count: Number(unread.n),
      items: page.map((n) => ({
        notification_id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        group_id: (n.data as Record<string, string>).group_id ?? null,
        session_id: (n.data as Record<string, string>).session_id ?? null,
        event_id: n.dedupe_key,
        data: n.data,
        server_ts: n.created_at.toISOString(),
        read: n.read_at !== null,
      })),
    };
  });

  app.post('/v1/me/notifications/read', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const body = parse(z.object({ ids: z.array(z.string().uuid()).optional(), up_to: z.string().datetime({ offset: true }).optional() }), req.body ?? {});
    let qb = ctx.db.updateTable('notifications').set({ read_at: new Date() }).where('user_id', '=', me.id).where('read_at', 'is', null);
    if (body.ids?.length) qb = qb.where('id', 'in', body.ids);
    else if (body.up_to) qb = qb.where(sql`date_trunc('milliseconds', created_at)`, '<=', new Date(body.up_to)); // server_ts trả ra ở độ chính xác ms
    await qb.execute();
    return reply.code(204).send();
  });
}
