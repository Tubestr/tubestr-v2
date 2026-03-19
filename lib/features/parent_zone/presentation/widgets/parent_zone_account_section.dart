import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../../../../shared_ui/components/private_key_export_card.dart';

class ParentZoneAccountSection extends ConsumerWidget {
  const ParentZoneAccountSection({
    super.key,
    required this.displayNameController,
    required this.pinManagementController,
    required this.onSaveDisplayName,
    required this.onPublishDisplayName,
    required this.onUpdatePin,
    required this.onResetApp,
  });

  final TextEditingController displayNameController;
  final TextEditingController pinManagementController;
  final VoidCallback onSaveDisplayName;
  final Future<void> Function() onPublishDisplayName;
  final VoidCallback onUpdatePin;
  final Future<void> Function() onResetApp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(parentIdentityProvider).valueOrNull;
    final palette = ref.watch(activeThemeProvider).palette;

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
                'Parent Profile & PIN',
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
              const Divider(height: 28),
              Text(
                'Parent PIN',
                style: Theme.of(context).textTheme.titleSmall,
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
                'Identity & Backup',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Keep your recovery details somewhere private so you can restore parent access if you switch devices.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: 14),
              _InlineInfo(
                icon: identity == null
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: identity == null ? palette.warning : palette.success,
                title: identity == null
                    ? 'Parent identity missing'
                    : 'Parent account is ready',
                detail: identity == null
                    ? 'Create or restore the parent account before using family tools.'
                    : 'Your public parent address is ready for invites and sharing.',
              ),
              if (identity != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parent address',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        identity.npub,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PrivateKeyExportCard(
                  secret: identity.nsec,
                  title: 'Recovery key',
                  description:
                      'This is the backup key for your parent account. Keep it somewhere private and easy for you to find later.',
                  warningText:
                      'Keep this private. Anyone with this key can control your family account.',
                  shareText:
                      'Nook Parent Backup Key\n\nKeep this private. Anyone with this key can control your family account.\n\n${identity.nsec}',
                ),
              ],
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
              _InlineInfo(
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
