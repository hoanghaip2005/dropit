import 'dart:async';
import 'dart:convert';

import 'package:dropit/core/auth.dart';
import 'package:dropit/core/session_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryTabStorage implements SessionStorage {
  String? value;
  @override
  String? read() => value;
  @override
  void write(String data) => value = data;
  @override
  void clear() => value = null;
}

class RefreshApi extends ProductionAuthApi {
  RefreshApi() : super(clientId: 'testclient');
  int calls = 0;
  Completer<AuthSession>? pending;
  bool fail = false;
  @override
  Future<AuthSession> refresh(AuthSession session) async {
    calls++;
    expect(session.accessToken, isEmpty);
    expect(session.refreshToken, 'refresh-secret');
    if (pending != null) return pending!.future;
    if (fail) throw const AuthFailure('Expired');
    return AuthSession(
      accessToken: 'fresh-access',
      label: session.label,
      refreshToken: 'refresh-secret',
    );
  }
}

Future<ProviderContainer> createContainer(
  MemoryTabStorage storage,
  RefreshApi api,
) async {
  SharedPreferences.setMockInitialValues({'onboarded': true});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      sessionStorageProvider.overrideWithValue(storage),
      productionAuthApiProvider.overrideWithValue(api),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

String saved({bool expired = false, String client = 'testclient'}) =>
    jsonEncode({
      'refreshToken': 'refresh-secret',
      'label': 'Demo',
      'clientId': client,
      'expiresAt': DateTime.now()
          .toUtc()
          .add(Duration(hours: expired ? -1 : 1))
          .toIso8601String(),
    });

void main() {
  test('Reload authenticates with Cognito before exposing a session', () async {
    final storage = MemoryTabStorage()..value = saved();
    final api = RefreshApi()..pending = Completer<AuthSession>();
    final container = await createContainer(storage, api);
    final restoring = container.read(authProvider.notifier).restoreSession();
    expect(container.read(authProvider).loggedIn, false);
    api.pending!.complete(
      const AuthSession(
        accessToken: 'fresh-access',
        label: 'Demo',
        refreshToken: 'refresh-secret',
      ),
    );
    await restoring;
    expect(container.read(authProvider).token, 'fresh-access');
    expect(api.calls, 1);
    expect(storage.value, isNot(contains('fresh-access')));
  });

  test(
    'Saving a session stores refresh credential only; logout erases it',
    () async {
      final storage = MemoryTabStorage();
      final container = await createContainer(storage, RefreshApi());
      await container
          .read(authProvider.notifier)
          .acceptSession(
            const AuthSession(
              accessToken: 'access-secret',
              label: 'Demo',
              refreshToken: 'refresh-secret',
            ),
          );
      final value = jsonDecode(storage.value!) as Map;
      expect(value['refreshToken'], 'refresh-secret');
      expect(value.containsKey('accessToken'), false);
      expect(value.containsKey('password'), false);
      expect(
        container
            .read(prefsProvider)
            .getKeys()
            .where((k) => k.contains('token')),
        isEmpty,
      );
      await container.read(authProvider.notifier).logout();
      expect(storage.value, isNull);
      expect(container.read(authProvider).loggedIn, false);
    },
  );

  for (final raw in [
    'malformed',
    saved(expired: true),
    saved(client: 'anotherclient'),
  ]) {
    test(
      'Invalid saved session is cleared without authenticating: ${raw == 'malformed' ? 'malformed' : 'expired or wrong client'}',
      () async {
        final storage = MemoryTabStorage()..value = raw;
        final api = RefreshApi();
        final container = await createContainer(storage, api);
        await container.read(authProvider.notifier).restoreSession();
        expect(api.calls, 0);
        expect(storage.value, isNull);
        expect(container.read(authProvider).loggedIn, false);
      },
    );
  }

  test(
    'Rejected refresh credentials cannot restore an authenticated session',
    () async {
      final storage = MemoryTabStorage()..value = saved();
      final api = RefreshApi()..fail = true;
      final container = await createContainer(storage, api);
      await container.read(authProvider.notifier).restoreSession();
      expect(container.read(authProvider).loggedIn, false);
      expect(storage.value, isNull);
    },
  );

  test('Logout wins over an in-flight restore', () async {
    final storage = MemoryTabStorage()..value = saved();
    final api = RefreshApi()..pending = Completer<AuthSession>();
    final container = await createContainer(storage, api);
    final restore = container.read(authProvider.notifier).restoreSession();
    await container.read(authProvider.notifier).logout();
    api.pending!.complete(
      const AuthSession(
        accessToken: 'late-access',
        label: 'Demo',
        refreshToken: 'refresh-secret',
      ),
    );
    await restore;
    expect(container.read(authProvider).loggedIn, false);
    expect(storage.value, isNull);
  });
}
