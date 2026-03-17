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
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient:
              background ??
              const LinearGradient(
                colors: [Color(0xFF15111C), Color(0xFF0C0A11)],
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
