import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../../../../services/safety/safety_hq_service.dart';

class ParentZoneSettingsSection extends ConsumerWidget {
  const ParentZoneSettingsSection({
    super.key,
    required this.displayNameController,
    required this.relayController,
    required this.blossomController,
    required this.pinManagementController,
    required this.approvalRequired,
    required this.onRefresh,
    required this.onSaveDisplayName,
    required this.onPublishDisplayName,
    required this.onToggleApprovalRequired,
    required this.onRetryOfflineQueue,
    required this.onSaveRelays,
    required this.onRemoveRelay,
    required this.onResetRelays,
    required this.onReconnectRelays,
    required this.onSaveBlossomServers,
    required this.onPublishBlossomServers,
    required this.onUpdatePin,
    required this.onProvisionSafetyHq,
    required this.onResetApp,
  });

  final TextEditingController displayNameController;
  final TextEditingController relayController;
  final TextEditingController blossomController;
  final TextEditingController pinManagementController;
  final bool approvalRequired;
  final VoidCallback onRefresh;
  final VoidCallback onSaveDisplayName;
  final Future<void> Function() onPublishDisplayName;
  final ValueChanged<bool> onToggleApprovalRequired;
  final Future<void> Function() onRetryOfflineQueue;
  final VoidCallback onSaveRelays;
  final Future<void> Function(String relay) onRemoveRelay;
  final Future<void> Function() onResetRelays;
  final Future<void> Function() onReconnectRelays;
  final VoidCallback onSaveBlossomServers;
  final Future<void> Function(List<String> servers) onPublishBlossomServers;
  final VoidCallback onUpdatePin;
  final Future<void> Function() onProvisionSafetyHq;
  final Future<void> Function() onResetApp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activeThemeProvider).palette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings & Safety',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Adjust the parent profile, connection health, media servers, and safety controls from one calmer workspace.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parent Profile',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the name other families will see when you connect or share.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  hintText: 'Lee and Emma',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonal(
                    onPressed: onSaveDisplayName,
                    child: const Text('Save locally'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await onPublishDisplayName();
                    },
                    child: const Text('Publish profile'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Approvals & Scanning',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Decide how much parent review happens before a clip can leave the device.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: approvalRequired,
                contentPadding: EdgeInsets.zero,
                title: const Text('Require parent approval before sharing'),
                subtitle: const Text(
                  'Clips are always scanned on-device. Turn this on if you also want every new clip to wait for a parent.',
                ),
                onChanged: onToggleApprovalRequired,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, _) {
            final queuedActions =
                ref.watch(offlineActionsProvider).valueOrNull ?? const [];
            return FrostCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connection Health',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    queuedActions.isEmpty
                        ? 'Sharing and reporting are connected right now.'
                        : 'Some actions are waiting for a relay connection before they can finish.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                  const SizedBox(height: 12),
                  _InlineStatus(
                    icon: queuedActions.isEmpty
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: queuedActions.isEmpty
                        ? palette.success
                        : palette.warning,
                    title: queuedActions.isEmpty
                        ? 'Everything has synced'
                        : '${queuedActions.length} queued action(s)',
                    detail: queuedActions.isEmpty
                        ? 'No retries needed.'
                        : 'Retry when you want to push waiting work back through.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: queuedActions.isEmpty
                        ? null
                        : () async {
                            await onRetryOfflineQueue();
                          },
                    child: const Text('Retry now'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<String>>(
          future: ref.read(nostrServiceProvider).loadRelayList(),
          builder: (context, snapshot) {
            final relays = snapshot.data ?? const [];
            return FrostCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Relay Access',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'These relay addresses carry invites, reports, and family updates.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                  const SizedBox(height: 12),
                  for (final relay in relays)
                    _ServerRow(
                      icon: Icons.circle,
                      color: palette.success,
                      value: relay,
                      onRemove: () async {
                        await onRemoveRelay(relay);
                        onRefresh();
                      },
                    ),
                  if (relays.isEmpty)
                    Text(
                      'No custom relays saved yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: relayController,
                    decoration: const InputDecoration(
                      labelText: 'Add relay URL',
                      hintText: 'wss://relay.example.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.tonal(
                        onPressed: () {
                          onSaveRelays();
                          onRefresh();
                        },
                        child: const Text('Save relays'),
                      ),
                      FilledButton.tonal(
                        onPressed: () async {
                          await onReconnectRelays();
                          onRefresh();
                        },
                        child: const Text('Reconnect'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          await onResetRelays();
                          onRefresh();
                        },
                        child: const Text('Use defaults'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<String>>(
          future: ref.read(nostrServiceProvider).loadBlossomServerList(),
          builder: (context, snapshot) {
            final servers = snapshot.data ?? AppConstants.defaultBlossomServers;
            final identity = ref.watch(parentIdentityProvider).valueOrNull;
            return FrostCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Media Servers',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose where encrypted media uploads can live for family delivery.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                  const SizedBox(height: 12),
                  for (final server in servers)
                    _ServerRow(
                      icon: Icons.cloud_done_rounded,
                      color: palette.accent,
                      value: server,
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: blossomController,
                    decoration: const InputDecoration(
                      labelText: 'Add Blossom server',
                      hintText: 'https://blossom.example',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.tonal(
                        onPressed: () {
                          onSaveBlossomServers();
                          onRefresh();
                        },
                        child: const Text('Save servers'),
                      ),
                      FilledButton(
                        onPressed: identity == null
                            ? null
                            : () async {
                                await onPublishBlossomServers(servers);
                              },
                        child: const Text('Publish server list'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, _) {
            final safetyStatus = ref.watch(safetyHqStatusProvider);
            return FrostCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety HQ',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This is the app-managed moderation inbox for higher-risk reports.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                  const SizedBox(height: 12),
                  safetyStatus.when(
                    data: (status) => _SafetyStatusBody(status: status),
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (error, _) => Text(
                      'Safety HQ needs another moment to connect.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () async {
                      await onProvisionSafetyHq();
                      onRefresh();
                    },
                    child: const Text('Provision Safety HQ'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parent PIN',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Update the four-digit code that protects the parent workspace.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinManagementController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'New 4-digit PIN',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onUpdatePin,
                child: const Text('Update PIN'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset This Device',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Sign out and wipe this device\'s local Nook data, including cached media, queued actions, and the parent PIN.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: 12),
              _InlineStatus(
                icon: Icons.warning_amber_rounded,
                color: palette.danger,
                title: 'This cannot be undone on this device',
                detail:
                    'Make sure your parent recovery key is saved somewhere safe before you continue.',
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  foregroundColor: palette.danger,
                  backgroundColor: palette.danger.withValues(alpha: 0.10),
                ),
                onPressed: () async {
                  await onResetApp();
                },
                child: const Text('Sign out & reset app'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostCard(
          child: Text(
            'MyTube v2 · Flutter',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
          ),
        ),
      ],
    );
  }
}

class _SafetyStatusBody extends StatelessWidget {
  const _SafetyStatusBody({required this.status});

  final SafetyHqStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InlineStatus(
          icon: status.isJoined ? Icons.shield_rounded : Icons.shield_outlined,
          color: status.isJoined ? Colors.green : Colors.orange,
          title: 'Status: ${status.label}',
          detail: status.lastSyncAt == null
              ? 'No recent update yet.'
              : 'Last updated ${status.lastSyncAt!.toLocal()}',
        ),
        if (status.groupId != null && status.groupId!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Group ID',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(status.groupId!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({
    required this.icon,
    required this.color,
    required this.value,
    this.onRemove,
  });

  final IconData icon;
  final Color color;
  final String value;
  final Future<void> Function()? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () async {
                await onRemove!();
              },
            ),
        ],
      ),
    );
  }
}
