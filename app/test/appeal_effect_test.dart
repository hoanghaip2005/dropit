import 'package:dropit/core/models_ext.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/appeals/appeal_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Final appeal shows persisted before and after without private rewards',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appealProvider('a').overrideWith(
              (ref) async => Appeal.fromJson({
                'appeal_id': 'a',
                'session_id': 's',
                'status': 'EXEMPTED',
                'body': 'Fixture appeal',
                'display_name': 'Fixture member',
                'decision_reason': 'Fixture decision',
                'decided_at': '2026-11-03T05:00:00Z',
                'decision_effect': {
                  'before': {'exempted': false, 'forfeited': true},
                  'after': {'exempted': true, 'forfeited': false},
                },
              }),
            ),
          ],
          child: MaterialApp(
            theme: buildOwnerTheme(),
            home: const OwnerAppealScreen(appealId: 'a'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Miễn trừ: Không → Có'), 200);
      expect(find.text('Mất thưởng tập thể: Có → Không'), findsOneWidget);
      expect(find.byKey(const Key('exemptButton')), findsNothing);
    },
  );
}
