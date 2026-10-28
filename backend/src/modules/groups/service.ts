// Module groups (EP-02): tạo nhóm, mã mời (BR-76), đồng ý → thành viên (BR-06, BR-74, BR-75, D-21, D-25).
import { createHash, randomInt } from 'node:crypto';
import type { Ctx } from '../../context.js';
import { AppError, E } from '../../shared/errors.js';
import { pgCode } from '../../shared/db.js';
import { sortPeople } from '../../shared/sort.js';
import { nextSessionOfGroup } from '../sessions/summary.js';
import { equipped } from '../shop/routes.js';
import { avatarUrl } from '../profile/routes.js';

// Bảng mã bỏ 0/O/1/I/L (theo CHECK schema; openapi còn cho L — xem README)
const ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
export const GROUP_MIN = 4; // BR-74, D-02 — chỉ cảnh báo
export const GROUP_MAX = 10; // BR-74 — chặn cứng
export const MAX_GROUPS_OWNED = 10; // BR-75 (b)
const INVITE_MAX_FAIL = 5;
const INVITE_LOCK_MIN = 15;

export function newInviteCode(): string {
  let s = '';
  for (let i = 0; i < 8; i++) s += ALPHABET[randomInt(ALPHABET.length)];
  return s;
}

/** Nội dung đồng ý minh bạch (V-05). Văn bản là bản nháp kỹ thuật (giả định), BA chốt câu chữ. */
export function consentItems(retentionMonths: number) {
  return [
    { code: 'RULE_D05', required: true, text: 'Nếu một người rời app quá 3 giây trong phiên, cả phiên mất thưởng tập thể; tên người rời được báo cho cả nhóm (D-05, D-22).' },
    { code: 'WHAT_RECORDED', required: true, text: 'Chỉ ghi: vào/rời phiên, rời app/quay lại, khóa màn hình, mất kết nối, thời gian tập trung. Không đọc tên app khác, nội dung máy hay vị trí.' },
    { code: 'OWNER_SEES', required: true, text: 'Chủ nhóm thấy kết quả phiên và điểm danh trong nhóm; KHÔNG thấy Coins, chuỗi của bạn.' },
    { code: 'RETENTION', required: true, text: `Kết quả từng phiên lưu ${retentionMonths} tháng (DQ-D02, giả định); điểm danh/chuỗi lưu đến khi xóa tài khoản.` },
  ];
}
const termsHash = (items: { code: string; text: string }[]) =>
  createHash('sha256').update(JSON.stringify(items)).digest('hex');

export async function memberCount(ctx: Ctx, groupId: string): Promise<number> {
  const r = await ctx.db
    .selectFrom('group_members')
    .select((eb) => eb.fn.countAll<string>().as('n'))
    .where('group_id', '=', groupId)
    .where('left_at', 'is', null)
    .executeTakeFirstOrThrow();
  return Number(r.n);
}

export async function getGroupRow(ctx: Ctx, groupId: string) {
  const g = await ctx.db.selectFrom('groups').selectAll().where('id', '=', groupId).executeTakeFirst();
  if (!g || g.status === 'DISSOLVED') throw E.notFound('Không tìm thấy nhóm');
  return g;
}

export async function activeMembership(ctx: Ctx, userId: string) {
  return ctx.db
    .selectFrom('group_members')
    .innerJoin('groups', 'groups.id', 'group_members.group_id')
    .select(['group_members.group_id', 'group_members.consent_version', 'group_members.joined_at', 'groups.name', 'groups.consent_version as group_consent_version'])
    .where('group_members.user_id', '=', userId)
    .where('groups.status', '<>', 'DISSOLVED')
    .where('group_members.left_at', 'is', null)
    .executeTakeFirst();
}

/** Vai trò theo từng nhóm (D-10): OWNER | MEMBER | null. */
export async function roleIn(ctx: Ctx, userId: string, groupId: string) {
  const g = await getGroupRow(ctx, groupId);
  if (g.owner_id === userId) return { g, role: 'OWNER' as const };
  const m = await ctx.db
    .selectFrom('group_members').select('id')
    .where('group_id', '=', groupId).where('user_id', '=', userId).where('left_at', 'is', null)
    .executeTakeFirst();
  return { g, role: m ? ('MEMBER' as const) : null };
}

