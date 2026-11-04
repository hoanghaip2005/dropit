import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/models_ext.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/groups/group_screens.dart';
import 'package:dropit/features/groups/invite_qr_export.dart';

MyGroup group(String role) => MyGroup.fromJson({
  'group_id': 'g',
  'name': 'Nhóm thử nghiệm',
  'role': role,
  'status': 'ACTIVE',
  'member_count': 1,
});

void main() {
  for (final role in ['MEMBER', 'OWNER']) {
    testWidgets('$role invite shows code link QR, rotate owner only', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      String? exportedUrl;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myGroupsProvider.overrideWith((ref) async => [group(role)]),
            inviteCodeProvider('g').overrideWith((ref) async => 'ABCDEFGH'),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: InviteScreen(
              groupId: 'g',
              saveInviteQr: (url) async {
                exportedUrl = url;
                return InviteQrSaveResult.saved;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inviteQr')), findsOneWidget);
      expect(find.text('ABCDEFGH'), findsOneWidget);
      expect(
        find.byKey(const Key('rotateInviteCode')),
        role == 'OWNER' ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text('Chép mã'));
      expect(copied, 'ABCDEFGH');
      await tester.tap(find.byKey(const Key('copyInviteLink')));
      expect(copied, groupInviteUrl('ABCDEFGH'));
      final qr = tester.widget<QrImageView>(find.byKey(const Key('inviteQr')));
      expect(qr.semanticsLabel, contains(groupInviteUrl('ABCDEFGH')));
      final qrPosition = tester.getTopLeft(find.byKey(const Key('inviteQr')));
      final exportPosition = tester.getTopLeft(
        find.byKey(const Key('downloadInviteQr')),
      );
      final codePosition = tester.getTopLeft(
        find.byKey(const Key('inviteCode')),
      );
      expect(exportPosition.dy, greaterThan(qrPosition.dy));
      expect(exportPosition.dy, lessThan(codePosition.dy));
      ScaffoldMessenger.of(
        tester.element(find.byKey(const Key('downloadInviteQr'))),
      ).clearSnackBars();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('downloadInviteQr')));
      await tester.pumpAndSettle();
      expect(exportedUrl, groupInviteUrl('ABCDEFGH'));
      expect(find.text('Đã lưu ảnh QR.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('invite QR export reports that a web download started', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myGroupsProvider.overrideWith((ref) async => [group('MEMBER')]),
          inviteCodeProvider('g').overrideWith((ref) async => 'ABCDEFGH'),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: InviteScreen(
            groupId: 'g',
            saveInviteQr: (_) async => InviteQrSaveResult.downloadStarted,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('downloadInviteQr')));
    await tester.pumpAndSettle();

    expect(find.text('Đã bắt đầu tải ảnh QR.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invite QR export reports save failures', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myGroupsProvider.overrideWith((ref) async => [group('MEMBER')]),
          inviteCodeProvider('g').overrideWith((ref) async => 'ABCDEFGH'),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: InviteScreen(
            groupId: 'g',
            saveInviteQr: (_) async => throw StateError('save failed'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('downloadInviteQr')));
    await tester.pumpAndSettle();

    expect(
      find.text('Không thể lưu ảnh QR. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('member can open invite directly from group detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/groups/g',
      routes: [
        GoRoute(
          path: '/groups/g',
          builder: (_, _) => const GroupDetailScreen(groupId: 'g'),
        ),
        GoRoute(
          path: '/groups/g/invite',
          builder: (_, _) => const Scaffold(body: Text('Trang mời nhóm')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myGroupsProvider.overrideWith((ref) async => [group('MEMBER')]),
          membersProvider('g').overrideWith(
            (ref) async =>
                GroupMembers.fromJson({'member_count': 1, 'members': []}),
          ),
          shopItemsProvider.overrideWith((ref) async => <ShopItem>[]),
        ],
        child: MaterialApp.router(
          theme: buildLightTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memberInvite')));
    await tester.pumpAndSettle();
    expect(find.text('Trang mời nhóm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
