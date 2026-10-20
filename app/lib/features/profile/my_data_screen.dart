import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/offline.dart';
import '../../core/widgets.dart';
import '../groups/group_screens.dart' show OwnerSessionDetailScreen;

/// Dữ liệu V-25 kèm mốc bản lưu (mất mạng → bản đã lưu + "Chưa cập nhật").
typedef MyDataView = ({Map<String, dynamic> data, DateTime? cachedAt});

final myDataProvider = FutureProvider.autoDispose.family<MyDataView, String?>((ref, groupId) async {
  final cache = ref.read(offlineCacheProvider);
  final key = 'my-data:${groupId ?? 'all'}';
  try {
    final d = await ref.watch(apiProvider).myData(groupId: groupId);
    await cache.put(key, d);
    return (data: d, cachedAt: null);
  } on ApiError catch (e) {
    final c = e.offline ? cache.get(key) : null;
    if (c == null) rethrow;
    return (data: c.data, cachedAt: c.at);
  }
});

List<Map<String, dynamic>> _l(Object? v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];
Map<String, dynamic> _m(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};
DateTime? _dt(Object? v) => v is String ? DateTime.tryParse(v)?.toUtc() : null;

/// Trạng thái của tôi trong phiên, theo câu chữ V-25.
String myStateText(String s, {bool forfeited = false}) => switch (s) {
      'COMPLETED' => forfeited ? 'Hoàn thành' : 'Hoàn thành có thưởng',
      'EXITED' => 'Rời app',
      'LOST' => 'Mất kết nối',
      'ABSENT' => 'Vắng',
      'WITHDRAWN' => 'Rút đồng ý',
      _ => 'Không tính',
    };

