import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/di/providers.dart';
import '../../core/i18n/app_locale_preference.dart';
import '../../core/theme/app_theme_mode.dart';
import '../../core/theme/theme_descriptor.dart';
import '../../l10n/app_localizations_x.dart';
import '../../l10n/l10n.dart';

/// Capsule button that shows the active profile name and opens
/// a menu to switch profiles or change theme.
class ProfileSwitcherButton extends ConsumerWidget {
  const ProfileSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
    final selectedId = ref.watch(selectedProfileIdProvider);
    final selected =
        profiles.firstWhereOrNull((p) => p.id == selectedId) ??
        profiles.firstOrNull;
    final activeTheme = ref.watch(activeThemeProvider);
    final appearanceMode = ref.watch(activeAppearanceModeProvider);
    final localePreference = ref.watch(activeLocalePreferenceProvider);
    final palette = ref.watch(activePaletteProvider);

    return MenuAnchor(
      menuChildren: [
        if (profiles.length > 1) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              context.l10n.switchProfile,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: palette.mutedInk),
            ),
          ),
          for (final profile in profiles)
            MenuItemButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                ref.read(selectedProfileIdProvider.notifier).state = profile.id;
              },
              leadingIcon: profile.id == selectedId
                  ? Icon(Icons.check_rounded, size: 18, color: palette.accent)
                  : const SizedBox(width: 18),
              child: Text(profile.name),
            ),
          const Divider(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            context.l10n.onboardingTheme,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: palette.mutedInk),
          ),
        ),
        for (final theme in ThemeDescriptor.values)
          MenuItemButton(
            onPressed: selected == null
                ? null
                : () async {
                    HapticFeedback.selectionClick();
                    // Update the profile's theme in the database
                    await ref
                        .read(appDatabaseProvider)
                        .updateProfileTheme(
                          profileId: selected.id,
                          theme: theme.name,
                        );
                  },
            leadingIcon: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: theme.paletteFor(Theme.of(context).brightness).accent,
                shape: BoxShape.circle,
              ),
            ),
            trailingIcon: theme == activeTheme
                ? Icon(Icons.check_rounded, size: 18, color: palette.accent)
                : const SizedBox(width: 18),
            child: Text(context.l10n.themeLabel(theme)),
          ),
        const Divider(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            context.l10n.appearance,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: palette.mutedInk),
          ),
        ),
        for (final mode in AppThemeModePreference.values)
          MenuItemButton(
            onPressed: () async {
              HapticFeedback.selectionClick();
              await ref
                  .read(appDatabaseProvider)
                  .putSetting(AppConstants.appearanceModeSettingKey, mode.name);
            },
            leadingIcon: Icon(
              mode.icon,
              size: 19,
              color: mode == appearanceMode ? palette.accent : palette.mutedInk,
            ),
            trailingIcon: mode == appearanceMode
                ? Icon(Icons.check_rounded, size: 18, color: palette.accent)
                : const SizedBox(width: 18),
            child: _AppearanceModeLabel(mode: mode, palette: palette),
          ),
        const Divider(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            context.l10n.language,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: palette.mutedInk),
          ),
        ),
        for (final preference in AppLocalePreference.values)
          MenuItemButton(
            onPressed: () async {
              HapticFeedback.selectionClick();
              await ref
                  .read(appDatabaseProvider)
                  .putSetting(
                    AppConstants.localePreferenceSettingKey,
                    preference.name,
                  );
            },
            leadingIcon: Icon(
              _localePreferenceIcon(preference),
              size: 19,
              color: preference == localePreference
                  ? palette.accent
                  : palette.mutedInk,
            ),
            trailingIcon: preference == localePreference
                ? Icon(Icons.check_rounded, size: 18, color: palette.accent)
                : const SizedBox(width: 18),
            child: _LocalePreferenceLabel(
              preference: preference,
              palette: palette,
            ),
          ),
      ],
      builder: (context, controller, child) {
        return ActionChip(
          avatar: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.accent, width: 1.5),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: palette.accent.withValues(alpha: 0.15),
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: palette.accent,
              ),
            ),
          ),
          label: Text(
            selected?.name ?? context.l10n.profileSwitcherProfileFallback,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }
}

IconData _localePreferenceIcon(AppLocalePreference preference) =>
    switch (preference) {
      AppLocalePreference.system => Icons.language_rounded,
      AppLocalePreference.english => Icons.translate_rounded,
      AppLocalePreference.spanish => Icons.translate_rounded,
    };

class _AppearanceModeLabel extends StatelessWidget {
  const _AppearanceModeLabel({required this.mode, required this.palette});

  final AppThemeModePreference mode;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.appearanceModeLabel(mode)),
          Text(
            context.l10n.appearanceModeDescription(mode),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
          ),
        ],
      ),
    );
  }
}

class _LocalePreferenceLabel extends StatelessWidget {
  const _LocalePreferenceLabel({
    required this.preference,
    required this.palette,
  });

  final AppLocalePreference preference;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.localePreferenceLabel(preference)),
          Text(
            context.l10n.localePreferenceDescription(preference),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
          ),
        ],
      ),
    );
  }
}
