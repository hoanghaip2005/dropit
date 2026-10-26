import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/session/result_screen.dart';

MySessionResult result([Map<String, dynamic> fields = const {}]) =>
    MySessionResult.fromJson({
      'session_id': 's',
      'group_name': 'Nhóm tập trung',
      'session_mode': 'SQUAD',
      'started_at': '2026-10-21T17:00:00Z',
      'joined_at': '2026-10-21T17:01:00Z',
      'exited_at': '2026-10-21T17:14:30Z',
      'ended_at': '2026-10-21T17:14:30Z',
      'duration_min': 25,
      'focus_seconds': 810,
      'final_state': 'EXITED',
      'coins_awarded': 0,
      'streak_after': 3,
      ...fields,
    });

Widget host(
  Future<MySessionResult> Function() load, {
  bool fromHistory = true,
}) => ProviderScope(
  retry: (_, _) => null,
  overrides: [resultProvider('s').overrideWith((ref) => load())],
  child: MaterialApp(
    theme: buildLightTheme(),
    home: ResultScreen(sessionId: 's', fromHistory: fromHistory),
  ),
);

void main() {
  test(
    'Result copy uses actual award, generic cap, forfeit flag and outage exception',
    () {
      expect(
        ResultCopy.of(
          result({'final_state': 'COMPLETED', 'coins_awarded': 0}),
        ).label,
        'Hoàn thành',
      );
      final capped = ResultCopy.of(
        result({'final_state': 'COMPLETED', 'reward_cap_reached': true}),
      );
      expect(capped.coins, isNot(contains('100')));
      expect(capped.label, 'Hoàn thành');
      expect(
        ResultCopy.of(result({'forfeited': false})).reason,
        isNot(contains('mất thưởng tập thể')),
      );
      expect(
        ResultCopy.of(result({'forfeited': true})).reason,
        contains('mất thưởng tập thể'),
      );
      final outage = ResultCopy.of(
        result({'forfeited': true, 'cancelled_outage_exited': true}),
      );
      expect(outage.reason, contains('không tính'));
      expect(outage.reason, isNot(contains('mất thưởng tập thể')));
      expect(outage.coins, 'Không tính');
      expect(resultFocusDuration(59), '0 phút 59 giây');
      expect(
        resultTimestamp(DateTime.parse('2026-10-21T17:14:30Z')),
        '22/10/2026 · 00:14',
      );
    },
  );

  for (final state in [
    'EXITED',
    'LOST',
    'ABSENT',
    'VOID',
    'WITHDRAWN',
    'COMPLETED',
  ]) {
    testWidgets(
      'Result retains semantic state $state, real duration and privacy',
      (tester) async {
        final data = result({
          'final_state': state,
          'coins_awarded': state == 'COMPLETED' ? 10 : 0,
          'streak_broken': true,
          'participants': [
            {
              'display_name': 'Zebra',
              'final_state': 'LOST',
              'coins_awarded': 999,
              'streak': 999,
              'explanation': 'secret',
            },
            {'display_name': 'An', 'final_state': 'EXITED'},
          ],
        });
        await tester.pumpWidget(host(() async => data));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.byKey(const Key('resultLabel'))).data,
          ResultCopy.of(data).label,
        );
        expect(find.text('13 phút 30 giây tập trung'), findsOneWidget);
        expect(find.text('25 phút'), findsOneWidget);
        expect(find.text('Squad'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Chuỗi hiện tại'), 250);
        expect(find.text('3 ngày'), findsOneWidget);
        expect(
          find.text('Phiên này đã làm ngắt chuỗi của bạn.'),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(find.text('Zebra'), 250);
        expect(
          tester.getTopLeft(find.text('An')).dy,
          lessThan(tester.getTopLeft(find.text('Zebra')).dy),
        );
        expect(find.textContaining('999'), findsNothing);
        expect(find.textContaining('secret'), findsNothing);
        expect(find.byKey(const Key('explainButton')), findsNothing);
        expect(find.byKey(const Key('appealButton')), findsNothing);
        expect(find.byKey(const Key('resultHomeButton')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets(
      'Long result wraps at $width with text scale 1.5 and null timestamps',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1024);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final data = result({
          'group_name':
              'Nhóm thiết kế sản phẩm và nghiên cứu trải nghiệm người dùng tên rất dài',
          'session_mode': null,
          'started_at': null,
          'joined_at': null,
          'exited_at': null,
          'ended_at': null,
          'forfeited': true,
          'forfeit_trigger_display_name':
              'Thành viên tên rất dài để kiểm tra xuống dòng',
          'exempted': true,
          'participants': [
            {
              'display_name':
                  'Thành viên tên rất dài cần hiển thị đầy đủ không bị che',
              'final_state': 'WITHDRAWN',
            },
          ],
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [resultProvider('s').overrideWith((ref) async => data)],
            child: MaterialApp(
              theme: buildLightTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
              home: const ResultScreen(sessionId: 's', fromHistory: true),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Chưa rõ chế độ'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Rời phiên lúc'), 250);
        expect(find.text('Chưa có dữ liệu'), findsWidgets);
        await tester.scrollUntilVisible(find.text('Đã được miễn trừ'), 250);
        expect(find.text('Đã được miễn trừ'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Xem lịch sử Coins'), 300);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Loading then server error retries; 409 has pending state', (
    tester,
  ) async {
    final pending = Completer<MySessionResult>();
    var requests = 0;
    await tester.pumpWidget(
      host(() {
        requests++;
        return requests == 1 ? pending.future : Future.value(result());
      }),
    );
    expect(find.byKey(const ValueKey('skeleton0')), findsOneWidget);
    pending.completeError(
      ApiError(message: 'Không tìm thấy phiên.', status: 404),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy phiên.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.byKey(const Key('resultLabel')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      host(
        () async => throw ApiError(
          message: 'Chưa xong',
          status: 409,
          code: 'SESSION_NOT_FINISHED',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đang chốt kết quả…'), findsOneWidget);
    expect(find.byKey(const Key('resultLabel')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      host(
        () async => throw ApiError(
          message: 'Xung đột khác.',
          status: 409,
          code: 'VERSION_CONFLICT',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đang chốt kết quả…'), findsNothing);
    expect(find.text('Xung đột khác.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets(
    'Historical back plus explanation, appeal and Coins navigate to correct routes',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/history',
        routes: [
          GoRoute(
            path: '/history',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/history/s'),
                child: const Text('Mở phiên'),
              ),
            ),
          ),
          GoRoute(
            path: '/history/s',
            builder: (_, _) =>
                const ResultScreen(sessionId: 's', fromHistory: true),
          ),
          GoRoute(
            path: '/explanation/s',
            builder: (_, _) => const Scaffold(body: Text('Trang giải trình')),
          ),
          GoRoute(
            path: '/appeal/new/s',
            builder: (_, _) => const Scaffold(body: Text('Trang khiếu nại')),
          ),
          GoRoute(
            path: '/coins',
            builder: (_, _) => const Scaffold(body: Text('Trang Coins')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resultProvider('s').overrideWith(
              (ref) async => result({
                'has_explanation': true,
                'can_explain': false,
                'can_appeal': true,
              }),
            ),
          ],
          child: MaterialApp.router(
            theme: buildLightTheme(),
            routerConfig: router,
          ),
        ),
      );
      await tester.tap(find.text('Mở phiên'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('resultHomeButton')), findsNothing);
      for (final action in [
        ('Xem giải trình', 'Trang giải trình'),
        ('Khiếu nại ghi nhầm', 'Trang khiếu nại'),
        ('Xem lịch sử Coins', 'Trang Coins'),
      ]) {
        await tester.scrollUntilVisible(find.text(action.$1), 300);
        await tester.tap(find.text(action.$1));
        await tester.pumpAndSettle();
        expect(find.text(action.$2), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Mở phiên'), findsOneWidget);
    },
  );

  testWidgets('Fresh result home action goes home', (tester) async {
    final router = GoRouter(
      initialLocation: '/result',
      routes: [
        GoRoute(
          path: '/result',
          builder: (_, _) => const ResultScreen(sessionId: 's'),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Trang chủ thử nghiệm')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [resultProvider('s').overrideWith((ref) async => result())],
        child: MaterialApp.router(
          theme: buildLightTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resultHomeButton')));
    await tester.pumpAndSettle();
    expect(find.text('Trang chủ thử nghiệm'), findsOneWidget);
  });

  testWidgets(
    'Creation permission shows send; absent permissions hide both actions',
    (tester) async {
      await tester.pumpWidget(
        host(() async => result({'can_explain': true, 'can_appeal': false})),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Gửi giải trình'), 300);
      expect(find.byKey(const Key('explainButton')), findsOneWidget);
      expect(find.byKey(const Key('appealButton')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        host(
          () async => result({'can_explain': false, 'has_explanation': false}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Xem lịch sử Coins'), 300);
      expect(find.byKey(const Key('explainButton')), findsNothing);
      expect(find.byKey(const Key('appealButton')), findsNothing);
    },
  );

  testWidgets(
    'Forbidden result shows actual error without receipt or actions',
    (tester) async {
      await tester.pumpWidget(
        host(
          () async =>
              throw ApiError(message: 'Không có quyền xem phiên.', status: 403),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Không có quyền xem phiên.'), findsOneWidget);
      expect(find.byKey(const Key('resultActualFocus')), findsNothing);
      expect(find.byKey(const Key('explainButton')), findsNothing);
    },
  );
}
