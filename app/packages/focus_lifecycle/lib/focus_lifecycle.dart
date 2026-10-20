/// Phát hiện rời app / khóa màn hình cho phiên DropIt! (tách từ spike T-01).
///
/// Quyền riêng tư (BR-34, NFR-P01, NFR-P02): chỉ dùng vòng đời của chính app
/// và trạng thái khóa màn hình; không UsageStatsManager, không cảm biến; chỉ
/// lắng nghe giữa [FocusLifecycle.start] và [FocusLifecycle.stop].
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'src/classifier.dart';

export 'src/classifier.dart';

/// Nguồn tín hiệu native (tách để test).
abstract class FocusNativeBridge {
  Stream<Map<dynamic, dynamic>> get events;
  Future<void> startWatching();
  Future<void> stopWatching();
}

class MethodChannelFocusBridge implements FocusNativeBridge {
  static const _method = MethodChannel('dropit/focus_lifecycle');
  static const _events = EventChannel('dropit/focus_lifecycle/events');

  @override
  Stream<Map<dynamic, dynamic>> get events =>
      _events.receiveBroadcastStream().map((e) => e as Map<dynamic, dynamic>);

  @override
  Future<void> startWatching() async {
    try {
      await _method.invokeMethod('startWatching');
    } on MissingPluginException {
      // Nền tảng không hỗ trợ (test/desktop): chỉ dùng AppLifecycleListener.
    }
  }

  @override
  Future<void> stopWatching() async {
    try {
      await _method.invokeMethod('stopWatching');
    } on MissingPluginException {
      // bỏ qua
    }
  }
}

/// Ghép `AppLifecycleListener` + kênh native → [FocusSignal].
class FocusLifecycle {
  FocusLifecycle({
    FocusNativeBridge? bridge,
    Duration lockWait = const Duration(milliseconds: 600),
  })  : _bridge = bridge ?? MethodChannelFocusBridge(),
        _lockWait = lockWait; // ignore: prefer_initializing_formals

  final FocusNativeBridge _bridge;
  final Duration _lockWait;
  final _out = StreamController<FocusSignal>.broadcast();
  LockLeaveClassifier? _classifier;
  AppLifecycleListener? _listener;
  StreamSubscription<Map<dynamic, dynamic>>? _nativeSub;

  Stream<FocusSignal> get signals => _out.stream;
  bool get watching => _classifier != null;

  Future<void> start() async {
    if (watching) return;
    final c = LockLeaveClassifier(
      onSignal: _out.add,
      lockWait: _lockWait,
      isForeground: () =>
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    )..start();
    _classifier = c;
    _listener = AppLifecycleListener(
      onStateChange: (s) => c.onHostLifecycle(HostLifecycle.values.byName(s.name)),
    );
    _nativeSub = _bridge.events.listen(c.onNative, onError: (_) {});
    await _bridge.startWatching();
  }

  Future<void> stop() async {
    if (!watching) return;
    _classifier?.stop();
    _classifier = null;
    _listener?.dispose();
    _listener = null;
    await _nativeSub?.cancel();
    _nativeSub = null;
    await _bridge.stopWatching();
  }

  Future<void> dispose() async {
    await stop();
    await _out.close();
  }
}
