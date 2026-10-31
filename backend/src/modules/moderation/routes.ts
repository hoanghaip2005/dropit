import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { currentUser, idempotent, parse } from '../../shared/http.js';
import { E } from '../../shared/errors.js';
import { roleIn } from '../groups/service.js';

async function requireSharedGroup(ctx: Ctx, viewer: string, target: string, group?: string) {
  if (viewer === target) throw E.validation('Không thể báo cáo hoặc chặn chính mình');
  const user = await ctx.db.selectFrom('users').select('status').where('id', '=', target).executeTakeFirst();
  if (!user || user.status === 'DELETED') throw E.notFound('Không tìm thấy người dùng');
  let groups = ctx.db.selectFrom('groups').select('id').where('status', '<>', 'DISSOLVED');
  if (group) groups = groups.where('id', '=', group);
  const rows = await groups.where((eb) => eb.or([eb('owner_id', '=', viewer), eb.exists(
    eb.selectFrom('group_members').select('id').whereRef('group_members.group_id', '=', 'groups.id')
      .where('group_members.user_id', '=', viewer).where('left_at', 'is', null))])).execute();
  for (const row of rows) if ((await roleIn(ctx, target, row.id)).role) return row.id;
  throw E.forbiddenGroup();
}

export function moderationRoutes(app: FastifyInstance, ctx: Ctx) {
  app.post('/v1/moderation/reports', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const body = parse(z.object({ user_id: z.string().uuid(), group_id: z.string().uuid().optional(),
      reason: z.enum(['HARASSMENT', 'INAPPROPRIATE_CONTENT', 'SPAM', 'OTHER']),
      details: z.string().trim().max(2000).default('') }).strict(), req.body);
    return idempotent(req, reply, ctx.db, me.id, async () => {
      const groupId = await requireSharedGroup(ctx, me.id, body.user_id, body.group_id);
      const row = await ctx.db.insertInto('moderation_reports').values({ reporter_id: me.id, subject_id: body.user_id,
        group_id: groupId, reason: body.reason, details: body.details }).returning(['id', 'status']).executeTakeFirstOrThrow();
      return { status: 201, body: { report_id: row.id, status: row.status } };
    });
  });
  app.get('/v1/me/blocks', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const rows = await ctx.db.selectFrom('user_blocks').innerJoin('users','users.id','user_blocks.blocked_id').select(['blocked_id', 'user_blocks.created_at', 'users.display_name'])
      .where('blocker_id', '=', me.id).orderBy('created_at', 'desc').execute();
    return { items: rows.map((r) => ({ user_id: r.blocked_id, display_name: r.display_name, blocked_at: r.created_at.toISOString() })) };
  });
  app.put('/v1/me/blocks/:user_id', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { user_id } = parse(z.object({ user_id: z.string().uuid() }), req.params);
    const { group_id } = parse(z.object({ group_id: z.string().uuid().optional() }).strict(), req.body);
    await requireSharedGroup(ctx, me.id, user_id, group_id);
    await ctx.db.insertInto('user_blocks').values({ blocker_id: me.id, blocked_id: user_id })
      .onConflict((oc) => oc.columns(['blocker_id', 'blocked_id']).doNothing()).execute();
    return { blocked: true };
  });
  app.delete('/v1/me/blocks/:user_id', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { user_id } = parse(z.object({ user_id: z.string().uuid() }), req.params);
    return idempotent(req, reply, ctx.db, me.id, async () => {
      await ctx.db.deleteFrom('user_blocks').where('blocker_id', '=', me.id).where('blocked_id', '=', user_id).execute();
      return { status: 204 };
    });
  });
}



