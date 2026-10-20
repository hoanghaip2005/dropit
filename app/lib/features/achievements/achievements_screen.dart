import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/models_ext.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Danh mục huy hiệu (design/schema.sql `badges`, BR-52). Chỉ ghi nhận, không cộng Coins.
class BadgeDef {
  const BadgeDef(this.code, this.metric, this.threshold, this.name, this.desc);
  final String code;
  final String metric; // STREAK_DAYS / REWARDED_SESSIONS / FOCUS_HOURS
  final int threshold;
  final String name;
  final String desc;

  IconData get icon => switch (metric) {
        'STREAK_DAYS' => Icons.local_fire_department,
        'REWARDED_SESSIONS' => Icons.task_alt,
        _ => Icons.bedtime_outlined,
      };
}

const badgeCatalog = [
  BadgeDef('STREAK_3', 'STREAK_DAYS', 3, 'Chuỗi 3 ngày', 'Chuỗi đạt 3 ngày.'),
  BadgeDef('STREAK_7', 'STREAK_DAYS', 7, 'Chuỗi 7 ngày', 'Chuỗi đạt 7 ngày.'),
  BadgeDef('STREAK_14', 'STREAK_DAYS', 14, 'Chuỗi 14 ngày', 'Chuỗi đạt 14 ngày.'),
  BadgeDef('STREAK_30', 'STREAK_DAYS', 30, 'Chuỗi 30 ngày', 'Chuỗi đạt 30 ngày.'),
  BadgeDef('STREAK_60', 'STREAK_DAYS', 60, 'Chuỗi 60 ngày', 'Chuỗi đạt 60 ngày.'),
  BadgeDef('STREAK_100', 'STREAK_DAYS', 100, 'Chuỗi 100 ngày', 'Chuỗi đạt 100 ngày.'),
  BadgeDef('SESS_10', 'REWARDED_SESSIONS', 10, '10 phiên có thưởng', 'Hoàn thành có thưởng 10 phiên.'),
  BadgeDef('SESS_50', 'REWARDED_SESSIONS', 50, '50 phiên có thưởng', 'Hoàn thành có thưởng 50 phiên.'),
  BadgeDef('SESS_100', 'REWARDED_SESSIONS', 100, '100 phiên có thưởng', 'Hoàn thành có thưởng 100 phiên.'),
  BadgeDef('SESS_500', 'REWARDED_SESSIONS', 500, '500 phiên có thưởng', 'Hoàn thành có thưởng 500 phiên.'),
  BadgeDef('HOURS_10', 'FOCUS_HOURS', 10, '10 giờ tập trung', 'Giờ tập trung (huy hiệu) đạt 10 giờ.'),
  BadgeDef('HOURS_50', 'FOCUS_HOURS', 50, '50 giờ tập trung', 'Giờ tập trung (huy hiệu) đạt 50 giờ.'),
  BadgeDef('HOURS_100', 'FOCUS_HOURS', 100, '100 giờ tập trung', 'Giờ tập trung (huy hiệu) đạt 100 giờ.'),
];

String badgeName(String code) => badgeCatalog.where((b) => b.code == code).firstOrNull?.name ?? code;

String monthKey(DateTime d) => '${d.year}-${two(d.month)}';

