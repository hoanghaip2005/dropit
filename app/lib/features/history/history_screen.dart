import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Nhãn ngắn của một mục lịch sử (n_10).
String historyLabel(MySessionResult r) => switch (r.finalState) {
  'COMPLETED' =>
    r.forfeited
        ? 'Hoàn thành · phiên mất thưởng do có người rời'
        : 'Hoàn thành có thưởng',
  'EXITED' => 'Rời sớm',
  'LOST' => 'Mất kết nối quá hạn',
  'ABSENT' => 'Vắng',
  'VOID' => 'Phiên bị hủy (sự cố hệ thống)',
  'WITHDRAWN' => 'Đã rời nhóm',
  _ => r.finalState,
};

enum HistoryPeriod { day, week, month }

/// One bounded period, shared by the rows and their statistics. Null dates and
/// future records cannot be assigned to the current period.
List<MySessionResult> historyInPeriod(
  List<MySessionResult> items, {
  required DateTime now,
  bool month = false,
  HistoryPeriod? period,
  DateTime? selectedDay,
}) {
  final local = vn(now);
  final chosen = selectedDay ?? DateTime(local.year, local.month, local.day);
  final day = DateTime(chosen.year, chosen.month, chosen.day);
  final scope = period ?? (month ? HistoryPeriod.month : HistoryPeriod.week);
  final from = switch (scope) {
    HistoryPeriod.day => day,
    HistoryPeriod.week => day.subtract(Duration(days: day.weekday - 1)),
    HistoryPeriod.month => DateTime(day.year, day.month),
  };
  final until = switch (scope) {
    HistoryPeriod.day => day.add(const Duration(days: 1)),
    HistoryPeriod.week => from.add(const Duration(days: 7)),
    HistoryPeriod.month => DateTime(day.year, day.month + 1),
  };
  return items.where((r) {
    final start = r.startedAt;
    if (start == null || start.toUtc().isAfter(now.toUtc())) return false;
    final d = vn(start);
    final date = DateTime(d.year, d.month, d.day);
    return !date.isBefore(from) && date.isBefore(until);
  }).toList()..sort((a, b) => b.startedAt!.compareTo(a.startedAt!));
}

/// Full local calendar date, avoiding collisions between different years.
DateTime historyDay(DateTime start) {
  final d = vn(start);
  return DateTime(d.year, d.month, d.day);
}

/// V-17 Lịch sử phiên của tôi (US-03.14). Mockup: `n_10_l_ch_s_phi_n`.
/// Chỉ dữ liệu của chính tôi (có Coins của tôi). Không xếp hạng, không so với người khác.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

