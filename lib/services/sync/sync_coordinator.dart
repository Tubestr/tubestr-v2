import 'dart:async';
import 'dart:collection';
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

enum SyncRefreshTrigger {
  startup('startup'),
  manual('manual'),
  reconnect('reconnect'),
  groupChange('group_change'),
  resume('resume');

  const SyncRefreshTrigger(this.value);

  final String value;
}

class SyncSubscriptionDiagnostics {
  const SyncSubscriptionDiagnostics({
    required this.subscriptionId,
    required this.generation,
    required this.kinds,
    required this.pTags,
    required this.hTags,
    required this.since,
  });

  final String subscriptionId;
  final int generation;
  final List<int> kinds;
  final List<String> pTags;
  final List<String> hTags;
  final int? since;

  String describe() {
    final segments = <String>[
      'id=$subscriptionId',
      'generation=$generation',
      if (kinds.isNotEmpty) 'kinds=${kinds.join(',')}',
      if (pTags.isNotEmpty) 'p=${pTags.join(',')}',
      if (hTags.isNotEmpty) 'h=${hTags.join(',')}',
      if (since != null) 'since=$since',
    ];
    return segments.join(' ');
  }
}

class SyncRecentHistoryEntry {
  const SyncRecentHistoryEntry({
    required this.at,
    required this.category,
    required this.detail,
    this.generation,
    this.trigger,
  });

  final DateTime at;
  final String category;
  final String detail;
  final int? generation;
  final String? trigger;

  String describe() {
    final prefix = <String>[
      at.toIso8601String(),
      category,
      if (generation != null) 'generation=$generation',
      if (trigger != null) 'trigger=$trigger',
    ].join(' ');
    return '$prefix $detail';
  }
}

class SyncEventDiagnostics {
  const SyncEventDiagnostics({
    required this.eventId,
    required this.kind,
    required this.reason,
    required this.outcome,
    required this.at,
  });

  final String eventId;
  final int kind;
  final String reason;
  final String outcome;
  final DateTime at;
}

class SyncCoordinatorDiagnostics {
  const SyncCoordinatorDiagnostics({
    required this.started,
    required this.revision,
    required this.refreshGeneration,
    required this.refreshInFlight,
    required this.activeRefreshGeneration,
    required this.activeRefreshTrigger,
    required this.lastRefreshTrigger,
    required this.lastRefreshStartedAt,
    required this.lastRefreshCompletedAt,
    required this.lastRefreshDuration,
    required this.lastRefreshError,
    required this.refreshRequestCount,
    required this.coalescedRefreshRequestCount,
    required this.subscriptionErrorCount,
    required this.unsubscribeFailureCount,
    required this.eventCount,
    required this.projectedEventCount,
    required this.ignoredEventCount,
    required this.errorEventCount,
    required this.relays,
    required this.trackedGroupNostrIds,
    required this.activeSubscriptions,
    required this.lastEvent,
    required this.recentHistory,
  });

  final bool started;
  final int revision;
  final int refreshGeneration;
  final bool refreshInFlight;
  final int? activeRefreshGeneration;
  final String? activeRefreshTrigger;
  final String? lastRefreshTrigger;
  final DateTime? lastRefreshStartedAt;
  final DateTime? lastRefreshCompletedAt;
  final Duration? lastRefreshDuration;
  final String? lastRefreshError;
  final int refreshRequestCount;
  final int coalescedRefreshRequestCount;
  final int subscriptionErrorCount;
  final int unsubscribeFailureCount;
  final int eventCount;
  final int projectedEventCount;
  final int ignoredEventCount;
  final int errorEventCount;
  final List<String> relays;
  final List<String> trackedGroupNostrIds;
  final List<SyncSubscriptionDiagnostics> activeSubscriptions;
  final SyncEventDiagnostics? lastEvent;
  final List<SyncRecentHistoryEntry> recentHistory;
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
  static const _maxRecentHistory = 20;

  final AppDatabase _database;
  final MdkService _mdkService;
  final NostrService? _nostrService;
  final IdentityService? _identityService;
  final RemoteMediaService? _remoteMediaService;
  final ParentProfileService? _parentProfileService;
  final StreamController<int> _revisionController =
      StreamController<int>.broadcast();
  final StreamController<int> _diagnosticsRevisionController =
      StreamController<int>.broadcast();

