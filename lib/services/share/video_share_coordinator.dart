import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/marmot/message_models.dart';
import '../../domain/models/offline_action.dart';
import '../../domain/models/parent_identity.dart';
import '../approval/video_approval_service.dart';
import '../blossom/blossom_client.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';
import '../offline/offline_action_store.dart';
import 'managed_video_upload_service.dart';
import 'share_history_service.dart';

const int _shareFanoutConcurrency = 4;

Future<List<R>> _runBounded<T, R>(
  List<T> items,
  int concurrency,
  Future<R> Function(T) task,
) async {
  if (items.isEmpty) return const <Never>[];
  final results = List<R?>.filled(items.length, null);
  final limit = concurrency.clamp(1, items.length);
  var next = 0;
  Future<void> worker() async {
    while (true) {
      final index = next++;
      if (index >= items.length) return;
      results[index] = await task(items[index]);
    }
  }

  await Future.wait(List.generate(limit, (_) => worker()));
  return results.cast<R>();
}

class _GroupShareAttempt {
  const _GroupShareAttempt._(this.group, this.eventId, this.error);
  factory _GroupShareAttempt.success(MdkGroupSummary group, String eventId) =>
      _GroupShareAttempt._(group, eventId, null);
  factory _GroupShareAttempt.failure(MdkGroupSummary group, String error) =>
      _GroupShareAttempt._(group, null, error);

  final MdkGroupSummary group;
  final String? eventId;
  final String? error;
}

class VideoShareCoordinator {
  VideoShareCoordinator({
    required AppDatabase database,
    required VideoApprovalService videoApprovalService,
    required BlossomClient blossomClient,
    required MdkService mdkService,
    required NostrService nostrService,
    required OfflineActionStore offlineActionStore,
    required ShareHistoryService shareHistoryService,
    required ManagedVideoUploadService managedVideoUploadService,
    Future<void> Function({
      required int sharedGroupCount,
      required int queuedGroupCount,
    })?
    onFirstPrivateShareSent,
  }) : _blossomClient = blossomClient,
       _database = database,
       _videoApprovalService = videoApprovalService,
       _mdkService = mdkService,
       _nostrService = nostrService,
       _offlineActionStore = offlineActionStore,
       _shareHistoryService = shareHistoryService,
       _managedVideoUploadService = managedVideoUploadService,
       _onFirstPrivateShareSent = onFirstPrivateShareSent;

  final BlossomClient _blossomClient;
  final AppDatabase _database;
  final VideoApprovalService _videoApprovalService;
  final MdkService _mdkService;
  final NostrService _nostrService;
  final OfflineActionStore _offlineActionStore;
  final ShareHistoryService _shareHistoryService;
  final ManagedVideoUploadService _managedVideoUploadService;
  final Future<void> Function({
    required int sharedGroupCount,
    required int queuedGroupCount,
  })?
  _onFirstPrivateShareSent;

  bool get isReady => [_blossomClient, _mdkService, _nostrService].length == 3;

  Future<List<MdkGroupSummary>> loadEligibleShareGroups() async {
    await warmUp();
    final groups = await _mdkService.getGroupSummaries();
    return _eligibleShareGroups(groups);
  }

  List<MdkGroupSummary> _eligibleShareGroups(List<MdkGroupSummary> groups) {
    final seen = <String>{};
    return groups
        .where((group) {
          final normalizedId = group.mlsGroupIdHex.trim().toLowerCase();
          if (normalizedId.isEmpty || !seen.add(normalizedId)) {
            return false;
          }
          final normalizedName = group.name.trim().toLowerCase();
          if (normalizedName == AppConstants.safetyHqGroupName.toLowerCase()) {
            return false;
          }
          return group.memberCount > 1 || _looksLikeConnectedFamilyGroup(group);
        })
        .toList(growable: false);
  }

  bool _looksLikeConnectedFamilyGroup(MdkGroupSummary group) {
    final normalizedName = group.name.trim().toLowerCase();
    final normalizedDescription = group.description.trim().toLowerCase();
    if (normalizedDescription.startsWith('connected ') ||
        normalizedDescription == 'created from scanned invite') {
      return true;
    }
    return normalizedName.contains(' & ');
  }

