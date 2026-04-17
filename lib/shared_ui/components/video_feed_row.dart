import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/theme_descriptor.dart';
import 'feed_metric_pill.dart';
import 'media_thumbnail_frame.dart';

/// Horizontal scrollable row of local video tiles.
///
/// Used by both the home feed ("My Videos") and the editor hub.
class LocalVideoFeedRow extends StatelessWidget {
  const LocalVideoFeedRow({
    super.key,
    required this.items,
    required this.palette,
    required this.onTap,
    this.showReactions = false,
  });

  final List<LocalVideo> items;
  final KidPalette palette;
  final void Function(LocalVideo video) onTap;

  /// When true, each tile surfaces aggregate like counts and top emoji
  /// reactions received from family members.
  final bool showReactions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: showReactions ? 226 : 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, i) => LocalVideoTile(
          video: items[i],
          palette: palette,
          onTap: () => onTap(items[i]),
          showReactions: showReactions,
        ),
      ),
    );
  }
}

/// Single tile inside [LocalVideoFeedRow].
class LocalVideoTile extends ConsumerWidget {
  const LocalVideoTile({
    super.key,
    required this.video,
    required this.palette,
    required this.onTap,
    this.showReactions = false,
  });

  final LocalVideo video;
  final KidPalette palette;
  final VoidCallback onTap;
  final bool showReactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbFile = video.thumbPath.isEmpty ? null : File(video.thumbPath);
    final hasThumb = thumbFile?.existsSync() == true;
    final isPending = video.approvalStatus != 'approved';

    final likeCount = showReactions
        ? (ref.watch(videoLikeCountProvider(video.id)).valueOrNull ?? 0)
        : 0;
    final reactions = showReactions
        ? ref.watch(videoReactionSummariesProvider(video.id))
        : const [];

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 148,
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
                                  palette.accentSecondary.withValues(
                                    alpha: 0.16,
                                  ),
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
                  if (video.liked)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF6B7A,
                          ).withValues(alpha: 0.92),
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
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (showReactions && (likeCount > 0 || reactions.isNotEmpty)) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (likeCount > 0)
                    FeedMetricPill(
                      palette: palette,
                      label: '$likeCount',
                      icon: Icons.favorite_rounded,
                      iconColor: const Color(0xFFFF6B7A),
                    ),
                  for (final reaction in reactions.take(2))
                    FeedMetricPill(
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
