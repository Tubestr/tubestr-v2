import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../domain/models/remote_share_projection.dart';
import '../../../shared_ui/components/kid_scaffold.dart';
import '../../../shared_ui/components/media_thumbnail_frame.dart';
import '../../../shared_ui/components/nook_decorations.dart';
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
                  // Welcome header
                  _WelcomeHeader(
                    name: selectedProfile?.name ?? 'there',
                    palette: palette,
                  ),
                  const SizedBox(height: 24),

                  // My Videos section
                  videos.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return _EmptyState(palette: palette);
                      }
                      return _MyVideosSection(items: items, palette: palette);
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => FrostCard(child: Text('$e')),
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
// Welcome header with time-of-day greeting
// ---------------------------------------------------------------------------

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.name, required this.palette});

  final String name;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      < 12 => 'Good Morning',
      < 17 => 'Good Afternoon',
      _ => 'Good Evening',
    };

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: palette.mutedInk),
              ),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        GlowBox(
          color: palette.accent,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: palette.accent.withValues(alpha: 0.15),
            child: Icon(Icons.face_rounded, size: 28, color: palette.accent),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// My Videos grid (v1: LazyVGrid, 3 columns)
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
                childAspectRatio: 0.8,
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

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video, required this.palette});

  final dynamic video;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette});

  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return FrostCard(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.08),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.12),
                    width: 2,
                  ),
                ),
              ),
              Icon(Icons.videocam_rounded, size: 48, color: palette.accent),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your Nook awaits!',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Record your first video on the Capture tab.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
          ),
          const SizedBox(height: 12),
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
      child: FrostCard(
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

class _SharedVideoTile extends StatelessWidget {
  const _SharedVideoTile({required this.item, required this.palette});

  final RemoteShareProjection item;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    final thumbnailFile = item.hasThumbnail ? File(item.localThumbPath!) : null;
    final hasThumb = thumbnailFile?.existsSync() == true;
    final statusLabel = switch (item.status) {
      'available' when item.isDownloaded => 'Ready',
      'available' => 'Tap to download later',
      'downloading' => 'Downloading',
      'failed' => 'Needs retry',
      _ => item.status,
    };

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
                                colors: [
                                  Color(0xFF16111D),
                                  Color(0xFF0C0A11),
                                ],
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
