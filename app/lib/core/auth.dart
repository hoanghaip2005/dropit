import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../app/env.dart';
import 'offline.dart';
import 'session_storage.dart';

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => createSessionStorage(),
);

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
  const AuthFailure(this.message, {this.retryable = false});
  final String message;
  final bool retryable;
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
        // Cognito's x-amz-json MIME type is not recognized as JSON by Dio.
        data: jsonEncode(body),
        options: Options(
          contentType: 'application/x-amz-json-1.1',
          headers: {
            'X-Amz-Target': 'AWSCognitoIdentityProviderService.$action',
          },
        ),
      );
      final data = result.data is String
          ? jsonDecode(result.data as String)
          : result.data;
      if (data is! Map) {
        throw const AuthFailure('Chưa nhận được phản hồi đăng nhập hợp lệ.');
      }
      return Map<String, dynamic>.from(data);
    } on DioException catch (error) {
      var data = error.response?.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          data = null;
        }
      }
      final code = data is Map ? '${data['__type'] ?? ''}'.split('#').last : '';
      throw AuthFailure(
        switch (code) {
          'NotAuthorizedException' ||
          'UserNotFoundException' => 'Email hoặc mật khẩu chưa đúng.',
          'UserNotConfirmedException' =>
            'Tài khoản chưa xác minh email. Vui lòng kiểm tra email hoặc liên hệ quản trị viên.',
          'PasswordResetRequiredException' =>
            'Tài khoản cần đặt lại mật khẩu. Vui lòng liên hệ quản trị viên.',
          'UsernameExistsException' =>
            'Email đã được đăng ký. Hãy đăng nhập hoặc xác minh email.',
          'InvalidPasswordException' =>
            'Mật khẩu cần ít nhất 12 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt.',
          'CodeMismatchException' => 'Mã xác minh chưa đúng.',
          'ExpiredCodeException' => 'Mã xác minh đã hết hạn. Hãy gửi lại mã.',
          'LimitExceededException' || 'TooManyRequestsException' =>
            'Bạn thử quá nhiều lần. Vui lòng chờ rồi thử lại.',
          'CodeDeliveryFailureException' =>
            'Chưa gửi được email xác minh. Vui lòng thử lại sau.',
          _ =>
            error.response == null
                ? 'Không kết nối được dịch vụ đăng nhập. Vui lòng thử lại.'
                : 'Chưa đăng nhập được. Vui lòng thử lại hoặc liên hệ quản trị viên.',
        },
        retryable:
            error.response == null ||
            (error.response?.statusCode ?? 0) >= 500 ||
            error.response?.statusCode == 429 ||
            code == 'TooManyRequestsException' ||
            code == 'LimitExceededException',
      );
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

  Future<void> signUp(String email, String password, String name) async {
    await _call('SignUp', {
      'ClientId': clientId,
      'Username': email.trim(),
      'Password': password,
      'UserAttributes': [
        {'Name': 'email', 'Value': email.trim()},
        {'Name': 'name', 'Value': name.trim()},
      ],
    });
  }

  Future<void> confirmSignUp(String email, String code) async {
    await _call('ConfirmSignUp', {
      'ClientId': clientId,
      'Username': email.trim(),
      'ConfirmationCode': code.trim(),
    });
  }

  Future<void> resendSignUpCode(String email) async {
    await _call('ResendConfirmationCode', {
      'ClientId': clientId,
      'Username': email.trim(),
    });
  }

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

/// Access tokens stay in memory. Web refresh credentials live only in sessionStorage.
/// This survives a same-tab reload, without persisting passwords or using localStorage.
class AuthController extends Notifier<AuthState> {
  Timer? _refreshTimer;
  AuthSession? _session;
  int _generation = 0;
  DateTime? _refreshExpiresAt;
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
    _refreshExpiresAt = DateTime.now().toUtc().add(const Duration(days: 1));
    _saveRefresh(session);
    state = state.copyWith(
      token: session.accessToken,
      userLabel: session.label,
      onboarded: true,
    );
    await _p.setBool('onboarded', true);
    if (!ref.mounted || generation != _generation) return;
    _schedule(session);
  }

  void _saveRefresh(AuthSession session) {
    final storage = ref.read(sessionStorageProvider);
    final token = session.refreshToken;
    if (token == null || token.isEmpty || _refreshExpiresAt == null) {
      storage.clear();
      return;
    }
    storage.write(
      jsonEncode({
        'refreshToken': token,
        'label': session.label,
        'expiresAt': _refreshExpiresAt!.toIso8601String(),
        'clientId': ref.read(productionAuthApiProvider).clientId,
      }),
    );
  }

  /// Called before the router is mounted, so a reload never briefly redirects to login.
  Future<void> restoreSession() async {
    final storage = ref.read(sessionStorageProvider);
    final raw = storage.read();
    if (raw == null) return;
    final generation = ++_generation;
    try {
      final data = jsonDecode(raw);
      final api = ref.read(productionAuthApiProvider);
      if (data is! Map ||
          data['refreshToken'] is! String ||
          (data['refreshToken'] as String).isEmpty ||
          data['label'] is! String ||
          data['clientId'] != api.clientId ||
          data['expiresAt'] is! String) {
        throw const FormatException('Invalid saved session');
      }
      final expiresAt = DateTime.parse(data['expiresAt'] as String).toUtc();
      if (!expiresAt.isAfter(DateTime.now().toUtc())) {
        throw const FormatException('Expired saved session');
      }
      final restored = await api.refresh(
        AuthSession(
          accessToken: '',
          label: data['label'] as String,
          refreshToken: data['refreshToken'] as String,
        ),
      );
      if (!ref.mounted || generation != _generation) return;
      await OfflineCache.clearAll(_p);
      if (!ref.mounted || generation != _generation) return;
      _session = restored;
      _refreshExpiresAt = expiresAt;
      _saveRefresh(restored);
      state = state.copyWith(
        token: restored.accessToken,
        userLabel: restored.label,
        onboarded: true,
      );
      await _p.setBool('onboarded', true);
      if (ref.mounted && generation == _generation) _schedule(restored);
    } on AuthFailure catch (error) {
      if (error.retryable) rethrow;
      if (ref.mounted && generation == _generation) storage.clear();
    } catch (_) {
      if (ref.mounted && generation == _generation) storage.clear();
    }
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
      _saveRefresh(next);
      state = state.copyWith(token: next.accessToken, userLabel: next.label);
      _schedule(next);
    } on AuthFailure catch (error) {
      if (!ref.mounted || generation != _generation) return;
      if (error.retryable) {
        _refreshTimer = Timer(
          const Duration(seconds: 15),
          () => unawaited(_refresh()),
        );
      } else {
        await logout();
      }
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
    _refreshExpiresAt = null;
    ref.read(sessionStorageProvider).clear();
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
