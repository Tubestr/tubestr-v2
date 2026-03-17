import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../domain/models/content_scan_summary.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';

class ParentZoneFamilySection extends ConsumerWidget {
  const ParentZoneFamilySection({
    super.key,
    required this.nameController,
    required this.childTheme,
    required this.onThemeSelected,
    required this.onSaveChild,
    required this.onDeleteChild,
    required this.onApproveVideo,
    required this.onRejectVideo,
  });

  final TextEditingController nameController;
  final ThemeDescriptor childTheme;
  final ValueChanged<ThemeDescriptor> onThemeSelected;
  final VoidCallback onSaveChild;
  final ValueChanged<String> onDeleteChild;
  final ValueChanged<String> onApproveVideo;
  final ValueChanged<String> onRejectVideo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(parentIdentityProvider).valueOrNull;
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
    final pendingVideos =
        ref.watch(pendingApprovalVideosProvider).valueOrNull ?? const [];
    final palette = ref.watch(activeThemeProvider).palette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parent Identity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(
                identity?.npub ?? 'No parent identity',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
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
                'Pending Approvals',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (pendingVideos.isEmpty)
                Text(
                  'New videos are scanned automatically. Anything that needs review will show up here.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                for (final video in pendingVideos.take(8))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Builder(
                      builder: (context) {
                        final scan = _parseScan(video.scanResults);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              scan?.summary ?? 'Waiting on scan results',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (scan != null) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _ScanChip(
                                    label: scan.riskLevel.toUpperCase(),
                                    color: _riskColor(
                                      palette: palette,
                                      riskLevel: scan.riskLevel,
                                    ),
                                  ),
                                  for (final flag in scan.flags.take(3))
                                    _ScanChip(
                                      label: _flagLabel(flag),
                                      color: palette.panelBorder,
                                      outlined: true,
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.tonal(
                                  onPressed: identity == null
                                      ? null
                                      : () => onApproveVideo(video.id),
                                  child: const Text('Approve'),
                                ),
                                OutlinedButton(
                                  onPressed: identity == null
                                      ? null
                                      : () => onRejectVideo(video.id),
                                  child: const Text('Reject'),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Children', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final profile in profiles)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ThemeDescriptorX.fromStorage(
                        profile.theme,
                      ).palette.accent,
                    ),
                  ),
                  title: Text(profile.name),
                  subtitle: Text(
                    ThemeDescriptorX.fromStorage(profile.theme).label,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => onDeleteChild(profile.id),
                  ),
                ),
              const Divider(),
              const SizedBox(height: 8),
              Text('Add Child', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Child name'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final descriptor in ThemeDescriptor.values)
                    ChoiceChip(
                      label: Text(descriptor.label),
                      selected: descriptor == childTheme,
                      onSelected: (_) => onThemeSelected(descriptor),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onSaveChild,
                child: const Text('Save child'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ContentScanSummary? _parseScan(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return ContentScanSummary.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Color _riskColor({required KidPalette palette, required String riskLevel}) {
    return switch (riskLevel) {
      'high' => palette.danger,
      'medium' => palette.warning,
      _ => palette.success,
    };
  }

  String _flagLabel(String flag) {
    return switch (flag) {
      'high_risk_label' => 'Unsafe topic',
      'review_label' => 'Needs a look',
      'very_loud_audio' => 'Very loud',
      'crowded_frame' => 'Lots of faces',
      'long_clip' => 'Long clip',
      'attention_seeking_title' => 'Intense title',
      _ => flag.replaceAll('_', ' '),
    };
  }
}

class _ScanChip extends StatelessWidget {
  const _ScanChip({
    required this.label,
    required this.color,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
