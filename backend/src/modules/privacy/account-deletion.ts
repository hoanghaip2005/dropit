import { readdir, unlink } from 'node:fs/promises';
import { resolve, sep } from 'node:path';
import type { FastifyInstance } from 'fastify';
import { sql } from 'kysely';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { parse } from '../../shared/http.js';
import { AppError, E } from '../../shared/errors.js';
import { deletedSubject } from '../../shared/auth.js';



/** Cognito self-service deletion uses only the authenticated caller's access token. */
export async function deleteCognitoUser(region: string, token: string, request: typeof fetch = fetch) {
  const response = await request(`https://cognito-idp.${region}.amazonaws.com/`, {
    method: 'POST', headers: { 'Content-Type': 'application/x-amz-json-1.1', 'X-Amz-Target': 'AWSCognitoIdentityProviderService.DeleteUser' },
    body: JSON.stringify({ AccessToken: token }), signal: AbortSignal.timeout(15000),
  });
  if (response.ok) return;
  // Do not turn scope/configuration/network failures into a false successful deletion.
  throw new AppError(503, 'IDENTITY_DELETION_UNAVAILABLE', 'Đã xóa dữ liệu ứng dụng. Chưa xóa được đăng nhập; vui lòng thử lại hoặc liên hệ hỗ trợ.');
}

