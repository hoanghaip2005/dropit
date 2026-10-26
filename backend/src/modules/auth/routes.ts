// Module auth: /time, /dev/token (chỉ NODE_ENV=development), /me.
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { Hs256Verifier } from '../../shared/auth.js';
import { currentUser, parse } from '../../shared/http.js';
import { AppError } from '../../shared/errors.js';
import { equipped } from '../shop/routes.js';
import { avatarUrl } from '../profile/routes.js';

export async function meProfile(ctx: Ctx, userId: string) {
  const u = await ctx.db
    .selectFrom('users')
    .leftJoin('user_coin_balance as b', 'b.user_id', 'users.id')
    .select(['users.id', 'display_name', 'email', 'status', 'current_streak', 'longest_streak', 'avatar_key', 'show_streak', 'b.balance'])
    .where('users.id', '=', userId)
    .executeTakeFirstOrThrow();
  const eq = await equipped(ctx, userId);
  return {
    user_id: u.id,
    display_name: u.display_name,
    email: u.email,
    avatar_url: avatarUrl(ctx, u.avatar_key),
    frame_item_id: eq.AVATAR_FRAME,
    background_item_id: eq.BACKGROUND,
    title_item_id: eq.TITLE,
    coins_balance: u.balance ?? 0,
    current_streak: u.current_streak,
    longest_streak: u.longest_streak,
    show_streak: u.show_streak, // BR-99
    status: u.status,
  };
}

export function authRoutes(app: FastifyInstance, ctx: Ctx) {
  app.get('/v1/time', async () => ({ server_ts: new Date().toISOString() }));

  if (['development', 'test'].includes(ctx.cfg.nodeEnv) && ctx.cfg.devAuth && ctx.verifier instanceof Hs256Verifier) {
    const signer = ctx.verifier;
    // Thay Cognito ở môi trường dev: cấp access token HS256 cho email bất kỳ.
    app.post('/dev/token', async (req) => {
      const body = parse(z.object({ email: z.string().email(), display_name: z.string().min(2).max(30).optional() }), req.body);
      const sub = `dev:${body.email.toLowerCase()}`;
      const token = await signer.sign({ sub, email: body.email.toLowerCase(), name: body.display_name }, 12 * 3600);
      return { access_token: token, token_type: 'Bearer', expires_in: 12 * 3600, sub };
    });
  }

  app.get('/v1/me', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    return meProfile(ctx, me.id);
  });

  app.patch('/v1/me', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const body = parse(z.object({ display_name: z.string().min(1).max(40).optional(), show_streak: z.boolean().optional() }).strict(), req.body);
    if (body.display_name !== undefined) {
      const name = body.display_name.trim();
      // BR-97: 2–30 ký tự, không ký tự điều khiển (schema CHECK) — openapi ghi 1–40 (xem README "Phát hiện khi code")
      if (name.length < 2 || name.length > 30 || /[\u0000-\u001f\u007f]/.test(name))
        throw new AppError(422, 'VALIDATION_FAILED', 'Tên hiển thị 2–30 ký tự, không ký tự điều khiển', 'BR-97');
      await ctx.db.updateTable('users').set({ display_name: name }).where('id', '=', me.id).execute();
    }
    // BR-99: tự bật/tắt hiện chuỗi trên hồ sơ công khai (mặc định ẩn)
    if (body.show_streak !== undefined) await ctx.db.updateTable('users').set({ show_streak: body.show_streak }).where('id', '=', me.id).execute();
    return meProfile(ctx, me.id);
  });
}
