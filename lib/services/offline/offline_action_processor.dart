import '../../domain/models/offline_action.dart';
import '../../domain/models/parent_identity.dart';
import '../engagement/like_coordinator.dart';
import '../engagement/reaction_coordinator.dart';
import '../identity/identity_service.dart';
import '../identity/parent_profile_service.dart';
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
  }) : _store = store,
       _identityService = identityService,
       _parentProfileService = parentProfileService,
       _videoShareCoordinator = videoShareCoordinator,
       _likeCoordinator = likeCoordinator,
       _reactionCoordinator = reactionCoordinator,
       _reportCoordinator = reportCoordinator;

  final OfflineActionStore _store;
  final IdentityService _identityService;
  final ParentProfileService _parentProfileService;
  final VideoShareCoordinator _videoShareCoordinator;
  final LikeCoordinator _likeCoordinator;
  final ReactionCoordinator _reactionCoordinator;
  final ReportCoordinator _reportCoordinator;

  Future<int> flush() async {
    final identity = await _identityService.loadIdentity();
    if (identity == null) {
      return 0;
    }
    final actions = await _store.load();
    var flushed = 0;
    for (final action in actions) {
      try {
        await _processAction(identity: identity, action: action);
        await _store.markSucceeded(action.id);
        flushed += 1;
      } catch (error) {
        await _store.markFailed(actionId: action.id, error: error);
      }
    }
    return flushed;
  }

  Future<void> _processAction({
    required ParentIdentity identity,
    required OfflineAction action,
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
            )
            .then((_) {});
    }
  }
}
