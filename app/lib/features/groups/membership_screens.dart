import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/models_ext.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../achievements/achievements_screen.dart' show badgeName;
import '../session/session_controller.dart';
import 'group_screens.dart' show sessionStatusText;

/// V-21 Rút đồng ý và rời nhóm (US-01.07) — 2 bước, nói rõ hệ quả trước khi xác nhận, kể cả khi đang trong phiên.
/// Không hỏi lý do; chủ nhóm chỉ nhận "‹Tên› đã rời nhóm". Nút "Rời nhóm" đen (không đỏ).
class LeaveGroupScreen extends ConsumerStatefulWidget {
  const LeaveGroupScreen({super.key, required this.groupId});
  final String groupId;
  @override
  ConsumerState<LeaveGroupScreen> createState() => _LeaveGroupScreenState();
}

class _LeaveGroupScreenState extends ConsumerState<LeaveGroupScreen> {
  int _step = 1;
  bool _busy = false;
  String? _err;

  Future<void> _leave(String name) async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await ref.read(apiProvider).withdrawConsent(widget.groupId);
      ref.invalidate(myGroupsProvider);
      ref.invalidate(upcomingProvider);
      if (!mounted) return;
      showSnack(context, 'Bạn đã rời $name.');
      context.go('/groups');
    } catch (e) {
      final a = ApiError.from(e);
      setState(() {
        _step = 1;
        _err = a.offline || a.status == null
            ? 'Chưa rút được đồng ý. Bạn vẫn là thành viên.'
            : (a.code == 'OWNER_OF_THIS_GROUP' ? 'Chủ nhóm không rút đồng ý — chỉ có "Giải tán nhóm".' : a.message);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final g = ref.watch(myGroupsProvider).value?.where((x) => x.groupId == widget.groupId).firstOrNull;
    final name = g?.name ?? 'nhóm';
    // Khối theo ngữ cảnh phiên: chỉ khi đang có trạng thái chưa kết thúc (controller phiên đang sống).
    final liveSid = ref.watch(liveSessionProvider);
    final live = liveSid == null ? null : ref.watch(sessionControllerProvider(liveSid));
    if (g != null && g.isOwner) {
      return const ComingSoonScreen(
        title: 'Rút đồng ý',
        code: 'V-21',
        body: 'Chủ nhóm không rút đồng ý. Chỉ có "Giải tán nhóm".',
      );
    }
    return AppScaffold(
      header: AppHeader.back(title: _step == 1 ? 'Rút đồng ý' : 'Xác nhận rời nhóm'),
      footer: _step == 1
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              PrimaryButton(key: const Key('leaveNext'), label: 'Tiếp tục', onPressed: () => setState(() => _step = 2)),
              const SizedBox(height: DT.spaceSm),
              SecondaryButton(label: 'Hủy', onPressed: () => context.pop()),
            ])
          : Column(mainAxisSize: MainAxisSize.min, children: [
              PrimaryButton(
                key: const Key('leaveConfirm'),
                label: _busy ? 'Đang xử lý…' : 'Rời nhóm',
                loading: _busy,
                onPressed: () => _leave(name),
              ),
              const SizedBox(height: DT.spaceSm),
              SecondaryButton(key: const Key('leaveCancel'), label: 'Hủy', onPressed: () => context.pop()),
            ]),
      children: _step == 1
          ? [
              Text('Rút đồng ý và rời $name', style: t.headlineMedium),
              if (live != null && live.isLive)
                AppBanner(
                  key: const Key('leaveInSession'),
                  tone: BannerTone.accent,
                  title: 'Bạn đang trong phiên',
                  text: live.forfeited
                      ? 'Phiên này đã mất thưởng tập thể. Rút đồng ý bây giờ vẫn ngắt chuỗi của bạn và bạn không nhận Coins phiên này.'
                      : 'Rút đồng ý sẽ dừng ghi ngay. Lần này không tính là rời app, không ai nhận thông báo, '
                          'phiên của nhóm không bị ảnh hưởng. Bạn không nhận Coins phiên này.',
                ),
              const AppCard(gap: DT.spaceMd, children: [
                InfoRow(
                    icon: Icons.pause_circle_outline,
                    title: 'Từ lúc này, DropIt! ngừng ghi dữ liệu phiên của bạn trong nhóm này.'),
                InfoRow(
                    icon: Icons.notifications_none,
                    title: 'Chủ nhóm chỉ nhận thông báo "‹Tên bạn› đã rời nhóm", không kèm lý do.'),
                InfoRow(
                    icon: Icons.inventory_2_outlined,
                    iconColor: DT.success,
                    title: 'Coins, đồ đã mua, chuỗi, huy hiệu, hồ sơ và nhật ký vẫn là của bạn.'),
                InfoRow(
                    icon: Icons.analytics_outlined,
                    title: 'Số liệu phiên đến hôm nay vẫn nằm trong báo cáo tháng của nhóm. '
                        'Bạn vẫn xem được phần của mình ở Dữ liệu của tôi.'),
                InfoRow(icon: Icons.vpn_key_outlined, title: 'Muốn quay lại, bạn cần được mời lại và đồng ý lại.'),
                InfoRow(icon: Icons.group_add_outlined, title: 'Sau khi rời, bạn có thể tham gia nhóm khác.'),
              ]),
              if (_err != null)
                AppBanner(
                  key: const Key('leaveError'),
                  tone: BannerTone.danger,
                  text: _err!,
                  action: 'Thử lại',
                  onAction: () => setState(() => _step = 2),
                ),
            ]
          : [
              Text('Bạn chắc chắn rời $name?', key: const Key('leaveQuestion'), style: t.headlineMedium),
              Text('Không cần nêu lý do.', style: t.bodyMedium!.copyWith(color: DT.textSecondary)),
            ],
    );
  }
}