export async function requireOwner(ctx: Ctx, userId: string, groupId: string) {
  const r = await roleIn(ctx, userId, groupId);
  if (r.role === 'MEMBER') throw E.notOwner();
  if (r.role !== 'OWNER') throw E.forbiddenGroup();
  return r.g;
}

export async function ownerView(ctx: Ctx, groupId: string) {
  const g = await getGroupRow(ctx, groupId);
  const n = await memberCount(ctx, groupId);
  return {
    group_id: g.id,
    name: g.name,
    report_purpose: g.report_purpose,
    status: g.status,
    member_count: n,
    below_minimum: n < GROUP_MIN,
    consent_version: g.consent_version,
    invite_code: g.invite_code.trim(),
    created_at: g.created_at.toISOString(),
  };
}

/** PublicUser (openapi): tên, avatar, đồ đang trang bị — không Coins/chuỗi (BR-53). */
export async function publicUser(ctx: Ctx, userId: string, joinedAt: Date | null = null) {
  const u = await ctx.db.selectFrom('users').select(['id', 'display_name', 'avatar_key']).where('id', '=', userId).executeTakeFirstOrThrow();
  const eq = await equipped(ctx, userId);
  return { ...pub(u.id, u.display_name, joinedAt), avatar_url: avatarUrl(ctx, u.avatar_key), frame_item_id: eq.AVATAR_FRAME, background_item_id: eq.BACKGROUND, title_item_id: eq.TITLE };
}
const pub = (id: string, name: string, joinedAt: Date | null) => ({
  user_id: id, display_name: name, avatar_url: null as string | null, frame_item_id: null as string | null,
  background_item_id: null as string | null, title_item_id: null as string | null,
  joined_at: joinedAt ? joinedAt.toISOString() : null,
});

export async function createGroup(ctx: Ctx, userId: string, input: { name: string; report_purpose: string }) {
  const name = input.name.trim();
  if (name.length < 1 || name.length > 60) throw new AppError(422, 'VALIDATION_FAILED', 'Tên nhóm 1–60 ký tự (DQ-D10)');
  const owned = await ctx.db
    .selectFrom('groups').select((eb) => eb.fn.countAll<string>().as('n'))
    .where('owner_id', '=', userId).where('status', '<>', 'DISSOLVED').executeTakeFirstOrThrow();
  if (Number(owned.n) >= MAX_GROUPS_OWNED)
    throw new AppError(409, 'MAX_GROUPS_OWNED', `Bạn đã làm chủ tối đa ${MAX_GROUPS_OWNED} nhóm`, 'BR-75');
  for (let attempt = 0; attempt < 5; attempt++) {
    try {
      const g = await ctx.db
        .insertInto('groups')
        .values({ owner_id: userId, name, report_purpose: input.report_purpose, invite_code: newInviteCode() })
        .returning('id')
        .executeTakeFirstOrThrow();
      return ownerView(ctx, g.id);
    } catch (e) {
      if (pgCode(e) === '23505') continue; // trùng mã mời → sinh lại
      if (pgCode(e) === '23514' && String((e as Error).message).includes('số nhóm'))
        throw new AppError(409, 'MAX_GROUPS_OWNED', 'Vượt số nhóm tối đa được tạo', 'BR-75');
      throw e;
    }
  }
  throw new AppError(500, 'INTERNAL', 'Không sinh được mã mời');
}

export async function getGroup(ctx: Ctx, userId: string, groupId: string) {
  const { g, role } = await roleIn(ctx, userId, groupId);
  if (role === 'OWNER') return ownerView(ctx, groupId);
  if (role !== 'MEMBER') throw E.forbiddenGroup();
  return {
    group_id: g.id,
    name: g.name,
    report_purpose: g.report_purpose,
    status: g.status,
    member_count: await memberCount(ctx, groupId),
    owner: await publicUser(ctx, g.owner_id),
  };
}

