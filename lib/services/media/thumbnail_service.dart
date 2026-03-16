import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailService {
  Future<String?> createVideoThumbnail({
    required String videoPath,
  }) async {
    if (videoPath.isEmpty) {
      return null;
    }

    final root = await getApplicationDocumentsDirectory();
    final thumbnailsDir = Directory(p.join(root.path, 'thumbnails'));
    await thumbnailsDir.create(recursive: true);

    return VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: thumbnailsDir.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 360,
      quality: 75,
      timeMs: 500,
    );
  }
}
