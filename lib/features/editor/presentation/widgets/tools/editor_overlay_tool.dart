import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/theme/radii.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/theme/theme_descriptor.dart';
import '../../../../../domain/models/editor_resources.dart';
import '../../../../../domain/models/editor_session.dart';
import '../../../../../services/editor/editor_resource_catalog.dart';
import '../../../../../l10n/l10n.dart';

class CompactOverlayTool extends StatefulWidget {
  const CompactOverlayTool({
    super.key,
    required this.palette,
    required this.session,
    required this.onStickerSelected,
    required this.onOpenSelfieStickerCapture,
    required this.userStickers,
    required this.onDeleteUserSticker,
  });

  final KidPalette palette;
  final EditorSession session;
  final void Function(String stickerId, String assetPath) onStickerSelected;
  final Future<void> Function() onOpenSelfieStickerCapture;
  final List<EditorStickerAsset> userStickers;
  final Future<void> Function(EditorStickerAsset sticker) onDeleteUserSticker;

  @override
  State<CompactOverlayTool> createState() => CompactOverlayToolState();
}

class CompactOverlayToolState extends State<CompactOverlayTool> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _categoryId = StickerCategory.all.id;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stickerItems = [
      for (final sticker in widget.userStickers)
        StickerPickerItem(sticker: sticker, isUserSticker: true),
      for (final sticker in EditorResourceCatalog.builtInStickerAssets)
        StickerPickerItem(sticker: sticker, isUserSticker: false),
    ];
    final categories = StickerCategory.visibleFor(
      hasUserStickers: widget.userStickers.isNotEmpty,
    );
    final selectedCategory = categories.firstWhere(
      (category) => category.id == _categoryId,
      orElse: () => StickerCategory.all,
    );
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredStickers = stickerItems
        .where((item) {
          if (!selectedCategory.matches(item)) return false;
          if (normalizedQuery.isEmpty) return true;
          final label = item.sticker.label.toLowerCase();
          final id = item.sticker.id.toLowerCase().replaceAll('_', ' ');
          return label.contains(normalizedQuery) ||
              id.contains(normalizedQuery);
        })
        .toList(growable: false);
    final visibleItems = [
      StickerPickerEntry.selfie,
      for (final item in filteredStickers) StickerPickerEntry.sticker(item),
    ];

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
          StickerToolHeader(
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
            child: visibleItems.length == 1
                ? StickerEmptyState(palette: widget.palette, query: _query)
                : GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 64,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemCount: visibleItems.length,
                    itemBuilder: (context, index) {
                      final entry = visibleItems[index];
                      if (entry.isSelfie) {
                        return StickerTile(
                          palette: widget.palette,
                          onTap: widget.onOpenSelfieStickerCapture,
                          child: Icon(
                            Icons.photo_camera_front_rounded,
                            color: widget.palette.accentSecondary,
                            size: AppIconSize.xl,
                          ),
                        );
                      }

                      final item = entry.item!;
                      final sticker = item.sticker;
                      final isBundled = sticker.assetPath.startsWith('assets/');
                      return StickerTile(
                        palette: widget.palette,
                        onTap: () => widget.onStickerSelected(
                          sticker.id,
                          sticker.assetPath,
                        ),
                        onLongPress: item.isUserSticker
                            ? () => widget.onDeleteUserSticker(sticker)
                            : null,
                        child: isBundled
                            ? Image.asset(
                                sticker.assetPath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => StickerLoadErrorIcon(
                                  palette: widget.palette,
                                ),
                              )
                            : Image.file(
                                File(sticker.assetPath),
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => StickerLoadErrorIcon(
                                  palette: widget.palette,
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class StickerToolHeader extends StatelessWidget {
  const StickerToolHeader({
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
          hintText: context.l10n.editorSearchStickers,
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

class StickerCategoryChip extends StatelessWidget {
  const StickerCategoryChip({
    super.key,
    required this.palette,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final KidPalette palette;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: 0.28)
              : palette.mediaSurfaceSubtle,
          borderRadius: AppRadii.smAll,
          border: Border.all(
            color: isSelected
                ? palette.accentSecondary.withValues(alpha: 0.55)
                : palette.mediaBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? palette.mediaInk : palette.mediaMutedInk,
            fontSize: AppTextSize.label,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class StickerTile extends StatelessWidget {
  const StickerTile({
    super.key,
    required this.palette,
    required this.onTap,
    required this.child,
    this.onLongPress,
  });

  final KidPalette palette;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: palette.mediaSurfaceSubtle,
          borderRadius: AppRadii.smAll,
          border: Border.all(color: palette.mediaBorder),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: child,
      ),
    );
  }
}

class StickerLoadErrorIcon extends StatelessWidget {
  const StickerLoadErrorIcon({super.key, required this.palette});

  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.image_not_supported_outlined,
      color: palette.mediaSubtleInk,
      size: AppIconSize.xl,
    );
  }
}

class StickerEmptyState extends StatelessWidget {
  const StickerEmptyState({
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
            ? context.l10n.editorNoStickersHereYet
            : context.l10n.editorNoMatchingStickers,
        style: TextStyle(
          color: palette.mediaSubtleInk,
          fontSize: AppTextSize.label,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class StickerPickerItem {
  const StickerPickerItem({required this.sticker, required this.isUserSticker});

  final EditorStickerAsset sticker;
  final bool isUserSticker;
}

class StickerPickerEntry {
  const StickerPickerEntry._({required this.isSelfie, this.item});

  const StickerPickerEntry.sticker(StickerPickerItem item)
    : this._(isSelfie: false, item: item);

  static const selfie = StickerPickerEntry._(isSelfie: true);

  final bool isSelfie;
  final StickerPickerItem? item;
}

class StickerCategory {
  const StickerCategory({
    required this.id,
    required this.label,
    required this.matches,
  });

  final String id;
  final String label;
  final bool Function(StickerPickerItem item) matches;

  static const all = StickerCategory(
    id: 'all',
    label: 'All',
    matches: _matchAll,
  );

  static const _user = StickerCategory(
    id: 'yours',
    label: 'Yours',
    matches: _matchUser,
  );

  static const _originals = StickerCategory(
    id: 'originals',
    label: 'Originals',
    matches: _matchOriginal,
  );

  static const _faces = StickerCategory(
    id: 'faces',
    label: 'Faces',
    matches: _matchFaces,
  );

  static const _hearts = StickerCategory(
    id: 'hearts',
    label: 'Hearts',
    matches: _matchHearts,
  );

  static const _party = StickerCategory(
    id: 'party',
    label: 'Party',
    matches: _matchParty,
  );

  static const _animals = StickerCategory(
    id: 'animals',
    label: 'Animals',
    matches: _matchAnimals,
  );

  static const _food = StickerCategory(
    id: 'food',
    label: 'Food',
    matches: _matchFood,
  );

  static const _sports = StickerCategory(
    id: 'sports',
    label: 'Sports',
    matches: _matchSports,
  );

  static const _objects = StickerCategory(
    id: 'objects',
    label: 'Objects',
    matches: _matchObjects,
  );

  static const _travel = StickerCategory(
    id: 'travel',
    label: 'Travel',
    matches: _matchTravel,
  );

  static List<StickerCategory> visibleFor({required bool hasUserStickers}) {
    return [
      all,
      if (hasUserStickers) _user,
      _originals,
      _faces,
      _hearts,
      _party,
      _animals,
      _food,
      _sports,
      _objects,
      _travel,
    ];
  }

  String localizedLabel(BuildContext context) => switch (id) {
    'all' => context.l10n.editorCategoryAll,
    'yours' => context.l10n.editorCategoryYours,
    'originals' => context.l10n.editorCategoryOriginals,
    'faces' => context.l10n.editorCategoryFaces,
    'hearts' => context.l10n.editorCategoryHearts,
    'party' => context.l10n.editorCategoryParty,
    'animals' => context.l10n.editorCategoryAnimals,
    'food' => context.l10n.editorCategoryFood,
    'sports' => context.l10n.editorCategorySports,
    'objects' => context.l10n.editorCategoryObjects,
    'travel' => context.l10n.editorCategoryTravel,
    _ => label,
  };
}

bool _matchAll(StickerPickerItem item) => true;

bool _matchUser(StickerPickerItem item) => item.isUserSticker;

bool _matchOriginal(StickerPickerItem item) {
  return !item.isUserSticker && !item.sticker.id.startsWith('fluent_emoji_');
}

bool _matchFaces(StickerPickerItem item) {
  final label = item.sticker.label.toLowerCase();
  return label.contains('face') ||
      label.contains('alien') ||
      label.contains('clown') ||
      label.contains('ghost') ||
      label.contains('robot');
}

bool _matchHearts(StickerPickerItem item) {
  final label = item.sticker.label.toLowerCase();
  return label.contains('heart');
}

bool _matchParty(StickerPickerItem item) {
  return _labelMatchesAny(item, const {
    'party',
    'confetti',
    'balloon',
    'gift',
    'birthday',
    'sparkle',
    'star',
    'rainbow',
    'fire',
    'hundred',
    'collision',
    'dizzy',
    'trophy',
    'medal',
  });
}

bool _matchAnimals(StickerPickerItem item) {
  return _labelMatchesAny(item, const {
    'dog',
    'cat',
    'mouse',
    'hamster',
    'rabbit',
    'fox',
    'bear',
    'panda',
    'koala',
    'tiger',
    'lion',
    'cow',
    'pig',
    'frog',
    'monkey',
    'chicken',
    'penguin',
    'bird',
    'unicorn',
    'butterfly',
    'beetle',
    'turtle',
    'octopus',
    'dolphin',
    'whale',
    'fish',
    'shark',
    'snail',
  });
}

bool _matchFood(StickerPickerItem item) {
  return _labelMatchesAny(item, const {
    'pizza',
    'hamburger',
    'fries',
    'hot dog',
    'taco',
    'burrito',
    'popcorn',
    'doughnut',
    'cookie',
    'candy',
    'lollipop',
    'ice cream',
    'cupcake',
    'watermelon',
    'strawberry',
    'banana',
    'apple',
    'grapes',
    'cherries',
  });
}

bool _matchSports(StickerPickerItem item) {
  return _labelMatchesAny(item, const {
    'soccer',
    'basketball',
    'baseball',
    'softball',
    'tennis',
    'volleyball',
    'disc',
    'kite',
    'yo-yo',
  });
}

bool _matchObjects(StickerPickerItem item) {
  return _labelMatchesAny(item, const {
    'game',
    'joystick',
    'palette',
    'music',
    'microphone',
    'headphone',
    'guitar',
    'drum',
    'trumpet',
    'violin',
    'camera',
    'movie',
    'clapper',
    'television',
    'laptop',
    'bulb',
    'magnet',
    'gem',
    'crown',
    'ring',
    'sunglasses',
    'wand',
  });
}

bool _matchTravel(StickerPickerItem item) {
  return _labelMatchesAny(item, const {
    'rocket',
    'saucer',
    'airplane',
    'bicycle',
    'skate',
  });
}

bool _labelMatchesAny(StickerPickerItem item, Set<String> terms) {
  final label = item.sticker.label.toLowerCase();
  return terms.any(label.contains);
}

// ── Compact Audio Tool ──────────────────────────────────────────────────
