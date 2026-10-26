import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/models.dart';
import '../../core/models_ext.dart';
import '../../core/providers.dart';
import '../../core/push.dart';
import '../../core/widgets.dart';
import '../achievements/achievements_screen.dart' show badgeName;

/// V-22 Hồ sơ của tôi. Mockup: `user_profile`, `employee_profile_inventory`.
/// Hiện khung avatar + hình nền đang trang bị. Chủ nhóm (không là thành viên nhóm nào) không thấy Coins/chuỗi/Shop (BR-53).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final owner = ref.watch(ownerOnlyProvider) ?? false;
    final showcase = owner ? <EarnedBadge>[] : (ref.watch(achievementsProvider).value?.badges.where((b) => b.visible).take(3).toList() ?? <EarnedBadge>[]);
    // BR-70 / AC-01.02.3: đang có trạng thái chưa kết thúc trong phiên → khóa Đăng xuất
    final inSession = ref.watch(liveSessionProvider) != null;
    final shop = owner ? const <ShopItem>[] : ref.watch(shopItemsProvider).value ?? const <ShopItem>[];
    final keyOf = {for (final s in shop) s.itemId: s};
    final t = context.text;
    Future<void> refresh() async {
      ref.invalidate(meProvider);
      ref.invalidate(shopItemsProvider);
      await ref.read(meProvider.future).then((_) {}, onError: (_) {});
    }

    return AppScaffold(
      header: AppHeader.large(
        title: 'Hồ sơ',
        caption: owner ? 'DropIt! · Chủ nhóm' : 'DropIt!',
        trailing: CircleIconButton(
          icon: Icons.notifications_none,
          tooltip: 'Hộp thông báo',
          onPressed: () => context.push('/notifications'),
        ),
      ),
      body: AsyncBody<MeProfile>(
        value: me,
        onRetry: () => ref.invalidate(meProvider),
        builder: (m) {
          final frame = owner ? null : keyOf[m.frameItemId];
          final bg = owner ? null : keyOf[m.backgroundItemId];
          final title = owner ? null : keyOf[m.titleItemId];
          return PageList(onRefresh: refresh, children: [
            if (m.cachedAt != null)
              AppBanner(
                key: const Key('profileStale'),
                tone: BannerTone.accent,
                icon: Icons.cloud_off,
                title: 'Chưa cập nhật',
                text: 'Không có kết nối. Đang hiện bản lưu lúc ${hhmm(m.cachedAt)} ${ddmm(m.cachedAt)}.',
                action: 'Thử lại',
                onAction: () => ref.invalidate(meProvider),
              ),
            // Hero: hình nền đang trang bị (mặc định: cam nhạt → canvas), avatar có khung.
            if (owner)
              AppCard(
                key: const Key('ownerProfileHero'),
                radius: DT.radiusLg,
                padding: const EdgeInsets.all(24),
                gap: DT.spaceMd,
                children: [
                  Center(child: Stack(clipBehavior: Clip.none, children: [
                    FramedAvatar(name: m.displayName,
                      imageUrl: m.avatarUrl == null ? null : fixHost(m.avatarUrl!), size: 88),
                    Positioned(right: -4, bottom: -4, child: CircleIconButton(
                      key: const Key('changeAvatar'), icon: Icons.photo_camera_outlined,
                      tooltip: 'Đổi ảnh đại diện', size: 44,
                      onPressed: () => pickAndUploadAvatar(context, ref))),
                  ])),
                  Column(children: [
                    Text(m.displayName, style: t.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: DT.spaceSm),
                    const StatusBadge('Chủ nhóm', tone: BadgeTone.accent),
                  ]),
                  SecondaryButton(label: 'Sửa hồ sơ', icon: Icons.edit_outlined,
                    onPressed: () => context.push('/profile/edit')),
                ],
              )
            else CosmeticSurface(
              key: const Key('profileHero'),
              artKey: bg?.previewKey,
              padding: const EdgeInsets.symmetric(vertical: DT.spaceLg, horizontal: DT.spaceMd),
              child: Column(children: [
                Stack(clipBehavior: Clip.none, children: [
                  FramedAvatar(
                    name: m.displayName,
                    imageUrl: m.avatarUrl == null ? null : fixHost(m.avatarUrl!),
                    frameKey: frame?.previewKey,
                    frameColor: frame == null ? null : previewColor(frame.previewKey),
                    size: 108,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: CircleIconButton(
                      key: const Key('changeAvatar'),
                      icon: Icons.photo_camera_outlined,
                      size: 36,
                      tooltip: 'Đổi ảnh đại diện',
                      onPressed: () => pickAndUploadAvatar(context, ref),
                    ),
                  ),
                ]),
                const SizedBox(height: DT.spaceMd),
                Text(m.displayName, style: t.headlineMedium, textAlign: TextAlign.center),
                if (title != null) ...[
                  const SizedBox(height: DT.spaceXs),
                  TitleAdornment(artKey: title.previewKey, label: title.name),
                ],
                const SizedBox(height: DT.spaceSm),
                Material(
                  color: DT.card,
                  shape: const StadiumBorder(),
                  elevation: 1,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => context.push('/profile/edit'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.edit_outlined, size: 16, color: DT.textSecondary),
                        const SizedBox(width: 6),
                        Text('Sửa hồ sơ', style: t.labelLarge),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
            if (!owner) ...[
              if (showcase.isNotEmpty)
                AppCard(children: [
                  const SectionHeader('Huy hiệu trưng bày'),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final b in showcase)
                      Expanded(child: Column(children: [
                        AchievementEmblem(code: b.code, size: 72),
                        Text(badgeName(b.code), textAlign: TextAlign.center, style: t.labelMedium),
                      ])),
                  ]),
                ]),
              StatRow(children: [
                StatTile(
                  label: 'Chuỗi hiện tại',
                  value: '${m.currentStreak} ngày',
                  caption: 'Chỉ bạn thấy',
                  icon: Icons.local_fire_department,
                ),
                GestureDetector(
                  onTap: () => context.push('/coins'),
                  child: StatTile(
                    key: const Key('profileCoins'),
                    label: 'Coins',
                    value: '${m.coinsBalance}',
                    valueColor: DT.accent,
                    caption: 'Chỉ đổi đồ trang trí',
                    icon: Icons.monetization_on,
                  ),
                ),
              ]),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: DT.spaceMd, vertical: DT.spaceXs),
                children: const [
                  _Link('Thành tích', Icons.military_tech_outlined, '/achievements'),
                  _Link('Đồ của tôi', Icons.checkroom_outlined, '/shop/mine'),
                  _Link('Nhật ký', Icons.book_outlined, '/journal'),
                  _Link('Lịch sử phiên', Icons.history, '/history'),
                  _Link('Dữ liệu của tôi', Icons.privacy_tip_outlined, '/my-data', last: true),
                ],
              ),
            ] else ...[
              const SectionHeader('Quản lý'),
              AppCard(
                radius: DT.radiusLg,
                padding: const EdgeInsets.symmetric(horizontal: DT.spaceMd, vertical: DT.spaceXs),
                children: const [
                  _Link('Nhóm tôi quản lý', Icons.groups_outlined, '/groups'),
                  _Link('Lịch phiên', Icons.event_outlined, '/owner/schedule'),
                  _Link('Báo cáo tháng', Icons.analytics_outlined, '/owner/reports', last: true),
                ],
              ),
              const SectionHeader('Cá nhân'),
              AppCard(
                radius: DT.radiusLg,
                padding: const EdgeInsets.symmetric(horizontal: DT.spaceMd, vertical: DT.spaceXs),
                children: const [
                  _Link('Nhật ký', Icons.book_outlined, '/journal'),
                  _Link('Dữ liệu của tôi', Icons.privacy_tip_outlined, '/my-data', last: true),
                ],
              ),
            ],
            if (inSession)
              const AppBanner(
                key: Key('logoutLocked'),
                tone: BannerTone.accent,
                title: 'Bạn đang trong phiên',
                text: 'Nút Đăng xuất bị khóa đến khi phiên của bạn kết thúc.',
              ),
            SecondaryButton(
              key: const Key('logoutButton'),
              label: 'Đăng xuất',
              icon: Icons.logout,
              destructive: true,
              onPressed: inSession
                  ? null
                  : () async {
                      final ok = await showConfirmDialog(context, title: 'Đăng xuất?', confirmLabel: 'Đăng xuất');
                      // kiểm lại lúc xác nhận: có thể vừa vào phòng chờ
                      if (ok && ref.read(liveSessionProvider) == null) await ref.read(authProvider.notifier).logout();
                    },
            ),
            if (!owner) Text('Không đăng xuất được khi đang trong phiên.', textAlign: TextAlign.center, style: t.bodySmall),
          ]);
        },
      ),
    );
  }
}

