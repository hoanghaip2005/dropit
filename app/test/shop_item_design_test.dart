import 'dart:async';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/models_ext.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/shop/shop_screen.dart';

class ItemApi extends DropItApi {
  ItemApi() : super(Dio());
  int price = 120;
  int balance = 1000;
  bool owned = false,
      equipped = false,
      metadataFail = false,
      unavailable = false;
  String kind = 'AVATAR_FRAME';
  DateTime? cached;
  Object? buyError, equipError;
  Completer<void>? pending;
  final purchases = <({String id, int price, String key})>[];
  final equipment = <String?>[];
  @override
  Future<List<ShopItem>> shopItems() async {
    if (metadataFail) throw Exception('catalog offline');
    return unavailable
        ? []
        : [
            ShopItem.fromJson({
              'item_id': 'a',
              'kind': kind,
              'name': 'Hoa Anh Đào với tên dài để kiểm tra bố cục',
              'price': price,
              'owned': owned,
              'preview_url': '/frame_sakura',
            }),
          ];
  }

  @override
  Future<MeProfile> me() async {
    if (metadataFail) throw Exception('me offline');
    return MeProfile.fromJson({
      'display_name': 'Nguyễn An với tên dài',
      'coins_balance': balance,
      'cached_at': cached?.toIso8601String(),
    });
  }

  @override
  Future<List<OwnedItem>> inventory() async {
    if (metadataFail) throw Exception('inventory offline');
    return [
      if (owned)
        OwnedItem.fromJson({
          'item_id': 'a',
          'kind': kind,
          'equipped': equipped,
        }),
    ];
  }

  @override
  Future<int> purchase(
    String id,
    int expectedPrice, {
    required String idempotencyKey,
  }) async {
    purchases.add((id: id, price: expectedPrice, key: idempotencyKey));
    if (pending != null) await pending!.future;
    if (buyError != null) throw buyError!;
    owned = true;
    balance -= expectedPrice;
    return balance;
  }

  @override
  Future<void> equip(String kind, String? id) async {
    equipment.add(id);
    if (pending != null) await pending!.future;
    if (equipError != null) throw equipError!;
    equipped = id != null;
  }
}

Widget itemApp(
  ItemApi api, {
  double scale = 1,
  String id = 'a',
  Widget? home,
  Future<MeProfile> Function()? me,
  Future<List<OwnedItem>> Function()? inventory,
  Future<List<ShopItem>> Function()? catalog,
}) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    apiProvider.overrideWithValue(api),
    if (me != null) meProvider.overrideWith((_) => me()),
    if (inventory != null) inventoryProvider.overrideWith((_) => inventory()),
    if (catalog != null) shopItemsProvider.overrideWith((_) => catalog()),
  ],
  child: MaterialApp(
    theme: buildLightTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: home ?? ShopItemScreen(itemId: id),
  ),
);

