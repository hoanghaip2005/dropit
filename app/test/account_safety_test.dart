import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/profile/safety_controls.dart';

class SafetyApi extends DropItApi {
  SafetyApi() : super(Dio());
  int deletions = 0;
  int reports = 0;
  bool failDelete = true;
  @override
  Future<void> deleteAccount() async {
    deletions++;
    if (failDelete) throw ApiError(message: 'Máy chủ chưa xóa được tài khoản.');
  }

  @override
  Future<void> reportUser(String userId, String reason, String details) async {
    reports++;
    throw ApiError(message: 'Chưa gửi được báo cáo.');
  }
}

void main() {
  testWidgets('Successful deletion clears signed-in session', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final api = SafetyApi()..failDelete = false;
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        apiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authProvider.notifier).setToken('test-token', 'Test');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: AccountSafetyActions()),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('deleteAccount')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteAccount')));
    await tester.pumpAndSettle();
    expect(api.deletions, 1);
    expect(container.read(authProvider).loggedIn, false);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'Deletion requires explicit acknowledgement; failure keeps dialog retryable',
    (tester) async {
      final api = SafetyApi();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiProvider.overrideWithValue(api)],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: AccountSafetyActions()),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('deleteAccount')));
      await tester.pumpAndSettle();
      final confirm = find.byKey(const Key('confirmDeleteAccount'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      expect(api.deletions, 0);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(api.deletions, 1);
      expect(find.text('Máy chủ chưa xóa được tài khoản.'), findsOneWidget);
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    },
  );
  testWidgets(
    'Report failure preserves user details and does not claim success',
    (tester) async {
      final api = SafetyApi();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiProvider.overrideWithValue(api)],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: PublicSafetyActions(userId: 'other')),
          ),
        ),
      );
      await tester.tap(find.text('Báo cáo người dùng'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Nội dung cần kiểm tra');
      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pumpAndSettle();
      expect(api.reports, 1);
      expect(find.text('Chưa gửi được báo cáo.'), findsOneWidget);
      expect(find.text('Nội dung cần kiểm tra'), findsOneWidget);
      expect(find.text('Đã gửi báo cáo để xem xét.'), findsNothing);
    },
  );
}