/// V-26/V-27/V-28 Thành tích. Mockup: `s_06_huy_hi_u_v_th_nh_t_ch`.
/// Chuỗi hiện tại/dài nhất, lịch điểm danh tháng, huy hiệu, công tắc hiện trên hồ sơ (mặc định tắt).
/// Không xếp hạng, không so với nhóm (D-03).
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});
  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  late DateTime _month = () {
    final n = vn(DateTime.now().toUtc());
    return DateTime(n.year, n.month);
  }();
  String _filter = 'ALL';
  bool _busy = false;

  Future<void> _refresh() async {
    ref.invalidate(achievementsProvider);
    ref.invalidate(attendanceProvider(monthKey(_month)));
    await ref.read(achievementsProvider.future).then((_) {}, onError: (_) {});
  }

  Future<void> _toggleVisible(Achievements a, bool on) async {
    if (on) {
      final ok = await showConfirmDialog(
        context,
        title: 'Hiện chuỗi và huy hiệu?',
        message: 'Khi bật, thành viên cùng nhóm sẽ thấy chuỗi và huy hiệu của bạn trên hồ sơ. '
            'Chủ nhóm không thấy chuỗi. Bạn tắt lại được bất cứ lúc nào.',
        confirmLabel: 'Bật hiện',
        confirmKey: const Key('showStreakConfirm'),
      );
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(apiProvider);
      // Trưng bày tối đa 3 huy hiệu (BR-99): bật → 3 huy hiệu mới nhất; tắt → ẩn hết.
      final sorted = [...a.badges]..sort((x, y) => (y.earnedAt ?? DateTime(0)).compareTo(x.earnedAt ?? DateTime(0)));
      for (var i = 0; i < sorted.length; i++) {
        final want = on && i < 3;
        if (sorted[i].visible != want) await api.setBadgeVisible(sorted[i].code, want);
      }
      // Chuỗi trên hồ sơ công khai (users.show_streak) — chủ nhóm vẫn không thấy (BR-53b).
      if (a.showStreak != on) await api.setShowStreak(on);
      ref.invalidate(achievementsProvider);
    } catch (e) {
      if (mounted) showSnack(context, ApiError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(achievementsProvider);
    final att = ref.watch(attendanceProvider(monthKey(_month)));
    final t = context.text;
    return AppScaffold(
      header: const AppHeader.back(title: 'Huy hiệu và thành tích'),
      body: AsyncBody<Achievements>(
        value: a,
        onRetry: _refresh,
        errorTitle: 'Chưa tải được thành tích.',
        builder: (d) {
          final earned = {for (final b in d.badges) b.code: b};
          final anyVisible = d.showStreak || d.badges.any((b) => b.visible);
          final metric = {for (final p in d.progress) p.metric: p.value}..putIfAbsent('STREAK_DAYS', () => d.longestStreak);
          final shown = badgeCatalog
              .where((b) => _filter == 'ALL' || b.metric == _filter)
              .toList()
            ..sort((x, y) => (earned.containsKey(x.code) ? 0 : 1).compareTo(earned.containsKey(y.code) ? 0 : 1));
          final nextStreak = badgeCatalog
              .where((b) => b.metric == 'STREAK_DAYS' && !earned.containsKey(b.code))
              .firstOrNull;
          return PageList(onRefresh: _refresh, children: [
            // Thẻ chuỗi (V-26).
            AppCard(children: [
              Row(children: [
                const Icon(Icons.local_fire_department, color: DT.accent),
                const SizedBox(width: DT.spaceSm),
                Expanded(child: Text('Chuỗi hiện tại', style: t.labelLarge!.copyWith(color: DT.textSecondary))),
                const StatusBadge('Chỉ bạn thấy'),
              ]),
              Text('${d.currentStreak} ngày',
                  key: const Key('currentStreak'), style: t.displayMedium!.copyWith(fontFeatures: DT.tabular)),
              Text('Chuỗi dài nhất: ${d.longestStreak} ngày', key: const Key('longestStreak'), style: t.bodyMedium),
              // AC-05.04.2: hôm nay chưa có phiên đạt → "chưa cộng", không phải "đã mất"
              StatusBadge(
                d.streakCountedToday ? 'Hôm nay đã cộng chuỗi' : 'Hôm nay chưa cộng chuỗi',
                key: const Key('streakToday'),
                tone: d.streakCountedToday ? BadgeTone.success : BadgeTone.neutral,
                icon: d.streakCountedToday ? Icons.check : Icons.schedule,
              ),
              const Divider(height: DT.spaceLg),
              if (nextStreak == null)
                Text('Bạn đã đạt mọi mốc chuỗi.', style: t.bodyMedium)
              else ...[
                Text(
                  'Huy hiệu ${nextStreak.name} — còn ${(nextStreak.threshold - d.longestStreak).clamp(0, 999)} ngày',
                  style: t.titleSmall,
                ),
                ProgressBar(value: d.longestStreak / nextStreak.threshold),
              ],
              Text(
                'Chuỗi +1 khi bạn hoàn thành có thưởng ít nhất một phiên trong ngày. Chuỗi về 0 khi bạn rời app, '
                'hoặc khi phiên bạn tham gia mất thưởng tập thể. Vắng hoặc ngày không có lịch không làm mất chuỗi. '
                'Chuỗi không cộng Coins.',
                style: t.bodySmall,
              ),
            ]),
            // Công tắc hiện trên hồ sơ (V-28, mặc định tắt, BR-99/NFR-P17).
            AppCard(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Hiện chuỗi và huy hiệu trên hồ sơ', style: t.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Mặc định tắt. Khi bật, thành viên cùng nhóm sẽ thấy chuỗi và huy hiệu của bạn. '
                      'Bạn tắt lại được bất cứ lúc nào.',
                      style: t.bodySmall,
                    ),
                  ]),
                ),
                Switch(
                  key: const Key('showStreakSwitch'),
                  value: anyVisible,
                  onChanged: _busy ? null : (v) => _toggleVisible(d, v),
                ),
              ]),
              Text(anyVisible ? 'Đang: Hiện với nhóm' : 'Đang: Ẩn với nhóm',
                  style: t.labelMedium!.copyWith(color: anyVisible ? DT.accent : DT.textSecondary)),
            ]),
            // Lịch điểm danh tháng.
            AppCard(children: [
              Row(children: [
                Expanded(child: Text('Điểm danh tháng ${two(_month.month)}/${_month.year}', style: t.titleMedium)),
                CircleIconButton(
                  icon: Icons.chevron_left,
                  size: 32,
                  tooltip: 'Tháng trước',
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                ),
                const SizedBox(width: DT.spaceSm),
                CircleIconButton(
                  icon: Icons.chevron_right,
                  size: 32,
                  tooltip: 'Tháng sau',
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                ),
              ]),
              att.when(
                skipLoadingOnRefresh: true,
                loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => ErrorState(
                    error: e,
                    onRetry: () => ref.invalidate(attendanceProvider(monthKey(_month))),
                    title: 'Chưa tải được điểm danh.'),
                data: (m) => AttendanceCalendar(month: _month, data: m),
              ),
              Text('Điểm danh khi bạn vào phòng chờ trước giờ bắt đầu và có kết quả phiên.', style: t.bodySmall),
            ]),
            // Huy hiệu (V-27/V-28).
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Huy hiệu của tôi', style: t.headlineSmall),
              Text('Đạt ${d.badges.length}/${badgeCatalog.length} huy hiệu. Huy hiệu chỉ để ghi nhận, không cộng Coins.',
                  style: t.bodySmall),
            ]),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(children: [
                for (final (code, label) in const [
                  ('ALL', 'Tất cả'),
                  ('STREAK_DAYS', 'Chuỗi'),
                  ('REWARDED_SESSIONS', 'Phiên có thưởng'),
                  ('FOCUS_HOURS', 'Giờ tập trung'),
                ]) ...[
                  FilterChipPill(label: label, selected: _filter == code, onTap: () => setState(() => _filter = code)),
                  const SizedBox(width: DT.spaceSm),
                ],
              ]),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: DT.spaceMd,
              crossAxisSpacing: DT.spaceMd,
              childAspectRatio: 0.92,
              children: [
                for (final b in shown)
                  _BadgeTile(def: b, earned: earned[b.code], value: metric[b.metric]),
              ],
            ),
          ]);
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.def, required this.earned, required this.value});
  final BadgeDef def;
  final EarnedBadge? earned;

  /// Số đo hiện tại của loại huy hiệu (chuỗi dài nhất / số phiên có thưởng / số giờ) — null nếu chưa có.
  final int? value;
  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final got = earned != null;
    final progress = value == null ? null : (value! / def.threshold).clamp(0.0, 1.0);
    return Semantics(
      label: '${def.name}${got ? ', đã đạt' : ', chưa đạt'}',
      child: AppCard(
        padding: const EdgeInsets.all(12),
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: got ? DT.accentSoftBg : DT.surfaceHigh, shape: BoxShape.circle),
              child: Icon(def.icon, color: got ? DT.accent : DT.textSecondary),
            ),
            const Spacer(),
            Icon(got ? Icons.check_circle : Icons.lock_outline, size: 18, color: got ? DT.success : DT.textSecondary),
          ]),
          Text(def.name, maxLines: 2, style: t.titleSmall),
          Text(def.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall),
          const Spacer(),
          if (got) ...[
            Text('Đạt ${ddmm(earned!.earnedAt).substring(0, 5)}', style: t.labelMedium!.copyWith(color: DT.success)),
            if (earned!.visible) Text('Đang hiện trên hồ sơ', style: t.labelSmall!.copyWith(color: DT.accent)),
          ] else if (progress != null) ...[
            Text('${value!.clamp(0, def.threshold)}/${def.threshold}', style: t.labelMedium),
            ProgressBar(value: progress),
          ] else
            Text('Chưa đạt', style: t.labelMedium!.copyWith(color: DT.textSecondary)),
        ],
      ),
    );
  }
}

