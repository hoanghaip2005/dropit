import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/models_ext.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/groups/group_screens.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('Owner group detail fits $width and retains management actions', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final group = MyGroup.fromJson({'group_id': 'detail',
        'name': 'Nhóm học tập và thiết kế sản phẩm', 'role': 'OWNER', 'status': 'SCHEDULE_SUSPENDED'});
      await tester.pumpWidget(ProviderScope(overrides: [
        myGroupsProvider.overrideWith((ref) async => [group]),
        membersProvider('detail').overrideWith((ref) async => GroupMembers.fromJson({
          'member_count': 0, 'below_minimum': true,
          'owner': {'user_id': 'owner', 'display_name': 'Chủ nhóm thử nghiệm'}, 'members': [],
        })),
        schedulesProvider('detail').overrideWith((ref) async => <SessionSummary>[]),
        shopItemsProvider.overrideWith((ref) async => <ShopItem>[]),
      ], child: MaterialApp(theme: buildOwnerTheme(), home: const GroupDetailScreen(groupId: 'detail'))));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ownerGroupSummary')), findsOneWidget);
      expect(find.text('Tạm ngưng lịch'), findsOneWidget);
      expect(find.text('Mã mời'), findsOneWidget);
      expect(find.text('Đặt lịch'), findsOneWidget);
      expect(find.text('Báo cáo nhóm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('Owner groups fits $width with long names and missing metrics', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final group = MyGroup.fromJson({
        'group_id': 'owner-design',
        'name': 'Nhóm học tập và thực hành thiết kế sản phẩm',
        'role': 'OWNER', 'member_count': 3, 'status': 'SCHEDULE_SUSPENDED',
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [myGroupsProvider.overrideWith((ref) async => [group])],
        child: MaterialApp(theme: buildOwnerTheme(), home: const GroupsScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Nhóm bạn quản lý'), findsOneWidget);
      expect(find.text('Tạm ngưng lịch'), findsOneWidget);
      expect(find.text('Chưa có dữ liệu tháng này'), findsOneWidget);
      expect(find.text('Chưa có lịch'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, OwnerStyle.canvas);
      final card = tester.widgetList<Container>(find.byType(Container)).where((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration && decoration.color == Colors.white &&
            decoration.borderRadius == BorderRadius.circular(32);
      });
      expect(card, hasLength(1));
      expect((card.single.decoration as BoxDecoration).border, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
