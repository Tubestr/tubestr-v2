import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/radii.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/theme/theme_descriptor.dart';
import '../../../../../domain/models/editor_resources.dart';
import '../../../../../domain/models/editor_session.dart';
import '../../../../../services/editor/editor_resource_catalog.dart';
import '../../../../../l10n/l10n.dart';
import 'editor_overlay_tool.dart';

class CompactAudioTool extends StatefulWidget {
  const CompactAudioTool({
    super.key,
    required this.palette,
    required this.session,
    required this.onMusicSelected,
    required this.onMusicRemoved,
    required this.onMusicVolumeChanged,
    required this.onMusicPreviewToggled,
    required this.previewingTrackId,
    required this.cachedTrackIds,
    required this.downloadingTrackIds,
  });

  final KidPalette palette;
  final EditorSession session;
  final Future<void> Function(EditorMusicTrackAsset track) onMusicSelected;
  final VoidCallback onMusicRemoved;
  final ValueChanged<double> onMusicVolumeChanged;
  final Future<void> Function(EditorMusicTrackAsset track)
  onMusicPreviewToggled;
  final String? previewingTrackId;
  final Set<String> cachedTrackIds;
  final Set<String> downloadingTrackIds;

  @override
  State<CompactAudioTool> createState() => CompactAudioToolState();
}

