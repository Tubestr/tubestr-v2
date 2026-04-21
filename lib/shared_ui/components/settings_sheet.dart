import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/di/providers.dart';
import '../../core/i18n/app_locale_preference.dart';
import '../../core/theme/app_theme_mode.dart';
import '../../core/theme/radii.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_descriptor.dart';
import '../../l10n/app_localizations_x.dart';
import '../../l10n/l10n.dart';

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

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

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.xxl),
          ),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.mutedInk.withValues(alpha: 0.3),
                      borderRadius: AppRadii.pillAll,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Profile section
                if (profiles.length > 1) ...[
                  _SectionLabel(
                    label: context.l10n.switchProfile,
                    palette: palette,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: profiles.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
                        final isSelected = profile.id == selectedId;
                        return _ProfileChip(
                          name: profile.name,
                          isSelected: isSelected,
                          palette: palette,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(selectedProfileIdProvider.notifier).state =
                                profile.id;
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Theme section
                _SectionLabel(
                  label: context.l10n.onboardingTheme,
                  palette: palette,
                ),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.4,
                  children: [
                    for (final theme in ThemeDescriptor.values)
                      _ThemeCard(
                        theme: theme,
                        isSelected: theme == activeTheme,
                        currentBrightness: Theme.of(context).brightness,
                        onTap: selected == null
                            ? null
                            : () async {
                                HapticFeedback.selectionClick();
                                await ref
                                    .read(appDatabaseProvider)
                                    .updateProfileTheme(
                                      profileId: selected.id,
                                      theme: theme.name,
                                    );
                              },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Appearance section
                _SectionLabel(label: context.l10n.appearance, palette: palette),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<AppThemeModePreference>(
                  segments: [
                    for (final mode in AppThemeModePreference.values)
                      ButtonSegment(
                        value: mode,
                        icon: Icon(mode.icon, size: AppIconSize.md),
                        label: Text(context.l10n.appearanceModeLabel(mode)),
                      ),
                  ],
                  selected: {appearanceMode},
                  onSelectionChanged: (selection) async {
                    HapticFeedback.selectionClick();
                    await ref
                        .read(appDatabaseProvider)
                        .putSetting(
                          AppConstants.appearanceModeSettingKey,
                          selection.first.name,
                        );
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Language section
                _SectionLabel(label: context.l10n.language, palette: palette),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<AppLocalePreference>(
                  segments: [
                    for (final pref in AppLocalePreference.values)
                      ButtonSegment(
                        value: pref,
                        label: Text(_localeLabel(pref)),
                      ),
                  ],
                  selected: {localePreference},
                  onSelectionChanged: (selection) async {
                    HapticFeedback.selectionClick();
                    await ref
                        .read(appDatabaseProvider)
                        .putSetting(
                          AppConstants.localePreferenceSettingKey,
                          selection.first.name,
                        );
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _localeLabel(AppLocalePreference pref) => switch (pref) {
  AppLocalePreference.system => 'System',
  AppLocalePreference.english => 'EN',
  AppLocalePreference.spanish => 'ES',
};

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.palette});

  final String label;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: palette.mutedInk),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.name,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final KidPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: AppRadii.lgAll,
          border: Border.all(
            color: isSelected ? palette.accent : palette.panelBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isSelected
                  ? palette.accent
                  : palette.mutedInk.withValues(alpha: 0.2),
              child: Icon(
                Icons.person_rounded,
                size: AppIconSize.md,
                color: isSelected ? palette.panel : palette.mutedInk,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? palette.accent : palette.ink,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.currentBrightness,
    required this.onTap,
  });

  final ThemeDescriptor theme;
  final bool isSelected;
  final Brightness currentBrightness;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final themePalette = theme.paletteFor(currentBrightness);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [themePalette.accent, themePalette.accentSecondary],
          ),
          borderRadius: AppRadii.mdAll,
          border: isSelected
              ? Border.all(color: themePalette.ink, width: 3)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themePalette.accent.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                context.l10n.themeLabel(theme),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: themePalette.onAccent,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: themePalette.ink.withValues(alpha: 0.32),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: themePalette.surfaceStrong,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: AppIconSize.xs,
                    color: themePalette.accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
