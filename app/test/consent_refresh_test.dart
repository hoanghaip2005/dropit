import 'package:dio/dio.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/groups/group_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class StaleConsentApi extends DropItApi {
  StaleConsentApi() : super(Dio());
  int calls = 0;
  @override
  Future<void> acceptConsent(
    String groupId, {
    required int version,
    required String code,
    required List<String> items,
  }) async {
    calls++;
    throw ApiError(message: 'stale', code: 'CONSENT_VERSION_STALE');
  }
}

void main() {
  testWidgets(
    'Stale consent reload clears old choices and requires fresh agreement',
    (tester) async {
      final api = StaleConsentApi();
      var loads = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiProvider.overrideWithValue(api),
            invitePreviewProvider('ABCDEFGH').overrideWith((ref) async {
              loads++;
              return ConsentDocument.fromJson({
                'group_id': 'g',
                'group_name': 'Fixture',
                'consent_version': loads,
                'items': [
                  {
                    'code': 'RULE',
                    'text': 'Terms version $loads',
                    'required': true,
                  },
                ],
              });
            }),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const ConsentScreen(code: 'ABCDEFGH'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rule = find.byKey(const Key('consent_RULE'));
      final submit = find.byKey(const Key('acceptConsent'));
      await tester.scrollUntilVisible(rule, 300);
      await tester.tap(rule);
      await tester.scrollUntilVisible(submit, 300);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(api.calls, 1);
      await tester.scrollUntilVisible(rule, 300);
      expect(find.text('Terms version 2'), findsOneWidget);
      expect(tester.widget<SwitchListTile>(rule).value, false);
      await tester.scrollUntilVisible(submit, 300);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(find.text('Tải lại quy tắc'), findsOneWidget);
      await tester.tap(find.text('Tải lại quy tắc'));
      await tester.pumpAndSettle();
      expect(loads, 3);
      expect(api.calls, 1);
    },
  );
}
