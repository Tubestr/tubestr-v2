import 'dart:io';

import '../marmot/message_models.dart';

class RemoteShareProjection {
  const RemoteShareProjection({
    required this.remoteShareId,
    required this.videoId,
    required this.mlsGroupId,
    required this.senderParentKey,
    required this.childProfileId,
    required this.childDisplayName,
    required this.status,
    required this.receivedAt,
    required this.downloadError,
    required this.blobHash,
    required this.thumbHash,
    required this.epoch,
    required this.mime,
    required this.metadataJson,
    required this.localMediaPath,
    required this.localThumbPath,
  });

  final String remoteShareId;
  final String videoId;
  final String mlsGroupId;
  final String senderParentKey;
  final String childProfileId;
  final String? childDisplayName;
  final String status;
  final DateTime receivedAt;
  final String? downloadError;
  final String? blobHash;
  final String? thumbHash;
  final String? epoch;
  final String? mime;
  final String? metadataJson;
  final String? localMediaPath;
  final String? localThumbPath;

  VideoShareMessage? get shareMessage {
    final raw = metadataJson;
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return VideoShareMessage.decode(raw);
    } catch (_) {
      return null;
    }
  }

  String get title => shareMessage?.meta.title ?? 'Shared video';

  String get displayName => childDisplayName ?? 'Friend';

  bool get isDownloaded {
    final path = localMediaPath;
    if (path == null || path.isEmpty) {
      return false;
    }
    final file = File(path);
    return file.existsSync() && file.lengthSync() > 0;
  }

  bool get hasThumbnail {
    final path = localThumbPath;
    if (path == null || path.isEmpty) {
      return false;
    }
    final file = File(path);
    return file.existsSync() && file.lengthSync() > 0;
  }
}
