import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../app/env.dart';

/// Một sự kiện từ socket. Sự kiện tổng hợp: `_connect`, `_disconnect`,
/// `_connect_error`.
class SocketEvent {
  const SocketEvent(this.name, [this.data = const {}]);
  final String name;
  final Map<String, dynamic> data;
}

/// Trừu tượng socket namespace `/session` (design/03-api-socket.md §3) để
/// test bằng socket giả.
abstract class SessionSocket {
  Stream<SocketEvent> get events;
  bool get connected;
  void connect();

  /// Gửi có ack; `null` nếu quá [timeout].
  Future<Map<String, dynamic>?> request(String event, Map<String, dynamic> payload,
      {Duration timeout = const Duration(seconds: 5)});

  /// Gửi không ack (heartbeat, `volatile`).
  void send(String event, Map<String, dynamic> payload);
  void dispose();
}

Map<String, dynamic> _asMap(Object? d) {
  if (d is Map) return Map<String, dynamic>.from(d);
  if (d is List && d.isNotEmpty && d.first is Map) return Map<String, dynamic>.from(d.first as Map);
  return {'value': d};
}

class IoSessionSocket implements SessionSocket {
  IoSessionSocket({required String token, required String deviceId, String? url}) {
    _s = io.io(
      url ?? Env.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // DQ-A06: tắt long-polling
          .setAuth({'token': token, 'v': 1, 'device_id': deviceId})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(500)
          .setReconnectionDelayMax(4000)
          .enableForceNew()
          .build(),
    );
    _s
      ..onConnect((_) => _ctrl.add(const SocketEvent('_connect')))
      ..onDisconnect((r) => _ctrl.add(SocketEvent('_disconnect', {'reason': '$r'})))
      ..onConnectError((e) => _ctrl.add(SocketEvent('_connect_error', _asMap(e))))
      ..onAny((event, data) => _ctrl.add(SocketEvent(event, _asMap(data))));
  }

  late final io.Socket _s;
  final _ctrl = StreamController<SocketEvent>.broadcast();

  @override
  Stream<SocketEvent> get events => _ctrl.stream;
  @override
  bool get connected => _s.connected;
  @override
  void connect() => _s.connect();

  @override
  Future<Map<String, dynamic>?> request(String event, Map<String, dynamic> payload,
      {Duration timeout = const Duration(seconds: 5)}) {
    final c = Completer<Map<String, dynamic>?>();
    final t = Timer(timeout, () {
      if (!c.isCompleted) c.complete(null);
    });
    _s.emitWithAck(event, payload, ack: (resp) {
      t.cancel();
      if (!c.isCompleted) c.complete(_asMap(resp));
    });
    return c.future;
  }

  @override
  void send(String event, Map<String, dynamic> payload) => _s.emit(event, payload);

  @override
  void dispose() {
    _s.dispose();
    _ctrl.close();
  }
}

typedef SessionSocketFactory = SessionSocket Function({required String token, required String deviceId});

final sessionSocketFactoryProvider = Provider<SessionSocketFactory>(
    (ref) => ({required String token, required String deviceId}) =>
        IoSessionSocket(token: token, deviceId: deviceId));