/** Owner-only soft dissolution. History/report rows remain readable, access is closed. */
export async function dissolveGroup(ctx: Ctx, userId: string, groupId: string) {
  const outcome = await ctx.db.transaction().execute(async (tx) => {
    const g = await tx.selectFrom('groups').selectAll().where('id', '=', groupId).forUpdate().executeTakeFirst();
    if (!g) throw E.notFound('Không tìm thấy nhóm');
    if (g.owner_id !== userId) throw E.notOwner();
    if (g.status === 'DISSOLVED') return { members: [] as string[], name: g.name };
    const sessions = await tx.selectFrom('sessions').select(['id', 'status', 'started_at'])
      .where('group_id', '=', groupId).where('status', 'in', ['SCHEDULED', 'COUNTDOWN', 'ACTIVE']).forUpdate().execute();
    const now = new Date();
    if (sessions.some((s) => s.status !== 'SCHEDULED' ||
      (ctx.sessions.runtimeStatus(s.id) && ctx.sessions.runtimeStatus(s.id) !== 'SCHEDULED') ||
      s.started_at.getTime() - ctx.cfg.engine.countdownMs <= now.getTime())) {
      throw new AppError(409, 'SESSION_IN_PROGRESS', 'Không thể xóa nhóm khi phiên đang đếm ngược hoặc hoạt động');
    }
    const members = await tx.selectFrom('group_members').select('user_id').where('group_id', '=', groupId).where('left_at', 'is', null).execute();
    // Stop loaded lobby timers synchronously before their activation can race the writes.
    for (const session of sessions) ctx.sessions.cancelLoaded(session.id);
    const sessionIds = sessions.map((s) => s.id);
    if (sessionIds.length) {
      await tx.updateTable('session_members').set({ state: 'VOID', end_reason: 'SESSION_CANCELLED', ended_at: now })
        .where('session_id', 'in', sessionIds).where('is_final', '=', false as never).execute();
      await tx.updateTable('sessions').set({ status: 'CANCELLED', cancel_reason: 'GROUP_DISSOLVED', cancelled_at: now })
        .where('id', 'in', sessionIds).where('status', '=', 'SCHEDULED').execute();
    }
    await tx.updateTable('schedules').set({ cancelled_at: now }).where('group_id', '=', groupId).where('cancelled_at', 'is', null).execute();
    await tx.updateTable('group_members').set({ left_at: now, leave_reason: 'GROUP_DISSOLVED', removal_effective_at: null })
      .where('group_id', '=', groupId).where('left_at', 'is', null).execute();
    await tx.updateTable('groups').set({ status: 'DISSOLVED', dissolved_at: now }).where('id', '=', groupId).execute();
    return { members: members.map((m) => m.user_id), name: g.name };
  });
  if (outcome.members.length) await ctx.notifications.notify(outcome.members, {
    type: 'GROUP_DISSOLVED', title: outcome.name, body: 'Chủ nhóm đã xóa nhóm. Các phiên chưa bắt đầu đã hủy; kết quả cá nhân được giữ lại.',
    data: { group_id: groupId }, dedupeKey: `GROUP_DISSOLVED:${groupId}`,
  });
  return { group_id: groupId, status: 'DISSOLVED' as const };
}

export async function rotateInviteCode(ctx: Ctx, userId: string, groupId: string) {
  await requireOwner(ctx, userId, groupId);
  for (let attempt = 0; attempt < 5; attempt++) {
    try {
      const r = await ctx.db
        .updateTable('groups')
        .set({ invite_code: newInviteCode(), invite_code_rotated_at: new Date() })
        .where('id', '=', groupId)
        .returning(['invite_code', 'invite_code_rotated_at'])
        .executeTakeFirstOrThrow();
      return { code: r.invite_code.trim(), created_at: r.invite_code_rotated_at.toISOString() };
    } catch (e) {
      if (pgCode(e) === '23505') continue;
      throw e;
    }
  }
  throw new AppError(500, 'INTERNAL', 'Không sinh được mã mời');
}

export async function getInviteCode(ctx: Ctx, userId: string, groupId: string) {
  const { g, role } = await roleIn(ctx, userId, groupId);
  if (!role) throw E.forbiddenGroup();
  if (g.status !== 'ACTIVE') throw E.forbiddenGroup();
  return { code: g.invite_code.trim(), created_at: g.invite_code_rotated_at.toISOString() };
}