/// V-32 Hồ sơ công khai của người cùng nhóm: tên, avatar, khung + hình nền đang trang bị,
/// huy hiệu/chuỗi chỉ khi người đó tự bật. Không Coins, không dữ liệu phiên, không email.
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(publicProfileProvider(userId));
    final shop = {for (final s in ref.watch(shopItemsProvider).value ?? const <ShopItem>[]) s.itemId: s.previewKey};
    final t = context.text;
    return AppScaffold(
      header: const AppHeader.back(title: 'Hồ sơ'),
      body: p.when(
        skipLoadingOnRefresh: true,
        loading: () => const SkeletonList(),
        error: (e, _) {
          final a = ApiError.from(e);
          if (a.status == 403 || a.status == 404) {
            return const StateMessage(
                key: Key('profileForbidden'), icon: Icons.lock_outline, title: 'Không xem được hồ sơ này.');
          }
          return ErrorState(error: e, onRetry: () => ref.invalidate(publicProfileProvider(userId)));
        },
        data: (d) {
          final u = d.user;
          final bgKey = u.backgroundItemId == null ? null : shop[u.backgroundItemId];
          final frameKey = u.frameItemId == null ? null : shop[u.frameItemId];
          final bg = bgKey == null || bgKey.startsWith('default') ? null : previewColor(bgKey);
          return PageList(children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: DT.spaceLg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DT.radiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: bg == null ? const [DT.accentSoftBg, DT.background] : [bg, Color.lerp(bg, DT.background, 0.75)!],
                ),
              ),
              child: Column(children: [
                FramedAvatar(
                  name: u.displayName,
                  imageUrl: u.avatarUrl == null ? null : fixHost(u.avatarUrl!),
                  frameColor: frameKey == null || frameKey.startsWith('default') ? null : previewColor(frameKey),
                  size: 108,
                ),
                const SizedBox(height: DT.spaceMd),
                Text(u.displayName, style: t.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: DT.spaceXs),
                StatusBadge(d.role == 'OWNER' ? 'Chủ nhóm' : 'Thành viên',
                    key: const Key('profileRole'), tone: d.role == 'OWNER' ? BadgeTone.dark : BadgeTone.neutral),
              ]),
            ),
            // Không có gì bật → không hiện khối thành tích (không ghi "đã ẩn").
            if (d.shownStreak != null || d.shownBadges.isNotEmpty)
              AppCard(children: [
                if (d.shownStreak != null)
                  InfoRow(
                      key: const Key('profileStreak'),
                      icon: Icons.local_fire_department,
                      title: 'Chuỗi ${d.shownStreak} ngày'),
                for (final b in d.shownBadges) InfoRow(icon: Icons.military_tech_outlined, title: badgeName(b)),
              ]),
          ]);
        },
      ),
    );
  }
}

