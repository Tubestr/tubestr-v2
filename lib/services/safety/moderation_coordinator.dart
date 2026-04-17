import 'dart:convert';
import 'dart:io';

import '../../core/storage/app_database.dart';
import '../../domain/models/mute_list.dart';
import '../../domain/models/parent_identity.dart';
import '../../domain/models/remote_share_projection.dart';
import '../blossom/blossom_client.dart';
import '../connections/family_connection_service.dart';
import '../identity/user_list_sync_service.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';
import '../nostr/outbox_relay_resolver.dart';
import '../share/video_lifecycle_coordinator.dart';

/// Thrown by [ModerationCoordinator.leaveGroup] when the departing parent
/// is the group's only remaining admin. MIP-03 forbids self-demoting the
/// last admin because it would leave the group unable to evolve.
class LastAdminCannotLeaveException implements Exception {
  const LastAdminCannotLeaveException();

  @override
  String toString() =>
      'Cannot leave: you are the only admin. Promote another admin first.';
}

class ModerationCoordinator {
  ModerationCoordinator({
    required AppDatabase database,
    required BlossomClient blossomClient,
    required MdkService mdkService,
    required NostrService nostrService,
    required VideoLifecycleCoordinator videoLifecycleCoordinator,
    FamilyConnectionService? familyConnectionService,
    UserListSyncService? userListSyncService,
    OutboxRelayResolver? outboxRelayResolver,
  }) : _database = database,
       _blossomClient = blossomClient,
       _mdkService = mdkService,
       _nostrService = nostrService,
       _videoLifecycleCoordinator = videoLifecycleCoordinator,
       _familyConnectionService = familyConnectionService,
       _userListSyncService = userListSyncService,
       _outboxRelayResolver = outboxRelayResolver;

  final AppDatabase _database;
  final BlossomClient _blossomClient;
  final MdkService _mdkService;
  final NostrService _nostrService;
  final VideoLifecycleCoordinator _videoLifecycleCoordinator;
  final FamilyConnectionService? _familyConnectionService;
  final UserListSyncService? _userListSyncService;
  final OutboxRelayResolver? _outboxRelayResolver;

  Future<List<String>> loadGroupMembers({required String mlsGroupIdHex}) {
    return _mdkService.getGroupMembers(mlsGroupIdHex: mlsGroupIdHex);
  }