  Future<MdkGroupSummary?> _loadPrimaryGroupFallback({
    required String profileId,
    required List<MdkGroupSummary> groups,
  }) async {
    final primaryGroupId =
        await _database.getPrimaryGroupIdForProfile(profileId) ??
        await _database.getPrimaryGroupIdForAnyProfile();
    final normalizedPrimaryGroupId = primaryGroupId?.trim().toLowerCase();
    if (normalizedPrimaryGroupId == null || normalizedPrimaryGroupId.isEmpty) {
      return null;
    }

    for (final group in groups) {
      if (group.mlsGroupIdHex.trim().toLowerCase() !=
          normalizedPrimaryGroupId) {
        continue;
      }
      if (group.name.trim().toLowerCase() ==
          AppConstants.safetyHqGroupName.toLowerCase()) {
        return null;
      }
      return group;
    }

    return MdkGroupSummary(
      mlsGroupIdHex: primaryGroupId!.trim(),
      nostrGroupIdHex: '',
      name: 'Family connection',
      description: 'Local primary family connection',
      memberCount: 2,
      adminPubkeysHex: const <String>[],
    );
  }

  Future<void> warmUp() async {
    await _mdkService.ensureInitialized();
    await _nostrService.loadRelayList();
  }

  VideoShareMessage buildDraftShareMessage({
    required String videoId,
    required String childProfileId,
    required String childDisplayName,
    required String title,
    required double durationSeconds,
    required int mediaCreatedAt,
    required String blobHash,
    required List<String> blobServers,
    required String blobMime,
    required int blobLength,
    required String thumbHash,
    required List<String> thumbServers,
    required String thumbMime,
    required int thumbLength,
    required String epoch,
    required String by,
    required int sharedAt,
    int policyVersion = 2,
    int? expiresAt,
    double? aspectRatio,
  }) {
    return VideoShareMessage(
      videoId: videoId,
      childProfileId: childProfileId,
      childDisplayName: childDisplayName,
      meta: VideoMeta(
        title: title,
        durationSeconds: durationSeconds,
        createdAt: mediaCreatedAt,
        aspectRatio: aspectRatio,
      ),
      blob: BlobDescriptor(
        hash: blobHash,
        servers: blobServers,
        mime: blobMime,
        length: blobLength,
      ),
      thumb: BlobDescriptor(
        hash: thumbHash,
        servers: thumbServers,
        mime: thumbMime,
        length: thumbLength,
      ),
      media: MediaDescriptor(algorithm: 'mip04', epoch: epoch),
      policy: PolicyDescriptor(version: policyVersion, expiresAt: expiresAt),
      by: by,
      ts: sharedAt,
    );
  }

  String buildDraftSharePayloadJson({
    required String videoId,
    required String childProfileId,
    required String childDisplayName,
    required String title,
    required double durationSeconds,
    required int mediaCreatedAt,
    required String blobHash,
    required List<String> blobServers,
    required String blobMime,
    required int blobLength,
    required String thumbHash,
    required List<String> thumbServers,
    required String thumbMime,
    required int thumbLength,
    required String epoch,
    required String by,
    required int sharedAt,
    int policyVersion = 2,
    int? expiresAt,
    double? aspectRatio,
  }) {
    final message = buildDraftShareMessage(
      videoId: videoId,
      childProfileId: childProfileId,
      childDisplayName: childDisplayName,
      title: title,
      durationSeconds: durationSeconds,
      mediaCreatedAt: mediaCreatedAt,
      blobHash: blobHash,
      blobServers: blobServers,
      blobMime: blobMime,
      blobLength: blobLength,
      thumbHash: thumbHash,
      thumbServers: thumbServers,
      thumbMime: thumbMime,
      thumbLength: thumbLength,
      epoch: epoch,
      by: by,
      sharedAt: sharedAt,
      policyVersion: policyVersion,
      expiresAt: expiresAt,
      aspectRatio: aspectRatio,
    );
    return jsonEncode(message.toJson());
  }

  Future<MdkCreatedMessage> createDraftShareMessageEvent({
    required String mlsGroupIdHex,
    required String senderPublicKeyHex,
    required String payloadJson,
    String? tagsJson,
    int kind = MarmotKinds.videoShare,
    int? createdAt,
  }) {
    return _mdkService.createApplicationMessage(
      mlsGroupIdHex: mlsGroupIdHex,
      senderPublicKeyHex: senderPublicKeyHex,
      kind: kind,
      content: payloadJson,
      tagsJson: tagsJson,
      createdAt: createdAt,
    );
  }

