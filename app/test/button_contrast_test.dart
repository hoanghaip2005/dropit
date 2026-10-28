import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/core/widgets/buttons.dart';
import 'package:dropit/core/widgets/dialogs.dart';

double contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);

void main() {
  for (final owner in [false, true]) {
    for (final dialog in [false, true]) {
      testWidgets('Enabled ${owner ? 'owner' : 'member'} ${dialog ? 'dialog' : 'primary'} button has readable text', (tester) async {
        final theme = owner ? buildOwnerTheme() : buildLightTheme();
        await tester.pumpWidget(MaterialApp(theme: theme, home: Scaffold(body:
          dialog ? const ConfirmDialog(title: 'Xác nhận', confirmLabel: 'Tiếp tục')
            : PrimaryButton(label: 'Lưu lịch', onPressed: () {}))));
        final button = tester.widget<FilledButton>(find.byType(FilledButton).first);
        final style = theme.filledButtonTheme.style!.merge(button.style);
        final bg = style.backgroundColor!.resolve({})!;
        final fg = style.foregroundColor!.resolve({})!;
        expect(contrast(bg, fg), greaterThanOrEqualTo(4.5));
      });
    }
  }
  test('Owner selected day and time remain readable on dark selection', () {
    final theme = buildOwnerTheme();
    const selected = {WidgetState.selected};
    expect(contrast(theme.datePickerTheme.dayBackgroundColor!.resolve(selected)!, theme.datePickerTheme.dayForegroundColor!.resolve(selected)!), greaterThanOrEqualTo(4.5));
    expect(contrast(WidgetStateProperty.resolveAs(theme.timePickerTheme.hourMinuteColor!, selected), WidgetStateProperty.resolveAs(theme.timePickerTheme.hourMinuteTextColor!, selected)), greaterThanOrEqualTo(4.5));
  });
}
