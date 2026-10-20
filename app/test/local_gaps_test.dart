// Kiểm cho các việc "làm local" (ba/review/doi-chieu-code.md §3): rời nhóm, hồ sơ công khai, sửa/hủy lịch,
// Dữ liệu của tôi, giải trình (lịch sử, "đã sửa lúc"), nhãn báo cáo, gói app nhỏ và mất mạng.
import 'package:dio/dio.dart';
import 'package:dropit/app/theme.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/auth.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/models_ext.dart';
import 'package:dropit/core/offline.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/widgets.dart';
import 'package:dropit/features/achievements/achievements_screen.dart';
import 'package:dropit/features/appeals/appeal_screens.dart';
import 'package:dropit/features/groups/group_screens.dart';
import 'package:dropit/features/groups/membership_screens.dart';
import 'package:dropit/features/journal/journal_screens.dart';
import 'package:dropit/features/profile/my_data_screen.dart';
import 'package:dropit/features/profile/profile_screens.dart';
import 'package:dropit/features/reports/report_screens.dart';
import 'package:dropit/features/session/session_controller.dart';
import 'package:dropit/features/session/session_screen.dart';
import 'package:dropit/features/shop/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeApi extends DropItApi {
  FakeApi() : super(Dio());
  bool offline = false;
  final calls = <String>[];
  int coinsBalance = 40;
  List<CoinEntry> coinItems = const [];
  Map<String, dynamic>? myExpl;
  final journalSaved = <String>[];

  ApiError get _off => ApiError(message: 'Không có kết nối tới máy chủ.', offline: true);

  @override
  Future<MeProfile> me() async {
    if (offline) throw _off;
    return MeProfile.fromJson({'user_id': 'u1', 'display_name': 'An', 'coins_balance': coinsBalance, 'current_streak': 3});
  }

  @override
  Future<List<MyGroup>> myGroups() async => [
        MyGroup.fromJson({'group_id': 'g1', 'name': 'Nhóm Học Toán', 'role': 'MEMBER', 'member_count': 4}),
      ];

  @override
  Future<({int balance, List<CoinEntry> items})> coins() async {
    if (offline) throw _off;
    return (balance: coinsBalance, items: coinItems);
  }

  @override
  Future<List<ShopItem>> shopItems() async => [
        ShopItem.fromJson({'item_id': 'i1', 'kind': 'AVATAR_FRAME', 'name': 'Khung Lá Xanh', 'price': 30, 'owned': false}),
      ];

  @override
  Future<List<OwnedItem>> inventory() async => const [];

  @override
  Future<Map<String, dynamic>> withdrawConsent(String groupId) async {
    calls.add('withdraw:$groupId');
    if (offline) throw _off;
    return {'group_id': groupId, 'sessions': []};
  }

  @override
  Future<PublicProfile> publicProfile(String userId) async {
    if (userId == 'stranger') throw ApiError(message: 'x', status: 403, code: 'FORBIDDEN_GROUP');
    return PublicProfile.fromJson({
      'user': {'user_id': userId, 'display_name': 'Bình'},
      'role': 'MEMBER',
      'shown_badges': ['STREAK_7'],
      'shown_streak': 5,
    });
  }

  @override
  Future<SessionSummary> session(String id) async => SessionSummary.fromJson({
        'session_id': id,
        'group_id': 'g1',
        'group_name': 'Nhóm Học Toán',
        'status': id == 'started' ? 'ACTIVE' : 'SCHEDULED',
        'started_at': DateTime.now().toUtc().add(Duration(hours: id == 'started' ? -0 : 3)).toIso8601String(),
        'duration_min': 25,
      });

  @override
  Future<void> cancelSession(String sessionId) async => calls.add('cancel:$sessionId');

  @override
  Future<SessionSummary> updateSession(String sessionId, {DateTime? startUtc, int? durationMin}) async {
    calls.add('update:$sessionId:$durationMin');
    return session(sessionId);
  }

  @override
  Future<Map<String, dynamic>> myData({String? groupId}) async {
    if (offline) throw _off;
    return {
      'groups': [
        {'group_id': 'g1', 'name': 'Nhóm Học Toán', 'left_at': null},
      ],
      'sessions': [
        {
          'session_id': 's1',
          'group_name': 'Nhóm Học Toán',
          'started_at': '2026-10-19T02:00:00Z',
          'final_state': 'COMPLETED',
          'forfeited': true,
          'forfeit_trigger_display_name': 'Minh',
          'forfeit_triggered_by_me': false,
        },
      ],
      'exit_events': [],
      'attendance': [],
      'reports': [],
      'consents': [
        {'group_name': 'Nhóm Học Toán', 'action': 'GRANT', 'consent_version': 1, 'at': '2026-10-01T02:00:00Z'},
      ],
      'streak': {'current': 3, 'longest': 7},
      'coins': {'balance': 40, 'ledger_entries': 2},
      'shop': {'owned_count': 1},
      'profile': {'display_name': 'An'},
      'badges': [],
      'journal': {'entry_count': 2},
    };
  }

  @override
  Future<Explanation?> myExplanation(String sessionId) async => myExpl == null ? null : Explanation.fromJson(myExpl!);

  @override
  Future<MySessionResult> result(String id) async =>
      MySessionResult.fromJson({'session_id': id, 'final_state': 'EXITED', 'started_at': '2026-10-19T02:00:00Z'});

  @override
  Future<List<JournalEntry>> journal() async => const [];

  @override
  Future<JournalEntry> saveJournal(String date, String text) async {
    if (offline) throw _off;
    journalSaved.add(text);
    return JournalEntry.fromJson({'date': date, 'text': text});
  }

  @override
  Future<Achievements> achievements() async => Achievements.fromJson({
        'current_streak': 2,
        'longest_streak': 4,
        'streak_counted_today': false,
        'badge_progress': [
          {'metric': 'REWARDED_SESSIONS', 'value': 6, 'next_threshold': 10},
          {'metric': 'FOCUS_HOURS', 'value': 3, 'next_threshold': 10},
        ],
        'badges': [],
      });

  @override
  Future<AttendanceMonth> attendance(String month) async => AttendanceMonth.fromJson({'month': month, 'days': []});
}

