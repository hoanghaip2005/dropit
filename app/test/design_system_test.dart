import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/core/widgets/buttons.dart';
import 'package:dropit/core/widgets/chips.dart';
import 'package:dropit/core/widgets/layout.dart';

void main() {
  testWidgets('Owner rollout uses Stitch canvas and black actions without changing member theme', (tester) async {
    expect(buildLightTheme().colorScheme.primary, DT.primary);
    final owner = buildOwnerTheme();
    expect(owner.colorScheme.primary, OwnerStyle.primary);
    await tester.pumpWidget(MaterialApp(theme: owner, home: AppScaffold(children: [
      PrimaryButton(label: 'Tạo nhóm', onPressed: () {}),
    ])));
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, OwnerStyle.canvas);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final context = tester.element(find.byType(FilledButton));
    expect(Theme.of(context).filledButtonTheme.style!.backgroundColor!.resolve({}), OwnerStyle.primary);
    expect(button.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
  test('Brand controls and body copy meet normal-text contrast', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
    }
    expect(contrast(DT.primary, DT.onPrimary), greaterThanOrEqualTo(4.5));
    expect(contrast(DT.accent, Colors.white), greaterThanOrEqualTo(4.5));
    expect(contrast(DT.accent, DT.background), greaterThanOrEqualTo(4.5));
    expect(contrast(DT.accent, DT.surfaceHigh), greaterThanOrEqualTo(4.5));
    expect(contrast(DT.accent, DT.accentSoftBg), greaterThanOrEqualTo(4.5));
    expect(contrast(DT.textSecondary, DT.background), greaterThanOrEqualTo(4.5));
  });
  testWidgets('Filter selection stays accessible; disabled action cannot fire', (tester) async {
    var selected = false;
    await tester.pumpWidget(MaterialApp(theme: buildLightTheme(), home: Scaffold(
      body: StatefulBuilder(builder: (context, update) => Column(children: [
        FilterChipPill(label: 'Chuỗi', selected: selected, onTap: () => update(() => selected = !selected)),
        const PrimaryButton(label: 'Chưa đủ Coins', onPressed: null),
      ])),
    )));
    await tester.tap(find.text('Chuỗi'));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    final action = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(action.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
