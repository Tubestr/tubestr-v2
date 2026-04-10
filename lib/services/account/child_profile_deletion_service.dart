import 'dart:convert';

import '../../core/storage/app_database.dart';
import '../../domain/models/parent_identity.dart';
import '../blossom/blossom_client.dart';
import '../nostr/nostr_service.dart';
import '../share/managed_video_upload_service.dart';
import '../share/share_history_service.dart';

class ChildProfileDeletionResult {
  const ChildProfileDeletionResult({
    required this.deletedBlobCount,
    required this.retainedUploadCount,
    required this.failedDeleteCount,
    required this.usedManagedCleanup,
    required this.deletedProfile,
  });

  final int deletedBlobCount;
  final int retainedUploadCount;
  final int failedDeleteCount;
  final bool usedManagedCleanup;
  final bool deletedProfile;
}

class ChildProfileDeletionService {
  ChildProfileDeletionService({
    required AppDatabase database,
    required BlossomClient blossomClient,
    required NostrService nostrService,
    required ShareHistoryService shareHistoryService,
    required ManagedVideoUploadService managedVideoUploadService,
  }) : _database = database,
       _blossomClient = blossomClient,
       _nostrService = nostrService,
       _shareHistoryService = shareHistoryService,
       _managedVideoUploadService = managedVideoUploadService;

  final AppDatabase _database;
  final BlossomClient _blossomClient;
  final NostrService _nostrService;
  final ShareHistoryService _shareHistoryService;
  final ManagedVideoUploadService _managedVideoUploadService;

  Future<ChildProfileDeletionResult> deleteProfile({
    required String profileId,
    ParentIdentity? identity,
  }) async {
    final uploads = await _managedVideoUploadService.loadForProfile(profileId);
    final shareHistory = await _shareHistoryService.load();
    final deliveredVideoIds = shareHistory
        .where(
          (entry) =>
              entry.childProfileId == profileId && entry.status == 'sent',
        )
        .map((entry) => entry.videoId)
        .toSet();

    final retainedUploads = <ManagedVideoUploadRecord>[];
    final deletableTargets = <_DeleteTarget>[];
    var usedManagedCleanup = false;

    for (final upload in uploads) {
      final reportRetention = await _database
          .hasManagedDeletionRetentionEvidence(
            videoId: upload.videoId,
            blobHashes: <String>{upload.videoBlob.hash, upload.thumbBlob.hash},
          );
      if (deliveredVideoIds.contains(upload.videoId) || reportRetention) {
        retainedUploads.add(upload);
        continue;
      }
      usedManagedCleanup = true;
      deletableTargets.addAll(_deleteTargetsForUpload(upload));
    }

    var deletedBlobCount = 0;
    var failedDeleteCount = 0;
    if (identity != null) {
      for (final target in deletableTargets) {
        try {
          await _blossomClient.deleteBlob(
            server: target.server,
            hash: target.hash,
            auth: await _createDeleteAuth(
              identity: identity,
              server: target.server,
              hashHex: target.hash,
            ),
          );
          deletedBlobCount += 1;
        } catch (_) {
          failedDeleteCount += 1;
        }
      }
    } else if (deletableTargets.isNotEmpty) {
      failedDeleteCount = deletableTargets.length;
    }

    final deletedProfile = failedDeleteCount == 0;
    if (deletedProfile) {
      await _database.deleteProfileById(profileId);
      await _managedVideoUploadService.removeProfile(profileId);
    }

    return ChildProfileDeletionResult(
      deletedBlobCount: deletedBlobCount,
      retainedUploadCount: retainedUploads.length,
      failedDeleteCount: failedDeleteCount,
      usedManagedCleanup: usedManagedCleanup,
      deletedProfile: deletedProfile,
    );
  }

  List<_DeleteTarget> _deleteTargetsForUpload(ManagedVideoUploadRecord upload) {
    final seen = <String>{};
    final targets = <_DeleteTarget>[];
    for (final blob in <ManagedUploadedBlob>[
      upload.videoBlob,
      upload.thumbBlob,
    ]) {
      for (final server in blob.servers) {
        final normalized = server.trim();
        if (normalized.isEmpty) {
          continue;
        }
        final key = '${blob.hash}::$normalized';
        if (!seen.add(key)) {
          continue;
        }
        targets.add(_DeleteTarget(hash: blob.hash, server: normalized));
      }
    }
    return targets;
  }

  Future<BlossomUploadAuth> _createDeleteAuth({
    required ParentIdentity identity,
    required String server,
    required String hashHex,
  }) async {
    final normalized = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;
    final serverHost = Uri.parse(normalized).host.toLowerCase();
    final deleteUrl = '$normalized/$hashHex';
    final expiresAt =
        DateTime.now()
            .add(const Duration(minutes: 10))
            .millisecondsSinceEpoch ~/
        1000;
    final eventJson = await _nostrService.createSignedEventJson(
      identity: identity,
      kind: 24242,
      content: 'Authorize Blossom delete',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: [
        ['t', 'delete'],
        ['x', hashHex],
        ['server', serverHost],
        ['u', deleteUrl],
        ['method', 'DELETE'],
        ['expiration', '$expiresAt'],
      ],
    );
    final encoded = base64Url
        .encode(utf8.encode(eventJson))
        .replaceAll('=', '');
    return BlossomUploadAuth(authorizationHeaderValue: 'Nostr $encoded');
  }
}

class _DeleteTarget {
  const _DeleteTarget({required this.hash, required this.server});

  final String hash;
  final String server;
}
