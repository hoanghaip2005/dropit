import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dropit/core/auth.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/push.dart';

class Client implements PushClient {
  @override
  bool available = true;
  AuthorizationStatus status = AuthorizationStatus.authorized;
  final requests = <bool>[];
  Completer<String?>? pending;
  @override
  Future<AuthorizationStatus> permission({bool request = false}) async {
    requests.add(request);
    return status;
  }

  @override
  Future<String?> token() async =>
      pending == null ? 'fcm-token' : pending!.future;
  @override
  Stream<String> get tokenChanges => const Stream.empty();
  @override
  Stream<RemoteMessage> get messages => const Stream.empty();
  @override
  Stream<RemoteMessage> get opened => const Stream.empty();
  @override
  Future<RemoteMessage?> initial() async => null;
}

class Auth extends AuthController {
  @override
  AuthState build() => const AuthState(token: 'session', deviceId: 'device');
}

class Api extends DropItApi {
  Api() : super(Dio());
  final registered = <String>[];
  int removed = 0;
  bool failRemove = false;
  bool fail = false;
  @override
  Future<void> registerPushDevice(
    String deviceId,
    String token,
    String platform,
  ) async {
    if (fail) throw StateError('private server detail');
    registered.add(token);
  }

  @override
  Future<void> removePushDevice(String deviceId) async {
    removed++;
    if (failRemove) throw StateError('offline');
  }
}

void main() {
  late Client client;
  late Api api;
  late ProviderContainer c;
  setUp(() {
    client = Client();
    api = Api();
    c = ProviderContainer(
      overrides: [
        authProvider.overrideWith(Auth.new),
        pushClientProvider.overrideWithValue(client),
        apiProvider.overrideWithValue(api),
      ],
    );
  });
  tearDown(() => c.dispose());
  test('Status check never prompts; authorized token registers', () async {
    await c.read(pushControllerProvider.notifier).sync();
    expect(client.requests, [false]);
    expect(api.registered, ['fcm-token']);
    expect(c.read(pushControllerProvider).registered, true);
  });
  test('Denied permission removes binding and does not block auth', () async {
    client.status = AuthorizationStatus.denied;
    await c.read(pushControllerProvider.notifier).sync();
    expect(api.registered, isEmpty);
    expect(api.removed, 1);
    expect(c.read(authProvider).loggedIn, true);
  });
  test('Explicit permission action requests only when requested', () async {
    client.status = AuthorizationStatus.notDetermined;
    await c.read(pushControllerProvider.notifier).sync(request: true);
    expect(client.requests, [false, true]);
  });
  test('Registration failure is safe, retry remains available', () async {
    api.fail = true;
    await c.read(pushControllerProvider.notifier).sync();
    expect(c.read(pushControllerProvider).registered, false);
    expect(
      c.read(pushControllerProvider).error,
      isNot(contains('private server detail')),
    );
    api.fail = false;
    await c.read(pushControllerProvider.notifier).sync();
    expect(c.read(pushControllerProvider).registered, true);
  });
  test('Logout stop prevents pending token from registering', () async {
    client.pending = Completer<String?>();
    final pending = c.read(pushControllerProvider.notifier).sync();
    await Future<void>.delayed(Duration.zero);
    final stopped = c.read(pushControllerProvider.notifier).stop();
    client.pending!.complete('late-token');
    await pending;
    await stopped;
    expect(api.registered, isEmpty);
    expect(c.read(pushControllerProvider).busy, false);
  });
  test('Repeated calls serialize pending registration', () async {
    client.pending = Completer<String?>();
    final first = c.read(pushControllerProvider.notifier).sync();
    await c.read(pushControllerProvider.notifier).sync(request: true);
    client.pending!.complete('one-token');
    await first;
    expect(api.registered, ['one-token', 'one-token']);
    expect(client.requests, [false, false]);
  });
  test(
    'Unavailable configuration never contacts backend or requests permission',
    () async {
      client.available = false;
      await c.read(pushControllerProvider.notifier).sync(request: true);
      expect(client.requests, isEmpty);
      expect(api.registered, isEmpty);
    },
  );
  test('Untrusted push URL cannot navigate outside authenticated inbox', () {
    expect(
      pushDestination({
        'route': 'https://evil.invalid',
        'session_id': '../../login',
      }),
      '/notifications',
    );
  });
  test(
    'Denied request failure keeps known permission and never prompts again',
    () async {
      client.status = AuthorizationStatus.denied;
      api.failRemove = true;
      await c.read(pushControllerProvider.notifier).sync(request: true);
      expect(c.read(pushControllerProvider).status, AuthorizationStatus.denied);
      expect(c.read(pushControllerProvider).canRequest, false);
      await c.read(pushControllerProvider.notifier).sync(request: true);
      expect(client.requests, [false, true, false]);
    },
  );
}
