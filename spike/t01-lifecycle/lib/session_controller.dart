import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Tham số spike (khớp BR-11, BR-19, BR-66).
class SpikeConfig {
  static const heartbeatS = 5; // heartbeat_s
  static const graceMs = 3000; // grace_s (chỉ để hiển thị; server quyết định)
  /// Thời gian client chờ tín hiệu khóa màn hình native sau khi app vào nền,
  /// trước khi báo `member:left_app`. Spike đo xem cần bao nhiêu (iOS
  /// protectedData có thể đến trễ). Phải << 1000 ms để đạt NFR-03.
  static const lockWaitMs = 600;
}

class LogEvent {
  LogEvent(this.kind, this.source, [this.data = const {}])
      : wallMs = DateTime.now().millisecondsSinceEpoch,
        monoUs = _sw.elapsedMicroseconds;
  static final Stopwatch _sw = Stopwatch()..start();
  final String kind; // tên sự kiện
  final String source; // flutter | native | socket | ui | classifier
  final Map<String, dynamic> data;
  final int wallMs;
  final int monoUs;

  String get line {
    final t = DateTime.fromMillisecondsSinceEpoch(wallMs);
    final hh = t.toIso8601String().substring(11, 23);
    return '$hh [$source] $kind ${data.isEmpty ? "" : jsonEncode(data)}';
  }

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'source': source,
        'clientWallMs': wallMs,
        'clientMonoUs': monoUs,
        ...data,
      };
}

/// Phân loại LOCK vs LEAVE + gửi sự kiện tới server. Server mới là bên
/// quyết định GRACE/EXITED theo giờ server (BR-03, BR-33).
class SessionController extends ChangeNotifier {
  static const _events = EventChannel('dropit/lifecycle_events');
  static const _method = MethodChannel('dropit/lifecycle');

  final List<LogEvent> events = [];
  bool recording = false;
  bool connected = false;
  String localState = 'IDLE'; // IDLE | FOCUSING | LEFT | LOCKED
  String serverState = '-';
  int? lastRttMs;
  int? clockOffsetMs; // serverTs - clientTs ước lượng (NTP đơn giản)
  int markCount = 0;

  io.Socket? _socket;
  AppLifecycleListener? _lifecycle;
  StreamSubscription? _nativeSub;
  Timer? _hb;
  Timer? _pendingLeave;
  bool _screenLocked = false;
  String _name = '';
  bool _joinedOnce = false;
  final _rnd = Random();

  void _log(String kind, String source, [Map<String, dynamic> data = const {}]) {
    events.add(LogEvent(kind, source, data));
    notifyListeners();
  }

