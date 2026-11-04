import 'package:dropit/core/models.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/home/home_ad_carousel.dart';
import 'package:dropit/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> mount(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
    await tester.pump();
  }

  testWidgets('sits between the Coins summary and streak on member Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    MyGroup fixtureGroup(String id, String role) => MyGroup.fromJson({
      'group_id': id,
      'name': 'Nhóm $id',
      'role': role,
      'status': 'ACTIVE',
      'member_count': 4,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myGroupsProvider.overrideWith(
            (ref) async => [
              fixtureGroup('member', 'MEMBER'),
              fixtureGroup('owner', 'OWNER'),
            ],
          ),
          meProvider.overrideWith(
            (ref) async => MeProfile.fromJson({
              'user_id': 'fixture',
              'display_name': 'An',
              'coins_balance': 50,
              'current_streak': 7,
            }),
          ),
          upcomingProvider.overrideWith((ref) async => null),
          coinsTodayProvider.overrideWith((ref) async => 24),
        ],
        child: MaterialApp(theme: buildLightTheme(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final coinsTop = tester.getTopLeft(find.byKey(const Key('coinsToday'))).dy;
    final adTop = tester.getTopLeft(find.byKey(const Key('homeAdPageView'))).dy;
    final streakTop = tester.getTopLeft(find.text('7 ngày')).dy;
    expect(adTop, greaterThan(coinsTop));
    expect(adTop, lessThan(streakTop));
    expect(find.text('Nhóm tôi quản lý'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows three clearly marked sample ads and advances every 5s', (
    tester,
  ) async {
    await mount(tester, const HomeAdCarousel());

    expect(find.text('QUẢNG CÁO MẪU · 1/3'), findsOneWidget);
    expect(find.text('Bắt đầu từ một mục tiêu nhỏ'), findsOneWidget);
    expect(find.byKey(const Key('homeAdDot_0')), findsOneWidget);
    expect(find.byKey(const Key('homeAdDot_1')), findsOneWidget);
    expect(find.byKey(const Key('homeAdDot_2')), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('QUẢNG CÁO MẪU · 2/3'), findsOneWidget);
    expect(find.text('Dành thời gian cho điều quan trọng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports swiping and page-dot selection', (tester) async {
    await mount(tester, const HomeAdCarousel());

    await tester.drag(
      find.byKey(const Key('homeAdPageView')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('QUẢNG CÁO MẪU · 2/3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('homeAdDot_2')));
    await tester.pumpAndSettle();
    expect(find.text('QUẢNG CÁO MẪU · 3/3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pauses while Home is covered by another route', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const HomeAdCarousel(),
          floatingActionButton: Builder(
            builder: (context) => FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Back'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('QUẢNG CÁO MẪU · 1/3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('QUẢNG CÁO MẪU · 2/3'), findsOneWidget);
  });

  testWidgets('pauses in background and resumes in foreground', (tester) async {
    await mount(tester, const HomeAdCarousel());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('QUẢNG CÁO MẪU · 1/3'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('QUẢNG CÁO MẪU · 2/3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adapts to a narrow viewport and enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Scaffold(body: HomeAdCarousel()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('homeAdPageView')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
