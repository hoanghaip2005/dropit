import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/models_ext.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// "2026-09" → "09/2026".
String monthLabel(String m) {
  final p = m.split('-');
  return p.length == 2 ? '${p[1]}/${p[0]}' : m;
}

String pct(num? v) => v == null ? '—' : '${v.round()}%';

/// "Báo cáo đầu tiên sẽ có vào 01/mm." (ngày 1 tháng sau).
String firstReportText() {
  final n = vn(DateTime.now().toUtc());
  final next = DateTime(n.year, n.month + 1);
  return 'Báo cáo đầu tiên sẽ có vào 01/${two(next.month)}/${next.year}.';
}

/// Tab "Báo cáo" của chủ nhóm: chọn một nhóm (không có "Mọi nhóm" — D-21) rồi xem báo cáo.
class OwnerReportsHubScreen extends ConsumerStatefulWidget {
  const OwnerReportsHubScreen({super.key});
  @override
  ConsumerState<OwnerReportsHubScreen> createState() => _OwnerReportsHubScreenState();
}

class _OwnerReportsHubScreenState extends ConsumerState<OwnerReportsHubScreen> {
  String? _gid;
  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(myGroupsProvider);
    final owned = groups.value?.where((g) => g.isOwner).toList() ?? const <MyGroup>[];
    final gid = _gid ?? owned.firstOrNull?.groupId;
    if (gid != null && owned.length <= 1) return ReportScreen(groupId: gid, inShell: true);
    return AppScaffold(
      header: const AppHeader.brand(caption: 'Chủ nhóm', title: 'Báo cáo tháng', icon: Icons.analytics_outlined),
      body: AsyncBody<List<MyGroup>>(
        value: groups,
        onRetry: () => ref.invalidate(myGroupsProvider),
        builder: (_) => Column(children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: DT.margin, vertical: 6),
              children: [
                for (final g in owned) ...[
                  FilterChipPill(label: g.name, selected: g.groupId == gid, onTap: () => setState(() => _gid = g.groupId)),
                  const SizedBox(width: DT.spaceSm),
                ],
              ],
            ),
          ),
          if (gid == null)
            const Expanded(child: StateMessage(icon: Icons.groups_outlined, title: 'Bạn chưa quản lý nhóm nào'))
          else
            Expanded(child: ReportBody(key: ValueKey(gid), groupId: gid)),
        ]),
      ),
    );
  }
}

/// V-48 (chủ nhóm) / V-34 (thành viên) — cùng endpoint, server trả view theo vai trò.
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key, required this.groupId, this.inShell = false});
  final String groupId;
  final bool inShell;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(myGroupsProvider).value?.where((x) => x.groupId == groupId).firstOrNull;
    final owner = g?.isOwner ?? false;
    return AppScaffold(
      header: owner
          ? AppHeader.brand(
              caption: 'Chủ nhóm · ${g?.name ?? ''}',
              title: 'Báo cáo tháng',
              icon: Icons.analytics_outlined,
              leading: inShell ? HeaderLeading.none : HeaderLeading.back,
            )
          : AppHeader.back(title: 'Báo cáo của tôi'),
      body: ReportBody(groupId: groupId),
    );
  }
}

class ReportBody extends ConsumerStatefulWidget {
  const ReportBody({super.key, required this.groupId});
  final String groupId;
  @override
  ConsumerState<ReportBody> createState() => _ReportBodyState();
}

class _ReportBodyState extends ConsumerState<ReportBody> {
  String? _month;

  @override
  Widget build(BuildContext context) {
    final periods = ref.watch(reportPeriodsProvider(widget.groupId));
    Future<void> refresh() async {
      ref.invalidate(reportPeriodsProvider(widget.groupId));
      if (_month != null) ref.invalidate(reportProvider((widget.groupId, _month!)));
      await ref.read(reportPeriodsProvider(widget.groupId).future).then((_) {}, onError: (_) {});
    }

    return AsyncBody<List<ReportPeriod>>(
      value: periods,
      onRetry: refresh,
      errorTitle: 'Chưa tải được báo cáo.',
      builder: (list) {
        final ready = list.where((p) => p.status == 'GENERATED').toList();
        if (ready.isEmpty) {
          return PageList(onRefresh: refresh, children: [
            SizedBox(
              height: 360,
              child: StateMessage(icon: Icons.analytics_outlined, title: 'Chưa có báo cáo', body: firstReportText()),
            ),
          ]);
        }
        final month = _month ?? ready.first.month;
        final rep = ref.watch(reportProvider((widget.groupId, month)));
        return PageList(onRefresh: refresh, children: [
          if (ready.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(children: [
                for (final p in ready) ...[
                  FilterChipPill(
                      label: 'Tháng ${monthLabel(p.month)}',
                      selected: p.month == month,
                      onTap: () => setState(() => _month = p.month)),
                  const SizedBox(width: DT.spaceSm),
                ],
              ]),
            ),
          ...rep.when(
            skipLoadingOnRefresh: true,
            loading: () => [const SizedBox(height: 300, child: SkeletonList(count: 3))],
            error: (e, _) => [
              ErrorState(
                error: e,
                onRetry: () => ref.invalidate(reportProvider((widget.groupId, month))),
                title: ApiError.from(e).code == 'REPORT_NOT_READY' ? 'Báo cáo chưa sẵn sàng.' : 'Chưa tải được báo cáo.',
              ),
            ],
            data: (r) => r.isOwnerView ? ownerReport(context, r) : memberReport(context, r),
          ),
        ]);
      },
    );
  }

