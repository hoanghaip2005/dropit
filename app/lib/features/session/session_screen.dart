import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import 'session_controller.dart';

/// Một route cho cả luồng trong phiên: V-06 phòng chờ, V-07 đếm ngược,
/// V-08 Lockdown, V-09 khoan hồng, V-10 mất kết nối, V-11 banner.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.sessionId});
  final String sessionId;
  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  Timer? _tick;
  Timer? _bannerTimer;
  String? _bannerShown;

  @override
  void initState() {
    super.initState();
    // Chỉ đổi mỗi giây (Lockdown tĩnh, DESIGN.md).
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _scheduleBannerHide(SessionView v) {
    final top = v.banners.isEmpty ? null : v.banners.first;
    if (top?.eventId == _bannerShown) return;
    _bannerShown = top?.eventId;
    _bannerTimer?.cancel();
    if (top != null) {
      _bannerTimer = Timer(const Duration(seconds: 6), () {
        ref.read(sessionControllerProvider(widget.sessionId).notifier).dismissBanner(top.eventId);
      });
    }
  }

  Future<void> _confirmLeave(SessionView v) async {
    final inLobby = v.phase == SessionPhase.waiting;
    final ok = await showConfirmDialog(
      context,
      title: 'Rời phiên?',
      message: inLobby ? 'Bạn sẽ bị ghi vắng ở phiên này. Không ai nhận thông báo.' : null,
      bullets: inLobby
          ? const []
          : const ['Bạn thoát phiên ngay và nhận 0 Coins.', 'Cả phiên mất thưởng tập thể.', 'Cả nhóm thấy tên bạn.'],
      confirmLabel: 'Xác nhận rời phiên',
      cancelLabel: inLobby ? 'Hủy' : 'Hủy — tiếp tục phiên',
      destructive: true,
      dark: !inLobby,
      confirmKey: const Key('leaveConfirm'),
      cancelKey: const Key('leaveCancel'),
    );
    if (ok) await ref.read(sessionControllerProvider(widget.sessionId).notifier).leave();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.sessionId;
    final v = ref.watch(sessionControllerProvider(id));
    final info = ref.watch(sessionInfoProvider(id)).value;

    ref.listen(sessionControllerProvider(id), (prev, next) {
      if (prev?.phase == next.phase) {
        if (next.leaveError != null && prev?.leaveError != next.leaveError) {
          showSnack(context, next.leaveError!);
          ref.read(sessionControllerProvider(id).notifier).clearLeaveError();
        }
        return;
      }
      switch (next.phase) {
        case SessionPhase.exited:
        case SessionPhase.ended:
          context.pushReplacement('/session/$id/result');
        case SessionPhase.absent:
          showSnack(context, 'Bạn đã rời phòng chờ — ghi vắng.');
          ref.invalidate(upcomingProvider);
          context.go('/home');
        default:
          break;
      }
    });
    _scheduleBannerHide(v);

    final dark = v.phase == SessionPhase.countdown || v.recording || v.phase == SessionPhase.lost;
    final inLobby = v.phase == SessionPhase.waiting;
    return PopScope(
      // Phòng chờ: nút Back hệ thống → hộp xác nhận "Rời phiên → vắng" (không thoát lặng lẽ).
      canPop: !dark && !inLobby,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && inLobby && !v.leaving) _confirmLeave(v);
      },
      child: dark
          ? Scaffold(backgroundColor: DT.lockdownBg, body: SafeArea(child: _body(v, info)))
          : AppScaffold(
              header: AppHeader.back(
                title: 'Phòng chờ',
                onLeading: inLobby ? () => _confirmLeave(v) : null,
              ),
              body: _body(v, info)),
    );
  }

  Widget _body(SessionView v, SessionSummary? info) {
    switch (v.phase) {
      case SessionPhase.connecting:
        return const StateMessage(icon: Icons.sync, tone: StateTone.accent, title: 'Đang vào phòng chờ…');
      case SessionPhase.error:
        return StateMessage(
          icon: Icons.block,
          tone: StateTone.danger,
          title: 'Chưa vào được phòng chờ',
          body: v.errorMessage,
          action: v.errorCode == 'CONSENT_REQUIRED' ? 'Xem nhóm' : 'Về trang chủ',
          onAction: () => context.go(v.errorCode == 'CONSENT_REQUIRED' ? '/groups' : '/home'),
        );
      case SessionPhase.cancelled:
        return StateMessage(
          icon: Icons.event_busy,
          title: v.cancelReason == 'SERVER_OUTAGE'
              ? 'Phiên đã hủy do sự cố hệ thống. Kết quả của bạn không bị tính.'
              : v.cancelReason == 'REMOVED'
                  ? 'Bạn không còn ở nhóm này.'
                  : 'Chủ nhóm đã hủy phiên này.',
          action: 'Về trang chủ',
          onAction: () => context.go('/home'),
        );
      case SessionPhase.waiting:
        return LobbyView(view: v, info: info, onLeave: () => _confirmLeave(v));
      case SessionPhase.countdown:
        return CountdownView(view: v, info: info);
      case SessionPhase.absent:
      case SessionPhase.exited:
      case SessionPhase.ended:
        return const StateMessage(icon: Icons.hourglass_top, title: 'Đang chốt kết quả…');
      case SessionPhase.focusing:
      case SessionPhase.grace:
      case SessionPhase.disconnected:
      case SessionPhase.lost:
        return LockdownView(
          view: v,
          onLeave: () => _confirmLeave(v),
          onDismissBanner: (e) => ref.read(sessionControllerProvider(widget.sessionId).notifier).dismissBanner(e),
        );
    }
  }
}

