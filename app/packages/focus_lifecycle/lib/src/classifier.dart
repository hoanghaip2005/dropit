import 'dart:async';

/// Loại tín hiệu gửi lên server (tên sự kiện socket ở design/03-api-socket.md §3.2).
enum FocusSignalType {
  /// `member:left_app` — vào nền mà không có tín hiệu khóa màn hình.
  leftApp,

  /// `member:returned` — quay lại app sau khi đã báo rời.
  returned,

  /// `member:screen_locked`.
  screenLocked,

  /// `member:screen_unlocked`.
  screenUnlocked,
}

class FocusSignal {
  const FocusSignal(this.type, this.trigger);
  final FocusSignalType type;

  /// Tín hiệu gốc gây ra (chỉ để log, không chứa dữ liệu ngoài app).
  final String trigger;

  @override
  String toString() => 'FocusSignal(${type.name}, $trigger)';
}

/// Trạng thái vòng đời Flutter mà bộ phân loại quan tâm (tách khỏi
/// `AppLifecycleState` để test thuần Dart).
enum HostLifecycle { resumed, inactive, hidden, paused, detached }

/// Trạng thái cục bộ của bộ phân loại.
enum LocalFocusState { idle, focusing, left, locked }

/// Bộ phân loại LOCK vs LEAVE (từ spike T-01, `session_controller.dart`).
///
/// Quy tắc:
/// - Android: `process_stop` + (`interactive == false` hoặc `keyguardLocked`) → LOCK;
///   `screen_off` → LOCK; `user_present` → mở khóa.
/// - iOS: `scene_did_enter_background` + `protectedDataAvailable == false` → LOCK;
///   `protected_data_unavailable` → LOCK; `protected_data_available` → mở khóa.
///   `inactive` đơn thuần (kéo Trung tâm thông báo) không tính.
/// - Còn lại `paused`/`hidden`/vào nền → chờ [lockWait] xem có tín hiệu khóa;
///   không có → LEAVE. `resumed` → RETURN (nếu đã LEAVE).
/// - `detached` (vuốt tắt) → LEAVE ngay (cố gắng).
///
/// Server mới là bên quyết định GRACE/EXITED theo giờ server (BR-03, BR-33).
class LockLeaveClassifier {
  LockLeaveClassifier({
    required this.onSignal,
    this.lockWait = const Duration(milliseconds: 600),
    bool Function()? isForeground,
  }) : _isForeground = isForeground ?? (() => true);

  final void Function(FocusSignal) onSignal;
  final Duration lockWait;
  final bool Function() _isForeground;

  LocalFocusState _state = LocalFocusState.idle;
  bool _screenLocked = false;
  Timer? _pendingLeave;

  LocalFocusState get state => _state;
  bool get screenLocked => _screenLocked;
  bool get active => _state != LocalFocusState.idle;

  /// Bắt đầu phân loại (chỉ khi phiên đang ghi — NFR-P02).
  void start() {
    _state = LocalFocusState.focusing;
    _screenLocked = false;
  }

  void stop() {
    _pendingLeave?.cancel();
    _state = LocalFocusState.idle;
    _screenLocked = false;
  }

  void onHostLifecycle(HostLifecycle s) {
    if (!active) return;
    switch (s) {
      case HostLifecycle.resumed:
        _onForeground();
      case HostLifecycle.paused:
      case HostLifecycle.hidden:
        _onBackground('flutter:${s.name}');
      case HostLifecycle.detached:
        if (_state == LocalFocusState.focusing) {
          _pendingLeave?.cancel();
          _state = LocalFocusState.left;
          onSignal(const FocusSignal(FocusSignalType.leftApp, 'detached'));
        }
      case HostLifecycle.inactive:
        break; // iOS: kéo Trung tâm thông báo/điều khiển → không tính.
    }
  }

  void onNative(Map<dynamic, dynamic> m) {
    if (!active) return;
    final ev = '${m['event']}';
    switch (ev) {
      case 'screen_off':
      case 'protected_data_unavailable':
        _onLocked(ev);
      case 'user_present':
      case 'protected_data_available':
        _onUnlocked(ev);
      case 'process_stop':
        if (m['interactive'] == false || m['keyguardLocked'] == true) {
          _onLocked('process_stop_noninteractive');
        } else {
          _onBackground('native:process_stop');
        }
      case 'scene_did_enter_background':
        if (m['protectedDataAvailable'] == false) {
          _onLocked('bg_protected_unavailable');
        } else {
          _onBackground('native:scene_did_enter_background');
        }
      case 'process_start':
      case 'scene_did_become_active':
        _onForeground();
    }
  }

  void _onBackground(String why) {
    if (_screenLocked || _state != LocalFocusState.focusing) return;
    if (_pendingLeave?.isActive == true) return;
    _pendingLeave = Timer(lockWait, () {
      if (_screenLocked || _state != LocalFocusState.focusing) return;
      _state = LocalFocusState.left;
      onSignal(FocusSignal(FocusSignalType.leftApp, why));
    });
  }

  void _onLocked(String why) {
    if (_screenLocked) return;
    _pendingLeave?.cancel();
    _screenLocked = true;
    _state = LocalFocusState.locked;
    onSignal(FocusSignal(FocusSignalType.screenLocked, why));
  }

  void _onUnlocked(String why) {
    if (!_screenLocked) return;
    _screenLocked = false;
    onSignal(FocusSignal(FocusSignalType.screenUnlocked, why));
    _state = LocalFocusState.focusing;
    if (!_isForeground()) _onBackground('unlocked_not_foreground');
  }

  void _onForeground() {
    _pendingLeave?.cancel();
    if (_screenLocked) return; // chờ user_present / protected_data_available
    if (_state == LocalFocusState.left) {
      onSignal(const FocusSignal(FocusSignalType.returned, 'resumed'));
    }
    _state = LocalFocusState.focusing;
  }

  void dispose() => stop();
}
