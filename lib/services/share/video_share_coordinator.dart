import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/marmot/message_models.dart';
import '../../domain/models/parent_identity.dart';
import '../blossom/blossom_client.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';

class VideoShareCoordinator {
  VideoShareCoordinator({
    required BlossomClient blossomClient,
    required MdkService mdkService,
    required NostrService nostrService,
  })  : _blossomClient = blossomClient,
        _mdkService = mdkService,
        _nostrService = nostrService;

  final BlossomClient _blossomClient;
  final MdkService _mdkService;
  final NostrService _nostrService;

  bool get isReady => [_blossomClient, _mdkService, _nostrService].length == 3;

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
    required int createdAt,
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
        createdAt: createdAt,
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
      media: MediaDescriptor(
        algorithm: 'mip04',
        epoch: epoch,
      ),
      policy: PolicyDescriptor(
        version: policyVersion,
        expiresAt: expiresAt,
      ),
      by: by,
      ts: createdAt,
    );
  }

  String buildDraftSharePayloadJson({
    required String videoId,
    required String childProfileId,
    required String childDisplayName,
    required String title,
    required double durationSeconds,
    required int createdAt,
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
    int policyVersion = 2,
    int? expiresAt,
  }) {
    final message = buildDraftShareMessage(
      videoId: videoId,
      childProfileId: childProfileId,
      childDisplayName: childDisplayName,
      title: title,
      durationSeconds: durationSeconds,
      createdAt: createdAt,
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

    final videoFile = File(localVideo.filePath);
    if (!videoFile.existsSync()) {
      throw StateError('Local video file is missing: ${localVideo.filePath}');
    }
    final thumbFile = File(localVideo.thumbPath);
    if (!thumbFile.existsSync()) {
      throw StateError('Local video thumbnail is missing: ${localVideo.thumbPath}');
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

    final primaryServer = configuredServers.first;
    final videoUpload = await _blossomClient.uploadEncryptedBlob(
      server: primaryServer,
      bytes: videoEncrypted.encryptedBytes,
      mimeType: 'application/octet-stream',
    );
    final thumbUpload = await _blossomClient.uploadEncryptedBlob(
      server: primaryServer,
      bytes: thumbEncrypted.encryptedBytes,
      mimeType: 'application/octet-stream',
    );

    final sharePayload = buildDraftSharePayloadJson(
      videoId: localVideo.id,
      childProfileId: localVideo.profileId,
      childDisplayName: childDisplayName,
      title: localVideo.title,
      durationSeconds: localVideo.durationSeconds,
      createdAt: localVideo.createdAt.millisecondsSinceEpoch ~/ 1000,
      blobHash: videoUpload.hash,
      blobServers: configuredServers,
      blobMime: videoEncrypted.mimeType,
      blobLength: videoUpload.length,
      thumbHash: thumbUpload.hash,
      thumbServers: configuredServers,
      thumbMime: thumbEncrypted.mimeType,
      thumbLength: thumbUpload.length,
      epoch: videoEncrypted.epoch.toString(),
      by: identity.publicKeyHex,
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
        uploadedUrl: '${videoUpload.server}/${videoUpload.hash}',
        mimeType: videoEncrypted.mimeType,
        filename: videoEncrypted.filename,
        originalHashHex: videoEncrypted.originalHashHex,
        nonceHex: videoEncrypted.nonceHex,
        schemeVersion: videoEncrypted.schemeVersion,
      ),
      _buildImetaTag(
        uploadedUrl: '${thumbUpload.server}/${thumbUpload.hash}',
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
      createdAt: localVideo.createdAt.millisecondsSinceEpoch ~/ 1000,
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
}
