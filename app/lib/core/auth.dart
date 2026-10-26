import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../app/env.dart';
import 'offline.dart';

final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final beforeLogoutProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);

class AuthState {
  const AuthState({
    this.token,
    this.userLabel,
    this.onboarded = false,
    required this.deviceId,
  });
  final String? token;
  final String? userLabel;
  final bool onboarded;
  final String deviceId;
  bool get loggedIn => token != null;
  AuthState copyWith({
    String? token,
    String? userLabel,
    bool? onboarded,
    bool clearToken = false,
  }) => AuthState(
    token: clearToken ? null : token ?? this.token,
    userLabel: clearToken ? null : userLabel ?? this.userLabel,
    onboarded: onboarded ?? this.onboarded,
    deviceId: deviceId,
  );
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.label,
    this.refreshToken,
    this.expiresIn = 3600,
  });
  final String accessToken;
  final String label;
  final String? refreshToken;
  final int expiresIn;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Public Cognito app client, without a client secret. Passwords go directly to AWS.
class ProductionAuthApi {
  ProductionAuthApi({
    Dio? dio,
    String? region,
    String? userPoolId,
    String? clientId,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 15),
             ),
           ),
       region = region ?? Env.cognitoRegion,
       userPoolId = userPoolId ?? Env.cognitoUserPoolId,
       clientId = clientId ?? Env.cognitoClientId;
  final Dio _dio;
  final String region;
  final String userPoolId;
  final String clientId;
  bool get configured =>
      RegExp(r'^[a-z]{2}(?:-[a-z]+)+-\d+$').hasMatch(region) &&
      RegExp('^${RegExp.escape(region)}_[A-Za-z0-9]+\$').hasMatch(userPoolId) &&
      RegExp(r'^[a-z0-9]{1,128}$').hasMatch(clientId);

  Future<Map<String, dynamic>> _call(
    String action,
    Map<String, dynamic> body,
  ) async {
    if (!configured) {
      throw const AuthFailure(
        'Đăng nhập chưa được cấu hình. Vui lòng liên hệ quản trị viên.',
      );
    }
    try {
      final result = await _dio.post(
        'https://cognito-idp.$region.amazonaws.com/',
        data: body,
        options: Options(
          contentType: 'application/x-amz-json-1.1',
          headers: {
            'X-Amz-Target': 'AWSCognitoIdentityProviderService.$action',
          },
        ),
      );
      if (result.data is! Map) {
        throw const AuthFailure('Chưa nhận được phản hồi đăng nhập hợp lệ.');
      }
      return Map<String, dynamic>.from(result.data as Map);
    } on DioException catch (error) {
      final data = error.response?.data;
      final code = data is Map ? '${data['__type'] ?? ''}'.split('#').last : '';
      throw AuthFailure(switch (code) {
        'NotAuthorizedException' ||
        'UserNotFoundException' => 'Email hoặc mật khẩu chưa đúng.',
        'UserNotConfirmedException' =>
          'Tài khoản chưa xác minh email. Vui lòng kiểm tra email hoặc liên hệ quản trị viên.',
        'PasswordResetRequiredException' =>
          'Tài khoản cần đặt lại mật khẩu. Vui lòng liên hệ quản trị viên.',
        'TooManyRequestsException' || 'LimitExceededException' =>
          'Bạn thử quá nhiều lần. Vui lòng chờ rồi thử lại.',
        _ =>
          error.response == null
              ? 'Không kết nối được dịch vụ đăng nhập. Vui lòng thử lại.'
              : 'Chưa đăng nhập được. Vui lòng thử lại hoặc liên hệ quản trị viên.',
      });
    }
  }

  AuthSession _session(
    Map<String, dynamic> result,
    String label, {
    String? refreshToken,
  }) {
    final auth = result['AuthenticationResult'];
    if (auth is! Map) {
      throw const AuthFailure(
        'Tài khoản cần hoàn tất bước xác thực bổ sung. Vui lòng liên hệ quản trị viên.',
      );
    }
    final token = auth['AccessToken'];
    final ttl = auth['ExpiresIn'];
    if (token is! String ||
        token.isEmpty ||
        ttl is! num ||
        ttl < 1 ||
        ttl > 86400) {
      throw const AuthFailure('Chưa nhận được phiên đăng nhập hợp lệ.');
    }
    return AuthSession(
      accessToken: token,
      label: label,
      expiresIn: ttl.toInt(),
      refreshToken: auth['RefreshToken'] is String
          ? auth['RefreshToken'] as String
          : refreshToken,
    );
  }

  Future<AuthSession> signIn(String email, String password) async => _session(
    await _call('InitiateAuth', {
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'ClientId': clientId,
      'AuthParameters': {'USERNAME': email.trim(), 'PASSWORD': password},
    }),
    email.trim(),
  );

  Future<AuthSession> refresh(AuthSession session) async {
    if (session.refreshToken == null) {
      throw const AuthFailure('Phiên đăng nhập đã hết hạn.');
    }
    return _session(
      await _call('InitiateAuth', {
        'AuthFlow': 'REFRESH_TOKEN_AUTH',
        'ClientId': clientId,
        'AuthParameters': {'REFRESH_TOKEN': session.refreshToken},
      }),
      session.label,
      refreshToken: session.refreshToken,
    );
  }
}

