import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/models_ext.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/core/widgets.dart';
import 'package:dropit/features/appeals/appeal_screens.dart';

MySessionResult result({bool canExplain = true, String state = 'EXITED'}) =>
    MySessionResult.fromJson({
      'session_id': 's',
      'group_name': 'Nhóm thử nghiệm',
      'final_state': state,
      'session_mode': 'SQUAD',
      'started_at': '2026-10-22T02:00:00Z',
      'exited_at': '2026-10-22T02:14:30Z',
      'focus_seconds': 870,
      'duration_min': 25,
      'can_explain': canExplain,
    });
Explanation explanation({bool editable = true, String body = 'Bản đã gửi'}) =>
    Explanation.fromJson({
      'session_id': 's',
      'body': body,
      'can_edit': editable,
      'submitted_at': '2026-10-22T02:20:00Z',
      'added_after_report': true,
      'history': [
        {
          'body': 'Bản cũ',
          'written_at': '2026-10-21T00:00:00Z',
          'replaced_at': '2026-10-22T00:00:00Z',
        },
      ],
    });

class ExplanationApi extends DropItApi {
  ExplanationApi(this.send) : super(Dio());
  final Future<Explanation> Function(String) send;
  int requests = 0;
  int? lastVersion;
  @override
  Future<Explanation> submitExplanation(
    String sessionId,
    String body, {
    int? version,
  }) {
    requests++;
    lastVersion = version;
    return send(body);
  }
}

Future<void> mount(
  WidgetTester tester, {
  required Future<MySessionResult> Function() loadResult,
  required Future<Explanation?> Function() loadMine,
  ExplanationApi? api,
  Size viewport = const Size(390, 1800),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        resultProvider.overrideWith((ref, id) => loadResult()),
        myExplanationProvider.overrideWith((ref, id) => loadMine()),
        if (api != null) apiProvider.overrideWithValue(api),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const ExplanationScreen(sessionId: 's'),
      ),
    ),
  );
}

