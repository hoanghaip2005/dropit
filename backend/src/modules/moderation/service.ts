import type { Ctx } from '../../context.js';
export async function isBlocked(ctx: Ctx, viewer: string, target: string) {
  if (viewer === target) return false;
  const row = await ctx.db.selectFrom('user_blocks').select('blocker_id')
    .where((eb) => eb.or([
      eb.and([eb('blocker_id', '=', viewer), eb('blocked_id', '=', target)]),
      eb.and([eb('blocker_id', '=', target), eb('blocked_id', '=', viewer)]),
    ])).executeTakeFirst();
  return Boolean(row);
}


export async function blockedIds(ctx: Ctx, viewer: string): Promise<Set<string>> {
  const rows = await ctx.db.selectFrom('user_blocks').select(['blocker_id','blocked_id'])
    .where((eb) => eb.or([eb('blocker_id','=',viewer),eb('blocked_id','=',viewer)])).execute();
  return new Set(rows.map((r) => r.blocker_id === viewer ? r.blocked_id : r.blocker_id));
}
