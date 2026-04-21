import '../core/i18n/app_locale_preference.dart';
import '../core/theme/app_theme_mode.dart';
import '../core/theme/theme_descriptor.dart';
import '../features/parent_zone/presentation/models/parent_zone_models.dart';
import 'app_localizations.dart';

extension AppLocalizationsX on AppLocalizations {
  String themeLabel(ThemeDescriptor theme) => switch (theme) {
    ThemeDescriptor.campfire => kidThemeCampfire,
    ThemeDescriptor.treehouse => kidThemeTreehouse,
    ThemeDescriptor.blanketFort => kidThemeBlanketFort,
    ThemeDescriptor.starlight => kidThemeStarlight,
  };

  String appearanceModeLabel(AppThemeModePreference mode) => switch (mode) {
    AppThemeModePreference.system => themeSystem,
    AppThemeModePreference.light => themeLight,
    AppThemeModePreference.dark => themeDark,
  };

  String appearanceModeDescription(AppThemeModePreference mode) =>
      switch (mode) {
        AppThemeModePreference.system => themeSystemDescription,
        AppThemeModePreference.light => themeLightDescription,
        AppThemeModePreference.dark => themeDarkDescription,
      };

  String localePreferenceLabel(AppLocalePreference preference) =>
      switch (preference) {
        AppLocalePreference.system => languageSystem,
        AppLocalePreference.english => languageEnglish,
        AppLocalePreference.spanish => languageSpanish,
      };

  String localePreferenceDescription(AppLocalePreference preference) =>
      switch (preference) {
        AppLocalePreference.system => languageSystemDescription,
        AppLocalePreference.english => languageEnglishDescription,
        AppLocalePreference.spanish => languageSpanishDescription,
      };

  String parentZoneSectionLabel(ParentZoneSection section) => switch (section) {
    ParentZoneSection.dashboard => parentSectionDashboard,
    ParentZoneSection.children => parentSectionChildren,
    ParentZoneSection.familySpaces => parentSectionFamily,
    ParentZoneSection.activity => parentSectionActivity,
    ParentZoneSection.account => parentSectionAccount,
    ParentZoneSection.network => parentSectionNetwork,
    ParentZoneSection.diagnostics => parentSectionDiagnostics,
  };
}