  /// Adds [memberPubkeyHex] to the admin set of [mlsGroupIdHex], preserving
  /// the existing admins. Only an existing admin can publish this update; the
  /// member must already be in the group.
  Future<void> promoteMemberToAdmin({
    required ParentIdentity identity,
    required String mlsGroupIdHex,
    required List<String> currentAdminPubkeysHex,
    required String memberPubkeyHex,
  }) async {
    final target = memberPubkeyHex.toLowerCase();
    final nextAdmins = <String>{
      for (final pubkey in currentAdminPubkeysHex) pubkey.toLowerCase(),
      target,
    }.toList(growable: false);

    final update = await _mdkService.updateGroupAdmins(
      mlsGroupIdHex: mlsGroupIdHex,
      adminPubkeysHex: nextAdmins,
    );
    final relays = await _nostrService.loadRelayList();
    await _nostrService.publishSignedEventJson(
      identity: identity,
      eventJson: update.wrapperEventJson,
      relays: relays,
    );
    await _database.addModerationAuditLog(
      mlsGroupId: mlsGroupIdHex,
      actionType: 'promote_admin',
      actorParentKey: identity.publicKeyHex,
      subjectParentKey: memberPubkeyHex,
      detailsJson: jsonEncode({'wrapper_event_id': update.wrapperEventIdHex}),
    );
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

  /// Leaves a family space the current parent is a member of.
  ///
  /// MIP-03 requires admins to self-demote before SelfRemoving, so this
  /// method performs a two-step dance when [isAdmin] is true: first publish
  /// a self-demote commit, then publish the SelfRemove proposal. Any other
  /// member will commit the removal on its next epoch advance.
  ///
  /// Throws [LastAdminCannotLeaveException] when the parent is the only
  /// remaining admin — another admin must be designated first (not yet
  /// supported in UI, so in practice this means the group has a single
  /// member and must be abandoned without ceremony).
  ///
  /// After a successful leave the group is flagged in [AppDatabase] so
  /// feeds, share pickers, and capture surfaces hide it immediately even
  /// though MDK still considers it active locally.
  Future<void> leaveGroup({
    required ParentIdentity identity,
    required String mlsGroupIdHex,
    required bool isAdmin,
  }) async {
    final members = await _mdkService.getGroupMembers(
      mlsGroupIdHex: mlsGroupIdHex,
    );
    final self = identity.publicKeyHex.toLowerCase();
    final otherMembers = members
        .where((member) => member.toLowerCase() != self)
        .toList(growable: false);
    final soloGroup = otherMembers.isEmpty;

    // Solo groups have no one to receive or commit a proposal, and mdk-core
    // refuses self-demote when you're the only admin. Abandon locally.
    if (soloGroup) {
      await _database.markFamilySpaceLeft(mlsGroupIdHex);
      await _database.addModerationAuditLog(
        mlsGroupId: mlsGroupIdHex,
        actionType: 'leave_group',
        actorParentKey: identity.publicKeyHex,
        subjectParentKey: identity.publicKeyHex,
        detailsJson: jsonEncode({'abandoned_solo': true}),
      );
      return;
    }

    final relays = await _nostrService.loadRelayList();

    String? demoteEventId;
    if (isAdmin) {
      try {
        final demote = await _mdkService.selfDemote(
          mlsGroupIdHex: mlsGroupIdHex,
        );
        await _nostrService.publishSignedEventJson(
          identity: identity,
          eventJson: demote.wrapperEventJson,
          relays: relays,
        );
        demoteEventId = demote.wrapperEventIdHex;
      } catch (err) {
        if (_looksLikeLastAdmin(err)) {
          throw const LastAdminCannotLeaveException();
        }
        rethrow;
      }
    }

    final leave = await _mdkService.leaveGroup(mlsGroupIdHex: mlsGroupIdHex);
    await _nostrService.publishSignedEventJson(
      identity: identity,
      eventJson: leave.wrapperEventJson,
      relays: relays,
    );

    await _database.markFamilySpaceLeft(mlsGroupIdHex);
    if (_familyConnectionService != null) {
      await _familyConnectionService.clearPendingConnectionsFor(otherMembers);
    }
    await _database.addModerationAuditLog(
      mlsGroupId: mlsGroupIdHex,
      actionType: 'leave_group',
      actorParentKey: identity.publicKeyHex,
      subjectParentKey: identity.publicKeyHex,
      detailsJson: jsonEncode({
        'self_demote_event_id': demoteEventId,
        'leave_event_id': leave.wrapperEventIdHex,
      }),
    );
  }

  bool _looksLikeLastAdmin(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('last active admin') ||
        message.contains('designate another admin');
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
    await _database.purgeRemoteAssetCache(
      remoteShareId: projection.remoteShareId,
    );
    await _database.markRemoteShareDeleted(
      remoteShareId: projection.remoteShareId,
      reason: reason ?? 'moderation_delete',
    );
    await _database.addModerationAuditLog(
      videoId: projection.videoId,
      mlsGroupId: projection.mlsGroupId,
      actionType: 'delete_video',
      actorParentKey: identity.publicKeyHex,
      subjectParentKey: projection.senderParentKey,
      detailsJson: jsonEncode({'reason': reason, 'blob_hash': blobHash}),
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

  /// Adds [pubkeyHex] to the local kind-10000 mute list and republishes. The
  /// blocked creator will be filtered from feeds wherever callers consult
  /// [UserListSyncService.loadMuteList]. Safe to call without the sync
  /// service wired — that only means the block stays local.
  Future<void> blockCreator({
    required ParentIdentity identity,
    required String pubkeyHex,
    String? reason,
  }) async {
    final normalized = pubkeyHex.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    await _database.addModerationAuditLog(
      actionType: 'block_creator',
      actorParentKey: identity.publicKeyHex,
      subjectParentKey: normalized,
      detailsJson: jsonEncode({'reason': reason}),
    );
    final sync = _userListSyncService;
    if (sync == null) {
      return;
    }
    final current = await sync.loadMuteList();
    if (current.contains(normalized)) {
      return;
    }
    final entries = [
      ...current.entries,
      MuteEntry(
        pubkeyHex: normalized,
        reason: reason,
        addedAt: DateTime.now().toUtc(),
      ),
    ];
    await sync.saveAndPublishMuteList(identity: identity, entries: entries);
  }

  Future<void> _reportBlobAbuse({
    required ParentIdentity identity,
    required RemoteShareProjection projection,
    required String blobHash,
    String? reason,
  }) async {
    final servers = await _resolveReportServers(projection);
    final eventJson = await _nostrService.createSignedEventJson(
      identity: identity,
      kind: 1984,
      tags: [
        ['x', blobHash, reason ?? 'inappropriate'],
        ['p', projection.senderParentKey],
      ],
      content: reason ?? 'Tubestr moderation delete',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    // BUD-09: report the blob to each storage server.
    for (final server in servers) {
      try {
        await _blossomClient.reportBlob(server: server, eventJson: eventJson);
      } catch (_) {
        // Best-effort. App-level lifecycle/report state remains authoritative.
      }
    }

    // NIP-56: broadcast the report to relays so moderation infrastructure
    // outside Blossom can see it. Union the local relay pool with the
    // reported creator's read relays so they can see it too.
    try {
      final relays =
          await _outboxRelayResolver?.unionForWrite(
            projection.senderParentKey,
          ) ??
          await _nostrService.loadRelayList();
      await _nostrService.publishSignedEventJson(
        identity: identity,
        eventJson: eventJson,
        relays: relays,
      );
    } catch (_) {
      // Best-effort. Report already went to Blossom above.
    }
  }

  Future<List<String>> _resolveReportServers(
    RemoteShareProjection projection,
  ) async {
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