/// V-06 Phòng chờ. Mockup: `session_lobby_1/2`.
class LobbyView extends StatelessWidget {
  const LobbyView({super.key, required this.view, required this.info, required this.onLeave});
  final SessionView view;
  final SessionSummary? info;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final start = view.startedAt ?? info?.startedAt;
    final dur = info?.durationMin ?? 25;
    final left = start?.difference(view.serverNow());
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(DT.margin, DT.spaceSm, DT.margin, DT.spaceLg), children: [
          if (!view.connected) ...[
            const AppBanner(tone: BannerTone.accent, icon: Icons.sync, text: 'Đang kết nối lại…'),
            const SizedBox(height: DT.spaceMd),
          ],
          Text(left == null ? '--:--' : mmss(left),
              style: t.displayMedium!.copyWith(fontFeatures: DT.tabular), textAlign: TextAlign.center),
          const SizedBox(height: DT.spaceSm),
          Text(info?.groupName ?? 'Phiên tập trung', style: t.headlineSmall, textAlign: TextAlign.center),
          Text('Bắt đầu ${hhmm(start)} · $dur phút · thời lượng do chủ nhóm đặt',
              style: t.bodyMedium!.copyWith(color: DT.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: DT.spaceSm),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: DT.spaceMd, vertical: 6),
              decoration: BoxDecoration(color: DT.successSoftBg, borderRadius: BorderRadius.circular(DT.pill)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.monetization_on, size: 18, color: DT.success),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('+${dur >= 50 ? 25 : 10} Coins mỗi người nếu cả phiên hoàn thành',
                      style: t.labelLarge!.copyWith(color: DT.success)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: DT.spaceMd),
          AppCard(children: [
            Text('Trong phòng chờ', style: t.titleMedium),
            Row(children: [
              const Icon(Icons.check_circle, size: 18, color: DT.success),
              const SizedBox(width: 6),
              Text(
                view.participantCount == null ? 'Đang cập nhật…' : '${view.participantCount} người đã vào phòng chờ',
                style: t.bodyMedium,
              ),
            ]),
            if (view.lobbyMembers.isNotEmpty)
              Wrap(
                key: const Key('lobbyMembers'),
                spacing: DT.spaceSm,
                runSpacing: DT.spaceSm,
                children: [for (final n in view.lobbyMembers) PersonChip(n)],
              ),
          ]),
          const SizedBox(height: DT.spaceMd),
          AppCard(gap: DT.spaceMd, children: [
            Text('Quy tắc phiên', style: t.titleMedium),
            const InfoRow(
              icon: Icons.logout,
              iconColor: DT.warning,
              title: 'Rời app quá 3 giây = rời phiên',
              subtitle: 'Khoan hồng 3 giây. Quá 3 giây, tên bạn được báo ngay cho cả nhóm.',
            ),
            const InfoRow(
              icon: Icons.group_off_outlined,
              iconColor: DT.warning,
              title: 'Cả phiên mất thưởng',
              subtitle: 'Phiên vẫn chạy đến hết giờ, nhưng mọi người trong phiên mất Coins của phiên.',
            ),
            const InfoRow(
              icon: Icons.screen_lock_portrait_outlined,
              iconColor: DT.success,
              title: 'Được tắt màn hình',
              subtitle: 'Khóa màn hình không tính là rời app.',
            ),
          ]),
        ]),
      ),
      Padding(
        padding:
            EdgeInsets.fromLTRB(DT.margin, DT.spaceSm, DT.margin, DT.spaceMd + MediaQuery.paddingOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Phiên tự bắt đầu đúng giờ. Ở lại màn này để không bị ghi vắng.',
              textAlign: TextAlign.center, style: t.bodySmall),
          const SizedBox(height: DT.spaceSm),
          SecondaryButton(
            key: const Key('leaveButton'),
            label: 'Rời phiên',
            destructive: true,
            onPressed: view.leaving ? null : onLeave,
          ),
        ]),
      ),
    ]);
  }
}

