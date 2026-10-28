import type { Ctx } from '../../context.js';
import type { SessionStatus } from '../../shared/db.js';

export type SessionRow = {
  id: string;
  group_id: string;
  group_name?: string;
  status: SessionStatus;
  started_at: Date;
  created_at: Date;
  ends_at: Date;
  duration_min: number;
  forfeited: boolean;
  cancel_reason: string | null;
};

/** SessionSummary (openapi) — không có trạng thái từng người. */
export function toSummary(ctx: Ctx, s: SessionRow) {
  return {
    session_id: s.id,
    group_id: s.group_id,
    ...(s.group_name !== undefined ? { group_name: s.group_name } : {}),
    status: s.status,
    started_at: s.started_at.toISOString(),
    ends_at: s.ends_at.toISOString(),
    duration_min: s.duration_min,
    // Check-in opens as soon as the schedule exists; users may enter early.
    lobby_opens_at: s.created_at.toISOString(),
    late_join_deadline: ctx.cfg.engine.lateJoinMs > 0
      ? new Date(Math.min(s.ends_at.getTime(), s.started_at.getTime() + ctx.cfg.engine.lateJoinMs)).toISOString()
      : null,
    forfeited: s.forfeited,
    cancel_reason: s.cancel_reason,
    server_ts: new Date().toISOString(),
  };
}

export const sessionCols = [
  'sessions.id', 'sessions.group_id', 'sessions.status', 'sessions.started_at', 'sessions.created_at', 'sessions.ends_at',
  'sessions.duration_min', 'sessions.forfeited', 'sessions.cancel_reason',
] as const;

export async function nextSessionOfGroup(ctx: Ctx, groupId: string) {
  const s = await ctx.db
    .selectFrom('sessions')
    .innerJoin('groups', 'groups.id', 'sessions.group_id')
    .select([...sessionCols, 'groups.name as group_name'])
    .where('sessions.group_id', '=', groupId)
    .where('sessions.status', 'in', ['SCHEDULED', 'COUNTDOWN', 'ACTIVE'])
    .where('sessions.ends_at', '>', new Date())
    .orderBy('sessions.started_at', 'asc')
    .limit(1)
    .executeTakeFirst();
  return s ? toSummary(ctx, s) : null;
}
