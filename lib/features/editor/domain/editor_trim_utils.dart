import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/editor_session.dart';

class NormalizedEditorTrim {
  const NormalizedEditorTrim({
    required this.videoDuration,
    required this.trimRange,
    required this.sliderValues,
  });

  final Duration videoDuration;
  final EditorTrimRange trimRange;
  final RangeValues sliderValues;
}

NormalizedEditorTrim normalizeEditorTrim({
  required Duration rawVideoDuration,
  required EditorTrimRange rawTrimRange,
  Duration fallbackDuration = const Duration(seconds: 30),
}) {
  final safeDuration = rawVideoDuration > Duration.zero
      ? rawVideoDuration
      : fallbackDuration;
  final totalMs = math.max(safeDuration.inMilliseconds, 1);
  final minGapMs = totalMs < 250 ? 1 : 250;
  final maxStartMs = math.max(totalMs - minGapMs, 0);
  final startMs = rawTrimRange.start.inMilliseconds.clamp(0, maxStartMs);
  final endMs = rawTrimRange.end.inMilliseconds.clamp(
    startMs + minGapMs,
    totalMs,
  );

  return NormalizedEditorTrim(
    videoDuration: safeDuration,
    trimRange: EditorTrimRange(
      start: Duration(milliseconds: startMs),
      end: Duration(milliseconds: endMs),
    ),
    sliderValues: RangeValues(startMs / totalMs, endMs / totalMs),
  );
}