final productionAuthApiProvider = Provider<ProductionAuthApi>(
  (ref) => ProductionAuthApi(),
);

/// Tokens stay in memory, never SharedPreferences or browser local storage.
/// Closing/reloading the app requires sign-in again; secure persistent sessions are a separate capability.
class AuthController extends Notifier<AuthState> {
  Timer? _refreshTimer;
  AuthSession? _session;
  int _generation = 0;
  SharedPreferences get _p => ref.read(prefsProvider);
  @override
  AuthState build() {
    ref.onDispose(() => _refreshTimer?.cancel());
    var device = _p.getString('device_id');
    if (device == null) {
      device = const Uuid().v4();
      unawaited(_p.setString('device_id', device));
    }
    unawaited(_p.remove('dev_token'));
    unawaited(_p.remove('dev_user'));
    return AuthState(
      onboarded: _p.getBool('onboarded') ?? false,
      deviceId: device,
    );
  }

  Future<void> finishOnboarding() async {
    await _p.setBool('onboarded', true);
    state = state.copyWith(onboarded: true);
  }

  Future<void> acceptSession(AuthSession session) async {
    final generation = ++_generation;
    _refreshTimer?.cancel();
    await OfflineCache.clearAll(_p);
    if (!ref.mounted || generation != _generation) return;
    _session = session;
    state = state.copyWith(
      token: session.accessToken,
      userLabel: session.label,
      onboarded: true,
    );
    await _p.setBool('onboarded', true);
    if (!ref.mounted || generation != _generation) return;
    _schedule(session);
  }

  void _schedule(AuthSession session) {
    _refreshTimer?.cancel();
    final seconds = session.expiresIn > 60
        ? session.expiresIn - 60
        : session.expiresIn;
    _refreshTimer = Timer(
      Duration(seconds: seconds),
      () => unawaited(_refresh()),
    );
  }

  Future<void> _refresh() async {
    final session = _session;
    if (session == null) return;
    final generation = _generation;
    final api = ref.read(productionAuthApiProvider);
    try {
      final next = await api.refresh(session);
      if (!ref.mounted || generation != _generation) return;
      _session = next;
      state = state.copyWith(token: next.accessToken, userLabel: next.label);
      _schedule(next);
    } catch (_) {
      if (ref.mounted && generation == _generation) await logout();
    }
  }

  /// Test injection; the UI only accepts sessions returned by the real identity provider.
  Future<void> setToken(String token, String label) async =>
      acceptSession(AuthSession(accessToken: token, label: label));
  Future<void> logout() async {
    final generation = ++_generation;
    _refreshTimer?.cancel();
    _session = null;
    try {
      await ref
          .read(beforeLogoutProvider)()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Revocation failure must not lock the user inside the app.
    }
    if (!ref.mounted || generation != _generation) return;
    state = state.copyWith(clearToken: true);
    await OfflineCache.clearAll(_p);
  }

  void expire() {
    if (state.loggedIn) unawaited(logout());
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
