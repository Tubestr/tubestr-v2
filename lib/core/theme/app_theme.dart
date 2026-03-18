import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_descriptor.dart';

ThemeData buildAppTheme(ThemeDescriptor descriptor) {
  final palette = descriptor.palette;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: palette.accent,
        secondary: palette.accentSecondary,
        surface: palette.panel,
        error: palette.danger,
        onPrimary: Colors.white,
        onSecondary: palette.ink,
        onSurface: palette.ink,
      );

  final baseText = GoogleFonts.nunitoTextTheme();
  final displayText = GoogleFonts.fredokaTextTheme(baseText);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.backgroundTop,
    textTheme: displayText.copyWith(
      bodyLarge: baseText.bodyLarge?.copyWith(color: palette.ink),
      bodyMedium: baseText.bodyMedium?.copyWith(color: palette.ink),
      labelLarge: baseText.labelLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
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
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: palette.panelBorder),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      selectedColor: palette.accent.withValues(alpha: 0.18),
      side: BorderSide(color: palette.panelBorder),
      labelStyle: baseText.labelLarge?.copyWith(
        color: palette.ink,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.74),
      indicatorColor: palette.accent.withValues(alpha: 0.16),
      labelTextStyle: WidgetStatePropertyAll(
        baseText.labelMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.68),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: palette.panelBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: palette.panelBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: palette.accent, width: 1.5),
      ),
    ),
  );
}