late SharedPreferences prefs;

Future<void> scrollTo(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await t.ensureVisible(f);
  await t.pumpAndSettle();
}

Widget app(Widget child, FakeApi api, {List extra = const []}) => ProviderScope(
      key: UniqueKey(), // mỗi lần dựng là một container mới (mô phỏng mở lại màn)
      retry: (_, _) => null,
      overrides: [apiProvider.overrideWithValue(api), prefsProvider.overrideWithValue(prefs), ...extra],
      child: MaterialApp(theme: buildLightTheme(), home: child),
    );

/// Màn có điều hướng (pop/go) → bọc GoRouter.
Widget routed(String initial, Map<String, Widget Function(GoRouterState)> pages, FakeApi api, {List extra = const []}) {
  final router = GoRouter(initialLocation: '/start', routes: [
    GoRoute(
        path: '/start',
        builder: (c, _) => Scaffold(body: Center(child: TextButton(onPressed: () => c.push(initial), child: const Text('mở'))))),
    for (final e in pages.entries) GoRoute(path: e.key, builder: (_, s) => e.value(s)),
  ]);
  return ProviderScope(
    key: UniqueKey(),
    retry: (_, _) => null,
    overrides: [apiProvider.overrideWithValue(api), prefsProvider.overrideWithValue(prefs), ...extra],
    child: MaterialApp.router(theme: buildLightTheme(), routerConfig: router),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'dev_user': 'An'});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('BR-70: đang trong phiên → nút Đăng xuất khóa + cảnh báo', (t) async {
    final api = FakeApi();
    await t.pumpWidget(app(const ProfileScreen(), api));
    await t.pumpAndSettle();
    final ctx = t.element(find.byType(ProfileScreen));
    ProviderScope.containerOf(ctx).read(liveSessionProvider.notifier).set('s1');
    await t.pumpAndSettle();
    await scrollTo(t, find.byKey(const Key('logoutButton')));
    expect(find.byKey(const Key('logoutLocked')), findsOneWidget);
    expect(t.widget<SecondaryButton>(find.byKey(const Key('logoutButton'))).onPressed, isNull);
    ProviderScope.containerOf(ctx).read(liveSessionProvider.notifier).set(null);
    await t.pumpAndSettle();
    expect(t.widget<SecondaryButton>(find.byKey(const Key('logoutButton'))).onPressed, isNotNull);
  });

  testWidgets('AC-07.01.3: mất mạng → hồ sơ bản đã lưu + "Chưa cập nhật"', (t) async {
    final api = FakeApi();
    await t.pumpWidget(app(const ProfileScreen(), api));
    await t.pumpAndSettle(); // lần đầu có mạng → lưu bản
    api.offline = true;
    await t.pumpWidget(app(ProfileScreen(key: UniqueKey()), api));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('profileStale')), findsOneWidget);
    expect(find.text('An'), findsOneWidget);
  });

  testWidgets('AC-06.02.5/.6: Coins mất mạng → số dư cũ "có thể chưa cập nhật"; đạt trần → câu trần ngày', (t) async {
    final api = FakeApi();
    final n = DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = '${n.year}-${two(n.month)}-${two(n.day)}';
    api.coinItems = [
      for (var i = 0; i < 4; i++)
        CoinEntry.fromJson({'amount': 25, 'type': 'SESSION_REWARD', 'reward_date': today, 'balance_after': 25 * (i + 1)}),
    ];
    await t.pumpWidget(app(const CoinsScreen(), api));
    await t.pumpAndSettle();
    expect(find.text('Hôm nay: 100/100 — đã đạt trần, phiên tiếp theo hôm nay không cộng Coins'), findsOneWidget);
    api.offline = true;
    await t.pumpWidget(app(CoinsScreen(key: UniqueKey()), api));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('coinsStale')), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
  });

  testWidgets('AC-05.04.2 + tiến độ huy hiệu phiên/giờ', (t) async {
    await t.pumpWidget(app(const AchievementsScreen(), FakeApi()));
    await t.pumpAndSettle();
    expect(find.text('Hôm nay chưa cộng chuỗi'), findsOneWidget);
    await scrollTo(t, find.text('6/10'));
    expect(find.text('6/10'), findsOneWidget); // 10 phiên có thưởng
  });

  testWidgets('AC-06.04.9: màn xác nhận mua ghi "Không hoàn Coins"', (t) async {
    await t.pumpWidget(app(const ShopItemScreen(itemId: 'i1'), FakeApi()));
    await t.pumpAndSettle();
    await scrollTo(t, find.byKey(const Key('noRefund')));
    expect(find.text('Không hoàn Coins sau khi mua.'), findsOneWidget);
  });

  testWidgets('AC-07.07.6 / .2: mất mạng khi lưu nhật ký → giữ nháp + "Chưa lưu lên máy chủ"; chỉ khoảng trắng → "Nhật ký trống"',
      (t) async {
    final api = FakeApi()..offline = true;
    await t.pumpWidget(app(JournalEditScreen(date: todayVnKey()), api));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('journalField')), '   ');
    await t.pump();
    await t.tap(find.byKey(const Key('journalSave')));
    await t.pumpAndSettle();
    expect(find.text('Nhật ký trống'), findsOneWidget);
    await t.enterText(find.byKey(const Key('journalField')), 'Hôm nay học tốt');
    await t.pump();
    await t.tap(find.byKey(const Key('journalSave')));
    await t.pumpAndSettle();
    expect(find.text('Chưa lưu lên máy chủ'), findsOneWidget);
    expect(OfflineCache(prefs, 'An').draft(todayVnKey()), 'Hôm nay học tốt');
    // mở lại màn → nháp còn; có mạng → Thử lại lưu được và xóa nháp
    api.offline = false;
    await t.pumpWidget(app(JournalEditScreen(key: UniqueKey(), date: todayVnKey()), api));
    await t.pumpAndSettle();
    expect(find.text('Hôm nay học tốt'), findsOneWidget);
    await scrollTo(t, find.text('Thử lại'));
    await t.tap(find.text('Thử lại'));
    await t.pumpAndSettle();
    expect(api.journalSaved, ['Hôm nay học tốt']);
    expect(OfflineCache(prefs, 'An').draft(todayVnKey()), isNull);
  });

  testWidgets('V-21: 2 bước, Hủy ở bước 2 không đổi gì; xác nhận → gọi rút đồng ý', (t) async {
    final api = FakeApi();
    await t.pumpWidget(routed('/leave/g1', {
      '/leave/:gid': (s) => LeaveGroupScreen(groupId: s.pathParameters['gid']!),
      '/groups': (_) => const Scaffold(body: Text('Nhóm của tôi')),
    }, api));
    await t.tap(find.text('mở'));
    await t.pumpAndSettle();
    expect(find.text('Rút đồng ý và rời Nhóm Học Toán'), findsOneWidget);
    await t.tap(find.byKey(const Key('leaveNext')));
    await t.pumpAndSettle();
    expect(find.text('Bạn chắc chắn rời Nhóm Học Toán?'), findsOneWidget);
    await t.tap(find.byKey(const Key('leaveCancel')));
    await t.pumpAndSettle();
    expect(api.calls, isEmpty, reason: 'AC-01.07.4');
    await t.tap(find.text('mở'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('leaveNext')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('leaveConfirm')));
    await t.pumpAndSettle();
    expect(api.calls, ['withdraw:g1']);
    expect(find.text('Nhóm của tôi'), findsOneWidget);
  });

  testWidgets('V-21: mất mạng → "Chưa rút được đồng ý. Bạn vẫn là thành viên."', (t) async {
    final api = FakeApi()..offline = true;
    await t.pumpWidget(routed('/leave/g1', {'/leave/:gid': (s) => LeaveGroupScreen(groupId: s.pathParameters['gid']!)}, api));
    await t.tap(find.text('mở'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('leaveNext')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('leaveConfirm')));
    await t.pumpAndSettle();
    await scrollTo(t, find.byKey(const Key('leaveError')));
    expect(find.text('Chưa rút được đồng ý. Bạn vẫn là thành viên.'), findsOneWidget);
  });

  testWidgets('V-32: hồ sơ công khai có vai trò, chuỗi/huy hiệu tự bật; người ngoài → "Không xem được hồ sơ này."', (t) async {
    await t.pumpWidget(app(const PublicProfileScreen(userId: 'u2'), FakeApi()));
    await t.pumpAndSettle();
    expect(find.text('Bình'), findsOneWidget);
    expect(find.text('Thành viên'), findsOneWidget);
    expect(find.text('Chuỗi 5 ngày'), findsOneWidget);
    expect(find.text('Chuỗi 7 ngày'), findsOneWidget); // huy hiệu STREAK_7
    expect(find.textContaining('Coins'), findsNothing);
    await t.pumpWidget(app(const PublicProfileScreen(userId: 'stranger'), FakeApi()));
    await t.pumpAndSettle();
    expect(find.text('Không xem được hồ sơ này.'), findsOneWidget);
  });

  testWidgets('V-45: phiên SCHEDULED sửa/hủy được (hủy có xác nhận); phiên đã bắt đầu → khóa', (t) async {
    final api = FakeApi();
    await t.pumpWidget(routed('/edit/s1', {'/edit/:sid': (s) => EditSessionScreen(sessionId: s.pathParameters['sid']!)}, api));
    await t.tap(find.text('mở'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('editDeadline')), findsOneWidget);
    await t.tap(find.text('50 phút'));
    await t.pump();
    await scrollTo(t, find.byKey(const Key('saveSession')));
    await t.tap(find.byKey(const Key('saveSession')));
    await t.pumpAndSettle();
    expect(api.calls, ['update:s1:50']);
    // dựng lại (snackbar "Đã lưu" che phần dưới màn)
    await t.pumpWidget(routed('/edit/s1', {'/edit/:sid': (s) => EditSessionScreen(sessionId: s.pathParameters['sid']!)}, api));
    await t.tap(find.text('mở'));
    await t.pumpAndSettle();
    await scrollTo(t, find.byKey(const Key('cancelSession')));
    await t.tap(find.byKey(const Key('cancelSession')));
    await t.pumpAndSettle();
    expect(find.text('Thành viên sẽ được báo. Không có dữ liệu nào được ghi.'), findsOneWidget);
    await t.tap(find.byKey(const Key('confirmCancelSession')));
    await t.pumpAndSettle();
    expect(api.calls.last, 'cancel:s1');

    await t.pumpWidget(app(const EditSessionScreen(sessionId: 'started'), api));
    await t.pumpAndSettle();
    expect(find.text('Phiên đã bắt đầu — không sửa hoặc hủy được.'), findsOneWidget);
    expect(find.byKey(const Key('cancelSession')), findsNothing);
  });

  testWidgets('V-46: hủy → "Phiên đã hủy lúc"; không ai rời → "Không có ai rời app"; miễn trừ → nhãn', (t) async {
    final cancelled = SessionOwnerView.fromJson({
      'session_id': 's1', 'status': 'CANCELLED', 'started_at': '2026-10-19T02:00:00Z', 'ends_at': '2026-10-19T02:25:00Z',
      'cancel_reason': 'OWNER_CANCEL', 'cancelled_at': '2026-10-19T01:30:00Z', 'members': [], 'exit_events': [],
    });
    await t.pumpWidget(app(const OwnerSessionDetailScreen(sessionId: 's1'), FakeApi(),
        extra: [ownerDetailProvider('s1').overrideWith((ref) async => cancelled)]));
    await t.pumpAndSettle();
    expect(find.text('Phiên đã hủy lúc 08:30.'), findsOneWidget);
    expect(find.text('Kết quả thành viên'), findsNothing);

    final done = SessionOwnerView.fromJson({
      'session_id': 's2', 'status': 'COMPLETED', 'started_at': '2026-10-19T02:00:00Z', 'ends_at': '2026-10-19T02:25:00Z',
      'members': [
        {'display_name': 'An', 'final_state': 'COMPLETED'},
        {'display_name': 'Bình', 'final_state': 'LOST'},
        {'display_name': 'Chi', 'final_state': 'EXITED', 'exempted': true},
      ],
      'exit_events': [],
    });
    await t.pumpWidget(app(const OwnerSessionDetailScreen(sessionId: 's2'), FakeApi(),
        extra: [ownerDetailProvider('s2').overrideWith((ref) async => done)]));
    await t.pumpAndSettle();
    await scrollTo(t, find.byKey(const Key('noExits')));
    expect(find.text('Không có ai rời app.'), findsOneWidget);
    await scrollTo(t, find.text('Đã miễn trừ'));
    expect(find.text('Đã miễn trừ'), findsOneWidget);
    expect(find.text('Mất kết nối'), findsOneWidget);
  });

  testWidgets('V-25: mục chủ nhóm thấy/chỉ bạn; tên người khởi phát mất thưởng', (t) async {
    await t.pumpWidget(app(const MyDataScreen(), FakeApi()));
    await t.pumpAndSettle();
    expect(find.textContaining('Đây là mọi thứ DropIt! lưu về bạn.'), findsOneWidget);
    await scrollTo(t, find.text('Phiên đã mất thưởng tập thể do Minh rời phiên.'));
    expect(find.text('Chủ nhóm thấy'), findsWidgets);
    await scrollTo(t, find.text('Bản ghi đồng ý'));
    expect(find.text('Chỉ bạn'), findsWidgets);
  });

  testWidgets('US-04.05: giải trình đã gửi được nạp lại, có lịch sử bản cũ và "Đã sửa lúc"', (t) async {
    final api = FakeApi()
      ..myExpl = {
        'session_id': 's1',
        'user_id': 'u1',
        'body': 'Bản mới',
        'submitted_at': '2026-10-19T03:00:00Z',
        'edited_at': '2026-10-19T04:00:00Z',
        'can_edit': true,
        'edit_deadline': '2026-10-20T03:00:00Z',
        'history': [
          {'body': 'Bản cũ', 'written_at': '2026-10-19T03:00:00Z', 'replaced_at': '2026-10-19T04:00:00Z'},
        ],
      };
    await t.pumpWidget(app(const ExplanationScreen(sessionId: 's1'), api));
    await t.pumpAndSettle();
    expect(find.text('Bản mới'), findsOneWidget);
    await scrollTo(t, find.byKey(const Key('explanationHistory')));
    expect(find.textContaining('Đã sửa lúc 11:00'), findsOneWidget);
    expect(find.text('“Bản cũ”'), findsOneWidget);
  });

  test('BR-102: nhãn "Thêm sau khi tạo báo cáo" + "Đã sửa lúc" trong dòng báo cáo', () {
    final s = explanationNote({'body': 'x', 'added_after_report': true, 'edited_at': '2026-10-19T04:00:00Z'});
    expect(s, contains('Thêm sau khi tạo báo cáo'));
    expect(s, contains('Đã sửa lúc 11:00'));
    expect(explanationNote({'body': 'y'}), 'Giải trình: “y”');
  });

  testWidgets('V-06: phòng chờ có tên người đang chờ', (t) async {
    final v = SessionView(
        phase: SessionPhase.waiting,
        connected: true,
        startedAt: DateTime.now().toUtc().add(const Duration(minutes: 2)),
        participantCount: 2,
        lobbyMembers: const ['An', 'Bình']);
    await t.pumpWidget(ProviderScope(
        child: MaterialApp(theme: buildLightTheme(), home: Scaffold(body: LobbyView(view: v, info: null, onLeave: () {})))));
    expect(find.byKey(const Key('lobbyMembers')), findsOneWidget);
    expect(find.text('Bình'), findsOneWidget);
  });

  testWidgets('V-19: thẻ nhóm có trạng thái khác HOẠT ĐỘNG và tỉ lệ riêng nhóm', (t) async {
    final g = MyGroup.fromJson({
      'group_id': 'g9', 'name': 'Nhóm A', 'role': 'OWNER', 'member_count': 3, 'status': 'SCHEDULE_SUSPENDED',
      'month_completion_rate': 87.5,
    });
    await t.pumpWidget(ProviderScope(
      overrides: [myGroupsProvider.overrideWith((ref) async => [g])],
      child: MaterialApp(theme: buildLightTheme(), home: const GroupsScreen()),
    ));
    await t.pumpAndSettle();
    expect(find.text('Tạm ngưng lịch'), findsOneWidget);
    expect(find.text('87.5%'), findsOneWidget);
  });
}
