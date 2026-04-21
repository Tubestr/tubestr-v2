import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/theme/spacing.dart';
import '../../l10n/l10n.dart';
import 'settings_sheet.dart';

/// Capsule button that shows the active profile name and opens
/// a settings sheet for profile, theme, appearance, and language.
class ProfileSwitcherButton extends ConsumerWidget {
  const ProfileSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
    final selectedId = ref.watch(selectedProfileIdProvider);
    final selected =
        profiles.firstWhereOrNull((p) => p.id == selectedId) ??
        profiles.firstOrNull;
    final palette = ref.watch(activePaletteProvider);

    final profileName =
        selected?.name ?? context.l10n.profileSwitcherProfileFallback;

    return Semantics(
      label: '$profileName, settings',
      button: true,
      child: ActionChip(
        avatar: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: palette.accent, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: palette.accent.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person_rounded,
                  size: AppIconSize.md,
                  color: palette.accent,
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: palette.panel,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.accent, width: 1),
                ),
                child: Icon(
                  Icons.settings,
                  size: AppIconSize.xs,
                  color: palette.accent,
                ),
              ),
            ),
          ],
        ),
        label: Text(
          profileName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: AppTextSize.body,
          ),
        ),
        onPressed: () => showSettingsSheet(context),
      ),
    );
  }
}
