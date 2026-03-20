import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mytube/core/constants.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/blossom/blossom_client.dart';
import 'package:mytube/services/identity/identity_service.dart';
import 'package:mytube/services/mdk/mdk_service.dart';
import 'package:mytube/services/nostr/nostr_service.dart';
import 'package:mytube/services/safety/safety_hq_backend_client.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

MdkGroupSummary fakeGroupSummary({
  required String mlsGroupIdHex,
  required String nostrGroupIdHex,
  required String name,
  required String description,
  required int memberCount,
  List<String> adminPubkeysHex = const ['parent-pubkey'],
}) {
  return MdkGroupSummary(
    mlsGroupIdHex: mlsGroupIdHex,
    nostrGroupIdHex: nostrGroupIdHex,
    name: name,
    description: description,
    memberCount: memberCount,
    adminPubkeysHex: adminPubkeysHex,
  );
}

class FakeBlossomClient extends BlossomClient {
  FakeBlossomClient({this.unavailableServer = 'https://snapshot.example'})
    : super(Dio());

  final String unavailableServer;
  final List<List<String>> attempts = [];
  final List<String> reportedServers = [];
  final List<String> reportedEventJsons = [];
  final List<String> uploadServers = [];
  final List<String?> uploadAuthHeaders = [];
  final Set<String> failingUploadServers = <String>{};

  @override
  Future<List<int>> downloadBlob({
    required String hash,
    required List<String> servers,
  }) async {
    attempts.add(List<String>.from(servers));
    if (servers.contains(unavailableServer)) {
      throw StateError('preferred server unavailable');
    }
    return List<int>.from('ciphertext-$hash'.codeUnits);
  }

  @override
  Future<UploadedBlob> uploadEncryptedBlob({
    required String server,
    required List<int> bytes,
    required String mimeType,
    BlossomUploadAuth? auth,
  }) async {
    if (failingUploadServers.contains(server)) {
      throw StateError('upload failed for $server');
    }
    uploadServers.add(server);
    uploadAuthHeaders.add(auth?.authorizationHeaderValue);
    return UploadedBlob(
      hash: sha256.convert(bytes).toString(),
      length: bytes.length,
      server: server,
    );
  }

  @override
  Future<void> reportBlob({
    required String server,
    required String eventJson,
  }) async {
    reportedServers.add(server);
    reportedEventJsons.add(eventJson);
  }
}

class FakeIdentityService extends IdentityService {
  FakeIdentityService({required this.identity, required super.database})
    : super(secureStorage: const FlutterSecureStorage());

  final ParentIdentity? identity;

  @override
  Future<ParentIdentity?> loadIdentity() async => identity;
}

class FakeSafetyHqBackendClient implements SafetyHqBackendClient {
  FakeSafetyHqBackendClient({
    SafetyHqBootstrapData? bootstrapData,
    this.throwOnFetch = false,
  }) : bootstrapData =
           bootstrapData ??
           SafetyHqBootstrapData(
             servicePublicKeyHex: AppConstants.safetyHqServicePublicKeyHex,
             signedKeyPackageEventJson: '{"id":"backend-key-package"}',
             keyPackageEventId: 'backend-key-package',
             relays: const ['wss://no.str.cr'],
             version: 'v1',
             generatedAt: DateTime.parse('2026-03-19T14:15:50.251046778Z'),
           );

  final SafetyHqBootstrapData bootstrapData;
  final bool throwOnFetch;

  @override
  Future<SafetyHqBootstrapData> fetchBootstrap() async {
    if (throwOnFetch) {
      throw StateError('bootstrap unavailable');
    }
    return bootstrapData;
  }
}

class FakeMdkService extends MdkService {
  KeyPackageEventData? keyPackageEventData;
  MdkCreateGroupResult? createGroupResult;
  MdkGroupSummary? createGroupSummaryResult;
  List<MdkGroupSummary> groupSummariesResult = const [];
  MdkProcessedMessage? processedMessage;
  List<MdkPendingWelcome> pendingWelcomesResult = const [];
  MdkGroupSummary? acceptedWelcomeGroup;
  MdkCreatedMessage? createdMessageResult;
  MdkGroupUpdate? removedGroupUpdate;
  List<String> groupMembersResult = const [];
  String? lastProcessedWelcomeRumor;
  String? lastDecryptUrl;
  String? lastAcceptedWelcomeEventId;
  int? lastCreatedMessageKind;
  String? lastCreatedMessageGroupId;
  final List<String> createdMessageGroupIds = [];
  String? lastCreatedMessageContent;
  int? lastCreatedMessageCreatedAt;
  List<String>? lastRemovedMemberPubkeys;
  String? lastCreateGroupName;
  String? lastCreateGroupDescription;

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<KeyPackageEventData> createKeyPackageEvent({
    required String publicKeyHex,
    required List<String> relays,
  }) async {
    return keyPackageEventData!;
  }

