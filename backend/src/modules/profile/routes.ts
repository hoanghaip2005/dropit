// Hồ sơ (EP-07): avatar lưu tệp local thư mục uploads/ thay S3 (BR-98, dev). Ảnh xem trước Shop sinh SVG giữ chỗ.
import { mkdir, readFile, unlink, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { currentUser, parse } from '../../shared/http.js';
import { AppError, E } from '../../shared/errors.js';
import { meProfile } from '../auth/routes.js';

const MAX = 5 * 1024 * 1024; // avatar_max_mb (BR-98): đúng 5 MB nhận, hơn 1 byte từ chối
const EXT: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
const MIME: Record<string, string> = { jpg: 'image/jpeg', png: 'image/png', webp: 'image/webp' };

export const avatarUrl = (ctx: Ctx, key: string | null) => (key ? `${ctx.cfg.publicBaseUrl}/uploads/${key}` : null);

/** Nhận diện định dạng theo byte đầu tệp (không tin Content-Type). */
export function sniffImage(b: Buffer): string | null {
  if (b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return 'image/jpeg';
  if (b.length >= 8 && b.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return 'image/png';
  if (b.length >= 12 && b.subarray(0, 4).toString('latin1') === 'RIFF' && b.subarray(8, 12).toString('latin1') === 'WEBP') return 'image/webp';
  return null;
}

export function profileRoutes(app: FastifyInstance, ctx: Ctx) {
  app.addContentTypeParser(/^image\//, { parseAs: 'buffer', bodyLimit: MAX + 1024 * 1024 }, (_req, body, done) => done(null, body));

  // openapi: xin URL tải lên. Bản local trả URL của chính server (PUT kèm Bearer) thay URL S3 ký sẵn.
  app.put('/v1/me/avatar', async (req) => {
    await currentUser(req, ctx.db, ctx.verifier);
    const body = parse(z.object({ content_type: z.string(), size_bytes: z.number().int().min(1) }), req.body);
    if (!EXT[body.content_type]) throw new AppError(422, 'VALIDATION_FAILED', 'Chỉ nhận JPG/PNG/WebP', 'BR-98');
    if (body.size_bytes > MAX) throw new AppError(422, 'VALIDATION_FAILED', 'Ảnh tối đa 5 MB', 'BR-98');
    return { upload_url: `${ctx.cfg.publicBaseUrl}/v1/me/avatar/content`, expires_at: new Date(Date.now() + 15 * 60000).toISOString() };
  });

  // Ngoài openapi (thay S3): nhận thân ảnh thô, lưu uploads/avatars/<user>-<ts>.<ext>, xóa tệp cũ.
  app.put('/v1/me/avatar/content', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const buf = req.body;
    if (!Buffer.isBuffer(buf) || !buf.length) throw E.validation('Gửi thân ảnh với Content-Type image/jpeg|png|webp');
    if (buf.length > MAX) throw new AppError(422, 'VALIDATION_FAILED', 'Ảnh tối đa 5 MB', 'BR-98');
    const type = sniffImage(buf);
    if (!type) throw new AppError(422, 'VALIDATION_FAILED', 'Tệp không phải ảnh JPG/PNG/WebP', 'BR-98');
    const dir = join(ctx.cfg.uploadsDir, 'avatars');
    await mkdir(dir, { recursive: true });
    const key = `avatars/${me.id}-${Date.now()}.${EXT[type]}`;
    await writeFile(join(ctx.cfg.uploadsDir, key), buf);
    const old = await ctx.db.selectFrom('users').select('avatar_key').where('id', '=', me.id).executeTakeFirstOrThrow();
    await ctx.db.updateTable('users').set({ avatar_key: key }).where('id', '=', me.id).execute();
    if (old.avatar_key) await unlink(join(ctx.cfg.uploadsDir, old.avatar_key)).catch(() => {});
    return meProfile(ctx, me.id);
  });

  app.delete('/v1/me/avatar', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const old = await ctx.db.selectFrom('users').select('avatar_key').where('id', '=', me.id).executeTakeFirstOrThrow();
    await ctx.db.updateTable('users').set({ avatar_key: null }).where('id', '=', me.id).execute();
    if (old.avatar_key) await unlink(join(ctx.cfg.uploadsDir, old.avatar_key)).catch(() => {});
    return reply.code(204).send();
  });

  app.get('/uploads/avatars/:file', async (req, reply) => {
    const { file } = parse(z.object({ file: z.string().regex(/^[0-9a-f-]{36}-\d+\.(jpg|png|webp)$/) }), req.params);
    try {
      const data = await readFile(join(ctx.cfg.uploadsDir, 'avatars', file));
      return reply.type(MIME[file.split('.').pop()!]).header('cache-control', 'private, max-age=86400').send(data);
    } catch {
      throw E.notFound('Không có ảnh');
    }
  });

  // Ảnh xem trước món Shop: SVG giữ chỗ sinh từ preview_key (thay S3/CloudFront)
  app.get('/assets/shop/:key', async (req, reply) => {
    const { key } = parse(z.object({ key: z.string().regex(/^[a-z0-9_-]{1,60}$/) }), req.params);
    let h = 0;
    for (const c of key) h = (h * 31 + c.charCodeAt(0)) % 360;
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><rect width="256" height="256" rx="32" fill="hsl(${h},60%,55%)"/><text x="128" y="136" font-family="sans-serif" font-size="20" text-anchor="middle" fill="#fff">${key}</text></svg>`;
    return reply.type('image/svg+xml').send(svg);
  });
}
