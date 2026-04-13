import '../../../core/storage/app_database.dart';
import '../../../domain/models/remote_share_projection.dart';

/// Lightweight value object carrying everything the editor needs to open a
/// video for remixing. Decouples the editor from the specific data-layer type
/// ([LocalVideo] vs [RemoteShareProjection]).
class EditorSource {
  const EditorSource({
    required this.id,
    required this.profileId,
    required this.filePath,
    required this.thumbPath,
    required this.title,
    required this.durationSeconds,
  });

  factory EditorSource.fromLocalVideo(LocalVideo v) => EditorSource(
    id: v.id,
    profileId: v.profileId,
    filePath: v.filePath,
    thumbPath: v.thumbPath,
    title: v.title,
    durationSeconds: v.durationSeconds,
  );

  factory EditorSource.fromRemoteShare(
    RemoteShareProjection r, {
    required String profileId,
  }) => EditorSource(
    id: r.remoteShareId,
    profileId: profileId,
    filePath: r.localMediaPath!,
    thumbPath: r.localThumbPath ?? '',
    title: r.title,
    durationSeconds: 0,
  );

  final String id;
  final String profileId;
  final String filePath;
  final String thumbPath;
  final String title;
  final double durationSeconds;
}
