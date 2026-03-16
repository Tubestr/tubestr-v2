import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../services/mdk/mdk_service.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../models/parent_zone_models.dart';

class ParentZoneConnectionsSection extends ConsumerWidget {
  const ParentZoneConnectionsSection({
    super.key,
    required this.mdkDebugFuture,
    required this.isGeneratingInvitePacket,
    required this.isCreatingWelcome,
    required this.isAcceptingWelcome,
    required this.isCreatingDebugShare,
    required this.isImportingDebugEvent,
    required this.eventImportController,
    required this.inviteImportController,
    required this.onCreateInvite,
    required this.onScanAndProcessInvite,
    required this.onProcessInviteInput,
    required this.onAcceptPendingWelcome,
    required this.onRefreshMdkState,
    required this.onManageGroup,
    required this.onCreateDebugShareEvent,
    required this.onImportDebugGroupEvent,
  });

  final Future<ParentZoneMdkDebugState> mdkDebugFuture;
  final bool isGeneratingInvitePacket;
  final bool isCreatingWelcome;
  final bool isAcceptingWelcome;
  final bool isCreatingDebugShare;
  final bool isImportingDebugEvent;
  final TextEditingController eventImportController;
  final TextEditingController inviteImportController;
  final VoidCallback onCreateInvite;
  final VoidCallback onScanAndProcessInvite;
  final VoidCallback onProcessInviteInput;
  final ValueChanged<String> onAcceptPendingWelcome;
  final VoidCallback onRefreshMdkState;
  final ValueChanged<MdkGroupSummary> onManageGroup;
  final Future<void> Function(bool publish) onCreateDebugShareEvent;
  final VoidCallback onImportDebugGroupEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(parentIdentityProvider).valueOrNull;
    final palette = ref.watch(activeThemeProvider).palette;
    final busy = isGeneratingInvitePacket || isCreatingWelcome;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect with a Family',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Share one invite code, then approve the connection here when their welcome arrives.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: 16),
              _ActionTile(
                icon: Icons.qr_code_rounded,
                color: palette.accent,
                title: 'Invite a Family',
                subtitle: 'Create a QR code or shareable invite link',
                busy: isGeneratingInvitePacket,
                onTap: identity == null || busy ? null : onCreateInvite,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.qr_code_scanner_rounded,
                color: palette.accentSecondary,
                title: 'Scan an Invite',
                subtitle: 'Create the shared family space in one step',
                busy: isCreatingWelcome,
                onTap: identity == null || busy ? null : onScanAndProcessInvite,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: inviteImportController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Paste invite link or code',
                  hintText: 'nook://family-invite?...',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: identity == null || busy
                    ? null
                    : onProcessInviteInput,
                child: Text(
                  isCreatingWelcome ? 'Connecting…' : 'Process invite',
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
              return FrostCard(child: Text('Error: ${snapshot.error}'));
            }
            final data = snapshot.data!;
            if (data.groups.isEmpty && data.pendingWelcomes.isEmpty) {
              return FrostCard(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Icon(
                      Icons.people_outline_rounded,
                      size: 40,
                      color: palette.mutedInk,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No connections yet',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
                    ),
                    const SizedBox(height: 8),
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
                              'Pending Invitations',
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        welcome.groupName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${welcome.memberCount} members',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: palette.mutedInk),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton(
                                  onPressed: isAcceptingWelcome
                                      ? null
                                      : () => onAcceptPendingWelcome(
                                          welcome.welcomeEventIdHex,
                                        ),
                                  child: Text(
                                    isAcceptingWelcome ? 'Joining…' : 'Accept',
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
                              'Active Connections',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              onPressed: onRefreshMdkState,
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${group.memberCount} members',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: palette.mutedInk),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_horiz_rounded),
                                  tooltip: 'Manage connection',
                                  onPressed: () => onManageGroup(group),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                FrostCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transport Debug',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create a sample video share wrapper event from your latest local clip, then import that event JSON on another device.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.mutedInk,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: isCreatingDebugShare
                                ? null
                                : () => onCreateDebugShareEvent(false),
                            child: Text(
                              isCreatingDebugShare
                                  ? 'Working…'
                                  : 'Create sample event',
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: isCreatingDebugShare
                                ? null
                                : () => onCreateDebugShareEvent(true),
                            child: const Text('Create + publish'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: eventImportController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Incoming group event JSON',
                          hintText: 'Paste a signed kind:445 event here',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: isImportingDebugEvent
                            ? null
                            : onImportDebugGroupEvent,
                        child: Text(
                          isImportingDebugEvent
                              ? 'Importing…'
                              : 'Import event into SyncCoordinator',
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
          : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
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
