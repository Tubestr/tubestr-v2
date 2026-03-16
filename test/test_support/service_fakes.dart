import 'dart:async';

import 'package:dio/dio.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/blossom/blossom_client.dart';
import 'package:mytube/services/mdk/mdk_service.dart';
import 'package:mytube/services/nostr/nostr_service.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

class FakeBlossomClient extends BlossomClient {
  FakeBlossomClient({this.unavailableServer = 'https://snapshot.example'})
    : super(Dio());

  final String unavailableServer;
  final List<List<String>> attempts = [];
  final List<String> reportedServers = [];
  final List<String> reportedEventJsons = [];

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
  Future<void> reportBlob({
    required String server,
    required String eventJson,
  }) async {
    reportedServers.add(server);
    reportedEventJsons.add(eventJson);
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
  String? lastCreatedMessageContent;
  List<String>? lastRemovedMemberPubkeys;

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
    return createGroupResult!;
  }

  @override
  Future<MdkGroupSummary> createGroup({
    required String creatorPublicKeyHex,
    required String name,
    required String description,
    required List<String> relays,
    List<String> memberKeyPackageEventJsons = const [],
  }) async {
    return createGroupSummaryResult ??
        createGroupResult!.group;
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
  Future<List<String>> getGroupMembers({
    required String mlsGroupIdHex,
  }) async {
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
    lastCreatedMessageContent = content;
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
    return List<int>.from('plaintext-$filename'.codeUnits);
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
  final List<String> publishedEventJsons = [];
  List<Nip01Event> queryEventsResult = const [];
  NdkResponse? subscribeResult;
  List<String> relayList = const ['wss://relay.example'];
  List<String> blossomServers = const ['https://blossom.example'];
  List<String> fetchedBlossomServers = const ['https://blossom.example'];
  String? unwrapGiftWrapRumorJsonResult;
  final Map<String, Filter> subscriptionFilters = {};
  final Map<String, StreamController<Nip01Event>> subscriptionControllers = {};
  final List<String> unsubscribedSubscriptionIds = [];

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
  }) async {}

  @override
  Future<String> publishSignedEventJson({
    required ParentIdentity identity,
    required String eventJson,
    List<String>? relays,
  }) async {
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
    return queryEventsResult;
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
    return subscribeResult ?? NdkResponse(subscriptionId, controller.stream);
  }

  @override
  Future<void> unsubscribe(String subscriptionId) async {
    unsubscribedSubscriptionIds.add(subscriptionId);
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
