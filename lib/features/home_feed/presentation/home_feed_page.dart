import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../domain/models/remote_share_projection.dart';
import '../../../shared_ui/components/media_thumbnail_frame.dart';
import '../../../shared_ui/components/profile_switcher.dart';

/// Home tab content — matches v1 HomeFeedView.
class HomeFeedContent extends ConsumerWidget {
  const HomeFeedContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
    final videos = ref.watch(videosForSelectedProfileProvider);
    final remoteShares =
        ref.watch(remoteSharesProvider).valueOrNull ?? const [];
    final selectedProfileId = ref.watch(selectedProfileIdProvider);
    final selectedProfile = profiles.firstWhereOrNull(
      (p) => p.id == selectedProfileId,
    );
    final palette = ref.watch(activeThemeProvider).palette;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Toolbar — "Nook" title + ProfileSwitcher
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              children: [
                Text(
                  'Nook',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: palette.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const ProfileSwitcherButton(),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(videosForSelectedProfileProvider);
                ref.invalidate(shareRecordsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  // My Videos section — hero only shown for new users (empty state)
                  videos.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return _WelcomeEmptyState(
                          name: selectedProfile?.name ?? 'there',
                          palette: palette,
                        );
                      }
                      return _MyVideosSection(items: items, palette: palette);
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your videos need another moment',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'We couldn\'t load this child\'s library just yet. Pull down to try again.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: palette.mutedInk),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // From Friends & Family
                  if (remoteShares.isNotEmpty) ...[
                    _SharedVideosSection(items: remoteShares, palette: palette),
                    const SizedBox(height: 24),
                  ],

                  // Add Friends CTA
                  _AddFriendsCta(palette: palette),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Welcome + empty state (shown only when user has no videos)
// ---------------------------------------------------------------------------

class _WelcomeEmptyState extends ConsumerWidget {
  const _WelcomeEmptyState({required this.name, required this.palette});

  final String name;
  final KidPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      < 12 => 'Good Morning',
      < 17 => 'Good Afternoon',
      _ => 'Good Evening',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting + headline
        Text(
          '$greeting, $name',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: palette.mutedInk,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Make your first video',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start in Capture, then head to Edit Studio to add stickers, music, or text.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
        ),
        const SizedBox(height: 20),

        // Ghost video grid with embedded CTA
        _GhostVideoGrid(palette: palette),

        const SizedBox(height: 20),

        // Single primary action
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(appShellTabIndexProvider.notifier).state = 1;
            },
            icon: const Icon(Icons.videocam_rounded),
            label: const Text('Open Capture'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ghost video grid — placeholder tiles with embedded record CTA
// ---------------------------------------------------------------------------

class _GhostVideoGrid extends ConsumerWidget {
  const _GhostVideoGrid({required this.palette});

  final KidPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2-column grid, 4 tiles. Tile 1 (index 0) is the CTA; the rest are ghosts.
    const cols = 2;
    const tileCount = 4;
    const aspectRatio = 9 / 16;
    const spacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        final tileHeight = tileWidth / aspectRatio;

        final tiles = List.generate(tileCount, (i) {
          if (i == 1) {
            // CTA tile — accent-colored, tappable
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(appShellTabIndexProvider.notifier).state = 1;
              },
              child: Container(
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.40),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.videocam_rounded,
                        color: palette.accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Record your\nfirst clip',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.accent,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Ghost placeholder tile
          return Container(
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: palette.panelBorder,
                width: 1,
                style: BorderStyle.none,
              ),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: palette.panelBorder,
                width: 1,
              ),
            ),
          );
        });

        return SizedBox(
          height: tileHeight * (tileCount / cols) + spacing * ((tileCount / cols) - 1),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemCount: tileCount,
            itemBuilder: (context, i) => tiles[i],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// My Videos grid (2-column portrait)
// ---------------------------------------------------------------------------

class _MyVideosSection extends StatelessWidget {
  const _MyVideosSection({required this.items, required this.palette});

  final List<dynamic> items;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionHeader(title: 'My Videos'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 9 / 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) =>
                  _VideoTile(video: items[i], palette: palette),
            );
          },
        ),
      ],
    );
  }
}

class _VideoTile extends ConsumerWidget {
  const _VideoTile({required this.video, required this.palette});

  final dynamic video;
  final KidPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbFile = video.thumbPath.isEmpty
        ? null
        : File(video.thumbPath as String);
    final hasThumb = thumbFile?.existsSync() == true;
    final isPending = (video.approvalStatus as String) != 'approved';