/// Chọn ảnh từ thư viện → `PUT /me/avatar` (xin URL) → PUT thân ảnh. JPG/PNG/WebP ≤ 5 MB (BR-98).
Future<void> pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
  final XFile? f;
  try {
    f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
  } catch (_) {
    if (context.mounted) showSnack(context, 'Không mở được thư viện ảnh.');
    return;
  }
  if (f == null) return;
  final bytes = await f.readAsBytes();
  final name = f.name.toLowerCase();
  final type = name.endsWith('.png')
      ? 'image/png'
      : name.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
  if (bytes.length > 5 * 1024 * 1024) {
    if (context.mounted) showSnack(context, 'Ảnh tối đa 5 MB.');
    return;
  }
  try {
    await ref.read(apiProvider).uploadAvatar(bytes, type);
    ref.invalidate(meProvider);
    if (context.mounted) showSnack(context, 'Đã đổi ảnh đại diện.');
  } catch (e) {
    if (context.mounted) showSnack(context, ApiError.from(e).message);
  }
}

class _Link extends StatelessWidget {
  const _Link(this.title, this.icon, this.route, {this.last = false});
  final String title;
  final IconData icon;
  final String route;
  final bool last;
  @override
  Widget build(BuildContext context) => ListRow(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: context.ownerStyle ? OwnerStyle.inset : DT.surfaceHigh,
            borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: context.ownerStyle ? OwnerStyle.ink : DT.textPrimary),
        ),
        title: title,
        divider: !last,
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: context.ownerStyle ? OwnerStyle.muted : DT.textSecondary),
        onTap: () => context.push(route),
      );
}

