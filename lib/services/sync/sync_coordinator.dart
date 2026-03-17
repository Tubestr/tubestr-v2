import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ndk/entities.dart';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/marmot/message_models.dart';
import '../../domain/models/parent_identity.dart';
import '../../domain/models/remote_share_identity.dart';
import '../../domain/models/remote_share_projection.dart';
import '../identity/identity_service.dart';
import '../identity/parent_profile_service.dart';
import '../mdk/mdk_service.dart';
import '../media/remote_media_service.dart';
import '../nostr/nostr_service.dart';

class SyncProjectionResult {
  const SyncProjectionResult({required this.projected, required this.reason});

  final bool projected;
  final String reason;
}

class SyncCoordinator {
  SyncCoordinator({
    required AppDatabase database,
    required MdkService mdkService,
    NostrService? nostrService,
    IdentityService? identityService,
    RemoteMediaService? remoteMediaService,
    ParentProfileService? parentProfileService,
  }) : _database = database,
       _mdkService = mdkService,
       _nostrService = nostrService,
       _identityService = identityService,
       _remoteMediaService = remoteMediaService,
       _parentProfileService = parentProfileService;

  static const _subscriptionId = 'mytube.family.sync';
  static const _lookback = Duration(days: 14);

  final AppDatabase _database;
  final MdkService _mdkService;
  final NostrService? _nostrService;
  final IdentityService? _identityService;
  final RemoteMediaService? _remoteMediaService;
  final ParentProfileService? _parentProfileService;
  final StreamController<int> _revisionController =
      StreamController<int>.broadcast();

  final List<StreamSubscription<Nip01Event>> _eventSubscriptions = [];
  final List<String> _activeSubscriptionIds = [];
  Set<String> _trackedGroupNostrIds = const <String>{};
  Future<void>? _refreshSubscriptionsTask;
  bool _started = false;
  int _revision = 0;

