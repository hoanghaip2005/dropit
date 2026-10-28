import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dropit/core/auth.dart';
import 'package:dropit/core/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Adapter implements HttpClientAdapter {
  Adapter(this.handler);
  final FutureOr<ResponseBody> Function(RequestOptions) handler;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<dynamic>? cancel,
  ) async => handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(Object body, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/x-amz-json-1.1'],
      },
    );
ProductionAuthApi api(Adapter adapter) => ProductionAuthApi(
  dio: Dio()..httpClientAdapter = adapter,
  region: 'ap-southeast-1',
  userPoolId: 'ap-southeast-1_Test123',
  clientId: 'testclient123',
);
Map<String, dynamic> sessionBody({
  String token = 'real-access',
  String? refresh = 'real-refresh',
}) => {
  'AuthenticationResult': {
    'AccessToken': token,
    'ExpiresIn': 3600,
    'RefreshToken': ?refresh,
  },
};
void main() {
  test(
    'Registration, confirmation and resend use Cognito JSON without role claims',
    () async {
      final requests = <RequestOptions>[];
      final auth = api(
        Adapter((r) {
          requests.add(r);
          return response({});
        }),
      );
      await auth.signUp(' demo@example.com ', ' Exact password1! ', ' Demo ');
      await auth.confirmSignUp(' demo@example.com ', ' 123456 ');
      await auth.resendSignUpCode(' demo@example.com ');
      final bodies = requests
          .map((r) => jsonDecode(r.data as String) as Map)
          .toList();
      expect(requests.map((r) => r.headers['X-Amz-Target']), [
        'AWSCognitoIdentityProviderService.SignUp',
        'AWSCognitoIdentityProviderService.ConfirmSignUp',
        'AWSCognitoIdentityProviderService.ResendConfirmationCode',
      ]);
      expect(bodies[0]['Username'], 'demo@example.com');
      expect(bodies[0]['Password'], ' Exact password1! ');
      expect(bodies[0]['UserAttributes'], [
        {'Name': 'email', 'Value': 'demo@example.com'},
        {'Name': 'name', 'Value': 'Demo'},
      ]);
      expect(bodies[0].containsKey('role'), false);
      expect(bodies[1]['ConfirmationCode'], '123456');
      expect(bodies[2]['Username'], 'demo@example.com');
    },
  );
  test(
    'Cognito receives password directly via HTTPS, exact password and public client only',
    () async {
      final requests = <RequestOptions>[];
      final auth = api(
        Adapter((r) {
          requests.add(r);
          return response(sessionBody());
        }),
      );
      final session = await auth.signIn(' an@example.com ', ' exact password ');
      expect(
        requests.single.uri.toString(),
        'https://cognito-idp.ap-southeast-1.amazonaws.com/',
      );
      expect(
        requests.single.headers['X-Amz-Target'],
        'AWSCognitoIdentityProviderService.InitiateAuth',
      );
      expect(
        (jsonDecode(requests.single.data as String) as Map)['AuthParameters'],
        {'USERNAME': 'an@example.com', 'PASSWORD': ' exact password '},
      );
      expect(
        (jsonDecode(requests.single.data as String) as Map).containsKey(
          'SECRET_HASH',
        ),
        false,
      );
      expect(session.accessToken, 'real-access');
    },
  );
  test('Missing configuration never sends credentials', () async {
    var calls = 0;
    final auth = ProductionAuthApi(
      region: '',
      userPoolId: '',
      clientId: '',
      dio: Dio()
        ..httpClientAdapter = Adapter((r) {
          calls++;
          return response({});
        }),
    );
    await expectLater(
      auth.signIn('a@example.com', 'password'),
      throwsA(isA<AuthFailure>()),
    );
    expect(calls, 0);
  });
  for (final code in [
    'NotAuthorizedException',
    'UserNotFoundException',
    'TooManyRequestsException',
    'PasswordResetRequiredException',
    'UsernameExistsException',
    'InvalidPasswordException',
    'CodeMismatchException',
    'ExpiredCodeException',
    'CodeDeliveryFailureException',
  ]) {
    test('Cognito $code maps safely without raw server detail', () async {
      final auth = api(
        Adapter(
          (r) => response({
            '__type': code,
            'message': 'sensitive internal detail',
          }, 400),
        ),
      );
      await expectLater(
        auth.signIn('a@example.com', 'password'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'safe',
            (isNot(contains('sensitive'))),
          ),
        ),
      );
    });
  }
  test(
    'Challenges and malformed success cannot create an authenticated session',
    () async {
      for (final body in [
        {'ChallengeName': 'SMS_MFA', 'Session': 'challenge-secret'},
        {
          'AuthenticationResult': {'AccessToken': 'x'},
        },
        {
          'AuthenticationResult': {'AccessToken': '', 'ExpiresIn': 3600},
        },
      ]) {
        await expectLater(
          api(
            Adapter((r) => response(body)),
          ).signIn('a@example.com', 'password'),
          throwsA(isA<AuthFailure>()),
        );
      }
    },
  );
  test(
    'Refresh uses refresh token and retains it when AWS omits replacement',
    () async {
      late RequestOptions sent;
      final auth = api(
        Adapter((r) {
          sent = r;
          return response(sessionBody(token: 'new-access', refresh: null));
        }),
      );
      final session = await auth.refresh(
        const AuthSession(
          accessToken: 'old',
          label: 'An',
          refreshToken: 'refresh',
        ),
      );
      expect((jsonDecode(sent.data as String) as Map)['AuthParameters'], {
        'REFRESH_TOKEN': 'refresh',
      });
      expect(session.accessToken, 'new-access');
      expect(session.refreshToken, 'refresh');
    },
  );
  test(
    'Legacy dev token is ignored, new tokens never persist, logout clears state',
    () async {
      SharedPreferences.setMockInitialValues({
        'dev_token': 'mock-token',
        'dev_user': 'Mock',
        'onboarded': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(container.read(authProvider).loggedIn, false);
      await container
          .read(authProvider.notifier)
          .acceptSession(
            const AuthSession(
              accessToken: 'actual-token',
              label: 'An',
              refreshToken: 'refresh',
            ),
          );
      expect(container.read(authProvider).token, 'actual-token');
      expect(prefs.getKeys().where((k) => k.contains('token')), isEmpty);
      await container.read(authProvider.notifier).logout();
      expect(container.read(authProvider).loggedIn, false);
    },
  );
  test(
    'A delayed 401 from an old request does not expire a newer session',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      await container.read(authProvider.notifier).setToken('old', 'Old');
      final gate = Completer<ResponseBody>();
      final started = Completer<void>();
      final dio = container.read(dioProvider)
        ..httpClientAdapter = Adapter((r) {
          started.complete();
          return gate.future;
        });
      final pending = dio.get('/me');
      await started.future;
      await container.read(authProvider.notifier).setToken('new', 'New');
      gate.complete(response({'code': 'TOKEN_EXPIRED'}, 401));
      await expectLater(pending, throwsA(isA<DioException>()));
      expect(container.read(authProvider).token, 'new');
      dio.httpClientAdapter = Adapter(
        (r) => response({'code': 'TOKEN_EXPIRED'}, 401),
      );
      await expectLater(dio.get('/me'), throwsA(isA<DioException>()));
      expect(container.read(authProvider).loggedIn, false);
    },
  );
}