export function accountDeletionRoutes(app: FastifyInstance, ctx: Ctx) {
  app.delete('/v1/me/account', async (req, reply) => {
    parse(z.object({ confirmation: z.literal('DELETE') }).strict(), req.body);
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) throw E.unauth();
    const token = header.slice(7);
    const identity = await ctx.verifier.verify(token);
    const tombstone = deletedSubject(identity.sub);
    const user = await ctx.db.selectFrom('users').select(['id', 'avatar_key', 'status'])
      .where('cognito_sub', 'in', [identity.sub, tombstone]).executeTakeFirst();
    if (!user) throw E.unauth();
    const owned = await ctx.db.selectFrom('groups').select('id').where('owner_id', '=', user.id).execute();
    const memberships = await ctx.db.selectFrom('group_members').select('group_id').where('user_id', '=', user.id).where('left_at', 'is', null).execute();
    for (const m of memberships) ctx.sessions.withdrawFromGroup(m.group_id, user.id);
    const ownerIds = owned.map(g => g.id);
    if (ownerIds.length) {
      const running = await ctx.db.selectFrom('sessions').select('id').where('group_id', 'in', ownerIds).where('status', 'in', ['SCHEDULED', 'COUNTDOWN', 'ACTIVE']).execute();
      for (const s of running) ctx.sessions.cancelLoaded(s.id);
    }
    if (user.avatar_key) {
      const root = resolve(ctx.cfg.uploadsDir);
      const file = resolve(root, user.avatar_key);
      if (file.startsWith(root + sep)) await unlink(file).catch(e => { if (e.code !== 'ENOENT') throw e; });
    }
    // Local report email previews contain the owner's name/email; remove every owned group's copy.
    const outbox = await readdir(ctx.cfg.outboxDir).catch((e: NodeJS.ErrnoException) => {
      if (e.code === 'ENOENT') return [] as string[];
      throw e;
    });
    for (const file of outbox) {
      if (/^report-[0-9]{4}-[0-9]{2}-/.test(file) && ownerIds.some(id => file.endsWith('-' + id + '.eml'))) {
        await unlink(resolve(ctx.cfg.outboxDir, file)).catch((e: NodeJS.ErrnoException) => { if (e.code !== 'ENOENT') throw e; });
      }
    }
    await ctx.db.transaction().execute(async tx => {
      await sql`select pg_advisory_xact_lock(hashtext(${identity.sub}))`.execute(tx);
      await tx.selectFrom('users').select('id').where('id', '=', user.id).forUpdate().executeTakeFirstOrThrow();
      await sql`select set_config('dropit.purge', 'on', true)`.execute(tx);
      const now = new Date();
      if (ownerIds.length) {
        const ownedSessions = tx.selectFrom('sessions').select('id').where('group_id', 'in', ownerIds).where('status', 'in', ['SCHEDULED', 'COUNTDOWN', 'ACTIVE']);
        await tx.updateTable('session_members').set({state: 'VOID', end_reason: 'SESSION_CANCELLED', ended_at: now}).where('session_id', 'in', ownedSessions).where('is_final', '=', false as never).execute();
        await tx.updateTable('sessions').set({ status: 'CANCELLED', cancel_reason: 'GROUP_DISSOLVED', cancelled_at: now, forfeited: false, forfeited_at: null, forfeit_trigger_user_id: null }).where('group_id', 'in', ownerIds).where('status', 'in', ['SCHEDULED', 'COUNTDOWN', 'ACTIVE']).execute();
        await tx.deleteFrom('consents').where('group_id', 'in', ownerIds).execute();
        await tx.deleteFrom('notifications').where(sql<boolean>`data->>'group_id' = any(${ownerIds}::text[])`).execute();
        await tx.updateTable('schedules').set({ cancelled_at: now }).where('group_id', 'in', ownerIds).execute();
        await tx.updateTable('group_members').set({ left_at: now, leave_reason: 'GROUP_DISSOLVED', removal_effective_at: null }).where('group_id', 'in', ownerIds).where('left_at', 'is', null).execute();
        await tx.updateTable('groups').set({ status: 'DISSOLVED', dissolved_at: now, name: 'Nhóm đã xóa', report_purpose: 'Đã xóa' }).where('id', 'in', ownerIds).execute();
      }
      await tx.updateTable('group_members').set({ left_at: now, leave_reason: 'ACCOUNT_DELETED', removal_effective_at: null }).where('user_id', '=', user.id).where('left_at', 'is', null).execute();
      await tx.updateTable('monthly_report_rows').set({ user_id: null, display_name_snapshot: null }).where('user_id', '=', user.id).execute();
      const explanations = tx.selectFrom('explanations').select('id').where('user_id', '=', user.id);
      await tx.deleteFrom('explanation_revisions').where('explanation_id', 'in', explanations).execute();
      await tx.deleteFrom('explanations').where('user_id', '=', user.id).execute();
      await sql`delete from session_pauses where user_id = ${user.id}`.execute(tx);
      await tx.deleteFrom('appeals').where('user_id', '=', user.id).execute();
      await sql`delete from moderation_reports where reporter_id = ${user.id} or subject_id = ${user.id}`.execute(tx);
      await sql`delete from user_blocks where blocker_id = ${user.id} or blocked_id = ${user.id}`.execute(tx);
      await sql`delete from abuse_reports where reporter_id = ${user.id} or target_user_id = ${user.id}`.execute(tx);
      await tx.deleteFrom('journals').where('user_id', '=', user.id).execute();
      await tx.deleteFrom('notifications').where('user_id', '=', user.id).execute();
      await tx.deleteFrom('device_tokens').where('user_id', '=', user.id).execute();
      await tx.deleteFrom('idempotency_keys').where('user_id', '=', user.id).execute();
      await tx.deleteFrom('consents').where('user_id', '=', user.id).execute();
      await tx.deleteFrom('invite_attempts').where('user_id', '=', user.id).execute();
      await tx.deleteFrom('daily_attendance').where('user_id', '=', user.id).execute();
      await tx.deleteFrom('user_equipped').where('user_id', '=', user.id).execute();
      await tx.deleteFrom('user_items').where('user_id', '=', user.id).execute();
      await tx.deleteFrom('user_badges').where('user_id', '=', user.id).execute();
      await tx.deleteFrom('achievement_log').where('user_id', '=', user.id).execute();
      await tx.deleteFrom('coin_ledger').where('user_id', '=', user.id).execute();
      await tx.deleteFrom('access_logs').where(eb => eb.or([eb('subject_user_id', '=', user.id), eb('viewer_id', '=', user.id)])).execute();
      await tx.updateTable('session_members').set({ state: 'WITHDRAWN', end_reason: 'CONSENT_WITHDRAWN', ended_at: now }).where('user_id', '=', user.id).where('is_final', '=', false as never).execute();
      await sql`update users set status = 'DELETED', cognito_sub = ${tombstone}, email = null, display_name = 'Người dùng đã xóa', avatar_key = null, current_streak = 0, longest_streak = 0, streak_last_inc_day = null, show_streak = false, locked_at = null, lock_reason = null, deleted_at = now() where id = ${user.id}`.execute(tx);
    });
    ctx.sessions.disconnectUser(user.id);
    if (ctx.cfg.cognitoRegion && !ctx.cfg.devAuth) {
      try { await deleteCognitoUser(ctx.cfg.cognitoRegion, token); } catch {
        throw new AppError(503, 'IDENTITY_DELETION_UNAVAILABLE', 'Đã xóa dữ liệu ứng dụng. Chưa xóa được đăng nhập; vui lòng thử lại hoặc liên hệ hỗ trợ.');
      }
    } else if (ctx.cfg.nodeEnv !== 'development' && ctx.cfg.nodeEnv !== 'test') {
      throw new AppError(503, 'IDENTITY_DELETION_UNAVAILABLE', 'Chưa cấu hình dịch vụ xóa đăng nhập.');
    }
    return reply.code(204).send();
  });
}









