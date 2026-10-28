import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_lifecycle/focus_lifecycle.dart';
import 'package:uuid/uuid.dart';

import '../../core/auth.dart';
import '../../core/providers.dart';
import '../../core/socket.dart';

/// Pha hiển thị phía client (phản chiếu `my_state` server — server quyết định).
enum SessionPhase {
  connecting, // chưa có ack session:join
  waiting, // V-06
  countdown, // V-07
  focusing, // V-08
  grace, // V-09
  disconnected, // V-10
  lost, // V-10 khối LOST
  exited, // tự rời / hết khoan hồng → V-13
  absent, // rời phòng chờ → V-03
  ended, // phiên chốt → V-12/V-14
  cancelled, // chủ nhóm hủy / sự cố
  error, // không vào được (LOBBY_NOT_OPEN, CONSENT_REQUIRED…)
}

class ExitBanner {
  const ExitBanner({
    required this.eventId,
    required this.name,
    required this.at,
    required this.triggeredForfeit,
  });
  final String eventId;
  final String name;
  final DateTime? at;

  /// Lần thoát khởi phát mất thưởng tập thể (MEMBER_EXITED kèm `forfeited`).
  final bool triggeredForfeit;
}

class SessionView {
  const SessionView({
    this.phase = SessionPhase.connecting,
    this.connected = false,
    this.startedAt,
    this.endsAt,
    this.participantCount,
    this.forfeited = false,
    this.forfeitTriggerName,
    this.graceDeadline,
    this.offset = Duration.zero,
    this.banners = const [],
    this.errorCode,
    this.errorMessage,
    this.leaveError,
    this.leaving = false,
    this.screenLocked = false,
    this.cancelReason,
    this.lobbyMembers = const [],
  });

  final SessionPhase phase;
  final bool connected;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final int? participantCount;
  final bool forfeited;
  final String? forfeitTriggerName;
  final DateTime? graceDeadline;

  /// giờ server − giờ máy (BR-03: chỉ dùng hiển thị).
  final Duration offset;
  final List<ExitBanner> banners;
  final String? errorCode;
  final String? errorMessage;
  final String? leaveError;
  final bool leaving;
  final bool screenLocked;
  final String? cancelReason;

  /// Tên người đang ở phòng chờ (session:state.lobby_members) — chỉ tên, không trạng thái khác (NFR-P06).
  final List<String> lobbyMembers;

  /// Có trạng thái chưa kết thúc (WAITING/FOCUSING/GRACE/DISCONNECTED) → khóa Đăng xuất (BR-70).
  bool get isLive =>
      phase == SessionPhase.waiting ||
      phase == SessionPhase.countdown ||
      phase == SessionPhase.focusing ||
      phase == SessionPhase.grace ||
      phase == SessionPhase.disconnected;

  /// "Phiên đang được ghi" khi và chỉ khi đang trong phiên ACTIVE (NFR-P08).
  bool get recording =>
      phase == SessionPhase.focusing ||
      phase == SessionPhase.grace ||
      phase == SessionPhase.disconnected;

  bool get canLeave =>
      phase == SessionPhase.waiting ||
      phase == SessionPhase.focusing ||
      phase == SessionPhase.grace;

  DateTime serverNow([DateTime? deviceNow]) =>
      (deviceNow ?? DateTime.now()).toUtc().add(offset);

  SessionView copyWith({
    SessionPhase? phase,
    bool? connected,
    DateTime? startedAt,
    DateTime? endsAt,
    int? participantCount,
    bool? forfeited,
    String? forfeitTriggerName,
    DateTime? graceDeadline,
    Duration? offset,
    List<ExitBanner>? banners,
    String? errorCode,
    String? errorMessage,
    String? leaveError,
    bool clearLeaveError = false,
    bool? leaving,
    bool? screenLocked,
    String? cancelReason,
    List<String>? lobbyMembers,
  }) => SessionView(
    phase: phase ?? this.phase,
    connected: connected ?? this.connected,
    startedAt: startedAt ?? this.startedAt,
    endsAt: endsAt ?? this.endsAt,
    participantCount: participantCount ?? this.participantCount,
    forfeited: forfeited ?? this.forfeited,
    forfeitTriggerName: forfeitTriggerName ?? this.forfeitTriggerName,
    graceDeadline: graceDeadline ?? this.graceDeadline,
    offset: offset ?? this.offset,
    banners: banners ?? this.banners,
    errorCode: errorCode ?? this.errorCode,
    errorMessage: errorMessage ?? this.errorMessage,
    leaveError: clearLeaveError ? null : (leaveError ?? this.leaveError),
    leaving: leaving ?? this.leaving,
    screenLocked: screenLocked ?? this.screenLocked,
    cancelReason: cancelReason ?? this.cancelReason,
    lobbyMembers: lobbyMembers ?? this.lobbyMembers,
  );
}