/// Lịch tháng (Thứ Hai đầu tuần): ngày điểm danh = chấm tròn cam đặc.
class AttendanceCalendar extends StatelessWidget {
  const AttendanceCalendar({super.key, required this.month, required this.data});
  final DateTime month;
  final AttendanceMonth data;
  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final todayVn = vn(DateTime.now().toUtc());
    final cells = <Widget>[
      for (final w in const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'])
        Center(child: Text(w, style: t.labelSmall!.copyWith(color: DT.textSecondary))),
      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
      for (var d = 1; d <= days; d++)
        Builder(builder: (context) {
          final key = '${month.year}-${two(month.month)}-${two(d)}';
          final on = data.attended.contains(key);
          final isToday = todayVn.year == month.year && todayVn.month == month.month && todayVn.day == d;
          return Semantics(
            label: 'Ngày $d${on ? ', đã điểm danh' : ''}',
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? DT.accent : Colors.transparent,
                  border: isToday && !on ? Border.all(color: DT.primary) : null,
                ),
                child: Text('$d',
                    style: t.labelMedium!.copyWith(
                        color: on ? Colors.white : DT.textPrimary, fontFeatures: DT.tabular)),
              ),
            ),
          );
        }),
    ];
    return Column(children: [
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.1,
        children: cells,
      ),
      const SizedBox(height: DT.spaceSm),
      Row(children: [
        Container(width: 12, height: 12, decoration: const BoxDecoration(color: DT.accent, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('Đã điểm danh: ${data.attended.length} ngày', key: const Key('attendedCount'), style: t.bodySmall),
      ]),
    ]);
  }
}