    return GestureDetector(
      onTap: () => context.push('/player/${video.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: hasThumb
                        ? MediaThumbnailFrame(
                            file: thumbFile!,
                            borderRadius: BorderRadius.circular(20),
                            background: LinearGradient(
                              colors: [
                                palette.accent.withValues(alpha: 0.18),
                                palette.accentSecondary.withValues(alpha: 0.16),
                                const Color(0xFF120F18),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            padding: const EdgeInsets.all(6),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  palette.accent.withValues(alpha: 0.25),
                                  palette.accentSecondary.withValues(
                                    alpha: 0.25,
                                  ),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 36,
                              color: palette.accent,
                            ),
                          ),
                  ),
                ),
                // Pending badge
                if (isPending)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: palette.warning,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (video.liked as bool)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B7A).withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            video.title as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.play_arrow_rounded, size: 14, color: palette.mutedInk),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  video.playCount == 0
                      ? 'New clip'
                      : '${video.playCount} ${video.playCount == 1 ? 'play' : 'plays'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.mutedInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Friends CTA
// ---------------------------------------------------------------------------

class _AddFriendsCta extends ConsumerWidget {
  const _AddFriendsCta({required this.palette});

  final KidPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(appShellTabIndexProvider.notifier).state = 3;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: palette.panelBorder),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_rounded,
                color: palette.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect with Friends',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: palette.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Share videos with trusted families',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.mutedInk),
          ],
        ),
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
      (RemoteShareProjection item) => item.senderParentKey,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'From Friends & Family'),
        const SizedBox(height: 12),
        for (final entry in grouped.entries) ...[
          _SharedFamilyHeader(
            senderParentKey: entry.key,
            fallbackChildName: entry.value.first.displayName,
            palette: palette,
          ),
          SizedBox(
            height: 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entry.value.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _SharedVideoTile(
                  item: entry.value[index],
                  palette: palette,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _SharedFamilyHeader extends ConsumerWidget {
  const _SharedFamilyHeader({
    required this.senderParentKey,
    required this.fallbackChildName,
    required this.palette,
  });

  final String senderParentKey;
  final String fallbackChildName;
  final KidPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref
        .watch(resolvedParentProfileProvider(senderParentKey))
        .valueOrNull;
    final label = profile?.displayName ?? fallbackChildName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'From $label',
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
    final statusLabel = switch (item.status) {
      'available' when item.isDownloaded => 'Ready',
      'available' => 'Tap to download later',
      'downloading' => 'Downloading',
      'failed' => 'Needs retry',
      _ => item.status,
    };
    final likeCount =
        ref.watch(videoLikeCountProvider(item.videoId)).valueOrNull ?? 0;
    final reactions = ref.watch(videoReactionSummariesProvider(item.videoId));

    return SizedBox(
      width: 196,
      child: GestureDetector(
        onTap: () => context.push('/player/remote/${item.remoteShareId}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: hasThumb
                          ? MediaThumbnailFrame(
                              file: thumbnailFile!,
                              borderRadius: BorderRadius.circular(20),
                              background: const LinearGradient(
                                colors: [Color(0xFF16111D), Color(0xFF0C0A11)],
                              ),
                              padding: const EdgeInsets.all(6),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    palette.accentSecondary.withValues(
                                      alpha: 0.28,
                                    ),
                                    palette.accent.withValues(alpha: 0.20),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Icon(
                                item.isDownloaded
                                    ? Icons.play_circle_fill_rounded
                                    : Icons.cloud_download_rounded,
                                size: 42,
                                color: palette.accent,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _StatusBadge(
                      label: statusLabel,
                      color: item.isDownloaded
                          ? palette.success
                          : palette.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            _RemoteAttributionLine(item: item, palette: palette),
            if (likeCount > 0 || reactions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (likeCount > 0)
                    _FeedMetricPill(
                      palette: palette,
                      label: '$likeCount ${likeCount == 1 ? 'like' : 'likes'}',
                      icon: Icons.favorite_rounded,
                      iconColor: const Color(0xFFFF6B7A),
                    ),
                  for (final reaction in reactions.take(2))
                    _FeedMetricPill(
                      palette: palette,
                      label: '${reaction.emoji} ${reaction.count}',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RemoteAttributionLine extends ConsumerWidget {
  const _RemoteAttributionLine({required this.item, required this.palette});

  final RemoteShareProjection item;
  final KidPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref
        .watch(resolvedParentProfileProvider(item.senderParentKey))
        .valueOrNull;
    final sourceLabel = profile == null
        ? item.displayName
        : '${profile.displayName} · ${item.displayName}';
    return Text(
      item.isDownloaded ? 'Ready to watch' : 'Saved from $sourceLabel',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FeedMetricPill extends StatelessWidget {
  const _FeedMetricPill({
    required this.palette,
    required this.label,
    this.icon,
    this.iconColor,
  });

  final KidPalette palette;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: iconColor ?? palette.accent),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header helper
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
