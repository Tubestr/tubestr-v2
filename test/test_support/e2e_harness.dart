import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mytube/core/constants.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/blossom/blossom_client.dart';
import 'package:mytube/services/connections/family_connection_service.dart';
import 'package:mytube/services/engagement/like_coordinator.dart';
import 'package:mytube/services/engagement/reaction_coordinator.dart';
import 'package:mytube/services/approval/content_scan_service.dart';
import 'package:mytube/services/approval/media_signal_extraction_service.dart';
import 'package:mytube/services/approval/video_approval_service.dart';
import 'package:mytube/services/identity/identity_service.dart';
import 'package:mytube/services/identity/parent_profile_service.dart';
import 'package:mytube/services/mdk/mdk_service.dart';
import 'package:mytube/services/media/remote_media_service.dart';
import 'package:mytube/services/nostr/nostr_service.dart';
import 'package:mytube/services/offline/offline_action_processor.dart';
import 'package:mytube/services/offline/offline_action_store.dart';
import 'package:mytube/services/safety/moderation_coordinator.dart';
import 'package:mytube/services/safety/report_coordinator.dart';
import 'package:mytube/services/safety/safety_hq_service.dart';
import 'package:mytube/services/share/managed_video_upload_service.dart';
import 'package:mytube/services/share/share_history_service.dart';
import 'package:mytube/services/share/video_lifecycle_coordinator.dart';
import 'package:mytube/services/share/video_share_coordinator.dart';
import 'package:mytube/services/sync/sync_coordinator.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

class LoopbackRelayBus {
  final List<LoopbackNostrService> _clients = [];
  final List<Nip01Event> _events = [];
  int _nextId = 1;

  void _register(LoopbackNostrService service) {
    _clients.add(service);
  }

  String nextEventId() => 'relay-${_nextId++}';

  Future<void> publish(Nip01Event event) async {
    _events.add(event);
    for (final client in _clients) {
      client.deliver(event);
    }
  }

  List<Nip01Event> query(Filter filter) {
    final matches = _events.where((event) => _matches(filter, event)).toList();
    if (filter.limit != null && matches.length > filter.limit!) {
      return matches.sublist(max(0, matches.length - filter.limit!));
    }
    return matches;
  }

  bool _matches(Filter filter, Nip01Event event) {
    if (filter.ids != null && !filter.ids!.contains(event.id)) {
      return false;
    }
    if (filter.authors != null && !filter.authors!.contains(event.pubKey)) {
      return false;
    }
    if (filter.kinds != null && !filter.kinds!.contains(event.kind)) {
      return false;
    }
    if (filter.since != null && event.createdAt < filter.since!) {
      return false;
    }
    if (filter.until != null && event.createdAt > filter.until!) {
      return false;
    }
    if (filter.search != null &&
        !event.content.toLowerCase().contains(filter.search!.toLowerCase())) {
      return false;
    }

    final tags = filter.tags;
    if (tags != null) {
      for (final entry in tags.entries) {
        final key = entry.key.startsWith('#')
            ? entry.key.substring(1)
            : entry.key;
        final eventValues = event.getTags(key);
        if (eventValues.isEmpty ||
            !entry.value.any((value) => eventValues.contains(value))) {
          return false;
        }
      }
    }

    return true;
  }
}

class LoopbackNostrService implements NostrService {
  LoopbackNostrService(this._bus) {
    _bus._register(this);
  }

  final LoopbackRelayBus _bus;
  final Map<String, _LoopbackSubscription> _subscriptions = {};
  List<String> relayList = const ['wss://loopback.local'];
  List<String> blossomServers = const ['https://blossom.loopback'];
  bool failPublishes = false;

  @override
  Future<void> connect() async {}

  @override
  Future<String> createSignedKeyPackageEventJson({
    required ParentIdentity identity,
    required String content,
    required String tagsJson,
  }) async {
    final event = Nip01Event(
      id: _bus.nextEventId(),
      pubKey: identity.publicKeyHex,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: MarmotKinds.keyPackage,
      tags: _decodeTags(tagsJson),
      content: content,
      sig: 'sig-${identity.publicKeyHex}',
    );
    return Nip01EventModel.fromEntity(event).toJsonString();
  }

