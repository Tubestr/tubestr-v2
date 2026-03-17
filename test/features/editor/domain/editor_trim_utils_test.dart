import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/models/editor_session.dart';
import 'package:mytube/features/editor/domain/editor_trim_utils.dart';

void main() {
  test(
    'normalizeEditorTrim falls back when clip duration metadata is missing',
    () {
      final normalized = normalizeEditorTrim(
        rawVideoDuration: Duration.zero,
        rawTrimRange: const EditorTrimRange(
          start: Duration.zero,
          end: Duration(seconds: 30),
        ),
      );

      expect(normalized.videoDuration, const Duration(seconds: 30));
      expect(normalized.sliderValues.start, 0);
      expect(normalized.sliderValues.end, 1);
    },
  );

  test('normalizeEditorTrim clamps out-of-range trim values safely', () {
    final normalized = normalizeEditorTrim(
      rawVideoDuration: const Duration(seconds: 10),
      rawTrimRange: const EditorTrimRange(
        start: Duration(seconds: 12),
        end: Duration(seconds: 30),
      ),
    );

    expect(normalized.trimRange.start, const Duration(milliseconds: 9750));
    expect(normalized.trimRange.end, const Duration(seconds: 10));
    expect(normalized.sliderValues.start, closeTo(0.975, 0.0001));
    expect(normalized.sliderValues.end, 1);
  });
}