  /// V-48 — mockup `manager_analytics_report`. Không Coins/chuỗi; sắp tên A→Z; không xếp hạng.
  List<Widget> ownerReport(BuildContext context, GroupReport r) {
    final t = context.text;
    final tot = r.totals ?? const {};
    return [
      Text('Báo cáo tháng ${monthLabel(r.month)}', key: const Key('reportTitle'), style: t.headlineMedium),
      PurposeCard(purpose: r.purpose, generatedAt: ddmm(r.generatedAt)),
      StatRow(children: [
        StatTile(label: 'Phiên đã diễn ra', value: '${tot['sessions_held'] ?? 0}'),
        StatTile(
          label: 'Phiên có người thoát',
          value: '${tot['forfeited_sessions'] ?? 0}',
          caption: 'Các phiên này mất thưởng tập thể',
        ),
      ]),
      StatRow(children: [
        StatTile(
          label: 'Tỉ lệ hoàn thành',
          value: pct(tot['completion_rate'] as num?),
          caption: 'Hết giờ mà bản thân không thoát',
        ),
        StatTile(
          label: 'Hoàn thành có thưởng',
          value: pct(tot['rewarded_completion_rate'] as num?),
          caption: 'Hoàn thành và phiên không mất thưởng',
        ),
      ]),
      AppCard(children: [
        const SectionHeader('Theo thành viên', subtitle: 'Sắp theo tên A→Z, không xếp hạng.'),
        Row(children: [
          Expanded(flex: 4, child: Text('Tên', style: t.labelMedium!.copyWith(color: DT.textSecondary))),
          Expanded(flex: 2, child: Text('Có mặt', style: t.labelMedium!.copyWith(color: DT.textSecondary))),
          Expanded(flex: 3, child: Text('Hoàn thành', style: t.labelMedium!.copyWith(color: DT.textSecondary))),
          Expanded(flex: 2, child: Text('Thoát', textAlign: TextAlign.end, style: t.labelMedium!.copyWith(color: DT.textSecondary))),
        ]),
        const Divider(height: 1),
        for (final row in r.rows)
          InkWell(
            key: Key('reportRow-${row.userId}'),
            onTap: () => context.push('/reports/${r.groupId}/${r.month}/members/${row.userId}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(flex: 4, child: Text(row.displayName, style: t.titleSmall)),
                  Expanded(flex: 2, child: Text('${row.present}/${row.expected}', style: t.bodyMedium!.copyWith(fontFeatures: DT.tabular))),
                  Expanded(flex: 3, child: Text(pct(row.completionRate), style: t.bodyMedium!.copyWith(fontFeatures: DT.tabular))),
                  Expanded(
                    flex: 2,
                    child: Text('${row.exited}',
                        textAlign: TextAlign.end,
                        style: t.titleSmall!.copyWith(color: row.exited > 0 ? DT.warning : DT.textPrimary)),
                  ),
                ]),
                if (row.exited > 0 || row.absent > 0)
                  Text(
                    [
                      if (row.exited > 0) 'Thoát ${row.exited} phiên',
                      if (row.absent > 0) 'Vắng ${row.absent} phiên',
                      if (row.lost > 0) 'Mất kết nối ${row.lost} lần',
                    ].join(' · '),
                    style: t.bodySmall,
                  ),
              ]),
            ),
          ),
      ]),
      HintText('Báo cáo tạo lúc ${hhmm(r.generatedAt)} ${ddmm(r.generatedAt)} — số liệu không đổi sau khi tạo.'),
      const HintText('Ngày 1 hằng tháng, email tóm tắt báo cáo gửi chủ nhóm, không kèm tệp PDF.', icon: Icons.mail_outline),
    ];
  }

  /// V-34 — thành viên chỉ thấy dòng của mình (+ tổng nhóm nếu đủ ngưỡng). Không Coins/chuỗi.
  List<Widget> memberReport(BuildContext context, GroupReport r) {
    final t = context.text;
    final g = ref.read(myGroupsProvider).value?.where((x) => x.groupId == r.groupId).firstOrNull;
    final m = r.myRow;
    final tot = r.totals;
    return [
      Text('Báo cáo của tôi · ${g?.name ?? ''} · Tháng ${monthLabel(r.month)}', style: t.headlineSmall),
      PurposeCard(purpose: r.purpose, generatedAt: ddmm(r.generatedAt)),
      const AppBanner(tone: BannerTone.info, icon: Icons.visibility_outlined, text: 'Chủ nhóm thấy đúng các số dưới đây về bạn.'),
      if (m == null)
        const AppCard(children: [InfoRow(icon: Icons.info_outline, title: 'Không có dòng của bạn trong kỳ này')])
      else
        AppCard(key: const Key('myReportRow'), children: [
          ReceiptRow(label: 'Số ngày điểm danh (trong nhóm)', value: '${m.attendanceDays}'),
          ReceiptRow(label: 'Phiên đã lên lịch', value: '${m.expected}'),
          ReceiptRow(label: 'Số phiên hoàn thành', value: '${m.completed}'),
          ReceiptRow(label: 'Tỉ lệ hoàn thành', value: pct(m.completionRate)),
          ReceiptRow(label: 'Tổng phút tập trung', value: '${m.focusMinutes}'),
          ReceiptRow(label: 'Số lần rời app', value: '${m.exited}'),
          ReceiptRow(label: 'Số lần mất kết nối', value: '${m.lost}'),
          ReceiptRow(label: 'Số lần vắng', value: '${m.absent}'),
        ]),
      if (m != null && m.explanations.isNotEmpty)
        AppCard(children: [
          Text('Sự kiện rời app', style: t.titleMedium),
          for (final e in m.explanations)
            InfoRow(
              icon: Icons.logout,
              iconColor: DT.warning,
              title: 'Rời lúc ${hhmm(DateTime.tryParse('${e['exited_at']}'))} ${ddmm(DateTime.tryParse('${e['exited_at']}'))}',
              subtitle: explanationNote(e),
            ),
        ]),
      if (tot != null)
        AppCard(children: [
          Text('Tổng nhóm', style: t.titleMedium),
          ReceiptRow(label: 'Phiên đã diễn ra', value: '${tot['sessions_held'] ?? 0}'),
          ReceiptRow(label: 'Tỉ lệ hoàn thành của nhóm', value: pct(tot['completion_rate'] as num?)),
          ReceiptRow(label: 'Phiên mất thưởng tập thể', value: '${tot['forfeited_sessions'] ?? 0}'),
        ]),
      HintText('Tạo lúc ${hhmm(r.generatedAt)} ${ddmm(r.generatedAt)}. Số liệu không đổi sau khi tạo.'),
      const HintText('Báo cáo không có chuỗi, Coins, điểm hay hạng.'),
    ];
  }
}

