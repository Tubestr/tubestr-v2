import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/nostr/nostr_key_format.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../services/mdk/mdk_service.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../models/parent_zone_models.dart';
import '../../../../l10n/l10n.dart';

class ParentZoneFamilySpacesSection extends ConsumerWidget {
  const ParentZoneFamilySpacesSection({
    super.key,
    required this.mdkDebugFuture,
    required this.isGeneratingInvitePacket,
    required this.isCreatingWelcome,
    required this.isAcceptingWelcome,
    required this.inviteImportController,
    required this.onCreateInvite,
    required this.onScanAndProcessInvite,
    required this.onProcessInviteInput,
    required this.onAcceptPendingWelcome,
    required this.onRefreshMdkState,
    required this.onManageGroup,
  });

  final Future<ParentZoneMdkDebugState> mdkDebugFuture;
  final bool isGeneratingInvitePacket;
  final bool isCreatingWelcome;
  final bool isAcceptingWelcome;
  final TextEditingController inviteImportController;
  final VoidCallback onCreateInvite;
  final VoidCallback onScanAndProcessInvite;
  final VoidCallback onProcessInviteInput;
  final ValueChanged<String> onAcceptPendingWelcome;
  final VoidCallback onRefreshMdkState;
  final ValueChanged<MdkGroupSummary> onManageGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(parentIdentityProvider).valueOrNull;
    final palette = ref.watch(activePaletteProvider);
    final busy = isGeneratingInvitePacket || isCreatingWelcome;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < 600 ? 12.0 : 20.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppSpacing.md,
        hPad,
        AppSpacing.bottomSafe,
      ),
      children: [
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentOpenFamilySpace,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.parentOpenFamilySpaceDetail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ActionTile(
                icon: Icons.qr_code_rounded,
                color: palette.accent,
                title: context.l10n.parentCreateInvite,
                subtitle: context.l10n.parentCreateInviteDetail,
                busy: isGeneratingInvitePacket,
                palette: palette,
                onTap: identity == null || busy ? null : onCreateInvite,
              ),
              const SizedBox(height: AppSpacing.md),
              _ActionTile(
                icon: Icons.qr_code_scanner_rounded,
                color: palette.accentSecondary,
                title: context.l10n.parentScanInvite,
                subtitle: context.l10n.parentScanInviteDetail,
                busy: isCreatingWelcome,
                palette: palette,
                onTap: identity == null || busy ? null : onScanAndProcessInvite,
              ),
              const SizedBox(height: AppSpacing.md),
              _ActionTile(
                icon: Icons.content_paste_rounded,
                color: palette.ink,
                title: context.l10n.parentPasteInvite,
                subtitle: context.l10n.parentPasteInviteDetail,
                busy: false,
                palette: palette,
                onTap: identity == null || busy
                    ? null
                    : () => _showPasteInviteSheet(
                        context,
                        controller: inviteImportController,
                        busy: isCreatingWelcome,
                        onSubmit: onProcessInviteInput,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<ParentZoneMdkDebugState>(
          future: mdkDebugFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const FrostCard(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            if (snapshot.hasError) {
              return FrostCard(
                child: Text(context.l10n.parentFamilyConnectionsFailed),
              );
            }
            final data = snapshot.data!;
            if (data.groups.isEmpty && data.pendingWelcomes.isEmpty) {
              return FrostCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.parentNoFamiliesTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.parentNoFamiliesDetail,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                if (data.pendingWelcomes.isNotEmpty) ...[
                  FrostCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.mark_email_unread_rounded,
                              size: AppIconSize.md,
                              color: palette.warning,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              context.l10n.parentPendingWelcomes,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final welcome in data.pendingWelcomes)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _PendingWelcomeDetails(
                                    welcome: welcome,
                                  ),
                                ),
                                FilledButton(
                                  onPressed: isAcceptingWelcome
                                      ? null
                                      : () => onAcceptPendingWelcome(
                                          welcome.welcomeEventIdHex,
                                        ),
                                  child: Text(
                                    isAcceptingWelcome
                                        ? context.l10n.parentJoiningEllipsis
                                        : context.l10n.actionApprove,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (data.groups.isNotEmpty)
                  FrostCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.group_rounded,
                              size: AppIconSize.md,
                              color: palette.success,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              context.l10n.parentActiveFamilySpaces,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: AppIconSize.md,
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                onRefreshMdkState();
                              },
                            ),
                          ],
                        ),
                        for (final group in data.groups)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: palette.success,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _ActiveGroupDetails(group: group),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_horiz_rounded),
                                  tooltip: context.l10n.parentManageConnection,
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    onManageGroup(group);
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PendingWelcomeDetails extends ConsumerWidget {
  const _PendingWelcomeDetails({required this.welcome});

  final MdkPendingWelcome welcome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);
    final welcomer = ref
        .watch(resolvedParentProfileProvider(welcome.welcomerPubkeyHex))
        .valueOrNull;
    final inviterLabel =
        welcomer?.displayName ??
        formatCompactPublicKeyLabel(welcome.welcomerPubkeyHex);
    final groupLabel = _preferredGroupLabel(
      currentLabel: welcome.groupName,
      fallbackParentName: welcomer?.displayName,
      context: context,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(groupLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.parentPendingWelcomeDetail(
            inviterLabel,
            welcome.memberCount,
          ),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
        ),
      ],
    );
  }
}