/** BR-76: 5 lần sai/15 phút → khóa 15 phút cho tài khoản. */
async function checkInviteLock(ctx: Ctx, userId: string) {
  const since = new Date(Date.now() - INVITE_LOCK_MIN * 60000);
  const fails = await ctx.db
    .selectFrom('invite_attempts').select('created_at')
    .where('user_id', '=', userId).where('success', '=', false).where('created_at', '>', since)
    .orderBy('created_at', 'desc').limit(INVITE_MAX_FAIL).execute();
  if (fails.length >= INVITE_MAX_FAIL) {
    const unlockAt = fails[INVITE_MAX_FAIL - 1].created_at.getTime() + INVITE_LOCK_MIN * 60000;
    const err = new AppError(429, 'INVITE_CODE_LOCKED', `Nhập sai mã quá ${INVITE_MAX_FAIL} lần. Thử lại sau ${INVITE_LOCK_MIN} phút.`, 'BR-76');
    (err as AppError & { retryAfter?: number }).retryAfter = Math.max(1, Math.ceil((unlockAt - Date.now()) / 1000));
    throw err;
  }
}

async function findByCode(ctx: Ctx, code: string) {
  return ctx.db.selectFrom('groups').selectAll().where('invite_code', '=', code).where('status', '<>', 'DISSOLVED').executeTakeFirst();
}

export async function previewInvite(ctx: Ctx, userId: string, code: string) {
  await checkInviteLock(ctx, userId);
  const g = await findByCode(ctx, code);
  await ctx.db.insertInto('invite_attempts').values({ user_id: userId, success: !!g }).execute();
  if (!g) throw new AppError(404, 'INVITE_CODE_INVALID', 'Mã nhóm không đúng hoặc đã hết hiệu lực', 'BR-76');
  const owner = await publicUser(ctx, g.owner_id);
  const n = await memberCount(ctx, g.id);
  return {
    group_id: g.id,
    group_name: g.name,
    owner_display_name: owner.display_name,
    report_purpose: g.report_purpose,
    consent_version: g.consent_version,
    member_count: n,
    is_full: n >= GROUP_MAX,
    items: consentItems(g.retention_months),
  };
}

export async function acceptConsent(
  ctx: Ctx, userId: string, groupId: string,
  body: { consent_version: number; invite_code?: string; accepted_items?: string[] },
) {
  const g = await getGroupRow(ctx, groupId);
  if (g.owner_id === userId) throw new AppError(409, 'OWNER_OF_THIS_GROUP', 'Bạn là chủ nhóm này — chủ nhóm không là thành viên (D-25)', 'BR-114');
  if (body.consent_version !== g.consent_version)
    throw new AppError(409, 'CONSENT_VERSION_STALE', 'Nội dung đồng ý đã đổi, vui lòng xem lại', 'BR-71');
  const items = consentItems(g.retention_months);
  const missing = body.accepted_items ? items.filter((i) => i.required && !body.accepted_items!.includes(i.code)) : [];
  if (missing.length) throw new AppError(422, 'VALIDATION_FAILED', `Chưa tích: ${missing.map((m) => m.code).join(', ')}`, 'BR-06');
  const cur = await activeMembership(ctx, userId);
  const consentRow = {
    user_id: userId, group_id: groupId, consent_version: g.consent_version, action: 'GRANT' as const,
    purpose_snapshot: g.report_purpose, retention_months: g.retention_months, terms_hash: termsHash(items), client_info: null,
  };
  if (cur && cur.group_id === groupId) {
    // Đồng ý lại (US-01.06, DQ-A12): đã là thành viên, không cần mã
    await ctx.db.transaction().execute(async (tx) => {
      await tx.updateTable('group_members').set({ consent_version: g.consent_version, consented_at: new Date() })
        .where('group_id', '=', groupId).where('user_id', '=', userId).where('left_at', 'is', null).execute();
      await tx.insertInto('consents').values(consentRow).execute();
    });
    return myGroup(ctx, userId, groupId, 'MEMBER');
  }
  if (!body.invite_code || body.invite_code !== g.invite_code.trim())
    throw new AppError(404, 'INVITE_CODE_INVALID', 'Mã nhóm không đúng hoặc đã hết hiệu lực', 'BR-76');
  if (cur) throw new AppError(409, 'ALREADY_IN_GROUP', `Bạn đang ở nhóm ${cur.name}. Rời nhóm ${cur.name} trước khi tham gia nhóm khác.`, 'BR-75');
  if (g.status !== 'ACTIVE') throw new AppError(409, 'GROUP_FULL', 'Nhóm không nhận thành viên mới lúc này', 'T-BA-37');
  try {
    await ctx.db.transaction().execute(async (tx) => {
      // khóa nhóm để kiểm trần 10 tuần tự (trigger cũng kiểm)
      await tx.selectFrom('groups').select('id').where('id', '=', groupId).forUpdate().execute();
      const n = await tx.selectFrom('group_members').select((eb) => eb.fn.countAll<string>().as('n'))
        .where('group_id', '=', groupId).where('left_at', 'is', null).executeTakeFirstOrThrow();
      if (Number(n.n) >= GROUP_MAX) throw new AppError(409, 'GROUP_FULL', 'Nhóm đã đủ 10 thành viên', 'BR-74');
      await tx.insertInto('group_members').values({ group_id: groupId, user_id: userId, consent_version: g.consent_version, consented_at: new Date(), left_at: null, leave_reason: null }).execute();
      await tx.insertInto('consents').values(consentRow).execute();
    });
  } catch (e) {
    if (e instanceof AppError) throw e;
    if (pgCode(e) === '23505') throw new AppError(409, 'ALREADY_IN_GROUP', 'Bạn đang ở nhóm khác', 'BR-75');
    if (pgCode(e) === '23514' && String((e as Error).message).includes('10 thành viên')) throw new AppError(409, 'GROUP_FULL', 'Nhóm đã đủ 10 thành viên', 'BR-74');
    throw e;
  }
  return myGroup(ctx, userId, groupId, 'MEMBER');
}

