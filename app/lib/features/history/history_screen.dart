import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/models_ext.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../session/result_screen.dart';

/// Nhãn ngắn của một mục lịch sử (n_10).
String historyLabel(MySessionResult r) => switch (r.finalState) {
      'COMPLETED' => r.forfeited ? 'Hoàn thành · phiên mất thưởng do có người rời' : 'Hoàn thành có thưởng',
      'EXITED' => 'Bạn đã rời phiên',
      'LOST' => 'Mất kết nối quá hạn',
      'ABSENT' => 'Vắng',
      'VOID' => 'Phiên bị hủy (sự cố hệ thống)',
      'WITHDRAWN' => 'Đã rời nhóm',
      _ => r.finalState,
    };

/// V-17 Lịch sử phiên của tôi (US-03.14). Mockup: `n_10_l_ch_s_phi_n`.
/// Chỉ dữ liệu của chính tôi (có Coins của tôi). Không xếp hạng, không so với người khác.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _month = false;

  Future<void> _refresh() async {
    ref.invalidate(historyProvider);
    await ref.read(historyProvider.future).then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final h = ref.watch(historyProvider);
    final t = context.text;
    return AppScaffold(
      header: const AppHeader.back(title: 'Lịch sử phiên của tôi'),
      body: AsyncBody<HistoryPage>(
        value: h,
        onRetry: _refresh,
        errorTitle: 'Chưa tải được lịch sử phiên.',
        builder: (page) {
          final now = vn(DateTime.now().toUtc());
          final today = DateTime(now.year, now.month, now.day);
          final from = _month ? DateTime(now.year, now.month) : today.subtract(Duration(days: now.weekday - 1));
          final inRange = page.items.where((r) {
            final s = r.startedAt == null ? null : vn(r.startedAt!);
            return s != null && !DateTime(s.year, s.month, s.day).isBefore(from);
          }).toList();
          final minutes = inRange.fold<int>(0, (a, r) => a + r.focusSeconds ~/ 60);
          final done = inRange.where((r) => r.finalState == 'COMPLETED').length;
          final counted = inRange.where((r) => r.finalState != 'VOID').length;

          // Nhóm theo ngày (giờ VN), mới nhất trước.
          final groups = <String, List<MySessionResult>>{};
          for (final r in page.items) {
            groups.putIfAbsent(ddmm(r.startedAt), () => []).add(r);
          }
          return PageList(onRefresh: _refresh, children: [
            PillToggle<bool>(
              value: _month,
              onChanged: (v) => setState(() => _month = v),
              options: const [PillOption(false, 'Tuần này'), PillOption(true, 'Tháng này')],
            ),
            StatRow(children: [
              StatTile(label: 'Phút tập trung', value: '$minutes'),
              StatTile(label: 'Phiên hoàn thành', value: '$done / $counted'),
            ]),
            if (page.items.isEmpty)
              const SizedBox(
                height: 300,
                child: StateMessage(
                  icon: Icons.history,
                  title: 'Chưa có phiên nào',
                  body: 'Phiên đã kết thúc của bạn sẽ hiện ở đây.',
                ),
              ),
            for (final e in groups.entries) ...[
              SectionHeader(dayLabel(e.value.first.startedAt), small: true),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: DT.spaceMd, vertical: DT.spaceXs),
                children: [
                  for (var i = 0; i < e.value.length; i++) _HistoryRow(r: e.value[i], divider: i < e.value.length - 1),
                ],
              ),
            ],
            if (page.nextCursor != null) Text('Đang hiện 50 phiên gần nhất.', style: t.bodySmall),
          ]);
        },
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.r, required this.divider});
  final MySessionResult r;
  final bool divider;
  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = ResultCopy.of(r);
    final end = r.startedAt?.add(Duration(minutes: r.durationMin));
    return ListRow(
      divider: divider,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.color == DT.success
              ? DT.successSoftBg
              : c.color == DT.warning
                  ? DT.warningSoftBg
                  : DT.surfaceHigh,
        ),
        child: Icon(c.icon, size: 20, color: c.color),
      ),
      title: r.groupName ?? 'Phiên tập trung',
      subtitle: '${hhmm(r.startedAt)}–${hhmm(end)} · ${r.durationMin} phút\n${historyLabel(r)}',
      trailing: Text(
        r.finalState == 'VOID' ? '—' : (r.coinsAwarded > 0 ? '+${r.coinsAwarded}' : '0'),
        style: t.titleMedium!.copyWith(
            color: r.coinsAwarded > 0 ? DT.accent : DT.textSecondary, fontFeatures: DT.tabular),
      ),
      onTap: () => context.push('/history/${r.sessionId}'),
    );
  }
}
