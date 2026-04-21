import '../../domain/models/offline_action.dart';
import '../../domain/models/parent_identity.dart';
import '../engagement/like_coordinator.dart';
import '../engagement/reaction_coordinator.dart';
import '../identity/identity_service.dart';
import '../identity/parent_profile_service.dart';
import '../identity/user_list_sync_service.dart';
import '../nostr/nostr_service.dart';
import '../offline/offline_action_store.dart';
import '../safety/report_coordinator.dart';
import '../share/video_share_coordinator.dart';

class OfflineActionProcessor {
  OfflineActionProcessor({
    required OfflineActionStore store,
    required IdentityService identityService,
    required ParentProfileService parentProfileService,
    required VideoShareCoordinator videoShareCoordinator,
    required LikeCoordinator likeCoordinator,
    required ReactionCoordinator reactionCoordinator,
    required ReportCoordinator reportCoordinator,
    required UserListSyncService userListSyncService,
    required NostrService nostrService,
  }) : _store = store,
       _identityService = identityService,
       _parentProfileService = parentProfileService,
       _videoShareCoordinator = videoShareCoordinator,
       _likeCoordinator = likeCoordinator,
       _reactionCoordinator = reactionCoordinator,
       _reportCoordinator = reportCoordinator,
       _userListSyncService = userListSyncService,
       _nostrService = nostrService;

  final OfflineActionStore _store;
  final IdentityService _identityService;
  final ParentProfileService _parentProfileService;
  final VideoShareCoordinator _videoShareCoordinator;
  final LikeCoordinator _likeCoordinator;
  final ReactionCoordinator _reactionCoordinator;
  final ReportCoordinator _reportCoordinator;
  final UserListSyncService _userListSyncService;
  final NostrService _nostrService;

  Future<int> flush() async {
    final identity = await _identityService.loadIdentity();
    if (identity == null) {
      return 0;
    }
    final actions = await _deduplicate(await _store.load());
    if (actions.isEmpty) return 0;

    // Preload relay + blossom lists once if this batch includes any video shares,
    // so N queued shares don't each re-read the same settings rows.
    List<String>? preloadedRelays;
    List<String>? preloadedBlossomServers;
    final hasShareVideo = actions.any(
      (a) => a.type == OfflineActionType.shareVideo,
    );
    if (hasShareVideo) {
      preloadedRelays = await _nostrService.loadRelayList();
      preloadedBlossomServers = await _nostrService.loadBlossomServerList();
    }

    final limit = _flushConcurrency.clamp(1, actions.length);
    final succeededIds = <String>[];
    final failedActions = <(String, Object)>[];
    var next = 0;

    Future<void> worker() async {
      while (true) {
        final index = next++;
        if (index >= actions.length) return;
        final action = actions[index];
        try {
          await _processAction(
            identity: identity,
            action: action,
            preloadedRelays: preloadedRelays,
            preloadedBlossomServers: preloadedBlossomServers,
          );
          succeededIds.add(action.id);
        } catch (error) {
          failedActions.add((action.id, error));
        }
      }
    }

    await Future.wait(List.generate(limit, (_) => worker()));

    // Batch process results sequentially to avoid race conditions
    for (final id in succeededIds) {
      await _store.markSucceeded(id);
    }
    for (final (id, error) in failedActions) {
      await _store.markFailed(actionId: id, error: error);
    }

    return succeededIds.length;
  }

  static const int _flushConcurrency = 4;

  /// Collapse duplicate actions (same type + payload) keeping the oldest.
  /// This heals queues bloated by the re-enqueue bug.
  Future<List<OfflineAction>> _deduplicate(List<OfflineAction> actions) async {
    final seen = <String>{};
    final deduped = <OfflineAction>[];
    final removals = <String>[];
    for (final action in actions) {
      final key = '${action.type.name}:${action.payload}';
      if (seen.add(key)) {
        deduped.add(action);
      } else {
        removals.add(action.id);
      }
    }
    for (final id in removals) {
      await _store.remove(id);
    }
    return deduped;
  }

  Future<void> _processAction({
    required ParentIdentity identity,
    required OfflineAction action,
    List<String>? preloadedRelays,
    List<String>? preloadedBlossomServers,
  }) {
    switch (action.type) {
      case OfflineActionType.shareVideo:
        return _videoShareCoordinator.shareLocalVideo(
          identity: identity,
          videoId: action.payload['video_id']?.toString() ?? '',
          profileId: action.payload['profile_id']?.toString() ?? '',
          childDisplayName:
              action.payload['child_display_name']?.toString() ?? '',
          mlsGroupIdHex: action.payload['mls_group_id']?.toString() ?? '',
          allowQueueOnFailure: false,
          preloadedRelays: preloadedRelays,
          preloadedBlossomServers: preloadedBlossomServers,
        );
      case OfflineActionType.sendLike:
        return _likeCoordinator.sendRemoteLike(
          identity: identity,
          videoId: action.payload['video_id']?.toString() ?? '',
          childProfileId: action.payload['child_profile_id']?.toString() ?? '',
          mlsGroupIdHex: action.payload['mls_group_id']?.toString() ?? '',
          allowQueueOnFailure: false,
        );
      case OfflineActionType.sendReaction:
        return _reactionCoordinator.sendRemoteReaction(
          identity: identity,
          videoId: action.payload['video_id']?.toString() ?? '',
          childProfileId: action.payload['child_profile_id']?.toString() ?? '',
          mlsGroupIdHex: action.payload['mls_group_id']?.toString() ?? '',
          emoji: action.payload['emoji']?.toString() ?? '',
          allowQueueOnFailure: false,
        );
      case OfflineActionType.submitReport:
        return _reportCoordinator
            .submitReport(
              identity: identity,
              videoId: action.payload['video_id']?.toString() ?? '',
              subjectChildId:
                  action.payload['subject_child_id']?.toString() ?? '',
              blobHash: action.payload['blob_hash']?.toString(),
              reporterChildId: action.payload['reporter_child_id']?.toString(),
              reason: action.payload['reason']?.toString() ?? 'Concern',
              note: action.payload['note']?.toString(),
              level:
                  int.tryParse(action.payload['level']?.toString() ?? '') ?? 1,
              recipientType:
                  action.payload['recipient_type']?.toString() ?? 'group',
              allowQueueOnFailure: false,
            )
            .then((_) {});
      case OfflineActionType.publishParentProfile:
        return _parentProfileService
            .publishLocalProfile(
              identity: identity,
              displayName: action.payload['display_name']?.toString() ?? '',
              allowQueueOnFailure: false,
            )
            .then((_) {});
      case OfflineActionType.publishRelayList:
        return _userListSyncService.replayRelayListPublish(
          identity: identity,
          payload: action.payload,
        );
      case OfflineActionType.publishBlossomServerList:
        return _userListSyncService.replayBlossomServerListPublish(
          identity: identity,
          payload: action.payload,
        );
      case OfflineActionType.publishMuteList:
        return _userListSyncService.replayMuteListPublish(
          identity: identity,
          payload: action.payload,
        );
    }
  }
}