  final List<StreamSubscription<Nip01Event>> _eventSubscriptions = [];
  final List<String> _activeSubscriptionIds = [];
  final Map<String, SyncSubscriptionDiagnostics>
  _activeSubscriptionDiagnostics = <String, SyncSubscriptionDiagnostics>{};
  final Queue<SyncRecentHistoryEntry> _recentHistory =
      Queue<SyncRecentHistoryEntry>();
  Set<String> _trackedGroupNostrIds = const <String>{};
  Future<void>? _refreshSubscriptionsTask;
  bool _started = false;
  int _revision = 0;
  int _diagnosticsRevision = 0;
  int _refreshGeneration = 0;
  int? _activeRefreshGeneration;
  SyncRefreshTrigger? _activeRefreshTrigger;
  SyncRefreshTrigger? _lastRefreshTrigger;
  DateTime? _lastRefreshStartedAt;
  DateTime? _lastRefreshCompletedAt;
  Duration? _lastRefreshDuration;
  String? _lastRefreshError;
  int _refreshRequestCount = 0;
  int _coalescedRefreshRequestCount = 0;
  int _subscriptionErrorCount = 0;
  int _unsubscribeFailureCount = 0;
  int _eventCount = 0;
  int _projectedEventCount = 0;
  int _ignoredEventCount = 0;
  int _errorEventCount = 0;
  List<String> _lastRelaySnapshot = const <String>[];
  SyncEventDiagnostics? _lastEvent;

