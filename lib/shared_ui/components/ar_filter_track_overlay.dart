import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/editor/ar_face_track_service.dart';
import '../../services/editor/ar_filter_catalog.dart';
import '../../services/editor/ar_filter_renderer.dart';
import 'ar_filter_overlay_painter.dart';

class ArFilterTrackOverlay extends StatefulWidget {
  const ArFilterTrackOverlay({
    super.key,
    required this.filterId,
    required this.trackPath,
    this.position = Duration.zero,
    this.positionListenable,
    this.assetBundle,
    this.isMirrored = false,
    this.loadFilterAsset,
  });

  final String? filterId;
  final String? trackPath;
  final Duration position;
  final ValueListenable<Duration>? positionListenable;
  final AssetBundle? assetBundle;
  final bool isMirrored;
  final ArFilterAssetLoader? loadFilterAsset;

  @override
  State<ArFilterTrackOverlay> createState() => _ArFilterTrackOverlayState();
}

class _ArFilterTrackOverlayState extends State<ArFilterTrackOverlay> {
  final ArFilterRenderer _renderer = const ArFilterRenderer();
  ArFilterAsset? _filter;
  List<ArFaceTrackSample> _samples = const <ArFaceTrackSample>[];
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ArFilterTrackOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterId != oldWidget.filterId ||
        widget.trackPath != oldWidget.trackPath ||
        widget.assetBundle != oldWidget.assetBundle) {
      _load();
    }
  }

  @override
  void dispose() {
    _loadGeneration += 1;
    _filter?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final filterId = widget.filterId;
    final trackPath = widget.trackPath;
    final generation = ++_loadGeneration;

    if (filterId == null ||
        filterId.isEmpty ||
        trackPath == null ||
        trackPath.isEmpty) {
      final oldFilter = _filter;
      if (mounted) {
        setState(() {
          _filter = null;
          _samples = const <ArFaceTrackSample>[];
        });
      }
      oldFilter?.dispose();
      return;
    }

    final samples = await ArFaceTrackService.readTrackFile(trackPath);
    final loadFilterAsset = widget.loadFilterAsset ?? ArFilterCatalog.load;
    final filter = await loadFilterAsset(
      filterId,
      assetBundle: widget.assetBundle,
    );
    if (!mounted || generation != _loadGeneration) {
      filter?.dispose();
      return;
    }

    final oldFilter = _filter;
    setState(() {
      _filter = filter;
      _samples = samples;
    });
    oldFilter?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = _filter;
    if (filter == null || _samples.isEmpty) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = constraints.biggest;
          if (viewportSize.isEmpty) {
            return const SizedBox.shrink();
          }
          return RepaintBoundary(
            child: CustomPaint(
              painter: _ArFilterTrackOverlayPainter(
                fallbackPosition: widget.position,
                positionListenable: widget.positionListenable,
                samples: _samples,
                filter: filter,
                renderer: _renderer,
                viewportSize: viewportSize,
                isMirrored: widget.isMirrored,
              ),
              size: viewportSize,
            ),
          );
        },
      ),
    );
  }
}

class _ArFilterTrackOverlayPainter extends CustomPainter {
  _ArFilterTrackOverlayPainter({
    required this.fallbackPosition,
    required this.positionListenable,
    required this.samples,
    required this.filter,
    required this.renderer,
    required this.viewportSize,
    required this.isMirrored,
  }) : super(repaint: positionListenable);

  final Duration fallbackPosition;
  final ValueListenable<Duration>? positionListenable;
  final List<ArFaceTrackSample> samples;
  final ArFilterAsset filter;
  final ArFilterRenderer renderer;
  final Size viewportSize;
  final bool isMirrored;

  @override
  void paint(Canvas canvas, Size size) {
    final sample = ArFaceTrackService.sampleAtPosition(
      samples: samples,
      position: positionListenable?.value ?? fallbackPosition,
    );
    if (sample == null) {
      return;
    }
    final commands = renderer.computeDrawCommands(
      face: sample.face,
      filter: filter,
      geometry: ArPreviewGeometry(
        imageSize: sample.face.imageSize,
        viewportSize: viewportSize,
        isMirrored: isMirrored,
      ),
    );
    ArFilterOverlayPainter(commands: commands).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _ArFilterTrackOverlayPainter oldDelegate) {
    return fallbackPosition != oldDelegate.fallbackPosition ||
        positionListenable != oldDelegate.positionListenable ||
        samples != oldDelegate.samples ||
        filter != oldDelegate.filter ||
        viewportSize != oldDelegate.viewportSize ||
        isMirrored != oldDelegate.isMirrored;
  }
}
