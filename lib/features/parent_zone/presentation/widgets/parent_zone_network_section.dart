import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../../../../services/safety/safety_hq_service.dart';
import '../../../../l10n/l10n.dart';

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
    required this.onRemoveBlossomServer,
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
  final Future<void> Function(String server) onRemoveBlossomServer;
  final Future<void> Function() onProvisionSafetyHq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < 600 ? AppSpacing.md : AppSpacing.xl;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppSpacing.md,
        hPad,
        AppSpacing.bottomSafe,
      ),
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
                    context.l10n.parentConnectionHealth,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    queuedActions.isEmpty
                        ? context.l10n.parentConnectionHealthy
                        : context.l10n.parentConnectionWaiting,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InlineStatus(
                    icon: queuedActions.isEmpty
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: queuedActions.isEmpty
                        ? palette.success
                        : palette.warning,
                    title: queuedActions.isEmpty
                        ? context.l10n.parentEverythingSynced
                        : context.l10n.parentQueuedActions(
                            queuedActions.length,
                          ),
                    detail: queuedActions.isEmpty
                        ? context.l10n.parentNoRetriesNeeded
                        : context.l10n.parentRetryWaitingDetail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonal(
                    onPressed: queuedActions.isEmpty
                        ? null
                        : () async {
                            await onRetryOfflineQueue();
                          },
                    child: Text(context.l10n.actionRetryNow),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Consumer(
          builder: (context, ref, _) {
            final relayListAsync = ref.watch(relayListProvider);
            final relayList = relayListAsync.valueOrNull;
            final urls = relayList?.urls ?? const <String>[];
            return FrostCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.parentRelayAccess,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.parentRelayAccessDetail,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final relay in urls)
                    _ServerRow(
                      icon: Icons.circle,
                      color: palette.success,
                      value: relay,
                      onRemove: () async {
                        await onRemoveRelay(relay);
                        onRefresh();
                      },
                    ),
                  if (urls.isEmpty)
                    Text(
                      context.l10n.parentNoCustomRelays,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: relayController,
                    decoration: InputDecoration(
                      labelText: context.l10n.parentRelayInputLabel,
                      hintText: 'wss://relay.example.com',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      FilledButton.tonal(
                        onPressed: () {
                          onSaveRelays();
                          onRefresh();
                        },
                        child: Text(context.l10n.parentRelaySave),
                      ),
                      FilledButton.tonal(
                        onPressed: () async {
                          await onReconnectRelays();
                          onRefresh();
                        },
                        child: Text(context.l10n.parentReconnect),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          await onResetRelays();
                          onRefresh();
                        },
                        child: Text(context.l10n.parentUseDefaults),
                      ),
                    ],
                  ),
                  if (relayList?.updatedAt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.parentLastPublished(
                        _formatTimestamp(relayList!.updatedAt!, context.l10n),
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Consumer(
          builder: (context, ref, _) {
            final blossomAsync = ref.watch(blossomServerListProvider);
            final list = blossomAsync.valueOrNull;
            final servers = list?.servers.isNotEmpty == true
                ? list!.servers
                : AppConstants.defaultBlossomServers;
            return FrostCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.parentMediaServers,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.parentMediaServersDetail,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final server in servers)
                    _ServerRow(
                      icon: Icons.cloud_done_rounded,
                      color: palette.accent,
                      value: server,
                      onRemove: servers.length > 1
                          ? () async {
                              await onRemoveBlossomServer(server);
                              onRefresh();
                            }
                          : null,
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: blossomController,
                    decoration: InputDecoration(
                      labelText: context.l10n.parentBlossomInputLabel,
                      hintText: 'https://blossom.example',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      FilledButton.tonal(
                        onPressed: () {
                          onSaveBlossomServers();
                          onRefresh();
                        },
                        child: Text(context.l10n.parentServersSave),
                      ),
                    ],
                  ),
                  if (list?.updatedAt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.parentLastPublished(
                        _formatTimestamp(list!.updatedAt!, context.l10n),
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Consumer(
          builder: (context, ref, _) {
            final safetyStatus = ref.watch(safetyHqStatusProvider);
            return FrostCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.parentSafetyHq,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.parentSafetyHqDetail,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  safetyStatus.when(
                    data: (status) =>
                        _SafetyStatusBody(status: status, palette: palette),
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (error, _) => Text(
                      context.l10n.parentSafetyHqRefreshPending,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonal(
                    onPressed: () async {
                      await onProvisionSafetyHq();
                      onRefresh();
                    },
                    child: Text(
                      safetyStatus.valueOrNull?.isJoined == true
                          ? context.l10n.parentSafetyHqRefresh
                          : safetyStatus.valueOrNull?.isProvisioning == true
                          ? context.l10n.parentSafetyHqCheck
                          : context.l10n.parentSafetyHqSetup,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentHowSafetyWorks,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.parentSafetyWorksDetail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReportingExplainerRow(
                icon: Icons.phone_android_rounded,
                title: context.l10n.parentSafetyLevelOneTitle,
                detail: context.l10n.parentSafetyLevelOneDetail,
              ),
              const SizedBox(height: AppSpacing.md),
              _ReportingExplainerRow(
                icon: Icons.family_restroom_rounded,
                title: context.l10n.parentSafetyLevelTwoTitle,
                detail: context.l10n.parentSafetyLevelTwoDetail,
              ),
              const SizedBox(height: AppSpacing.md),
              _ReportingExplainerRow(
                icon: Icons.groups_rounded,
                title: context.l10n.parentSafetyLevelThreeTitle,
                detail: context.l10n.parentSafetyLevelThreeDetail,
              ),
              const SizedBox(height: AppSpacing.md),
              _ReportingExplainerRow(
                icon: Icons.cloud_upload_rounded,
                title: context.l10n.parentSafetyBud09Title,
                detail: context.l10n.parentSafetyBud09Detail,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafetyStatusBody extends StatelessWidget {
  const _SafetyStatusBody({required this.status, required this.palette});

  final SafetyHqStatus status;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final label = _safetyStatusLabel(status, l10n);
    final detail = _safetyStatusDetail(status, l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InlineStatus(
          icon: status.isJoined
              ? Icons.verified_user_rounded
              : status.isProvisioning
              ? Icons.sync_rounded
              : Icons.shield_outlined,
          color: status.isJoined ? palette.success : palette.warning,
          title: l10n.parentStatus(label),
          detail: status.lastSyncAt == null
              ? detail
              : l10n.parentStatusLastUpdated(
                  detail,
                  _formatTimestamp(status.lastSyncAt!, l10n),
                ),
        ),
        if (status.groupId != null && status.groupId!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.parentLocalGroupId,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(status.groupId!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

String _safetyStatusLabel(SafetyHqStatus status, AppLocalizations l10n) {
  if (status.isJoined) {
    return l10n.safetyHqProvisioned;
  }
  if (status.isProvisioning) {
    return l10n.safetyHqConnecting;
  }
  if (status.isQueued) {
    return l10n.safetyHqQueued;
  }
  return l10n.safetyHqNotConfigured;
}

String _safetyStatusDetail(SafetyHqStatus status, AppLocalizations l10n) {
  if (status.isJoined) {
    return l10n.safetyHqProvisionedDetail;
  }
  if (status.isProvisioning) {
    return l10n.safetyHqConnectingDetail;
  }
  if (status.isQueued) {
    return l10n.safetyHqQueuedDetail;
  }
  return l10n.safetyHqNotConfiguredDetail;
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
        Icon(icon, size: AppIconSize.md),
        const SizedBox(width: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.xs),
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
            borderRadius: AppRadii.mdAll,
          ),
          child: Icon(icon, size: AppIconSize.lg, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.xs),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatTimestamp(DateTime value, AppLocalizations l10n) {
  final now = DateTime.now();
  final diff = now.difference(value);
  if (diff.inSeconds < 60) {
    return l10n.parentJustNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.parentMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l10n.parentHoursAgo(diff.inHours);
  }
  final days = diff.inDays;
  if (days < 30) {
    return l10n.parentDaysAgo(days);
  }
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.xs, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: AppIconSize.md),
              onPressed: () async {
                await onRemove!();
              },
            ),
        ],
      ),
    );
  }
}
