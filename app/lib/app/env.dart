import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Cấu hình môi trường qua `--dart-define`.
///
/// - `API_BASE_URL`: gốc server (không có `/v1`). Mặc định Android emulator
///   `http://10.0.2.2:3000`, iOS simulator/khác `http://localhost:3000`.
/// - `API_PREFIX`: tiền tố REST, mặc định `/v1` (design/03-api-socket.md P1).
/// - `SOCKET_NAMESPACE`: mặc định `/session` (§3.1).
class Env {
  static const _base = String.fromEnvironment('API_BASE_URL');
  static const apiPrefix = String.fromEnvironment('API_PREFIX', defaultValue: '/v1');
  static const socketNamespace =
      String.fromEnvironment('SOCKET_NAMESPACE', defaultValue: '/session');

  static String get baseUrl {
    if (_base.isNotEmpty) return _base;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static String get restBase => '$baseUrl$apiPrefix';
  static String get socketUrl => '$baseUrl$socketNamespace';
}
