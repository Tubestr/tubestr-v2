import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/radii.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../domain/models/remote_share_projection.dart';
import '../../../shared_ui/components/media_thumbnail_frame.dart';
import '../../../shared_ui/components/profile_switcher.dart';
import '../../../shared_ui/components/video_feed_row.dart';
import '../../../shared_ui/motion/app_motion.dart';
import '../../editor/domain/editor_source.dart';
import '../../editor/presentation/editor_detail_page.dart';
import '../../../l10n/l10n.dart';

/// Editor tab content — gallery of videos available for editing.
class EditorHubContent extends ConsumerWidget {
  const EditorHubContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);
    final videos = ref.watch(videosForSelectedProfileProvider);
    final remoteShares =
        ref.watch(remoteSharesFromOthersProvider).valueOrNull ?? const [];

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [const Spacer(), const ProfileSwitcherButton()],
            ),
          ),

          Expanded(
            child: videos.when(
              data: (items) => _Body(
                items: items,
                remoteShares: remoteShares,
                palette: palette,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.editorHubNeedsMoment,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'We couldn\'t load your clips for editing just yet. Try switching profiles or come back in a moment.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.items,
    required this.remoteShares,
    required this.palette,
  });

  final List<LocalVideo> items;
  final List<RemoteShareProjection> remoteShares;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && remoteShares.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.bottomSafe,
        ),
        children: [
          _StudioHero(palette: palette),
          const SizedBox(height: AppSpacing.xl),
          _EmptyState(palette: palette),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.bottomSafe,
      ),
      children: [
        _HasClipsHeader(items: items, palette: palette),
        if (items.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          LocalVideoFeedRow(
            items: items,
            palette: palette,
            onTap: (video) {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                AppMotion.modalRoute(
                  context: context,
                  builder: (_) => EditorDetailPage.fromVideo(video: video),
                ),
              );
            },
          ),
        ],
        if (remoteShares.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          _SharedVideosSection(items: remoteShares, palette: palette),
        ],
      ],
    );
  }
}

/// Compact title row shown when the user has clips.
class _HasClipsHeader extends ConsumerWidget {
  const _HasClipsHeader({required this.items, required this.palette});

  final List<LocalVideo> items;
  final KidPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Text(
          context.l10n.editorHubTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: palette.accent,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            ref.read(appShellTabIndexProvider.notifier).state = 1;
          },
          icon: const Icon(Icons.videocam_rounded),
          tooltip: context.l10n.tabCapture,
        ),
      ],
    );
  }
}

/// Typography-only hero shown when the user has no clips.
class _StudioHero extends ConsumerWidget {
  const _StudioHero({required this.palette});

  final KidPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.editorHubTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: palette.accent,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.editorHubEmptyDetail,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(appShellTabIndexProvider.notifier).state = 1;
                },
                icon: const Icon(Icons.videocam_rounded),
                label: Text(context.l10n.editorHubCaptureFirst),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(context.l10n.editorHubEmptyTitle),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const Divider(),
      ],
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.palette});

  final KidPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: palette.surfacePressed,
            borderRadius: AppRadii.xlAll,
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: palette.accent,
            size: AppIconSize.display,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.editorHubNothingToRemix,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.editorHubRecordFirstDetail,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _StudioPill(
              icon: Icons.cut_rounded,
              label: context.l10n.editorToolTrim,
              palette: palette,
            ),
            _StudioPill(
              icon: Icons.music_note_rounded,
              label: context.l10n.editorHubMusic,
              palette: palette,
            ),
            _StudioPill(
              icon: Icons.emoji_emotions_outlined,
              label: context.l10n.editorToolStickers,
              palette: palette,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: () =>
              ref.read(appShellTabIndexProvider.notifier).state = 1,
          icon: const Icon(Icons.videocam_rounded),
          label: Text(context.l10n.homeOpenCapture),
        ),
      ],
    );
  }
}

class _StudioPill extends StatelessWidget {
  const _StudioPill({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceDefault,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: palette.panelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.sm, color: palette.accent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SharedVideosSection extends StatelessWidget {
  const _SharedVideosSection({required this.items, required this.palette});

  final List<RemoteShareProjection> items;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    final grouped = groupBy(
      items,
      (RemoteShareProjection item) => item.mlsGroupId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.homeFromFriendsFamily,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final entry in grouped.entries) ...[
          _SharedGroupHeader(
            mlsGroupId: entry.key,
            fallbackChildName: entry.value.first.displayName,
            palette: palette,
          ),
          SizedBox(
            height: 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entry.value.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = entry.value[index];
                return _SharedVideoTile(item: item, palette: palette);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

class _SharedGroupHeader extends ConsumerWidget {
  const _SharedGroupHeader({
    required this.mlsGroupId,
    required this.fallbackChildName,
    required this.palette,
  });

  final String mlsGroupId;
  final String fallbackChildName;
  final KidPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupSummary = ref
        .watch(mdkGroupSummaryProvider(mlsGroupId))
        .valueOrNull;
    final label = groupSummary?.name ?? fallbackChildName;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        context.l10n.editorHubFromLabel(label),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: palette.mutedInk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SharedVideoTile extends ConsumerWidget {
  const _SharedVideoTile({required this.item, required this.palette});

  final RemoteShareProjection item;
  final KidPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailFile = item.hasThumbnail ? File(item.localThumbPath!) : null;
    final hasThumb = thumbnailFile?.existsSync() == true;
    final selectedProfileId = ref.watch(selectedProfileIdProvider);

    return SizedBox(
      width: 140,
      child: GestureDetector(
        onTap: () {
          if (item.isDownloaded && selectedProfileId != null) {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              AppMotion.modalRoute(
                context: context,
                builder: (_) => EditorDetailPage(
                  source: EditorSource.fromRemoteShare(
                    item,
                    profileId: selectedProfileId,
                  ),
                ),
              ),
            );
          } else {
            context.push('/player/remote/${item.remoteShareId}');
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 128,
              child: ClipRRect(
                borderRadius: AppRadii.xlAll,
                child: hasThumb
                    ? MediaThumbnailFrame(
                        file: thumbnailFile!,
                        borderRadius: AppRadii.xlAll,
                        background: LinearGradient(
                          colors: [
                            palette.mediaSurfaceStrong,
                            palette.mediaScrim,
                          ],
                        ),
                        padding: const EdgeInsets.all(AppSpacing.xs),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              palette.accentSecondaryMedium,
                              palette.accentMuted,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          item.isDownloaded
                              ? Icons.play_circle_fill_rounded
                              : Icons.cloud_download_rounded,
                          size: AppIconSize.empty,
                          color: palette.accent,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
