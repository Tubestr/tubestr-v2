import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
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
        profiles.firstWhereOrNull((p) => p.id == selectedId) ?? profiles.firstOrNull;
    final palette = ref.watch(activeThemeProvider).palette;

    return MenuAnchor(
      menuChildren: [
        if (profiles.length > 1) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Switch Profile',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.mutedInk,
                  ),
            ),
          ),
          for (final profile in profiles)
            MenuItemButton(
              onPressed: () {
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: palette.mutedInk,
                ),
          ),
        ),
        for (final theme in ThemeDescriptor.values)
          MenuItemButton(
            onPressed: selected == null
                ? null
                : () async {
                    // Update the profile's theme in the database
                    await ref.read(appDatabaseProvider).updateProfileTheme(
                          profileId: selected.id,
                          theme: theme.name,
                        );
                  },
            leadingIcon: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: theme.palette.accent,
                shape: BoxShape.circle,
              ),
            ),
            child: Text(theme.label),
          ),
      ],
      builder: (context, controller, child) {
        return ActionChip(
          avatar: CircleAvatar(
            radius: 12,
            backgroundColor: palette.accent.withValues(alpha: 0.15),
            child: Icon(Icons.person_rounded, size: 14, color: palette.accent),
          ),
          label: Text(selected?.name ?? 'Profile'),
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