/// V-07 Đếm ngược 5 giây — không có nút. Nền đen tĩnh.
class CountdownView extends StatelessWidget {
  const CountdownView({super.key, required this.view, required this.info});
  final SessionView view;
  final SessionSummary? info;

  @override
  Widget build(BuildContext context) {
    final start = view.startedAt;
    if (start == null) {
      return const Center(child: Text('Đang đồng bộ giờ…', style: lockGrey));
    }
    final ms = start.difference(view.serverNow()).inMilliseconds;
    final n = (ms / 1000).ceil().clamp(1, 5);
    return Semantics(
      label: 'Phiên sắp bắt đầu. Còn $n giây',
      child: Padding(
        padding: const EdgeInsets.all(DT.margin),
        child: Column(children: [
          const SizedBox(height: DT.spaceSm),
          Text('${info?.groupName ?? 'Phiên tập trung'} · ${info?.durationMin ?? ''} phút',
              style: lockGrey, textAlign: TextAlign.center),
          const Spacer(),
          CountdownRing(
            value: '$n',
            label: 'giây',
            size: 180,
            ringColor: DT.lockdownButton,
            valueKey: const Key('countdownDigit'),
          ),
          const SizedBox(height: DT.spaceLg),
          const Text('Phiên sắp bắt đầu',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: DT.spaceSm),
          Text('Chưa ghi — bắt đầu ghi lúc ${hhmmss(start)}', style: lockGrey, textAlign: TextAlign.center),
          if (!view.connected) const Text('Đang kết nối lại…', style: lockGrey),
          const Spacer(),
          const _LockNote(
            icon: Icons.warning_amber_rounded,
            iconColor: _alertRed,
            text: 'Ở lại trong app. Rời app sau khi bắt đầu sẽ báo tên bạn cho cả nhóm và làm cả phiên mất thưởng.',
            white: true,
          ),
          const SizedBox(height: DT.spaceSm),
          const _LockNote(
            icon: Icons.screen_lock_portrait_outlined,
            text: 'Bạn có thể khóa hoặc úp máy — khóa màn hình không tính là rời app.',
          ),
          if (view.participantCount != null) ...[
            const SizedBox(height: DT.spaceSm),
            _LockNote(icon: Icons.groups_outlined, text: '${view.participantCount} người đã sẵn sàng'),
          ],
          const SizedBox(height: DT.spaceLg),
        ]),
      ),
    );
  }
}

/// Đỏ sáng cho biểu tượng cảnh báo trên nền đen (mockup `#FF6B5E`, 7.1:1 trên đen).
const _alertRed = Color(0xFFFF6B5E);

class _LockNote extends StatelessWidget {
  const _LockNote({required this.icon, required this.text, this.white = false, this.iconColor});
  final IconData icon;
  final String text;
  final bool white;
  final Color? iconColor;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: iconColor ?? DT.lockdownTextSecondary),
        const SizedBox(width: DT.spaceSm),
        Expanded(
          child: Text(text, style: white ? const TextStyle(color: Colors.white, fontSize: 14, height: 20 / 14) : lockGrey),
        ),
      ]);
}