/// V-23 Sửa hồ sơ (tên hiển thị).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _c = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _c.text = ref.read(meProvider).value?.displayName ?? '';
  }

  Future<void> _save() async {
    final v = _c.text.trim();
    if (v.isEmpty) {
      setState(() => _err = 'Nhập tên hiển thị');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).updateMe(v);
      ref.invalidate(meProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _err = ApiError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        header: const AppHeader.back(title: 'Sửa hồ sơ', leading: HeaderLeading.close),
        footer: PrimaryButton(label: 'Lưu', loading: _busy, onPressed: _save),
        children: [
          Builder(builder: (context) {
            final m = ref.watch(meProvider).value;
            return AppCard(children: [
              Row(children: [
                FramedAvatar(
                  name: m?.displayName ?? _c.text,
                  imageUrl: m?.avatarUrl == null ? null : fixHost(m!.avatarUrl!),
                  size: 72,
                ),
                const SizedBox(width: DT.spaceMd),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ảnh đại diện', style: context.text.titleMedium),
                    Text('JPG, PNG hoặc WebP, tối đa 5 MB.', style: context.text.bodySmall),
                  ]),
                ),
              ]),
              SecondaryButton(
                key: const Key('pickAvatar'),
                label: 'Đổi ảnh đại diện',
                icon: Icons.photo_library_outlined,
                onPressed: () => pickAndUploadAvatar(context, ref),
              ),
            ]);
          }),
          AppCard(children: [
            const FieldLabel('Tên hiển thị'),
            TextField(controller: _c, maxLength: 40, decoration: inCardInput(error: _err)),
          ]),
          const HintText('Tên này hiện cho thành viên cùng nhóm và trong thông báo rời phiên.'),
        ],
      );
}

/// V-29 Coins của tôi và lịch sử.
class CoinsScreen extends ConsumerWidget {
  const CoinsScreen({super.key});