  String _eid() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_rnd.nextInt(1 << 32)}';

  void _emit(String ev, [Map<String, dynamic> extra = const {}]) {
    final payload = {
      'eventId': _eid(),
      'clientTs': DateTime.now().millisecondsSinceEpoch,
      ...extra,
    };
    _log('send:$ev', 'socket', {'eventId': payload['eventId']});
    _socket?.emitWithAck(ev, payload, ack: (resp) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final sent = payload['clientTs'] as int;
      if (resp is Map) {
        lastRttMs = now - sent;
        if (resp['state'] != null) serverState = '${resp['state']}';
        _log('ack:$ev', 'socket', {
          'rttMs': lastRttMs,
          'serverTs': resp['serverTs'],
          'state': resp['state'],
          if (resp['dup'] == true) 'dup': true,
        });
      }
    });
  }

  // ---------------- Bắt đầu / kết thúc ghi phiên ----------------
  Future<void> start(String url, String name) async {
    if (recording) return;
    _name = name.isEmpty ? 'may' : name;
    recording = true;
    _joinedOnce = false;
    localState = 'FOCUSING';
    _log('session_start', 'ui', {
      'url': url,
      'name': _name,
      'platform': Platform.operatingSystem,
      'lockWaitMs': SpikeConfig.lockWaitMs,
    });

    _socket = io.io(
        url,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableReconnection()
            .build());
    _socket!
      ..onConnect((_) {
        connected = true;
        _log('connected', 'socket');
        // fresh = lần nối đầu sau Bắt đầu → server tạo trạng thái mới nếu
        // phiên cũ của tên này đã kết thúc; nối lại thì giữ trạng thái (BR-20).
        _emit('member:join', {
          'name': _name,
          'platform': Platform.operatingSystem,
          'fresh': !_joinedOnce,
        });
        _joinedOnce = true;
        _syncClock();
      })
      ..onDisconnect((r) {
        connected = false;
        _log('disconnected', 'socket', {'reason': '$r'});
      })
      ..on('session:state', (d) {
        if (d is Map && d['name'] == _name) serverState = '${d['state']}';
        _log('recv:session:state', 'socket', Map<String, dynamic>.from(d as Map));
      })
      ..on('MEMBER_EXITED', (d) {
        final m = Map<String, dynamic>.from(d as Map);
        final now = DateTime.now().millisecondsSinceEpoch;
        final st = (m['serverTs'] as num).toInt();
        _log('recv:MEMBER_EXITED', 'socket', {
          ...m,
          // Độ trễ server→client đã hiệu chỉnh lệch giờ (ước lượng).
          'latencyMs': clockOffsetMs == null ? null : now + clockOffsetMs! - st,
        });
      })
      ..connect();

    _lifecycle = AppLifecycleListener(onStateChange: _onFlutterState);
    _nativeSub = _events.receiveBroadcastStream().listen(_onNative,
        onError: (e) => _log('native_error', 'native', {'error': '$e'}));
    try {
      await _method.invokeMethod('startWatching');
    } catch (e) {
      _log('native_unavailable', 'native', {'error': '$e'});
    }
    _hb = Timer.periodic(const Duration(seconds: SpikeConfig.heartbeatS), (_) {
      // Heartbeat ghi cả khi khóa để spike đo được Dart timer có chạy khi
      // màn hình tắt không (BR-66 cho phép ngừng).
      if (_socket?.connected == true) {
        _emit('heartbeat', {'locked': _screenLocked, 'local': localState});
      } else {
        _log('heartbeat_skipped', 'socket', {'connected': false});
      }
    });
    notifyListeners();
  }

  Future<void> stop() async {
    if (!recording) return;
    _emit('session:end');
    _hb?.cancel();
    _pendingLeave?.cancel();
    _lifecycle?.dispose();
    await _nativeSub?.cancel();
    try {
      await _method.invokeMethod('stopWatching');
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 300));
    _socket?.dispose();
    _socket = null;
    recording = false;
    connected = false;
    localState = 'IDLE';
    _log('session_stop', 'ui');
  }

  void mark() {
    markCount++;
    _log('MARK', 'ui', {'case': markCount});
    _emit('client:mark', {'case': markCount});
  }

  void _syncClock() {
    // 5 mẫu ping, lấy mẫu RTT nhỏ nhất để ước lệch giờ.
    var best = 1 << 30;
    for (var i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: 200 * i), () {
        final t0 = DateTime.now().millisecondsSinceEpoch;
        _socket?.emitWithAck('clock:ping', {'t0': t0}, ack: (r) {
          final t1 = DateTime.now().millisecondsSinceEpoch;
          final rtt = t1 - t0;
          if (r is Map && rtt < best) {
            best = rtt;
            clockOffsetMs = (r['serverTs'] as num).toInt() - (t0 + rtt ~/ 2);
            _log('clock_sync', 'socket',
                {'rttMs': rtt, 'offsetMs': clockOffsetMs});
          }
        });
      });
    }
  }

  // ---------------- Tín hiệu vào ----------------
  void _onFlutterState(AppLifecycleState s) {
    _log('flutter:${s.name}', 'flutter', {'screenLocked': _screenLocked});
    switch (s) {
      case AppLifecycleState.resumed:
        _onForeground();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _onBackground('flutter:${s.name}');
      case AppLifecycleState.detached:
        // Vuốt tắt app: cố gửi ngay (best effort), không chờ khóa.
        if (localState == 'FOCUSING') {
          _emit('member:left_app', {'reason': 'detached'});
          localState = 'LEFT';
        }
      case AppLifecycleState.inactive:
        // iOS: kéo Trung tâm thông báo/điều khiển → chỉ inactive. Không tính.
        break;
    }
  }

  void _onNative(dynamic raw) {
    final m = Map<String, dynamic>.from(raw as Map);
    final ev = '${m['event']}';
    _log('native:$ev', 'native', m..remove('event'));
    switch (ev) {
      // Android: ACTION_SCREEN_OFF; iOS: protectedDataWillBecomeUnavailable.
      case 'screen_off':
      case 'protected_data_unavailable':
        _onLocked(ev);
      // Android: ACTION_USER_PRESENT (đã mở khóa); iOS: protectedDataDidBecomeAvailable.
      case 'user_present':
      case 'protected_data_available':
        _onUnlocked(ev);
      // Android ProcessLifecycleOwner ON_STOP kèm isInteractive.
      case 'process_stop':
        if (m['interactive'] == false || m['keyguardLocked'] == true) {
          _onLocked('process_stop_noninteractive');
        } else {
          _onBackground('native:process_stop');
        }
      // iOS sceneDidEnterBackground kèm isProtectedDataAvailable.
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

  // ---------------- Bộ phân loại LOCK vs LEAVE ----------------
  void _onBackground(String why) {
    if (!recording || _screenLocked || localState != 'FOCUSING') return;
    if (_pendingLeave?.isActive == true) return;
    // Chờ lockWaitMs xem có tín hiệu khóa không; nếu không → LEAVE.
    _pendingLeave =
        Timer(const Duration(milliseconds: SpikeConfig.lockWaitMs), () {
      if (_screenLocked || localState != 'FOCUSING') return;
      localState = 'LEFT';
      _log('CLASSIFY:LEAVE', 'classifier', {'trigger': why});
      _emit('member:left_app', {'trigger': why});
    });
  }

  void _onLocked(String why) {
    if (!recording || _screenLocked) return;
    _pendingLeave?.cancel();
    _screenLocked = true;
    final wasLeft = localState == 'LEFT';
    localState = 'LOCKED';
    _log('CLASSIFY:LOCK', 'classifier', {'trigger': why, 'afterLeave': wasLeft});
    _emit('member:screen_locked', {'trigger': why, 'afterLeave': wasLeft});
  }

  void _onUnlocked(String why) {
    if (!recording || !_screenLocked) return;
    _screenLocked = false;
    _log('CLASSIFY:UNLOCK', 'classifier', {'trigger': why});
    _emit('member:screen_unlocked', {'trigger': why});
    // Sau mở khóa: nếu app đang ở tiền cảnh → FOCUSING, nếu không → coi là rời.
    final fg = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    localState = 'FOCUSING';
    if (!fg) _onBackground('unlocked_not_foreground');
  }

  void _onForeground() {
    if (!recording) return;
    _pendingLeave?.cancel();
    if (_screenLocked) return; // chờ user_present / protected_data_available
    if (localState == 'LEFT') {
      _log('CLASSIFY:RETURN', 'classifier');
      _emit('member:returned');
    }
    localState = 'FOCUSING';
    notifyListeners();
  }

  // ---------------- Xuất log ----------------
  Future<void> exportLog() async {
    final dir = await getTemporaryDirectory();
    final f = File(
        '${dir.path}/t01_${_name}_${DateTime.now().millisecondsSinceEpoch}.json');
    await f.writeAsString(const JsonEncoder.withIndent(' ').convert({
      'device': _name,
      'platform': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'lockWaitMs': SpikeConfig.lockWaitMs,
      'events': events.map((e) => e.toJson()).toList(),
    }));
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
  }
}
