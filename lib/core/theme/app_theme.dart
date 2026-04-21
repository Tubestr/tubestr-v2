import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'radii.dart';
import 'spacing.dart';
import 'theme_descriptor.dart';

ThemeData buildAppTheme(
  ThemeDescriptor descriptor, {
  Brightness brightness = Brightness.light,
}) {
  final palette = descriptor.paletteFor(brightness);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: brightness,
      ).copyWith(
        primary: palette.accent,
        secondary: palette.accentSecondary,
        surface: palette.panel,
        error: palette.danger,
        onPrimary: palette.onAccent,
        onSecondary: palette.onAccentSecondary,
        onSurface: palette.ink,
      );

  final materialText = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
  ).textTheme;
  final baseText = GoogleFonts.nunitoTextTheme(
    materialText,
  ).apply(bodyColor: palette.ink, displayColor: palette.ink);
  final displayText = GoogleFonts.fredokaTextTheme(
    baseText,
  ).apply(bodyColor: palette.ink, displayColor: palette.ink);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.backgroundTop,
    textTheme: displayText.copyWith(
      bodyLarge: baseText.bodyLarge?.copyWith(color: palette.ink),
      bodyMedium: baseText.bodyMedium?.copyWith(color: palette.ink),
      bodySmall: baseText.bodySmall?.copyWith(color: palette.mutedInk),
      labelLarge: baseText.labelLarge?.copyWith(
        color: palette.ink,
        fontWeight: FontWeight.w800,
      ),
      labelMedium: baseText.labelMedium?.copyWith(color: palette.mutedInk),
      labelSmall: baseText.labelSmall?.copyWith(color: palette.mutedInk),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: displayText.titleLarge?.copyWith(
        color: palette.ink,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.cardAll,
        side: BorderSide(color: palette.panelBorder),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.xxlAll),
      selectedColor: palette.accent.withValues(alpha: 0.18),
      side: BorderSide(color: palette.panelBorder),
      labelStyle: baseText.labelLarge?.copyWith(
        color: palette.ink,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surfaceRaised,
      indicatorColor: palette.accent.withValues(alpha: 0.16),
      labelTextStyle: WidgetStatePropertyAll(
        baseText.labelMedium?.copyWith(
          color: palette.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.xxlAll),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.ink,
        side: BorderSide(color: palette.panelBorder),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.xxlAll),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceSubtle,
      border: OutlineInputBorder(
        borderRadius: AppRadii.xxlAll,
        borderSide: BorderSide(color: palette.panelBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.xxlAll,
        borderSide: BorderSide(color: palette.panelBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.xxlAll,
        borderSide: BorderSide(color: palette.accent, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.ink,
      contentTextStyle: baseText.bodyMedium?.copyWith(color: palette.panel),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.xlAll),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surfaceRaised,
      modalBackgroundColor: palette.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xxl),
        ),
        side: BorderSide(color: palette.panelBorder),
      ),
    ),
  );
}
