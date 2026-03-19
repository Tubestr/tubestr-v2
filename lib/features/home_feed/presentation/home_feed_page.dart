import 'dart:math';
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
    final videoItems = videos.valueOrNull;
    final isFreshState =
        videoItems != null && videoItems.isEmpty && remoteShares.isEmpty;

    return Stack(
      children: [
        Positioned.fill(
          child: _HomeFeedMotionLayer(
            palette: palette,
            emphasizeMotion: isFreshState,
          ),
        ),
        SafeArea(
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
                  child: isFreshState
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                100,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - 116,
                                ),
                                child: _FreshHomeState(
                                  name: selectedProfile?.name ?? 'there',
                                  palette: palette,
                                ),
                              ),
                            );
                          },
                        )
                      : ListView(
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
                                return _MyVideosSection(
                                  items: items,
                                  palette: palette,
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (e, _) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your videos need another moment',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'We couldn\'t load this child\'s library just yet. Pull down to try again.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: palette.mutedInk),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // From Friends & Family
                            if (remoteShares.isNotEmpty) ...[
                              _SharedVideosSection(
                                items: remoteShares,
                                palette: palette,
                              ),
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
        ),
      ],
    );
  }
}

class _HomeFeedMotionLayer extends StatefulWidget {
  const _HomeFeedMotionLayer({
    required this.palette,
    required this.emphasizeMotion,
  });

  final KidPalette palette;
  final bool emphasizeMotion;

  @override
  State<_HomeFeedMotionLayer> createState() => _HomeFeedMotionLayerState();
}

class _HomeFeedMotionLayerState extends State<_HomeFeedMotionLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return LayoutBuilder(
      builder: (context, constraints) {
        final localSize = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 400,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 240,
        );

        return IgnorePointer(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = reduceMotion ? 0.35 : _controller.value;
                final orbit = 26.0 * sin(t * pi * 2);
                final float = 18.0 * cos(t * pi * 2);
                final shimmer = 10.0 * sin(t * pi * 4);
                final orbAlpha = widget.emphasizeMotion ? 0.24 : 0.15;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -72 + float,
                      right: -54 - orbit * 0.4,
                      child: Transform.scale(
                        scale: 1.0 + 0.06 * sin(t * pi * 2),
                        child: _HomeGlowOrb(
                          color: widget.palette.accent.withValues(
                            alpha: orbAlpha,
                          ),
                          size: widget.emphasizeMotion ? 240 : 210,
                        ),
                      ),
                    ),
                    Positioned(
                      top: localSize.height * 0.24 - float * 0.6,
                      left: -92 + orbit * 0.5,
                      child: Transform.scale(
                        scale: 0.96 + 0.08 * cos(t * pi * 2),
                        child: _HomeGlowOrb(
                          color: widget.palette.accentSecondary.withValues(
                            alpha: orbAlpha - 0.04,
                          ),
                          size: widget.emphasizeMotion ? 220 : 190,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 28 - float * 0.6,
                      right: localSize.width * 0.16 + orbit * 0.2,
                      child: Transform.scale(
                        scale: 0.94 + 0.07 * sin(t * pi * 2 + 1.2),
                        child: _HomeGlowOrb(
                          color: widget.palette.accent.withValues(
                            alpha: orbAlpha - 0.06,
                          ),
                          size: widget.emphasizeMotion ? 150 : 130,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 34 + shimmer,
                      right: 54,
                      child: _HomeGlowOrb(
                        color: widget.palette.accentSecondary.withValues(
                          alpha: 0.30,
                        ),
                        size: 34,
                      ),
                    ),
                    Positioned(
                      top: localSize.height * 0.56 - shimmer,
                      left: 42,
                      child: _HomeGlowOrb(
                        color: widget.palette.accent.withValues(alpha: 0.22),
                        size: 24,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _HomeGlowOrb extends StatelessWidget {
  const _HomeGlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ),
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
        _HomeSceneHero(
          palette: palette,
          eyebrow: '$greeting, $name',
          title: 'Make your first video',
          detail:
              'Start in Capture, then head to Edit Studio to add stickers, music, or text.',
          emphasizeMotion: true,
        ),
        const SizedBox(height: 18),
        _FirstVideoPanel(palette: palette),
        const SizedBox(height: 18),

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

class _FreshHomeState extends ConsumerWidget {
  const _FreshHomeState({required this.name, required this.palette});

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
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HomeSceneHero(
          palette: palette,
          eyebrow: '$greeting, $name',
          title: 'Your family video shelf starts here',
          detail:
              'Capture a first clip or connect with a trusted family before this space fills up.',
          emphasizeMotion: true,
          compactTitle: true,
        ),
        const SizedBox(height: 18),
        _FirstVideoPanel(palette: palette),
        const SizedBox(height: 18),
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
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(pendingParentZoneSectionProvider.notifier).state =
                  'familySpaces';
              ref.read(appShellTabIndexProvider.notifier).state = 3;
            },
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Connect Families'),
          ),
        ),
      ],
    );
  }
}

class _HomeSceneHero extends StatelessWidget {
  const _HomeSceneHero({
    required this.palette,
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.emphasizeMotion,
    this.compactTitle = false,
  });

  final KidPalette palette;
  final String eyebrow;
  final String title;
  final String detail;
  final bool emphasizeMotion;
  final bool compactTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compactTitle ? 196 : 208),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.panelBorder, width: 1.2),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.52),
            Colors.white.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: _HomeFeedMotionLayer(
                palette: palette,
                emphasizeMotion: emphasizeMotion,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      palette.backgroundTop.withValues(alpha: 0.34),
                      palette.backgroundBottom.withValues(alpha: 0.62),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eyebrow,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: palette.ink.withValues(alpha: 0.74),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style:
                        (compactTitle
                                ? Theme.of(context).textTheme.headlineSmall
                                : Theme.of(context).textTheme.headlineMedium)
                            ?.copyWith(
                              color: palette.ink,
                              fontWeight: FontWeight.w900,
                              height: 1.02,
                            ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      detail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.ink.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirstVideoPanel extends StatelessWidget {
  const _FirstVideoPanel({required this.palette});

  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.accent.withValues(alpha: 0.12),
            palette.accentSecondary.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'First steps',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.accent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Capture a clip, then decorate it in Edit Studio when you\'re ready.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This shelf stays simple until your family actually starts recording.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.movie_creation_rounded,
                  color: palette.accent,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FirstStepPill(label: 'Capture'),
              _FirstStepPill(label: 'Edit'),
              _FirstStepPill(label: 'Share later'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FirstStepPill extends StatelessWidget {
  const _FirstStepPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
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
                childAspectRatio: 3 / 4,
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
        ref.read(pendingParentZoneSectionProvider.notifier).state =
            'familySpaces';
        ref.read(appShellTabIndexProvider.notifier).state = 3;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.panelBorder)),
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
      (RemoteShareProjection item) => item.mlsGroupId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'From Friends & Family'),
        const SizedBox(height: 12),
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
    final groupSummary =
        ref.watch(mdkGroupSummaryProvider(mlsGroupId)).valueOrNull;
    final label = groupSummary?.name ?? fallbackChildName;
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
