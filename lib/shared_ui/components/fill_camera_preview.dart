import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
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
    this.previewAspectRatio,
    this.debugLabel,
  });

  final CameraController controller;
  final Alignment alignment;
  final double? previewAspectRatio;
  final String? debugLabel;

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
            final previewAspectRatio =
                this.previewAspectRatio ??
                effectivePreviewAspectRatioFor(value);
            if (previewAspectRatio <= 0) {
              return CameraPreview(controller);
            }

            final viewportSize = constraints.biggest;
            final fittedSize = _coverSize(
              viewportSize: viewportSize,
              childAspectRatio: previewAspectRatio,
            );
            _logPreviewLayout(
              value: value,
              viewportSize: viewportSize,
              fittedSize: fittedSize,
              previewAspectRatio: previewAspectRatio,
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

  static double effectivePreviewAspectRatioFor(CameraValue value) {
    final base = value.aspectRatio;
    if (_isLandscape(value)) {
      return base;
    }
    return 1 / base;
  }

  static bool _isLandscape(CameraValue value) {
    final orientation = _applicableOrientation(value);
    return orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;
  }

  static DeviceOrientation _applicableOrientation(CameraValue value) {
    return value.isRecordingVideo
        ? (value.recordingOrientation ??
              value.lockedCaptureOrientation ??
              value.deviceOrientation)
        : (value.previewPauseOrientation ??
              value.lockedCaptureOrientation ??
              value.deviceOrientation);
  }

  void _logPreviewLayout({
    required CameraValue value,
    required Size viewportSize,
    required Size fittedSize,
    required double previewAspectRatio,
  }) {
    final label = debugLabel;
    if (!kDebugMode || label == null) {
      return;
    }
    final previewSize = value.previewSize;
    debugPrint(
      'CAPTURE_CAMERA preview_layout label=$label '
      'recording=${value.isRecordingVideo} '
      'streaming=${value.isStreamingImages} '
      'previewSize=${previewSize?.width.toStringAsFixed(0)}x${previewSize?.height.toStringAsFixed(0)} '
      'rawAspect=${value.aspectRatio.toStringAsFixed(4)} '
      'effectiveAspect=${previewAspectRatio.toStringAsFixed(4)} '
      'override=${this.previewAspectRatio?.toStringAsFixed(4) ?? 'none'} '
      'viewport=${viewportSize.width.toStringAsFixed(0)}x${viewportSize.height.toStringAsFixed(0)} '
      'fitted=${fittedSize.width.toStringAsFixed(0)}x${fittedSize.height.toStringAsFixed(0)} '
      'device=${value.deviceOrientation.name} '
      'locked=${value.lockedCaptureOrientation?.name ?? 'none'} '
      'recordingOrientation=${value.recordingOrientation?.name ?? 'none'} '
      'paused=${value.previewPauseOrientation?.name ?? 'none'}',
    );
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
