// Thành tích (EP-05) — chỉ của chính tôi; chuỗi không bao giờ trả cho người khác (BR-53, D-12).
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { currentUser, parse } from '../../shared/http.js';
import { AppError, E } from '../../shared/errors.js';
import { decodeCursor, encodeCursor } from '../../shared/cursor.js';
import { vnDay } from '../../shared/time.js';
import { badgeMetrics } from './service.js';

export const MonthStr = z.string().regex(/^\d{4}-(0[1-9]|1[0-2])$/, 'month dạng YYYY-MM');

export function daysOfMonth(month: string): string[] {
  const [y, m] = month.split('-').map(Number);
  const n = new Date(Date.UTC(y, m, 0)).getUTCDate();
  return Array.from({ length: n }, (_, i) => `${month}-${String(i + 1).padStart(2, '0')}`);
}

export function achievementRoutes(app: FastifyInstance, ctx: Ctx) {
  app.get('/v1/me/achievements', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const u = await ctx.db.selectFrom('users').select(['current_streak', 'longest_streak', 'streak_last_inc_day', 'show_streak']).where('id', '=', me.id).executeTakeFirstOrThrow();
    const next = await ctx.db.selectFrom('badges').select('threshold').where('metric', '=', 'STREAK_DAYS').where('retired_at', 'is', null)
      .where('threshold', '>', u.current_streak).orderBy('threshold').limit(1).executeTakeFirst();
    const badges = await ctx.db.selectFrom('user_badges').select(['badge_id', 'awarded_at', 'showcase_slot'])
      .where('user_id', '=', me.id).orderBy('awarded_at').orderBy('badge_id').execute();
    // Tiến độ huy hiệu theo số phiên / số giờ (US-05.05): số đo hiện tại + mốc kế tiếp từng loại
    const metrics = await badgeMetrics(ctx.db, me.id);
    const allBadges = await ctx.db.selectFrom('badges').select(['id', 'name', 'metric', 'threshold']).where('retired_at', 'is', null).orderBy('threshold').execute();
    const ownedIds = new Set(badges.map((b) => b.badge_id));
    const progress = (['REWARDED_SESSIONS', 'FOCUS_HOURS', 'STREAK_DAYS'] as const).map((metric) => {
      const nextB = allBadges.find((b) => b.metric === metric && !ownedIds.has(b.id) && b.threshold > metrics[metric])
        ?? allBadges.find((b) => b.metric === metric && !ownedIds.has(b.id));
      return { metric, value: metrics[metric], next_badge_code: nextB?.id ?? null, next_badge_name: nextB?.name ?? null, next_threshold: nextB?.threshold ?? null };
    });
    return {
      current_streak: u.current_streak,
      longest_streak: u.longest_streak,
      // AC-05.04.2: hôm nay (giờ VN) đã có lần +1 chuỗi chưa → app hiện "Hôm nay chưa cộng chuỗi" (không phải "đã mất")
      streak_counted_today: u.streak_last_inc_day === vnDay(new Date()),
      show_streak: u.show_streak,
      badge_progress: progress,
      next_milestone: next?.threshold ?? null,
      badges: badges.map((b) => ({ code: b.badge_id, earned_at: b.awarded_at.toISOString(), visible_on_profile: b.showcase_slot !== null })),
    };
  });

  // Lịch điểm danh tháng (US-05.02, BR-46)
  app.get('/v1/me/attendance', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const q = parse(z.object({ month: MonthStr.default(vnDay(new Date()).slice(0, 7)) }), req.query);
    const days = daysOfMonth(q.month);
    const rows = await ctx.db.selectFrom('daily_attendance').select('day').where('user_id', '=', me.id)
      .where('day', '>=', days[0]).where('day', '<=', days[days.length - 1]).execute();
    const set = new Set(rows.map((r) => r.day));
    return { month: q.month, days: days.map((d) => ({ date: d, attended: set.has(d) })) };
  });

  // Lịch sử chuỗi/huy hiệu (US-05.08) — mới nhất trước
  app.get('/v1/me/achievements/history', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const q = parse(z.object({ cursor: z.string().optional(), limit: z.coerce.number().int().min(1).max(100).default(20) }), req.query);
    let qb = ctx.db.selectFrom('achievement_log').select(['entry_id', 'kind', 'value_after', 'ref_badge_id', 'created_at'])
      .where('user_id', '=', me.id).where('kind', 'in', ['STREAK_INC', 'STREAK_BREAK', 'STREAK_RESTORE', 'BADGE_AWARD']);
    const c = decodeCursor(q.cursor);
    if (c) qb = qb.where((eb) => eb.or([eb('created_at', '<', c.t), eb.and([eb('created_at', '=', c.t), eb('entry_id', '<', c.id)])]));
    const rows = await qb.orderBy('created_at', 'desc').orderBy('entry_id', 'desc').limit(q.limit + 1).execute();
    const page = rows.slice(0, q.limit);
    const kind = { STREAK_INC: 'STREAK_UP', STREAK_RESTORE: 'STREAK_UP', STREAK_BREAK: 'STREAK_BROKEN', BADGE_AWARD: 'BADGE_EARNED', CHECKIN: 'STREAK_UP' } as const;
    return {
      next_cursor: rows.length > q.limit ? encodeCursor(page[page.length - 1].created_at, String(page[page.length - 1].entry_id)) : null,
      items: page.map((r) => ({
        kind: kind[r.kind], value: r.value_after ?? 0, badge_code: r.kind === 'BADGE_AWARD' ? r.ref_badge_id : null, server_ts: r.created_at.toISOString(),
      })),
    };
  });

  // Bật/tắt trưng bày huy hiệu (BR-99: tối đa 3)
  app.put('/v1/me/badges/:badge_code/display', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { badge_code } = parse(z.object({ badge_code: z.string().min(1).max(40) }), req.params);
    const { visible } = parse(z.object({ visible: z.boolean() }), req.body);
    await ctx.db.transaction().execute(async (tx) => {
      const mine = await tx.selectFrom('user_badges').select(['showcase_slot']).where('user_id', '=', me.id).execute();
      const b = await tx.selectFrom('user_badges').select('showcase_slot').where('user_id', '=', me.id).where('badge_id', '=', badge_code).forUpdate().executeTakeFirst();
      if (!b) throw E.notFound('Bạn chưa có huy hiệu này');
      if (!visible) {
        await tx.updateTable('user_badges').set({ showcase_slot: null }).where('user_id', '=', me.id).where('badge_id', '=', badge_code).execute();
        return;
      }
      if (b.showcase_slot !== null) return;
      const used = new Set(mine.map((m) => m.showcase_slot).filter((x) => x !== null));
      const slot = [1, 2, 3].find((s) => !used.has(s));
      if (!slot) throw new AppError(422, 'VALIDATION_FAILED', 'Chỉ trưng bày tối đa 3 huy hiệu', 'BR-99');
      await tx.updateTable('user_badges').set({ showcase_slot: slot }).where('user_id', '=', me.id).where('badge_id', '=', badge_code).execute();
    });
    return reply.code(204).send();
  });
}
