import 'package:flutter/material.dart';

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
  bool get ownerStyle => Theme.of(this).extension<OwnerStyle>() != null;
  DropItColors get dropit => Theme.of(this).extension<DropItColors>() ?? DropItColors.light;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Owner-only visual rollout; member screens retain their current palette.
class OwnerStyle extends ThemeExtension<OwnerStyle> {
  const OwnerStyle();
  static const canvas = Color(0xFFF4F5F7);
  static const inset = Color(0xFFF8F9FA);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF6C6C70);
  static const primary = Color(0xFF010102);
  static const line = Color(0xFFE5E7EB);
  @override
  OwnerStyle copyWith() => this;
  @override
  OwnerStyle lerp(covariant OwnerStyle? other, double t) => this;
}

ThemeData buildOwnerTheme() {
  final base = buildLightTheme();
  final scheme = base.colorScheme.copyWith(primary: OwnerStyle.primary, onPrimary: Colors.white,
      onSurface: OwnerStyle.ink, onSurfaceVariant: OwnerStyle.muted,
      surfaceContainerHigh: OwnerStyle.inset, surfaceContainerHighest: OwnerStyle.line,
      outline: OwnerStyle.muted, outlineVariant: OwnerStyle.line);
  return base.copyWith(
    extensions: [...base.extensions.values, const OwnerStyle()],
    colorScheme: scheme,
    scaffoldBackgroundColor: OwnerStyle.canvas,
    canvasColor: OwnerStyle.canvas,
    textTheme: base.textTheme.apply(bodyColor: OwnerStyle.ink, displayColor: OwnerStyle.ink),
    filledButtonTheme: FilledButtonThemeData(style: base.filledButtonTheme.style!.copyWith(
      foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? OwnerStyle.muted : Colors.white),
      backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? OwnerStyle.line : OwnerStyle.primary))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: base.outlinedButtonTheme.style!.copyWith(
      foregroundColor: const WidgetStatePropertyAll(OwnerStyle.ink),
      side: const WidgetStatePropertyAll(BorderSide(color: OwnerStyle.line)))),
    checkboxTheme: base.checkboxTheme.copyWith(checkColor: const WidgetStatePropertyAll(Colors.white), fillColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? OwnerStyle.primary : Colors.transparent)),
    radioTheme: base.radioTheme.copyWith(fillColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? OwnerStyle.primary : OwnerStyle.muted)),
    switchTheme: base.switchTheme.copyWith(trackColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? OwnerStyle.primary : OwnerStyle.line)),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: OwnerStyle.line))),
    dividerTheme: const DividerThemeData(color: OwnerStyle.line, thickness: 1),
    datePickerTheme: base.datePickerTheme.copyWith(
      dayForegroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
      todayForegroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : OwnerStyle.ink),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? OwnerStyle.primary : null)),
    timePickerTheme: base.timePickerTheme.copyWith(dialBackgroundColor: OwnerStyle.inset,
      dialTextColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : OwnerStyle.ink),
      hourMinuteTextColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : OwnerStyle.ink),
      dialHandColor: OwnerStyle.primary, hourMinuteColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.selected) ? OwnerStyle.primary : OwnerStyle.inset)),
  );
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

