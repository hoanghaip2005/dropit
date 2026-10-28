import 'package:dropit/core/models.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/reports/report_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('owner edits schedule directly from hub at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var loads = 0;
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const OwnerScheduleHubScreen()),
        GoRoute(
          path: '/owner/sessions/:id/edit',
          builder: (context, state) => Scaffold(body: TextButton(
            onPressed: () => context.pop(),
            child: Text('Sửa ${state.pathParameters['id']}'),
          )),
        ),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(overrides: [
        myGroupsProvider.overrideWith((ref) async => [MyGroup.fromJson({
          'group_id': 'g', 'role': 'OWNER', 'name': 'Nhóm thử nghiệm lịch dài',
        })]),
        schedulesProvider('g').overrideWith((ref) async {
          loads++;
          return [SessionSummary.fromJson({
            'session_id': 's', 'group_id': 'g', 'duration_min': 45,
            'started_at': DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String(),
          })];
        }),
      ], child: MaterialApp.router(theme: buildOwnerTheme(), routerConfig: router)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('editSchedule-s')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('editSchedule-s')));
      await tester.pumpAndSettle();
      expect(find.text('Sửa s'), findsOneWidget);
      await tester.tap(find.text('Sửa s'));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(find.byKey(const ValueKey('editSchedule-s')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
