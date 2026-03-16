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
    required this.relayController,
    required this.blossomController,
    required this.pinManagementController,
    required this.onRefresh,
    required this.onSaveRelays,
    required this.onSaveBlossomServers,
    required this.onPublishBlossomServers,
    required this.onUpdatePin,
    required this.onProvisionSafetyHq,
  });

  final TextEditingController relayController;
  final TextEditingController blossomController;
  final TextEditingController pinManagementController;
  final VoidCallback onRefresh;
  final VoidCallback onSaveRelays;
  final VoidCallback onSaveBlossomServers;
  final Future<void> Function(List<String> servers) onPublishBlossomServers;
  final VoidCallback onUpdatePin;
  final Future<void> Function() onProvisionSafetyHq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activeThemeProvider).palette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        FutureBuilder<List<String>>(
          future: ref.read(nostrServiceProvider).loadRelayList(),
          builder: (context, snapshot) {
            final relays = snapshot.data ?? const [];
            return FrostCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Relays',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final relay in relays)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: palette.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              relay,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: relayController,
                    decoration: const InputDecoration(
                      labelText: 'Add relay URL',
                      hintText: 'wss://relay.example.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () {
                      onSaveRelays();
                      onRefresh();
                    },
                    child: const Text('Save relays'),
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
                    'Blossom Servers',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final server in servers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_done_rounded,
                            size: 16,
                            color: palette.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              server,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        child: const Text('Publish kind:10063'),
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
                  const SizedBox(height: 12),
                  safetyStatus.when(
                    data: (status) => _SafetyStatusBody(status: status),
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (error, _) => Text(
                      '$error',
                      style: Theme.of(context).textTheme.bodySmall,
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
    final lines = <String>[
      'Status: ${status.label}',
      if (status.groupId != null && status.groupId!.isNotEmpty)
        'Group: ${status.groupId!}',
      if (status.lastSyncAt != null)
        'Updated: ${status.lastSyncAt!.toLocal()}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(line, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}
