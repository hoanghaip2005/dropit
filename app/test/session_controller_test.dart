import 'dart:async';

import 'package:dropit/core/auth.dart';
import 'package:dropit/core/socket.dart';
import 'package:dropit/features/session/session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_lifecycle/focus_lifecycle.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSocket implements SessionSocket {
  final ctrl = StreamController<SocketEvent>.broadcast(sync: true);
  final sent = <(String, Map<String, dynamic>)>[];
  final volatile = <String>[];
  bool _connected = false;
  Map<String, dynamic>? Function(String, Map<String, dynamic>) reply = (e, p) => {'ok': true};

  @override
  Stream<SocketEvent> get events => ctrl.stream;
  @override
  bool get connected => _connected;

  @override
  void connect() {
    _connected = true;
    ctrl.add(const SocketEvent('_connect'));
  }

  void drop() {
    _connected = false;
    ctrl.add(const SocketEvent('_disconnect', {'reason': 'transport close'}));
  }

  void server(String name, Map<String, dynamic> data) => ctrl.add(SocketEvent(name, data));

  @override
  Future<Map<String, dynamic>?> request(String event, Map<String, dynamic> payload,
      {Duration timeout = const Duration(seconds: 5)}) async {
    sent.add((event, payload));
    return reply(event, payload);
  }

  @override
  void send(String event, Map<String, dynamic> payload) => volatile.add(event);
  @override
  void dispose() => ctrl.close();

  List<String> names() => sent.map((e) => e.$1).where((n) => n != 'clock:ping').toList();
}

class FakeWatcher implements FocusWatcher {
  final ctrl = StreamController<FocusSignal>.broadcast(sync: true);
  bool started = false;
  @override
  Stream<FocusSignal> get signals => ctrl.stream;
  @override
  Future<void> start() async => started = true;
  @override
  Future<void> stop() async => started = false;
}

const sid = 's-1';