class CompactAudioToolState extends State<CompactAudioTool> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _categoryId = AudioCategory.all.id;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = widget.session.audioSelection;
    final categories = AudioCategory.visibleFor(
      tracks: EditorResourceCatalog.builtInMusicTracks,
      cachedTrackIds: widget.cachedTrackIds,
    );
    final selectedCategory = categories.firstWhere(
      (category) => category.id == _categoryId,
      orElse: () => AudioCategory.all,
    );
    final normalizedQuery = _query.trim().toLowerCase();
    final tracks = EditorResourceCatalog.builtInMusicTracks
        .where((track) {
          if (!selectedCategory.matches(track, widget.cachedTrackIds)) {
            return false;
          }
          if (normalizedQuery.isEmpty) {
            return true;
          }
          final searchable = [
            track.label,
            track.creator ?? '',
            track.id.replaceAll('_', ' '),
            ...track.categories,
          ].join(' ').toLowerCase();
          return searchable.contains(normalizedQuery);
        })
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AudioToolHeader(
            palette: widget.palette,
            controller: _searchController,
            onQueryChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.id == selectedCategory.id;
                return StickerCategoryChip(
                  palette: widget.palette,
                  label: category.localizedLabel(context),
                  isSelected: isSelected,
                  onTap: () => setState(() => _categoryId = category.id),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: tracks.isEmpty
                ? AudioEmptyState(palette: widget.palette, query: _query)
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: tracks.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return AudioTrackRow(
                        palette: widget.palette,
                        track: track,
                        isSelected: selection?.trackId == track.id,
                        isPreviewing: widget.previewingTrackId == track.id,
                        isCached: widget.cachedTrackIds.contains(track.id),
                        isDownloading: widget.downloadingTrackIds.contains(
                          track.id,
                        ),
                        onSelected: () =>
                            unawaited(widget.onMusicSelected(track)),
                        onPreview: () =>
                            unawaited(widget.onMusicPreviewToggled(track)),
                      );
                    },
                  ),
          ),
          if (selection != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  color: widget.palette.mediaSubtleInk,
                  size: AppIconSize.md,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      activeTrackColor: widget.palette.accentSecondary,
                      inactiveTrackColor: widget.palette.mediaSurfaceSubtle,
                      thumbColor: widget.palette.mediaInk,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      value: selection.volume,
                      onChanged: widget.onMusicVolumeChanged,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onMusicRemoved,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: widget.palette.mediaSurfaceSubtle,
                      borderRadius: AppRadii.smAll,
                    ),
                    child: Text(
                      context.l10n.actionRemove,
                      style: TextStyle(
                        color: widget.palette.mediaMutedInk,
                        fontSize: AppTextSize.label,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AudioToolHeader extends StatelessWidget {
  const AudioToolHeader({
    super.key,
    required this.palette,
    required this.controller,
    required this.onQueryChanged,
  });

  final KidPalette palette;
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        onChanged: onQueryChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: palette.mediaInk,
          fontSize: AppTextSize.body,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: context.l10n.editorSearchMusic,
          hintStyle: TextStyle(
            color: palette.mediaSubtleInk,
            fontSize: AppTextSize.body,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: palette.mediaSubtleInk,
            size: AppIconSize.lg,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close_rounded,
                    color: palette.mediaMutedInk,
                    size: AppIconSize.md,
                  ),
                  onPressed: () {
                    controller.clear();
                    onQueryChanged('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          filled: true,
          fillColor: palette.mediaSurfaceSubtle,
          border: OutlineInputBorder(
            borderRadius: AppRadii.smAll,
            borderSide: BorderSide(color: palette.mediaBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.smAll,
            borderSide: BorderSide(color: palette.mediaBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.smAll,
            borderSide: BorderSide(color: palette.mediaBorderStrong),
          ),
        ),
      ),
    );
  }
}

class AudioTrackRow extends StatelessWidget {
  const AudioTrackRow({
    super.key,
    required this.palette,
    required this.track,
    required this.isSelected,
    required this.isPreviewing,
    required this.isCached,
    required this.isDownloading,
    required this.onSelected,
    required this.onPreview,
  });

  final KidPalette palette;
  final EditorMusicTrackAsset track;
  final bool isSelected;
  final bool isPreviewing;
  final bool isCached;
  final bool isDownloading;
  final VoidCallback onSelected;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final creator = track.creator;
    final status = track.isBlossomBacked && !isCached
        ? context.l10n.editorMusicDownload
        : (track.license ?? context.l10n.editorMusicReady);

    return GestureDetector(
      onTap: isDownloading ? null : onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [palette.accent, palette.accentSecondary],
                )
              : null,
          color: isSelected ? null : palette.mediaSurfaceSubtle,
          borderRadius: AppRadii.smAll,
          border: Border.all(
            color: isSelected ? palette.mediaBorderStrong : palette.mediaBorder,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: isDownloading ? null : onPreview,
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.mediaSurface,
                  borderRadius: AppRadii.smAll,
                ),
                child: isDownloading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.mediaInk,
                        ),
                      )
                    : Icon(
                        isPreviewing
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: palette.mediaInk,
                        size: AppIconSize.lg,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.mediaInk,
                      fontSize: AppTextSize.label,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (creator != null && creator.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      creator,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.mediaMutedInk,
                        fontSize: AppTextSize.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              constraints: const BoxConstraints(maxWidth: 86),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: palette.mediaSurface,
                borderRadius: AppRadii.smAll,
              ),
              child: Text(
                isDownloading ? context.l10n.editorMusicLoading : status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.mediaMutedInk,
                  fontSize: AppTextSize.micro,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.check_rounded,
                color: palette.mediaInk,
                size: AppIconSize.sm,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AudioEmptyState extends StatelessWidget {
  const AudioEmptyState({
    super.key,
    required this.palette,
    required this.query,
  });

  final KidPalette palette;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        query.trim().isEmpty
            ? context.l10n.editorNoMusicHereYet
            : context.l10n.editorNoMatchingMusic,
        style: TextStyle(
          color: palette.mediaSubtleInk,
          fontSize: AppTextSize.label,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AudioCategory {
  const AudioCategory({
    required this.id,
    required this.label,
    required this.matches,
  });

  final String id;
  final String label;
  final bool Function(EditorMusicTrackAsset track, Set<String> cachedTrackIds)
  matches;

  static const all = AudioCategory(
    id: 'all',
    label: 'All',
    matches: _matchAllAudio,
  );

  static const downloaded = AudioCategory(
    id: 'downloaded',
    label: 'Ready',
    matches: _matchDownloadedAudio,
  );

  static const happy = AudioCategory(
    id: 'happy',
    label: 'Happy',
    matches: _matchHappyAudio,
  );

  static const energy = AudioCategory(
    id: 'energy',
    label: 'Energy',
    matches: _matchEnergyAudio,
  );

  static const chill = AudioCategory(
    id: 'chill',
    label: 'Chill',
    matches: _matchChillAudio,
  );

  static const chiptune = AudioCategory(
    id: 'chiptune',
    label: 'Chiptune',
    matches: _matchChiptuneAudio,
  );

  static const dramatic = AudioCategory(
    id: 'dramatic',
    label: 'Dramatic',
    matches: _matchDramaticAudio,
  );

  static const loops = AudioCategory(
    id: 'loops',
    label: 'Loops',
    matches: _matchLoopsAudio,
  );

  static List<AudioCategory> visibleFor({
    required List<EditorMusicTrackAsset> tracks,
    required Set<String> cachedTrackIds,
  }) {
    final base = <AudioCategory>[
      all,
      downloaded,
      happy,
      energy,
      chill,
      chiptune,
      dramatic,
      loops,
    ];
    return base
        .where(
          (category) =>
              category == all ||
              tracks.any((track) => category.matches(track, cachedTrackIds)),
        )
        .toList(growable: false);
  }

  String localizedLabel(BuildContext context) => switch (id) {
    'all' => context.l10n.editorCategoryAll,
    'downloaded' => context.l10n.editorMusicReady,
    'happy' => context.l10n.editorMusicHappy,
    'energy' => context.l10n.editorMusicEnergy,
    'chill' => context.l10n.editorMusicChill,
    'chiptune' => context.l10n.editorMusicChiptune,
    'dramatic' => context.l10n.editorMusicDramatic,
    'loops' => context.l10n.editorMusicLoops,
    _ => label,
  };
}

bool _matchAllAudio(EditorMusicTrackAsset track, Set<String> cachedTrackIds) {
  return true;
}

bool _matchDownloadedAudio(
  EditorMusicTrackAsset track,
  Set<String> cachedTrackIds,
) {
  return cachedTrackIds.contains(track.id);
}

bool _matchHappyAudio(EditorMusicTrackAsset track, Set<String> cachedTrackIds) {
  return track.categories.contains('happy');
}

bool _matchEnergyAudio(
  EditorMusicTrackAsset track,
  Set<String> cachedTrackIds,
) {
  return track.categories.contains('energy');
}

bool _matchChillAudio(EditorMusicTrackAsset track, Set<String> cachedTrackIds) {
  return track.categories.contains('chill');
}

bool _matchChiptuneAudio(
  EditorMusicTrackAsset track,
  Set<String> cachedTrackIds,
) {
  return track.categories.contains('chiptune');
}

bool _matchDramaticAudio(
  EditorMusicTrackAsset track,
  Set<String> cachedTrackIds,
) {
  return track.categories.contains('dramatic');
}

bool _matchLoopsAudio(EditorMusicTrackAsset track, Set<String> cachedTrackIds) {
  return track.categories.contains('loops');
}

// ── Compact Text Tool ───────────────────────────────────────────────────