/// Nguồn tín hiệu rời app/khóa màn hình (bọc package focus_lifecycle để test).
abstract class FocusWatcher {
  Stream<FocusSignal> get signals;
  Future<void> start();
  Future<void> stop();
}

class PackageFocusWatcher implements FocusWatcher {
  final _fl = FocusLifecycle();
  @override
  Stream<FocusSignal> get signals => _fl.signals;
  @override
  Future<void> start() => _fl.start();
  @override
  Future<void> stop() => _fl.stop();
}

final focusWatcherFactoryProvider = Provider<FocusWatcher Function()>(
  (ref) => PackageFocusWatcher.new,
);

const heartbeatInterval = Duration(seconds: 5); // BR-19 heartbeat_s

/// Notifier duy nhất của màn phiên (design/01-kien-truc.md §3.2).
class SessionController extends Notifier<SessionView> {
  SessionController(this.sessionId);
  final String sessionId;

  static const _uuid = Uuid();
  SessionSocket? _socket;
  StreamSubscription<SocketEvent>? _sub;
  FocusWatcher? _watcher;
  StreamSubscription<FocusSignal>? _focusSub;
  Timer? _hb;
  Timer? _tick;
  Timer? _entryRetry;
  bool _joined = false;
  String? _lastServerEventId;
  final _seen = <String>{};
  final _pending = <(String, Map<String, dynamic>)>[];

