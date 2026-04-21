import 'package:flutter/widgets.dart';

enum AppLocalePreference { system, english, spanish }

extension AppLocalePreferenceX on AppLocalePreference {
  Locale? get locale => switch (this) {
    AppLocalePreference.system => null,
    AppLocalePreference.english => const Locale('en'),
    AppLocalePreference.spanish => const Locale('es'),
  };

  static AppLocalePreference fromStorage(String? raw) {
    return AppLocalePreference.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => AppLocalePreference.system,
    );
  }
}
