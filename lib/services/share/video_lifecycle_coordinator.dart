import 'dart:convert';

import '../../core/constants.dart';
import '../../domain/marmot/message_models.dart';
import '../../domain/models/parent_identity.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';

class VideoLifecycleCoordinator {
  VideoLifecycleCoordinator({
    required MdkService mdkService,
    required NostrService nostrService,
  }) : _mdkService = mdkService,
       _nostrService = nostrService;

  final MdkService _mdkService;
  final NostrService _nostrService;

  Future<void> publishDelete({
    required ParentIdentity identity,
    required String mlsGroupIdHex,
    required String videoId,
    required String blobHash,
    String? reason,
  }) {
    return _publishLifecycle(
      identity: identity,
      mlsGroupIdHex: mlsGroupIdHex,
      type: VideoLifecycleMessage.deleteType,
      kind: MarmotKinds.videoDelete,
      videoId: videoId,
      blobHash: blobHash,
      reason: reason,
    );
  }

  Future<void> publishRevoke({
    required ParentIdentity identity,
    required String mlsGroupIdHex,
    required String videoId,
    required String blobHash,
    String? reason,
  }) {
    return _publishLifecycle(
      identity: identity,
      mlsGroupIdHex: mlsGroupIdHex,
      type: VideoLifecycleMessage.revokeType,
      kind: MarmotKinds.videoRevoke,
      videoId: videoId,
      blobHash: blobHash,
      reason: reason,
    );
  }

  Future<void> _publishLifecycle({
    required ParentIdentity identity,
    required String mlsGroupIdHex,
    required String type,
    required int kind,
    required String videoId,
    required String blobHash,
    String? reason,
  }) async {
    final timestamp = DateTime.now();
    final payload = VideoLifecycleMessage(
      type: type,
      videoId: videoId,
      blobHash: blobHash,
      reason: reason,
      by: identity.publicKeyHex,
      ts: timestamp.millisecondsSinceEpoch ~/ 1000,
    );
    final createdMessage = await _mdkService.createApplicationMessage(
      mlsGroupIdHex: mlsGroupIdHex,
      senderPublicKeyHex: identity.publicKeyHex,
      kind: kind,
      content: jsonEncode(payload.toJson()),
      createdAt: payload.ts,
    );
    final relays = await _nostrService.loadRelayList();
    await _nostrService.publishSignedEventJson(
      identity: identity,
      eventJson: createdMessage.wrapperEventJson,
      relays: relays,
    );
  }
}