  @override
  SessionView build() {
    final auth = ref.read(authProvider);
    final socket = ref.read(sessionSocketFactoryProvider)(
      token: auth.token ?? '',
      deviceId: auth.deviceId,
    );
    _socket = socket;
    _sub = socket.events.listen(_onEvent);
    ref.onDispose(_dispose);
    final live = ref.read(liveSessionProvider.notifier);
    listenSelf((_, next) {
      if (next.isLive) {
        live.set(sessionId);
      } else {
        live.clearIf(sessionId);
      }
    });
    // Không được sửa provider khác trong onDispose → dời sang microtask (container có thể đã hủy).
    ref.onDispose(
      () => scheduleMicrotask(() {
        try {
          live.clearIf(sessionId);
        } catch (_) {}
      }),
    );
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) => _onTick());
    scheduleMicrotask(socket.connect);
    return const SessionView();
  }

  void _dispose() {
    _entryRetry?.cancel();
    _tick?.cancel();
    _hb?.cancel();
    _focusSub?.cancel();
    _watcher?.stop();
    _sub?.cancel();
    _socket?.dispose();
  }

  Map<String, dynamic> _env([Map<String, dynamic> extra = const {}]) => {
    'event_id': _uuid.v4(),
    'session_id': sessionId,
    'client_ts': DateTime.now().toUtc().toIso8601String(),
    ...extra,
  };

  // ---------------- Sự kiện vào ----------------
  void _onEvent(SocketEvent e) {
    final d = e.data;
    final sid = d['session_id'];
    if (sid != null && sid != sessionId) return;
    final eid = d['event_id'] as String?;
    if (eid != null && !e.name.startsWith('_')) {
      if (_seen.contains(eid)) return; // khử trùng khi phát lại (§3.4)
      _seen.add(eid);
      _lastServerEventId = eid;
    }
    switch (e.name) {
      case '_connect':
        state = state.copyWith(connected: true);
        _joinOrResume();
      case '_disconnect':
        state = state.copyWith(
          connected: false,
          phase: state.phase == SessionPhase.focusing
              ? SessionPhase.disconnected
              : null,
        );
      case '_connect_error':
        state = state.copyWith(connected: false);
        if (!_joined && d['code'] == 'UNAUTHENTICATED') {
          _fail(
            'UNAUTHENTICATED',
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          );
        }
      case 'session:state':
        _applyServerState(d);
      case 'session:countdown':
        state = state.copyWith(
          phase: SessionPhase.countdown,
          startedAt: _dt(d['started_at']),
          offset: _offsetFrom(d['server_ts']),
        );
      case 'member:grace':
        state = state.copyWith(
          phase: SessionPhase.grace,
          graceDeadline: _dt(d['grace_deadline']),
        );
      case 'member:state':
        _applyMyState('${d['my_state']}');
      case 'MEMBER_EXITED':
        _onMemberExited(d);
      case 'SESSION_CANCELLED':
      case 'SESSION_CANCELLED_OUTAGE':
      case 'SESSION_CANCELLED_OUTAGE_EXITED':
        state = state.copyWith(
          phase: SessionPhase.cancelled,
          cancelReason: '${d['reason'] ?? e.name}',
        );
        _stopRecording();
      case 'SESSION_RESULT':
        state = state.copyWith(phase: SessionPhase.ended);
        _stopRecording();
      case 'SESSION_UPDATED':
        // Chủ nhóm đổi giờ/thời lượng (US-02.11): phòng chờ cũ đóng, vào lại theo giờ mới.
        _fail(
          'SESSION_RESCHEDULED',
          'Chủ nhóm vừa đổi giờ phiên. Vào lại phòng chờ theo giờ mới.',
        );
        _stopRecording();
      case 'MEMBER_REMOVED':
        state = state.copyWith(
          phase: SessionPhase.cancelled,
          cancelReason: 'REMOVED',
        );
        _stopRecording();
      case 'error':
        if (d['code'] == 'TOKEN_EXPIRED') {
          state = state.copyWith(connected: false);
        }
    }
  }

  Future<void> _joinOrResume() async {
    _entryRetry?.cancel();
    _syncClock();
    final first = !_joined;
    var ack = await _requestRetry(
      first ? 'session:join' : 'session:resume',
      _env({
        if (!first && _lastServerEventId != null)
          'last_server_event_id': _lastServerEventId,
      }),
    );
    // Mở lại màn tạo controller mới: server vẫn giữ trạng thái người đã vào.
    if (first &&
        ack?['ok'] == false &&
        ack?['code'] == 'SESSION_NOT_ACTIVE' &&
        ack?['state'] != null) {
      ack = await _requestRetry('session:resume', _env());
    }
    if (!ref.mounted || _entryFinished) return;
    if (ack == null) {
      // An ack timeout does not imply a transport disconnect. Retry even when
      // Socket.IO remains connected, otherwise the lobby can stall until start.
      _entryRetry = Timer(const Duration(seconds: 2), () {
        if (ref.mounted && !_entryFinished && _socket?.connected == true) {
          _joinOrResume();
        }
      });
      return;
    }
    if (ack['ok'] == false) {
      final code = '${ack['code']}';
      if (code == 'LOBBY_NOT_OPEN') {
        final opens = _dt(ack['lobby_opens_at'] ?? ack['detail']);
        _fail(code, _joinErrorText(code));
        final wait =
            opens?.difference(state.serverNow()) ?? const Duration(seconds: 5);
        _entryRetry = Timer(
          wait.isNegative ? const Duration(seconds: 1) : wait,
          () {
            if (ref.mounted && !_entryFinished) retryEntry();
          },
        );
        return;
      }
      if (code == 'SESSION_LOST') {
        _applyMyState('LOST');
      } else if (ack['state'] == 'EXITED' ||
          ack['state'] == 'ABSENT' ||
          ack['state'] == 'COMPLETED' ||
          ack['state'] == 'VOID') {
        _applyMyState('${ack['state']}');
      } else if (first) {
        _fail(code, '${ack['detail'] ?? _joinErrorText(code)}');
      }
      return;
    }
    _joined = true;
    if (ack['state'] != null) _applyMyState('${ack['state']}');
    _flushPending();
  }

  static String _joinErrorText(String code) => switch (code) {
    'LOBBY_NOT_OPEN' => 'Phòng chờ chưa mở.',
    'LATE_JOIN_CLOSED' => 'Phiên đã bắt đầu. Bạn không vào được phiên này.',
    'OWNER_CANNOT_JOIN_SESSION' => 'Chủ nhóm không tham gia phiên.',
    'CONSENT_REQUIRED' =>
      'Bạn cần đồng ý điều khoản của nhóm trước khi vào phiên.',
    'FORBIDDEN_GROUP' => 'Bạn không thuộc nhóm của phiên này.',
    'SESSION_ALREADY_JOINED_ELSEWHERE' =>
      'Phiên này đang mở trên thiết bị khác.',
    'ALREADY_IN_OTHER_SESSION' => 'Bạn đang ở một phiên khác.',
    'SESSION_NOT_ACTIVE' => 'Phiên đã kết thúc hoặc bị hủy.',
    _ => 'Chưa vào được phòng chờ.',
  };

  bool get _entryFinished => const {
    SessionPhase.cancelled,
    SessionPhase.ended,
    SessionPhase.exited,
    SessionPhase.absent,
    SessionPhase.lost,
  }.contains(state.phase);

  void retryEntry() {
    if (_entryFinished) return;
    state = state.copyWith(phase: SessionPhase.connecting);
    if (_socket?.connected == true) {
      _joinOrResume();
    } else {
      _socket?.connect();
    }
  }

  void _fail(String code, String msg) {
    state = state.copyWith(
      phase: SessionPhase.error,
      errorCode: code,
      errorMessage: msg,
    );
  }

  void _syncClock() async {
    final t0 = DateTime.now();
    final r = await _socket?.request('clock:ping', {
      't0': t0.millisecondsSinceEpoch,
    });
    if (r == null || r['server_ts'] == null) return;
    final t1 = DateTime.now();
    final server = _dt(r['server_ts']);
    if (server == null) return;
    final mid = t0.add(t1.difference(t0) ~/ 2).toUtc();
    state = state.copyWith(offset: server.difference(mid));
  }

  void _applyServerState(Map<String, dynamic> d) {
    final ft = d['forfeit_trigger_display_name'] as String?;
    state = state.copyWith(
      startedAt: _dt(d['started_at']),
      endsAt: _dt(d['ends_at']),
      participantCount: (d['participant_count'] as num?)?.toInt(),
      lobbyMembers: d['lobby_members'] is List
          ? [for (final n in d['lobby_members'] as List) '$n']
          : null,
      forfeited: d['forfeited'] == true ? true : null,
      forfeitTriggerName: ft,
      graceDeadline: _dt(d['my_grace_deadline']),
      offset: state.offset == Duration.zero
          ? _offsetFrom(d['server_ts'])
          : null,
    );
    final status = '${d['status'] ?? ''}';
    if (status == 'CANCELLED') {
      state = state.copyWith(
        phase: SessionPhase.cancelled,
        cancelReason: '${d['cancel_reason'] ?? ''}',
      );
      _stopRecording();
      return;
    }
    final my = d['my_state'] as String?;
    if (my != null) {
      _applyMyState(my, sessionStatus: status);
    } else if (status == 'COUNTDOWN' && state.phase == SessionPhase.waiting) {
      state = state.copyWith(phase: SessionPhase.countdown);
    }
  }

  void _applyMyState(String my, {String? sessionStatus}) {
    final p = switch (my) {
      'WAITING' =>
        sessionStatus == 'COUNTDOWN'
            ? SessionPhase.countdown
            : SessionPhase.waiting,
      'FOCUSING' || 'PAUSED' => SessionPhase.focusing,
      'GRACE' => SessionPhase.grace,
      'DISCONNECTED' => SessionPhase.disconnected,
      'LOST' => SessionPhase.lost,
      'EXITED' => SessionPhase.exited,
      'ABSENT' => SessionPhase.absent,
      'COMPLETED' || 'WITHDRAWN' => SessionPhase.ended,
      'VOID' => SessionPhase.cancelled,
      _ => null,
    };
    if (p == null) return;
    // Không lùi từ countdown về waiting khi server chưa đổi trạng thái người.
    if (p == SessionPhase.waiting && state.phase == SessionPhase.countdown) {
      return;
    }
    state = state.copyWith(phase: p);
    if (state.recording) {
      _startRecording();
    } else if (p != SessionPhase.waiting && p != SessionPhase.countdown) {
      _stopRecording();
    }
  }

  void _onMemberExited(Map<String, dynamic> d) {
    final name = '${d['exited_display_name'] ?? ''}';
    final f = d['forfeited'];
    final triggered = f is Map || f == true;
    final b = ExitBanner(
      eventId: '${d['event_id'] ?? _uuid.v4()}',
      name: name,
      at: _dt(d['exited_at']),
      triggeredForfeit: triggered,
    );
    state = state.copyWith(
      banners: [...state.banners, b],
      forfeited: triggered || state.forfeited,
      forfeitTriggerName: triggered
          ? (f is Map ? '${f['display_name'] ?? name}' : name)
          : null,
    );
  }

  /// Người dùng vuốt ẩn hoặc hết 6 giây (V-11, giả định).
  void dismissBanner(String eventId) {
    state = state.copyWith(
      banners: state.banners.where((b) => b.eventId != eventId).toList(),
    );
  }

  void _onTick() {
    final s = state;
    // Đến started_at (giờ server) → vào phiên (V-07 → V-08). Server xác nhận sau.
    if (s.phase == SessionPhase.countdown &&
        s.startedAt != null &&
        !s.serverNow().isBefore(s.startedAt!)) {
      state = s.copyWith(
        phase: s.connected ? SessionPhase.focusing : SessionPhase.disconnected,
      );
      _startRecording();
    }
  }

  // ---------------- Ghi phiên ----------------
  void _startRecording() {
    if (_watcher != null) return;
    final w = ref.read(focusWatcherFactoryProvider)();
    _watcher = w;
    _focusSub = w.signals.listen(_onFocusSignal);
    w.start();
    _hb = Timer.periodic(heartbeatInterval, (_) {
      if (_socket?.connected == true && !state.screenLocked) {
        _socket!.send('heartbeat', {'session_id': sessionId});
      }
    });
  }

  void _stopRecording() {
    _hb?.cancel();
    _hb = null;
    _focusSub?.cancel();
    _focusSub = null;
    _watcher?.stop();
    _watcher = null;
  }

  void _onFocusSignal(FocusSignal s) {
    switch (s.type) {
      case FocusSignalType.leftApp:
        _emit('member:left_app', {'trigger': s.trigger});
      case FocusSignalType.returned:
        _emit('member:returned');
      case FocusSignalType.screenLocked:
        state = state.copyWith(screenLocked: true);
        _emit('member:screen_locked');
      case FocusSignalType.screenUnlocked:
        state = state.copyWith(screenLocked: false);
        _emit('member:screen_unlocked');
    }
  }

  /// Gửi sự kiện vòng đời; mất mạng → xếp hàng kèm `event_id` (§3.4 của 01).
  Future<void> _emit(String ev, [Map<String, dynamic> extra = const {}]) async {
    final payload = _env(extra);
    if (_socket?.connected != true) {
      _pending.add((ev, payload));
      return;
    }
    final ack = await _requestRetry(ev, payload);
    if (ack == null) {
      _pending.add((ev, payload));
      return;
    }
    if (ack['ok'] != false && ack['state'] != null) {
      _applyMyState('${ack['state']}');
    }
  }

  void _flushPending() {
    final items = List.of(_pending);
    _pending.clear();
    for (final (ev, p) in items) {
      _requestRetry(ev, p).then((ack) {
        if (ack != null && ack['ok'] != false && ack['state'] != null) {
          _applyMyState('${ack['state']}');
        }
      });
    }
  }

  /// Chờ ack ≤ 5 s rồi gửi lại **cùng** `event_id` một lần (§3.1).
  Future<Map<String, dynamic>?> _requestRetry(
    String ev,
    Map<String, dynamic> p,
  ) async {
    final s = _socket;
    if (s == null) return null;
    final a = await s.request(ev, p);
    if (a != null || !s.connected) return a;
    return s.request(ev, p);
  }

  // ---------------- Lệnh người dùng ----------------
  /// "Rời phiên" đã xác nhận. Không có mạng → báo lỗi, không xếp hàng (BR-118, D-29).
  Future<bool> leave() async {
    if (!state.canLeave || state.leaving) return false;
    if (_socket?.connected != true) {
      state = state.copyWith(leaveError: 'Chưa rời phiên — không có kết nối.');
      return false;
    }
    state = state.copyWith(leaving: true, clearLeaveError: true);
    final ack = await _requestRetry('session:leave', _env());
    if (ack == null || ack['ok'] == false) {
      state = state.copyWith(
        leaving: false,
        leaveError: '${ack?['detail'] ?? 'Chưa rời phiên — không có kết nối.'}',
      );
      return false;
    }
    state = state.copyWith(leaving: false);
    if (ack['left_lobby'] == true) return true;
    final st = '${ack['state'] ?? ''}';
    if (st == 'ABSENT') {
      _applyMyState('ABSENT');
    } else {
      _applyMyState(st.isEmpty ? 'EXITED' : st);
    }
    return false;
  }

  void clearLeaveError() => state = state.copyWith(clearLeaveError: true);

  static DateTime? _dt(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toUtc() : null;

  Duration? _offsetFrom(Object? serverTs) {
    final s = _dt(serverTs);
    return s?.difference(DateTime.now().toUtc());
  }
}

final sessionControllerProvider = NotifierProvider.autoDispose
    .family<SessionController, SessionView, String>(SessionController.new);
