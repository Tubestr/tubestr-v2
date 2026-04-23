import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';
import 'package:mytube/domain/models/ar_face_result.dart';
import 'package:mytube/services/editor/ar_face_track_service.dart';
import 'package:mytube/services/editor/ar_filter_catalog.dart';
import 'package:mytube/services/editor/ar_filter_renderer.dart';

void main() {
  test('ArPreviewGeometry maps uncropped portrait points directly', () {
    const geometry = ArPreviewGeometry(
      imageSize: Size(720, 1280),
      viewportSize: Size(360, 640),
    );

    expect(
      geometry.mapNormalizedPoint(const Offset(0.5, 0.5)),
      const Offset(180, 320),
    );
    expect(geometry.mapNormalizedPoint(const Offset(0, 0)), Offset.zero);
  });

  test('ArPreviewGeometry accounts for cover crop', () {
    const geometry = ArPreviewGeometry(
      imageSize: Size(1280, 720),
      viewportSize: Size(360, 640),
    );

    expect(
      geometry.mapNormalizedPoint(const Offset(0.5, 0.5)),
      const Offset(180, 320),
    );
    expect(geometry.mapNormalizedPoint(const Offset(0, 0)).dx, lessThan(0));
    expect(
      geometry.mapNormalizedPoint(const Offset(1, 1)).dx,
      greaterThan(360),
    );
  });

  test('ArPreviewGeometry mirrors x coordinates exactly once', () {
    const geometry = ArPreviewGeometry(
      imageSize: Size(720, 1280),
      viewportSize: Size(360, 640),
      isMirrored: true,
    );

    expect(
      geometry.mapNormalizedPoint(const Offset(0.2, 0.5)),
      const Offset(288, 320),
    );
  });

  test(
    'ArFilterRenderer positions and sizes commands from landmarks',
    () async {
      final image = await _testImage(width: 100, height: 50);
      addTearDown(image.dispose);
      const renderer = ArFilterRenderer();
      final face = _face();
      final filter = ArFilterAsset(
        id: 'test',
        label: 'Test',
        parts: <ArFilterPart>[
          ArFilterPart(
            image: image,
            anchor: ArFilterAnchor.eyesBridge,
            widthScale: 1,
            offset: Offset(0, -0.5),
          ),
        ],
      );

      final commands = renderer.computeDrawCommands(
        face: face,
        filter: filter,
        geometry: const ArPreviewGeometry(
          imageSize: Size(1000, 1000),
          viewportSize: Size(500, 500),
        ),
      );

      expect(commands, hasLength(1));
      final command = commands.single;
      expect(command.position.dx, closeTo(250, 0.01));
      expect(command.position.dy, lessThan(250));
      expect(command.size.width, closeTo(245, 0.01));
      expect(command.size.height, closeTo(122.5, 0.01));
    },
  );

  test(
    'ArFilterRenderer falls back to bounding box when eye landmarks are missing',
    () async {
      final image = await _testImage(width: 20, height: 20);
      addTearDown(image.dispose);
      const renderer = ArFilterRenderer();
      final face = ArFaceResult(
        boundingBox: const FaceMeshBox(
          left: 200,
          top: 200,
          right: 500,
          bottom: 600,
        ),
        landmarks: const <FaceMeshLandmark>[],
        score: 1,
        imageSize: const Size(1000, 1000),
      );
      final filter = ArFilterAsset(
        id: 'test',
        label: 'Test',
        parts: <ArFilterPart>[
          ArFilterPart(
            image: image,
            anchor: ArFilterAnchor.noseTip,
            widthScale: 1,
          ),
        ],
      );

      final commands = renderer.computeDrawCommands(
        face: face,
        filter: filter,
        geometry: const ArPreviewGeometry(
          imageSize: Size(1000, 1000),
          viewportSize: Size(500, 500),
        ),
      );

      expect(commands, isEmpty);
    },
  );

  test('ArFilterCatalog recovers persisted filter tags', () {
    expect(
      ArFilterCatalog.idFromTags(const [
        'captured',
        'ar_filter:crown',
        'family',
      ]),
      'crown',
    );
    expect(ArFilterCatalog.tagFor('sparkles'), 'ar_filter:sparkles');
    expect(
      ArFilterCatalog.trackPathFromTags(const [
        'captured',
        'ar_track:/tmp/track.json',
      ]),
      '/tmp/track.json',
    );
    expect(
      ArFilterCatalog.trackTagFor('/tmp/track.json'),
      'ar_track:/tmp/track.json',
    );
    expect(ArFilterCatalog.idFromTags(const ['ar_filter:unknown']), 'unknown');
  });

  test('ArFaceTrackService interpolates sidecar samples between frames', () {
    final before = _faceWithNose(x: 0.4, y: 0.5);
    final after = _faceWithNose(x: 0.8, y: 0.7);
    final sample = ArFaceTrackService.sampleAtPosition(
      samples: [
        ArFaceTrackSample(timeMs: 0, face: before),
        ArFaceTrackSample(timeMs: 100, face: after),
      ],
      position: const Duration(milliseconds: 50),
    );

    expect(sample, isNotNull);
    expect(sample!.timeMs, 50);
    expect(sample.face.noseTip?.dx, closeTo(0.6, 0.001));
    expect(sample.face.noseTip?.dy, closeTo(0.6, 0.001));
    expect(sample.face.boundingBox.left, closeTo(400, 0.001));
    expect(sample.face.boundingBox.right, closeTo(800, 0.001));
  });

  test('ArFaceTrackService defaults to mobile-friendly export rates', () {
    expect(ArFaceTrackService.defaultKeyframeFrameRate, 6);
    expect(ArFaceTrackService.defaultOutputFrameRate, 20);
  });
}

