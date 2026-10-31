import { isBlocked } from '../moderation/service.js';
// Quyền riêng tư (EP-01/EP-07): "Dữ liệu của tôi" (US-01.08, V-25) và hồ sơ công khai người cùng nhóm (V-32).
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { currentUser, parse } from '../../shared/http.js';
import { AppError, E } from '../../shared/errors.js';
import { iso } from '../../shared/time.js';
import { publicUser } from '../groups/service.js';
import { equipped } from '../shop/routes.js';
import { avatarUrl } from '../profile/routes.js';

/** Các nhóm người này đang thuộc (thành viên hiện tại hoặc chủ nhóm chưa giải tán), kèm vai trò. */
async function liveGroups(ctx: Ctx, userId: string) {
  const owned = await ctx.db.selectFrom('groups').select('id').where('owner_id', '=', userId).where('status', '<>', 'DISSOLVED').execute();
  const member = await ctx.db.selectFrom('group_members').innerJoin('groups', 'groups.id', 'group_members.group_id')
    .select(['group_members.group_id', 'group_members.joined_at'])
    .where('group_members.user_id', '=', userId).where('group_members.left_at', 'is', null).where('groups.status', '<>', 'DISSOLVED').execute();
  const m = new Map<string, { role: 'OWNER' | 'MEMBER'; joinedAt: Date | null }>();
  for (const g of owned) m.set(g.id, { role: 'OWNER', joinedAt: null });
  for (const g of member) m.set(g.group_id, { role: 'MEMBER', joinedAt: g.joined_at });
  return m;
}

/** Loại dữ liệu đang lưu, ai thấy, thời hạn (openapi MyDataSummary.categories; ma trận 04 §3). */
const CATEGORIES = (retention: number) => [
  { code: 'EXIT_EVENTS', description: 'Sự kiện rời app trong phiên: phiên, giờ server, giải trình, khiếu nại', visible_to: ['SELF', 'GROUP_OWNER'], retention: `${retention} tháng` },
  { code: 'SESSION_RESULTS', description: 'Kết quả từng phiên: trạng thái của bạn, vào muộn, mất kết nối, vắng, phiên mất thưởng tập thể', visible_to: ['SELF', 'GROUP_OWNER'], retention: `${retention} tháng` },
  { code: 'EXPLANATIONS', description: 'Giải trình: nội dung, lúc gửi, lúc sửa', visible_to: ['SELF', 'GROUP_OWNER'], retention: `${retention} tháng` },
  { code: 'ATTENDANCE', description: 'Điểm danh theo nhóm: số ngày, số phiên, số phút', visible_to: ['SELF', 'GROUP_OWNER'], retention: 'Đến khi xóa tài khoản' },
  { code: 'MONTHLY_REPORTS', description: 'Báo cáo tháng — dòng của bạn', visible_to: ['SELF', 'GROUP_OWNER'], retention: '13 tháng' },
  { code: 'STREAK', description: 'Chuỗi ngày hiện tại và dài nhất', visible_to: ['SELF'], retention: 'Đến khi xóa tài khoản' },
  { code: 'BADGES', description: 'Huy hiệu đã đạt (người cùng nhóm chỉ thấy huy hiệu bạn tự bật trưng bày)', visible_to: ['SELF', 'GROUP_MEMBERS'], retention: 'Đến khi xóa tài khoản' },
  { code: 'COINS', description: 'Số dư và lịch sử Coins', visible_to: ['SELF'], retention: 'Đến khi xóa tài khoản' },
  { code: 'SHOP_ITEMS', description: 'Đồ đã mua; đồ đang trang bị (người cùng nhóm thấy)', visible_to: ['SELF', 'GROUP_MEMBERS'], retention: 'Đến khi xóa tài khoản' },
  { code: 'PROFILE', description: 'Tên, ảnh (người cùng nhóm thấy); email (chỉ bạn và quản trị)', visible_to: ['SELF', 'GROUP_MEMBERS', 'ADMIN'], retention: 'Đến khi xóa tài khoản' },
  { code: 'JOURNAL', description: 'Nhật ký riêng tư (mã hóa) — chỉ số mục ở đây', visible_to: ['SELF'], retention: 'Đến khi bạn xóa' },
  { code: 'CONSENTS', description: 'Bản ghi đồng ý / rút đồng ý', visible_to: ['SELF', 'ADMIN'], retention: 'Đến khi xóa tài khoản' },
];