void main() {
  late FakeSocket socket;
  late FakeWatcher watcher;
  late ProviderContainer c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'dev_token': 't', 'onboarded': true});
    final prefs = await SharedPreferences.getInstance();
    socket = FakeSocket();
    watcher = FakeWatcher();
    socket.reply = (e, p) => switch (e) {
          'session:join' => {'ok': true, 'state': 'WAITING'},
          _ => {'ok': true},
        };
    c = ProviderContainer(overrides: [
      prefsProvider.overrideWithValue(prefs),
      sessionSocketFactoryProvider.overrideWithValue(({required String token, required String deviceId}) => socket),
      focusWatcherFactoryProvider.overrideWithValue(() => watcher),
    ]);
  });

  tearDown(() => c.dispose());

  Future<SessionView> boot() async {
    c.listen(sessionControllerProvider(sid), (_, _) {});
    await pumpEventQueue();
    return c.read(sessionControllerProvider(sid));
  }

  SessionController ctl() => c.read(sessionControllerProvider(sid).notifier);
  SessionView view() => c.read(sessionControllerProvider(sid));

  test('kết nối → gửi session:join có event_id, vào WAITING', () async {
    final v = await boot();
    expect(v.phase, SessionPhase.waiting);
    final join = socket.sent.firstWhere((e) => e.$1 == 'session:join').$2;
    expect(join['session_id'], sid);
    expect(join['event_id'], isA<String>());
    expect(watcher.started, isFalse, reason: 'chưa ghi khi ở phòng chờ (NFR-P02)');
  });

  test('join bị từ chối → error với thông điệp tiếng Việt', () async {
    socket.reply = (e, p) => e == 'session:join' ? {'ok': false, 'code': 'OWNER_CANNOT_JOIN_SESSION'} : {'ok': true};
    final v = await boot();
    expect(v.phase, SessionPhase.error);
    expect(v.errorMessage, 'Chủ nhóm không tham gia phiên.');
  });

  test('session:state FOCUSING → bắt đầu ghi + heartbeat; tín hiệu rời app → member:left_app', () async {
    await boot();
    final now = DateTime.now().toUtc();
    socket.server('session:state', {
      'event_id': 'e1',
      'session_id': sid,
      'status': 'ACTIVE',
      'started_at': now.toIso8601String(),
      'ends_at': now.add(const Duration(minutes: 25)).toIso8601String(),
      'server_ts': now.toIso8601String(),
      'participant_count': 5,
      'my_state': 'FOCUSING',
      'forfeited': false,
    });
    expect(view().phase, SessionPhase.focusing);
    expect(view().recording, isTrue);
    expect(watcher.started, isTrue);

    socket.reply = (e, p) => e == 'member:left_app' ? {'ok': true, 'state': 'GRACE'} : {'ok': true};
    watcher.ctrl.add(const FocusSignal(FocusSignalType.leftApp, 'flutter:paused'));
    await pumpEventQueue();
    expect(socket.names(), contains('member:left_app'));
    expect(view().phase, SessionPhase.grace);
  });

  test('khóa màn hình → member:screen_locked, không đổi trạng thái', () async {
    await boot();
    socket.server('member:state', {'event_id': 'e2', 'session_id': sid, 'my_state': 'FOCUSING'});
    watcher.ctrl.add(const FocusSignal(FocusSignalType.screenLocked, 'screen_off'));
    await pumpEventQueue();
    expect(socket.names().last, 'member:screen_locked');
    expect(view().phase, SessionPhase.focusing);
    expect(view().screenLocked, isTrue);
  });

  test('MEMBER_EXITED có forfeited → banner có tên + cờ mất thưởng; trùng event_id bị bỏ', () async {
    await boot();
    final ev = {
      'event_id': 'x1',
      'type': 'MEMBER_EXITED',
      'session_id': sid,
      'exited_display_name': 'Minh',
      'exited_at': '2026-10-19T02:10:03Z',
      'forfeited': {'display_name': 'Minh', 'at': '2026-10-19T02:10:03Z'},
    };
    socket.server('MEMBER_EXITED', ev);
    socket.server('MEMBER_EXITED', ev); // phát lại khi nối lại
    expect(view().banners, hasLength(1));
    expect(view().banners.single.name, 'Minh');
    expect(view().banners.single.triggeredForfeit, isTrue);
    expect(view().forfeited, isTrue);
    expect(view().forfeitTriggerName, 'Minh');

    socket.server('MEMBER_EXITED', {
      'event_id': 'x2',
      'session_id': sid,
      'exited_display_name': 'Lan',
      'exited_at': '2026-10-19T02:15:40Z',
    });
    expect(view().banners.map((b) => b.triggeredForfeit), [true, false]);
    ctl().dismissBanner('x1');
    expect(view().banners.single.name, 'Lan');
  });

  test('mất kết nối khi FOCUSING → DISCONNECTED; nối lại gửi session:resume', () async {
    await boot();
    socket.server('member:state', {'event_id': 'e3', 'session_id': sid, 'my_state': 'FOCUSING'});
    socket.drop();
    expect(view().phase, SessionPhase.disconnected);
    socket.reply = (e, p) => e == 'session:resume' ? {'ok': true, 'state': 'FOCUSING'} : {'ok': true};
    socket.connect();
    await pumpEventQueue();
    final resume = socket.sent.lastWhere((e) => e.$1 == 'session:resume').$2;
    expect(resume['last_server_event_id'], 'e3');
    expect(view().phase, SessionPhase.focusing);
  });

  test('nối lại quá hạn → LOST (không phải thoát)', () async {
    await boot();
    socket.server('member:state', {'event_id': 'e4', 'session_id': sid, 'my_state': 'FOCUSING'});
    socket.drop();
    socket.reply = (e, p) => e == 'session:resume' ? {'ok': false, 'code': 'SESSION_LOST', 'state': 'LOST'} : {'ok': true};
    socket.connect();
    await pumpEventQueue();
    expect(view().phase, SessionPhase.lost);
    expect(watcher.started, isFalse);
  });

  test('Rời phiên khi mất mạng → báo lỗi, KHÔNG gửi/xếp hàng (BR-118)', () async {
    await boot();
    socket.server('member:state', {'event_id': 'e5', 'session_id': sid, 'my_state': 'FOCUSING'});
    socket.drop();
    // canLeave chỉ khi focusing/grace/waiting; giả lập mất mạng ở phòng chờ:
    socket.server('member:state', {'event_id': 'e6', 'session_id': sid, 'my_state': 'WAITING'});
    await ctl().leave();
    expect(view().leaveError, 'Chưa rời phiên — không có kết nối.');
    expect(socket.names(), isNot(contains('session:leave')));
  });

  test('Rời phiên ở phòng chờ → ABSENT; trong phiên → EXITED', () async {
    await boot();
    socket.reply = (e, p) => e == 'session:leave' ? {'ok': true, 'state': 'ABSENT'} : {'ok': true};
    await ctl().leave();
    expect(view().phase, SessionPhase.absent);
  });

  test('Rời phiên khi FOCUSING → EXITED, dừng ghi', () async {
    await boot();
    socket.server('member:state', {'event_id': 'e7', 'session_id': sid, 'my_state': 'FOCUSING'});
    expect(watcher.started, isTrue);
    socket.reply = (e, p) => e == 'session:leave' ? {'ok': true, 'state': 'EXITED'} : {'ok': true};
    await ctl().leave();
    expect(view().phase, SessionPhase.exited);
    expect(watcher.started, isFalse);
  });

  test('chủ nhóm hủy khi đang chờ → cancelled', () async {
    await boot();
    socket.server('SESSION_CANCELLED', {'event_id': 'c1', 'session_id': sid, 'reason': 'OWNER_CANCEL'});
    expect(view().phase, SessionPhase.cancelled);
  });

  test('sự kiện của phiên khác bị bỏ qua', () async {
    await boot();
    socket.server('MEMBER_EXITED', {'event_id': 'o1', 'session_id': 'khac', 'exited_display_name': 'X'});
    expect(view().banners, isEmpty);
  });
}