export async function myGroup(ctx: Ctx, userId: string, groupId: string, role: 'OWNER' | 'MEMBER') {
  const g = await getGroupRow(ctx, groupId);
  let needs = false;
  if (role === 'MEMBER') {
    const m = await activeMembership(ctx, userId);
    needs = !!m && m.consent_version < g.consent_version;
  }
  const n = await memberCount(ctx, groupId);
  return {
    group_id: g.id,
    name: g.name,
    role,
    status: g.status, // AC-02.06.1
    member_count: n,
    below_minimum: role === 'OWNER' ? n < GROUP_MIN : null, // AC-01.07.6, AC-02.08.6 (chỉ chủ nhóm)
    consent_version: g.consent_version,
    needs_reconsent: needs,
    next_session: await nextSessionOfGroup(ctx, groupId),
    // AC-02.06.6 / BR-117: chỉ số RIÊNG từng nhóm, tháng hiện tại tạm tính đến hôm qua (chủ nhóm: cả nhóm; thành viên: của mình)
    month_completion_rate: await monthCompletionRate(ctx, groupId, role === 'MEMBER' ? userId : null),
  };
}

/** Tỉ lệ hoàn thành phiên tháng hiện tại (giờ VN) đến hết hôm qua, như §Báo cáo §3: hoàn thành / lượt dự kiến. */
export async function monthCompletionRate(ctx: Ctx, groupId: string, onlyUser: string | null, now = new Date()): Promise<number | null> {
  const vn = new Date(now.getTime() + 7 * 3600e3);
  const monthStart = new Date(Date.UTC(vn.getUTCFullYear(), vn.getUTCMonth(), 1) - 7 * 3600e3);
  const todayStart = new Date(Date.UTC(vn.getUTCFullYear(), vn.getUTCMonth(), vn.getUTCDate()) - 7 * 3600e3);
  if (todayStart <= monthStart) return null; // ngày 1: chưa có "đến hôm qua"
  const sessions = await ctx.db.selectFrom('sessions').select(['id', 'started_at']).where('group_id', '=', groupId)
    .where('status', '=', 'COMPLETED').where('started_at', '>=', monthStart).where('started_at', '<', todayStart).execute();
  if (!sessions.length) return null;
  let mq = ctx.db.selectFrom('group_members').select(['user_id', 'joined_at', 'left_at']).where('group_id', '=', groupId)
    .where('joined_at', '<', todayStart).where((eb) => eb.or([eb('left_at', 'is', null), eb('left_at', '>=', monthStart)]));
  if (onlyUser) mq = mq.where('user_id', '=', onlyUser);
  const members = await mq.execute();
  const sms = await ctx.db.selectFrom('session_members').select(['session_id', 'user_id', 'state'])
    .where('session_id', 'in', sessions.map((x) => x.id)).execute();
  const st = new Map(sms.map((r) => [`${r.session_id}:${r.user_id}`, r.state]));
  let expected = 0;
  let done = 0;
  for (const m of members)
    for (const x of sessions) {
      if (x.started_at < m.joined_at || (m.left_at && x.started_at >= m.left_at)) continue;
      const state = st.get(`${x.id}:${m.user_id}`) ?? 'ABSENT';
      if (state === 'WITHDRAWN' || state === 'VOID') continue;
      expected++;
      if (state === 'COMPLETED') done++;
    }
  return expected ? Math.round((done / expected) * 1000) / 10 : null;
}