/// V-45 Sửa / hủy lịch phiên (US-02.11) — chỉ khi phiên SCHEDULED và trước mốc đếm ngược (started_at − 5s).
class EditSessionScreen extends ConsumerStatefulWidget {
  const EditSessionScreen({super.key, required this.sessionId});
  final String sessionId;
  @override
  ConsumerState<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends ConsumerState<EditSessionScreen> {
  DateTime? _date;
  TimeOfDay? _time;
  int? _dur;
  bool _busy = false;
  String? _err;
  String? _timeErr;

  void _init(SessionSummary s) {
    if (_date != null) return;
    final v = vn(s.startedAt);
    _date = DateTime(v.year, v.month, v.day);
    _time = TimeOfDay(hour: v.hour, minute: v.minute);
    _dur = s.durationMin;
  }

  DateTime get _startUtc => DateTime.utc(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute)
      .subtract(const Duration(hours: 7));

  String _errText(ApiError a) => switch (a.code) {
        'SESSION_ALREADY_STARTED' => 'Phiên vừa bắt đầu đếm ngược — thay đổi không được lưu.',
        'SCHEDULE_OVERLAP' => 'Trùng phiên khác của nhóm.',
        'START_IN_PAST' => 'Giờ bắt đầu phải sau thời điểm hiện tại ít nhất 1 phút.',
        'DURATION_OUT_OF_RANGE' => 'Chỉ chọn 25 hoặc 50 phút.',
        'SESSION_IN_PROGRESS' => a.message,
        _ => a.offline ? 'Chưa lưu được. Lịch cũ vẫn giữ nguyên.' : a.message,
      };

  Future<void> _save(SessionSummary s) async {
    if (_startUtc.isBefore(DateTime.now().toUtc().add(const Duration(minutes: 1)))) {
      setState(() => _timeErr = 'Giờ bắt đầu phải sau thời điểm hiện tại ít nhất 1 phút.');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
      _timeErr = null;
    });
    try {
      await ref.read(apiProvider).updateSession(widget.sessionId,
          startUtc: _startUtc.isAtSameMomentAs(s.startedAt) ? null : _startUtc, durationMin: _dur);
      _invalidate(s);
      if (mounted) {
        showSnack(context, 'Đã lưu. Thành viên đã được báo.');
        context.pop();
      }
    } catch (e) {
      setState(() => _err = _errText(ApiError.from(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(SessionSummary s) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hủy phiên lúc ${hhmm(s.startedAt)} ${ddmm(s.startedAt).substring(0, 5)}?',
      message: 'Thành viên sẽ được báo. Không có dữ liệu nào được ghi.',
      confirmLabel: 'Hủy phiên',
      cancelLabel: 'Giữ phiên',
      destructive: true,
      confirmKey: const Key('confirmCancelSession'),
    );
    if (!ok) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await ref.read(apiProvider).cancelSession(widget.sessionId);
      _invalidate(s);
      if (mounted) {
        showSnack(context, 'Đã hủy phiên. Thành viên đã được báo.');
        context.pop();
      }
    } catch (e) {
      setState(() => _err = _errText(ApiError.from(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _invalidate(SessionSummary s) {
    ref.invalidate(sessionInfoProvider(widget.sessionId));
    ref.invalidate(ownerDetailProvider(widget.sessionId));
    ref.invalidate(schedulesProvider(s.groupId));
    ref.invalidate(myGroupsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(sessionInfoProvider(widget.sessionId));
    final t = context.text;
    return AppScaffold(
      header: const AppHeader.back(title: 'Sửa / hủy lịch', leading: HeaderLeading.close),
      body: AsyncBody<SessionSummary>(
        value: info,
        onRetry: () => ref.invalidate(sessionInfoProvider(widget.sessionId)),
        builder: (s) {
          _init(s);
          final deadline = s.startedAt.subtract(const Duration(seconds: 5));
          final editable = s.status == 'SCHEDULED' && DateTime.now().toUtc().isBefore(deadline);
          return PageList(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.groupName ?? 'Phiên của nhóm', style: t.headlineSmall),
              Text(sessionStatusText(s.status), style: t.bodySmall),
            ]),
            if (!editable)
              const AppBanner(
                key: Key('sessionLocked'),
                tone: BannerTone.accent,
                text: 'Phiên đã bắt đầu — không sửa hoặc hủy được.',
              )
            else
              Text('Sửa hoặc hủy được đến ${hhmmss(deadline)}.', key: const Key('editDeadline'), style: t.bodyMedium),
            AppCard(gap: DT.spaceMd, children: [
              InfoRow(
                icon: Icons.calendar_today_outlined,
                title: 'Ngày: ${two(_date!.day)}/${two(_date!.month)}/${_date!.year}',
                subtitle: editable ? 'Chạm để đổi ngày' : null,
                onTap: !editable
                    ? null
                    : () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _date!,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (d != null) setState(() => _date = d);
                      },
              ),
              InfoRow(
                icon: Icons.schedule,
                title: 'Giờ bắt đầu: ${two(_time!.hour)}:${two(_time!.minute)}',
                subtitle: 'Phiên bắt đầu đếm ngược 5 giây trước giờ này.',
                onTap: !editable
                    ? null
                    : () async {
                        final tm = await showTimePicker(context: context, initialTime: _time!);
                        if (tm != null) setState(() => _time = tm);
                      },
              ),
              if (_timeErr != null) Text(_timeErr!, style: t.bodySmall!.copyWith(color: DT.warning)),
            ]),
            AppCard(children: [
              Text('Thời lượng', style: t.titleMedium),
              IgnorePointer(
                ignoring: !editable,
                child: PillToggle<int>(
                  big: true,
                  value: _dur!,
                  onChanged: (v) => setState(() => _dur = v),
                  options: const [
                    PillOption(25, '25 phút', caption: '+10 Coins'),
                    PillOption(50, '50 phút', caption: '+25 Coins'),
                  ],
                ),
              ),
              Text('25 phút: +10 Coins · 50 phút: +25 Coins cho mỗi thành viên hoàn thành có thưởng.',
                  style: t.bodySmall),
            ]),
            if (_err != null) AppBanner(key: const Key('editError'), tone: BannerTone.danger, text: _err!),
            if (editable) ...[
              PrimaryButton(
                  key: const Key('saveSession'), label: 'Lưu thay đổi', loading: _busy, onPressed: () => _save(s)),
              LinkButton(
                key: const Key('cancelSession'),
                label: 'Hủy phiên',
                color: DT.warning,
                onPressed: _busy ? null : () => _cancel(s),
              ),
            ],
          ]);
        },
      ),
    );
  }
}