/// V-49 Chi tiết báo cáo một thành viên (chủ nhóm). Mockup `t_11_chi_ti_t_b_o_c_o_th_nh_vi_n`.
/// Không Coins, chuỗi, điểm, hạng; mục đích báo cáo ở đầu (V-35).
class OwnerMemberReportScreen extends ConsumerWidget {
  const OwnerMemberReportScreen({super.key, required this.groupId, required this.month, required this.userId});
  final String groupId;
  final String month;
  final String userId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = ref.watch(reportRowProvider((groupId, month, userId)));
    final rep = ref.watch(reportProvider((groupId, month))).value;
    final t = context.text;
    return AppScaffold(
      header: AppHeader.brand(
        caption: 'Chủ nhóm',
        title: '${row.value?.displayName ?? 'Thành viên'} · tháng ${monthLabel(month)}',
        leading: HeaderLeading.back,
      ),
      body: AsyncBody<ReportRow>(
        value: row,
        onRetry: () => ref.invalidate(reportRowProvider((groupId, month, userId))),
        errorTitle: 'Chưa tải được chi tiết.',
        builder: (m) => PageList(children: [
          PurposeCard(purpose: rep?.purpose, generatedAt: rep == null ? null : ddmm(rep.generatedAt)),
          StatRow(children: [
            StatTile(label: 'Có mặt', value: '${m.present}/${m.expected}', caption: 'phiên đã lên lịch'),
            StatTile(
              label: 'Số lần thoát',
              value: '${m.exited}',
              valueColor: m.exited > 0 ? DT.warning : null,
            ),
          ]),
          StatRow(children: [
            StatTile(label: 'Tỉ lệ hoàn thành', value: pct(m.completionRate)),
            StatTile(label: 'Phút tập trung', value: '${m.focusMinutes}'),
          ]),
          AppCard(children: [
            ReceiptRow(label: 'Số phiên hoàn thành', value: '${m.completed}'),
            ReceiptRow(label: 'Số ngày điểm danh', value: '${m.attendanceDays}'),
            ReceiptRow(label: 'Mất kết nối', value: '${m.lost}'),
            ReceiptRow(label: 'Vắng', value: '${m.absent}'),
          ]),
          AppCard(children: [
            Text('Giải trình trong tháng', style: t.titleMedium),
            if (m.explanations.isEmpty)
              Text(m.exited > 0 ? 'Không giải trình.' : 'Không có lần thoát nào.',
                  style: t.bodyMedium!.copyWith(color: DT.textSecondary))
            else
              for (final e in m.explanations)
                ListRow(
                  leading: const Icon(Icons.logout, color: DT.warning),
                  title: 'Đã thoát · ${hhmm(DateTime.tryParse('${e['exited_at']}'))} ${ddmm(DateTime.tryParse('${e['exited_at']}'))}',
                  subtitle: explanationNote(e),
                  divider: false,
                  onTap: () => context.push('/owner/sessions/${e['session_id']}/explanations'),
                ),
          ]),
          const HintText('Chỉ gồm dữ liệu phiên trong nhóm này. Không có điểm, hạng, chuỗi hay Coins.'),
        ]),
      ),
    );
  }
}

