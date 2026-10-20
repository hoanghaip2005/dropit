import 'package:dropit/app/theme.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/auth.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/features/groups/group_screens.dart';
import 'package:dropit/features/session/result_screen.dart';
import 'package:dropit/features/session/session_controller.dart';
import 'package:dropit/features/session/session_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget wrap(Widget child, {List overrides = const []}) => ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(theme: buildLightTheme(), home: Scaffold(body: child)),
    );

void main() {
  final now = DateTime.now().toUtc();

  testWidgets('V-08 Lockdown: chỉ báo ghi, đồng hồ, nút Rời phiên, banner có tên', (t) async {
    final v = SessionView(
      phase: SessionPhase.focusing,
      connected: true,
      startedAt: now,
      endsAt: now.add(const Duration(minutes: 25)),
      forfeited: true,
      banners: [
        ExitBanner(eventId: 'x', name: 'Minh', at: DateTime.utc(2026, 10, 19, 2, 10, 3), triggeredForfeit: true),
      ],
    );
    await t.pumpWidget(wrap(LockdownView(view: v, onLeave: () {}, onDismissBanner: (_) {})));
    expect(find.text('Phiên đang được ghi'), findsOneWidget);
    expect(find.byKey(const Key('leaveButton')), findsOneWidget);
    expect(find.text('Phiên đã mất thưởng tập thể'), findsOneWidget);
    expect(
        find.text('Minh đã rời phiên lúc 09:10:03. Phiên đã mất thưởng tập thể — vẫn tiếp tục đến hết giờ.'),
        findsOneWidget);
    expect(find.textContaining('Coins'), findsNothing, reason: 'Lockdown không hiện Coins');
  });

  testWidgets('V-09/V-10: lớp khoan hồng và mất kết nối', (t) async {
    final g = SessionView(
        phase: SessionPhase.grace, endsAt: now.add(const Duration(minutes: 5)), graceDeadline: now.add(const Duration(seconds: 3)));
    await t.pumpWidget(wrap(LockdownView(view: g, onLeave: () {}, onDismissBanner: (_) {})));
    expect(find.byKey(const Key('graceOverlay')), findsOneWidget);

    const d = SessionView(phase: SessionPhase.disconnected);
    await t.pumpWidget(wrap(LockdownView(view: d, onLeave: () {}, onDismissBanner: (_) {})));
    expect(find.text('Đang kết nối lại…'), findsOneWidget);
    expect(find.text('Phiên đang được ghi'), findsOneWidget);
  });

  testWidgets('LOST: không còn chỉ báo ghi, không nút Rời phiên', (t) async {
    const v = SessionView(phase: SessionPhase.lost);
    await t.pumpWidget(wrap(LockdownView(view: v, onLeave: () {}, onDismissBanner: (_) {})));
    expect(find.text('Phiên đang được ghi'), findsNothing);
    expect(find.byKey(const Key('leaveButton')), findsNothing);
    expect(find.textContaining('Mất kết nối — 0 Coins'), findsOneWidget);
  });

  testWidgets('V-07 Đếm ngược: không có nút, có "Chưa ghi"', (t) async {
    final v = SessionView(phase: SessionPhase.countdown, connected: true, startedAt: now.add(const Duration(seconds: 3)));
    await t.pumpWidget(wrap(CountdownView(view: v, info: null)));
    expect(find.byType(ButtonStyleButton), findsNothing);
    expect(find.textContaining('Chưa ghi — bắt đầu ghi lúc'), findsOneWidget);
    expect(find.text('Phiên đang được ghi'), findsNothing);
  });

  testWidgets('V-06 Phòng chờ: có nút Rời phiên và luật', (t) async {
    var tapped = false;
    final v = SessionView(phase: SessionPhase.waiting, connected: true, startedAt: now.add(const Duration(minutes: 2)), participantCount: 4);
    await t.pumpWidget(wrap(LobbyView(view: v, info: null, onLeave: () => tapped = true)));
    expect(find.text('4 người đã vào phòng chờ'), findsOneWidget);
    expect(find.text('Khóa màn hình không tính là rời app.'), findsOneWidget);
    await t.tap(find.byKey(const Key('leaveButton')));
    expect(tapped, isTrue);
  });

  testWidgets('V-05 Đồng ý: công tắc mặc định tắt, nút bị khóa đến khi bật đủ mục bắt buộc', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final doc = ConsentDocument.fromJson({
      'group_id': 'g1',
      'group_name': 'Nhóm Học Toán',
      'owner_display_name': 'Cô Hà',
      'report_purpose': 'Theo dõi chuyên cần',
      'consent_version': 1,
      'member_count': 3,
      'items': [
        {'code': 'A', 'text': 'Ghi giờ rời app', 'required': true},
        {'code': 'B', 'text': 'Cả nhóm thấy tên khi tôi rời phiên', 'required': true},
      ],
    });
    await t.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        invitePreviewProvider('ABCDEFGH').overrideWith((ref) async => doc),
      ],
      child: MaterialApp(theme: buildLightTheme(), home: const ConsentScreen(code: 'ABCDEFGH')),
    ));
    await t.pumpAndSettle();
    expect(find.text('Nhóm Học Toán'), findsOneWidget);
    // Mới mở, chưa cuộn → có câu nhắc cuộn hết (nút khóa).
    expect(find.byKey(const Key('consentScrollHint'), skipOffstage: false), findsOneWidget);
    // Công tắc nằm dưới các thẻ quy tắc (mockup c_04) → cuộn tới.
    await t.scrollUntilVisible(find.byKey(const Key('consent_B')), 200);
    final switches = t.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
    expect(switches, hasLength(2));
    expect(switches.every((s) => s.value == false), isTrue);
    await t.ensureVisible(find.byKey(const Key('consent_A')));
    await t.tap(find.byKey(const Key('consent_A')));
    await t.pump();
    await t.scrollUntilVisible(find.byKey(const Key('consent_B')), 100);
    await t.tap(find.byKey(const Key('consent_B')));
    await t.pump();
    // AC-01.05.5: nút chỉ bật khi đã bật đủ mục bắt buộc VÀ đã cuộn đến cuối nội dung.
    FilledButton btn() => t.widget<FilledButton>(find.byKey(const Key('acceptConsent'), skipOffstage: false));
    await t.drag(find.byType(ListView), const Offset(0, -3000));
    await t.pumpAndSettle();
    expect(btn().onPressed, isNotNull);
    expect(find.byKey(const Key('consentScrollHint')), findsNothing);
  });

  testWidgets('V-05 Đồng ý: cuộn hết nhưng chưa bật đủ mục bắt buộc → nút vẫn khóa', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final doc = ConsentDocument.fromJson({
      'group_id': 'g1',
      'group_name': 'Nhóm Học Toán',
      'consent_version': 1,
      'items': [
        {'code': 'A', 'text': 'Ghi giờ rời app', 'required': true},
      ],
    });
    await t.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        invitePreviewProvider('ABCDEFGH').overrideWith((ref) async => doc),
      ],
      child: MaterialApp(theme: buildLightTheme(), home: const ConsentScreen(code: 'ABCDEFGH')),
    ));
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView), const Offset(0, -3000));
    await t.pumpAndSettle();
    expect(t.widget<FilledButton>(find.byKey(const Key('acceptConsent'))).onPressed, isNull);
  });

  testWidgets('V-19 Nhóm của tôi: trạng thái rỗng và mất mạng', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [myGroupsProvider.overrideWith((ref) async => <MyGroup>[])],
      child: MaterialApp(theme: buildLightTheme(), home: const GroupsScreen()),
    ));
    await t.pumpAndSettle();
    expect(find.text('Chưa có nhóm'), findsOneWidget);

    await t.pumpWidget(ProviderScope(
      key: UniqueKey(),
      retry: (_, _) => null,
      overrides: [
        myGroupsProvider.overrideWith((ref) async => throw ApiError(message: 'x', offline: true)),
      ],
      child: MaterialApp(theme: buildLightTheme(), home: const GroupsScreen()),
    ));
    await t.pumpAndSettle();
    expect(find.text('Không có kết nối mạng'), findsOneWidget);
  });

  testWidgets('V-46 chủ nhóm: không có Coins/chuỗi', (t) async {
    final v = SessionOwnerView.fromJson({
      'session_id': 's1',
      'status': 'COMPLETED',
      'started_at': '2026-10-19T02:00:00Z',
      'ends_at': '2026-10-19T02:25:00Z',
      'forfeited': true,
      'forfeit_trigger_display_name': 'Minh',
      'fetched_at': '2026-10-19T03:00:00Z',
      'members': [
        {'display_name': 'An', 'final_state': 'COMPLETED'},
        {'display_name': 'Minh', 'final_state': 'EXITED'},
      ],
      'exit_events': [
        {'display_name': 'Minh', 'server_ts': '2026-10-19T02:10:03Z'},
      ],
    });
    await t.pumpWidget(ProviderScope(
      overrides: [ownerDetailProvider('s1').overrideWith((ref) async => v)],
      child: MaterialApp(theme: buildLightTheme(), home: const OwnerSessionDetailScreen(sessionId: 's1')),
    ));
    await t.pumpAndSettle();
    expect(find.textContaining('mất thưởng tập thể do Minh'), findsOneWidget);
    expect(find.text('Rời phiên'), findsNWidgets(2)); // tiêu đề mục + trạng thái của Minh
    expect(find.textContaining('Coins'), findsNothing);
    expect(find.textContaining('Chuỗi'), findsNothing);
    expect(find.textContaining('Cập nhật lúc'), findsOneWidget);
  });

  test('ResultCopy: các biến thể kết quả', () {
    MySessionResult r(Map<String, dynamic> j) => MySessionResult.fromJson({'duration_min': 25, ...j});
    expect(ResultCopy.of(r({'final_state': 'COMPLETED', 'coins_awarded': 10})).label, 'Hoàn thành có thưởng');
    final a = ResultCopy.of(r({'final_state': 'COMPLETED', 'forfeited': true, 'forfeit_trigger_display_name': 'Minh'}));
    expect(a.label, 'Hoàn thành');
    expect(a.coins, '0 Coins');
    expect(a.reason, contains('do Minh rời phiên'));
    expect(ResultCopy.of(r({'final_state': 'EXITED'})).label, 'Bạn đã rời phiên');
    expect(ResultCopy.of(r({'final_state': 'LOST'})).label, 'Mất kết nối');
    expect(ResultCopy.of(r({'final_state': 'ABSENT'})).label, 'Vắng');
  });
}
