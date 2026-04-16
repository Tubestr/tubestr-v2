import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../../../../services/safety/safety_hq_service.dart';

class ParentZoneNetworkSection extends ConsumerWidget {
  const ParentZoneNetworkSection({
    super.key,
    required this.relayController,
    required this.blossomController,
    required this.onRefresh,
    required this.onRetryOfflineQueue,
    required this.onSaveRelays,
    required this.onRemoveRelay,
    required this.onResetRelays,
    required this.onReconnectRelays,
    required this.onSaveBlossomServers,
    required this.onPublishBlossomServers,
    required this.onProvisionSafetyHq,
  });

  final TextEditingController relayController;
  final TextEditingController blossomController;
  final VoidCallback onRefresh;
  final Future<void> Function() onRetryOfflineQueue;
  final VoidCallback onSaveRelays;
  final Future<void> Function(String relay) onRemoveRelay;
  final Future<void> Function() onResetRelays;
  final Future<void> Function() onReconnectRelays;
  final VoidCallback onSaveBlossomServers;
  final Future<void> Function(List<String> servers) onPublishBlossomServers;
  final Future<void> Function() onProvisionSafetyHq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < 600 ? 12.0 : 20.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 100),
      children: [
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
                    'Keep higher-risk reports separate from the main family thread and deliver them to Tubestr moderation once Safety HQ is connected.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                  const SizedBox(height: 12),
                  safetyStatus.when(
                    data: (status) => _SafetyStatusBody(status: status),
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (error, _) => Text(
                      'Safety HQ needs another moment to refresh.',
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
                    child: Text(
                      safetyStatus.valueOrNull?.isJoined == true
                          ? 'Refresh Safety HQ'
                          : safetyStatus.valueOrNull?.isProvisioning == true
                          ? 'Check Safety HQ'
                          : 'Set Up Safety HQ',
                    ),
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
                'How Safety Reporting Works',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Parents can verify what stays private, what reaches the other family, and where media abuse reports are sent.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: 12),
              const _ReportingExplainerRow(
                icon: Icons.phone_android_rounded,
                title: 'Level 1 stays here',
                detail:
                    'Gentle feedback stays on this device so a child can talk with a grown-up later.',
              ),
              const SizedBox(height: 10),
              const _ReportingExplainerRow(
                icon: Icons.family_restroom_rounded,
                title: 'Level 2 alerts the parent on this device',
                detail:
                    'Stronger concerns stay private to this family and show up in Parent Zone only.',
              ),
              const SizedBox(height: 10),
              const _ReportingExplainerRow(
                icon: Icons.groups_rounded,
                title: 'Level 3 alerts both families',
                detail:
                    'The family group gets the report first. Safety HQ keeps a separate copy when it has been set up.',
              ),
              const SizedBox(height: 10),
              const _ReportingExplainerRow(
                icon: Icons.cloud_upload_rounded,
                title: 'BUD-09 abuse signals are best effort',
                detail:
                    'If a parent deletes a shared video, Tubestr also asks the media servers to flag that blob, but the in-app moderation state remains the source of truth.',
              ),
            ],
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
          icon: status.isJoined
              ? Icons.verified_user_rounded
              : status.isProvisioning
              ? Icons.sync_rounded
              : Icons.shield_outlined,
          color: status.isJoined ? Colors.green : Colors.orange,
          title: 'Status: ${status.label}',
          detail: status.lastSyncAt == null
              ? status.detail
              : '${status.detail} Last updated ${status.lastSyncAt!.toLocal()}',
        ),
        if (status.groupId != null && status.groupId!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Local group ID',
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

class _ReportingExplainerRow extends StatelessWidget {
  const _ReportingExplainerRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
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