  static String typeText(CoinEntry e) => switch (e.type) {
        'SESSION_REWARD' => e.reason == 'APPEAL_RESTORE' ? 'Hoàn thưởng miễn trừ' : 'Thưởng phiên',
        'SHOP_PURCHASE' => 'Mua ở Shop',
        'ADMIN_ADJUST' => 'Điều chỉnh',
        _ => e.type,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(coinsProvider);
    final today = ref.watch(coinsTodayProvider).value;
    final t = context.text;
    Future<void> refresh() async {
      ref.invalidate(coinsProvider);
      await ref.read(coinsProvider.future).then((_) {}, onError: (_) {});
    }

    return AppScaffold(
      header: const AppHeader.back(title: 'Coins của tôi'),
      body: AsyncBody(
        value: c,
        onRetry: () => ref.invalidate(coinsProvider),
        builder: (d) => PageList(onRefresh: refresh, children: [
          if (d.cachedAt != null)
            AppBanner(
              key: const Key('coinsStale'),
              tone: BannerTone.accent,
              icon: Icons.cloud_off,
              title: 'Có thể chưa cập nhật',
              text: 'Không có kết nối. Số dư lần tải lúc ${hhmm(d.cachedAt)} ${ddmm(d.cachedAt)}. Chưa mua được ở Shop khi mất mạng.',
              action: 'Thử lại',
              onAction: () => ref.invalidate(coinsProvider),
            ),
          AppCard(
            padding: const EdgeInsets.all(DT.spaceLg),
            children: [
              Row(children: [
                Text('Số dư', style: t.labelLarge!.copyWith(color: DT.textSecondary)),
                const Spacer(),
                const Icon(Icons.monetization_on, color: DT.accent),
              ]),
              Text('${d.balance}',
                  key: const Key('coinBalance'),
                  style: t.displayMedium!.copyWith(fontSize: 44, color: DT.accent, fontFeatures: DT.tabular)),
              Text('Coins chỉ dùng mua đồ trang trí. Tối đa 100 Coins mỗi ngày.', style: t.bodySmall),
              if (today != null)
                Text(
                  key: const Key('coinsToday'),
                  today >= 100
                      ? 'Hôm nay: $today/100 — đã đạt trần, phiên tiếp theo hôm nay không cộng Coins'
                      : 'Hôm nay: $today/100',
                  style: t.labelLarge!.copyWith(color: today >= 100 ? DT.accent : DT.textSecondary),
                ),
            ],
          ),
          SecondaryButton(label: 'Đến Shop', icon: Icons.local_mall_outlined, onPressed: () => context.go('/shop')),
          const SectionHeader('Lịch sử', small: true),
          if (d.items.isEmpty)
            const AppCard(children: [
              InfoRow(
                icon: Icons.receipt_long_outlined,
                iconColor: DT.textSecondary,
                title: 'Chưa có giao dịch',
                subtitle: 'Hoàn thành phiên để nhận Coins.',
              ),
            ])
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: DT.spaceMd, vertical: DT.spaceXs),
              children: [
                for (var i = 0; i < d.items.length; i++)
                  ListRow(
                    title: typeText(d.items[i]),
                    subtitle:
                        '${ddmm(d.items[i].createdAt)} ${hhmm(d.items[i].createdAt)} · số dư ${d.items[i].balanceAfter}',
                    divider: i < d.items.length - 1,
                    trailing: Text(
                      d.items[i].amount >= 0 ? '+${d.items[i].amount}' : '${d.items[i].amount}',
                      style: t.titleMedium!.copyWith(
                          color: d.items[i].amount >= 0 ? DT.accent : DT.textPrimary, fontFeatures: DT.tabular),
                    ),
                  ),
              ],
            ),
        ]),
      ),
    );
  }
}

