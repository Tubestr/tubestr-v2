import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/marmot/message_models.dart';
import '../../domain/models/offline_action.dart';
import '../../domain/models/parent_identity.dart';
import '../blossom/blossom_client.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';
import '../offline/offline_action_store.dart';
import 'share_history_service.dart';

class VideoShareCoordinator {
  VideoShareCoordinator({
    required AppDatabase database,
    required BlossomClient blossomClient,
    required MdkService mdkService,
    required NostrService nostrService,
    required OfflineActionStore offlineActionStore,
    required ShareHistoryService shareHistoryService,
  }) : _blossomClient = blossomClient,
       _database = database,
       _mdkService = mdkService,
       _nostrService = nostrService,
       _offlineActionStore = offlineActionStore,
       _shareHistoryService = shareHistoryService;

  final BlossomClient _blossomClient;
  final AppDatabase _database;
  final MdkService _mdkService;
  final NostrService _nostrService;
  final OfflineActionStore _offlineActionStore;
  final ShareHistoryService _shareHistoryService;

  bool get isReady => [_blossomClient, _mdkService, _nostrService].length == 3;

  Future<List<MdkGroupSummary>> loadEligibleShareGroups() async {
    await warmUp();
    final groups = await _mdkService.getGroupSummaries();
    final seen = <String>{};
    return groups.where((group) {
      final normalizedId = group.mlsGroupIdHex.trim().toLowerCase();
      if (normalizedId.isEmpty || !seen.add(normalizedId)) {
        return false;
      }
      final normalizedName = group.name.trim().toLowerCase();
      if (normalizedName == AppConstants.safetyHqGroupName.toLowerCase()) {
        return false;
      }
      return group.memberCount > 1;
    }).toList(growable: false);
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
  }) {
    return VideoShareMessage(
      videoId: videoId,
      childProfileId: childProfileId,
      childDisplayName: childDisplayName,
      meta: VideoMeta(
        title: title,
        durationSeconds: durationSeconds,
        createdAt: mediaCreatedAt,
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
    await warmUp();

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

    final videoUpload = await _blossomClient.uploadEncryptedBlobWithMirrors(
      servers: configuredServers,
      bytes: videoEncrypted.encryptedBytes,
      mimeType: 'application/octet-stream',
      authForServer: (server) => _createBlossomUploadAuth(
        identity: identity,
        server: server,
        hashHex: videoEncrypted.encryptedHashHex,
      ),
    );
    final thumbUpload = await _blossomClient.uploadEncryptedBlobWithMirrors(
      servers: configuredServers,
      bytes: thumbEncrypted.encryptedBytes,
      mimeType: 'application/octet-stream',
      authForServer: (server) => _createBlossomUploadAuth(
        identity: identity,
        server: server,
        hashHex: thumbEncrypted.encryptedHashHex,
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

    final tagsJson = jsonEncode([
      _buildImetaTag(
        uploadedUrl: '${videoUpload.primaryServer}/${videoUpload.hash}',
        mimeType: videoEncrypted.mimeType,
        filename: videoEncrypted.filename,
        originalHashHex: videoEncrypted.originalHashHex,
        nonceHex: videoEncrypted.nonceHex,
        schemeVersion: videoEncrypted.schemeVersion,
      ),
      _buildImetaTag(
        uploadedUrl: '${thumbUpload.primaryServer}/${thumbUpload.hash}',
        mimeType: thumbEncrypted.mimeType,
        filename: thumbEncrypted.filename,
        originalHashHex: thumbEncrypted.originalHashHex,
        nonceHex: thumbEncrypted.nonceHex,
        schemeVersion: thumbEncrypted.schemeVersion,
      ),
    ]);

    return createDraftShareMessageEvent(
      mlsGroupIdHex: mlsGroupIdHex,
      senderPublicKeyHex: identity.publicKeyHex,
      payloadJson: augmentedPayload.encode(),
      tagsJson: tagsJson,
      createdAt: sharedAt,
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

  Future<String> shareLocalVideo({
    required ParentIdentity identity,
    required String videoId,
    required String profileId,
    required String childDisplayName,
    required String mlsGroupIdHex,
    bool allowQueueOnFailure = true,
  }) async {
    final localVideo = await _database.getLocalVideoById(videoId);
    if (localVideo == null) {
      throw StateError('Local video not found: $videoId');
    }
    try {
      final event = await createUploadedShareMessage(
        identity: identity,
        localVideo: localVideo,
        childDisplayName: childDisplayName,
        mlsGroupIdHex: mlsGroupIdHex,
      );
      final relays = await _nostrService.loadRelayList();
      final eventId = await publishSignedGroupMessage(
        identity: identity,
        signedEventJson: event.wrapperEventJson,
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

  Future<ShareDispatchResult> shareLocalVideoToEligibleGroups({
    required ParentIdentity identity,
    required String videoId,
    required String profileId,
    required String childDisplayName,
    bool allowQueueOnFailure = true,
  }) async {
    final groups = await loadEligibleShareGroups();
    if (groups.isEmpty) {
      throw StateError(
        'Join a family connection with at least one other parent before sharing.',
      );
    }

    final sharedGroupIds = <String>[];
    final queuedGroupIds = <String>[];
    final eventIds = <String>[];
    final errors = <String>[];

    for (final group in groups) {
      try {
        final eventId = await shareLocalVideo(
          identity: identity,
          videoId: videoId,
          profileId: profileId,
          childDisplayName: childDisplayName,
          mlsGroupIdHex: group.mlsGroupIdHex,
          allowQueueOnFailure: allowQueueOnFailure,
        );
        sharedGroupIds.add(group.mlsGroupIdHex);
        eventIds.add(eventId);
      } catch (error) {
        final message = '$error';
        if (message.startsWith('Share queued for retry:')) {
          queuedGroupIds.add(group.mlsGroupIdHex);
        }
        errors.add('${group.name}: $message');
      }
    }

    if (sharedGroupIds.isEmpty && queuedGroupIds.isEmpty) {
      throw StateError(errors.join('\n'));
    }

    return ShareDispatchResult(
      sharedGroupIds: sharedGroupIds,
      queuedGroupIds: queuedGroupIds,
      eventIds: eventIds,
      errors: errors,
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
    final expiresAt =
        DateTime.now()
            .add(const Duration(minutes: 10))
            .millisecondsSinceEpoch ~/
        1000;
    final eventJson = await _nostrService.createSignedEventJson(
      identity: identity,
      kind: 24242,
      content: 'Authorize Blossom upload',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: [
        ['t', 'upload'],
        ['x', hashHex],
        ['server', serverHost],
        ['u', uploadUrl],
        ['method', 'PUT'],
        ['expiration', '$expiresAt'],
      ],
    );
    final encoded = base64Url.encode(utf8.encode(eventJson)).replaceAll('=', '');
    return BlossomUploadAuth(
      authorizationHeaderValue: 'Nostr $encoded',
    );
  }
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
