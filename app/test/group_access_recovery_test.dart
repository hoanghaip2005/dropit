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

void main() {
  testWidgets('Removed member recovers from stale owner view without raw error', (tester) async {
    final router = GoRouter(initialLocation: '/groups/stale', routes: [
      GoRoute(path: '/groups/stale', builder: (_, _) => const GroupDetailScreen(groupId: 'stale')),
      GoRoute(path: '/groups', builder: (_, _) => const Scaffold(body: Text('Danh sách đã tải lại'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [
      myGroupsProvider.overrideWith((ref) async => [MyGroup.fromJson({
        'group_id': 'stale', 'name': 'Nhóm cũ', 'role': 'OWNER',
      })]),
      membersProvider('stale').overrideWith((ref) async => throw ApiError(
        status: 403, code: 'FORBIDDEN_GROUP', message: 'RAW_FORBIDDEN_ADMIN',
      )),
      shopItemsProvider.overrideWith((ref) async => <ShopItem>[]),
    ], child: MaterialApp.router(theme: buildOwnerTheme(), routerConfig: router)));
    await tester.pumpAndSettle();
    expect(find.text('Bạn không còn trong nhóm này'), findsOneWidget);
    expect(find.textContaining('RAW_FORBIDDEN_ADMIN'), findsNothing);
    expect(find.byKey(const Key('ownerGroupSummary')), findsNothing);
    await tester.tap(find.text('Về danh sách nhóm'));
    await tester.pumpAndSettle();
    expect(find.text('Danh sách đã tải lại'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Network failure and owner permission are not membership removal', () {
    expect(isGroupAccessLost(ApiError(message: 'offline', offline: true)), isFalse);
    expect(isGroupAccessLost(ApiError(message: 'denied', status: 403, code: 'NOT_GROUP_OWNER')), isFalse);
    expect(isGroupAccessLost(ApiError(message: 'server', status: 500)), isFalse);
    expect(isGroupAccessLost(ApiError(message: 'removed', status: 403, code: 'FORBIDDEN_GROUP')), isTrue);
  });
}
