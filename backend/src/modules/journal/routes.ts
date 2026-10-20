// Nhật ký cá nhân (US-07.07…07.10, BR-100): 1 mục/ngày, ≤ 5000 ký tự, mã hóa phía server, chỉ chủ sở hữu đọc.
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { currentUser, idempotent, parse } from '../../shared/http.js';
import { AppError, E } from '../../shared/errors.js';
import { decodeCursor, encodeCursor } from '../../shared/cursor.js';
import { vnDay } from '../../shared/time.js';
import { decryptJournal, encryptJournal, masterKey } from './crypto.js';

const DateParam = z.object({ date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'date dạng YYYY-MM-DD') });
const MAX_CHARS = 5000;

export function journalRoutes(app: FastifyInstance, ctx: Ctx) {
  const key = masterKey(ctx.cfg.journalKey);
  const forbidden = () => new AppError(403, 'FORBIDDEN_GROUP', 'Nhật ký chỉ chủ sở hữu xem được — chủ nhóm và quản trị không xem được trong app', 'BR-100');

  app.put('/v1/me/journal/:date', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { date } = parse(DateParam, req.params);
    const body = parse(z.object({ text: z.string() }).strict(), req.body);
    const text = body.text;
    const n = [...text].length; // đếm theo ký tự Unicode như char_length của Postgres
    if (!text.trim().length) throw E.validation('Nhật ký không được trống');
    if (n > MAX_CHARS) throw new AppError(422, 'JOURNAL_TOO_LONG', `Nhật ký tối đa ${MAX_CHARS} ký tự (hiện ${n})`, 'BR-100');
    const today = vnDay(new Date());
    const exists = await ctx.db.selectFrom('journals').select('id').where('user_id', '=', me.id).where('day', '=', date).executeTakeFirst();
    // Ngày của mục = ngày server nhận (giờ VN); mục cũ đã có thì sửa được không giới hạn thời gian
    if (!exists && date !== today)
      throw new AppError(422, 'JOURNAL_DATE_INVALID', `Chỉ viết mục mới cho hôm nay (${today}, giờ server)`, 'BR-100');
    const enc = encryptJournal(key, me.id, date, text);
    const row = await ctx.db.insertInto('journals').values({ user_id: me.id, day: date, char_count: n, ...enc })
      .onConflict((oc) => oc.columns(['user_id', 'day']).doUpdateSet({ ...enc, char_count: n }))
      .returning(['day', 'updated_at']).executeTakeFirstOrThrow();
    return { date: row.day, text, updated_at: row.updated_at.toISOString() };
  });

  app.get('/v1/me/journal', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const q = parse(z.object({ cursor: z.string().optional(), limit: z.coerce.number().int().min(1).max(100).default(20) }), req.query);
    let qb = ctx.db.selectFrom('journals').selectAll().where('user_id', '=', me.id);
    const c = decodeCursor(q.cursor);
    if (c) qb = qb.where('day', '<', c.id);
    const rows = await qb.orderBy('day', 'desc').limit(q.limit + 1).execute();
    const page = rows.slice(0, q.limit);
    return {
      next_cursor: rows.length > q.limit ? encodeCursor(page[page.length - 1].updated_at, page[page.length - 1].day) : null,
      items: page.map((r) => ({ date: r.day, text: decryptJournal(key, me.id, r.day, r), updated_at: r.updated_at.toISOString() })),
    };
  });

  app.get('/v1/me/journal/:date', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { date } = parse(DateParam, req.params);
    const r = await ctx.db.selectFrom('journals').selectAll().where('user_id', '=', me.id).where('day', '=', date).executeTakeFirst();
    if (!r) throw E.notFound('Không có nhật ký ngày này');
    return { date: r.day, text: decryptJournal(key, me.id, r.day, r), updated_at: r.updated_at.toISOString() };
  });

  app.delete('/v1/me/journal/:date', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { date } = parse(DateParam, req.params);
    return idempotent(req, reply, ctx.db, me.id, async () => {
      const r = await ctx.db.deleteFrom('journals').where('user_id', '=', me.id).where('day', '=', date).executeTakeFirst();
      if (!Number(r.numDeletedRows)) throw E.notFound('Không có nhật ký ngày này');
      return { status: 204 };
    });
  });

  // US-07.10: không có đường đọc nhật ký người khác — mọi yêu cầu như vậy trả 403 (kể cả chủ nhóm)
  app.get('/v1/users/:user_id/journal', async (req) => {
    await currentUser(req, ctx.db, ctx.verifier);
    throw forbidden();
  });
  app.get('/v1/users/:user_id/journal/:date', async (req) => {
    await currentUser(req, ctx.db, ctx.verifier);
    throw forbidden();
  });
  app.get('/v1/groups/:group_id/members/:user_id/journal', async (req) => {
    await currentUser(req, ctx.db, ctx.verifier);
    throw forbidden();
  });
}