/// V-25 Dữ liệu của tôi (US-01.08) — mọi thứ DropIt! lưu về tôi, cùng trường chủ nhóm thấy (NFR-P03). Chỉ đọc.
class MyDataScreen extends ConsumerStatefulWidget {
  const MyDataScreen({super.key});
  @override
  ConsumerState<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends ConsumerState<MyDataScreen> {
  String? _group; // null = Tất cả

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(myDataProvider(_group));
    final t = context.text;
    return AppScaffold(
      header: const AppHeader.back(title: 'Dữ liệu của tôi'),
      body: AsyncBody<MyDataView>(
        value: v,
        onRetry: () => ref.invalidate(myDataProvider(_group)),
        builder: (view) {
          final d = view.data;
          final groups = _l(d['groups']);
          final sessions = _l(d['sessions']);
          final exits = _l(d['exit_events']);
          final attendance = _l(d['attendance']);
          final reports = _l(d['reports']);
          final consents = _l(d['consents']);
          final streak = _m(d['streak']);
          final coins = _m(d['coins']);
          final shop = _m(d['shop']);
          final profile = _m(d['profile']);
          final badges = _l(d['badges']);
          final noGroupData = groups.isEmpty;
          Widget empty() => Text('Chưa có dữ liệu', style: t.bodyMedium!.copyWith(color: DT.textSecondary));
          return PageList(
            onRefresh: () async {
              ref.invalidate(myDataProvider(_group));
              await ref.read(myDataProvider(_group).future).then((_) {}, onError: (_) {});
            },
            children: [
              if (view.cachedAt != null)
                AppBanner(
                  key: const Key('myDataStale'),
                  tone: BannerTone.accent,
                  icon: Icons.cloud_off,
                  title: 'Chưa cập nhật',
                  text: 'Đang hiện bản lưu lúc ${hhmm(view.cachedAt)} ${ddmm(view.cachedAt)}.',
                ),
              Text(
                'Đây là mọi thứ DropIt! lưu về bạn. Chủ nhóm chỉ thấy phần ghi "Chủ nhóm thấy" và chỉ trong nhóm của họ.',
                style: t.bodyMedium!.copyWith(color: DT.textSecondary),
              ),
              if (groups.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(children: [
                    FilterChipPill(label: 'Tất cả', selected: _group == null, onTap: () => setState(() => _group = null)),
                    for (final g in {for (final g in groups) '${g['group_id']}': g}.values) ...[
                      const SizedBox(width: DT.spaceSm),
                      FilterChipPill(
                        key: Key('filter_${g['group_id']}'),
                        label: '${g['name']}${g['left_at'] != null ? ' (đã rời)' : ''}',
                        selected: _group == '${g['group_id']}',
                        onTap: () => setState(() => _group = '${g['group_id']}'),
                      ),
                    ],
                  ]),
                ),
              _Section(
                key: const Key('secExits'),
                title: 'Sự kiện rời app',
                ownerSees: true,
                children: noGroupData || exits.isEmpty
                    ? [empty()]
                    : [
                        for (final e in exits)
                          ListRow(
                            title: '${e['group_name']} · rời lúc ${hhmmss(_dt(e['exited_at']))} ${ddmm(_dt(e['exited_at']))}',
                            subtitle: [
                              if (e['explanation'] != null)
                                'Giải trình: ${_m(e['explanation'])['body']}'
                                    '${_m(e['explanation'])['edited_at'] != null ? ' (đã sửa lúc ${hhmm(_dt(_m(e['explanation'])['edited_at']))})' : ''}',
                              if (e['appeal_status'] != null) 'Khiếu nại: ${appealStatusLabel('${e['appeal_status']}')}',
                              if (e['exempted'] == true) 'Đã miễn trừ',
                            ].join('\n').ifEmptyNull,
                            onTap: () => context.push('/explanation/${e['session_id']}'),
                          ),
                        Text('Không xóa được sự kiện rời app khi còn trong nhóm. Nếu ghi nhầm, hãy gửi giải trình.',
                            style: t.bodySmall),
                      ],
              ),
              _Section(
                key: const Key('secSessions'),
                title: 'Kết quả phiên',
                ownerSees: true,
                children: noGroupData || sessions.isEmpty
                    ? [empty()]
                    : [
                        for (final s in sessions.take(50))
                          ListRow(
                            title: '${s['group_name']} · ${ddmm(_dt(s['started_at']))} ${hhmm(_dt(s['started_at']))}',
                            subtitle: [
                              if (s['forfeited'] == true && s['forfeit_triggered_by_me'] != true)
                                'Phiên đã mất thưởng tập thể do ${s['forfeit_trigger_display_name']} rời phiên.',
                              if (s['forfeit_triggered_by_me'] == true) 'Bạn rời phiên — cả phiên mất thưởng.',
                              if (s['late_join'] == true) 'Vào muộn',
                              if ((s['pause_count'] as num? ?? 0) > 0) 'Tạm dừng ${s['pause_count']} lần',
                            ].join('\n').ifEmptyNull,
                            trailing: StatusBadge(
                              myStateText('${s['final_state']}', forfeited: s['forfeited'] == true),
                              tone: OwnerSessionDetailScreen.finalStateTone('${s['final_state']}'),
                            ),
                            onTap: () => context.push('/history/${s['session_id']}'),
                          ),
                      ],
              ),
              _Section(
                title: 'Điểm danh trong nhóm',
                ownerSees: true,
                children: attendance.isEmpty
                    ? [empty()]
                    : [
                        for (final a in attendance)
                          ListRow(
                            title: '${a['group_name'] ?? 'Nhóm'}',
                            subtitle:
                                '${a['days']} ngày · ${a['sessions_completed']} phiên · ${a['focus_minutes']} phút',
                            divider: false,
                          ),
                      ],
              ),
              _Section(
                title: 'Báo cáo tháng (phần của tôi)',
                ownerSees: true,
                children: reports.isEmpty
                    ? [empty()]
                    : [
                        for (final r in reports)
                          ListRow(
                              title: '${r['group_name']} · tháng ${r['month']}',
                              onTap: () => context.push('/reports/${r['group_id']}')),
                      ],
              ),
              _Section(title: 'Chuỗi ngày', children: [
                Text('Hiện tại ${streak['current'] ?? 0} ngày · dài nhất ${streak['longest'] ?? 0} ngày'
                    '${streak['shown_on_profile'] == true ? ' · đang hiện trên hồ sơ' : ''}'),
              ]),
              _Section(title: 'Huy hiệu', children: [
                badges.isEmpty ? empty() : Text('${badges.length} huy hiệu: ${badges.map((b) => b['name']).join(', ')}'),
              ]),
              _Section(title: 'Coins', children: [
                Text('Số dư ${coins['balance'] ?? 0} · ${coins['ledger_entries'] ?? 0} giao dịch'),
              ]),
              _Section(title: 'Đồ Shop', children: [
                Text('Đã có ${shop['owned_count'] ?? 0} món. Món đang trang bị: người cùng nhóm thấy.'),
              ]),
              _Section(title: 'Hồ sơ', children: [
                Text('${profile['display_name'] ?? ''}${profile['email'] != null ? ' · ${profile['email']}' : ''}'),
                Text('Tên, ảnh: người cùng nhóm thấy. Email: chỉ bạn và quản trị.', style: t.bodySmall),
              ]),
              _Section(title: 'Nhật ký', children: [
                Text('${_m(d['journal'])['entry_count'] ?? 0} mục (nội dung chỉ mở ở màn Nhật ký).'),
              ]),
              _Section(
                title: 'Bản ghi đồng ý',
                children: consents.isEmpty
                    ? [empty()]
                    : [
                        for (final c in consents)
                          ListRow(
                            title: '${c['group_name']} · ${c['action'] == 'WITHDRAW' ? 'Rút đồng ý' : 'Đồng ý'}',
                            subtitle: 'Phiên bản ${c['consent_version']} · ${hhmm(_dt(c['at']))} ${ddmm(_dt(c['at']))}',
                            divider: false,
                          ),
                      ],
              ),
            ],
          );
        },
      ),
    );
  }
}

String appealStatusLabel(String s) => switch (s) {
      'PENDING' => 'chờ xử lý',
      'IN_REVIEW' => 'đang xử lý',
      'ESCALATED' => 'chuyển quản trị',
      'EXEMPTED' => 'miễn trừ',
      'REJECTED' => 'bác',
      _ => s,
    };

class _Section extends StatelessWidget {
  const _Section({super.key, required this.title, required this.children, this.ownerSees = false});
  final String title;
  final List<Widget> children;
  final bool ownerSees;
  @override
  Widget build(BuildContext context) => AppCard(children: [
        Row(children: [
          Expanded(child: Text(title, style: context.text.titleMedium)),
          StatusBadge(ownerSees ? 'Chủ nhóm thấy' : 'Chỉ bạn', tone: ownerSees ? BadgeTone.accent : BadgeTone.neutral),
        ]),
        ...children,
      ]);
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}
