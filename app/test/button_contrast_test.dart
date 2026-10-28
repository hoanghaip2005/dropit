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
  testWidgets('Black primary enforces white label, icon and loading despite dark override', (tester) async {
    final base = buildLightTheme();
    final theme = base.copyWith(filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.black)));
    for (final loading in [false, true]) {
      await tester.pumpWidget(MaterialApp(theme: theme, home: Scaffold(body: PrimaryButton(label: 'Lưu', icon: Icons.save, loading: loading, foreground: Colors.black, onPressed: () {}))));
      final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;
      expect(style.foregroundColor!.resolve(loading ? {WidgetState.disabled} : {}), Colors.white);
      if (loading) expect(tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).color, Colors.white);
    }
  });
  testWidgets('Primary uses painted button theme even when scheme is scoped; loading preserves pair', (tester) async {
    final base = buildLightTheme();
    final theme = base.copyWith(colorScheme: base.colorScheme.copyWith(primary: Colors.black, onPrimary: Colors.white));
    for (final loading in [false, true]) {
      await tester.pumpWidget(MaterialApp(theme: theme, home: Scaffold(body: PrimaryButton(label: 'Lưu', loading: loading, onPressed: () {}))));
      final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;
      final states = loading ? {WidgetState.disabled} : <WidgetState>{};
      expect(contrast(style.backgroundColor!.resolve(states)!, style.foregroundColor!.resolve(states)!), greaterThanOrEqualTo(4.5));
    }
  });
  testWidgets('Explicit light primary surface gets dark label by default', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: buildOwnerTheme(), home: Scaffold(body: PrimaryButton(label: 'Tiếp tục', background: Colors.white, onPressed: () {}))));
    final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;
    expect(contrast(style.backgroundColor!.resolve({})!, style.foregroundColor!.resolve({})!), greaterThanOrEqualTo(4.5));
  });
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