/// V-08 Màn phiên (Lockdown) + lớp V-09/V-10/V-11/LOST. Mockup: `lockdown_mode` — đen tĩnh.
class LockdownView extends StatelessWidget {
  const LockdownView({super.key, required this.view, required this.onLeave, required this.onDismissBanner});
  final SessionView view;
  final VoidCallback onLeave;
  final void Function(String eventId) onDismissBanner;

  @override
  Widget build(BuildContext context) {
    final v = view;
    final remaining = v.endsAt?.difference(v.serverNow());
    final lost = v.phase == SessionPhase.lost;
    return Stack(children: [
      Padding(
        padding: const EdgeInsets.all(DT.margin),
        child: Column(children: [
          SizedBox(
            height: 32,
            child: lost
                ? null
                : const Align(alignment: Alignment.centerLeft, child: RecordingPill(textKey: Key('recordingIndicator'))),
          ),
          const SizedBox(height: 72),
          Text(lost ? 'Phiên của bạn đã kết thúc' : 'Thời gian còn lại', style: lockGrey),
          const SizedBox(height: DT.spaceSm),
          Text(remaining == null ? '--:--' : mmss(remaining),
              key: const Key('remaining'),
              style: const TextStyle(
                  color: Colors.white, fontSize: 72, fontWeight: FontWeight.w700, height: 1, fontFeatures: DT.tabular)),
          if (v.endsAt != null && !lost) ...[
            const SizedBox(height: DT.spaceSm),
            Text('Kết thúc lúc ${hhmm(v.endsAt)}', style: lockGrey),
          ],
          if (v.forfeited)
            const Padding(
              padding: EdgeInsets.only(top: DT.spaceSm),
              child: Text('Phiên đã mất thưởng tập thể', key: Key('forfeitedLabel'), style: lockGrey),
            ),
          const Spacer(),
          if (lost)
            Container(
              padding: const EdgeInsets.all(DT.spaceLg),
              decoration: lockPanelDecoration(),
              child: Column(children: [
                const Text(
                  'Bạn đã mất kết nối quá lâu. Phiên của bạn đã kết thúc: Mất kết nối — 0 Coins. '
                  'Phiên của nhóm vẫn tiếp tục và không bị ảnh hưởng.',
                  style: lockWhite,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DT.spaceMd),
                LockdownButton(label: 'Về trang chủ', onPressed: () => context.go('/home')),
              ]),
            )
          else ...[
            const _LockNote(
              icon: Icons.warning_amber_rounded,
              iconColor: _alertRed,
              text: 'Rời app quá 3 giây sẽ báo tên bạn cho cả nhóm và làm cả phiên mất thưởng.',
              white: true,
            ),
            const SizedBox(height: DT.spaceSm),
            const _LockNote(icon: Icons.screen_lock_portrait_outlined, text: 'Khóa màn hình không tính là rời app.'),
            const SizedBox(height: DT.spaceMd),
            LockdownButton(
              key: const Key('leaveButton'),
              icon: Icons.logout,
              label: 'Rời phiên',
              onPressed: v.leaving ? null : onLeave,
            ),
            TextButton(
              onPressed: () => context.push('/leave-group'),
              style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
              child: const Text('Rút đồng ý và rời nhóm',
                  style: TextStyle(color: DT.lockdownTextSecondary, fontSize: 12)),
            ),
          ],
        ]),
      ),
      if (v.banners.isNotEmpty && !lost)
        Positioned(
          left: DT.margin,
          right: DT.margin,
          top: 56,
          child: ExitBannerView(banner: v.banners.first, more: v.banners.length - 1, onDismiss: onDismissBanner),
        ),
      if (v.phase == SessionPhase.grace) Positioned.fill(child: GraceOverlay(view: v, onLeave: onLeave)),
      if (v.phase == SessionPhase.disconnected) const Positioned.fill(child: DisconnectedOverlay()),
    ]);
  }
}

