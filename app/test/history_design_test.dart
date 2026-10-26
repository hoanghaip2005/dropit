import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/models_ext.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/history/history_screen.dart';

MySessionResult record(String id, String? at) => MySessionResult.fromJson({
  'session_id': id,
  'started_at': at,
  'group_name': 'Nhóm $id',
  'final_state': 'COMPLETED',
  'focus_seconds': 600,
  'coins_awarded': 10,
});

void main() {
  test('Vietnamese midnight uses UTC+7 across month/year boundaries', () {
    expect(
      historyNextMidnight(DateTime.parse('2026-12-31T16:59:59Z')),
      DateTime.parse('2026-12-31T17:00:00Z'),
    );
    expect(
      historyNextMidnight(DateTime.parse('2026-12-31T17:00:00Z')),
      DateTime.parse('2027-01-01T17:00:00Z'),
    );
  });
  test(
    'Selected past day, week and month have exclusive upper bounds in VN',
    () {
      final rows = [
        record('before', '2026-09-30T16:59:59Z'),
        record('in', '2026-09-30T17:00:00Z'),
        record('after', '2026-10-01T17:00:00Z'),
      ];
      final day = historyInPeriod(
        rows,
        now: DateTime.parse('2026-10-22T05:00:00Z'),
        period: HistoryPeriod.day,
        selectedDay: DateTime(2026, 10, 1),
      );
      expect(day.map((r) => r.sessionId), ['in']);
      expect(historyFocusDuration(870), '14 phút 30 giây');
      expect(historyFocusDuration(0), '0 phút');
    },
  );
  testWidgets(
    'Actual focus, explicit mode, actual exit and completion clocks survive day selection',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now().toUtc();
      final rows = [
        MySessionResult.fromJson({
          'session_id': 'exit',
          'group_name': 'Tên nhóm rất dài để kiểm tra xuống dòng tiếng Việt',
          'started_at': now
              .subtract(const Duration(minutes: 30))
              .toIso8601String(),
          'exited_at': now
              .subtract(const Duration(minutes: 16))
              .toIso8601String(),
          'final_state': 'EXITED',
          'session_mode': 'SQUAD',
          'focus_seconds': 840,
          'duration_min': 25,
        }),
        MySessionResult.fromJson({
          'session_id': 'done',
          'group_name': 'Cá nhân thực',
          'started_at': now
              .subtract(const Duration(minutes: 60))
              .toIso8601String(),
          'ended_at': now
              .subtract(const Duration(minutes: 35))
              .toIso8601String(),
          'final_state': 'COMPLETED',
          'session_mode': 'SOLO',
          'focus_seconds': 1500,
        }),
        MySessionResult.fromJson({
          'session_id': 'lost',
          'started_at': now
              .subtract(const Duration(minutes: 90))
              .toIso8601String(),
          'final_state': 'LOST',
          'focus_seconds': 120,
          'session_mode': null,
        }),
      ];
      final ranges = <(String, String)>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyPeriodProvider.overrideWith((ref, range) async {
              ranges.add(range);
              return HistoryPage(rows, null);
            }),
            historyRewardTodayProvider.overrideWith(
              (ref) async => HistoryRewardToday.fromJson({
                'reward_date': 'today',
                'coins_awarded': 40,
                'daily_cap': 100,
              }),
            ),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const HistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Squad'), findsOneWidget);
      expect(find.text('Cá nhân'), findsOneWidget);
      expect(find.text('14 phút tập trung'), findsOneWidget);
      expect(find.text('Rời sớm'), findsOneWidget);
      expect(find.text('Mất kết nối quá hạn'), findsOneWidget);
      expect(find.textContaining('Rời lúc'), findsOneWidget);
      expect(find.textContaining('Hoàn thành lúc'), findsOneWidget);
      expect(find.text('40 / 100 Coins'), findsOneWidget);
      await tester.tap(find.text('Ngày'));
      await tester.pumpAndSettle();
      expect(ranges.length, 2);
      expect(
        DateTime.parse(
          ranges.last.$2,
        ).difference(DateTime.parse(ranges.last.$1)),
        const Duration(days: 1),
      );
      await tester.tap(find.byKey(const Key('historyDatePicker')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.text('Chọn ngày xem lịch sử'), findsOneWidget);
      await tester.tap(find.byTooltip('Switch to input'));
      await tester.pumpAndSettle();
      final local = now.add(const Duration(hours: 7));
      final chosen = DateTime(
        local.year,
        local.month,
        local.day,
      ).subtract(const Duration(days: 2));
      await tester.enterText(
        find.byType(TextField),
        '${chosen.month}/${chosen.day}/${chosen.year}',
      );
      await tester.tap(find.text('Chọn'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(
        ranges.last.$1,
        DateTime.utc(
          chosen.year,
          chosen.month,
          chosen.day,
        ).subtract(const Duration(hours: 7)).toIso8601String(),
      );
      expect(
        find.text('Không có phiên đã tải trong khoảng thời gian này.'),
        findsOneWidget,
      );
      expect(find.text('40 / 100 Coins'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Today reward never fabricates zero while loading or error; retry fetches summary',
    (tester) async {
      final pending = Completer<HistoryRewardToday>();
      var requests = 0;
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            historyPeriodProvider.overrideWith(
              (ref, range) async => HistoryPage([], null),
            ),
            historyRewardTodayProvider.overrideWith((ref) {
              requests++;
              return requests == 1
                  ? pending.future
                  : Future.value(
                      HistoryRewardToday.fromJson({
                        'reward_date': 'today',
                        'coins_awarded': 12,
                        'daily_cap': 100,
                      }),
                    );
            }),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const HistoryScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('historyRewardLoading')), findsOneWidget);
      expect(find.byKey(const Key('historyRewardValue')), findsNothing);
      pending.completeError(Exception('reward failed'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('historyRewardError')), findsOneWidget);
      expect(find.byKey(const Key('historyRewardValue')), findsNothing);
      await tester.tap(find.byTooltip('Thử tải phần thưởng lại'));
      await tester.pumpAndSettle();
      expect(find.text('12 / 100 Coins'), findsOneWidget);
      expect(requests, 2);
    },
  );
  testWidgets(
    'Loading becomes error, retry reloads and shows period empty state',
    (tester) async {
      final pending = Completer<HistoryPage>();
      var requests = 0;
      await tester.pumpWidget(
        ProviderScope(
          retry: (retryCount, error) => null,
          overrides: [
            historyRewardTodayProvider.overrideWith(
              (ref) async => HistoryRewardToday.fromJson({
                'reward_date': '2026-10-22',
                'coins_awarded': 30,
                'daily_cap': 100,
              }),
            ),
            historyPeriodProvider.overrideWith((ref, range) {
              requests++;
              return requests == 1
                  ? pending.future
                  : Future.value(
                      HistoryPage([
                        record('old', '2020-01-01T00:00:00Z'),
                      ], null),
                    );
            }),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const HistoryScreen(),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('skeleton0')), findsOneWidget);
      await tester.pump();
      expect(find.text('30 / 100 Coins'), findsOneWidget);
      expect(find.byKey(const Key('historyDatePicker')), findsOneWidget);
      pending.completeError(Exception('test failure'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa tải được lịch sử phiên.'), findsOneWidget);
      expect(find.text('30 / 100 Coins'), findsOneWidget);
      expect(find.byKey(const Key('historyDatePicker')), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(requests, 2);
      expect(
        find.text('Không có phiên đã tải trong khoảng thời gian này.'),
        findsOneWidget,
      );
      expect(find.text('Nhóm old'), findsNothing);
      expect(find.byKey(const Key('historyPartialNotice')), findsNothing);
    },
  );
  final now = DateTime.parse('2026-10-22T05:00:00Z');
  test(
    'Vietnamese week excludes prior week, future and unknown dates; sorts newest first',
    () {
      final rows = [
        record('old', '2026-10-18T16:59:59Z'),
        record('boundary', '2026-10-18T17:00:00Z'),
        record('future', '2026-10-22T05:00:01Z'),
        record('unknown', null),
        record('latest', '2026-10-22T05:00:00Z'),
      ];
      expect(
        historyInPeriod(rows, now: now, month: false).map((r) => r.sessionId),
        ['latest', 'boundary'],
      );
      expect(rows.first.sessionId, 'old');
    },
  );
  test('Vietnamese month uses local first day and rejects previous year', () {
    final rows = [
      record('before', '2026-09-30T16:59:59Z'),
      record('boundary', '2026-09-30T17:00:00Z'),
      record('year', '2025-10-21T00:00:00Z'),
    ];
    expect(
      historyInPeriod(rows, now: now, month: true).map((r) => r.sessionId),
      ['boundary'],
    );
    expect(
      historyDay(DateTime.parse('2025-12-31T18:00:00Z')),
      DateTime(2026, 1, 1),
    );
  });
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('History period keeps rows and statistics together at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1024);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final instant = DateTime.now().toUtc();
      final local = instant.add(const Duration(hours: 7));
      final startWeek = DateTime.utc(
        local.year,
        local.month,
        local.day,
      ).subtract(Duration(days: local.weekday - 1, hours: 7));
      final prior = startWeek.subtract(const Duration(minutes: 1));
      final canCompare =
          prior.add(const Duration(hours: 7)).month == local.month;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRewardTodayProvider.overrideWith(
              (ref) async => HistoryRewardToday.fromJson({
                'reward_date': '2026-10-22',
                'coins_awarded': 30,
                'daily_cap': 100,
              }),
            ),
            historyPeriodProvider.overrideWith(
              (ref, range) async => HistoryPage([
                record('hiện tại', instant.toIso8601String()),
                if (canCompare) record('trước tuần', prior.toIso8601String()),
              ], 'next'),
            ),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const HistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nhóm trước tuần'), findsNothing);
      expect(find.text('10'), findsOneWidget);
      expect(find.byKey(const Key('historyPartialNotice')), findsOneWidget);
      final selectedBefore = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((widget) => widget.properties.selected == true);
      expect(selectedBefore, hasLength(1));
      await tester.scrollUntilVisible(find.text('Nhóm hiện tại'), 200);
      expect(find.text('Nhóm hiện tại'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tháng'));
      await tester.pumpAndSettle();
      if (canCompare) {
        expect(find.text('20'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Nhóm trước tuần'), 200);
        expect(find.text('Nhóm trước tuần'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
