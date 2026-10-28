import 'package:dio/dio.dart';
import 'package:dropit/app/env.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/models_ext.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/groups/group_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ManagementApi extends DropItApi {
  ManagementApi() : super(Dio());
  int deletes = 0;
  final cursors = <String?>[];
  @override
  Future<Map<String, dynamic>> createGroup(String name, String purpose) async =>
      {'group_id': 'new-group'};
  @override
  Future<void> deleteGroup(String groupId) async {
    deletes++;
  }

  @override
  Future<({List<SessionSummary> items, String? nextCursor})> schedulesPage(
    String groupId, {
    String? cursor,
    int limit = 5,
  }) async {
    cursors.add(cursor);
    expect(limit, 5);
    return (
      items: List.generate(
        cursor == null ? 5 : 2,
        (i) => SessionSummary.fromJson({
          'session_id': '${cursor ?? 'first'}-$i',
          'duration_min': 37,
          'started_at': '2030-01-01T10:00:00Z',
          'status': 'SCHEDULED',
        }),
      ),
      nextCursor: cursor == null ? 'page2' : null,
    );
  }
}

void main() {
  testWidgets('Create success opens group detail instead of invite', (
    tester,
  ) async {
    final api = ManagementApi();
    final router = GoRouter(
      initialLocation: '/new',
      routes: [
        GoRoute(path: '/new', builder: (_, _) => const CreateGroupScreen()),
        GoRoute(
          path: '/groups/:gid',
          builder: (_, _) => const Scaffold(body: Text('Chi tiết mới')),
        ),
        GoRoute(
          path: '/groups/:gid/invite',
          builder: (_, _) => const Scaffold(body: Text('Mã mời mới')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(api)],
        child: MaterialApp.router(
          theme: buildOwnerTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'DEMO');
    await tester.enterText(find.byType(TextFormField).at(1), 'Dữ liệu mẫu');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết mới'), findsOneWidget);
    expect(find.text('Mã mời mới'), findsNothing);
  });

  testWidgets('Invite QR carries same code as readable text, no external image', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inviteCodeProvider('g').overrideWith((ref) async => 'ABCD1234'),
        ],
        child: MaterialApp(
          theme: buildOwnerTheme(),
          home: const InviteScreen(groupId: 'g'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final qr = tester.widget<QrImageView>(find.byKey(const Key('inviteQr')));
    expect(
      qr.semanticsLabel,
      'Mời tham gia nhóm: ${Uri.parse(Env.baseUrl).replace(fragment: '/consent/ABCD1234')}',
    );
    expect(find.text('ABCD1234'), findsOneWidget);
    expect(find.text('Chép mã'), findsOneWidget);
  });

  testWidgets('Duration accepts custom minutes and rejects outside bounds', (
    tester,
  ) async {
    int? value = 25;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildOwnerTheme(),
        home: Scaffold(
          body: SessionDurationInput(
            initialValue: 25,
            onChanged: (v) => value = v,
          ),
        ),
      ),
    );
    final field = find.byKey(const Key('sessionDurationMinutes'));
    await tester.enterText(field, '37');
    expect(value, 37);
    await tester.enterText(field, '0');
    expect(value, isNull);
    await tester.pump();
    expect(find.text('Nhập số phút từ 1 đến 240.'), findsOneWidget);
    await tester.enterText(field, '241');
    expect(value, isNull);
    await tester.enterText(field, '240');
    expect(value, 240);
  });

  testWidgets('Delete group requires confirmation; cancel does not call API', (
    tester,
  ) async {
    final api = ManagementApi();
    final router = GoRouter(
      initialLocation: '/group',
      routes: [
        GoRoute(
          path: '/group',
          builder: (_, _) => const Scaffold(
            body: DeleteGroupButton(groupId: 'g', groupName: 'DEMO'),
          ),
        ),
        GoRoute(
          path: '/groups',
          builder: (_, _) => const Scaffold(body: Text('Nhóm đã cập nhật')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(api)],
        child: MaterialApp.router(
          theme: buildOwnerTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('deleteGroup')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lịch sử học'), findsOneWidget);
    await tester.tap(find.text('Giữ nhóm'));
    await tester.pumpAndSettle();
    expect(api.deletes, 0);
    await tester.tap(find.byKey(const Key('deleteGroup')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteGroup')));
    await tester.pumpAndSettle();
    expect(api.deletes, 1);
    expect(find.text('Nhóm đã cập nhật'), findsOneWidget);
  });

  testWidgets(
    'Owner schedules request five rows per page and preserve previous cursor',
    (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ManagementApi();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiProvider.overrideWithValue(api),
            myGroupsProvider.overrideWith(
              (ref) async => [
                MyGroup.fromJson({
                  'group_id': 'g',
                  'role': 'OWNER',
                  'name': 'DEMO',
                }),
              ],
            ),
            membersProvider('g').overrideWith(
              (ref) async =>
                  GroupMembers.fromJson({'member_count': 0, 'members': []}),
            ),
            shopItemsProvider.overrideWith((ref) async => <ShopItem>[]),
          ],
          child: MaterialApp(
            theme: buildOwnerTheme(),
            home: const GroupDetailScreen(groupId: 'g'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('groupSession-first-0')), findsOneWidget);
      expect(find.byKey(const Key('groupSession-first-4')), findsOneWidget);
      expect(find.byKey(const Key('groupSession-first-5')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('sessionsNext')));
      await tester.tap(find.byKey(const Key('sessionsNext')));
      await tester.pumpAndSettle();
      expect(find.text('Trang 2'), findsOneWidget);
      expect(find.byKey(const Key('groupSession-page2-0')), findsOneWidget);
      expect(api.cursors, [null, 'page2']);
      await tester.tap(find.byKey(const Key('sessionsPrevious')));
      await tester.pumpAndSettle();
      expect(find.text('Trang 1'), findsOneWidget);
      expect(find.byKey(const Key('groupSession-first-0')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