  Future<String> publishSignedGroupMessage({
    required ParentIdentity identity,
    required String signedEventJson,
    List<String>? relays,
  }) {
    return _nostrService.publishSignedEventJson(
      identity: identity,
      eventJson: signedEventJson,
      relays: relays,
    );
  }

  Future<MdkCreatedMessage> createUploadedShareMessage({
    required ParentIdentity identity,
    required LocalVideo localVideo,
    required String childDisplayName,
    required String mlsGroupIdHex,
    List<String>? blossomServers,
  }) async {
    final prepared = await _prepareUploadedShare(
      identity: identity,
      localVideo: localVideo,
      childDisplayName: childDisplayName,
      mlsGroupIdHex: mlsGroupIdHex,
      blossomServers: blossomServers,
    );

    return createDraftShareMessageEvent(
      mlsGroupIdHex: mlsGroupIdHex,
      senderPublicKeyHex: identity.publicKeyHex,
      payloadJson: prepared.nativeContentJson,
      tagsJson: prepared.nativeTagsJson,
      createdAt: prepared.sharedAt,
    );
  }

  Future<CreatedVideoShareMessages> createUploadedShareMessages({
    required ParentIdentity identity,
    required LocalVideo localVideo,
    required String childDisplayName,
    required String mlsGroupIdHex,
    List<String>? blossomServers,
  }) async {
    final prepared = await _prepareUploadedShare(
      identity: identity,
      localVideo: localVideo,
      childDisplayName: childDisplayName,
      mlsGroupIdHex: mlsGroupIdHex,
      blossomServers: blossomServers,
    );

    final nativeShare = await createDraftShareMessageEvent(
      mlsGroupIdHex: mlsGroupIdHex,
      senderPublicKeyHex: identity.publicKeyHex,
      payloadJson: prepared.nativeContentJson,
      tagsJson: prepared.nativeTagsJson,
      createdAt: prepared.sharedAt,
    );
    final whiteNoiseCompanion = await createDraftShareMessageEvent(
      mlsGroupIdHex: mlsGroupIdHex,
      senderPublicKeyHex: identity.publicKeyHex,
      payloadJson: prepared.whiteNoiseContent,
      tagsJson: _buildWhiteNoiseCompanionTagsJson(
        videoImetaTag: prepared.videoImetaTag,
        videoId: localVideo.id,
        senderPublicKeyHex: identity.publicKeyHex,
        nativeRumorEventIdHex: nativeShare.rumorEventIdHex,
      ),
      kind: MarmotKinds.chatMessage,
      createdAt: prepared.sharedAt,
    );

    return CreatedVideoShareMessages(
      nativeShare: nativeShare,
      whiteNoiseCompanion: whiteNoiseCompanion,
    );
  }

