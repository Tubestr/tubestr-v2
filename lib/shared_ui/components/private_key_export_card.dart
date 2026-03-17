import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/di/providers.dart';
import '../../core/theme/theme_descriptor.dart';

class PrivateKeyExportCard extends ConsumerStatefulWidget {
  const PrivateKeyExportCard({
    super.key,
    required this.secret,
    this.title = 'Private key backup',
    this.description =
        'This private key gives full control of your parent account.',
    this.warningText =
        'Keep this private. Anyone with this key can control your family account.',
    this.shareText,
  });

  final String secret;
  final String title;
  final String description;
  final String warningText;
  final String? shareText;

  @override
  ConsumerState<PrivateKeyExportCard> createState() =>
      _PrivateKeyExportCardState();
}

class _PrivateKeyExportCardState extends ConsumerState<PrivateKeyExportCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(activeThemeProvider).palette;
    final displayedSecret = _revealed
        ? widget.secret
        : _maskSecret(widget.secret);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.key_rounded, color: palette.accent, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.description,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(18),
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _revealed = !_revealed),
              icon: Icon(
                _revealed ? Icons.visibility_off_rounded : Icons.visibility,
                size: 18,
              ),
              label: Text(_revealed ? 'Hide key' : 'Reveal key'),
            ),
            FilledButton.tonalIcon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.secret));
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recovery key copied')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await SharePlus.instance.share(
                  ShareParams(text: widget.shareText ?? widget.secret),
                );
              },
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Share'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.danger.withValues(alpha: 0.2)),
          ),
          child: Text(
            widget.warningText,
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