/// Tab "Lịch" của chủ nhóm: phiên sắp tới của các nhóm mình quản lý + "Lên lịch phiên".
class OwnerScheduleHubScreen extends ConsumerWidget {
  const OwnerScheduleHubScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(myGroupsProvider);
    final t = context.text;
    Future<void> refresh() async {
      ref.invalidate(myGroupsProvider);
      await ref.read(myGroupsProvider.future).then((_) {}, onError: (_) {});
    }

    return AppScaffold(
      header: const AppHeader.brand(caption: 'Chủ nhóm', title: 'Lịch phiên', icon: Icons.event),
      body: AsyncBody<List<MyGroup>>(
        value: groups,
        onRetry: refresh,
        builder: (list) {
          final owned = list.where((g) => g.isOwner).toList();
          return PageList(onRefresh: refresh, children: [
            Text('Chủ nhóm không tham gia phiên, chỉ quản lý lịch và xem kết quả sau phiên.', style: t.bodySmall),
            for (final g in owned) _GroupSchedules(group: g),
          ]);
        },
      ),
    );
  }
}

class _GroupSchedules extends ConsumerWidget {
  const _GroupSchedules({required this.group});
  final MyGroup group;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(schedulesProvider(group.groupId));
    final t = context.text;
    final now = DateTime.now().toUtc();
    return AppCard(children: [
      Text(group.name, style: t.headlineSmall),
      s.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text(ApiError.from(e).message, style: t.bodySmall),
        data: (list) {
          final up = list.where((x) => x.startedAt.isAfter(now) && x.status == 'SCHEDULED').take(6).toList();
          if (up.isEmpty) return Text('Chưa có phiên sắp tới.', style: t.bodyMedium!.copyWith(color: DT.textSecondary));
          return Column(children: [
            for (var i = 0; i < up.length; i++)
              ListRow(
                title: '${hhmm(up[i].startedAt)} · ${dayLabel(up[i].startedAt)}',
                subtitle: '${up[i].durationMin} phút',
                divider: i < up.length - 1,
                trailing: const StatusBadge('Đã lên lịch', tone: BadgeTone.accent),
              ),
          ]);
        },
      ),
      PrimaryButton(
        compact: true,
        icon: Icons.add,
        label: 'Lên lịch phiên',
        onPressed: () => context.push('/groups/${group.groupId}/schedule'),
      ),
    ]);
  }
}

/// Dòng giải trình trong báo cáo (trong app): nhãn "thêm sau khi tạo báo cáo" (BR-102) và "đã sửa lúc …" (AC-04.06.6).
String explanationNote(Map<String, dynamic> e) {
  final edited = DateTime.tryParse('${e['edited_at']}');
  return [
    'Giải trình: “${e['body']}”',
    if (e['added_after_report'] == true) 'Thêm sau khi tạo báo cáo',
    if (edited != null) 'Đã sửa lúc ${hhmm(edited)} ${ddmm(edited)}',
  ].join('\n');
}
