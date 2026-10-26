import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/models_ext.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Nội dung khối kết quả theo biến thể (V-12, V-13, V-14) — thuần, dễ test.
String participantStateText(String s) => switch (s) {
  'COMPLETED' => 'Hoàn thành',
  'EXITED' => 'Rời phiên',
  'LOST' => 'Mất kết nối',
  'ABSENT' => 'Vắng',
  'WITHDRAWN' => 'Đã rời nhóm',
  'VOID' => 'Không tính',
  _ => s,
};

class ResultCopy {
  const ResultCopy(this.label, this.icon, this.color, this.reason, this.coins);
  final String label;
  final IconData icon;
  final Color color;
  final String? reason;
  final String coins;

  static ResultCopy of(MySessionResult r) {
    final coins = r.finalState == 'VOID' || r.cancelledOutageExited
        ? 'Không tính'
        : r.coinsAwarded > 0
        ? '+${r.coinsAwarded} Coins${r.rewardCapReached ? ' (đã đạt trần ngày)' : ''}'
        : (r.rewardCapReached ? '0 Coins — đã đạt trần ngày' : '0 Coins');
    final who = r.forfeitTrigger;
    switch (r.finalState) {
      case 'COMPLETED':
        if (r.forfeited) {
          return ResultCopy(
            'Hoàn thành',
            Icons.check_circle_outline,
            DT.success,
            'Phiên đã mất thưởng tập thể${who == null ? '' : ' do $who rời phiên'}. Bạn vẫn hoàn thành phiên.',
            coins,
          );
        }
        return ResultCopy(
          r.coinsAwarded > 0 ? 'Hoàn thành có thưởng' : 'Hoàn thành',
          Icons.emoji_events_outlined,
          DT.success,
          r.rewardCapReached ? 'Bạn đã đạt trần thưởng trong ngày.' : null,
          coins,
        );
      case 'EXITED':
        return ResultCopy(
          'Bạn đã rời phiên',
          Icons.logout,
          DT.warning,
          r.cancelledOutageExited
              ? 'Phiên bị hủy do sự cố hệ thống. Lần rời này không tính.'
              : r.forfeited
              ? 'Phiên đã mất thưởng tập thể. Bạn đã kết thúc phần tham gia sớm.'
              : 'Bạn đã kết thúc phần tham gia sớm.',
          coins,
        );
      case 'LOST':
        return ResultCopy(
          'Mất kết nối',
          Icons.wifi_off,
          DT.textSecondary,
          'Bạn mất kết nối quá lâu nên phần tham gia kết thúc sớm. Lần mất kết nối này không làm mất thưởng tập thể.'
              '${r.forfeited ? ' Phiên đã mất thưởng tập thể${who == null ? '' : ' do $who rời phiên'}.' : ''}',
          coins,
        );
      case 'ABSENT':
        return ResultCopy(
          'Vắng',
          Icons.event_busy,
          DT.textSecondary,
          'Bạn chưa vào phiên trước giờ bắt đầu. Vắng không phải là chủ động rời phiên.',
          coins,
        );
      case 'VOID':
        return ResultCopy(
          'Phiên bị hủy — không tính',
          Icons.block,
          DT.textSecondary,
          'Kết quả của bạn không bị tính.',
          coins,
        );
      case 'WITHDRAWN':
        return ResultCopy(
          'Đã rời nhóm',
          Icons.person_remove_outlined,
          DT.textSecondary,
          null,
          coins,
        );
      default:
        return ResultCopy(
          r.finalState,
          Icons.info_outline,
          DT.textSecondary,
          null,
          coins,
        );
    }
  }
}

/// V-12…V-14 Kết quả phiên. [fromHistory] = chi tiết từ Lịch sử phiên (n_10): có nút quay lại, không nút "Về trang chủ".
class ResultScreen extends ConsumerWidget {
  const ResultScreen({
    super.key,
    required this.sessionId,
    this.fromHistory = false,
  });
  final String sessionId;
  final bool fromHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(resultProvider(sessionId));
    Future<void> refresh() async {
      ref.invalidate(historyRewardTodayProvider);
      ref.invalidate(resultProvider(sessionId));
      await ref
          .read(resultProvider(sessionId).future)
          .then((_) {}, onError: (_) {});
    }

