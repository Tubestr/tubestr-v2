import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/di/providers.dart';
import '../../core/theme/radii.dart';
import '../../core/theme/spacing.dart';
import '../../l10n/l10n.dart';

class PrivateKeyExportCard extends ConsumerStatefulWidget {
  const PrivateKeyExportCard({
    super.key,
    required this.secret,
    this.title,
    this.description,
    this.warningText,
    this.shareText,
  });

  final String secret;
  final String? title;
  final String? description;
  final String? warningText;
  final String? shareText;

  @override
  ConsumerState<PrivateKeyExportCard> createState() =>
      _PrivateKeyExportCardState();
}

class _PrivateKeyExportCardState extends ConsumerState<PrivateKeyExportCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(activePaletteProvider);
    final l10n = context.l10n;
    final displayedSecret = _revealed
        ? widget.secret
        : _maskSecret(widget.secret);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: AppIconSize.hero,
              height: AppIconSize.hero,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: AppRadii.mdAll,
              ),
              child: Icon(
                Icons.key_rounded,
                color: palette.accent,
                size: AppIconSize.lg,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                widget.title ?? l10n.privateKeyBackupTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.description ?? l10n.privateKeyBackupSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: palette.surfaceDefault,
            borderRadius: AppRadii.xlAll,
            border: Border.all(color: palette.panelBorder),
          ),
          child: SelectableText(
            displayedSecret,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _revealed = !_revealed),
                icon: Icon(
                  _revealed ? Icons.visibility_off_rounded : Icons.visibility,
                  size: AppIconSize.md,
                ),
                label: Text(_revealed ? l10n.actionHide : l10n.actionReveal),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: widget.secret));
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.recoveryKeyCopied)),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: AppIconSize.md),
                label: Text(l10n.actionCopy),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await SharePlus.instance.share(
                    ShareParams(text: widget.shareText ?? widget.secret),
                  );
                },
                icon: const Icon(Icons.ios_share_rounded, size: AppIconSize.md),
                label: Text(l10n.actionShare),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: palette.danger.withValues(alpha: 0.08),
            borderRadius: AppRadii.lgAll,
            border: Border.all(color: palette.danger.withValues(alpha: 0.2)),
          ),
          child: Text(
            widget.warningText ?? l10n.privateKeyBackupWarning,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _maskSecret(String secret) {
    if (secret.length <= 16) {
      return List<String>.filled(secret.length, '•').join();
    }
    return '${secret.substring(0, 8)}••••••${secret.substring(secret.length - 8)}';
  }
}