DateTime historyNextMidnight(DateTime now) {
  final local = vn(now);
  return DateTime.utc(
    local.year,
    local.month,
    local.day + 1,
  ).subtract(const Duration(hours: 7));
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;
  late DateTime _observedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _observedDay = historyDay(DateTime.now().toUtc());
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now().toUtc();
    _midnightTimer = Timer(
      historyNextMidnight(now).difference(now) +
          const Duration(milliseconds: 100),
      () {
        _checkDay();
        _scheduleMidnight();
      },
    );
  }

  void _checkDay() {
    final today = historyDay(DateTime.now().toUtc());
    if (today == _observedDay || !mounted) return;
    _observedDay = today;
    ref.invalidate(historyRewardTodayProvider);
    ref.invalidate(historyPeriodProvider(_rangeKey()));
    setState(
      () {},
    ); // Default today follows the clock; explicit selectedDay stays.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDay();
      _scheduleMidnight();
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  HistoryPeriod _period = HistoryPeriod.week;
  DateTime? _selectedDay;

  Future<void> _pickDate() async {
    final local = vn(DateTime.now().toUtc());
    final today = DateTime(local.year, local.month, local.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay ?? today,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Chọn ngày xem lịch sử',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: OwnerStyle.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: OwnerStyle.ink,
              onSurfaceVariant: OwnerStyle.muted,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              headerBackgroundColor: OwnerStyle.canvas,
              headerForegroundColor: OwnerStyle.ink,
              dayBackgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? OwnerStyle.primary
                    : null,
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.selected) ? Colors.white : null,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) setState(() => _selectedDay = picked);
  }

  (String, String) _rangeKey() {
    final local = vn(DateTime.now().toUtc());
    final day = _selectedDay ?? DateTime(local.year, local.month, local.day);
    final from = switch (_period) {
      HistoryPeriod.day => DateTime.utc(day.year, day.month, day.day),
      HistoryPeriod.week => DateTime.utc(
        day.year,
        day.month,
        day.day,
      ).subtract(Duration(days: day.weekday - 1)),
      HistoryPeriod.month => DateTime.utc(day.year, day.month),
    };
    final until = switch (_period) {
      HistoryPeriod.day => from.add(const Duration(days: 1)),
      HistoryPeriod.week => from.add(const Duration(days: 7)),
      HistoryPeriod.month => DateTime.utc(day.year, day.month + 1),
    };
    return (
      from.subtract(const Duration(hours: 7)).toIso8601String(),
      until.subtract(const Duration(hours: 7)).toIso8601String(),
    );
  }

  Future<void> _refresh() async {
    final provider = historyPeriodProvider(_rangeKey());
    ref.invalidate(provider);
    ref.invalidate(historyRewardTodayProvider);
    await ref.read(provider.future).then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final h = ref.watch(historyPeriodProvider(_rangeKey()));
    final t = context.text;
    final controls = <Widget>[
      _PeriodSelector(
        period: _period,
        onChanged: (v) => setState(() => _period = v),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('historyDatePicker'),
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(
            _selectedDay == null
                ? 'Hôm nay · Chọn ngày'
                : '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year} · Đổi ngày',
          ),
          style: TextButton.styleFrom(
            foregroundColor: OwnerStyle.ink,
            backgroundColor: Colors.white,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.pill),
            ),
          ),
        ),
      ),
      const _TodayRewardBanner(),
    ];
    // Reuse neutral palette tokens without enabling owner-specific widgets.
    final scopedTheme = Theme.of(context).copyWith(
      textTheme: t.apply(
        bodyColor: OwnerStyle.ink,
        displayColor: OwnerStyle.ink,
      ),
    );
    return Theme(
      data: scopedTheme,
      child: AppScaffold(
        backgroundColor: OwnerStyle.canvas,
        header: const AppHeader.back(title: 'Lịch sử phiên của tôi'),
        body: h.when(
          loading: () => PageList(
            children: [
              ...controls,
              const SizedBox(height: 300, child: SkeletonList()),
            ],
          ),
          error: (error, stack) => PageList(
            children: [
              ...controls,
              SizedBox(
                height: 420,
                child: ErrorState(
                  error: error,
                  onRetry: _refresh,
                  title: 'Chưa tải được lịch sử phiên.',
                ),
              ),
            ],
          ),
          data: (page) {
            final inRange = historyInPeriod(
              page.items,
              now: DateTime.now().toUtc(),
              period: _period,
              selectedDay: _selectedDay,
            );
            final minutes = inRange.fold<int>(
              0,
              (a, r) => a + r.focusSeconds ~/ 60,
            );
            final done = inRange
                .where((r) => r.finalState == 'COMPLETED')
                .length;
            final counted = inRange.where((r) => r.finalState != 'VOID').length;
            final groups = <DateTime, List<MySessionResult>>{};
            for (final r in inRange) {
              groups.putIfAbsent(historyDay(r.startedAt!), () => []).add(r);
            }
            return PageList(
              onRefresh: _refresh,
              children: [
                ...controls,
                if (page.nextCursor != null)
                  Text(
                    'Thống kê và danh sách chỉ tính các phiên đã tải trong kỳ. Còn lịch sử chưa tải.',
                    key: const Key('historyPartialNotice'),
                    style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
                  ),
                StatRow(
                  children: [
                    _HistoryStat(label: 'Phút tập trung', value: '$minutes'),
                    _HistoryStat(
                      label: 'Phiên hoàn thành',
                      value: '$done / $counted',
                    ),
                  ],
                ),
                if (inRange.isEmpty)
                  const SizedBox(
                    height: 300,
                    child: StateMessage(
                      icon: Icons.history,
                      title: 'Chưa có phiên nào',
                      body: 'Không có phiên đã tải trong khoảng thời gian này.',
                    ),
                  ),
                for (final e in groups.entries) ...[
                  Text(
                    dayLabel(e.value.first.startedAt),
                    style: t.labelLarge!.copyWith(color: OwnerStyle.muted),
                  ),
                  AppCard(
                    color: Colors.white,
                    gap: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DT.spaceMd,
                      vertical: DT.spaceXs,
                    ),
                    children: [
                      for (var i = 0; i < e.value.length; i++)
                        _HistoryRow(
                          r: e.value[i],
                          divider: i < e.value.length - 1,
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
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
    final stateColor = switch (r.finalState) {
      'COMPLETED' => r.forfeited ? DT.accent : DT.success,
      'EXITED' => DT.warning,
      _ => OwnerStyle.muted,
    };
    final modeLabel = switch (r.sessionMode) {
      'SQUAD' => 'Squad',
      'SOLO' => 'Cá nhân',
      _ => 'Chưa rõ chế độ',
    };
    return Column(
      children: [
        InkWell(
          onTap: () => context.push('/history/${r.sessionId}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: DT.spaceMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.groupName ?? 'Phiên tập trung',
                        style: t.titleMedium!.copyWith(color: OwnerStyle.ink),
                      ),
                      const SizedBox(height: DT.spaceXs),
                      Text(
                        'Bắt đầu ${hhmm(r.startedAt)} · Kế hoạch ${r.durationMin} phút',
                        style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
                      ),
                      const SizedBox(height: DT.spaceXs),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _HistoryBadge(
                            label: modeLabel,
                            color: OwnerStyle.muted,
                          ),
                          _HistoryBadge(
                            label:
                                '${historyFocusDuration(r.focusSeconds)} tập trung',
                            color: OwnerStyle.ink,
                          ),
                          _HistoryBadge(
                            label: historyLabel(r),
                            color: stateColor,
                          ),
                        ],
                      ),
                      if (r.finalState == 'COMPLETED' && r.endedAt != null) ...[
                        const SizedBox(height: DT.spaceXs),
                        Text(
                          'Hoàn thành lúc ${hhmm(r.endedAt)}',
                          style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
                        ),
                      ],
                      if (r.finalState == 'EXITED') ...[
                        const SizedBox(height: DT.spaceXs),
                        Text(
                          r.exitedAt == null
                              ? 'Chưa có thời điểm rời phiên'
                              : 'Rời lúc ${hhmm(r.exitedAt)}',
                          style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: DT.spaceSm),
                Text(
                  r.finalState == 'VOID'
                      ? '—'
                      : (r.coinsAwarded > 0 ? '+${r.coinsAwarded}' : '0'),
                  style: t.titleMedium!.copyWith(
                    color: r.coinsAwarded > 0 ? DT.accent : OwnerStyle.muted,
                    fontFeatures: DT.tabular,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (divider) const Divider(height: 1, color: OwnerStyle.line),
      ],
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => AppCard(
    color: Colors.white,
    children: [
      Text(
        label,
        style: context.text.bodySmall!.copyWith(
          color: OwnerStyle.muted,
          fontSize: 12,
        ),
      ),
      Text(
        value,
        style: context.text.headlineMedium!.copyWith(
          color: OwnerStyle.ink,
          fontFeatures: DT.tabular,
        ),
      ),
    ],
  );
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period, required this.onChanged});
  final HistoryPeriod period;
  final ValueChanged<HistoryPeriod> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(DT.pill),
    ),
    child: Row(
      children: [
        for (final value in HistoryPeriod.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Semantics(
                selected: period == value,
                button: true,
                child: Material(
                  color: period == value
                      ? OwnerStyle.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DT.pill),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(DT.pill),
                    onTap: () => onChanged(value),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Text(
                            switch (value) {
                              HistoryPeriod.day => 'Ngày',
                              HistoryPeriod.week => 'Tuần',
                              HistoryPeriod.month => 'Tháng',
                            },
                            style: context.text.labelLarge!.copyWith(
                              color: period == value
                                  ? Colors.white
                                  : OwnerStyle.muted,
                              fontWeight: period == value
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

String historyFocusDuration(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = safe ~/ 60;
  final rest = safe % 60;
  return rest == 0 ? '$minutes phút' : '$minutes phút $rest giây';
}

class _HistoryBadge extends StatelessWidget {
  const _HistoryBadge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(label, style: context.text.labelSmall!.copyWith(color: color)),
  );
}

class _TodayRewardBanner extends ConsumerWidget {
  const _TodayRewardBanner();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reward = ref.watch(historyRewardTodayProvider);
    return AppCard(
      color: DT.accentSoftBg,
      child: reward.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Đang tải phần thưởng hôm nay…',
            key: Key('historyRewardLoading'),
          ),
        ),
        error: (error, stack) => Row(
          children: [
            const Expanded(
              child: Text(
                'Chưa tải được phần thưởng hôm nay.',
                key: Key('historyRewardError'),
              ),
            ),
            IconButton(
              tooltip: 'Thử tải phần thưởng lại',
              onPressed: () => ref.invalidate(historyRewardTodayProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        data: (summary) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.toll_outlined, color: DT.accent, size: 22),
                const SizedBox(width: DT.spaceSm),
                Expanded(
                  child: Text(
                    'Phần thưởng hôm nay',
                    style: context.text.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DT.spaceSm),
            Text(
              '${summary.coinsAwarded} / ${summary.dailyCap} Coins',
              key: const Key('historyRewardValue'),
              style: context.text.headlineMedium!.copyWith(color: DT.accent),
            ),
            if (summary.dailyCap > 0) ...[
              const SizedBox(height: DT.spaceSm),
              ClipRRect(
                borderRadius: BorderRadius.circular(DT.pill),
                child: LinearProgressIndicator(
                  value: (summary.coinsAwarded / summary.dailyCap).clamp(
                    0.0,
                    1.0,
                  ),
                  minHeight: 6,
                  color: DT.accent,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
            const SizedBox(height: DT.spaceXs),
            Text(
              'Ngày ${summary.rewardDate} · Không phụ thuộc kỳ lịch sử đang chọn',
              style: context.text.bodySmall!.copyWith(color: OwnerStyle.muted),
            ),
          ],
        ),
      ),
    );
  }
}
