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
    final coins = r.coinsAwarded > 0
        ? '+${r.coinsAwarded} Coins${r.rewardCapReached ? ' (đã đạt trần ngày)' : ''}'
        : (r.rewardCapReached ? '0 Coins — đã đạt trần 100 Coins hôm nay' : '0 Coins');
    final who = r.forfeitTrigger;
    switch (r.finalState) {
      case 'COMPLETED':
        if (r.forfeited) {
          return ResultCopy('Hoàn thành', Icons.check_circle_outline, DT.success,
              'Phiên đã mất thưởng tập thể${who == null ? '' : ' do $who rời phiên'}. Bạn vẫn hoàn thành phiên.', coins);
        }
        return ResultCopy('Hoàn thành có thưởng', Icons.emoji_events_outlined, DT.success,
            r.rewardCapReached ? 'Trần Coins mỗi ngày là 100.' : null, coins);
      case 'EXITED':
        return ResultCopy('Bạn đã rời phiên', Icons.logout, DT.warning,
            'Cả nhóm đã nhận thông báo có tên bạn. Phiên đã mất thưởng tập thể.', coins);
      case 'LOST':
        return ResultCopy(
            'Mất kết nối',
            Icons.wifi_off,
            DT.textSecondary,
            'Bạn mất kết nối quá lâu nên phiên của bạn kết thúc sớm. Cả nhóm không bị ảnh hưởng.'
            '${r.forfeited && who != null ? ' Phiên cũng đã mất thưởng tập thể do $who rời phiên.' : ''}',
            coins);
      case 'ABSENT':
        return ResultCopy('Vắng', Icons.event_busy, DT.textSecondary,
            'Bạn chưa vào phiên trước giờ bắt đầu. Vắng không phải là rời app và không ai nhận thông báo.', coins);
      case 'VOID':
        return ResultCopy('Phiên bị hủy — không tính', Icons.block, DT.textSecondary,
            'Kết quả của bạn không bị tính.', coins);
      case 'WITHDRAWN':
        return ResultCopy('Đã rời nhóm', Icons.person_remove_outlined, DT.textSecondary, null, coins);
      default:
        return ResultCopy(r.finalState, Icons.info_outline, DT.textSecondary, null, coins);
    }
  }
}

/// V-12…V-14 Kết quả phiên. [fromHistory] = chi tiết từ Lịch sử phiên (n_10): có nút quay lại, không nút "Về trang chủ".
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.sessionId, this.fromHistory = false});
  final String sessionId;
  final bool fromHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(resultProvider(sessionId));
    Future<void> refresh() async {
      ref.invalidate(resultProvider(sessionId));
      await ref.read(resultProvider(sessionId).future).then((_) {}, onError: (_) {});
    }

    Widget body() => r.when(
          loading: () => const SkeletonList(count: 2),
          error: (e, _) {
            final a = ApiError.from(e);
            if (a.code == 'SESSION_NOT_FINISHED' || a.status == 409) {
              return PageList(onRefresh: refresh, children: [
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
              ]);
            }
            return ErrorState(error: e, onRetry: refresh, title: 'Chưa tải được kết quả.');
          },
          data: (res) {
            final c = ResultCopy.of(res);
            final t = context.text;
            final tint = c.color == DT.success
                ? DT.successSoftBg
                : c.color == DT.warning
                    ? DT.warningSoftBg
                    : DT.card;
            return PageList(onRefresh: refresh, children: [
              Column(children: [
                const SizedBox(height: DT.spaceSm),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: tint, shape: BoxShape.circle, boxShadow: tint == DT.card ? DT.cardShadow : null),
                  child: Icon(c.icon, size: 40, color: c.color),
                ),
                const SizedBox(height: DT.spaceMd),
                Text(c.label, key: const Key('resultLabel'), textAlign: TextAlign.center, style: t.headlineLarge),
                const SizedBox(height: DT.spaceXs),
                Text('${res.groupName ?? ''} · ${ddmm(res.startedAt)} · ${res.durationMin} phút',
                    textAlign: TextAlign.center, style: t.bodyMedium!.copyWith(color: DT.textSecondary)),
                if (c.reason != null) ...[
                  const SizedBox(height: DT.spaceSm),
                  Text(c.reason!,
                      key: const Key('resultReason'),
                      textAlign: TextAlign.center,
                      style: t.bodyMedium!.copyWith(color: DT.textSecondary)),
                ],
              ]),
              AppCard(children: [
                Text('Biên nhận phiên', style: t.titleMedium),
                ReceiptRow(label: 'Thời gian tập trung', value: '${res.focusSeconds ~/ 60} phút'),
                ReceiptRow(
                  label: res.streakBroken ? 'Chuỗi bị ngắt' : 'Chuỗi: ${res.streakAfter} ngày',
                  value: res.streakBroken ? 'còn 0 ngày' : 'không cộng Coins',
                  valueColor: DT.textSecondary,
                ),
                ReceiptRow(
                  label: 'Tổng nhận',
                  value: c.coins,
                  total: true,
                  valueColor: res.coinsAwarded > 0 ? DT.accent : DT.textSecondary,
                ),
              ]),
              if (res.exempted)
                const AppBanner(
                    tone: BannerTone.success,
                    text: 'Lần rời phiên của bạn đã được chủ nhóm miễn trừ.'),
              if (res.participants.isNotEmpty)
                AppCard(children: [
                  Text('Người trong phiên', style: t.titleMedium),
                  Text('Sắp theo tên A→Z.', style: t.bodySmall),
                  for (final p in sortByName([...res.participants], (m) => '${m['display_name']}'))
                    ReceiptRow(
                      label: '${p['display_name']}',
                      value: participantStateText('${p['final_state']}'),
                      valueColor: p['final_state'] == 'EXITED' ? DT.warning : DT.textSecondary,
                    ),
                ]),
              if (res.canExplain)
                SecondaryButton(
                    key: const Key('explainButton'),
                    label: 'Gửi giải trình',
                    icon: Icons.edit_note,
                    onPressed: () => context.push('/explanation/$sessionId')),
              if (res.canAppeal)
                SecondaryButton(
                    key: const Key('appealButton'),
                    label: 'Khiếu nại ghi nhầm',
                    icon: Icons.gavel_outlined,
                    onPressed: () => context.push('/appeal/new/$sessionId')),
              SecondaryButton(label: 'Xem lịch sử Coins', onPressed: () => context.push('/coins')),
            ]);
          },
        );

    if (fromHistory) {
      return AppScaffold(header: const AppHeader.back(title: 'Chi tiết phiên'), body: body());
    }
    return AppScaffold(
      header: const AppHeader.back(title: 'Kết quả phiên', leading: HeaderLeading.none),
      footer: PrimaryButton(
        label: 'Về trang chủ',
        onPressed: () {
          ref.invalidate(upcomingProvider);
          ref.invalidate(meProvider);
          context.go('/home');
        },
      ),
      body: body(),
    );
  }
}
