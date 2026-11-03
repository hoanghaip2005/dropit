import 'package:dio/dio.dart';
import 'package:dropit/app/router.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/auth.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'registration_screen_test.dart' show RegistrationApi;

class FlowAuth extends AuthController {
  @override
  AuthState build() => const AuthState(deviceId: 'fixture', onboarded: true);

  @override
  Future<void> acceptSession(AuthSession session) async {
    state = state.copyWith(token: session.accessToken, onboarded: true);
  }
}

class FlowApi extends DropItApi {
  FlowApi() : super(Dio());
  int joins = 0;
  @override
  Future<void> acceptConsent(
    String groupId, {
    required int version,
    required String code,
    required List<String> items,
  }) async {
    expect(groupId, 'g');
    expect(code, 'AB3CD7EF');
    expect(items, ['RULE']);
    joins++;
  }

  @override
  Future<MeProfile> updateMe(String name) async =>
      MeProfile.fromJson({'user_id': 'fixture', 'display_name': name});
}

void main() {
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    required RegistrationApi auth,
    bool loggedIn = false,
    String? location,
  }) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(FlowAuth.new),
        productionAuthApiProvider.overrideWithValue(auth),
        apiProvider.overrideWithValue(FlowApi()),
        myGroupsProvider.overrideWith((ref) async => []),
        meProvider.overrideWith(
          (ref) async => MeProfile.fromJson({
            'user_id': 'fixture',
            'display_name': 'Demo',
          }),
        ),
        upcomingProvider.overrideWith(
          (ref) => throw StateError('No group: must not load sessions'),
        ),
        invitePreviewProvider('AB3CD7EF').overrideWith(
          (ref) async => ConsentDocument.fromJson({
            'group_id': 'g',
            'group_name': 'Fixture group',
            'items': [
              {'code': 'RULE', 'text': 'Fixture rule', 'required': true},
            ],
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    if (loggedIn) {
      await container
          .read(authProvider.notifier)
          .acceptSession(
            const AuthSession(accessToken: 'fixture', label: 'Demo'),
          );
    }
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    if (location != null) router.go(location);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: buildLightTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  for (final next in ['', '?next=%2Fconsent%2FAB3CD7EF']) {
    testWidgets('Verified signup goes home, optional invite=$next', (
      tester,
    ) async {
      final auth = RegistrationApi();
      final container = await mount(
        tester,
        auth: auth,
        location: '/register$next',
      );
      final fields = find.byType(TextFormField);
      for (final entry in [
        'Demo',
        'demo@example.org',
        'ExamplePass123!',
        'ExamplePass123!',
      ].asMap().entries) {
        await tester.enterText(fields.at(entry.key), entry.value);
      }
      await tester.ensureVisible(find.text('Tạo tài khoản'));
      await tester.tap(find.text('Tạo tài khoản'));
      await tester.pumpAndSettle();
      expect(container.read(authProvider).loggedIn, false);
      expect(find.text('Xác minh email'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.ensureVisible(find.text('Xác minh và tiếp tục'));
      await tester.tap(find.text('Xác minh và tiếp tục'));
      await tester.pumpAndSettle();
      expect(container.read(authProvider).loggedIn, true);
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/home',
      );
      expect(find.text('Bạn chưa ở nhóm nào'), findsOneWidget);
      expect(find.text('Tham gia nhóm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Authenticated account without group can reopen home and return from login',
    (tester) async {
      final container = await mount(
        tester,
        auth: RegistrationApi(),
        loggedIn: true,
      );
      expect(find.text('Bạn chưa ở nhóm nào'), findsOneWidget);
      container.read(routerProvider).go('/login');
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/home',
      );
      expect(find.text('Bạn chưa ở nhóm nào'), findsOneWidget);
    },
  );

  testWidgets('Home joins only on demand and opens existing consent step', (
    tester,
  ) async {
    final container = await mount(
      tester,
      auth: RegistrationApi(),
      loggedIn: true,
    );
    await tester.tap(find.text('Tham gia nhóm'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inviteCodeField')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('inviteCodeField')),
      'AB3CD7EF',
    );
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('Quy tắc minh bạch'), findsOneWidget);
    expect(find.byKey(const Key('consent_RULE')), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('consent_RULE')))
          .value,
      false,
    );
    final api = container.read(apiProvider) as FlowApi;
    expect(api.joins, 0);
    await tester.scrollUntilVisible(
      find.byKey(const Key('acceptConsent')),
      300,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('acceptConsent')))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byKey(const Key('consent_RULE')));
    await tester.tap(find.byKey(const Key('consent_RULE')));
    await tester.ensureVisible(find.byKey(const Key('acceptConsent')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('acceptConsent')));
    await tester.pumpAndSettle();
    expect(api.joins, 1);
    expect(find.text('Bạn chưa ở nhóm nào'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Signing in again without membership opens home', (tester) async {
    final container = await mount(
      tester,
      auth: RegistrationApi(),
      location: '/login',
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'demo@example.org',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'ExamplePass123!');
    final submit = find.byType(FilledButton);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(container.read(authProvider).loggedIn, true);
    expect(find.text('Bạn chưa ở nhóm nào'), findsOneWidget);
  });
}
