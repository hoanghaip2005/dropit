import 'package:dio/dio.dart';
import 'package:dropit/app/theme.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/models_ext.dart';
import 'package:dropit/core/widgets.dart';
import 'package:dropit/features/journal/journal_screens.dart';
import 'package:dropit/features/profile/profile_screens.dart';
import 'package:dropit/features/reports/report_screens.dart';
import 'package:dropit/features/shop/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// API giả: đủ cho Shop / nhật ký / hồ sơ / báo cáo, không gọi mạng.
class FakeApi extends DropItApi {
  FakeApi({this.balance = 50, this.owner = false}) : super(Dio());
  int balance;
  final bool owner;
  bool owned = false;
  final purchaseKeys = <String>[];
  final journalSaved = <String>[];

  @override
  Future<MeProfile> me() async => MeProfile.fromJson({
        'user_id': 'u1',
        'display_name': owner ? 'Lan' : 'An',
        'email': owner ? 'lan@dropit.dev' : 'an@dropit.dev',
        'coins_balance': balance,
        'current_streak': 7,
      });

  @override
  Future<List<MyGroup>> myGroups() async => [
        MyGroup.fromJson({'group_id': 'g1', 'name': 'Nhóm Học Toán', 'role': owner ? 'OWNER' : 'MEMBER', 'member_count': 5}),
      ];

  @override
  Future<List<ShopItem>> shopItems() async => [
        ShopItem.fromJson({
          'item_id': 'i1',
          'kind': 'AVATAR_FRAME',
          'name': 'Khung Lá Xanh',
          'price': 30,
          'preview_url': 'http://localhost:3000/assets/shop/frame_leaf',
          'owned': owned,
        }),
        ShopItem.fromJson({'item_id': 'i2', 'kind': 'AVATAR_FRAME', 'name': 'Khung Vàng', 'price': 70, 'owned': false}),
      ];

  @override
  Future<List<OwnedItem>> inventory() async => [
        if (owned) OwnedItem.fromJson({'item_id': 'i1', 'kind': 'AVATAR_FRAME', 'name': 'Khung Lá Xanh', 'equipped': false}),
      ];

  @override
  Future<int> purchase(String itemId, int expectedPrice, {required String idempotencyKey}) async {
    purchaseKeys.add(idempotencyKey);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (balance < expectedPrice) throw ApiError(message: 'x', code: 'INSUFFICIENT_COINS', status: 422);
    balance -= expectedPrice;
    owned = true;
    return balance;
  }

  @override
  Future<({int balance, List<CoinEntry> items})> coins() async => (balance: balance, items: const <CoinEntry>[]);

  @override
  Future<List<JournalEntry>> journal() async => const [];

  @override
  Future<JournalEntry> saveJournal(String date, String text) async {
    journalSaved.add(text);
    return JournalEntry.fromJson({'date': date, 'text': text});
  }

  @override
  Future<List<ReportPeriod>> reportPeriods(String groupId) async =>
      [ReportPeriod.fromJson({'month': '2026-09', 'status': 'GENERATED', 'generated_at': '2026-10-01T00:00:00Z'})];

  @override
  Future<GroupReport> report(String groupId, String month) async => GroupReport.fromJson({
        'view': 'OWNER',
        'group_id': groupId,
        'month': month,
        'report_purpose': 'Theo dõi mức độ tập trung chung của nhóm.',
        'generated_at': '2026-10-01T00:00:00Z',
        'rows': [
          {'user_id': 'e', 'display_name': 'Em', 'expected_sessions': 3, 'completed_sessions': 0, 'completion_rate': 0, 'absent_count': 3},
          {'user_id': 'd', 'display_name': 'Đỗ Minh', 'expected_sessions': 3, 'completed_sessions': 2, 'completion_rate': 66.7, 'exited_count': 1},
          {'user_id': 'a', 'display_name': 'An', 'expected_sessions': 3, 'completed_sessions': 3, 'completion_rate': 100},
        ],
        'group_totals': {'sessions_held': 3, 'forfeited_sessions': 1, 'completion_rate': 73.3, 'rewarded_completion_rate': 53.3},
      });
}

Widget app(Widget child, FakeApi api) => ProviderScope(
      overrides: [apiProvider.overrideWithValue(api)],
      child: MaterialApp(theme: buildLightTheme(), home: child),
    );

