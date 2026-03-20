import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/nostr/nostr_key_format.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../services/mdk/mdk_service.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../models/parent_zone_models.dart';

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
    final palette = ref.watch(activeThemeProvider).palette;
    final busy = isGeneratingInvitePacket || isCreatingWelcome;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < 600 ? 12.0 : 20.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 100),
      children: [
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Open A Family Space',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Share one invite code, then come back here when the other parent sends their welcome.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: 16),
              _ActionTile(
                icon: Icons.qr_code_rounded,
                color: palette.accent,
                title: 'Create invite',
                subtitle: 'Show a QR code or send a shareable invite link',
                busy: isGeneratingInvitePacket,
                onTap: identity == null || busy ? null : onCreateInvite,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.qr_code_scanner_rounded,
                color: palette.accentSecondary,
                title: 'Scan invite',
                subtitle: 'Join the shared family space in one step',
                busy: isCreatingWelcome,
                onTap: identity == null || busy ? null : onScanAndProcessInvite,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.content_paste_rounded,
                color: palette.ink,
                title: 'Paste invite',
                subtitle: 'Enter an invite link or code manually',
                busy: false,
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
        const SizedBox(height: 16),
        FutureBuilder<ParentZoneMdkDebugState>(
          future: mdkDebugFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const FrostCard(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            if (snapshot.hasError) {
              return FrostCard(
                child: Text('We could not load family connections right now.'),
              );
            }
            final data = snapshot.data!;
            if (data.groups.isEmpty && data.pendingWelcomes.isEmpty) {
              return FrostCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No trusted families yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create an invite or scan one from another parent to open your first family space.',
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
                              size: 18,
                              color: palette.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pending Welcomes',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final welcome in data.pendingWelcomes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
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
                                    isAcceptingWelcome ? 'Joining…' : 'Approve',
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                              size: 18,
                              color: palette.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Active Family Spaces',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                onRefreshMdkState();
                              },
                            ),
                          ],
                        ),
                        for (final group in data.groups)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
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
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ActiveGroupDetails(group: group),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_horiz_rounded),
                                  tooltip: 'Manage connection',
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
    final palette = ref.watch(activeThemeProvider).palette;
    final welcomer = ref
        .watch(resolvedParentProfileProvider(welcome.welcomerPubkeyHex))
        .valueOrNull;
    final inviterLabel =
        welcomer?.displayName ??
        formatCompactPublicKeyLabel(welcome.welcomerPubkeyHex);
    final groupLabel = _preferredGroupLabel(
      currentLabel: welcome.groupName,
      fallbackParentName: welcomer?.displayName,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(groupLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          'From $inviterLabel · ${welcome.memberCount} members',
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
    final palette = ref.watch(activeThemeProvider).palette;
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
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(groupLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          familyLabel == null || familyLabel.isEmpty
              ? adminPubkey == null
                    ? '${group.memberCount} members'
                    : '${formatCompactPublicKeyLabel(adminPubkey)} · ${group.memberCount} members'
              : '$familyLabel · ${group.memberCount} members',
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
}) {
  final trimmedCurrent = currentLabel.trim();
  if (trimmedCurrent.isNotEmpty &&
      trimmedCurrent.toLowerCase() != 'family space') {
    return trimmedCurrent;
  }

  final fallback = fallbackParentName?.trim();
  if (fallback == null || fallback.isEmpty) {
    return trimmedCurrent.isEmpty ? 'Family Space' : trimmedCurrent;
  }
  if (fallback.toLowerCase().contains('family')) {
    return fallback;
  }
  return '$fallback Family';
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
            20,
            0,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste Invite',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Paste an invite link or code from another parent.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Invite link or code',
                  hintText: 'nook://family-invite?...',
                ),
              ),
              const SizedBox(height: 16),
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
                  child: Text(busy ? 'Joining family…' : 'Use invite'),
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
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null
          ? Colors.grey.shade100
          : Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: onTap == null ? Colors.grey : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onTap == null
                            ? Colors.grey
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
