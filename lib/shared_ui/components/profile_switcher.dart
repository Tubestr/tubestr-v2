import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/di/providers.dart';
import '../../core/theme/app_theme_mode.dart';
import '../../core/theme/theme_descriptor.dart';

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
    final palette = ref.watch(activePaletteProvider);

    return MenuAnchor(
      menuChildren: [
        if (profiles.length > 1) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Switch Profile',
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
            'Theme',
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
            child: Text(theme.label),
          ),
        const Divider(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Appearance',
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
            selected?.name ?? 'Profile',
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
          Text(mode.label),
          Text(
            mode.description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
          ),
        ],
      ),
    );
  }
}
