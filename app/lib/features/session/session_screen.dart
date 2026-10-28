import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
  bool _leaveDialogOpen = false;

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
        if (mounted) {
          ref
              .read(sessionControllerProvider(widget.sessionId).notifier)
              .dismissBanner(top.eventId);
        }
      });
    }
  }

  Future<void> _confirmLeave(SessionView v) async {
    final inLobby = v.phase == SessionPhase.waiting;
    if (v.leaving || _leaveDialogOpen) return;
    _leaveDialogOpen = true;
    final ok = await showDialog<bool>(
      context: context,
      animationStyle: AnimationStyle.noAnimation,
      builder: (ctx) => Dialog(
        backgroundColor: inLobby ? Colors.white : DT.lockdownSurface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  inLobby ? 'Rời phòng chờ?' : 'Rời phiên?',
                  style: TextStyle(
                    color: inLobby ? OwnerStyle.ink : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  inLobby
                      ? 'Bạn có thể quay lại check-in trước giờ bắt đầu. Rời phòng chờ lúc này không bị ghi vắng.'
                      : 'Bạn kết thúc phần tham gia ngay. Cả phiên mất thưởng tập thể và tên bạn được báo cho nhóm.',
                  style: TextStyle(
                    color: inLobby ? OwnerStyle.muted : Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('leaveConfirm'),
                  style: FilledButton.styleFrom(
                    backgroundColor: DT.warning,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Xác nhận rời phiên',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('leaveCancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: inLobby ? OwnerStyle.ink : Colors.white,
                    side: BorderSide(
                      color: inLobby
                          ? OwnerStyle.line
                          : DT.lockdownTextSecondary,
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      inLobby ? 'Hủy' : 'Hủy — tiếp tục phiên',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() => _leaveDialogOpen = false);
    if (ok != true || !mounted) return;
    final current = ref.read(sessionControllerProvider(widget.sessionId));
    if (current.leaving || !current.canLeave) return;
    if ((current.phase == SessionPhase.waiting) != inLobby) {
      showSnack(
        context,
        'Trạng thái phiên đã thay đổi. Vui lòng xác nhận rời phiên lại.',
      );
      return;
    }
    final leftLobby = await ref
        .read(sessionControllerProvider(widget.sessionId).notifier)
        .leave();
    if (leftLobby && mounted) {
      ref.invalidate(upcomingProvider);
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.sessionId;
    final v = ref.watch(sessionControllerProvider(id));
    final infoState = ref.watch(sessionInfoProvider(id));
    final info = infoState.value;
    final metadataMessage = infoState.hasError
        ? 'Chưa tải được thông tin phiên. Trạng thái kết nối được hiển thị riêng.'
        : null;

    ref.listen(sessionControllerProvider(id), (prev, next) {
      if (prev?.phase == next.phase) {
        if (next.leaveError != null && prev?.leaveError != next.leaveError) {
          showSnack(
            context,
            'Chưa rời được phiên. Kiểm tra kết nối rồi thử lại.',
          );
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

    final dark =
        v.phase == SessionPhase.countdown ||
        v.recording ||
        v.phase == SessionPhase.lost;
    final inLobby = v.phase == SessionPhase.waiting;
    final base = Theme.of(context);
    final scoped = base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: OwnerStyle.ink,
        displayColor: OwnerStyle.ink,
      ),
    );
    return Theme(
      data: scoped,
      child: PopScope(
        // Phòng chờ: nút Back hệ thống → hộp xác nhận "Rời phiên → vắng" (không thoát lặng lẽ).
        canPop: !dark && !inLobby,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && inLobby && !v.leaving) _confirmLeave(v);
        },
        child: dark
            ? Scaffold(
                backgroundColor: DT.lockdownBg,
                body: SafeArea(child: _body(v, info, metadataMessage)),
              )
            : AppScaffold(
                backgroundColor: OwnerStyle.canvas,
                header: AppHeader.back(
                  title: 'Phòng chờ',
                  onLeading: inLobby ? () => _confirmLeave(v) : null,
                ),
                body: _body(v, info, metadataMessage),
              ),
      ),
    );
  }

  Widget _body(SessionView v, SessionSummary? info, String? metadataMessage) {
    switch (v.phase) {
      case SessionPhase.connecting:
        return const StateMessage(
          icon: Icons.sync,
          tone: StateTone.accent,
          title: 'Đang vào phòng chờ…',
        );
      case SessionPhase.error:
        return StateMessage(
          icon: Icons.block,
          tone: StateTone.danger,
          title: 'Chưa vào được phòng chờ',
          body: sessionEntryError(v.errorCode),
          action: v.errorCode == 'LOBBY_NOT_OPEN' || v.errorCode == null
              ? 'Thử kết nối lại'
              : v.errorCode == 'CONSENT_REQUIRED'
              ? 'Xem nhóm'
              : 'Về trang chủ',
          onAction: () => v.errorCode == 'LOBBY_NOT_OPEN' || v.errorCode == null
              ? ref
                    .read(sessionControllerProvider(widget.sessionId).notifier)
                    .retryEntry()
              : context.go(
                  v.errorCode == 'CONSENT_REQUIRED' ? '/groups' : '/home',
                ),
        );
      case SessionPhase.cancelled:
        return StateMessage(
          icon: Icons.event_busy,
          title: sessionCancellationText(v.cancelReason),
          action: 'Về trang chủ',
          onAction: () => context.go('/home'),
        );
      case SessionPhase.waiting:
        return LobbyView(
          view: v,
          info: info,
          metadataMessage: metadataMessage,
          onLeave: () => _confirmLeave(v),
        );
      case SessionPhase.countdown:
        return CountdownView(view: v, info: info);
      case SessionPhase.absent:
      case SessionPhase.exited:
      case SessionPhase.ended:
        return const StateMessage(
          icon: Icons.hourglass_top,
          title: 'Đang chốt kết quả…',
        );
      case SessionPhase.focusing:
      case SessionPhase.grace:
      case SessionPhase.disconnected:
      case SessionPhase.lost:
        return LockdownView(
          view: v,
          info: info,
          onLeave: () => _confirmLeave(v),
          onDismissBanner: (e) => ref
              .read(sessionControllerProvider(widget.sessionId).notifier)
              .dismissBanner(e),
        );
    }
  }
}

/// V-06 Phòng chờ. Mockup: `session_lobby_1/2`.
class LobbyView extends StatelessWidget {
  const LobbyView({
    super.key,
    required this.view,
    required this.info,
    required this.onLeave,
    this.metadataMessage,
  });
  final SessionView view;
  final SessionSummary? info;
  final VoidCallback onLeave;
  final String? metadataMessage;

  @override
  Widget build(BuildContext context) {
    final t = context.text.apply(
      bodyColor: OwnerStyle.ink,
      displayColor: OwnerStyle.ink,
    );
    final start = view.startedAt ?? info?.startedAt;
    final left = start?.difference(view.serverNow());
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (!view.connected) ...[
                const AppBanner(
                  tone: BannerTone.accent,
                  icon: Icons.sync,
                  text: 'Đang kết nối lại…',
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Bắt đầu sau',
                textAlign: TextAlign.center,
                style: t.bodyMedium!.copyWith(color: OwnerStyle.muted),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  left == null ? '--:--' : mmss(left),
                  key: const Key('lobbyTimer'),
                  style: t.displayMedium!.copyWith(fontFeatures: DT.tabular),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                info?.groupName ?? 'Phiên tập trung',
                style: t.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                start == null
                    ? 'Đang cập nhật giờ bắt đầu'
                    : 'Bắt đầu ${hhmm(start)}',
                textAlign: TextAlign.center,
                style: t.bodyMedium!.copyWith(color: OwnerStyle.muted),
              ),
              Text(
                info == null
                    ? (metadataMessage ?? 'Đang cập nhật thời lượng phiên')
                    : '${info!.durationMin} phút · do chủ nhóm đặt',
                key: const Key('lobbyDuration'),
                textAlign: TextAlign.center,
                style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
              ),
              const SizedBox(height: 16),
              AppCard(
                color: DT.successSoftBg,
                children: [
                  Text(
                    'Thưởng theo kết quả phiên và trần ngày',
                    style: t.labelLarge!.copyWith(color: DT.success),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                color: Colors.white,
                children: [
                  Text('Trong phòng chờ', style: t.titleMedium),
                  Text(
                    view.participantCount == null
                        ? 'Đang cập nhật số người…'
                        : '${view.participantCount} người đã vào phòng chờ',
                    style: t.bodyMedium!.copyWith(color: OwnerStyle.muted),
                  ),
                  if (view.lobbyMembers.isEmpty)
                    Text(
                      'Tên người tham gia sẽ xuất hiện khi được cập nhật.',
                      style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
                    ),
                  if (view.lobbyMembers.isNotEmpty)
                    Wrap(
                      key: const Key('lobbyMembers'),
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final name in view.lobbyMembers)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: OwnerStyle.inset,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(name, style: t.labelLarge),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                color: Colors.white,
                gap: 16,
                children: [
                  Text('Quy tắc phiên', style: t.titleMedium),
                  const InfoRow(
                    icon: Icons.logout,
                    iconColor: DT.warning,
                    title: 'Rời app quá thời gian khoan hồng',
                    subtitle:
                        'Trong phiên đang hoạt động, rời app quá thời gian khoan hồng sẽ ghi nhận bạn rời phiên.',
                  ),
                  const InfoRow(
                    icon: Icons.phone_in_talk_outlined,
                    iconColor: OwnerStyle.muted,
                    title: 'Cuộc gọi và thông báo',
                    subtitle:
                        'Khi đang check-in, bạn có thể xem thông báo hoặc nghe máy rồi quay lại. Khi phiên đã bắt đầu, hãy quay lại trong thời gian khoan hồng.',
                  ),
                  const InfoRow(
                    icon: Icons.group_off_outlined,
                    iconColor: DT.warning,
                    title: 'Cả phiên mất thưởng',
                    subtitle:
                        'Khi có người rời phiên, phiên vẫn tiếp tục nhưng mất thưởng tập thể.',
                  ),
                  InfoRow(
                    icon: Icons.screen_lock_portrait_outlined,
                    iconColor: OwnerStyle.muted,
                    title: kIsWeb
                        ? 'Lưu ý khi dùng bản web'
                        : 'Khóa màn hình trên thiết bị',
                    subtitle: sessionLockGuidance,
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Check-in trước giờ học. Bạn có thể rời rồi quay lại; cần có mặt khi phiên bắt đầu.',
                textAlign: TextAlign.center,
                style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('leaveButton'),
                onPressed: view.leaving ? null : onLeave,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: DT.warning,
                  side: const BorderSide(color: OwnerStyle.line),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Rời phòng chờ'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
    final n = math.max(0, (ms / 1000).ceil());
    return Semantics(
      label: 'Phiên sắp bắt đầu. Còn $n giây',
      child: Padding(
        padding: const EdgeInsets.all(DT.margin),
        child: _SessionScrollable(
          children: [
            const SizedBox(height: DT.spaceSm),
            Text(
              info == null
                  ? 'Đang cập nhật thông tin phiên'
                  : '${info!.groupName ?? 'Phiên tập trung'} · ${info!.durationMin} phút',
              style: lockGrey,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            CountdownRing(
              value: '$n',
              label: 'giây',
              size: 180,
              ringColor: DT.lockdownButton,
              valueKey: const Key('countdownDigit'),
            ),
            const SizedBox(height: DT.spaceLg),
            Text(
              n == 0 ? 'Đang đồng bộ bắt đầu phiên…' : 'Phiên sắp bắt đầu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DT.spaceSm),
            Text(
              'Chưa ghi — bắt đầu ghi lúc ${hhmmss(start)}',
              style: lockGrey,
              textAlign: TextAlign.center,
            ),
            if (!view.connected)
              const Text('Đang kết nối lại…', style: lockGrey),
            const Spacer(),
            const _LockNote(
              icon: Icons.warning_amber_rounded,
              iconColor: _alertRed,
              text:
                  'Ở lại trong app. Rời app sau khi bắt đầu sẽ báo tên bạn cho cả nhóm và làm cả phiên mất thưởng.',
              white: true,
            ),
            const SizedBox(height: DT.spaceSm),
            _LockNote(
              icon: Icons.screen_lock_portrait_outlined,
              text: sessionLockGuidance,
            ),
            if (view.participantCount != null) ...[
              const SizedBox(height: DT.spaceSm),
              _LockNote(
                icon: Icons.groups_outlined,
                text: '${view.participantCount} người đã sẵn sàng',
              ),
            ],
            const SizedBox(height: DT.spaceLg),
          ],
        ),
      ),
    );
  }
}

/// Đỏ sáng cho biểu tượng cảnh báo trên nền đen (mockup `#FF6B5E`, 7.1:1 trên đen).
const _alertRed = Color(0xFFFF6B5E);

class _LockNote extends StatelessWidget {
  const _LockNote({
    required this.icon,
    required this.text,
    this.white = false,
    this.iconColor,
  });
  final IconData icon;
  final String text;
  final bool white;
  final Color? iconColor;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: iconColor ?? DT.lockdownTextSecondary),
      const SizedBox(width: DT.spaceSm),
      Expanded(
        child: Text(
          text,
          style: white
              ? const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 20 / 14,
                )
              : lockGrey,
        ),
      ),
    ],
  );
}

/// V-08 Màn phiên (Lockdown) + lớp V-09/V-10/V-11/LOST. Mockup: `lockdown_mode` — đen tĩnh.
class LockdownView extends StatelessWidget {
  const LockdownView({
    super.key,
    required this.view,
    required this.onLeave,
    required this.onDismissBanner,
    this.info,
  });
  final SessionView view;
  final VoidCallback onLeave;
  final void Function(String eventId) onDismissBanner;
  final SessionSummary? info;

  @override
  Widget build(BuildContext context) {
    final v = view;
    final remaining = v.endsAt?.difference(v.serverNow());
    final lost = v.phase == SessionPhase.lost;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(DT.margin),
          child: _SessionScrollable(
            children: [
              if (v.recording)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: DT.lockdownSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 8),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Phiên đang được ghi',
                          key: Key('recordingIndicator'),
                          style: lockGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              if (v.recording)
                const Text(
                  'Ghi nhận trạng thái và thời gian phiên',
                  style: lockGrey,
                ),
              if (v.banners.isNotEmpty && !lost) ...[
                const SizedBox(height: 16),
                ExitBannerView(
                  banner: v.banners.first,
                  more: v.banners.length - 1,
                  onDismiss: onDismissBanner,
                ),
              ],
              if (info?.groupName != null) ...[
                const SizedBox(height: 16),
                Text(
                  info!.groupName!,
                  style: lockGrey,
                  textAlign: TextAlign.center,
                ),
              ],
              if (info != null)
                Text(
                  '${info!.durationMin} phút theo kế hoạch',
                  style: lockGrey,
                ),
              if (v.participantCount != null)
                Text(
                  '${v.participantCount} người trong phiên',
                  style: lockGrey,
                ),
              const SizedBox(height: 32),
              Text(
                lost ? 'Phần tham gia đã kết thúc' : 'Thời gian còn lại',
                style: lockGrey,
              ),
              const SizedBox(height: DT.spaceSm),
              if (!lost)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    remaining == null ? '--:--' : mmss(remaining),
                    key: const Key('remaining'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      fontFeatures: DT.tabular,
                    ),
                  ),
                ),
              if (v.endsAt != null && !lost) ...[
                const SizedBox(height: DT.spaceSm),
                Text('Kết thúc lúc ${hhmm(v.endsAt)}', style: lockGrey),
              ],
              if (v.forfeited)
                const Padding(
                  padding: EdgeInsets.only(top: DT.spaceSm),
                  child: Text(
                    'Phiên đã mất thưởng tập thể',
                    key: Key('forfeitedLabel'),
                    style: lockGrey,
                  ),
                ),
              const Spacer(),
              if (lost)
                Container(
                  padding: const EdgeInsets.all(DT.spaceLg),
                  decoration: lockPanelDecoration(),
                  child: Column(
                    children: [
                      const Text(
                        'Bạn đã mất kết nối quá lâu. Phần tham gia của bạn kết thúc với trạng thái Mất kết nối. '
                        'Kết quả và phần thưởng sẽ được chốt sau. Mất mạng tự nó không làm nhóm mất thưởng.',
                        style: lockWhite,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DT.spaceMd),
                      _SessionDarkButton(
                        label: 'Về trang chủ',
                        onPressed: () => context.go('/home'),
                      ),
                    ],
                  ),
                )
              else ...[
                const _LockNote(
                  icon: Icons.warning_amber_rounded,
                  iconColor: _alertRed,
                  text:
                      'Rời app quá thời gian khoan hồng sẽ ghi nhận bạn rời phiên và làm cả phiên mất thưởng.',
                  white: true,
                ),
                const SizedBox(height: DT.spaceSm),
                _LockNote(
                  icon: Icons.screen_lock_portrait_outlined,
                  text: sessionLockGuidance,
                ),
                const SizedBox(height: DT.spaceMd),
                _SessionDarkButton(
                  key: const Key('leaveButton'),
                  icon: Icons.logout,
                  label: 'Rời phiên',
                  onPressed: v.leaving ? null : onLeave,
                ),
                TextButton(
                  onPressed: () => context.push('/leave-group'),
                  style: TextButton.styleFrom(
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: const Text(
                    'Rút đồng ý và rời nhóm',
                    style: TextStyle(
                      color: DT.lockdownTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (v.phase == SessionPhase.grace)
          Positioned.fill(
            child: GraceOverlay(view: v, onLeave: onLeave),
          ),
        if (v.phase == SessionPhase.disconnected)
          const Positioned.fill(child: DisconnectedOverlay()),
      ],
    );
  }
}

/// V-11 Banner người thoát — hiện/ẩn tức thì, không hoạt ảnh.
class ExitBannerView extends StatelessWidget {
  const ExitBannerView({
    super.key,
    required this.banner,
    required this.more,
    required this.onDismiss,
  });
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.campaign_outlined, color: Colors.white),
            const SizedBox(width: DT.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  if (banner.triggeredForfeit)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Bạn vẫn hoàn thành phiên nếu ở lại đến hết giờ.',
                        style: lockGrey,
                      ),
                    ),
                  if (more > 0) Text('+$more thông báo khác', style: lockGrey),
                ],
              ),
            ),
          ],
        ),
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
    final left = d == null
        ? null
        : math.max(
            0,
            (d.difference(view.serverNow()).inMilliseconds / 1000).ceil(),
          );
    return ColoredBox(
      color: DT.lockdownBg,
      child: Padding(
        key: const Key('graceOverlay'),
        padding: const EdgeInsets.all(DT.spaceLg),
        child: _SessionScrollable(
          children: [
            const Spacer(),
            const Text(
              'Bạn vừa rời DropIt!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DT.spaceLg),
            CountdownRing(value: left == null ? '–' : '$left', label: 'giây'),
            const SizedBox(height: DT.spaceLg),
            const Text(
              'Hết thời gian khoan hồng, tên bạn sẽ được báo cho cả nhóm và mọi người trong phiên. '
              'Cả phiên mất thưởng tập thể.',
              style: lockGrey,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DT.spaceSm),
            const Text(
              'Ở lại trong app để tiếp tục phiên. Quay lại trước thời hạn để tiếp tục.',
              style: lockGrey,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (onLeave != null) ...[
              _SessionDarkButton(
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
          ],
        ),
      ),
    );
  }
}

/// V-10 Mất kết nối.
class DisconnectedOverlay extends StatelessWidget {
  const DisconnectedOverlay({super.key});
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: DT.lockdownBg,
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          key: const Key('disconnectedOverlay'),
          padding: const EdgeInsets.all(24),
          decoration: lockPanelDecoration(),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 36),
              SizedBox(height: 12),
              Text(
                'Đang kết nối lại…',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ở lại trong app để kết nối lại. Mất mạng không tính là chủ động rời app và tự nó không làm cả phiên mất thưởng.',
                style: lockGrey,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String get sessionLockGuidance => kIsWeb
    ? 'Bản web có thể xem chuyển tab hoặc ẩn trang là rời app; không đảm bảo phân biệt khóa màn hình.'
    : 'Ứng dụng hỗ trợ nhận biết khóa màn hình trên thiết bị tương thích. Giữ phiên mở khi quay lại.';

String sessionCancellationText(String? reason) => switch (reason) {
  'SERVER_OUTAGE' =>
    'Phiên đã hủy do sự cố hệ thống. Kết quả sẽ được chốt theo trạng thái tham gia của bạn.',
  'REMOVED' => 'Bạn không còn ở nhóm này.',
  'NO_ATTENDEE' => 'Phiên đã hủy vì không có thành viên vào phòng chờ.',
  'OWNER_CANCEL' => 'Chủ nhóm đã hủy phiên này.',
  _ => 'Phiên đã hủy.',
};

String sessionEntryError(String? code) => switch (code) {
  'CONSENT_REQUIRED' => 'Bạn cần đồng ý tham gia nhóm trước khi vào phiên.',
  'LOBBY_NOT_OPEN' =>
    'Check-in mở ngay khi phiên được đặt lịch. Bạn có thể vào sớm, rời phòng chờ rồi quay lại trước giờ bắt đầu.',
  'LATE_JOIN_CLOSED' => 'Phiên đã bắt đầu. Thời gian vào phiên đã đóng.',
  'SESSION_NOT_ACTIVE' =>
    'Phiên đã kết thúc hoặc bị hủy. Xem lịch sử để kiểm tra kết quả.',
  'FORBIDDEN_GROUP' => 'Bạn không còn là thành viên của nhóm này.',
  'UNAUTHENTICATED' => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
  'SESSION_NOT_FOUND' => 'Không tìm thấy phiên này.',
  'NOT_MEMBER' || 'FORBIDDEN' => 'Bạn không có quyền tham gia phiên này.',
  'SESSION_ALREADY_ACTIVE' || 'ALREADY_JOINED' =>
    'Phiên đang hoạt động. Vui lòng mở lại phiên từ trang chủ để kết nối lại.',
  _ =>
    'Kết nối phiên chưa hoàn tất. Về trang chủ rồi mở lại phiên để tiếp tục.',
};

class _SessionScrollable extends StatelessWidget {
  const _SessionScrollable({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(child: Column(children: children)),
      ),
    ),
  );
}

class _SessionDarkButton extends StatelessWidget {
  const _SessionDarkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: DT.lockdownSurface,
      side: const BorderSide(color: DT.lockdownButton),
      minimumSize: const Size.fromHeight(56),
      splashFactory: NoSplash.splashFactory,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Flexible(
            child: Text(label, textAlign: TextAlign.center, style: lockWhite),
          ),
        ],
      ),
    ),
  );
}
