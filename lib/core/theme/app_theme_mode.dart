import 'package:flutter/material.dart';

enum AppThemeModePreference { system, light, dark }

extension AppThemeModePreferenceX on AppThemeModePreference {
  String get label => switch (this) {
    AppThemeModePreference.system => 'System',
    AppThemeModePreference.light => 'Light',
    AppThemeModePreference.dark => 'Dark',
  };

  String get description => switch (this) {
    AppThemeModePreference.system => 'Follow device',
    AppThemeModePreference.light => 'Keep it bright',
    AppThemeModePreference.dark => 'Keep it cozy',
  };

  IconData get icon => switch (this) {
    AppThemeModePreference.system => Icons.brightness_auto_rounded,
    AppThemeModePreference.light => Icons.light_mode_rounded,
    AppThemeModePreference.dark => Icons.dark_mode_rounded,
  };

  ThemeMode get materialThemeMode => switch (this) {
    AppThemeModePreference.system => ThemeMode.system,
    AppThemeModePreference.light => ThemeMode.light,
    AppThemeModePreference.dark => ThemeMode.dark,
  };

  Brightness resolveBrightness(Brightness platformBrightness) => switch (this) {
    AppThemeModePreference.system => platformBrightness,
    AppThemeModePreference.light => Brightness.light,
    AppThemeModePreference.dark => Brightness.dark,
  };

  static AppThemeModePreference fromStorage(String? raw) {
    return AppThemeModePreference.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => AppThemeModePreference.system,
    );
  }
}
