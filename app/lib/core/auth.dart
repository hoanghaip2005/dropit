import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../app/env.dart';

import 'offline.dart';

/// Ghi đè trong `main()` sau khi `SharedPreferences.getInstance()`.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

class AuthState {
  const AuthState({this.token, this.userLabel, this.onboarded = false, required this.deviceId});
  final String? token;
  final String? userLabel;
  final bool onboarded;
  final String deviceId;
  bool get loggedIn => token != null;

  AuthState copyWith({String? token, String? userLabel, bool? onboarded, bool clearToken = false}) => AuthState(
        token: clearToken ? null : (token ?? this.token),
        userLabel: clearToken ? null : (userLabel ?? this.userLabel),
        onboarded: onboarded ?? this.onboarded,
        deviceId: deviceId,
      );
}

/// Đăng nhập dev: `POST /dev/token` của backend local (thay Cognito ở MVP dev).
/// (giả định) Token lưu ở SharedPreferences chỉ cho bản dev; bản thật dùng
/// flutter_secure_storage + Cognito (design/01-kien-truc.md §3.4).
class AuthController extends Notifier<AuthState> {
  static const _kToken = 'dev_token';
  static const _kUser = 'dev_user';
  static const _kOnboarded = 'onboarded';
  static const _kDevice = 'device_id';

  SharedPreferences get _p => ref.read(prefsProvider);

  @override
  AuthState build() {
    var device = _p.getString(_kDevice);
    if (device == null) {
      device = const Uuid().v4();
      _p.setString(_kDevice, device);
    }
    return AuthState(
      token: _p.getString(_kToken),
      userLabel: _p.getString(_kUser),
      onboarded: _p.getBool(_kOnboarded) ?? false,
      deviceId: device,
    );
  }

  Future<void> finishOnboarding() async {
    await _p.setBool(_kOnboarded, true);
    state = state.copyWith(onboarded: true);
  }

  Future<void> setToken(String token, String label) async {
    await _p.setString(_kToken, token);
    await _p.setString(_kUser, label);
    state = state.copyWith(token: token, userLabel: label);
  }

  Future<void> logout() async {
    await OfflineCache.clearAll(_p); // bản lưu ngoại tuyến + nháp nhật ký của người này
    await _p.remove(_kToken);
    await _p.remove(_kUser);
    state = state.copyWith(clearToken: true);
  }

  /// 401 từ server → về màn đăng nhập.
  void expire() {
    if (state.loggedIn) logout();
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

class DevUser {
  const DevUser(this.id, this.label, {this.email});
  final String id;
  final String label;
  final String? email;
}

/// Người dùng seed của backend (backend/db/seed.sql). Backend không có
/// `GET /dev/users` nên đây là danh sách chính; `/dev/token` nhận `email`.
const fallbackDevUsers = [
  DevUser('lan', 'Lan (chủ nhóm 2 nhóm)', email: 'lan@dropit.dev'),
  DevUser('an', 'An', email: 'an@dropit.dev'),
  DevUser('binh', 'Bình', email: 'binh@dropit.dev'),
  DevUser('chi', 'Chi', email: 'chi@dropit.dev'),
  DevUser('dung', 'Dũng', email: 'dung@dropit.dev'),
  DevUser('em', 'Em', email: 'em@dropit.dev'),
  DevUser('giang', 'Giang', email: 'giang@dropit.dev'),
  DevUser('hoa', 'Hoa', email: 'hoa@dropit.dev'),
];

class DevAuthApi {
  DevAuthApi([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.baseUrl,
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 10),
            ));
  final Dio _dio;

  /// Thử `/dev/users` rồi `/v1/dev/users`; lỗi → danh sách dự phòng.
  Future<List<DevUser>> users() async {
    for (final p in ['/dev/users', '${Env.apiPrefix}/dev/users']) {
      try {
        final r = await _dio.get(p);
        final d = r.data;
        final list = d is List ? d : (d is Map ? (d['items'] ?? d['users']) : null);
        if (list is List && list.isNotEmpty) {
          return list.whereType<Map>().map((m) {
            final id = '${m['user_id'] ?? m['id'] ?? m['sub'] ?? m['email']}';
            final name = '${m['display_name'] ?? m['name'] ?? m['email'] ?? id}';
            return DevUser(id, name, email: m['email'] as String?);
          }).toList();
        }
      } catch (_) {/* thử đường tiếp */}
    }
    return fallbackDevUsers;
  }

  /// `POST /dev/token` (gửi cả `user_id` và `email` nếu có) → `access_token`|`token`.
  Future<String> token(DevUser u) async {
    DioException? last;
    for (final p in ['/dev/token', '${Env.apiPrefix}/dev/token']) {
      try {
        // Hợp đồng backend: { email, display_name? } — chỉ gửi email để giữ tên seed.
        final r = await _dio.post(p, data: {'email': u.email ?? '${u.id}@dropit.dev'});
        final d = r.data;
        final t = d is Map ? (d['access_token'] ?? d['token'] ?? d['accessToken']) : d;
        if (t is String && t.isNotEmpty) return t;
      } on DioException catch (e) {
        last = e;
        if (e.response?.statusCode != 404) rethrow;
      }
    }
    throw last ?? Exception('Không nhận được token');
  }
}

final devAuthApiProvider = Provider<DevAuthApi>((ref) => DevAuthApi());