  Stream<int> get revisions => _revisionController.stream;
  Stream<int> get diagnosticsRevisions => _diagnosticsRevisionController.stream;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    _recordHistory(category: 'lifecycle', detail: 'started');
    await refreshSubscriptions(trigger: SyncRefreshTrigger.startup);
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
        } catch (error) {
          _unsubscribeFailureCount += 1;
          _recordHistory(
            category: 'subscription',
            detail:
                'unsubscribe failed for $subscriptionId (${_safeErrorSummary(error)})',
          );
        }
      }
    }
    _activeSubscriptionIds.clear();
    _activeSubscriptionDiagnostics.clear();
    _recordHistory(category: 'lifecycle', detail: 'stopped');
    await _revisionController.close();
    await _diagnosticsRevisionController.close();
  }

  Future<void> refreshSubscriptions({
    SyncRefreshTrigger trigger = SyncRefreshTrigger.manual,
  }) async {
    if (!_started) {
      _recordHistory(
        category: 'refresh',
        detail: 'ignored while stopped',
        trigger: trigger,
      );
      return;
    }
    _refreshRequestCount += 1;
    final existingTask = _refreshSubscriptionsTask;
    if (existingTask != null) {
      _coalescedRefreshRequestCount += 1;
      _recordHistory(
        category: 'refresh',
        detail:
            'coalesced into generation ${_activeRefreshGeneration ?? _refreshGeneration}',
        generation: _activeRefreshGeneration,
        trigger: trigger,
      );
      return existingTask;
    }
    final generation = ++_refreshGeneration;
    _activeRefreshGeneration = generation;
    _activeRefreshTrigger = trigger;
    _lastRefreshTrigger = trigger;
    _lastRefreshStartedAt = DateTime.now().toUtc();
    _lastRefreshCompletedAt = null;
    _lastRefreshDuration = null;
    _lastRefreshError = null;
    _recordHistory(
      category: 'refresh',
      detail: 'starting',
      generation: generation,
      trigger: trigger,
    );
    _publishDiagnosticsRevision();
    final task = _refreshSubscriptionsInternal(
      generation: generation,
      trigger: trigger,
    );
    _refreshSubscriptionsTask = task;
    try {
      await task;
      _lastRefreshCompletedAt = DateTime.now().toUtc();
      _lastRefreshDuration = _lastRefreshCompletedAt!.difference(
        _lastRefreshStartedAt!,
      );
      _recordHistory(
        category: 'refresh',
        detail:
            'completed with ${_activeSubscriptionIds.length} subscription(s)',
        generation: generation,
        trigger: trigger,
      );
    } catch (error) {
      _lastRefreshCompletedAt = DateTime.now().toUtc();
      _lastRefreshDuration = _lastRefreshCompletedAt!.difference(
        _lastRefreshStartedAt!,
      );
      _lastRefreshError = _safeErrorSummary(error);
      _recordHistory(
        category: 'refresh',
        detail: 'failed (${_lastRefreshError!})',
        generation: generation,
        trigger: trigger,
      );
      rethrow;
    } finally {
      if (_activeRefreshGeneration == generation) {
        _activeRefreshGeneration = null;
        _activeRefreshTrigger = null;
      }
      _publishDiagnosticsRevision();
      if (identical(_refreshSubscriptionsTask, task)) {
        _refreshSubscriptionsTask = null;
      }
    }
  }

  Future<void> _refreshSubscriptionsInternal({
    required int generation,
    required SyncRefreshTrigger trigger,
  }) async {
    final nostrService = _nostrService;
    final identityService = _identityService;
    if (nostrService == null || identityService == null) {
      _recordHistory(
        category: 'refresh',
        detail: 'skipped because services are unavailable',
        generation: generation,
        trigger: trigger,
      );
      return;
    }

    final identity = await identityService.loadIdentity();
    if (identity == null) {
      _recordHistory(
        category: 'refresh',
        detail: 'skipped because no identity is loaded',
        generation: generation,
        trigger: trigger,
      );
      return;
    }
    if (!_isRefreshStillActive(generation)) {
      return;
    }

    await _mdkService.ensureInitialized();
    await nostrService.connect();
    if (!_isRefreshStillActive(generation)) {
      return;
    }

    for (final subscription in _eventSubscriptions) {
      await subscription.cancel();
    }
    _eventSubscriptions.clear();
    for (final subscriptionId in _activeSubscriptionIds) {
      try {
        await nostrService.unsubscribe(subscriptionId);
      } catch (error) {
        _unsubscribeFailureCount += 1;
        _recordHistory(
          category: 'subscription',
          detail:
              'unsubscribe failed for $subscriptionId (${_safeErrorSummary(error)})',
          generation: generation,
          trigger: trigger,
        );
      }
    }
    _activeSubscriptionIds.clear();
    _activeSubscriptionDiagnostics.clear();

    final relays = await nostrService.loadRelayList();
    _lastRelaySnapshot = List<String>.from(relays, growable: false);
    final groups = await _mdkService.getGroupSummaries();
    _trackedGroupNostrIds = groups
        .map((group) => group.nostrGroupIdHex.trim().toLowerCase())
        .where((groupId) => groupId.isNotEmpty)
        .toSet();
    if (!_isRefreshStillActive(generation)) {
      return;
    }
    final filters = _buildFilters(
      parentPublicKeyHex: identity.publicKeyHex,
      trackedGroupNostrIds: _trackedGroupNostrIds,
    );
    _recordHistory(
      category: 'refresh',
      detail:
          'resolved ${relays.length} relay(s), ${_trackedGroupNostrIds.length} tracked group(s), ${filters.length} filter(s)',
      generation: generation,
      trigger: trigger,
    );
    for (var index = 0; index < filters.length; index += 1) {
      if (!_isRefreshStillActive(generation)) {
        return;
      }
      final subscriptionId = '$_subscriptionId.$index';
      final subscriptionDiagnostics = SyncSubscriptionDiagnostics(
        subscriptionId: subscriptionId,
        generation: generation,
        kinds: List<int>.from(filters[index].kinds ?? const <int>[]),
        pTags: List<String>.from(filters[index].pTags ?? const <String>[]),
        hTags: List<String>.from(
          filters[index].tags?['#h'] ?? const <String>[],
        ),
        since: filters[index].since,
      );
      final response = await nostrService.subscribe(
        subscriptionId: subscriptionId,
        relays: relays,
        filter: filters[index],
      );
      if (!_isRefreshStillActive(generation)) {
        await _cleanupInactiveSubscription(
          subscriptionId: subscriptionId,
          nostrService: nostrService,
          generation: generation,
          trigger: trigger,
        );
        return;
      }

      _activeSubscriptionIds.add(subscriptionId);
      _activeSubscriptionDiagnostics[subscriptionId] = subscriptionDiagnostics;
      _recordHistory(
        category: 'subscription',
        detail: 'subscribed ${subscriptionDiagnostics.describe()}',
        generation: generation,
        trigger: trigger,
      );
      _eventSubscriptions.add(
        response.stream.listen(
          (event) => unawaited(_handleIncomingEvent(identity, event)),
          onError: (Object error, StackTrace stackTrace) {
            _subscriptionErrorCount += 1;
            _recordHistory(
              category: 'subscription',
              detail:
                  'stream error for $subscriptionId (${_safeErrorSummary(error)})',
              generation: generation,
              trigger: trigger,
            );
            _publishDiagnosticsRevision();
            debugPrint(
              'Sync subscription error: ${_safeErrorSummary(error)}',
            );
          },
        ),
      );
    }
    _publishDiagnosticsRevision();
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
      case MarmotKinds.reaction:
        final message = ReactionMessage.fromJson(
          jsonDecode(processed.content) as Map<String, dynamic>,
        );
        await _database.upsertReaction(
          videoId: message.videoId,
          childProfileId: message.childProfileId,
          parentPubkey: message.by,
          emoji: message.emoji,
          createdAt: DateTime.fromMillisecondsSinceEpoch(message.ts * 1000),
        );
        return const SyncProjectionResult(
          projected: true,
          reason: 'projected:reaction',
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
      _eventCount += 1;
      _ignoredEventCount += 1;
      _lastEvent = SyncEventDiagnostics(
        eventId: event.id,
        kind: event.kind,
        reason: 'ignored:out_of_scope',
        outcome: 'ignored',
        at: DateTime.now().toUtc(),
      );
      _recordHistory(
        category: 'event',
        detail: 'ignored event ${event.id} kind=${event.kind} out_of_scope',
      );
      _publishDiagnosticsRevision();
      return;
    }

    final eventJson = Nip01EventModel.fromEntity(event).toJsonString();
    final result = await _processEvent(
      identity: identity,
      event: event,
      eventJson: eventJson,
    );
    _eventCount += 1;
    final outcome = result.reason.startsWith('error:')
        ? 'error'
        : result.projected
        ? 'projected'
        : 'ignored';
    if (outcome == 'projected') {
      _projectedEventCount += 1;
    } else if (outcome == 'error') {
      _errorEventCount += 1;
    } else {
      _ignoredEventCount += 1;
    }
    _lastEvent = SyncEventDiagnostics(
      eventId: event.id,
      kind: event.kind,
      reason: result.reason,
      outcome: outcome,
      at: DateTime.now().toUtc(),
    );
    _recordHistory(
      category: 'event',
      detail: '$outcome event ${event.id} kind=${event.kind} ${result.reason}',
    );
    _publishDiagnosticsRevision();
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
        debugPrint(
          'Ignoring out-of-scope sync event ${event.id}: ${_safeErrorSummary(error)}',
        );
      } else {
        debugPrint(
          'Failed to process sync event ${event.id}: ${_safeErrorSummary(error)}',
        );
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

  SyncCoordinatorDiagnostics debugSnapshot() {
    return SyncCoordinatorDiagnostics(
      started: _started,
      revision: _revision,
      refreshGeneration: _refreshGeneration,
      refreshInFlight: _refreshSubscriptionsTask != null,
      activeRefreshGeneration: _activeRefreshGeneration,
      activeRefreshTrigger: _activeRefreshTrigger?.value,
      lastRefreshTrigger: _lastRefreshTrigger?.value,
      lastRefreshStartedAt: _lastRefreshStartedAt,
      lastRefreshCompletedAt: _lastRefreshCompletedAt,
      lastRefreshDuration: _lastRefreshDuration,
      lastRefreshError: _lastRefreshError,
      refreshRequestCount: _refreshRequestCount,
      coalescedRefreshRequestCount: _coalescedRefreshRequestCount,
      subscriptionErrorCount: _subscriptionErrorCount,
      unsubscribeFailureCount: _unsubscribeFailureCount,
      eventCount: _eventCount,
      projectedEventCount: _projectedEventCount,
      ignoredEventCount: _ignoredEventCount,
      errorEventCount: _errorEventCount,
      relays: List<String>.from(_lastRelaySnapshot, growable: false),
      trackedGroupNostrIds: _trackedGroupNostrIds.toList(growable: false)
        ..sort(),
      activeSubscriptions:
          _activeSubscriptionDiagnostics.values.toList(growable: false)..sort(
            (left, right) =>
                left.subscriptionId.compareTo(right.subscriptionId),
          ),
      lastEvent: _lastEvent,
      recentHistory: _recentHistory.toList(growable: false),
    );
  }

  String debugDescribeState() {
    final snapshot = debugSnapshot();
    final buffer = StringBuffer()
      ..writeln('SyncCoordinator diagnostics')
      ..writeln('started: ${snapshot.started}')
      ..writeln('revision: ${snapshot.revision}')
      ..writeln('refresh_generation: ${snapshot.refreshGeneration}')
      ..writeln('refresh_in_flight: ${snapshot.refreshInFlight}')
      ..writeln(
        'active_refresh: generation=${snapshot.activeRefreshGeneration ?? '-'} trigger=${snapshot.activeRefreshTrigger ?? '-'}',
      )
      ..writeln(
        'last_refresh: trigger=${snapshot.lastRefreshTrigger ?? '-'} started=${_formatTime(snapshot.lastRefreshStartedAt)} completed=${_formatTime(snapshot.lastRefreshCompletedAt)} duration_ms=${snapshot.lastRefreshDuration?.inMilliseconds ?? '-'} error=${snapshot.lastRefreshError ?? '-'}',
      )
      ..writeln(
        'refresh_requests: total=${snapshot.refreshRequestCount} coalesced=${snapshot.coalescedRefreshRequestCount}',
      )
      ..writeln(
        'subscription_health: stream_errors=${snapshot.subscriptionErrorCount} unsubscribe_failures=${snapshot.unsubscribeFailureCount}',
      )
      ..writeln(
        'event_counters: total=${snapshot.eventCount} projected=${snapshot.projectedEventCount} ignored=${snapshot.ignoredEventCount} errors=${snapshot.errorEventCount}',
      )
      ..writeln(
        'relays (${snapshot.relays.length}): ${snapshot.relays.join(', ')}',
      )
      ..writeln(
        'tracked_groups (${snapshot.trackedGroupNostrIds.length}): ${snapshot.trackedGroupNostrIds.join(', ')}',
      )
      ..writeln(
        'active_subscriptions (${snapshot.activeSubscriptions.length}):',
      );
    if (snapshot.activeSubscriptions.isEmpty) {
      buffer.writeln('  - none');
    } else {
      for (final subscription in snapshot.activeSubscriptions) {
        buffer.writeln('  - ${subscription.describe()}');
      }
    }
    if (snapshot.lastEvent != null) {
      buffer.writeln(
        'last_event: ${snapshot.lastEvent!.at.toIso8601String()} ${snapshot.lastEvent!.outcome} kind=${snapshot.lastEvent!.kind} id=${snapshot.lastEvent!.eventId} reason=${snapshot.lastEvent!.reason}',
      );
    } else {
      buffer.writeln('last_event: -');
    }
    buffer.writeln('recent_history (${snapshot.recentHistory.length}):');
    if (snapshot.recentHistory.isEmpty) {
      buffer.writeln('  - none');
    } else {
      for (final entry in snapshot.recentHistory) {
        buffer.writeln('  - ${entry.describe()}');
      }
    }
    return buffer.toString().trimRight();
  }

  bool _isRefreshStillActive(int generation) {
    final isActive = _started && _activeRefreshGeneration == generation;
    if (!isActive) {
      _recordHistory(
        category: 'refresh',
        detail: 'aborted before completion',
        generation: generation,
        trigger: _activeRefreshTrigger,
      );
    }
    return isActive;
  }

  void _recordHistory({
    required String category,
    required String detail,
    int? generation,
    SyncRefreshTrigger? trigger,
  }) {
    _recentHistory.addLast(
      SyncRecentHistoryEntry(
        at: DateTime.now().toUtc(),
        category: category,
        detail: detail,
        generation: generation,
        trigger: trigger?.value,
      ),
    );
    while (_recentHistory.length > _maxRecentHistory) {
      _recentHistory.removeFirst();
    }
    _publishDiagnosticsRevision();
  }

  Future<void> _cleanupInactiveSubscription({
    required String subscriptionId,
    required NostrService nostrService,
    required int generation,
    required SyncRefreshTrigger trigger,
  }) async {
    _recordHistory(
      category: 'subscription',
      detail: 'cleaned up late subscribe response for $subscriptionId',
      generation: generation,
      trigger: trigger,
    );
    try {
      await nostrService.unsubscribe(subscriptionId);
    } catch (error) {
      _unsubscribeFailureCount += 1;
      _recordHistory(
        category: 'subscription',
        detail:
            'unsubscribe failed for $subscriptionId (${_safeErrorSummary(error)})',
        generation: generation,
        trigger: trigger,
      );
    }
  }

  void _publishDiagnosticsRevision() {
    if (_diagnosticsRevisionController.isClosed) {
      return;
    }
    _diagnosticsRevision += 1;
    _diagnosticsRevisionController.add(_diagnosticsRevision);
  }

  String _safeErrorSummary(Object error) {
    var summary = '$error';
    summary = summary.replaceAll(
      RegExp(
        r'"(content|sig|privateKeyHex|private_key|secret|nsec)"\s*:\s*"[^"]*"',
      ),
      r'"$1":"[redacted]"',
    );
    if (summary.length > 220) {
      summary = '${summary.substring(0, 217)}...';
    }
    return summary;
  }

  String _formatTime(DateTime? value) {
    return value?.toIso8601String() ?? '-';
  }
}
