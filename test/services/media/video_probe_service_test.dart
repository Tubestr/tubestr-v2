import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/services/media/video_probe_service.dart';

void main() {
  test('parseVideoProbeJson reads rotation from side data', () {
    const json = '''
{
  "streams": [
    {
      "index": 0,
      "codec_type": "video",
      "width": 1280,
      "height": 720,
      "side_data_list": [
        {
          "side_data_type": "Display Matrix",
          "rotation": -90
        }
      ]
    },
    {
      "index": 1,
      "codec_type": "audio"
    }
  ]
}
''';

    final result = parseVideoProbeJson(json);

    expect(result, isNotNull);
    expect(result!.encodedSize.width, 1280);
    expect(result.encodedSize.height, 720);
    expect(result.rotationDegrees, -90);
    expect(result.hasAudio, isTrue);
    expect(result.displaySize.width, 720);
    expect(result.displaySize.height, 1280);
  });

  test('parseVideoProbeJson prefers reported display aspect ratio', () {
    const json = '''
{
  "streams": [
    {
      "index": 0,
      "codec_type": "video",
      "width": 1280,
      "height": 720,
      "display_aspect_ratio": "9:16",
      "tags": {
        "rotate": "90"
      }
    }
  ]
}
''';

    final result = parseVideoProbeJson(json);

    expect(result, isNotNull);
    expect(result!.rotationDegrees, 90);
    expect(result.reportedDisplayAspectRatio, closeTo(9 / 16, 0.0001));
    expect(result.displayAspectRatio, closeTo(9 / 16, 0.0001));
    expect(result.displaySize.width, 720);
    expect(result.displaySize.height, 1280);
  });
}