    Widget body() => r.when(
      loading: () => const SkeletonList(count: 2),
      error: (e, _) {
        final a = ApiError.from(e);
        if (a.code == 'SESSION_NOT_FINISHED') {
          return PageList(
            onRefresh: refresh,
            children: [
              SizedBox(
                height: 420,
                child: StateMessage(
                  icon: Icons.hourglass_top,
                  tone: StateTone.accent,
                  title: 'Đang chốt kết quả…',
                  body: 'Kết quả có khi phiên kết thúc. Kéo xuống để làm mới.',
                  action: 'Về trang chủ',
                  onAction: () => context.go('/home'),
                ),
              ),
            ],
          );
        }
        return ErrorState(
          error: e,
          onRetry: refresh,
          title: 'Chưa tải được kết quả.',
        );
      },
      data: (res) {
        final c = ResultCopy.of(res);
        final t = context.text.apply(
          bodyColor: OwnerStyle.ink,
          displayColor: OwnerStyle.ink,
        );
        final mode = switch (res.sessionMode) {
          'SQUAD' => 'Squad',
          'SOLO' => 'Cá nhân',
          _ => 'Chưa rõ chế độ',
        };
        return PageList(
          onRefresh: refresh,
          children: [
            Column(
              children: [
                const SizedBox(height: DT.spaceSm),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: .10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(c.icon, size: 40, color: c.color),
                ),
                const SizedBox(height: DT.spaceMd),
                Text(
                  c.label,
                  key: const Key('resultLabel'),
                  textAlign: TextAlign.center,
                  style: t.headlineLarge!.copyWith(color: OwnerStyle.ink),
                ),
                const SizedBox(height: DT.spaceSm),
                Text(
                  res.groupName ?? 'Phiên tập trung',
                  textAlign: TextAlign.center,
                  style: t.titleMedium!.copyWith(color: OwnerStyle.ink),
                ),
                const SizedBox(height: DT.spaceSm),
                _ResultBadge(label: mode, color: OwnerStyle.muted),
              ],
            ),
            AppCard(
              color: Colors.white,
              children: [
                Text('Thời gian phiên', style: t.titleMedium),
                Text(
                  '${resultFocusDuration(res.focusSeconds)} tập trung',
                  key: const Key('resultActualFocus'),
                  style: t.headlineMedium!.copyWith(
                    color: OwnerStyle.ink,
                    fontFeatures: DT.tabular,
                  ),
                ),
                _ResultLine(
                  label: 'Theo kế hoạch',
                  value: '${res.durationMin} phút',
                ),
                _ResultLine(
                  label: 'Bắt đầu theo lịch',
                  value: resultTimestamp(res.startedAt),
                ),
                if (res.joinedAt != null)
                  _ResultLine(
                    label: 'Vào phiên',
                    value: resultTimestamp(res.joinedAt),
                  ),
                if (res.finalState == 'EXITED')
                  _ResultLine(
                    label: 'Rời phiên lúc',
                    value: resultTimestamp(res.exitedAt),
                  ),
                if (res.endedAt != null)
                  _ResultLine(
                    label: 'Kết thúc tham gia lúc',
                    value: resultTimestamp(res.endedAt),
                  ),
              ],
            ),
            AppCard(
              color: Colors.white,
              children: [
                Text('Biên nhận phiên', style: t.titleMedium),
                if (c.reason != null)
                  Text(
                    c.reason!,
                    key: const Key('resultReason'),
                    style: t.bodyMedium!.copyWith(color: OwnerStyle.muted),
                  ),
                _ResultLine(
                  label: 'Chuỗi hiện tại',
                  value: '${res.streakAfter} ngày',
                ),
                if (res.streakBroken)
                  Text(
                    'Phiên này đã làm ngắt chuỗi của bạn.',
                    style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
                  ),
                Text(
                  'Chuỗi không cộng Coins',
                  style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
                ),
                const Divider(height: DT.spaceMd, color: OwnerStyle.line),
                _ResultLine(
                  label: 'Tổng nhận',
                  value: c.coins,
                  valueColor: res.coinsAwarded > 0
                      ? DT.accent
                      : OwnerStyle.muted,
                  total: true,
                ),
              ],
            ),
            if (res.exempted)
              AppCard(
                color: DT.successSoftBg,
                children: [
                  Text(
                    'Đã được miễn trừ',
                    style: t.titleMedium!.copyWith(color: DT.success),
                  ),
                  Text(
                    'Lần rời phiên của bạn đã được chủ nhóm miễn trừ.',
                    style: t.bodyMedium,
                  ),
                ],
              ),
            if (res.participants.isNotEmpty)
              AppCard(
                color: Colors.white,
                children: [
                  Text('Người trong phiên', style: t.titleMedium),
                  for (final p in sortByName([
                    ...res.participants,
                  ], (m) => '${m['display_name'] ?? ''}'))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: DT.spaceXs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p['display_name'] ?? 'Thành viên'}',
                            style: t.bodyMedium,
                          ),
                          const SizedBox(height: DT.spaceXs),
                          _ResultBadge(
                            label: participantStateText('${p['final_state']}'),
                            color: p['final_state'] == 'EXITED'
                                ? DT.warning
                                : OwnerStyle.muted,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            if (res.canExplain || res.hasExplanation)
              _ResultAction(
                key: const Key('explainButton'),
                label: res.hasExplanation ? 'Xem giải trình' : 'Gửi giải trình',
                icon: Icons.edit_note,
                onPressed: () => context.push('/explanation/$sessionId'),
              ),
            if (res.canAppeal)
              _ResultAction(
                key: const Key('appealButton'),
                label: 'Khiếu nại ghi nhầm',
                icon: Icons.gavel_outlined,
                onPressed: () => context.push('/appeal/new/$sessionId'),
              ),
            _ResultAction(
              label: 'Xem lịch sử Coins',
              onPressed: () => context.push('/coins'),
            ),
          ],
        );
      },
    );

