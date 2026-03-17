import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../shared_ui/components/kid_scaffold.dart';
import '../../../shared_ui/components/media_thumbnail_frame.dart';
import '../../../shared_ui/components/profile_switcher.dart';
import '../../editor/presentation/editor_detail_page.dart';

/// Editor tab content — gallery of videos available for editing.
class EditorHubContent extends ConsumerWidget {
  const EditorHubContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activeThemeProvider).palette;
    final videos = ref.watch(videosForSelectedProfileProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              children: [const Spacer(), const ProfileSwitcherButton()],
            ),
          ),

          Expanded(
            child: videos.when(
              data: (items) => _Body(items: items, palette: palette),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.items, required this.palette});

  final List<LocalVideo> items;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // Header card
        FrostCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: palette.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Studio',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: palette.accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a video to remix and edit',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (items.isEmpty)
          _EmptyState(palette: palette)
        else
          _VideoGrid(items: items, palette: palette),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette});

  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return FrostCard(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.08),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.12),
                    width: 2,
                  ),
                ),
              ),
              Icon(
                Icons.video_camera_back_rounded,
                size: 32,
                color: palette.accent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'No videos to edit yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: palette.mutedInk),
          ),
          const SizedBox(height: 4),
          Text(
            'Record something on the Capture tab first',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _VideoGrid extends StatelessWidget {
  const _VideoGrid({required this.items, required this.palette});

  final List<LocalVideo> items;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final video = items[i];
        return _EditorVideoCard(video: video, palette: palette);
      },
    );
  }
}

class _EditorVideoCard extends StatelessWidget {
  const _EditorVideoCard({required this.video, required this.palette});

  final LocalVideo video;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    final thumbFile = video.thumbPath.isEmpty ? null : File(video.thumbPath);
    final hasThumb = thumbFile?.existsSync() == true;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EditorDetailPage(video: video)),
        );
      },
      child: FrostCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: hasThumb
                          ? MediaThumbnailFrame(
                              file: thumbFile!,
                              borderRadius: BorderRadius.circular(16),
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
                                    palette.accent.withValues(alpha: 0.2),
                                    palette.accentSecondary.withValues(
                                      alpha: 0.2,
                                    ),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 40,
                                color: palette.accent,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              video.tags.join(' \u00b7 '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
            ),
          ],
        ),
      ),
    );
  }
}