  Future<_PreparedUploadedShare> _prepareUploadedShare({
    required ParentIdentity identity,
    required LocalVideo localVideo,
    required String childDisplayName,
    required String mlsGroupIdHex,
    List<String>? blossomServers,
  }) async {
    await _mdkService.ensureInitialized();

    if (localVideo.approvalStatus != 'approved') {
      throw StateError(
        'This video still needs parent approval before it can be shared.',
      );
    }

    final videoFile = File(localVideo.filePath);
    if (!videoFile.existsSync()) {
      throw StateError('Local video file is missing: ${localVideo.filePath}');
    }
    final thumbFile = File(localVideo.thumbPath);
    if (!thumbFile.existsSync()) {
      throw StateError(
        'Local video thumbnail is missing: ${localVideo.thumbPath}',
      );
    }
    final configuredServers = blossomServers == null || blossomServers.isEmpty
        ? await _nostrService.loadBlossomServerList()
        : blossomServers;
    if (configuredServers.isEmpty) {
      throw StateError('At least one Blossom server is required.');
    }

    final videoEncrypted = await _mdkService.encryptMedia(
      mlsGroupIdHex: mlsGroupIdHex,
      bytes: await videoFile.readAsBytes(),
      mimeType: 'video/mp4',
      filename: p.basename(localVideo.filePath),
    );
    final thumbEncrypted = await _mdkService.encryptMedia(
      mlsGroupIdHex: mlsGroupIdHex,
      bytes: await thumbFile.readAsBytes(),
      mimeType: 'image/jpeg',
      filename: p.basename(localVideo.thumbPath),
    );
    final videoEncryptedBlobHash = sha256
        .convert(videoEncrypted.encryptedBytes)
        .toString();
    final thumbEncryptedBlobHash = sha256
        .convert(thumbEncrypted.encryptedBytes)
        .toString();

    final videoUpload = await _blossomClient.uploadEncryptedBlobWithMirrors(
      servers: configuredServers,
      bytes: videoEncrypted.encryptedBytes,
      mimeType: 'application/octet-stream',
      authForServer: (server) => _createBlossomUploadAuth(
        identity: identity,
        server: server,
        hashHex: videoEncryptedBlobHash,
      ),
    );
    final thumbUpload = await _blossomClient.uploadEncryptedBlobWithMirrors(
      servers: configuredServers,
      bytes: thumbEncrypted.encryptedBytes,
      mimeType: 'application/octet-stream',
      authForServer: (server) => _createBlossomUploadAuth(
        identity: identity,
        server: server,
        hashHex: thumbEncryptedBlobHash,
      ),
    );
    final sharedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final sharePayload = buildDraftSharePayloadJson(
      videoId: localVideo.id,
      childProfileId: localVideo.profileId,
      childDisplayName: childDisplayName,
      title: localVideo.title,
      durationSeconds: localVideo.durationSeconds,
      mediaCreatedAt: localVideo.createdAt.millisecondsSinceEpoch ~/ 1000,
      blobHash: videoUpload.hash,
      blobServers: videoUpload.servers,
      blobMime: videoEncrypted.mimeType,
      blobLength: videoUpload.length,
      thumbHash: thumbUpload.hash,
      thumbServers: thumbUpload.servers,
      thumbMime: thumbEncrypted.mimeType,
      thumbLength: thumbUpload.length,
      epoch: videoEncrypted.epoch.toString(),
      by: identity.publicKeyHex,
      sharedAt: sharedAt,
      aspectRatio: localVideo.aspectRatio,
    );

    final payload = VideoShareMessage.decode(sharePayload);
    final augmentedPayload = VideoShareMessage(
      videoId: payload.videoId,
      childProfileId: payload.childProfileId,
      childDisplayName: payload.childDisplayName,
      meta: payload.meta,
      blob: BlobDescriptor(
        hash: payload.blob.hash,
        servers: payload.blob.servers,
        mime: payload.blob.mime,
        length: payload.blob.length,
        originalHash: videoEncrypted.originalHashHex,
        nonce: videoEncrypted.nonceHex,
        filename: videoEncrypted.filename,
        schemeVersion: videoEncrypted.schemeVersion,
      ),
      thumb: BlobDescriptor(
        hash: payload.thumb.hash,
        servers: payload.thumb.servers,
        mime: payload.thumb.mime,
        length: payload.thumb.length,
        originalHash: thumbEncrypted.originalHashHex,
        nonce: thumbEncrypted.nonceHex,
        filename: thumbEncrypted.filename,
        schemeVersion: thumbEncrypted.schemeVersion,
      ),
      media: payload.media,
      policy: payload.policy,
      by: payload.by,
      ts: payload.ts,
    );

    final videoImetaTag = _buildImetaTag(
      uploadedUrl: '${videoUpload.primaryServer}/${videoUpload.hash}',
      mimeType: videoEncrypted.mimeType,
      filename: videoEncrypted.filename,
      originalHashHex: videoEncrypted.originalHashHex,
      nonceHex: videoEncrypted.nonceHex,
      schemeVersion: videoEncrypted.schemeVersion,
    );

    final tagsJson = jsonEncode([
      videoImetaTag,
      _buildImetaTag(
        uploadedUrl: '${thumbUpload.primaryServer}/${thumbUpload.hash}',
        mimeType: thumbEncrypted.mimeType,
        filename: thumbEncrypted.filename,
        originalHashHex: thumbEncrypted.originalHashHex,
        nonceHex: thumbEncrypted.nonceHex,
        schemeVersion: thumbEncrypted.schemeVersion,
      ),
    ]);

    await _managedVideoUploadService.recordUpload(
      videoId: localVideo.id,
      profileId: localVideo.profileId,
      videoBlob: ManagedUploadedBlob(
        hash: videoUpload.hash,
        servers: videoUpload.servers,
      ),
      thumbBlob: ManagedUploadedBlob(
        hash: thumbUpload.hash,
        servers: thumbUpload.servers,
      ),
    );

    return _PreparedUploadedShare(
      nativeContentJson: augmentedPayload.encode(),
      nativeTagsJson: tagsJson,
      videoImetaTag: videoImetaTag,
      whiteNoiseContent: _buildWhiteNoiseVideoShareContent(
        localVideo: localVideo,
        childDisplayName: childDisplayName,
      ),
      sharedAt: sharedAt,
    );
  }

