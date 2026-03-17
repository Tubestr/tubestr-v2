import 'dart:convert';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/marmot/message_models.dart';
import '../../domain/models/offline_action.dart';
import '../../domain/models/parent_identity.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';
import '../offline/offline_action_store.dart';

class ReactionCoordinator {
  ReactionCoordinator({
    required AppDatabase database,
    required MdkService mdkService,
    required NostrService nostrService,
    required OfflineActionStore offlineActionStore,
  }) : _database = database,
       _mdkService = mdkService,
       _nostrService = nostrService,
       _offlineActionStore = offlineActionStore;

  final AppDatabase _database;
  final MdkService _mdkService;
  final NostrService _nostrService;
  final OfflineActionStore _offlineActionStore;

  Future<void> sendRemoteReaction({
    required ParentIdentity identity,
    required String videoId,
    required String childProfileId,
    required String mlsGroupIdHex,
    required String emoji,
    bool allowQueueOnFailure = true,
  }) async {
    try {
      final createdAt = DateTime.now();
      final payload = ReactionMessage(
        videoId: videoId,
        childProfileId: childProfileId,
        emoji: emoji,
        by: identity.publicKeyHex,
        ts: createdAt.millisecondsSinceEpoch ~/ 1000,
      );
      final createdMessage = await _mdkService.createApplicationMessage(
        mlsGroupIdHex: mlsGroupIdHex,
        senderPublicKeyHex: identity.publicKeyHex,
        kind: MarmotKinds.reaction,
        content: jsonEncode(payload.toJson()),
        createdAt: payload.ts,
      );
      final relays = await _nostrService.loadRelayList();
      await _nostrService.publishSignedEventJson(
        identity: identity,
        eventJson: createdMessage.wrapperEventJson,
        relays: relays,
      );
      await _database.upsertReaction(
        videoId: videoId,
        childProfileId: childProfileId,
        parentPubkey: identity.publicKeyHex,
        emoji: emoji,
        createdAt: createdAt,
      );
    } catch (error) {
      if (allowQueueOnFailure) {
        await _offlineActionStore.enqueue(
          type: OfflineActionType.sendReaction,
          payload: <String, dynamic>{
            'video_id': videoId,
            'child_profile_id': childProfileId,
            'mls_group_id': mlsGroupIdHex,
            'emoji': emoji,
          },
        );
        throw StateError('Reaction queued for retry: $error');
      }
      rethrow;
    }
  }
}
