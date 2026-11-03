import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/profile/my_data_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'Former owner discovers archived reports without active membership',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const MyDataScreen()),
          GoRoute(
            path: '/reports/g',
            builder: (_, _) =>
                const Scaffold(body: Text('Fixture archived report')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myDataProvider(null).overrideWith(
              (ref) async => (
                cachedAt: null,
                data: <String, dynamic>{
                  'groups': [],
                  'owned_reports': [
                    {
                      'group_id': 'g',
                      'group_name': 'Fixture group',
                      'group_status': 'DISSOLVED',
                      'month': '2026-10',
                    },
                  ],
                },
              ),
            ),
          ],
          child: MaterialApp.router(
            theme: buildLightTheme(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
    final entry = find.text('Fixture group');
      await tester.scrollUntilVisible(entry, 400);
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
    expect(find.text('Nhóm đã giải tán · Xem các kỳ báo cáo'), findsOneWidget);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.text('Fixture archived report'), findsOneWidget);
    },
  );
}