/// Đích điều hướng theo loại thông báo (V-16). Vai trò theo nhóm của thông báo:
/// chủ nhóm nhóm đó → màn chủ nhóm; còn lại → màn của thành viên.
String? notificationRoute(AppNotification it, List<MyGroup> groups) {
  final sid = it.sessionId ?? it.data['session_id'] as String?;
  final gid = it.groupId ?? it.data['group_id'] as String?;
  final ownerOfGroup = groups.any((g) => g.isOwner && (gid == null || g.groupId == gid));
  switch (it.type) {
    case 'APPEAL_CREATED':
      final aid = it.data['appeal_id'] as String?;
      return aid != null ? '/appeals/$aid' : (sid == null ? null : '/owner/sessions/$sid');
    case 'EXPLANATION_SUBMITTED':
      return sid == null ? null : '/owner/sessions/$sid/explanations';
    case 'MEMBER_EXITED':
    case 'SESSION_FORFEITED':
      if (sid == null) return null;
      return ownerOfGroup ? '/owner/sessions/$sid' : '/history/$sid';
    case 'SESSION_RESULT':
    case 'EXEMPTION_GRANTED':
    case 'APPEAL_DECIDED':
    case 'SESSION_CANCELLED_OUTAGE':
    case 'SESSION_CANCELLED_OUTAGE_EXITED':
      return sid == null ? null : (ownerOfGroup ? '/owner/sessions/$sid' : '/history/$sid');
    case 'REPORT_READY':
      return gid == null ? null : '/reports/$gid';
    case 'BADGE_EARNED':
    case 'STREAK_BROKEN':
      return '/achievements';
    default:
      return sid == null ? null : (ownerOfGroup ? '/owner/sessions/$sid' : '/history/$sid');
  }
}

/// V-16 Hộp thông báo.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(notificationsProvider);
    final t = context.text;
    Future<void> refresh() async {
      ref.invalidate(notificationsProvider);
      await ref.read(notificationsProvider.future).then((_) {}, onError: (_) {});
    }

    return AppScaffold(
      header: AppHeader.back(
        title: 'Thông báo',
        trailing: CircleIconButton(
          icon: Icons.done_all,
          tooltip: 'Đọc hết',
          onPressed: () async {
            try {
              await ref.read(apiProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            } catch (e) {
              if (context.mounted) showSnack(context, ApiError.from(e).message);
            }
          },
        ),
      ),
      body: Column(children: [
        const PushPermissionCard(),
        Expanded(child: AsyncBody(
        value: n,
        onRetry: refresh,
        isEmpty: (d) => d.items.isEmpty,
        empty: const StateMessage(
          icon: Icons.notifications_none,
          title: 'Chưa có thông báo',
          body: 'Thông báo nhắc phiên, rời phiên và kết quả sẽ hiện ở đây.',
        ),
        builder: (d) => PageList(onRefresh: refresh, children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: DT.spaceMd, vertical: DT.spaceXs),
            children: [
              for (var i = 0; i < d.items.length; i++)
                Builder(builder: (context) {
                  final it = d.items[i];
                  final exit = it.type == 'MEMBER_EXITED' || it.type == 'SESSION_FORFEITED';
                  return ListRow(
                    divider: i < d.items.length - 1,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: exit ? DT.warningSoftBg : DT.accentSoftBg, shape: BoxShape.circle),
                      child: Icon(exit ? Icons.logout : Icons.notifications_outlined,
                          size: 20, color: exit ? DT.warning : DT.accent),
                    ),
                    title: it.title,
                    titleStyle: t.titleMedium!.copyWith(fontWeight: it.read ? FontWeight.w400 : FontWeight.w600),
                    subtitle: '${it.body}\n${ddmm(it.serverTs)} ${hhmm(it.serverTs)}',
                    trailing: it.read
                        ? null
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: DT.accent, shape: BoxShape.circle)),
                    onTap: () async {
                      final groups = await ref.read(myGroupsProvider.future).catchError((_) => <MyGroup>[]);
                      if (!context.mounted) return;
                      final route = notificationRoute(it, groups);
                      if (!it.read) {
                        ref.read(apiProvider).markRead([it.id]).then((_) => ref.invalidate(notificationsProvider),
                            onError: (_) {});
                      }
                      if (route != null) context.push(route);
                    },
                  );
                }),
            ],
          ),
        ]),
      )),
      ]),
    );
  }
}