const collVi = new Intl.Collator('vi', { sensitivity: 'base' });

export async function listMyGroups(ctx: Ctx, userId: string) {
  const owned = await ctx.db.selectFrom('groups').select(['id', 'name', 'created_at'])
    .where('owner_id', '=', userId).where('status', '<>', 'DISSOLVED').execute();
  // BR-117: theo tên nhóm (tiếng Việt, không phân biệt hoa/thường), trùng tên theo thời điểm tạo
  owned.sort((a, b) => collVi.compare(a.name, b.name) || a.created_at.getTime() - b.created_at.getTime());
  const items = [];
  for (const g of owned) items.push(await myGroup(ctx, userId, g.id, 'OWNER'));
  const m = await activeMembership(ctx, userId);
  if (m) items.push(await myGroup(ctx, userId, m.group_id, 'MEMBER'));
  return { items };
}

// ---------------- rời nhóm / rút đồng ý (US-01.07) ----------------

/** Bỏ trạng thái INVITED của người này ở các phiên SCHEDULED của nhóm (AC-01.07.1). */
async function dropInvited(ctx: Ctx, groupId: string, userId: string) {
  await ctx.db.deleteFrom('session_members').where('user_id', '=', userId).where('state', '=', 'INVITED')
    .where('session_id', 'in', (eb) => eb.selectFrom('sessions').select('id').where('group_id', '=', groupId).where('status', '=', 'SCHEDULED'))
    .execute();
}

/**
 * Rút đồng ý = rời nhóm (BR-26, D-14). Trong phiên → WITHDRAWN ngay (không MEMBER_EXITED, không forfeited).
 * Chủ nhóm chỉ nhận "X đã rời nhóm", không lý do. Coins/đồ/chuỗi/hồ sơ/nhật ký giữ nguyên.
 */
export async function withdrawConsent(ctx: Ctx, userId: string, groupId: string) {
  const g = await ctx.db.selectFrom('groups').selectAll().where('id', '=', groupId).executeTakeFirst();
  if (!g) throw E.notFound('Không tìm thấy nhóm');
  if (g.owner_id === userId)
    throw new AppError(403, 'OWNER_OF_THIS_GROUP', 'Chủ nhóm không rút đồng ý — chỉ có "Giải tán nhóm"', 'D-25');
  const mem = await ctx.db.selectFrom('group_members').select(['id']).where('group_id', '=', groupId)
    .where('user_id', '=', userId).where('left_at', 'is', null).executeTakeFirst();
  if (!mem) throw E.forbiddenGroup();
  // Đồng bộ ngay sau lần đọc cuối: WITHDRAWN ưu tiên mọi hạn đang chạy (AC-01.07.2)
  const inSession = ctx.sessions.withdrawFromGroup(groupId, userId);
  const now = new Date();
  const items = consentItems(g.retention_months);
  await ctx.db.transaction().execute(async (tx) => {
    await tx.updateTable('group_members').set({ left_at: now, leave_reason: 'CONSENT_WITHDRAWN', removal_effective_at: null })
      .where('id', '=', mem.id).where('left_at', 'is', null).execute();
    await tx.insertInto('consents').values({
      user_id: userId, group_id: groupId, consent_version: g.consent_version, action: 'WITHDRAW',
      purpose_snapshot: g.report_purpose, retention_months: g.retention_months, terms_hash: termsHash(items), client_info: null,
    }).execute();
  });
  await dropInvited(ctx, groupId, userId);
  const me = await ctx.db.selectFrom('users').select('display_name').where('id', '=', userId).executeTakeFirstOrThrow();
  const n = await memberCount(ctx, groupId);
  await ctx.notifications.notify([g.owner_id], {
    type: 'MEMBER_LEFT_GROUP', title: g.name,
    body: `${me.display_name} đã rời nhóm.` + (n < GROUP_MIN ? ' Nhóm dưới 4 người — mời thêm.' : ''),
    data: { group_id: groupId, member_count: n, below_minimum: n < GROUP_MIN },
    dedupeKey: `MEMBER_LEFT_GROUP:${groupId}:${userId}:${now.getTime()}`,
  });
  return {
    group_id: groupId,
    left_at: now.toISOString(),
    // WITHDRAWN trong phiên (nếu có); after_forfeit → vẫn bị ngắt chuỗi tại ends_at (D-23)
    sessions: inSession.map((x) => ({ session_id: x.sessionId, state: 'WITHDRAWN', after_forfeit: x.afterForfeit })),
  };
}