export async function myData(ctx: Ctx, userId: string, groupId?: string) {
  const db = ctx.db;
  const u = await db.selectFrom('users').leftJoin('user_coin_balance as b', 'b.user_id', 'users.id')
    .select(['users.display_name', 'users.email', 'users.avatar_key', 'users.current_streak', 'users.longest_streak', 'users.show_streak', 'b.balance'])
    .where('users.id', '=', userId).executeTakeFirstOrThrow();

  // Nhóm (kể cả đã rời / đã giải tán) — bộ lọc V-25
  const memberships = await db.selectFrom('group_members').innerJoin('groups', 'groups.id', 'group_members.group_id')
    .select(['groups.id', 'groups.name', 'groups.status', 'group_members.joined_at', 'group_members.left_at', 'group_members.leave_reason'])
    .where('group_members.user_id', '=', userId).orderBy('group_members.joined_at', 'desc').execute();
  const groupName = new Map(memberships.map((m) => [m.id, m.name]));

  // Kết quả phiên (dòng session_members của tôi đã kết thúc) — cùng trường chủ nhóm thấy ở owner-detail (NFR-P03)
  let sq = db.selectFrom('session_members as sm').innerJoin('sessions as s', 's.id', 'sm.session_id').innerJoin('groups as g', 'g.id', 's.group_id')
    .leftJoin('users as t', 't.id', 's.forfeit_trigger_user_id')
    .select(['s.id', 's.group_id', 'g.name as group_name', 's.status', 's.started_at', 's.duration_min', 's.forfeited', 's.forfeit_trigger_user_id',
      's.cancel_reason', 't.display_name as trigger_name', 'sm.state', 'sm.late_join', 'sm.exited_at', 'sm.focus_seconds', 'sm.pause_count',
      'sm.exempted', 'sm.end_reason'])
    .where('sm.user_id', '=', userId).where('sm.is_final', '=', true as never);
  if (groupId) sq = sq.where('s.group_id', '=', groupId);
  const rows = await sq.orderBy('s.started_at', 'desc').limit(500).execute();
  const ids = rows.map((r) => r.id);
  const expl = ids.length
    ? await db.selectFrom('explanations').select(['session_id', 'body', 'created_at', 'edited_at', 'added_after_report']).where('user_id', '=', userId).where('session_id', 'in', ids).execute()
    : [];
  const appeals = ids.length
    ? await db.selectFrom('appeals').select(['session_id', 'status', 'decided_at']).where('user_id', '=', userId).where('session_id', 'in', ids).execute()
    : [];
  const sessions = rows.map((r) => ({
    session_id: r.id,
    group_id: r.group_id,
    group_name: r.group_name,
    started_at: r.started_at.toISOString(),
    duration_min: r.duration_min,
    session_status: r.status,
    final_state: r.state,
    late_join: r.late_join,
    pause_count: r.pause_count,
    focus_seconds: r.focus_seconds,
    exited_at: iso(r.exited_at),
    exempted: r.exempted,
    forfeited: r.forfeited,
    // AC-01.08.4: chỉ TÊN người khởi phát, không dữ liệu nào khác của họ (NFR-P06)
    forfeit_trigger_display_name: r.forfeited ? (r.forfeit_trigger_user_id === userId ? u.display_name : r.trigger_name) : null,
    forfeit_triggered_by_me: r.forfeited && r.forfeit_trigger_user_id === userId,
    cancel_reason: r.cancel_reason,
  }));
  const exitEvents = rows.filter((r) => r.state === 'EXITED').map((r) => {
    const e = expl.find((x) => x.session_id === r.id);
    const a = appeals.find((x) => x.session_id === r.id);
    return {
      session_id: r.id, group_id: r.group_id, group_name: r.group_name, exited_at: iso(r.exited_at), end_reason: r.end_reason, exempted: r.exempted,
      explanation: e ? { body: e.body, submitted_at: e.created_at.toISOString(), edited_at: iso(e.edited_at), added_after_report: e.added_after_report } : null,
      appeal_status: a?.status ?? null,
    };
  });

  let aq = db.selectFrom('daily_attendance').select(['group_id', (eb) => eb.fn.countAll<string>().as('days'),
    (eb) => eb.fn.sum<string>('sessions_completed').as('sessions'), (eb) => eb.fn.sum<string>('focus_minutes').as('minutes')])
    .where('user_id', '=', userId).groupBy('group_id');
  if (groupId) aq = aq.where('group_id', '=', groupId);
  const attendance = (await aq.execute()).map((a) => ({
    group_id: a.group_id, group_name: groupName.get(a.group_id) ?? null, days: Number(a.days), sessions_completed: Number(a.sessions), focus_minutes: Number(a.minutes),
  }));

  let rq = db.selectFrom('monthly_report_rows as r').innerJoin('monthly_reports as m', 'm.id', 'r.report_id').innerJoin('groups as g', 'g.id', 'm.group_id')
    .select(['m.group_id', 'g.name', 'm.period']).where('r.user_id', '=', userId).where('m.status', '=', 'GENERATED').where('m.expires_at', '>', new Date());
  if (groupId) rq = rq.where('m.group_id', '=', groupId);
  const reports = (await rq.orderBy('m.period', 'desc').execute()).map((r) => ({ group_id: r.group_id, group_name: r.name, month: r.period.slice(0, 7) }));

  let cq = db.selectFrom('consents').innerJoin('groups', 'groups.id', 'consents.group_id')
    .select(['consents.group_id', 'groups.name', 'consents.action', 'consents.consent_version', 'consents.created_at']).where('consents.user_id', '=', userId);
  if (groupId) cq = cq.where('consents.group_id', '=', groupId);
  const consents = (await cq.orderBy('consents.created_at', 'desc').execute()).map((c) => ({
    group_id: c.group_id, group_name: c.name, action: c.action, consent_version: c.consent_version, at: c.created_at.toISOString(),
  }));

  const badges = await db.selectFrom('user_badges').innerJoin('badges', 'badges.id', 'user_badges.badge_id')
    .select(['user_badges.badge_id', 'badges.name', 'user_badges.awarded_at', 'user_badges.showcase_slot']).where('user_id', '=', userId).orderBy('awarded_at').execute();
  const owned = await db.selectFrom('user_items').select((eb) => eb.fn.countAll<string>().as('n')).where('user_id', '=', userId).executeTakeFirstOrThrow();
  const ledger = await db.selectFrom('coin_ledger').select((eb) => eb.fn.countAll<string>().as('n')).where('user_id', '=', userId).executeTakeFirstOrThrow();
  const journal = await db.selectFrom('journals').select((eb) => eb.fn.countAll<string>().as('n')).where('user_id', '=', userId).executeTakeFirstOrThrow();
  const eq = await equipped(ctx, userId);

  return {
    generated_at: new Date().toISOString(),
    group_filter: groupId ?? null,
    categories: CATEGORIES(13),
    groups: memberships.map((m) => ({
      group_id: m.id, name: m.name, group_status: m.status, joined_at: m.joined_at.toISOString(), left_at: iso(m.left_at), leave_reason: m.leave_reason,
    })),
    sessions,
    exit_events: exitEvents,
    attendance,
    reports,
    consents,
    // Mục cá nhân (AC-01.08.5): luôn có, không phụ thuộc nhóm
    profile: { display_name: u.display_name, email: u.email, avatar_url: avatarUrl(ctx, u.avatar_key) },
    streak: { current: u.current_streak, longest: u.longest_streak, shown_on_profile: u.show_streak },
    badges: badges.map((b) => ({ code: b.badge_id, name: b.name, earned_at: b.awarded_at.toISOString(), shown_on_profile: b.showcase_slot !== null })),
    coins: { balance: u.balance ?? 0, ledger_entries: Number(ledger.n) },
    shop: { owned_count: Number(owned.n), equipped: { frame_item_id: eq.AVATAR_FRAME, background_item_id: eq.BACKGROUND, title_item_id: eq.TITLE } },
    journal: { entry_count: Number(journal.n) },
  };
}