ThemeData buildLightTheme() {
  const scheme = ColorScheme.light(
    primary: DT.primary,
    onPrimary: DT.onPrimary,
    primaryContainer: DT.accentSoftBg,
    onPrimaryContainer: DT.accent,
    primaryFixed: DT.surfaceDim,
    primaryFixedDim: DT.outlineVariant,
    onPrimaryFixed: DT.textPrimary,
    onPrimaryFixedVariant: DT.textSecondary,
    secondary: DT.accent,
    onSecondary: Colors.white,
    secondaryContainer: DT.accentSoftBg,
    onSecondaryContainer: DT.accent,
    secondaryFixed: DT.accentSoftBg,
    secondaryFixedDim: Color(0xFFFFC999),
    onSecondaryFixed: DT.accent,
    onSecondaryFixedVariant: DT.accent,
    tertiary: DT.success,
    onTertiary: Colors.white,
    tertiaryContainer: DT.successSoftBg,
    onTertiaryContainer: DT.success,
    tertiaryFixed: DT.successSoftBg,
    tertiaryFixedDim: Color(0xFFB9DFC5),
    onTertiaryFixed: DT.success,
    onTertiaryFixedVariant: DT.success,
    error: DT.warning,
    onError: Colors.white,
    errorContainer: DT.warningSoftBg,
    onErrorContainer: DT.onWarningSoft,
    surface: DT.card,
    onSurface: DT.textPrimary,
    onSurfaceVariant: DT.textSecondary,
    surfaceTint: Colors.transparent,
    surfaceDim: DT.surfaceDim,
    surfaceBright: DT.card,
    inverseSurface: DT.textPrimary,
    onInverseSurface: Colors.white,
    inversePrimary: DT.outlineVariant,
    surfaceContainerLowest: DT.card,
    surfaceContainerLow: DT.card,
    surfaceContainer: DT.card,
    surfaceContainerHigh: DT.surfaceHigh,
    surfaceContainerHighest: DT.surfaceDim,
    outline: DT.outlineVariant,
    outlineVariant: DT.outline,
  );
  final text = _textTheme.apply(fontFamily: 'Inter');
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radius));
  final btnLabel = text.titleMedium!.copyWith(fontSize: 16);
  OutlineInputBorder border([Color? c, double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(DT.radius),
    borderSide: c == null ? BorderSide.none : BorderSide(color: c, width: w),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    splashFactory: InkSparkle.splashFactory,
    hoverColor: DT.primary.withValues(alpha: 0.04),
    focusColor: DT.accent.withValues(alpha: 0.10),
    disabledColor: DT.textSecondary,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: DT.background,
    canvasColor: DT.background,
    textTheme: text,
    extensions: const [DropItColors.light],
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: DT.accent,
      selectionColor: DT.accent.withValues(alpha: 0.16),
      selectionHandleColor: DT.accent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DT.primary,
        foregroundColor: DT.onPrimary,
        disabledBackgroundColor: DT.surfaceDim,
        disabledForegroundColor: DT.textSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: pill,
        minimumSize: const Size(48, DT.buttonHeightCompact),
        textStyle: btnLabel,
      ),
    ),
    cardTheme: CardThemeData(
      color: DT.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radius)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: DT.card,
      selectedColor: DT.accentSoftBg,
      disabledColor: DT.surfaceHigh,
      checkmarkColor: DT.accent,
      labelStyle: text.labelLarge,
      secondaryLabelStyle: text.labelLarge!.copyWith(color: DT.accent),
      side: const BorderSide(color: DT.outline),
      shape: pill,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: DT.textPrimary,
      unselectedLabelColor: DT.textSecondary,
      labelStyle: text.titleMedium,
      unselectedLabelStyle: text.labelLarge,
      indicatorColor: DT.accent,
      dividerColor: DT.outline,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: text.bodyMedium,
      menuStyle: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(DT.card),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radius))),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: DT.card,
      surfaceTintColor: Colors.transparent,
      textStyle: text.bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radius)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: DT.textPrimary, borderRadius: BorderRadius.circular(DT.radiusSm)),
      textStyle: text.bodySmall!.copyWith(color: Colors.white),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? DT.accent : DT.outlineVariant,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: DT.accent,
      inactiveTrackColor: DT.surfaceDim,
      thumbColor: DT.accent,
      overlayColor: DT.accentSoftBg,
    ),
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
        foregroundColor: DT.onPrimary,
        disabledBackgroundColor: DT.surfaceDim,
        disabledForegroundColor: DT.textSecondary,
        minimumSize: const Size.fromHeight(DT.buttonHeight),
        shape: pill,
        elevation: 0,
        textStyle: btnLabel,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DT.accent,
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
      focusedBorder: border(DT.accent, 1.5),
      errorBorder: border(DT.warning),
      focusedErrorBorder: border(DT.warning, 1.5),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? DT.accent : DT.outlineVariant,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? DT.surfaceDim
        : s.contains(WidgetState.selected) ? DT.accent : DT.card),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: const BorderSide(color: DT.outlineVariant, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(
      foregroundColor: DT.accent, hoverColor: DT.accentSoftBg,
      minimumSize: const Size(44, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radiusSm)),
    )),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DT.card, indicatorColor: DT.accentSoftBg,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? DT.accent : DT.textSecondary)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => text.labelSmall!.copyWith(color: s.contains(WidgetState.selected) ? DT.accent : DT.textSecondary)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? DT.accent : DT.textSecondary),
      backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? DT.accentSoftBg : DT.card),
      side: const WidgetStatePropertyAll(BorderSide(color: DT.outline)),
    )),
    listTileTheme: ListTileThemeData(
      iconColor: DT.textSecondary,
      titleTextStyle: text.titleMedium,
      subtitleTextStyle: text.bodySmall,
    ),
    iconTheme: const IconThemeData(color: DT.textPrimary),
    dividerTheme: const DividerThemeData(color: DT.divider, space: 1, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: DT.primary, linearTrackColor: DT.surfaceDim),
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
    datePickerTheme: DatePickerThemeData(
      backgroundColor: DT.card,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: DT.card,
      headerForegroundColor: DT.textPrimary,
      todayForegroundColor: const WidgetStatePropertyAll(DT.accent),
      todayBorder: const BorderSide(color: DT.accent),
      dayBackgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? DT.primary : null),
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? DT.onPrimary : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radiusMd)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: DT.card,
      dialBackgroundColor: DT.surfaceHigh,
      dialHandColor: DT.primary,
      hourMinuteColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.selected) ? DT.primary : DT.surfaceHigh,
      ),
      hourMinuteTextColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.selected) ? DT.onPrimary : DT.textPrimary,
      ),
      dayPeriodColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? DT.accentSoftBg : DT.card),
      dayPeriodTextColor: DT.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radiusMd)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: DT.textPrimary,
      contentTextStyle: text.bodyMedium!.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radius)),
    ),
  );
}
