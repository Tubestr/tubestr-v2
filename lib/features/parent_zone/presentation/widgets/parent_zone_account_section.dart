import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/radii.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../../../../shared_ui/components/private_key_export_card.dart';
import '../../../../l10n/l10n.dart';

class ParentZoneAccountSection extends ConsumerWidget {
  const ParentZoneAccountSection({
    super.key,
    required this.displayNameController,
    required this.pinManagementController,
    required this.onSaveDisplayName,
    required this.onPublishDisplayName,
    required this.onUpdatePin,
    required this.onOpenSupport,
    required this.onOpenPrivacyPolicy,
    required this.onOpenTerms,
    required this.onResetApp,
    required this.onDeleteAccount,
    required this.isDeletingAccount,
  });

  final TextEditingController displayNameController;
  final TextEditingController pinManagementController;
  final VoidCallback onSaveDisplayName;
  final Future<void> Function() onPublishDisplayName;
  final VoidCallback onUpdatePin;
  final Future<void> Function() onOpenSupport;
  final Future<void> Function() onOpenPrivacyPolicy;
  final Future<void> Function() onOpenTerms;
  final Future<void> Function() onResetApp;
  final Future<void> Function() onDeleteAccount;
  final bool isDeletingAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(parentIdentityProvider).valueOrNull;
    final palette = ref.watch(activePaletteProvider);

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
                context.l10n.parentProfilePinCardTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.parentDisplayNameDetail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: displayNameController,
                decoration: InputDecoration(
                  labelText: context.l10n.parentDisplayNameLabel,
                  hintText: context.l10n.parentDisplayNameHint,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  FilledButton.tonal(
                    onPressed: onSaveDisplayName,
                    child: Text(context.l10n.parentSaveLocally),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await onPublishDisplayName();
                    },
                    child: Text(context.l10n.parentPublishProfile),
                  ),
                ],
              ),
              const Divider(height: 28),
              Text(
                context.l10n.parentPinTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.parentUpdatePinDetail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: pinManagementController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: context.l10n.parentNewPinLabel,
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: onUpdatePin,
                child: Text(context.l10n.parentUpdatePin),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentDeleteAccountCardTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.parentDeleteAccountCardDetail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: AppSpacing.md),
              _InlineInfo(
                icon: Icons.delete_forever_rounded,
                color: palette.danger,
                title: context.l10n.parentPermanentServerDeletion,
                detail: context.l10n.parentDeleteAccountDetail,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  foregroundColor: palette.danger,
                  backgroundColor: palette.danger.withValues(alpha: 0.10),
                ),
                onPressed: isDeletingAccount
                    ? null
                    : () async {
                        await onDeleteAccount();
                      },
                child: Text(
                  isDeletingAccount
                      ? context.l10n.parentDeletingAccount
                      : context.l10n.parentDeleteAccount,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentIdentityBackupTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.parentIdentityBackupDetail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InlineInfo(
                icon: identity == null
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: identity == null ? palette.warning : palette.success,
                title: identity == null
                    ? context.l10n.parentIdentityMissing
                    : context.l10n.parentIdentityReady,
                detail: identity == null
                    ? context.l10n.parentAccountNoIdentity
                    : context.l10n.parentPublicAddressReady,
              ),
              if (identity != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: palette.surfaceDefault,
                    borderRadius: AppRadii.lgAll,
                    border: Border.all(color: palette.panelBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.parentAddressLabel,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SelectableText(
                        identity.npub,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrivateKeyExportCard(
                  secret: identity.nsec,
                  title: context.l10n.parentRecoveryKey,
                  description: context.l10n.parentBackupKeyDescription,
                  warningText: context.l10n.privateKeyBackupWarning,
                  shareText: context.l10n.onboardingBackupShareText(
                    identity.nsec,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentPoliciesSupportTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.parentPoliciesSupportDetail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await onOpenSupport();
                    },
                    icon: const Icon(Icons.support_agent_rounded),
                    label: Text(context.l10n.parentSupport),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await onOpenPrivacyPolicy();
                    },
                    icon: const Icon(Icons.privacy_tip_outlined),
                    label: Text(context.l10n.parentPrivacyPolicy),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await onOpenTerms();
                    },
                    icon: const Icon(Icons.gavel_rounded),
                    label: Text(context.l10n.parentTerms),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentResetDeviceTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.parentResetDeviceDetail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: AppSpacing.md),
              _InlineInfo(
                icon: Icons.warning_amber_rounded,
                color: palette.danger,
                title: context.l10n.parentCannotUndoDevice,
                detail: context.l10n.parentResetDeviceWarning,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  foregroundColor: palette.danger,
                  backgroundColor: palette.danger.withValues(alpha: 0.10),
                ),
                onPressed: () async {
                  await onResetApp();
                },
                child: Text(context.l10n.parentSignOutReset),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({
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
