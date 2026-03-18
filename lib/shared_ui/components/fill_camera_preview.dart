import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fills the available space with a camera preview without stretching it.
///
/// The camera plugin reports preview sizes in sensor coordinates, which can
/// look stretched when a portrait UI simply forces `CameraPreview` to fill the
/// screen. This widget scales and crops instead of distorting.
class FillCameraPreview extends StatelessWidget {
  const FillCameraPreview({
    super.key,
    required this.controller,
    this.alignment = Alignment.center,
  });

  final CameraController controller;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (!value.isInitialized) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final previewAspectRatio = _effectivePreviewAspectRatio(value);
            if (previewAspectRatio <= 0) {
              return CameraPreview(controller);
            }

            final viewportSize = constraints.biggest;
            final fittedSize = _coverSize(
              viewportSize: viewportSize,
              childAspectRatio: previewAspectRatio,
            );

            return ClipRect(
              child: OverflowBox(
                minWidth: fittedSize.width,
                maxWidth: fittedSize.width,
                minHeight: fittedSize.height,
                maxHeight: fittedSize.height,
                alignment: alignment,
                child: SizedBox(
                  width: fittedSize.width,
                  height: fittedSize.height,
                  child: CameraPreview(controller),
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _effectivePreviewAspectRatio(CameraValue value) {
    final base = value.aspectRatio;
    if (_isLandscape(value)) {
      return base;
    }
    return 1 / base;
  }

  bool _isLandscape(CameraValue value) {
    final orientation = value.isRecordingVideo
        ? value.recordingOrientation
        : (value.previewPauseOrientation ??
              value.lockedCaptureOrientation ??
              value.deviceOrientation);
    return orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;
  }

  Size _coverSize({
    required Size viewportSize,
    required double childAspectRatio,
  }) {
    final viewportAspectRatio =
        viewportSize.width / math.max(viewportSize.height, 1);
    if (viewportAspectRatio > childAspectRatio) {
      final width = viewportSize.width;
      return Size(width, width / childAspectRatio);
    }
    final height = viewportSize.height;
    return Size(height * childAspectRatio, height);
  }
}
