import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Màu ngữ nghĩa bổ sung ngoài [ColorScheme] — `context.dropit.accent`…
@immutable
class DropItColors extends ThemeExtension<DropItColors> {
  const DropItColors({
    required this.card,
    required this.textSecondary,
    required this.accent,
    required this.accentSoftBg,
    required this.success,
    required this.successSoftBg,
    required this.warning,
    required this.warningSoftBg,
    required this.outline,
    required this.lockdownBg,
    required this.lockdownButton,
    required this.lockdownTextSecondary,
  });

  static const light = DropItColors(
    card: DT.card,
    textSecondary: DT.textSecondary,
    accent: DT.accent,
    accentSoftBg: DT.accentSoftBg,
    success: DT.success,
    successSoftBg: DT.successSoftBg,
    warning: DT.warning,
    warningSoftBg: DT.warningSoftBg,
    outline: DT.outline,
    lockdownBg: DT.lockdownBg,
    lockdownButton: DT.lockdownButton,
    lockdownTextSecondary: DT.lockdownTextSecondary,
  );

  final Color card;
  final Color textSecondary;
  final Color accent;
  final Color accentSoftBg;
  final Color success;
  final Color successSoftBg;
  final Color warning;
  final Color warningSoftBg;
  final Color outline;
  final Color lockdownBg;
  final Color lockdownButton;
  final Color lockdownTextSecondary;

  @override
  DropItColors copyWith({Color? card, Color? accent}) => DropItColors(
        card: card ?? this.card,
        textSecondary: textSecondary,
        accent: accent ?? this.accent,
        accentSoftBg: accentSoftBg,
        success: success,
        successSoftBg: successSoftBg,
        warning: warning,
        warningSoftBg: warningSoftBg,
        outline: outline,
        lockdownBg: lockdownBg,
        lockdownButton: lockdownButton,
        lockdownTextSecondary: lockdownTextSecondary,
      );

  @override
  DropItColors lerp(ThemeExtension<DropItColors>? other, double t) => this;
}

extension DropItThemeX on BuildContext {
  DropItColors get dropit => Theme.of(this).extension<DropItColors>() ?? DropItColors.light;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Thang chữ Inter (DESIGN.md + cấu hình Tailwind của mockup):
/// displayLarge 72 (đồng hồ Lockdown) · displayMedium 56 (đồng hồ phòng chờ) ·
/// displaySmall 32/40 (onboarding) · headlineLarge 28/34 · headlineMedium 22/28 ·
/// headlineSmall 18/24 · titleMedium = label-lg 14/20 w600 · body 16/14/12 ·
/// labelLarge = label-md 14 w500 · labelMedium 12 w600 · labelSmall 11 w500.
const _textTheme = TextTheme(
  displayLarge: TextStyle(fontSize: 72, fontWeight: FontWeight.w700, height: 1, color: DT.textPrimary),
  displayMedium: TextStyle(fontSize: 56, fontWeight: FontWeight.w700, height: 1, color: DT.textPrimary),
  displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 40 / 32, color: DT.textPrimary),
  headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 34 / 28, color: DT.textPrimary),
  headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 28 / 22, color: DT.textPrimary),
  headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 24 / 18, color: DT.textPrimary),
  titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 24 / 18, color: DT.textPrimary),
  titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 20 / 14, color: DT.textPrimary),
  titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 16 / 12, color: DT.textPrimary),
  bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16, color: DT.textPrimary),
  bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: DT.textPrimary),
  bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 16 / 12, color: DT.textSecondary),
  labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 18 / 14, color: DT.textPrimary),
  labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 16 / 12, color: DT.textPrimary),
  labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 14 / 11, color: DT.textPrimary),
);

/// Trong `flutter test` không tải font qua mạng (google_fonts sẽ báo lỗi).
bool get _isTest => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

TextTheme _inter(TextTheme t) => _isTest ? t : GoogleFonts.interTextTheme(t);

ThemeData buildLightTheme() {
  const scheme = ColorScheme.light(
    primary: DT.primary,
    onPrimary: Colors.white,
    primaryContainer: DT.primary,
    onPrimaryContainer: Colors.white,
    secondary: DT.accent,
    onSecondary: Colors.white,
    secondaryContainer: DT.accentSoftBg,
    onSecondaryContainer: DT.accent,
    tertiary: DT.success,
    onTertiary: Colors.white,
    tertiaryContainer: DT.successSoftBg,
    onTertiaryContainer: DT.success,
    error: DT.warning,
    onError: Colors.white,
    errorContainer: DT.warningSoftBg,
    onErrorContainer: DT.onWarningSoft,
    surface: DT.card,
    onSurface: DT.textPrimary,
    onSurfaceVariant: DT.textSecondary,
    surfaceContainerLowest: DT.card,
    surfaceContainerLow: DT.card,
    surfaceContainer: DT.card,
    surfaceContainerHigh: DT.surfaceHigh,
    surfaceContainerHighest: DT.surfaceDim,
    outline: DT.outlineVariant,
    outlineVariant: DT.outline,
  );
  final text = _inter(_textTheme);
  const pill = StadiumBorder();
  final btnLabel = text.titleMedium!.copyWith(fontSize: 16);
  OutlineInputBorder border([Color? c, double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(DT.radius),
      borderSide: c == null ? BorderSide.none : BorderSide(color: c, width: w));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _isTest ? null : GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: DT.background,
    canvasColor: DT.background,
    textTheme: text,
    extensions: const [DropItColors.light],
    appBarTheme: AppBarTheme(
      backgroundColor: DT.background,
      foregroundColor: DT.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: text.headlineSmall,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DT.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: DT.primary.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(DT.buttonHeight),
        shape: pill,
        elevation: 0,
        textStyle: btnLabel,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DT.textPrimary,
        backgroundColor: DT.card,
        minimumSize: const Size.fromHeight(DT.buttonHeightCompact),
        shape: pill,
        side: const BorderSide(color: DT.outline),
        textStyle: btnLabel,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: DT.accent, textStyle: text.titleMedium, shape: pill),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DT.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: text.bodyLarge!.copyWith(color: DT.textSecondary),
      labelStyle: text.bodyMedium!.copyWith(color: DT.textSecondary),
      helperStyle: text.bodySmall,
      border: border(),
      enabledBorder: border(),
      focusedBorder: border(DT.primary, 1.5),
      errorBorder: border(DT.warning),
      focusedErrorBorder: border(DT.warning, 1.5),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      trackColor:
          WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? DT.success : DT.outlineVariant),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? DT.success : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: DT.textSecondary,
      titleTextStyle: text.titleMedium,
      subtitleTextStyle: text.bodySmall,
    ),
    iconTheme: const IconThemeData(color: DT.textPrimary),
    dividerTheme: const DividerThemeData(color: DT.divider, space: 1, thickness: 1),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: DT.primary, linearTrackColor: DT.surfaceDim),
    dialogTheme: DialogThemeData(
      backgroundColor: DT.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radiusMd)),
      titleTextStyle: text.headlineSmall,
      contentTextStyle: text.bodyMedium,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: DT.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(DT.radiusMd))),
    ),
    datePickerTheme: const DatePickerThemeData(backgroundColor: DT.card, surfaceTintColor: Colors.transparent),
    timePickerTheme: const TimePickerThemeData(backgroundColor: DT.card),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: DT.primary,
      contentTextStyle: text.bodyMedium!.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radius)),
    ),
  );
}