  @override
  Future<MdkCreateGroupResult> createGroupWithWelcomes({
    required String creatorPublicKeyHex,
    required String name,
    required String description,
    required List<String> relays,
    List<String> memberKeyPackageEventJsons = const [],
  }) async {
    lastCreateGroupName = name;
    lastCreateGroupDescription = description;
    final result = createGroupResult!;
    return MdkCreateGroupResult(
      group: MdkGroupSummary(
        mlsGroupIdHex: result.group.mlsGroupIdHex,
        nostrGroupIdHex: result.group.nostrGroupIdHex,
        name: name,
        description: description,
        memberCount: result.group.memberCount,
        adminPubkeysHex: result.group.adminPubkeysHex,
      ),
      welcomeRumorJsons: result.welcomeRumorJsons,
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
    lastCreateGroupName = name;
    lastCreateGroupDescription = description;
    final result = createGroupSummaryResult ?? createGroupResult!.group;
    return MdkGroupSummary(
      mlsGroupIdHex: result.mlsGroupIdHex,
      nostrGroupIdHex: result.nostrGroupIdHex,
      name: name,
      description: description,
      memberCount: result.memberCount,
      adminPubkeysHex: result.adminPubkeysHex,
    );
  }

  @override
  Future<List<MdkGroupSummary>> getGroupSummaries() async {
    return groupSummariesResult;
  }

  @override
  Future<List<MdkPendingWelcome>> getPendingWelcomes() async {
    return pendingWelcomesResult;
  }

  @override
  Future<MdkPendingWelcome> processWelcomeRumor({
    required String welcomeRumorJson,
  }) async {
    lastProcessedWelcomeRumor = welcomeRumorJson;
    return const MdkPendingWelcome(
      welcomeEventIdHex: 'welcome-event',
      wrapperEventIdHex: 'wrapper-event',
      mlsGroupIdHex: 'mls-group',
      nostrGroupIdHex: 'nostr-group',
      groupName: 'Family Space',
      groupDescription: 'Legacy welcome',
      memberCount: 2,
      welcomerPubkeyHex: 'welcomer',
      relays: ['wss://relay.example'],
      state: 'pending',
    );
  }

  @override
  Future<MdkGroupSummary> acceptPendingWelcome({
    required String welcomeEventIdHex,
  }) async {
    lastAcceptedWelcomeEventId = welcomeEventIdHex;
    return acceptedWelcomeGroup!;
  }

  @override
  Future<List<String>> getGroupMembers({required String mlsGroupIdHex}) async {
    return groupMembersResult;
  }

  @override
  Future<MdkGroupUpdate> removeGroupMembers({
    required String mlsGroupIdHex,
    required List<String> memberPubkeysHex,
  }) async {
    lastRemovedMemberPubkeys = List<String>.from(memberPubkeysHex);
    return removedGroupUpdate ??
        MdkGroupUpdate(
          wrapperEventJson: '{"id":"commit"}',
          wrapperEventIdHex: 'commit',
          mlsGroupIdHex: mlsGroupIdHex,
        );
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
    lastCreatedMessageKind = kind;
    lastCreatedMessageGroupId = mlsGroupIdHex;
    createdMessageGroupIds.add(mlsGroupIdHex);
    lastCreatedMessageContent = content;
    lastCreatedMessageCreatedAt = createdAt;
    return createdMessageResult ??
        MdkCreatedMessage(
          wrapperEventJson: '{"id":"wrapped"}',
          wrapperEventIdHex: 'wrapped',
          rumorEventIdHex: 'rumor',
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
    lastDecryptUrl = url;
    if (mimeType == 'video/mp4') {
      return <int>[
        0x00,
        0x00,
        0x00,
        0x18,
        0x66,
        0x74,
        0x79,
        0x70,
        0x69,
        0x73,
        0x6F,
        0x6D,
      ];
    }
    if (mimeType == 'image/jpeg') {
      return <int>[0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10];
    }
    if (mimeType == 'image/png') {
      return <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A];
    }
    return List<int>.from('plaintext-$filename'.codeUnits);
  }

  @override
  Future<MdkEncryptedMedia> encryptMedia({
    required String mlsGroupIdHex,
    required List<int> bytes,
    required String mimeType,
    required String filename,
  }) async {
    final encryptedBytes = List<int>.from(utf8.encode('ciphertext-$filename'));
    return MdkEncryptedMedia(
      encryptedBytes: encryptedBytes,
      encryptedHashHex: sha256.convert(encryptedBytes).toString(),
      originalHashHex: sha256.convert(bytes).toString(),
      mimeType: mimeType,
      filename: filename,
      originalSize: bytes.length,
      encryptedSize: encryptedBytes.length,
      nonceHex: 'nonce-$filename',
      schemeVersion: 'mip04-v2',
      epoch: 1,
    );
  }

  @override
  Future<MdkProcessedMessage> processMessageEvent({
    required String eventJson,
  }) async {
    return processedMessage!;
  }
}

class FakeNostrService implements NostrService {
  String? lastPublishedEventJson;
  String? lastGiftWrapRumorJson;
  String? lastGiftWrapRecipient;
  String? lastPublishedDisplayName;
  final List<String> publishedEventJsons = [];
  int? lastCreatedSignedEventKind;
  String? lastCreatedSignedEventContent;
  List<List<String>>? lastCreatedSignedEventTags;
  List<Nip01Event> queryEventsResult = const [];
  NdkResponse? subscribeResult;
  List<String> relayList = const ['wss://relay.example'];
  List<String> blossomServers = const ['https://blossom.example'];
  List<String> fetchedBlossomServers = const ['https://blossom.example'];
  String? unwrapGiftWrapRumorJsonResult;
  bool throwOnPublishSignedEvent = false;
  bool throwOnPublishParentProfile = false;
  final Set<String> unsubscribeFailures = <String>{};
  final Map<String, Filter> subscriptionFilters = {};
  final Map<String, StreamController<Nip01Event>> subscriptionControllers = {};
  final List<String> unsubscribedSubscriptionIds = [];
  Filter? lastQueryFilter;