  List<String> _buildImetaTag({
    required String uploadedUrl,
    required String mimeType,
    required String filename,
    required String originalHashHex,
    required String nonceHex,
    required String schemeVersion,
  }) {
    return [
      'imeta',
      'url $uploadedUrl',
      'm $mimeType',
      'filename $filename',
      'x $originalHashHex',
      'n $nonceHex',
      'v $schemeVersion',
    ];
  }

  String _buildWhiteNoiseCompanionTagsJson({
    required List<String> videoImetaTag,
    required String videoId,
    required String senderPublicKeyHex,
    required String nativeRumorEventIdHex,
  }) {
    final tags = <List<String>>[
      List<String>.from(videoImetaTag),
      ['client', AppConstants.appName],
      ['tubestr', 'video_share', videoId],
    ];
    final normalizedNativeId = nativeRumorEventIdHex.trim();
    if (normalizedNativeId.isNotEmpty) {
      tags.add(['q', normalizedNativeId, '', senderPublicKeyHex]);
    }
    return jsonEncode(tags);
  }

  String _buildWhiteNoiseVideoShareContent({
    required LocalVideo localVideo,
    required String childDisplayName,
  }) {
    final childName = childDisplayName.trim();
    final title = localVideo.title.trim();
    if (childName.isEmpty && title.isEmpty) {
      return 'Shared a Tubestr video';
    }
    if (childName.isEmpty) {
      return 'Shared a Tubestr video: $title';
    }
    if (title.isEmpty) {
      return '$childName shared a Tubestr video';
    }
    return '$childName shared a Tubestr video: $title';
  }

  Future<String> shareLocalVideo({
    required ParentIdentity identity,
    required String videoId,
    required String profileId,
    required String childDisplayName,
    required String mlsGroupIdHex,
    bool allowQueueOnFailure = true,
    List<String>? preloadedRelays,
    List<String>? preloadedBlossomServers,
  }) async {
    var localVideo = await _database.getLocalVideoById(videoId);
    if (localVideo == null) {
      throw StateError('Local video not found: $videoId');
    }
    if (localVideo.scanCompletedAt == null ||
        localVideo.scanResults == null ||
        localVideo.scanResults!.isEmpty) {
      await _videoApprovalService.scanAndClassifyVideo(videoId: videoId);
      localVideo = await _database.getLocalVideoById(videoId);
      if (localVideo == null) {
        throw StateError('Local video disappeared before sharing: $videoId');
      }
    }
    try {
      final messages = await createUploadedShareMessages(
        identity: identity,
        localVideo: localVideo,
        childDisplayName: childDisplayName,
        mlsGroupIdHex: mlsGroupIdHex,
        blossomServers: preloadedBlossomServers,
      );
      final relays = preloadedRelays ?? await _nostrService.loadRelayList();
      final eventId = await publishSignedGroupMessage(
        identity: identity,
        signedEventJson: messages.nativeShare.wrapperEventJson,
        relays: relays,
      );
      await _publishWhiteNoiseCompanionBestEffort(
        identity: identity,
        signedEventJson: messages.whiteNoiseCompanion.wrapperEventJson,
        relays: relays,
      );
      await _shareHistoryService.recordSent(
        videoId: localVideo.id,
        title: localVideo.title,
        childProfileId: profileId,
        childDisplayName: childDisplayName,
        mlsGroupId: mlsGroupIdHex,
        eventId: eventId,
      );
      return eventId;
    } catch (error) {
      if (allowQueueOnFailure) {
        await _offlineActionStore.enqueue(
          type: OfflineActionType.shareVideo,
          payload: <String, dynamic>{
            'video_id': videoId,
            'profile_id': profileId,
            'child_display_name': childDisplayName,
            'mls_group_id': mlsGroupIdHex,
          },
        );
        await _shareHistoryService.recordQueued(
          videoId: videoId,
          title: localVideo.title,
          childProfileId: profileId,
          childDisplayName: childDisplayName,
          mlsGroupId: mlsGroupIdHex,
          error: '$error',
        );
        throw StateError('Share queued for retry: $error');
      }
      rethrow;
    }
  }

