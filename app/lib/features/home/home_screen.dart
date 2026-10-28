import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// V-03 Trang chủ thành viên (+ khối "Nhóm tôi quản lý", VQ-01). Mockup: `employee_home(_dashboard)`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(upcomingProvider);
    ref.invalidate(myGroupsProvider);
    ref.invalidate(meProvider);
    ref.invalidate(coinsProvider);
    await ref.read(myGroupsProvider.future).catchError((_) => <MyGroup>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(myGroupsProvider);
    final me = ref.watch(meProvider).value;
    final memberGroup = groups.value?.where((g) => !g.isOwner).firstOrNull;
    final first = me?.displayName.trim().split(' ').last ?? '';
    final header = AppHeader.large(
      caption: memberGroup == null
          ? 'DropIt!'
          : 'DropIt! · ${memberGroup.name}',
      title: first.isEmpty ? 'Xin chào!' : 'Chào $first!',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (me != null && (memberGroup != null))
            InkWell(
              borderRadius: BorderRadius.circular(DT.pill),
              onTap: () => context.push('/coins'),
              child: CoinChip('${me.coinsBalance} Coins', onCard: true),
            ),
          const SizedBox(width: DT.spaceSm),
          CircleIconButton(
            icon: Icons.notifications_none,
            tooltip: 'Hộp thông báo',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
    );
    return AppScaffold(
      header: header,
      body: AsyncBody<List<MyGroup>>(
        value: groups,
        onRetry: () => _refresh(ref),
        isEmpty: (g) => g.isEmpty,
        empty: StateMessage(
          icon: Icons.group_add_outlined,
          tone: StateTone.accent,
          title: 'Bạn chưa ở nhóm nào',
          body: 'Nhập mã mời từ chủ nhóm, hoặc tạo nhóm của bạn.',
          action: 'Nhập mã nhóm',
          onAction: () => context.push('/join'),
          secondaryAction: 'Tạo nhóm',
          onSecondaryAction: () => context.push('/groups/new'),
        ),
        builder: (list) {
          final memberGroups = list.where((g) => !g.isOwner).toList();
          final owned = list.where((g) => g.isOwner).toList();
          return PageList(
            onRefresh: () => _refresh(ref),
            children: [
              if (memberGroups.isNotEmpty) ...[
                const _UpcomingCard(),
                const _MySummary(),
              ] else
                AppCard(
                  children: [
                    Text(
                      'Bạn chưa là thành viên nhóm nào.',
                      style: context.text.titleMedium,
                    ),
                    Text(
                      'Nhập mã 8 ký tự do chủ nhóm gửi để tham gia phiên.',
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: DT.spaceXs),
                    SecondaryButton(
                      label: 'Nhập mã nhóm',
                      icon: Icons.vpn_key_outlined,
                      onPressed: () => context.push('/join'),
                    ),
                  ],
                ),
              if (owned.isNotEmpty) ...[
                const SectionHeader('Nhóm tôi quản lý'),
                for (final g in owned)
                  AppCard(
                    onTap: () => context.push('/groups/${g.groupId}'),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.name, style: context.text.headlineSmall),
                                Text(
                                  '${g.memberCount} thành viên (tối thiểu 4, tối đa 10)',
                                  style: context.text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: DT.textSecondary,
                          ),
                        ],
                      ),
                      ListRow(
                        title: 'Phiên kế tiếp',
                        divider: false,
                        trailing: StatusBadge(
                          g.nextSession == null
                              ? 'Chưa có lịch'
                              : '${hhmm(g.nextSession!.startedAt)} ${dayLabel(g.nextSession!.startedAt).toLowerCase()}',
                          tone: g.nextSession == null
                              ? BadgeTone.neutral
                              : BadgeTone.accent,
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _UpcomingCard extends ConsumerStatefulWidget {
  const _UpcomingCard();
  @override
  ConsumerState<_UpcomingCard> createState() => _UpcomingCardState();
}

class _UpcomingCardState extends ConsumerState<_UpcomingCard> {
  Timer? _clock;
  int _seconds = 0;
  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (++_seconds % 15 == 0) ref.invalidate(upcomingProvider);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final up = ref.watch(upcomingProvider);
    final t = context.text;
    return up.when(
      loading: () => Container(
        height: 180,
        decoration: BoxDecoration(
          color: DT.skeleton,
          borderRadius: BorderRadius.circular(DT.radiusCard),
        ),
      ),
      error: (e, _) => AppBanner(
        tone: BannerTone.danger,
        title: 'Chưa tải được phiên kế tiếp',
        text: 'Kiểm tra mạng rồi thử lại.',
        action: 'Thử lại',
        onAction: () => ref.invalidate(upcomingProvider),
      ),
      data: (s) {
        if (s == null) {
          return AppCard(
            children: [
              Text(
                'Phiên kế tiếp của nhóm',
                style: t.labelLarge!.copyWith(color: DT.accent),
              ),
              Text('Chưa có phiên nào được đặt lịch.', style: t.headlineSmall),
              Text(
                'Chủ nhóm sẽ đặt lịch, bạn nhận thông báo trước giờ phiên.',
                style: t.bodySmall,
              ),
            ],
          );
        }
        final left = s.startedAt.difference(DateTime.now().toUtc());
        final coins = sessionRewardCoins(s.durationMin);
        return AppCard(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Phiên kế tiếp của nhóm',
                    style: t.labelLarge!.copyWith(color: DT.accent),
                  ),
                ),
                if (!left.isNegative && left.inHours < 24)
                  StatusBadge(
                    left.inMinutes < 60
                        ? 'Còn ${left.inMinutes} phút'
                        : 'Còn ${left.inHours} giờ',
                    tone: BadgeTone.accent,
                  ),
              ],
            ),
            Text(
              'Bắt đầu lúc ${hhmm(s.startedAt)}',
              style: t.headlineSmall!.copyWith(fontFeatures: DT.tabular),
            ),
            Text(
              '${dayLabel(s.startedAt)} ${hhmm(s.startedAt)} · ${s.durationMin} phút${s.groupName == null ? '' : ' · ${s.groupName}'}',
              style: t.bodyMedium!.copyWith(color: DT.textSecondary),
            ),
            Row(
              children: [
                const Icon(Icons.monetization_on, size: 18, color: DT.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '+$coins Coins mỗi người nếu cả phiên hoàn thành',
                    style: t.labelLarge!.copyWith(color: DT.success),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DT.spaceXs),
            PrimaryButton(
              compact: true,
              label: left.isNegative
                  ? 'Vào phiên ngay'
                  : 'Check-in · Vào phòng chờ',
              onPressed: () => context.push('/session/${s.sessionId}'),
            ),
            Text(
              'Check-in trước giờ bắt đầu. Có thể rời phòng chờ rồi quay lại; phiên tự bắt đầu đúng giờ.',
              textAlign: TextAlign.center,
              style: t.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

class _MySummary extends ConsumerWidget {
  const _MySummary();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final today = ref.watch(coinsTodayProvider).value ?? 0;
    final t = context.text;
    return me.maybeWhen(
      data: (m) => Column(
        children: [
          AppCard(
            key: const Key('coinsToday'),
            onTap: () => context.push('/coins'),
            children: [
              Row(
                children: [
                  Expanded(child: Text('Coins hôm nay', style: t.labelLarge)),
                  Text(
                    '$today / 100',
                    style: t.labelMedium!.copyWith(
                      color: DT.textSecondary,
                      fontFeatures: DT.tabular,
                    ),
                  ),
                ],
              ),
              ProgressBar(value: today / 100),
              Text(
                'Trần 100 Coins mỗi ngày. Số dư: ${m.coinsBalance} Coins, chỉ đổi đồ trang trí.',
                style: t.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: DT.spaceMd),
          AppCard(
            children: [
              InfoRow(
                icon: Icons.local_fire_department,
                title: '${m.currentStreak} ngày',
              ),
            ],
          ),
        ],
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