  Stream<int> get revisions => _revisionController.stream;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    await refreshSubscriptions();
  }

  Future<void> stop() async {
    _started = false;
    for (final subscription in _eventSubscriptions) {
      await subscription.cancel();
    }
    _eventSubscriptions.clear();
    if (_nostrService != null) {
      for (final subscriptionId in _activeSubscriptionIds) {
        try {
          await _nostrService.unsubscribe(subscriptionId);
        } catch (_) {
          // Ignore close errors when the subscription was never opened.
        }
      }
    }
    _activeSubscriptionIds.clear();
    await _revisionController.close();
  }

  Future<void> refreshSubscriptions() async {
    if (!_started) {
      return;
    }
    final existingTask = _refreshSubscriptionsTask;
    if (existingTask != null) {
      return existingTask;
    }
    final task = _refreshSubscriptionsInternal();
    _refreshSubscriptionsTask = task;
    try {
      await task;
    } finally {
      if (identical(_refreshSubscriptionsTask, task)) {
        _refreshSubscriptionsTask = null;
      }
    }
  }

  Future<void> _refreshSubscriptionsInternal() async {
    final nostrService = _nostrService;
    final identityService = _identityService;
    if (nostrService == null || identityService == null) {
      return;
    }

    final identity = await identityService.loadIdentity();
    if (identity == null) {
      return;
    }

    await _mdkService.ensureInitialized();
    await nostrService.connect();

    for (final subscription in _eventSubscriptions) {
      await subscription.cancel();
    }
    _eventSubscriptions.clear();
    for (final subscriptionId in _activeSubscriptionIds) {
      try {
        await nostrService.unsubscribe(subscriptionId);
      } catch (_) {
        // Ignore if this is the first subscription.
      }
    }
    _activeSubscriptionIds.clear();

    final relays = await nostrService.loadRelayList();
    final groups = await _mdkService.getGroupSummaries();
    _trackedGroupNostrIds = groups
        .map((group) => group.nostrGroupIdHex.trim().toLowerCase())
        .where((groupId) => groupId.isNotEmpty)
        .toSet();
    final filters = _buildFilters(
      parentPublicKeyHex: identity.publicKeyHex,
      trackedGroupNostrIds: _trackedGroupNostrIds,
    );
    for (var index = 0; index < filters.length; index += 1) {
      final subscriptionId = '$_subscriptionId.$index';
      final response = await nostrService.subscribe(
        subscriptionId: subscriptionId,
        relays: relays,
        filter: filters[index],
      );

      _activeSubscriptionIds.add(subscriptionId);
      _eventSubscriptions.add(
        response.stream.listen(
          (event) => unawaited(_handleIncomingEvent(identity, event)),
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Sync subscription error: $error');
          },
        ),
      );
    }
  }

  Future<SyncProjectionResult> processIncomingEventJson({
    required String eventJson,
  }) async {
    final event = Nip01EventModel.fromJson(
      jsonDecode(eventJson) as Map<String, dynamic>,
    );
    final identity = await _identityService?.loadIdentity();
    return _processEvent(
      identity: identity,
      event: event,
      eventJson: Nip01EventModel.fromEntity(event).toJsonString(),
    );
  }

  Future<SyncProjectionResult> projectProcessedMessage(
    MdkProcessedMessage processed,
  ) async {
    if (processed.outcome != MdkMessageOutcome.applicationMessage) {
      return SyncProjectionResult(
        projected: false,
        reason: 'ignored:${processed.outcome.value}',
      );
    }

    switch (processed.kind) {
      case MarmotKinds.videoShare:
        final message = VideoShareMessage.decode(processed.content);
        final localIdentity = await _identityService?.loadIdentity();
        await _parentProfileService?.primeKnownProfiles(
          publicKeysHex: <String>[message.by],
          localIdentity: localIdentity,
        );
        final remoteShareId = await _database.upsertRemoteShareProjection(
          videoId: message.videoId,
          mlsGroupId: processed.mlsGroupIdHex,
          senderParentKey: message.by,
          childProfileId: message.childProfileId,
          childDisplayName: message.childDisplayName,
          blobHash: message.blob.hash,
          thumbHash: message.thumb.hash,
          epoch: message.media.epoch,
          mime: message.blob.mime,
          metadataJson: jsonEncode(message.toJson()),
          receivedAt: DateTime.fromMillisecondsSinceEpoch(
            processed.createdAt * 1000,
          ),
        );
        final projection = await _database
            .watchRemoteShareProjectionByRemoteShareId(remoteShareId)
            .first;
        if (projection != null && _remoteMediaService != null) {
          unawaited(_remoteMediaService.prefetchThumbnail(projection));
        }
        return const SyncProjectionResult(
          projected: true,
          reason: 'projected:video_share',
        );
      case MarmotKinds.like:
        final message = LikeMessage.fromJson(
          jsonDecode(processed.content) as Map<String, dynamic>,
        );
        await _database.upsertLike(
          videoId: message.videoId,
          childProfileId: message.childProfileId,
          parentPubkey: message.by,
          createdAt: DateTime.fromMillisecondsSinceEpoch(message.ts * 1000),
        );
        return const SyncProjectionResult(
          projected: true,
          reason: 'projected:like',
        );
      case MarmotKinds.report:
        final message = ReportMessage.fromJson(
          jsonDecode(processed.content) as Map<String, dynamic>,
        );
        final localIdentity = await _identityService?.loadIdentity();
        await _parentProfileService?.primeKnownProfiles(
          publicKeysHex: <String>[message.by],
          localIdentity: localIdentity,
        );
        final isOutbound = localIdentity?.publicKeyHex == message.by;
        await _database.upsertReportRecord(
          reportId: message.reportId,
          videoId: message.videoId,
          subjectChildId: message.subjectChildId,
          blobHash: message.blobHash,
          reason: message.reason,
          note: message.note,
          level: message.level,
          recipientType: message.recipientType,
          reporterChildId: message.reporterChildId,
          reporterParentKey: message.by,
          isOutbound: isOutbound,
          createdAt: DateTime.fromMillisecondsSinceEpoch(message.ts * 1000),
          status: isOutbound ? 'delivered' : 'received',
          deliveredAt: isOutbound ? DateTime.now() : null,
        );
        return SyncProjectionResult(
          projected: true,
          reason: isOutbound ? 'projected:report_outbound' : 'projected:report',
        );
      case MarmotKinds.videoRevoke:
      case MarmotKinds.videoDelete:
        final message = VideoLifecycleMessage.fromJson(
          jsonDecode(processed.content) as Map<String, dynamic>,
        );
        final remoteShareId = buildRemoteShareId(
          senderParentKey: message.by,
          mlsGroupId: processed.mlsGroupIdHex,
          videoId: message.videoId,
        );
        final existingProjection = await _database
            .getRemoteShareProjectionByRemoteShareId(remoteShareId);
        await _deleteCachedRemoteFiles(existingProjection);
        await _database.purgeRemoteAssetCache(remoteShareId: remoteShareId);
        await _database.markRemoteShareDeleted(
          remoteShareId: remoteShareId,
          reason: message.reason ?? message.type,
        );
        return SyncProjectionResult(
          projected: true,
          reason: processed.kind == MarmotKinds.videoDelete
              ? 'projected:video_delete'
              : 'projected:video_revoke',
        );
      default:
        return SyncProjectionResult(
          projected: false,
          reason: 'ignored:kind_${processed.kind}',
        );
    }
  }

  Future<void> _deleteCachedRemoteFiles(
    RemoteShareProjection? projection,
  ) async {
    if (projection == null) {
      return;
    }
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

  @visibleForTesting
  List<Filter> buildFiltersForTesting({
    required String parentPublicKeyHex,
    required Set<String> trackedGroupNostrIds,
  }) {
    return _buildFilters(
      parentPublicKeyHex: parentPublicKeyHex,
      trackedGroupNostrIds: trackedGroupNostrIds,
    );
  }

  List<Filter> _buildFilters({
    required String parentPublicKeyHex,
    required Set<String> trackedGroupNostrIds,
  }) {
    final since =
        DateTime.now().subtract(_lookback).millisecondsSinceEpoch ~/ 1000;

    final filters = <Filter>[
      Filter(
        kinds: [MarmotKinds.giftWrap],
        pTags: [parentPublicKeyHex],
        since: since,
      ),
    ];

    if (trackedGroupNostrIds.isNotEmpty) {
      filters.add(
        Filter(
          kinds: [MarmotKinds.groupCommit],
          tags: <String, List<String>>{
            '#h': trackedGroupNostrIds.toList(growable: false),
          },
          since: since,
        ),
      );
    }

    return filters;
  }

  Future<void> _handleIncomingEvent(
    ParentIdentity identity,
    Nip01Event event,
  ) async {
    if (!_shouldProcessSubscribedEvent(event)) {
      return;
    }

    final eventJson = Nip01EventModel.fromEntity(event).toJsonString();
    final result = await _processEvent(
      identity: identity,
      event: event,
      eventJson: eventJson,
    );
    if (result.reason.startsWith('updated:') ||
        result.reason.startsWith('projected:')) {
      _publishRevision();
    }
  }

  bool _shouldProcessSubscribedEvent(Nip01Event event) {
    if (event.kind != MarmotKinds.groupCommit) {
      return true;
    }

    if (_trackedGroupNostrIds.isEmpty) {
      return false;
    }

    final groupIds = event.getTags('h');
    if (groupIds.isEmpty) {
      return false;
    }

    return groupIds.any(
      (groupId) => _trackedGroupNostrIds.contains(groupId.toLowerCase()),
    );
  }

  Future<SyncProjectionResult> _processEvent({
    required ParentIdentity? identity,
    required Nip01Event event,
    required String eventJson,
  }) async {
    try {
      if (event.kind == MarmotKinds.giftWrap) {
        if (identity == null) {
          return const SyncProjectionResult(
            projected: false,
            reason: 'ignored:no_identity',
          );
        }

        final nostrService = _nostrService;
        if (nostrService == null) {
          return const SyncProjectionResult(
            projected: false,
            reason: 'ignored:no_nostr_service',
          );
        }

        final rumorJson = await nostrService.unwrapGiftWrapRumorJson(
          identity: identity,
          giftWrapEvent: event,
        );
        if (rumorJson == null) {
          return const SyncProjectionResult(
            projected: false,
            reason: 'ignored:gift_wrap_empty',
          );
        }

        final rumor = Nip01EventModel.fromJson(
          jsonDecode(rumorJson) as Map<String, dynamic>,
        );
        if (rumor.kind != MarmotKinds.welcome) {
          return SyncProjectionResult(
            projected: false,
            reason: 'ignored:gift_wrap_kind_${rumor.kind}',
          );
        }

        await _mdkService.processWelcomeRumor(welcomeRumorJson: rumorJson);
        return const SyncProjectionResult(
          projected: true,
          reason: 'updated:welcome_gift_wrap',
        );
      }

      if (event.kind == MarmotKinds.welcome) {
        await _mdkService.processWelcomeRumor(welcomeRumorJson: eventJson);
        return const SyncProjectionResult(
          projected: true,
          reason: 'updated:welcome',
        );
      }

      final processed = await _mdkService.processMessageEvent(
        eventJson: eventJson,
      );
      final projection = await projectProcessedMessage(processed);
      if (projection.projected) {
        return projection;
      }

      switch (processed.outcome) {
        case MdkMessageOutcome.commit:
        case MdkMessageOutcome.proposal:
        case MdkMessageOutcome.pendingProposal:
        case MdkMessageOutcome.externalJoinProposal:
          return SyncProjectionResult(
            projected: true,
            reason: 'updated:${processed.outcome.value}',
          );
        case MdkMessageOutcome.applicationMessage:
        case MdkMessageOutcome.ignoredProposal:
        case MdkMessageOutcome.unprocessable:
        case MdkMessageOutcome.previouslyFailed:
          return projection;
      }
    } catch (error) {
      if ('$error'.toLowerCase().contains('group not found')) {
        debugPrint('Ignoring out-of-scope sync event ${event.id}: $error');
      } else {
        debugPrint('Failed to process sync event ${event.id}: $error');
      }
      return SyncProjectionResult(
        projected: false,
        reason: 'error:${event.kind}',
      );
    }
  }

  void _publishRevision() {
    if (_revisionController.isClosed) {
      return;
    }
    _revision += 1;
    _revisionController.add(_revision);
  }
}