void main() {
  testWidgets('Shop: mua một lần với Idempotency-Key, bấm hai lần chỉ trừ một lần, sau đó đổi sang Trang bị', (t) async {
    final api = FakeApi(balance: 50);
    await t.pumpWidget(app(const ShopItemScreen(itemId: 'i1'), api));
    await t.pumpAndSettle();

    expect(find.text('Khung Lá Xanh'), findsOneWidget);
    expect(find.text('Xác nhận mua (30 Coins)'), findsOneWidget);
    expect(find.text('20 Coins'), findsOneWidget, reason: 'số dư còn lại sau mua');

    await t.tap(find.byKey(const Key('buyButton')));
    await t.pump();
    await t.tap(find.byKey(const Key('buyButton')), warnIfMissed: false);
    await t.pumpAndSettle();

    expect(api.purchaseKeys, hasLength(1));
    expect(api.purchaseKeys.single, isNotEmpty);
    expect(api.balance, 20);
    expect(find.text('Trang bị'), findsOneWidget);
  });

  testWidgets('Shop: thiếu Coins → nút tắt ghi "Thiếu N Coins"', (t) async {
    final api = FakeApi(balance: 50);
    await t.pumpWidget(app(const ShopItemScreen(itemId: 'i2'), api));
    await t.pumpAndSettle();
    expect(find.text('Thiếu 20 Coins'), findsWidgets);
    final btn = t.widget<PrimaryButton>(find.byKey(const Key('buyButton')));
    expect(btn.onPressed, isNull);
  });

  testWidgets('Nhật ký: giới hạn 5.000 ký tự có bộ đếm, câu riêng tư', (t) async {
    final api = FakeApi();
    await t.pumpWidget(app(JournalEditScreen(date: todayVnKey()), api));
    await t.pumpAndSettle();

    expect(find.text('0/5.000 ký tự'), findsOneWidget);
    expect(find.text('Chủ nhóm và quản trị không xem được trong app.'), findsOneWidget);
    final save = find.byKey(const Key('journalSave'));
    expect(t.widget<TextButton>(save).onPressed, isNull, reason: 'ô trống → Lưu tắt');

    await t.enterText(find.byKey(const Key('journalField')), 'a' * 5200);
    await t.pump();
    final field = t.widget<TextField>(find.byKey(const Key('journalField')));
    expect(field.controller!.text.length, journalMaxChars);
    expect(find.text('5.000/5.000 ký tự'), findsOneWidget);
    expect(find.text('Đã đạt giới hạn 5.000 ký tự.'), findsOneWidget);

    await t.tap(save);
    await t.pumpAndSettle();
    expect(api.journalSaved.single.length, 5000);
  });

  testWidgets('Chủ nhóm: hồ sơ không có Coins/chuỗi', (t) async {
    final api = FakeApi(owner: true);
    await t.pumpWidget(app(const ProfileScreen(), api));
    await t.pumpAndSettle();
    expect(find.text('Lan'), findsOneWidget);
    expect(find.textContaining('Coins'), findsNothing);
    expect(find.textContaining('Chuỗi'), findsNothing);
    expect(find.byKey(const Key('profileCoins')), findsNothing);
  });

  testWidgets('Thành viên: hồ sơ có Coins của chính mình', (t) async {
    final api = FakeApi();
    await t.pumpWidget(app(const ProfileScreen(), api));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('profileCoins')), findsOneWidget);
  });

  testWidgets('Báo cáo chủ nhóm: mục đích ở đầu, sắp tên A→Z (Đ cạnh D), không Coins/chuỗi', (t) async {
    final api = FakeApi(owner: true);
    await t.pumpWidget(app(const ReportScreen(groupId: 'g1'), api));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('purposeCard')), findsOneWidget);
    expect(find.text('Theo dõi mức độ tập trung chung của nhóm.'), findsOneWidget);
    expect(find.textContaining('Coins'), findsNothing);
    expect(find.textContaining('chuỗi', findRichText: false).evaluate().where((e) {
      final w = e.widget;
      return w is Text && (w.data ?? '').contains('chuỗi') && !(w.data ?? '').contains('không có');
    }), isEmpty);
    final ys = [for (final n in ['An', 'Đỗ Minh', 'Em']) t.getTopLeft(find.text(n)).dy];
    expect(ys[0] < ys[1] && ys[1] < ys[2], isTrue, reason: 'A→Z theo tên, không theo chỉ số');
  });

  test('foldVi: Đ sắp như D', () {
    final l = sortByName(['Em', 'Đỗ', 'Bình', 'Dũng'], (s) => s);
    expect(l, ['Bình', 'Đỗ', 'Dũng', 'Em']);
  });
}