Future<void> clearSnack(WidgetTester tester) async {
  tester
      .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
      .clearSnackBars();
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    for (final kind in ['AVATAR_FRAME', 'TITLE', 'BACKGROUND']) {
      testWidgets(
        'Detail fits $width text1.5 $kind with purchase policy readable',
        (tester) async {
          tester.view.physicalSize = Size(width, width == 320 ? 740 : 1024);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final api = ItemApi()
            ..kind = kind
            ..price = 999999
            ..balance = 1000000;
          await tester.pumpWidget(itemApp(api, scale: 1.5));
          await tester.pumpAndSettle();
          expect(
            tester.getSize(find.byKey(const Key('buyButton'))).height,
            greaterThanOrEqualTo(44),
          );
          await tester.scrollUntilVisible(
            find.byKey(const Key('noRefund')),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          expect(find.byKey(const Key('noRefund')), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'Unknown and cached balances never imply zero, short funds or allow purchase',
    (tester) async {
      final api = ItemApi();
      final pending = Completer<MeProfile>();
      await tester.pumpWidget(itemApp(api, me: () => pending.future));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('buyButton')))
            .onPressed,
        isNull,
      );
      expect(find.textContaining('Thiếu '), findsNothing);
      pending.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('itemMetadataRetry')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const Key('itemMetadataRetry')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.cached = DateTime.utc(2026);
      api.balance = 0;
      await tester.pumpWidget(itemApp(api));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa cập nhật'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('buyButton')))
            .onPressed,
        isNull,
      );
      expect(find.textContaining('Thiếu '), findsNothing);
    },
  );
  testWidgets(
    'Known zero is insufficient; inventory unknown preserves owned but blocks equip',
    (tester) async {
      final api = ItemApi()..balance = 0;
      await tester.pumpWidget(itemApp(api));
      await tester.pumpAndSettle();
      expect(find.text('Thiếu 120 Coins'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.owned = true;
      final pending = Completer<List<OwnedItem>>();
      await tester.pumpWidget(itemApp(api, inventory: () => pending.future));
      await tester.pump();
      expect(find.text('Đã sở hữu'), findsOneWidget);
      expect(find.text('Đang dùng'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('itemEquip')))
            .onPressed,
        isNull,
      );
      pending.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('itemEquip')))
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'Buy serializes, records exact price, then owns without automatic equip',
    (tester) async {
      final api = ItemApi()..pending = Completer<void>();
      await tester.pumpWidget(itemApp(api));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('buyButton')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('buyButton')));
      await tester.pump();
      expect(api.purchases, hasLength(1));
      expect(api.purchases.single.price, 120);
      api.pending!.complete();
      api.pending = null;
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('itemEquip')), findsOneWidget);
      expect(api.equipment, isEmpty);
    },
  );
  testWidgets(
    'Ambiguous retry preserves key and body even after refreshed catalog price',
    (tester) async {
      final api = ItemApi()..buyError = Exception('secret timeout');
      await tester.pumpWidget(itemApp(api));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('buyButton')));
      await tester.pumpAndSettle();
      expect(find.textContaining('không bị trừ'), findsNothing);
      api.price = 300;
      await tester.scrollUntilVisible(
        find.byKey(const Key('itemStatusRetry')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('itemStatusRetry')));
      await tester.pumpAndSettle();
      expect(find.text('Thử lại giao dịch (120 Coins)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('buyButton')));
      await tester.pumpAndSettle();
      expect(api.purchases, hasLength(2));
      expect(api.purchases[1], api.purchases[0]);
    },
  );
  testWidgets(
    'Definitive changed price refreshes then needs explicit new confirmation',
    (tester) async {
      final api = ItemApi()
        ..buyError = ApiError(message: 'x', code: 'PRICE_CHANGED');
      await tester.pumpWidget(itemApp(api));
      await tester.pumpAndSettle();
      api.price = 300;
      await tester.tap(find.byKey(const Key('buyButton')));
      await tester.pumpAndSettle();
      expect(api.purchases, hasLength(1));
      expect(find.text('Xác nhận mua (300 Coins)'), findsOneWidget);
      api.buyError = null;
      await tester.tap(find.byKey(const Key('buyButton')));
      await tester.pumpAndSettle();
      expect(api.purchases.last.price, 300);
      expect(api.purchases.last.key, isNot(api.purchases.first.key));
    },
  );
  testWidgets(
    'Unavailable disables; already owned refreshes to equip; insufficient refreshes balance',
    (tester) async {
      for (final code in [
        'ITEM_UNAVAILABLE',
        'ALREADY_OWNED',
        'INSUFFICIENT_COINS',
      ]) {
        await tester.pumpWidget(const SizedBox());
        final api = ItemApi()..buyError = ApiError(message: 'x', code: code);
        await tester.pumpWidget(itemApp(api));
        await tester.pumpAndSettle();
        if (code == 'ALREADY_OWNED') api.owned = true;
        if (code == 'INSUFFICIENT_COINS') api.balance = 0;
        await tester.tap(find.byKey(const Key('buyButton')));
        await tester.pumpAndSettle();
        if (code == 'ALREADY_OWNED') {
          expect(find.byKey(const Key('itemEquip')), findsOneWidget);
        } else {
          expect(
            tester
                .widget<FilledButton>(find.byKey(const Key('buyButton')))
                .onPressed,
            isNull,
          );
        }
      }
    },
  );
  testWidgets(
    'Accepted purchase remains owned if refresh fails, never offers another purchase',
    (tester) async {
      final api = ItemApi()..pending = Completer<void>();
      await tester.pumpWidget(itemApp(api));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('buyButton')));
      await tester.pump();
      api.metadataFail = true;
      api.pending!.complete();
      api.pending = null;
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buyButton')), findsNothing);
      expect(
        find.text(
          'Đã mua vật phẩm. Chưa tải lại được trạng thái; hãy kiểm tra lại.',
        ),
        findsOneWidget,
      );
      api.metadataFail = false;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ShopItemScreen)),
      );
      container.invalidate(shopItemsProvider);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('itemEquip')), findsOneWidget);
      expect(api.purchases, hasLength(1));
    },
  );
  testWidgets(
    'Equip/gỡ busy serializes; error does not expose raw server text',
    (tester) async {
      final api = ItemApi()
        ..owned = true
        ..pending = Completer<void>();
      await tester.pumpWidget(itemApp(api));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('itemEquip')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('itemEquip')));
      await tester.pump();
      expect(api.equipment, ['a']);
      api.pending!.complete();
      api.pending = null;
      await tester.pumpAndSettle();
      expect(find.text('Gỡ trang bị'), findsOneWidget);
      await tester.tap(find.byKey(const Key('itemEquip')));
      await tester.pumpAndSettle();
      expect(api.equipment, ['a', null]);
      api.equipError = Exception('raw secret');
      await tester.tap(find.byKey(const Key('itemEquip')));
      await tester.pumpAndSettle();
      expect(find.textContaining('raw secret'), findsNothing);
    },
  );
  for (final equip in [false, true]) {
    testWidgets(
      'Disposed pending ${equip ? 'equip' : 'purchase'} never uses ref or state',
      (tester) async {
        final api = ItemApi()
          ..owned = equip
          ..pending = Completer<void>();
        await tester.pumpWidget(itemApp(api));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key(equip ? 'itemEquip' : 'buyButton')));
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        api.pending!.complete();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Catalog refresh/loading/error/missing never leaves stale mutation footer',
    (tester) async {
      final api = ItemApi();
      var calls = 0;
      final pending = Completer<List<ShopItem>>();
      await tester.pumpWidget(
        itemApp(
          api,
          catalog: () {
            calls++;
            return calls == 1 ? api.shopItems() : pending.future;
          },
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ShopItemScreen)),
      );
      container.invalidate(shopItemsProvider);
      await tester.pump();
      expect(find.byKey(const Key('buyButton')), findsNothing);
      pending.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buyButton')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.unavailable = true;
      await tester.pumpWidget(itemApp(api));
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy vật phẩm'), findsOneWidget);
      expect(find.byKey(const Key('buyButton')), findsNothing);
    },
  );
  testWidgets(
    'Busy back is held; uncertain transaction warns then permits explicit leave',
    (tester) async {
      final api = ItemApi()
        ..pending = Completer<void>()
        ..buyError = Exception('timeout');
      await tester.pumpWidget(
        itemApp(
          api,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ShopItemScreen(itemId: 'a'),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('buyButton')));
      await tester.pump();
      final nav = Navigator.of(tester.element(find.byType(ShopItemScreen)));
      await nav.maybePop();
      await tester.pump();
      expect(find.byType(ShopItemScreen), findsOneWidget);
      api.pending!.complete();
      api.pending = null;
      await tester.pumpAndSettle();
      await clearSnack(tester);
      await nav.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Giao dịch chưa được xác nhận'), findsOneWidget);
      await tester.tap(find.text('Ở lại kiểm tra'));
      await tester.pumpAndSettle();
      expect(find.byType(ShopItemScreen), findsOneWidget);
      await nav.maybePop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rời màn hình'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
    },
  );
  testWidgets(
    'Already owned stays confirmed when subsequent catalog has stale ownership',
    (tester) async {
      final api = ItemApi()
        ..buyError = ApiError(message: 'x', code: 'ALREADY_OWNED');
      await tester.pumpWidget(itemApp(api));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('buyButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buyButton')), findsNothing);
      expect(find.byKey(const Key('itemEquip')), findsOneWidget);
    },
  );
  testWidgets('Changing item on same State never reuses another item intent', (
    tester,
  ) async {
    final api = ItemApi()..buyError = Exception('timeout');
    Future<List<ShopItem>> catalog() async => [
      for (final id in ['a', 'b'])
        ShopItem.fromJson({
          'item_id': id,
          'kind': 'AVATAR_FRAME',
          'name': id,
          'price': id == 'a' ? 120 : 300,
          'owned': false,
        }),
    ];
    await tester.pumpWidget(itemApp(api, catalog: catalog));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('buyButton')));
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(ShopItemScreen));
    await tester.pumpWidget(itemApp(api, id: 'b', catalog: catalog));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(ShopItemScreen)), same(state));
    await tester.tap(find.byKey(const Key('buyButton')));
    await tester.pumpAndSettle();
    expect(api.purchases.last.id, 'b');
    expect(api.purchases.last.price, 300);
    expect(api.purchases.last.key, isNot(api.purchases.first.key));
  });
  testWidgets(
    'GoRouter unknown exit leaves once without another purchase or dialog',
    (tester) async {
      final api = ItemApi()..buyError = Exception('timeout');
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Shop root')),
          ),
          GoRoute(
            path: '/item',
            builder: (_, _) => const ShopItemScreen(itemId: 'a'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [apiProvider.overrideWithValue(api)],
          child: MaterialApp.router(
            theme: buildLightTheme(),
            routerConfig: router,
          ),
        ),
      );
      router.push('/item');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('buyButton')));
      await tester.pumpAndSettle();
      await Navigator.of(
        tester.element(find.byType(ShopItemScreen)),
      ).maybePop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rời màn hình'));
      await tester.pumpAndSettle();
      expect(find.text('Shop root'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(api.purchases, hasLength(1));
    },
  );
  testWidgets(
    'Persistent accepted status fits 320 text1.5 with footer after metadata partial failure',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ItemApi()..pending = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        itemApp(
          api,
          scale: 1.5,
          me: () {
            calls++;
            return calls > 1 ? Future.error(Exception('offline')) : api.me();
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('buyButton')));
      await tester.pump();
      api.pending!.complete();
      api.pending = null;
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Đã mua vật phẩm. Chưa tải lại được trạng thái; hãy kiểm tra lại.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('itemEquip')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