    final base = Theme.of(context);
    final scoped = base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: OwnerStyle.ink,
        displayColor: OwnerStyle.ink,
      ),
    );
    return Theme(
      data: scoped,
      child: AppScaffold(
        backgroundColor: OwnerStyle.canvas,
        header: fromHistory
            ? const AppHeader.back(title: 'Chi tiết phiên')
            : const AppHeader.back(
                title: 'Kết quả phiên',
                leading: HeaderLeading.none,
              ),
        footer: fromHistory
            ? null
            : PrimaryButton(
                key: const Key('resultHomeButton'),
                label: 'Về trang chủ',
                background: OwnerStyle.primary,
                onPressed: () {
                  ref.invalidate(upcomingProvider);
                  ref.invalidate(meProvider);
                  context.go('/home');
                },
              ),
        body: body(),
      ),
    );
  }
}

String resultFocusDuration(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = safe ~/ 60;
  final rest = safe % 60;
  return rest == 0 ? '$minutes phút' : '$minutes phút $rest giây';
}

String resultTimestamp(DateTime? timestamp) {
  if (timestamp == null) return 'Chưa có dữ liệu';
  final local = vn(timestamp);
  return '${local.day}/${local.month}/${local.year} · ${hhmm(timestamp)}';
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(label, style: context.text.labelMedium!.copyWith(color: color)),
  );
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.total = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool total;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final t = context.text;
      final labelWidget = Text(
        label,
        style: total ? t.titleMedium : t.bodyMedium,
      );
      final valueWidget = Text(
        value,
        style: (total ? t.titleMedium : t.bodyMedium)!.copyWith(
          color: valueColor ?? OwnerStyle.muted,
          fontFeatures: DT.tabular,
        ),
      );
      if (constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelWidget,
            const SizedBox(height: DT.spaceXs),
            valueWidget,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: labelWidget),
          const SizedBox(width: DT.spaceSm),
          Expanded(child: valueWidget),
        ],
      );
    },
  );
}

class _ResultAction extends StatelessWidget {
  const _ResultAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: OwnerStyle.ink,
      side: const BorderSide(color: OwnerStyle.line),
      minimumSize: const Size.fromHeight(48),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}