/// V-11 Banner người thoát — hiện/ẩn tức thì, không hoạt ảnh.
class ExitBannerView extends StatelessWidget {
  const ExitBannerView({super.key, required this.banner, required this.more, required this.onDismiss});
  final ExitBanner banner;
  final int more;
  final void Function(String) onDismiss;

  @override
  Widget build(BuildContext context) {
    final at = hhmmss(banner.at);
    final text = banner.triggeredForfeit
        ? '${banner.name} đã rời phiên lúc $at. Phiên đã mất thưởng tập thể — vẫn tiếp tục đến hết giờ.'
        : '${banner.name} đã rời phiên lúc $at.';
    return Dismissible(
      key: ValueKey(banner.eventId),
      onDismissed: (_) => onDismiss(banner.eventId),
      child: Container(
        key: const Key('exitBanner'),
        padding: const EdgeInsets.all(DT.spaceMd),
        decoration: lockPanelDecoration(),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.campaign_outlined, color: Colors.white),
          const SizedBox(width: DT.spaceSm + 4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
              if (banner.triggeredForfeit)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Bạn vẫn hoàn thành phiên nếu ở lại đến hết giờ.', style: lockGrey),
                ),
              if (more > 0) Text('+$more thông báo khác', style: lockGrey),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// V-09 Cảnh báo khoan hồng 3 giây. Bố cục và câu chữ theo mockup `n_07`, nhưng giữ quy tắc
/// "Lockdown đen tĩnh": nền đen, vòng tĩnh viền đỏ + số giây (không cung chạy, không hoạt ảnh, không Coins).
/// Lối thoát khẩn cấp đi qua cùng hộp xác nhận "Rời phiên" (thoát = rời app).
class GraceOverlay extends StatelessWidget {
  const GraceOverlay({super.key, required this.view, this.onLeave});
  final SessionView view;
  final VoidCallback? onLeave;
  @override
  Widget build(BuildContext context) {
    final d = view.graceDeadline;
    final left = d == null ? null : (d.difference(view.serverNow()).inMilliseconds / 1000).ceil().clamp(0, 3);
    return ColoredBox(
      color: DT.lockdownBg,
      child: Padding(
        key: const Key('graceOverlay'),
        padding: const EdgeInsets.all(DT.spaceLg),
        child: Column(children: [
          const Spacer(),
          const Text('Bạn vừa rời DropIt!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: DT.spaceLg),
          CountdownRing(value: left == null ? '–' : '$left', label: 'giây'),
          const SizedBox(height: DT.spaceLg),
          const Text(
            'Hết 3 giây khoan hồng, tên bạn sẽ được báo cho cả nhóm và mọi người trong phiên. '
            'Cả phiên mất thưởng tập thể và mọi người bị ngắt chuỗi.',
            style: lockGrey,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DT.spaceSm),
          const Text('Ở lại trong app để tiếp tục phiên. Lượt khoan hồng chỉ có một lần mỗi phiên.',
              style: lockGrey, textAlign: TextAlign.center),
          const Spacer(),
          if (onLeave != null) ...[
            LockdownButton(
              key: const Key('graceEmergencyExit'),
              icon: Icons.logout,
              label: 'Tôi có việc khẩn cấp — thoát phiên',
              onPressed: view.leaving ? null : onLeave,
            ),
            const SizedBox(height: DT.spaceSm),
            const Text(
              'Thoát phiên được tính như rời app: báo tên cho cả nhóm và cả phiên mất thưởng.',
              style: TextStyle(color: DT.lockdownTextSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ]),
      ),
    );
  }
}

/// V-10 Mất kết nối.
class DisconnectedOverlay extends StatelessWidget {
  const DisconnectedOverlay({super.key});
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.center,
        child: Container(
          key: const Key('disconnectedOverlay'),
          margin: const EdgeInsets.all(DT.margin),
          padding: const EdgeInsets.all(DT.spaceLg),
          decoration: lockPanelDecoration(),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 36),
            SizedBox(height: 12),
            Text('Đang kết nối lại…', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(
              'Ở lại trong app. Mất mạng không tính là rời app. Nếu không kết nối lại kịp, chỉ bạn không nhận Coins phiên này; cả nhóm không bị ảnh hưởng.',
              style: lockGrey,
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
}
