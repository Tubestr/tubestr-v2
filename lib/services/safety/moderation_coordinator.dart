import 'dart:convert';
import 'dart:io';

import '../../core/storage/app_database.dart';
import '../../domain/models/parent_identity.dart';
import '../../domain/models/remote_share_projection.dart';
import '../blossom/blossom_client.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';
import '../share/video_lifecycle_coordinator.dart';

class ModerationCoordinator {
  ModerationCoordinator({
    required AppDatabase database,
    required BlossomClient blossomClient,
    required MdkService mdkService,
    required NostrService nostrService,
    required VideoLifecycleCoordinator videoLifecycleCoordinator,
  }) : _database = database,
       _blossomClient = blossomClient,
       _mdkService = mdkService,
       _nostrService = nostrService,
       _videoLifecycleCoordinator = videoLifecycleCoordinator;

  final AppDatabase _database;
  final BlossomClient _blossomClient;
  final MdkService _mdkService;
  final NostrService _nostrService;
  final VideoLifecycleCoordinator _videoLifecycleCoordinator;

  Future<List<String>> loadGroupMembers({
    required String mlsGroupIdHex,
  }) {
    return _mdkService.getGroupMembers(mlsGroupIdHex: mlsGroupIdHex);
  }

  Future<void> removeMember({
    required ParentIdentity identity,
    required String mlsGroupIdHex,
    required String memberPubkeyHex,
    String? reason,
  }) async {
    final update = await _mdkService.removeGroupMembers(
      mlsGroupIdHex: mlsGroupIdHex,
      memberPubkeysHex: [memberPubkeyHex],
    );
    final relays = await _nostrService.loadRelayList();
    await _nostrService.publishSignedEventJson(
      identity: identity,
      eventJson: update.wrapperEventJson,
      relays: relays,
    );
    await _database.addModerationAuditLog(
      mlsGroupId: mlsGroupIdHex,
      actionType: 'remove_member',
      actorParentKey: identity.publicKeyHex,
      subjectParentKey: memberPubkeyHex,
      detailsJson: jsonEncode({
        'reason': reason,
        'wrapper_event_id': update.wrapperEventIdHex,
      }),
    );
  }

  Future<void> deleteSharedVideo({
    required ParentIdentity identity,
    required RemoteShareProjection projection,
    String? reason,
  }) async {
    final blobHash = projection.blobHash;
    if (blobHash == null || blobHash.isEmpty) {
      throw StateError('Shared video is missing a blob hash.');
    }

    await _videoLifecycleCoordinator.publishDelete(
      identity: identity,
      mlsGroupIdHex: projection.mlsGroupId,
      videoId: projection.videoId,
      blobHash: blobHash,
      reason: reason,
    );
    await _reportBlobAbuse(
      identity: identity,
      projection: projection,
      blobHash: blobHash,
      reason: reason,
    );
    await _deleteLocalCacheFiles(projection);
    await _database.purgeRemoteAssetCache(videoId: projection.videoId);
    await _database.markRemoteShareDeleted(
      videoId: projection.videoId,
      reason: reason ?? 'moderation_delete',
    );
    await _database.addModerationAuditLog(
      videoId: projection.videoId,
      mlsGroupId: projection.mlsGroupId,
      actionType: 'delete_video',
      actorParentKey: identity.publicKeyHex,
      subjectParentKey: projection.senderParentKey,
      detailsJson: jsonEncode({
        'reason': reason,
        'blob_hash': blobHash,
      }),
    );
  }

  Future<void> _deleteLocalCacheFiles(RemoteShareProjection projection) async {
    final candidates = [
      projection.localMediaPath,
      projection.localThumbPath,
    ].whereType<String>().where((path) => path.isNotEmpty);

    for (final path in candidates) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _reportBlobAbuse({
    required ParentIdentity identity,
    required RemoteShareProjection projection,
    required String blobHash,
    String? reason,
  }) async {
    final servers = await _resolveReportServers(projection);
    if (servers.isEmpty) {
      return;
    }

    final eventJson = await _nostrService.createSignedEventJson(
      identity: identity,
      kind: 1984,
      tags: [
        ['x', blobHash, reason ?? 'inappropriate'],
      ],
      content: reason ?? 'MyTube moderation delete',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    for (final server in servers) {
      try {
        await _blossomClient.reportBlob(server: server, eventJson: eventJson);
      } catch (_) {
        // Best-effort BUD-09 reporting. App-level lifecycle/report state remains authoritative.
      }
    }
  }

  Future<List<String>> _resolveReportServers(RemoteShareProjection projection) async {
    final shareMessage = projection.shareMessage;
    final snapshotServers = shareMessage?.blob.servers ?? const <String>[];
    if (snapshotServers.isNotEmpty) {
      return snapshotServers;
    }
    return _nostrService.fetchBlossomServerList(
      publicKeyHex: projection.senderParentKey,
    );
  }
}
