// Tiện ích HTTP dùng chung: xác thực người gọi, parse zod, idempotency (P6), lỗi problem+json (P10).
import { createHash } from 'node:crypto';
import { sql } from 'kysely';
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { z, ZodError, type ZodTypeAny } from 'zod';
import type { DB } from './db.js';
import { deletedSubject, type TokenVerifier, type Identity } from './auth.js';
import { AppError, E } from './errors.js';

export type CurrentUser = { id: string; display_name: string; status: string; identity: Identity };

/** Lấy người gọi từ Bearer token; tạo bản ghi users ở lần gọi đầu (GET /me, 03 P2). */
export async function currentUser(req: FastifyRequest, db: DB, verifier: TokenVerifier): Promise<CurrentUser> {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) throw E.unauth();
  const identity = await verifier.verify(h.slice(7));
  return ensureUser(db, identity);
}

export async function ensureUser(db: DB, identity: Identity): Promise<CurrentUser> {
  return db.transaction().execute(async tx => {
    await sql`select pg_advisory_xact_lock(hashtext(${identity.sub}))`.execute(tx);
    return ensureUserLocked(tx, identity);
  });
}

async function ensureUserLocked(db: DB, identity: Identity): Promise<CurrentUser> {
  let u = await db.selectFrom('users').select(['id', 'display_name', 'status']).where('cognito_sub', 'in', [identity.sub, deletedSubject(identity.sub)]).executeTakeFirst();
  if (!u) {
    const base = (identity.name || identity.email?.split('@')[0] || 'Người dùng').trim();
    const name = (base.length < 2 ? `${base}__` : base).slice(0, 30);
    u = await db
      .insertInto('users')
      .values({ cognito_sub: identity.sub, email: identity.email ?? null, display_name: name, avatar_key: null, streak_last_inc_day: null })
      .onConflict((oc) => oc.column('cognito_sub').doUpdateSet({ cognito_sub: identity.sub }))
      .returning(['id', 'display_name', 'status'])
      .executeTakeFirstOrThrow();
  }
  if (u.status === 'LOCKED') throw new AppError(403, 'ACCOUNT_LOCKED', 'Tài khoản đang bị khóa', 'BR-108');
  if (u.status === 'DELETED') throw E.unauth('Tài khoản đã xóa');
  return { ...u, identity };
}

export function parse<T extends ZodTypeAny>(schema: T, data: unknown): z.infer<T> {
  return schema.parse(data);
}

/** P6: POST/DELETE có tác dụng phụ bắt buộc Idempotency-Key; trùng khóa + cùng thân → trả lại phản hồi cũ. */
export async function idempotent(
  req: FastifyRequest,
  reply: FastifyReply,
  db: DB,
  userId: string,
  run: () => Promise<{ status: number; body?: unknown }>,
) {
  const key = req.headers['idempotency-key'];
  const uuid = z.string().uuid().safeParse(key);
  if (!uuid.success) throw E.validation('Thiếu hoặc sai header Idempotency-Key (UUID)');
  const hash = createHash('sha256').update(JSON.stringify(req.body ?? null)).digest('hex');
  const path = req.url.split('?')[0];
  const prev = await db
    .selectFrom('idempotency_keys')
    .selectAll()
    .where('user_id', '=', userId)
    .where('key', '=', uuid.data)
    .where('expires_at', '>', new Date())
    .executeTakeFirst();
  if (prev) {
    if (prev.request_hash !== hash || prev.path !== path || prev.method !== req.method)
      throw new AppError(422, 'IDEMPOTENCY_MISMATCH', 'Idempotency-Key đã dùng cho yêu cầu khác');
    reply.header('Idempotent-Replayed', 'true');
    return reply.code(prev.status_code ?? 200).send(prev.response_body ?? undefined);
  }
  const res = await run();
  await db
    .insertInto('idempotency_keys')
    .values({
      user_id: userId, key: uuid.data, method: req.method, path, request_hash: hash,
      status_code: res.status, response_body: res.body === undefined ? null : JSON.stringify(res.body),
    })
    .onConflict((oc) => oc.columns(['user_id', 'key']).doNothing())
    .execute();
  return reply.code(res.status).send(res.body);
}

export function installErrorHandler(app: FastifyInstance) {
  app.setErrorHandler((err, req, reply) => {
    let e: AppError;
    if (err instanceof AppError) e = err;
    else if (err instanceof ZodError) e = E.validation(err.issues.map((i) => `${i.path.join('.') || '(thân)'}: ${i.message}`).join('; '));
    else if ((err as { validation?: unknown }).validation || (err as { statusCode?: number }).statusCode === 400) e = E.validation(err.message);
    else {
      req.log.error(err);
      e = new AppError(500, 'INTERNAL', 'Lỗi máy chủ');
    }
    if (e.code === 'INVITE_CODE_LOCKED' || e.code === 'RATE_LIMITED') reply.header('Retry-After', String((e as AppError & { retryAfter?: number }).retryAfter ?? 60));
    reply.code(e.status).type('application/problem+json').send(e.toProblem(String(req.id)));
  });
}
