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
import 'package:dropit/features/profile/profile_screens.dart';
import 'package:dropit/features/shop/shop_screen.dart';

class NameApi extends DropItApi {
  NameApi() : super(Dio());
  final names = <String>[];
  Completer<void>? pending;
  bool fail = false;
  @override
  Future<MeProfile> updateMe(String name) async {
    names.add(name);
    if (pending != null) await pending!.future;
    if (fail) throw ApiError(message: 'Chưa lưu được tên.');
    return MeProfile.fromJson({'display_name': name});
  }
}

ShopItem cosmetic(String id, String kind, String key) => ShopItem.fromJson({
  'item_id': id,
  'kind': kind,
  'name': 'Danh hiệu học tập',
  'price': 100,
  'preview_url': '/$key',
});

void main() {
  testWidgets(
    'Title tab passes the current profile and equipped frame into its preview',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            meProvider.overrideWith(
              (ref) async => MeProfile.fromJson({
                'display_name': 'Hải',
                'frame_item_id': 'f',
                'coins_balance': 1000,
              }),
            ),
            inventoryProvider.overrideWith(
              (ref) async => [
                OwnedItem.fromJson({
                  'item_id': 'f',
                  'kind': 'AVATAR_FRAME',
                  'equipped': true,
                }),
              ],
            ),
            shopItemsProvider.overrideWith(
              (ref) async => [
                cosmetic('f', 'AVATAR_FRAME', 'frame_sakura'),
                cosmetic('t', 'TITLE', 'title_night_owl'),
              ],
            ),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const ShopScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shopCategory-TITLE')));
      await tester.pumpAndSettle();
      final preview = tester.widget<ShopArtworkPreview>(
        find.byType(ShopArtworkPreview),
      );
      expect(preview.me!.displayName, 'Hải');
      expect(preview.frameKey, 'frame_sakura');
    },
  );

  testWidgets('Profile opens the compact name editor in place', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownerOnlyProvider.overrideWithValue(true),
          meProvider.overrideWith(
            (ref) async => MeProfile.fromJson({'display_name': 'An'}),
          ),
        ],
        child: MaterialApp(
          theme: buildOwnerTheme(),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sửa hồ sơ'), findsNothing);
    await tester.tap(find.byKey(const Key('editProfileName')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Đổi tên hiển thị'), findsOneWidget);
    expect(find.byKey(const Key('changeAvatar')), findsOneWidget);
  });

  test('Title preview uses equipped frame, not merely purchased frame', () {
    final catalog = [
      cosmetic('a', 'AVATAR_FRAME', 'frame_sakura'),
      cosmetic('b', 'AVATAR_FRAME', 'frame_royal'),
    ];
    final owned = [
      OwnedItem.fromJson({
        'item_id': 'b',
        'kind': 'AVATAR_FRAME',
        'equipped': false,
      }),
    ];
    expect(
      equippedFrameKey(
        MeProfile.fromJson({'frame_item_id': 'a'}),
        catalog,
        owned,
      ),
      'frame_sakura',
    );
    expect(equippedFrameKey(MeProfile.fromJson({}), catalog, owned), isNull);
    expect(
      equippedFrameKey(null, catalog, [
        OwnedItem.fromJson({
          'item_id': 'b',
          'kind': 'AVATAR_FRAME',
          'equipped': true,
        }),
      ]),
      'frame_royal',
    );
  });
  testWidgets('Title and frame preview retain current uploaded avatar', (
    tester,
  ) async {
    final me = MeProfile.fromJson({
      'display_name': 'Hải',
      'avatar_url': 'https://example.com/avatar.png',
    });
    for (final kind in ['TITLE', 'AVATAR_FRAME']) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: Center(
              child: ShopArtworkPreview(
                item: cosmetic(
                  't',
                  kind,
                  kind == 'TITLE' ? 'title_night_owl' : 'frame_royal',
                ),
                me: me,
                frameKey: 'frame_sakura',
                size: 160,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final avatar = tester.widget<FramedAvatar>(find.byType(FramedAvatar));
      expect(avatar.imageUrl, 'https://example.com/avatar.png');
      expect(avatar.frameKey, kind == 'TITLE' ? 'frame_sakura' : 'frame_royal');
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
  Future<void> openName(WidgetTester tester, NameApi api) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiProvider.overrideWithValue(api),
          meProvider.overrideWith(
            (ref) async => MeProfile.fromJson({'display_name': 'An'}),
          ),
        ],
        child: MaterialApp(
          theme: buildOwnerTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showEditNameDialog(context, 'An'),
                child: const Text('Đổi tên'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Đổi tên'));
    await tester.pumpAndSettle();
  }

  testWidgets('Name popup validates empty, saves trimmed name once', (
    tester,
  ) async {
    final api = NameApi()..pending = Completer<void>();
    await openName(tester, api);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('profileNameInput')))
          .controller!
          .text,
      'An',
    );
    await tester.enterText(find.byKey(const Key('profileNameInput')), '   ');
    await tester.tap(find.byKey(const Key('profileNameSave')));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên hiển thị.'), findsOneWidget);
    expect(api.names, isEmpty);
    await tester.enterText(find.byKey(const Key('profileNameInput')), 'A');
    await tester.tap(find.byKey(const Key('profileNameSave')));
    await tester.pumpAndSettle();
    expect(find.text('Tên tối thiểu 2 ký tự.'), findsOneWidget);
    expect(api.names, isEmpty);
    expect(tester.widget<TextField>(find.descendant(of: find.byKey(const Key('profileNameInput')), matching: find.byType(TextField))).maxLength, 30);
    await tester.enterText(find.byKey(const Key('profileNameInput')), ' Hải ');
    await tester.tap(find.byKey(const Key('profileNameSave')));
    await tester.pump();
    expect(api.names, ['Hải']);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('profileNameSave')))
          .onPressed,
      isNull,
    );
    api.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets('Name popup accepts maximum 30 characters', (tester) async {
    final api = NameApi();
    await openName(tester, api);
    final name = List.filled(30, 'A').join();
    await tester.enterText(find.byKey(const Key('profileNameInput')), name);
    await tester.tap(find.byKey(const Key('profileNameSave')));
    await tester.pumpAndSettle();
    expect(api.names, [name]);
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets('Name failure keeps popup and entered name for retry', (
    tester,
  ) async {
    final api = NameApi()..fail = true;
    await openName(tester, api);
    await tester.enterText(find.byKey(const Key('profileNameInput')), 'Hải');
    await tester.tap(find.byKey(const Key('profileNameSave')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Chưa lưu được tên.'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('profileNameInput')))
          .controller!
          .text,
      'Hải',
    );
    api.fail = false;
    await tester.tap(find.byKey(const Key('profileNameSave')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