ArFaceResult _faceWithNose({required double x, required double y}) {
  final face = _face();
  final landmarks = List<FaceMeshLandmark>.from(face.landmarks);
  landmarks[1] = FaceMeshLandmark(x: x, y: y, z: 0);
  final shift = (x - 0.5) * 1000;
  return ArFaceResult(
    boundingBox: FaceMeshBox(
      left: face.boundingBox.left + shift,
      top: face.boundingBox.top,
      right: face.boundingBox.right + shift,
      bottom: face.boundingBox.bottom,
    ),
    landmarks: landmarks,
    score: face.score,
    imageSize: face.imageSize,
    trackingId: face.trackingId,
    headEulerY: face.headEulerY,
    headEulerZ: face.headEulerZ,
  );
}

ArFaceResult _face() {
  final landmarks = List<FaceMeshLandmark>.generate(
    468,
    (_) => FaceMeshLandmark(x: 0.5, y: 0.5, z: 0),
  );
  landmarks[33] = FaceMeshLandmark(x: 0.4, y: 0.5, z: 0);
  landmarks[263] = FaceMeshLandmark(x: 0.6, y: 0.5, z: 0);
  landmarks[1] = FaceMeshLandmark(x: 0.5, y: 0.56, z: 0);
  landmarks[10] = FaceMeshLandmark(x: 0.5, y: 0.32, z: 0);
  landmarks[61] = FaceMeshLandmark(x: 0.45, y: 0.66, z: 0);
  landmarks[291] = FaceMeshLandmark(x: 0.55, y: 0.66, z: 0);
  return ArFaceResult(
    boundingBox: const FaceMeshBox(
      left: 300,
      top: 220,
      right: 700,
      bottom: 760,
    ),
    landmarks: landmarks,
    score: 1,
    imageSize: const Size(1000, 1000),
  );
}

Future<ui.Image> _testImage({required int width, required int height}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = Colors.white,
  );
  final picture = recorder.endRecording();
  return picture.toImage(width, height);
}