void main() {
  testWidgets('Narrow layout supports large text and keyboard draft', (
    tester,
  ) async {
    await mount(
      tester,
      loadResult: () async => result(),
      loadMine: () async => null,
      viewport: const Size(320, 740),
      textScale: 1.5,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('explanationField')),
      200,
    );
    await tester.enterText(
      find.byKey(const Key('explanationField')),
      'Lý do trên màn hình nhỏ',
    );
    await tester.pump();
    expect(
      tester
          .widget<PrimaryButton>(find.byKey(const Key('explanationSubmit')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Edit forwards version; conflict keeps draft while loading server copy',
    (tester) async {
      var version = 8;
      Explanation current() => Explanation.fromJson({
        'body': 'Bản máy chủ',
        'can_edit': true,
        'version': version,
      });
      final api = ExplanationApi((_) async {
        version = 9;
        throw ApiError(message: 'Xung đột', code: 'VERSION_CONFLICT');
      });
      await mount(
        tester,
        loadResult: () async => result(canExplain: false),
        loadMine: () async => current(),
        api: api,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('explanationField')),
        'Bản đang viết',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('explanationSubmit')));
      await tester.pumpAndSettle();
      expect(api.lastVersion, 8);
      expect(
        find.textContaining('Giải trình đã thay đổi ở nơi khác.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Tải lại quyền và trạng thái'));
      await tester.tap(find.text('Tải lại quyền và trạng thái'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('explanationField')))
            .controller!
            .text,
        'Bản đang viết',
      );
      expect(find.text('Bản máy chủ'), findsOneWidget);
    },
  );

  testWidgets(
    'Server deadline transition makes editor read-only without leaving the view',
    (tester) async {
      final deadline = DateTime.now().toUtc().add(
        const Duration(milliseconds: 100),
      );
      await mount(
        tester,
        loadResult: () async => MySessionResult.fromJson({
          'final_state': 'EXITED',
          'can_explain': true,
          'explanation_submit_deadline': deadline.toIso8601String(),
        }),
        loadMine: () async => null,
      );
      await tester.pump();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 130)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('explanationField')))
            .readOnly,
        isTrue,
      );
      expect(find.byKey(const Key('explanationSubmit')), findsNothing);
    },
  );
  testWidgets(
    'Both permission sources must finish; result error retries without editable form',
    (tester) async {
      var calls = 0;
      final pending = Completer<MySessionResult>();
      await mount(
        tester,
        loadResult: () {
          calls++;
          return calls == 1 ? pending.future : Future.value(result());
        },
        loadMine: () async => null,
      );
      await tester.pump();
      expect(find.byKey(const Key('explanationField')), findsNothing);
      pending.completeError(
        ApiError(message: 'Không tìm thấy phiên', status: 404),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa tải được thông tin giải trình.'), findsOneWidget);
      expect(find.byKey(const Key('explanationSubmit')), findsNothing);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explanationField')), findsOneWidget);
      expect(calls, 2);
    },
  );

  testWidgets('Mine error never becomes new explanation', (tester) async {
    await mount(
      tester,
      loadResult: () async => result(),
      loadMine: () async => throw ApiError(message: 'Mất mạng', offline: true),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('explanationField')), findsNothing);
    expect(find.text('Không có kết nối mạng'), findsOneWidget);
  });

  testWidgets(
    'Expired submission and LOST show read-only; existing edit rights are independent',
    (tester) async {
      await mount(
        tester,
        loadResult: () async => result(canExplain: false),
        loadMine: () async => null,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('explanationField')))
            .readOnly,
        isTrue,
      );
      expect(find.byKey(const Key('explanationSubmit')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await mount(
        tester,
        loadResult: () async => result(canExplain: false),
        loadMine: () async => explanation(),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('explanationField')))
            .readOnly,
        isFalse,
      );
      expect(find.text('Lưu thay đổi'), findsOneWidget);
    },
  );

  testWidgets(
    'Rune counter handles combining marks, whitespace and 501 without truncating draft',
    (tester) async {
      await mount(
        tester,
        loadResult: () async => result(),
        loadMine: () async => null,
      );
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('explanationField'));
      await tester.enterText(field, '  a\u0301  ');
      await tester.pump();
      expect(find.text('2 / 500'), findsOneWidget);
      await tester.enterText(field, List.filled(501, '😀').join());
      await tester.pump();
      expect(find.text('501 / 500'), findsOneWidget);
      expect(
        tester
            .widget<PrimaryButton>(find.byKey(const Key('explanationSubmit')))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<TextField>(field).controller!.text.runes.length,
        501,
      );
    },
  );

  testWidgets(
    'Busy prevents duplicates; API error preserves text; close asks before discarding',
    (tester) async {
      final pending = Completer<Explanation>();
      final api = ExplanationApi((_) => pending.future);
      await mount(
        tester,
        loadResult: () async => result(),
        loadMine: () async => null,
        api: api,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('explanationField')),
        'Lý do cần giữ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('explanationSubmit')));
      await tester.pump();
      expect(api.requests, 1);
      expect(
        tester
            .widget<PrimaryButton>(find.byKey(const Key('explanationSubmit')))
            .onPressed,
        isNull,
      );
      pending.completeError(ApiError(message: 'Mất mạng', offline: true));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('explanationField')))
            .controller!
            .text,
        'Lý do cần giữ',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục viết'));
      await tester.pumpAndSettle();
      expect(find.text('Lý do cần giữ'), findsOneWidget);
    },
  );

  testWidgets(
    'Saved text, history, privacy and actual session time remain readable after expiry',
    (tester) async {
      await mount(
        tester,
        loadResult: () async => result(canExplain: false),
        loadMine: () async => explanation(editable: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tập trung 14 phút 30 giây'), findsOneWidget);
      expect(find.text('Squad · 22/10/2026'), findsOneWidget);
      expect(
        find.text('Chỉ bạn và chủ nhóm xem được nội dung.'),
        findsOneWidget,
      );
      expect(find.text('Bản cũ'), findsOneWidget);
      expect(find.text('Đã thêm sau khi tạo báo cáo.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('explanationField')))
            .readOnly,
        isTrue,
      );
      expect(find.byKey(const Key('explanationSubmit')), findsNothing);
    },
  );

  testWidgets(
    'Submit succeeds with full server metadata and survives disposal while pending',
    (tester) async {
      final api = ExplanationApi((body) async => explanation(body: body));
      await mount(
        tester,
        loadResult: () async => result(),
        loadMine: () async => null,
        api: api,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('explanationField')),
        'Nội dung đã gửi',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('explanationSubmit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explanationSent')), findsOneWidget);
      expect(api.requests, 1);
      await tester.pumpWidget(const SizedBox());
      final pending = Completer<Explanation>();
      await mount(
        tester,
        loadResult: () async => result(),
        loadMine: () async => null,
        api: ExplanationApi((_) => pending.future),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('explanationField')),
        'Đang gửi',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('explanationSubmit')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      pending.complete(explanation());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