  Future<void> _publishWhiteNoiseCompanionBestEffort({
    required ParentIdentity identity,
    required String signedEventJson,
    List<String>? relays,
  }) async {
    try {
      await publishSignedGroupMessage(
        identity: identity,
        signedEventJson: signedEventJson,
        relays: relays,
      );
    } catch (_) {
      // The native share is already delivered; WhiteNoise interop is best-effort.
    }
  }

  Future<ShareDispatchResult> shareLocalVideoToEligibleGroups({
    required ParentIdentity identity,
    required String videoId,
    required String profileId,
    required String childDisplayName,
    bool allowQueueOnFailure = true,
  }) async {
    await warmUp();
    final summaries = await _mdkService.getGroupSummaries();
    var groups = _eligibleShareGroups(summaries);
    if (groups.isEmpty) {
      final fallback = await _loadPrimaryGroupFallback(
        profileId: profileId,
        groups: summaries,
      );
      if (fallback != null) {
        groups = [fallback];
      }
    }
    if (groups.isEmpty) {
      throw StateError(
        'Join a family connection with at least one other parent before sharing.',
      );
    }

    // Hoist per-share DB lookups out of the fanout — one read for N groups.
    final preloadedRelays = await _nostrService.loadRelayList();
    final preloadedBlossomServers = await _nostrService.loadBlossomServerList();

    final sharedGroupIds = <String>[];
    final queuedGroupIds = <String>[];
    final eventIds = <String>[];
    final errors = <String>[];

    final attempts = await _runBounded<MdkGroupSummary, _GroupShareAttempt>(
      groups,
      _shareFanoutConcurrency,
      (group) async {
        try {
          final eventId = await shareLocalVideo(
            identity: identity,
            videoId: videoId,
            profileId: profileId,
            childDisplayName: childDisplayName,
            mlsGroupIdHex: group.mlsGroupIdHex,
            allowQueueOnFailure: allowQueueOnFailure,
            preloadedRelays: preloadedRelays,
            preloadedBlossomServers: preloadedBlossomServers,
          );
          return _GroupShareAttempt.success(group, eventId);
        } catch (error) {
          return _GroupShareAttempt.failure(group, '$error');
        }
      },
    );

    for (final attempt in attempts) {
      if (attempt.eventId != null) {
        sharedGroupIds.add(attempt.group.mlsGroupIdHex);
        eventIds.add(attempt.eventId!);
      } else {
        final message = attempt.error ?? 'Unknown error';
        if (message.startsWith('Share queued for retry:')) {
          queuedGroupIds.add(attempt.group.mlsGroupIdHex);
        }
        errors.add('${attempt.group.name}: $message');
      }
    }

    if (sharedGroupIds.isEmpty && queuedGroupIds.isEmpty) {
      throw StateError(errors.join('\n'));
    }

    final result = ShareDispatchResult(
      sharedGroupIds: sharedGroupIds,
      queuedGroupIds: queuedGroupIds,
      eventIds: eventIds,
      errors: errors,
    );
    if (result.sharedGroupCount > 0 && _onFirstPrivateShareSent != null) {
      unawaited(
        _onFirstPrivateShareSent(
          sharedGroupCount: result.sharedGroupCount,
          queuedGroupCount: result.queuedGroupCount,
        ),
      );
    }
    return result;
  }