  List<Nip01Event> _matchingEvents(Filter filter) {
    final matches = queryEventsResult
        .where((event) => _matches(filter, event))
        .toList(growable: false);
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

  @override
  Future<void> connect() async {}

  @override
  Future<List<String>> loadBlossomServerList() async => blossomServers;

  @override
  Future<String> createSignedKeyPackageEventJson({
    required ParentIdentity identity,
    required String content,
    required String tagsJson,
  }) async {
    return '{"kind":443,"content":"$content"}';
  }

  @override
  Future<String> createSignedEventJson({
    required ParentIdentity identity,
    required int kind,
    required List<List<String>> tags,
    required String content,
    int? createdAt,
  }) async {
    lastCreatedSignedEventKind = kind;
    lastCreatedSignedEventContent = content;
    lastCreatedSignedEventTags = tags
        .map((tag) => List<String>.from(tag))
        .toList(growable: false);
    return '{"kind":$kind,"content":"$content"}';
  }

  @override
  Future<List<String>> loadRelayList() async => relayList;

  @override
  Future<String> publishBlossomServerList({
    required ParentIdentity identity,
    List<String>? servers,
    List<String>? relays,
  }) async {
    return 'blossom-event-id';
  }

  @override
  Future<String> publishKeyPackageEvent({
    required ParentIdentity identity,
    required String content,
    required String tagsJson,
    List<String>? relays,
  }) async {
    return 'key-package-event-id';
  }

  @override
  Future<String> publishGiftWrappedRumor({
    required ParentIdentity identity,
    required String rumorEventJson,
    required String recipientPublicKeyHex,
    List<String>? relays,
  }) async {
    lastGiftWrapRumorJson = rumorEventJson;
    lastGiftWrapRecipient = recipientPublicKeyHex;
    return 'gift-wrap-id';
  }

  @override
  Future<void> publishParentProfile({
    required ParentIdentity identity,
    required String displayName,
  }) async {
    if (throwOnPublishParentProfile) {
      throw StateError('relay unavailable');
    }
    lastPublishedDisplayName = displayName;
  }

  @override
  Future<String> publishSignedEventJson({
    required ParentIdentity identity,
    required String eventJson,
    List<String>? relays,
  }) async {
    if (throwOnPublishSignedEvent) {
      throw StateError('relay unavailable');
    }
    lastPublishedEventJson = eventJson;
    publishedEventJsons.add(eventJson);
    return 'event-id';
  }

  @override
  Future<List<Nip01Event>> queryEvents({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
  }) async {
    lastQueryFilter = filter;
    return _matchingEvents(filter);
  }

  @override
  Future<void> saveRelayList(List<String> relays) async {
    relayList = relays;
  }

  @override
  Future<void> saveBlossomServerList(List<String> servers) async {
    blossomServers = servers;
  }

  @override
  Future<NdkResponse> subscribe({
    required String subscriptionId,
    required Filter filter,
    List<String>? relays,
  }) async {
    subscriptionFilters[subscriptionId] = filter;
    final controller = StreamController<Nip01Event>.broadcast();
    subscriptionControllers[subscriptionId] = controller;
    Future<void>.delayed(Duration.zero, () {
      if (controller.isClosed) {
        return;
      }
      for (final event in _matchingEvents(filter)) {
        controller.add(event);
      }
    });
    return subscribeResult ?? NdkResponse(subscriptionId, controller.stream);
  }

  @override
  Future<void> unsubscribe(String subscriptionId) async {
    unsubscribedSubscriptionIds.add(subscriptionId);
    if (unsubscribeFailures.contains(subscriptionId)) {
      throw StateError('unsubscribe failed for $subscriptionId');
    }
    await subscriptionControllers.remove(subscriptionId)?.close();
  }

  @override
  Future<List<String>> fetchBlossomServerList({
    required String publicKeyHex,
    List<String>? relays,
  }) async {
    return fetchedBlossomServers;
  }

  @override
  Future<String?> unwrapGiftWrapRumorJson({
    required ParentIdentity identity,
    required Nip01Event giftWrapEvent,
  }) async {
    return unwrapGiftWrapRumorJsonResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
