import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/models_ext.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/shop/shop_screen.dart';

ShopItem item(String id, {String kind = 'AVATAR_FRAME', bool owned = false}) =>
    ShopItem.fromJson({
      'item_id': id,
      'kind': kind,
      'name': 'Vật phẩm $id có tên tiếng Việt dài',
      'price': 999999,
      'owned': owned,
      'preview_url': '/frame_sakura',
    });
MeProfile profile() =>
    MeProfile.fromJson({'display_name': 'An', 'coins_balance': 10000000});

class EquipApi extends DropItApi {
  EquipApi() : super(Dio());
  final calls = <String?>[];
  Completer<void>? pending;
  bool fail = false;
  @override
  Future<void> equip(String kind, String? id) async {
    calls.add(id);
    if (pending != null) await pending!.future;
    if (fail) throw Exception('raw secret');
  }
}

Widget app({
  required Future<List<ShopItem>> Function() catalog,
  Future<MeProfile> Function()? me,
  Future<List<OwnedItem>> Function()? inventory,
  EquipApi? api,
  double scale = 1,
  GoRouter? router,
}) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    shopItemsProvider.overrideWith((ref) => catalog()),
    meProvider.overrideWith((ref) => (me ?? () async => profile())()),
    inventoryProvider.overrideWith(
      (ref) => (inventory ?? () async => <OwnedItem>[])(),
    ),
    if (api != null) apiProvider.overrideWithValue(api),
  ],
  child: router != null
      ? MaterialApp.router(theme: buildLightTheme(), routerConfig: router)
      : MaterialApp(
          theme: buildLightTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const ShopScreen(),
        ),
);

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'Shop cards fit $width scale $scale with readable actions and categories',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            app(
              scale: scale,
              catalog: () async => [
                item('frame'),
                item('title', kind: 'TITLE'),
                item('bg', kind: 'BACKGROUND'),
              ],
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Bộ sưu tập'), findsNothing);
          await tester.scrollUntilVisible(
            find.byKey(const Key('shopDetail-frame')),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          expect(
            tester.getSize(find.byKey(const Key('shopDetail-frame'))).height,
            greaterThanOrEqualTo(44),
          );
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(
            find.byKey(const Key('shopCategory-TITLE')),
          );
          await tester.tap(find.byKey(const Key('shopCategory-TITLE')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('shopItem-title')), findsOneWidget);
          await tester.ensureVisible(
            find.byKey(const Key('shopCategory-BACKGROUND')),
          );
          await tester.tap(find.byKey(const Key('shopCategory-BACKGROUND')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('shopItem-bg')), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'Unknown balance and inventory never fabricate short funds or equipped state',
    (tester) async {
      final me = Completer<MeProfile>();
      final inv = Completer<List<OwnedItem>>();
      await tester.pumpWidget(
        app(
          catalog: () async => [item('owned', owned: true)],
          me: () => me.future,
          inventory: () => inv.future,
        ),
      );
      await tester.pump();
      expect(find.text('…'), findsOneWidget);
      expect(find.text('Chưa đủ Coins'), findsNothing);
      expect(find.text('Đã sở hữu'), findsOneWidget);
      expect(find.text('Đang dùng'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('shopEquip-owned')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNull,
      );
      me.completeError(Exception('balance'));
      inv.completeError(Exception('inventory'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('shopMetadataRetry')), findsOneWidget);
      expect(find.text('Chưa đủ Coins'), findsNothing);
    },
  );
  testWidgets(
    'Catalog loading, failure retry and category empty remain distinct',
    (tester) async {
      var calls = 0;
      final pending = Completer<List<ShopItem>>();
      await tester.pumpWidget(
        app(
          catalog: () {
            calls++;
            return calls == 1 ? pending.future : Future.value([item('a')]);
          },
        ),
      );
      expect(find.byKey(const ValueKey('skeleton0')), findsOneWidget);
      pending.completeError(ApiError(message: 'Catalog unavailable'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.byKey(const Key('shopItem-a')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('shopCategory-TITLE')));
      await tester.tap(find.byKey(const Key('shopCategory-TITLE')));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có danh hiệu đang bán'), findsOneWidget);
    },
  );
  testWidgets(
    'Equip serializes requests, waits for refreshed inventory, removes and reports error honestly',
    (tester) async {
      final api = EquipApi()..pending = Completer<void>();
      var refreshes = 0;
      Future<List<OwnedItem>> inv() async {
        refreshes++;
        return [
          OwnedItem.fromJson({
            'item_id': 'a',
            'kind': 'AVATAR_FRAME',
            'equipped': api.calls.isNotEmpty && api.calls.last == 'a',
          }),
        ];
      }

      await tester.pumpWidget(
        app(
          catalog: () async => [item('a', owned: true)],
          inventory: inv,
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('shopEquip-a')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('shopEquip-a')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('shopEquip-a')));
      await tester.pump();
      expect(api.calls, ['a']);
      api.pending!.complete();
      api.pending = null;
      await tester.pumpAndSettle();
      expect(refreshes, 2);
      expect(find.text('Đang dùng'), findsOneWidget);
      await tester.tap(find.byKey(const Key('shopEquip-a')));
      await tester.pumpAndSettle();
      expect(api.calls, ['a', null]);
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .clearSnackBars();
      await tester.pumpAndSettle();
      api.fail = true;
      await tester.tap(find.byKey(const Key('shopEquip-a')));
      await tester.pumpAndSettle();
      expect(
        find.text('Chưa cập nhật được trang bị. Thử tải lại để kiểm tra.'),
        findsOneWidget,
      );
      expect(find.textContaining('raw secret'), findsNothing);
    },
  );
  testWidgets('Cached balance offers retry without short-funds inference', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        catalog: () async => [item('a')],
        me: () async {
          calls++;
          return MeProfile.fromJson({
            'coins_balance': 0,
            'cached_at': '2026-10-23T00:00:00Z',
          });
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shopMetadataRetry')), findsOneWidget);
    expect(find.text('Chưa đủ Coins'), findsNothing);
    await tester.tap(find.byKey(const Key('shopMetadataRetry')));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
  testWidgets('Pending equip safely completes after Shop disposal', (
    tester,
  ) async {
    final api = EquipApi()..pending = Completer<void>();
    await tester.pumpWidget(
      app(catalog: () async => [item('a', owned: true)], api: api),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('shopEquip-a')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('shopEquip-a')));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    api.pending!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Coins, mine and item buttons navigate without buying directly', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/shop',
      routes: [
        GoRoute(path: '/shop', builder: (_, _) => const ShopScreen()),
        for (final path in ['/coins', '/shop/mine', '/shop/item/a'])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Text('Destination $path')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      app(catalog: () async => [item('a')], router: router),
    );
    await tester.pumpAndSettle();
    for (final entry in [
      ('shopCoins', '/coins'),
      ('myItems', '/shop/mine'),
      ('shopDetail-a', '/shop/item/a'),
      ('shopPreview-a', '/shop/item/a'),
    ]) {
      await tester.ensureVisible(find.byKey(Key(entry.$1)));
      await tester.tap(find.byKey(Key(entry.$1)));
      await tester.pumpAndSettle();
      expect(find.text('Destination ${entry.$2}'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
    }
  });
}