  /// Optimistic fanout: resolve eligible groups, scan once upfront, enqueue one
  /// offline share action per group, return immediately. Callers are expected
  /// to trigger [OfflineActionProcessor.flush] so the queue drains right away
  /// instead of waiting for the next connectivity/resume tick.
  Future<ShareDispatchResult> queueShareToEligibleGroups({
    required ParentIdentity identity,
    required String videoId,
    required String profileId,
    required String childDisplayName,
  }) async {
    await warmUp();
    final summaries = await _mdkService.getGroupSummaries();
    var groups = _eligibleShareGroups(summaries);
    if (groups.isEmpty) {
      final fallback = await _loadPrimaryGroupFallback(
        profileId: profileId,
        groups: summaries,
      );
      if (fallback != null) {
        groups = [fallback];
      }
    }
    if (groups.isEmpty) {
      throw StateError(
        'Join a family connection with at least one other parent before sharing.',
      );
    }

    // Scan once upfront so parallel workers don't race on an unscanned video.
    var localVideo = await _database.getLocalVideoById(videoId);
    if (localVideo == null) {
      throw StateError('Local video not found: $videoId');
    }
    if (localVideo.scanCompletedAt == null ||
        localVideo.scanResults == null ||
        localVideo.scanResults!.isEmpty) {
      await _videoApprovalService.scanAndClassifyVideo(videoId: videoId);
      localVideo = await _database.getLocalVideoById(videoId);
      if (localVideo == null) {
        throw StateError('Local video disappeared before sharing: $videoId');
      }
    }
    if (localVideo.approvalStatus != 'approved') {
      throw StateError(
        'This video still needs parent approval before it can be shared.',
      );
    }

    final queuedGroupIds = <String>[];
    for (final group in groups) {
      await _offlineActionStore.enqueue(
        type: OfflineActionType.shareVideo,
        payload: <String, dynamic>{
          'video_id': videoId,
          'profile_id': profileId,
          'child_display_name': childDisplayName,
          'mls_group_id': group.mlsGroupIdHex,
        },
      );
      queuedGroupIds.add(group.mlsGroupIdHex);
    }

    return ShareDispatchResult(
      sharedGroupIds: const <String>[],
      queuedGroupIds: queuedGroupIds,
      eventIds: const <String>[],
      errors: const <String>[],
    );
  }

  Future<BlossomUploadAuth> _createBlossomUploadAuth({
    required ParentIdentity identity,
    required String server,
    required String hashHex,
  }) async {
    final normalized = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;
    final serverHost = Uri.parse(normalized).host.toLowerCase();
    final uploadUrl = '$normalized/upload';
    final authCreatedAt = DateTime.now().subtract(const Duration(minutes: 5));
    final expiresAt =
        DateTime.now()
            .add(const Duration(minutes: 10))
            .millisecondsSinceEpoch ~/
        1000;
    final eventJson = await _nostrService.createSignedEventJson(
      identity: identity,
      kind: 24242,
      content: 'Authorize Blossom upload',
      createdAt: authCreatedAt.millisecondsSinceEpoch ~/ 1000,
      tags: [
        ['t', 'upload'],
        ['x', hashHex],
        ['server', serverHost],
        ['u', uploadUrl],
        ['method', 'PUT'],
        ['expiration', '$expiresAt'],
      ],
    );
    final encoded = base64Url
        .encode(utf8.encode(eventJson))
        .replaceAll('=', '');
    return BlossomUploadAuth(authorizationHeaderValue: 'Nostr $encoded');
  }
}

class CreatedVideoShareMessages {
  const CreatedVideoShareMessages({
    required this.nativeShare,
    required this.whiteNoiseCompanion,
  });

  final MdkCreatedMessage nativeShare;
  final MdkCreatedMessage whiteNoiseCompanion;
}

class _PreparedUploadedShare {
  const _PreparedUploadedShare({
    required this.nativeContentJson,
    required this.nativeTagsJson,
    required this.videoImetaTag,
    required this.whiteNoiseContent,
    required this.sharedAt,
  });

  final String nativeContentJson;
  final String nativeTagsJson;
  final List<String> videoImetaTag;
  final String whiteNoiseContent;
  final int sharedAt;
}

class ShareDispatchResult {
  const ShareDispatchResult({
    required this.sharedGroupIds,
    required this.queuedGroupIds,
    required this.eventIds,
    required this.errors,
  });

  final List<String> sharedGroupIds;
  final List<String> queuedGroupIds;
  final List<String> eventIds;
  final List<String> errors;

  int get sharedGroupCount => sharedGroupIds.length;
  int get queuedGroupCount => queuedGroupIds.length;
}