export function privacyRoutes(app: FastifyInstance, ctx: Ctx) {
  // US-01.08: luôn lấy user từ token; truyền user_id của người khác → 403 (AC-01.08.3)
  app.get('/v1/me/data', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const q = parse(z.object({ group_id: z.string().uuid().optional(), user_id: z.string().optional() }), req.query);
    if (q.user_id && q.user_id !== me.id) throw new AppError(403, 'FORBIDDEN_GROUP', 'Chỉ xem được dữ liệu của chính bạn', 'NFR-11');
    return myData(ctx, me.id, q.group_id);
  });

  // V-32 hồ sơ công khai (US-07.04, AC-06.05.5/.6): chỉ người cùng nhóm; không Coins; chuỗi/huy hiệu chỉ khi tự bật (BR-99);
  // người xem là chủ nhóm → shown_streak luôn null (BR-53b). Không ghi nhật ký truy cập (Q-106).
  app.get('/v1/users/:user_id/public-profile', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { user_id } = parse(z.object({ user_id: z.string().uuid() }), req.params);
    if (await isBlocked(ctx, me.id, user_id)) throw E.notFound('Không tìm thấy người dùng');
    const target = await ctx.db.selectFrom('users').select(['id', 'show_streak', 'current_streak', 'status']).where('id', '=', user_id).executeTakeFirst();
    if (!target || target.status === 'DELETED') throw E.notFound('Không tìm thấy người dùng');
    let viewerIsOwner = false;
    let targetRole: 'OWNER' | 'MEMBER' = 'MEMBER';
    let joinedAt: Date | null = null;
    if (user_id !== me.id) {
      const mine = await liveGroups(ctx, me.id);
      const theirs = await liveGroups(ctx, user_id);
      const shared = [...theirs.keys()].filter((g) => mine.has(g));
      if (!shared.length) throw E.forbiddenGroup();
      const g = shared[0];
      viewerIsOwner = shared.some((x) => mine.get(x)!.role === 'OWNER');
      targetRole = theirs.get(g)!.role;
      joinedAt = theirs.get(g)!.joinedAt;
    }
    const badges = await ctx.db.selectFrom('user_badges').select(['badge_id']).where('user_id', '=', user_id)
      .where('showcase_slot', 'is not', null).orderBy('showcase_slot').execute();
    return {
      user: await publicUser(ctx, user_id, joinedAt),
      role: targetRole,
      shown_badges: badges.map((b) => b.badge_id),
      shown_streak: target.show_streak && !viewerIsOwner ? target.current_streak : null,
    };
  });
}