// ---------------- chủ nhóm xóa thành viên (US-02.08) ----------------

async function finalizeRemoval(ctx: Ctx, g: { id: string; name: string }, userId: string) {
  const now = new Date();
  const r = await ctx.db.updateTable('group_members').set({ left_at: now, leave_reason: 'REMOVED' })
    .where('group_id', '=', g.id).where('user_id', '=', userId).where('left_at', 'is', null).returning('id').executeTakeFirst();
  if (!r) return false;
  await dropInvited(ctx, g.id, userId);
  await ctx.notifications.notify([userId], {
    type: 'REMOVED_FROM_GROUP', title: g.name, body: `Bạn không còn trong nhóm ${g.name}.`,
    data: { group_id: g.id }, dedupeKey: `REMOVED_FROM_GROUP:${g.id}:${userId}:${now.getTime()}`,
  });
  return true;
}

/** BR-77: ngoài phiên hiệu lực ngay; đang có trạng thái chưa kết thúc trong phiên đang chạy → sau ends_at. */
export async function removeMember(ctx: Ctx, ownerId: string, groupId: string, userId: string) {
  const g = await requireOwner(ctx, ownerId, groupId);
  if (userId === ownerId)
    throw new AppError(409, 'CANNOT_REMOVE_SELF', 'Không thể tự xóa mình khỏi nhóm. Dùng "Giải tán nhóm".', 'D-25');
  const mem = await ctx.db.selectFrom('group_members').select(['id']).where('group_id', '=', groupId)
    .where('user_id', '=', userId).where('left_at', 'is', null).executeTakeFirst();
  if (!mem) throw E.notFound('Người này không là thành viên nhóm');
  const live = ctx.sessions.liveIn(groupId, userId);
  if (live) {
    const eff = new Date(live.endsAt);
    await ctx.db.updateTable('group_members').set({ removal_effective_at: eff }).where('id', '=', mem.id).execute();
    return { status: 202, body: { user_id: userId, effective: 'AFTER_SESSION', effective_at: eff.toISOString(), session_id: live.sessionId } as Record<string, unknown> | undefined };
  }
  await finalizeRemoval(ctx, g, userId);
  return { status: 204, body: undefined as Record<string, unknown> | undefined };
}

/** Áp các lần xóa đang chờ khi người đó không còn trong phiên đang chạy (gọi sau ends_at/hủy và từ cron). */
export async function applyPendingRemovals(ctx: Ctx, groupId?: string) {
  let q = ctx.db.selectFrom('group_members').innerJoin('groups', 'groups.id', 'group_members.group_id')
    .select(['group_members.user_id', 'group_members.group_id', 'groups.name'])
    .where('group_members.left_at', 'is', null).where('group_members.removal_effective_at', 'is not', null);
  if (groupId) q = q.where('group_members.group_id', '=', groupId);
  let n = 0;
  for (const r of await q.execute()) {
    if (ctx.sessions.liveIn(r.group_id, r.user_id)) continue;
    if (await finalizeRemoval(ctx, { id: r.group_id, name: r.name }, r.user_id)) n++;
  }
  return n;
}

export async function listMembers(ctx: Ctx, userId: string, groupId: string) {
  const { g, role } = await roleIn(ctx, userId, groupId);
  if (!role) throw E.forbiddenGroup();
  const rows = await ctx.db
    .selectFrom('group_members').innerJoin('users', 'users.id', 'group_members.user_id')
    .select(['users.id', 'users.display_name', 'group_members.joined_at'])
    .where('group_members.group_id', '=', groupId).where('group_members.left_at', 'is', null).execute();
  const people = [];
  for (const r of rows) people.push(await publicUser(ctx, r.id, r.joined_at)); // AC-07.04.1: khung/hình nền đang trang bị
  const members = sortPeople(people);
  return {
    owner: await publicUser(ctx, g.owner_id),
    members,
    member_count: members.length,
    below_minimum: role === 'OWNER' ? members.length < GROUP_MIN : null,
  };
}
