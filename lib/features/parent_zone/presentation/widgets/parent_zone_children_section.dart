import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../domain/models/content_scan_summary.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';

class ParentZoneChildrenSection extends ConsumerWidget {
  const ParentZoneChildrenSection({
    super.key,
    required this.nameController,
    required this.childTheme,
    required this.approvalRequired,
    required this.onThemeSelected,
    required this.onSaveChild,
    required this.onDeleteChild,
    required this.onApproveVideo,
    required this.onRejectVideo,
    required this.onToggleApprovalRequired,
  });

  final TextEditingController nameController;
  final ThemeDescriptor childTheme;
  final bool approvalRequired;
  final ValueChanged<ThemeDescriptor> onThemeSelected;
  final VoidCallback onSaveChild;
  final ValueChanged<String> onDeleteChild;
  final ValueChanged<String> onApproveVideo;
  final ValueChanged<String> onRejectVideo;
  final ValueChanged<bool> onToggleApprovalRequired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(parentIdentityProvider).valueOrNull;
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
    final pendingVideos =
        ref.watch(pendingApprovalVideosProvider).valueOrNull ?? const [];
    final palette = ref.watch(activePaletteProvider);

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
                'Approval Queue',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                pendingVideos.isEmpty
                    ? 'No clips are waiting for a parent review right now.'
                    : 'Review new clips before they can be shared outside the device.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: 14),
              if (pendingVideos.isEmpty)
                _EmptyPanel(
                  icon: Icons.verified_rounded,
                  title: 'Queue is clear',
                  detail:
                      'New videos are scanned automatically. Anything that needs your approval will appear here.',
                  color: palette.success,
                  palette: palette,
                )
              else
                for (final video in pendingVideos.take(8))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Builder(
                      builder: (context) {
                        final scan = _parseScan(video.scanResults);
                        return _ApprovalCard(
                          title: video.title,
                          summary: scan?.summary ?? 'Waiting on scan results',
                          riskLevel: scan?.riskLevel,
                          flags: scan?.flags ?? const [],
                          palette: palette,
                          onApprove: identity == null
                              ? null
                              : () => onApproveVideo(video.id),
                          onReject: identity == null
                              ? null
                              : () => onRejectVideo(video.id),
                          flagLabel: _flagLabel,
                          riskColor: (riskLevel) => _riskColor(
                            palette: palette,
                            riskLevel: riskLevel,
                          ),
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
              const SizedBox(height: 4),
              Text(
                'Each child keeps a theme and local profile for capture, editing, and playback.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: 14),
              if (profiles.isEmpty)
                _EmptyPanel(
                  icon: Icons.people_outline_rounded,
                  title: 'No child profiles yet',
                  detail:
                      'Add a child profile below so the app has someone to capture and edit for.',
                  color: palette.warning,
                  palette: palette,
                )
              else
                for (final profile in profiles)
                  _ChildRow(
                    name: profile.name,
                    themeLabel: ThemeDescriptorX.fromStorage(
                      profile.theme,
                    ).label,
                    color: ThemeDescriptorX.fromStorage(
                      profile.theme,
                    ).paletteFor(Theme.of(context).brightness).accent,
                    onDelete: () => onDeleteChild(profile.id),
                  ),
              const Divider(height: 28),
              Text(
                'Add Child Profile',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a name and theme so capture and editing stay personalized.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Child name'),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final descriptor in ThemeDescriptor.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(descriptor.label),
                          selected: descriptor == childTheme,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            onThemeSelected(descriptor);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onSaveChild,
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Save child'),
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
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  onToggleApprovalRequired(value);
                },
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

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.title,
    required this.summary,
    required this.riskLevel,
    required this.flags,
    required this.palette,
    required this.onApprove,
    required this.onReject,
    required this.flagLabel,
    required this.riskColor,
  });

  final String title;
  final String summary;
  final String? riskLevel;
  final List<String> flags;
  final KidPalette palette;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final String Function(String) flagLabel;
  final Color Function(String) riskColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panel.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(summary, style: Theme.of(context).textTheme.bodySmall),
          if (riskLevel != null || flags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (riskLevel != null)
                  _ScanChip(
                    label: riskLevel!.toUpperCase(),
                    color: riskColor(riskLevel!),
                  ),
                for (final flag in flags.take(3))
                  _ScanChip(
                    label: flagLabel(flag),
                    color: palette.panelBorder,
                    outlined: true,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonal(
                onPressed: onApprove,
                child: const Text('Approve'),
              ),
              OutlinedButton(onPressed: onReject, child: const Text('Reject')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.name,
    required this.themeLabel,
    required this.color,
    required this.onDelete,
  });

  final String name;
  final String themeLabel;
  final Color color;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(themeLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    required this.palette,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panel.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
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
      ),
    );
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
