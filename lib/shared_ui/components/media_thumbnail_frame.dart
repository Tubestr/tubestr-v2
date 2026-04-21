import 'dart:io';

import 'package:flutter/material.dart';

/// Presents a local thumbnail without forcing portrait media into a landscape
/// crop. The file is letterboxed inside a styled frame instead of stretched or
/// aggressively cropped.
class MediaThumbnailFrame extends StatelessWidget {
  const MediaThumbnailFrame({
    super.key,
    required this.file,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.background,
    this.padding = EdgeInsets.zero,
  });

  final File file;
  final BorderRadius borderRadius;
  final Gradient? background;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient:
              background ??
              LinearGradient(
                colors: [
                  colorScheme.inverseSurface,
                  colorScheme.inverseSurface.withValues(alpha: 0.72),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        ),
        child: Padding(
          padding: padding,
          child: Center(child: Image.file(file, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
