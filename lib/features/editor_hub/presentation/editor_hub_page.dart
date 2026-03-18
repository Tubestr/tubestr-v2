import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../shared_ui/components/media_thumbnail_frame.dart';
import '../../../shared_ui/components/profile_switcher.dart';
import '../../../shared_ui/motion/app_motion.dart';
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
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Studio needs another moment',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
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
  const _Body({required this.items, required this.palette});

  final List<LocalVideo> items;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          _StudioHero(palette: palette),
          const SizedBox(height: 20),
          _EmptyState(palette: palette),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _HasClipsHeader(items: items, palette: palette),
        const SizedBox(height: 16),
        _LatestClipPreview(video: items.first, palette: palette),
        const SizedBox(height: 24),
        Text(
          'All clips',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _VideoGrid(items: items, palette: palette),
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
          'Edit Studio',
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
          tooltip: 'Capture',
        ),
      ],
    );
  }
}

/// Large preview card for the latest clip.
class _LatestClipPreview extends StatelessWidget {
  const _LatestClipPreview({required this.video, required this.palette});

  final LocalVideo video;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    final thumbFile = video.thumbPath.isEmpty ? null : File(video.thumbPath);
    final hasThumb = thumbFile?.existsSync() == true;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          AppMotion.modalRoute(
            context: context,
            builder: (_) => EditorDetailPage(video: video),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail or gradient placeholder
              if (hasThumb)
                MediaThumbnailFrame(
                  file: thumbFile!,
                  borderRadius: BorderRadius.circular(0),
                  background: LinearGradient(
                    colors: [
                      palette.accent.withValues(alpha: 0.18),
                      palette.accentSecondary.withValues(alpha: 0.16),
                      const Color(0xFF120F18),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  padding: EdgeInsets.zero,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        palette.accent.withValues(alpha: 0.3),
                        palette.accentSecondary.withValues(alpha: 0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.movie_creation_outlined,
                    size: 48,
                    color: palette.accent,
                  ),
                ),

              // Scrim + "Edit this clip" overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).push(
                            AppMotion.modalRoute(
                              context: context,
                              builder: (_) => EditorDetailPage(video: video),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: const Text('Edit this clip'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          'Edit Studio',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: palette.accent,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Capture something first, then bring it here for stickers, music, text, and remixes.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(appShellTabIndexProvider.notifier).state = 1;
                },
                icon: const Icon(Icons.videocam_rounded),
                label: const Text('Capture First'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Need a clip'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
            color: palette.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: palette.accent,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Nothing to remix yet',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Record something in Capture first, then come back here to add music, stickers, text, and trims.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StudioPill(
              icon: Icons.cut_rounded,
              label: 'Trim',
              palette: palette,
            ),
            _StudioPill(
              icon: Icons.music_note_rounded,
              label: 'Music',
              palette: palette,
            ),
            _StudioPill(
              icon: Icons.emoji_emotions_outlined,
              label: 'Stickers',
              palette: palette,
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () =>
              ref.read(appShellTabIndexProvider.notifier).state = 1,
          icon: const Icon(Icons.videocam_rounded),
          label: const Text('Open Capture'),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: palette.accent),
          const SizedBox(width: 8),
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
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          AppMotion.modalRoute(
            context: context,
            builder: (_) => EditorDetailPage(video: video),
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.accent.withValues(alpha: 0.15),
              palette.accentSecondary.withValues(alpha: 0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
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
      ),
    );
  }
}