  @override
  Future<String> createSignedEventJson({
    required ParentIdentity identity,
    required int kind,
    required List<List<String>> tags,
    required String content,
    int? createdAt,
  }) async {
    final event = Nip01Event(
      id: _bus.nextEventId(),
      pubKey: identity.publicKeyHex,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: kind,
      tags: tags,
      content: content,
      sig: 'sig-${identity.publicKeyHex}',
    );
    return Nip01EventModel.fromEntity(event).toJsonString();
  }

  void deliver(Nip01Event event) {
    for (final entry in _subscriptions.values) {
      if (_bus._matches(entry.filter, event)) {
        entry.controller.add(event);
      }
    }
  }

  @override
  Future<List<String>> fetchBlossomServerList({
    required String publicKeyHex,
    List<String>? relays,
  }) async {
    final events = _bus.query(
      Filter(
        authors: [publicKeyHex],
        kinds: [MarmotKinds.blossomServers],
        limit: 1,
      ),
    );
    if (events.isEmpty) {
      return const [];
    }
    return events.first.tags
        .where((tag) => tag.isNotEmpty && tag.first == 'server')
        .map((tag) => tag.length > 1 ? tag[1] : '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<String>> loadBlossomServerList() async => blossomServers;

  @override
  Future<List<String>> loadRelayList() async => relayList;

  @override
  Future<String> publishBlossomServerList({
    required ParentIdentity identity,
    List<String>? servers,
    List<String>? relays,
  }) async {
    if (failPublishes) {
      throw StateError('Relay offline');
    }
    final activeServers = servers ?? blossomServers;
    blossomServers = activeServers;
    final event = Nip01Event(
      id: _bus.nextEventId(),
      pubKey: identity.publicKeyHex,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: MarmotKinds.blossomServers,
      tags: activeServers
          .map((server) => <String>['server', server])
          .toList(growable: false),
      content: '',
      sig: 'sig-${identity.publicKeyHex}',
    );
    await _bus.publish(event);
    return event.id;
  }

  @override
  Future<String> publishGiftWrappedRumor({
    required ParentIdentity identity,
    required String rumorEventJson,
    required String recipientPublicKeyHex,
    List<String>? relays,
  }) async {
    if (failPublishes) {
      throw StateError('Relay offline');
    }
    final event = Nip01Event(
      id: _bus.nextEventId(),
      pubKey: identity.publicKeyHex,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: MarmotKinds.giftWrap,
      tags: [
        ['p', recipientPublicKeyHex],
      ],
      content: rumorEventJson,
      sig: 'sig-${identity.publicKeyHex}',
    );
    await _bus.publish(event);
    return event.id;
  }

  @override
  Future<String> publishKeyPackageEvent({
    required ParentIdentity identity,
    required String content,
    required String tagsJson,
    List<String>? relays,
  }) async {
    final json = await createSignedKeyPackageEventJson(
      identity: identity,
      content: content,
      tagsJson: tagsJson,
    );
    return publishSignedEventJson(
      identity: identity,
      eventJson: json,
      relays: relays,
    );
  }

  @override
  Future<void> publishParentProfile({
    required ParentIdentity identity,
    required String displayName,
  }) async {
    if (failPublishes) {
      throw StateError('Relay offline');
    }
    final event = Nip01Event(
      id: _bus.nextEventId(),
      pubKey: identity.publicKeyHex,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: 0,
      tags: const [],
      content: jsonEncode({
        'display_name': displayName,
        'name': displayName,
        'about': 'Parent account for MyTube',
      }),
      sig: 'sig-${identity.publicKeyHex}',
    );
    await _bus.publish(event);
  }

  @override
  Future<String> publishSignedEventJson({
    required ParentIdentity identity,
    required String eventJson,
    List<String>? relays,
  }) async {
    if (failPublishes) {
      throw StateError('Relay offline');
    }
    final event = Nip01EventModel.fromJson(
      jsonDecode(eventJson) as Map<String, dynamic>,
    );
    await _bus.publish(event);
    return event.id;
  }

  @override
  Future<List<Nip01Event>> queryEvents({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
  }) async {
    return _bus.query(filter);
  }

  @override
  Future<void> saveBlossomServerList(List<String> servers) async {
    blossomServers = servers;
  }

  @override
  Future<void> saveRelayList(List<String> relays) async {
    relayList = relays;
  }

  @override
  Future<NdkResponse> subscribe({
    required String subscriptionId,
    required Filter filter,
    List<String>? relays,
  }) async {
    final controller = StreamController<Nip01Event>.broadcast();
    _subscriptions[subscriptionId] = _LoopbackSubscription(
      filter: filter,
      controller: controller,
    );
    Future<void>.delayed(Duration.zero, () {
      if (controller.isClosed) {
        return;
      }
      for (final event in _bus.query(filter)) {
        controller.add(event);
      }
    });
    return NdkResponse(subscriptionId, controller.stream);
  }

  @override
  Future<void> unsubscribe(String subscriptionId) async {
    final removed = _subscriptions.remove(subscriptionId);
    await removed?.controller.close();
  }

  @override
  Future<String?> unwrapGiftWrapRumorJson({
    required ParentIdentity identity,
    required Nip01Event giftWrapEvent,
  }) async {
    return giftWrapEvent.content;
  }

  List<List<String>> _decodeTags(String tagsJson) {
    final decoded = jsonDecode(tagsJson) as List<dynamic>;
    return decoded
        .map<List<String>>(
          (entry) => (entry as List<dynamic>)
              .map((value) => value.toString())
              .toList(growable: false),
        )
        .toList(growable: false);
  }
}

class _LoopbackSubscription {
  const _LoopbackSubscription({required this.filter, required this.controller});

  final Filter filter;
  final StreamController<Nip01Event> controller;
}

class InMemoryBlossomClient extends BlossomClient {
  InMemoryBlossomClient() : super(Dio());

  final Map<String, List<int>> _blobs = {};

  @override
  Future<List<int>> downloadBlob({
    required String hash,
    required List<String> servers,
  }) async {
    final bytes = _blobs[hash];
    if (bytes == null) {
      throw StateError('Blob not found: $hash');
    }
    return bytes;
  }

  @override
  Future<UploadedBlob> uploadEncryptedBlob({
    required String server,
    required List<int> bytes,
    required String mimeType,
    BlossomUploadAuth? auth,
  }) async {
    final hash = sha256.convert(bytes).toString();
    _blobs[hash] = bytes;
    return UploadedBlob(hash: hash, length: bytes.length, server: server);
  }
}

class LoopbackMdkService extends MdkService {
  LoopbackMdkService({
    required String ownerPublicKeyHex,
    required LoopbackMdkWorld world,
  }) : _ownerPublicKeyHex = ownerPublicKeyHex,
       _world = world;

  final String _ownerPublicKeyHex;
  final LoopbackMdkWorld _world;
  final Map<String, MdkGroupSummary> _localGroups = {};
  final Map<String, MdkPendingWelcome> _pendingWelcomes = {};
  int _nextKeyPackage = 1;
  int _nextEpoch = 1;

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<KeyPackageEventData> createKeyPackageEvent({
    required String publicKeyHex,
    required List<String> relays,
  }) async {
    final content = jsonEncode({
      'member_pubkey': publicKeyHex,
      'seq': _nextKeyPackage++,
    });
    return KeyPackageEventData(
      content: content,
      tagsJson: jsonEncode(const <List<String>>[]),
      hashRefHex: sha256.convert(utf8.encode(content)).toString(),
    );
  }

  @override
  Future<MdkGroupSummary> createGroup({
    required String creatorPublicKeyHex,
    required String name,
    required String description,
    required List<String> relays,
    List<String> memberKeyPackageEventJsons = const [],
  }) async {
    final result = await createGroupWithWelcomes(
      creatorPublicKeyHex: creatorPublicKeyHex,
      name: name,
      description: description,
      relays: relays,
      memberKeyPackageEventJsons: memberKeyPackageEventJsons,
    );
    return result.group;
  }

  @override
  Future<MdkCreateGroupResult> createGroupWithWelcomes({
    required String creatorPublicKeyHex,
    required String name,
    required String description,
    required List<String> relays,
    List<String> memberKeyPackageEventJsons = const [],
  }) async {
    final invitedPubkeys = memberKeyPackageEventJsons
        .map((json) {
          final event = Nip01EventModel.fromJson(
            jsonDecode(json) as Map<String, dynamic>,
          );
          final content = jsonDecode(event.content) as Map<String, dynamic>;
          return content['member_pubkey'] as String;
        })
        .toList(growable: false);

    final group = _world._createGroup(
      name: name,
      description: description,
      creatorPublicKeyHex: creatorPublicKeyHex,
      invitedPubkeys: invitedPubkeys,
    );
    final summary = group.toSummary();
    _localGroups[summary.mlsGroupIdHex] = summary;
    final welcomes = invitedPubkeys
        .map(
          (recipient) => Nip01EventModel.fromEntity(
            Nip01Event(
              id: _world.nextEventId(),
              pubKey: creatorPublicKeyHex,
              createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              kind: MarmotKinds.welcome,
              tags: const [],
              content: jsonEncode({
                'recipient': recipient,
                'group': {
                  'mls_group_id_hex': summary.mlsGroupIdHex,
                  'nostr_group_id_hex': summary.nostrGroupIdHex,
                  'name': summary.name,
                  'description': summary.description,
                  'member_count': summary.memberCount,
                  'admin_pubkeys_hex': summary.adminPubkeysHex,
                },
              }),
              sig: 'sig-$creatorPublicKeyHex',
            ),
          ).toJsonString(),
        )
        .toList(growable: false);

    return MdkCreateGroupResult(group: summary, welcomeRumorJsons: welcomes);
  }

  @override
  Future<MdkCreatedMessage> createApplicationMessage({
    required String mlsGroupIdHex,
    required String senderPublicKeyHex,
    required int kind,
    required String content,
    String? tagsJson,
    int? createdAt,
  }) async {
    final groupSummary =
        _localGroups[mlsGroupIdHex] ??
        _world._groupByMlsId(mlsGroupIdHex)?.toSummary();
    if (groupSummary == null) {
      throw StateError('Group not found');
    }
    final envelope = {
      'mls_group_id_hex': mlsGroupIdHex,
      'message_kind': kind,
      'message_content': content,
      'message_created_at':
          createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    final event = Nip01Event(
      id: _world.nextEventId(),
      pubKey: senderPublicKeyHex,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: MarmotKinds.groupCommit,
      tags: [
        ['h', groupSummary.nostrGroupIdHex],
      ],
      content: jsonEncode(envelope),
      sig: 'sig-$senderPublicKeyHex',
    );
    return MdkCreatedMessage(
      wrapperEventJson: Nip01EventModel.fromEntity(event).toJsonString(),
      wrapperEventIdHex: event.id,
      rumorEventIdHex: 'rumor-${event.id}',
      mlsGroupIdHex: mlsGroupIdHex,
    );
  }

  @override
  Future<List<int>> decryptMedia({
    required String mlsGroupIdHex,
    required List<int> encryptedBytes,
    required String originalHashHex,
    required String mimeType,
    required String filename,
    required String nonceHex,
    required String schemeVersion,
    required String url,
  }) async {
    return encryptedBytes.map((byte) => byte ^ 0xAA).toList(growable: false);
  }

  @override
  Future<MdkEncryptedMedia> encryptMedia({
    required String mlsGroupIdHex,
    required List<int> bytes,
    required String mimeType,
    required String filename,
  }) async {
    final encrypted = bytes.map((byte) => byte ^ 0xAA).toList(growable: false);
    return MdkEncryptedMedia(
      encryptedBytes: encrypted,
      encryptedHashHex: sha256.convert(encrypted).toString(),
      originalHashHex: sha256.convert(bytes).toString(),
      mimeType: mimeType,
      filename: filename,
      originalSize: bytes.length,
      encryptedSize: encrypted.length,
      nonceHex:
          'nonce-${sha256.convert(utf8.encode(filename)).toString().substring(0, 12)}',
      schemeVersion: 'loopback-mip04',
      epoch: _nextEpoch++,
    );
  }

  @override
  Future<List<MdkGroupSummary>> getGroupSummaries() async {
    return _localGroups.values.toList(growable: false);
  }

  @override
  Future<List<String>> getGroupMembers({required String mlsGroupIdHex}) async {
    return _world
            ._groupByMlsId(mlsGroupIdHex)
            ?.memberPubkeysHex
            .toList(growable: false) ??
        const <String>[];
  }

  @override
  Future<List<MdkPendingWelcome>> getPendingWelcomes() async {
    return _pendingWelcomes.values.toList(growable: false);
  }

  @override
  Future<MdkGroupSummary> acceptPendingWelcome({
    required String welcomeEventIdHex,
  }) async {
    final welcome = _pendingWelcomes.remove(welcomeEventIdHex);
    if (welcome == null) {
      throw StateError('Pending welcome not found');
    }
    final summary = MdkGroupSummary(
      mlsGroupIdHex: welcome.mlsGroupIdHex,
      nostrGroupIdHex: welcome.nostrGroupIdHex,
      name: welcome.groupName,
      description: welcome.groupDescription,
      memberCount: welcome.memberCount,
      adminPubkeysHex: [welcome.welcomerPubkeyHex],
    );
    _localGroups[summary.mlsGroupIdHex] = summary;
    return summary;
  }

  @override
  Future<MdkProcessedMessage> processMessageEvent({
    required String eventJson,
  }) async {
    final event = Nip01EventModel.fromJson(
      jsonDecode(eventJson) as Map<String, dynamic>,
    );
    final envelope = jsonDecode(event.content) as Map<String, dynamic>;
    if (!envelope.containsKey('message_kind')) {
      return MdkProcessedMessage(
        outcome: MdkMessageOutcome.commit,
        mlsGroupIdHex: envelope['mls_group_id_hex']?.toString() ?? '',
        messageEventIdHex: event.id,
        wrapperEventIdHex: event.id,
        pubkeyHex: event.pubKey,
        kind: event.kind,
        content: event.content,
        createdAt: event.createdAt,
        state: 'processed',
      );
    }
    return MdkProcessedMessage(
      outcome: MdkMessageOutcome.applicationMessage,
      mlsGroupIdHex: envelope['mls_group_id_hex'] as String,
      messageEventIdHex: event.id,
      wrapperEventIdHex: event.id,
      pubkeyHex: event.pubKey,
      kind: envelope['message_kind'] as int,
      content: envelope['message_content'] as String,
      createdAt: envelope['message_created_at'] as int,
      state: 'processed',
    );
  }

  @override
  Future<MdkPendingWelcome> processWelcomeRumor({
    required String welcomeRumorJson,
  }) async {
    final decoded = jsonDecode(welcomeRumorJson) as Map<String, dynamic>;
    final payload = decoded['kind'] == MarmotKinds.welcome
        ? jsonDecode(decoded['content'] as String) as Map<String, dynamic>
        : decoded;
    final recipient = payload['recipient'] as String;
    if (recipient != _ownerPublicKeyHex) {
      throw StateError('Welcome was not intended for this parent');
    }
    final group = payload['group'] as Map<String, dynamic>;
    final pending = MdkPendingWelcome(
      welcomeEventIdHex: _world.nextWelcomeId(),
      wrapperEventIdHex: _world.nextEventId(),
      mlsGroupIdHex: group['mls_group_id_hex'] as String,
      nostrGroupIdHex: group['nostr_group_id_hex'] as String,
      groupName: group['name'] as String,
      groupDescription: group['description'] as String,
      memberCount: group['member_count'] as int,
      welcomerPubkeyHex: ((group['admin_pubkeys_hex'] as List<dynamic>).first)
          .toString(),
      relays: const ['wss://loopback.local'],
      state: 'pending',
    );
    _pendingWelcomes[pending.welcomeEventIdHex] = pending;
    return pending;
  }

  @override
  Future<MdkGroupUpdate> removeGroupMembers({
    required String mlsGroupIdHex,
    required List<String> memberPubkeysHex,
  }) async {
    final group = _world._groupByMlsId(mlsGroupIdHex);
    if (group == null) {
      throw StateError('Group not found');
    }
    group.memberPubkeysHex.removeWhere(memberPubkeysHex.contains);
    _localGroups[mlsGroupIdHex] = group.toSummary();
    final event = Nip01Event(
      id: _world.nextEventId(),
      pubKey: _ownerPublicKeyHex,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: MarmotKinds.groupCommit,
      tags: [
        ['h', group.nostrGroupIdHex],
      ],
      content: jsonEncode({
        'mls_group_id_hex': mlsGroupIdHex,
        'removed_members': memberPubkeysHex,
      }),
      sig: 'sig-$_ownerPublicKeyHex',
    );
    return MdkGroupUpdate(
      wrapperEventJson: Nip01EventModel.fromEntity(event).toJsonString(),
      wrapperEventIdHex: event.id,
      mlsGroupIdHex: mlsGroupIdHex,
    );
  }
}

class LoopbackMdkWorld {
  int _nextGroup = 1;
  int _nextEvent = 1;
  int _nextWelcome = 1;
  final Map<String, LoopbackGroup> _groupsByMlsId = {};

  LoopbackGroup _createGroup({
    required String name,
    required String description,
    required String creatorPublicKeyHex,
    required List<String> invitedPubkeys,
  }) {
    final group = LoopbackGroup(
      mlsGroupIdHex: 'mls-$_nextGroup',
      nostrGroupIdHex: 'nostr-$_nextGroup',
      name: name,
      description: description,
      adminPubkeysHex: [creatorPublicKeyHex],
      memberPubkeysHex: [creatorPublicKeyHex, ...invitedPubkeys],
    );
    _groupsByMlsId[group.mlsGroupIdHex] = group;
    _nextGroup += 1;
    return group;
  }

  LoopbackGroup? _groupByMlsId(String mlsGroupIdHex) =>
      _groupsByMlsId[mlsGroupIdHex];

  String nextEventId() => 'mdk-event-${_nextEvent++}';

  String nextWelcomeId() => 'welcome-${_nextWelcome++}';
}

class LoopbackGroup {
  LoopbackGroup({
    required this.mlsGroupIdHex,
    required this.nostrGroupIdHex,
    required this.name,
    required this.description,
    required this.adminPubkeysHex,
    required this.memberPubkeysHex,
  });

  final String mlsGroupIdHex;
  final String nostrGroupIdHex;
  final String name;
  final String description;
  final List<String> adminPubkeysHex;
  final List<String> memberPubkeysHex;

  MdkGroupSummary toSummary() {
    return MdkGroupSummary(
      mlsGroupIdHex: mlsGroupIdHex,
      nostrGroupIdHex: nostrGroupIdHex,
      name: name,
      description: description,
      memberCount: memberPubkeysHex.length,
      adminPubkeysHex: adminPubkeysHex,
    );
  }
}

class FamilyAppHarness {
  FamilyAppHarness._({
    required this.identity,
    required this.database,
    required this.mdk,
    required this.nostr,
    required this.blossom,
    required this.rootDir,
    required this.childId,
    required this.childName,
    required this.connectionService,
    required this.shareCoordinator,
    required this.lifecycleCoordinator,
    required this.syncCoordinator,
    required this.remoteMediaService,
    required this.likeCoordinator,
    required this.reportCoordinator,
    required this.moderationCoordinator,
    required this.parentProfileService,
    required this.offlineActionStore,
    required this.offlineActionProcessor,
  });

  final ParentIdentity identity;
  final AppDatabase database;
  final LoopbackMdkService mdk;
  final LoopbackNostrService nostr;
  final InMemoryBlossomClient blossom;
  final Directory rootDir;
  final String childId;
  final String childName;
  final FamilyConnectionService connectionService;
  final VideoShareCoordinator shareCoordinator;
  final VideoLifecycleCoordinator lifecycleCoordinator;
  final SyncCoordinator syncCoordinator;
  final RemoteMediaService remoteMediaService;
  final LikeCoordinator likeCoordinator;
  final ReportCoordinator reportCoordinator;
  final ModerationCoordinator moderationCoordinator;
  final ParentProfileService parentProfileService;
  final OfflineActionStore offlineActionStore;
  final OfflineActionProcessor offlineActionProcessor;

  static Future<FamilyAppHarness> create({
    required LoopbackRelayBus relayBus,
    required LoopbackMdkWorld mdkWorld,
    required InMemoryBlossomClient blossom,
    required ParentIdentity identity,
    required String childId,
    required String childName,
  }) async {
    final rootDir = await Directory.systemTemp.createTemp('mytube-family-');
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.upsertProfile(
      id: childId,
      name: childName,
      theme: 'campfire',
      avatarAsset: 'avatar.png',
    );
    final mdk = LoopbackMdkService(
      ownerPublicKeyHex: identity.publicKeyHex,
      world: mdkWorld,
    );
    final nostr = LoopbackNostrService(relayBus);
    final remoteMediaService = RemoteMediaService(
      database: database,
      blossomClient: blossom,
      mdkService: mdk,
      nostrService: nostr,
      supportDirectoryProvider: () async => rootDir,
    );
    final fakeIdentityService = _StaticIdentityService(
      identity: identity,
      database: database,
    );
    final syncCoordinator = SyncCoordinator(
      database: database,
      mdkService: mdk,
      nostrService: nostr,
      identityService: fakeIdentityService,
      remoteMediaService: remoteMediaService,
    );
    final offlineActionStore = OfflineActionStore(database: database);
    final shareHistoryService = ShareHistoryService(database: database);
    final parentProfileService = ParentProfileService(
      database: database,
      nostrService: nostr,
      offlineActionStore: offlineActionStore,
    );
    final likeCoordinator = LikeCoordinator(
      database: database,
      mdkService: mdk,
      nostrService: nostr,
      offlineActionStore: offlineActionStore,
    );
    final reactionCoordinator = ReactionCoordinator(
      database: database,
      mdkService: mdk,
      nostrService: nostr,
      offlineActionStore: offlineActionStore,
    );
    final safetyHqService = SafetyHqService(
      database: database,
      mdkService: mdk,
      nostrService: nostr,
      dio: Dio(),
    );
    final reportCoordinator = ReportCoordinator(
      database: database,
      mdkService: mdk,
      nostrService: nostr,
      offlineActionStore: offlineActionStore,
      safetyHqService: safetyHqService,
    );
    final lifecycleCoordinator = VideoLifecycleCoordinator(
      mdkService: mdk,
      nostrService: nostr,
    );
    final moderationCoordinator = ModerationCoordinator(
      database: database,
      blossomClient: blossom,
      mdkService: mdk,
      nostrService: nostr,
      videoLifecycleCoordinator: lifecycleCoordinator,
    );
    final shareCoordinator = VideoShareCoordinator(
      database: database,
      videoApprovalService: VideoApprovalService(
        database: database,
        scanService: const ContentScanService(),
        signalExtractionService: MediaSignalExtractionService(
          extractSignals: (video) async => MediaSignalExtractionResult(
            cvLabels: video.cvLabels,
            faceCount: video.faceCount,
            loudness: video.loudness,
          ),
        ),
      ),
      blossomClient: blossom,
      mdkService: mdk,
      nostrService: nostr,
      offlineActionStore: offlineActionStore,
      shareHistoryService: shareHistoryService,
      managedVideoUploadService: ManagedVideoUploadService(database: database),
    );
    final offlineActionProcessor = OfflineActionProcessor(
      store: offlineActionStore,
      identityService: fakeIdentityService,
      parentProfileService: parentProfileService,
      videoShareCoordinator: shareCoordinator,
      likeCoordinator: likeCoordinator,
      reactionCoordinator: reactionCoordinator,
      reportCoordinator: reportCoordinator,
    );
    return FamilyAppHarness._(
      identity: identity,
      database: database,
      mdk: mdk,
      nostr: nostr,
      blossom: blossom,
      rootDir: rootDir,
      childId: childId,
      childName: childName,
      connectionService: FamilyConnectionService(
        mdkService: mdk,
        nostrService: nostr,
      ),
      shareCoordinator: shareCoordinator,
      lifecycleCoordinator: lifecycleCoordinator,
      syncCoordinator: syncCoordinator,
      remoteMediaService: remoteMediaService,
      likeCoordinator: likeCoordinator,
      reportCoordinator: reportCoordinator,
      moderationCoordinator: moderationCoordinator,
      parentProfileService: parentProfileService,
      offlineActionStore: offlineActionStore,
      offlineActionProcessor: offlineActionProcessor,
    );
  }

  Future<void> dispose() async {
    await syncCoordinator.stop();
    await database.close();
    if (rootDir.existsSync()) {
      await rootDir.delete(recursive: true);
    }
  }
}

class _StaticIdentityService extends IdentityService {
  _StaticIdentityService({required this.identity, required super.database})
    : super(secureStorage: const FlutterSecureStorage());

  final ParentIdentity identity;

  @override
  Future<ParentIdentity?> loadIdentity() async => identity;
}
