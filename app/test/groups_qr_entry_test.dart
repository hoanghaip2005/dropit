import 'package:dropit/core/models.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/groups/group_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('group actions fit at ${width.toInt()}px and open QR scanner', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1280);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/groups',
        routes: [
          GoRoute(path: '/groups', builder: (_, _) => const GroupsScreen()),
          GoRoute(
            path: '/join',
            builder: (_, _) => const Scaffold(body: Text('MANUAL_JOIN')),
          ),
          GoRoute(
            path: '/scan-invite',
            builder: (_, _) => const Scaffold(body: Text('QR_SCANNER')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myGroupsProvider.overrideWith(
              (ref) async => [
                MyGroup.fromJson({
                  'group_id': 'g',
                  'name': 'Nhóm thử nghiệm',
                  'role': 'MEMBER',
                  'status': 'ACTIVE',
                  'member_count': 1,
                }),
              ],
            ),
          ],
          child: MaterialApp.router(
            theme: buildLightTheme(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('joinGroupManually')), findsOneWidget);
      expect(find.byKey(const Key('scanInviteQr')), findsOneWidget);
      await tester.tap(find.byKey(const Key('scanInviteQr')));
      await tester.pumpAndSettle();
      expect(find.text('QR_SCANNER'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('manual group-code entry remains available', (tester) async {
    final router = GoRouter(
      initialLocation: '/groups',
      routes: [
        GoRoute(path: '/groups', builder: (_, _) => const GroupsScreen()),
        GoRoute(
          path: '/join',
          builder: (_, _) => const Scaffold(body: Text('MANUAL_JOIN')),
        ),
        GoRoute(
          path: '/scan-invite',
          builder: (_, _) => const Scaffold(body: Text('QR_SCANNER')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myGroupsProvider.overrideWith(
            (ref) async => [
              MyGroup.fromJson({
                'group_id': 'g',
                'name': 'Nhóm thử nghiệm',
                'role': 'MEMBER',
                'status': 'ACTIVE',
                'member_count': 1,
              }),
            ],
          ),
        ],
        child: MaterialApp.router(
          theme: buildLightTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('joinGroupManually')));
    await tester.pumpAndSettle();
    expect(find.text('MANUAL_JOIN'), findsOneWidget);
  });
}