class _ActiveGroupDetails extends ConsumerWidget {
  const _ActiveGroupDetails({required this.group});

  final MdkGroupSummary group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);
    final adminPubkey = group.adminPubkeysHex.isEmpty
        ? null
        : group.adminPubkeysHex.first;
    final adminProfile = adminPubkey == null
        ? null
        : ref.watch(resolvedParentProfileProvider(adminPubkey)).valueOrNull;
    final familyLabel = adminProfile?.displayName;
    final groupLabel = _preferredGroupLabel(
      currentLabel: group.name,
      fallbackParentName: familyLabel,
      context: context,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(groupLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          familyLabel == null || familyLabel.isEmpty
              ? adminPubkey == null
                    ? context.l10n.parentMembers(group.memberCount)
                    : '${formatCompactPublicKeyLabel(adminPubkey)} · ${context.l10n.parentMembers(group.memberCount)}'
              : '$familyLabel · ${context.l10n.parentMembers(group.memberCount)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
        ),
        Text(
          group.nostrGroupIdHex,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
        ),
      ],
    );
  }
}

String _preferredGroupLabel({
  required String currentLabel,
  required String? fallbackParentName,
  required BuildContext context,
}) {
  final trimmedCurrent = currentLabel.trim();
  if (trimmedCurrent.isNotEmpty &&
      trimmedCurrent.toLowerCase() != 'family space') {
    return trimmedCurrent;
  }

  final fallback = fallbackParentName?.trim();
  if (fallback == null || fallback.isEmpty) {
    return trimmedCurrent.isEmpty
        ? context.l10n.parentFamilySpaceFallback
        : trimmedCurrent;
  }
  if (fallback.toLowerCase().contains('family')) {
    return fallback;
  }
  return context.l10n.parentFamilyFallback(fallback);
}

void _showPasteInviteSheet(
  BuildContext context, {
  required TextEditingController controller,
  required bool busy,
  required VoidCallback onSubmit,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentPasteInviteTitle,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.parentPasteInvitePrompt,
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.l10n.parentInviteInputLabel,
                  hintText: 'tubestr://family-invite?...',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          Navigator.of(sheetContext).pop();
                          onSubmit();
                        },
                  child: Text(
                    busy
                        ? context.l10n.parentJoiningFamily
                        : context.l10n.parentUseInvite,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool busy;
  final KidPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null
          ? palette.panel.withValues(alpha: 0.42)
          : palette.panel.withValues(alpha: 0.72),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.lgAll,
        side: BorderSide(color: palette.panelBorder),
      ),
      child: InkWell(
        borderRadius: AppRadii.lgAll,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadii.lgAll,
                ),
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color, size: AppIconSize.xl),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: onTap == null ? palette.mutedInk : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onTap == null
                            ? palette.mutedInk
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: color,
                  size: AppIconSize.lg,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
