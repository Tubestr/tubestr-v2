import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'api.dart' as bridge_api;
import 'frb_generated.dart';

class MdkValidationNote {
  const MdkValidationNote({required this.topic, required this.status});

  final String topic;
  final String status;
}

class KeyPackageEventData {
  const KeyPackageEventData({
    required this.content,
    required this.tagsJson,
    required this.hashRefHex,
  });

  final String content;
  final String tagsJson;
  final String hashRefHex;
}

class MdkGroupSummary {
  const MdkGroupSummary({
    required this.mlsGroupIdHex,
    required this.nostrGroupIdHex,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.adminPubkeysHex,
  });

  final String mlsGroupIdHex;
  final String nostrGroupIdHex;
  final String name;
  final String description;
  final int memberCount;
  final List<String> adminPubkeysHex;
}

class MdkPendingWelcome {
  const MdkPendingWelcome({
    required this.welcomeEventIdHex,
    required this.wrapperEventIdHex,
    required this.mlsGroupIdHex,
    required this.nostrGroupIdHex,
    required this.groupName,
    required this.groupDescription,
    required this.memberCount,
    required this.welcomerPubkeyHex,
    required this.relays,
    required this.state,
  });

  final String welcomeEventIdHex;
  final String wrapperEventIdHex;
  final String mlsGroupIdHex;
  final String nostrGroupIdHex;
  final String groupName;
  final String groupDescription;
  final int memberCount;
  final String welcomerPubkeyHex;
  final List<String> relays;
  final String state;
}

class MdkCreateGroupResult {
  const MdkCreateGroupResult({
    required this.group,
    required this.welcomeRumorJsons,
  });

  final MdkGroupSummary group;
  final List<String> welcomeRumorJsons;
}

class MdkGroupUpdate {
  const MdkGroupUpdate({
    required this.wrapperEventJson,
    required this.wrapperEventIdHex,
    required this.mlsGroupIdHex,
  });

  final String wrapperEventJson;
  final String wrapperEventIdHex;
  final String mlsGroupIdHex;
}

class MdkCreatedMessage {
  const MdkCreatedMessage({
    required this.wrapperEventJson,
    required this.wrapperEventIdHex,
    required this.rumorEventIdHex,
    required this.mlsGroupIdHex,
  });

  final String wrapperEventJson;
  final String wrapperEventIdHex;
  final String rumorEventIdHex;
  final String mlsGroupIdHex;
}

class MdkEncryptedMedia {
  const MdkEncryptedMedia({
    required this.encryptedBytes,
    required this.encryptedHashHex,
    required this.originalHashHex,
    required this.mimeType,
    required this.filename,
    required this.originalSize,
    required this.encryptedSize,
    required this.nonceHex,
    required this.schemeVersion,
    required this.epoch,
  });

  final List<int> encryptedBytes;
  final String encryptedHashHex;
  final String originalHashHex;
  final String mimeType;
  final String filename;
  final int originalSize;
  final int encryptedSize;
  final String nonceHex;
  final String schemeVersion;
  final int epoch;
}

enum MdkMessageOutcome {
  applicationMessage('application_message'),
  proposal('proposal'),
  pendingProposal('pending_proposal'),
  ignoredProposal('ignored_proposal'),
  externalJoinProposal('external_join_proposal'),
  commit('commit'),
  unprocessable('unprocessable'),
  previouslyFailed('previously_failed');

  const MdkMessageOutcome(this.value);

  final String value;

  static MdkMessageOutcome fromValue(String raw) {
    return MdkMessageOutcome.values.firstWhere(
      (value) => value.value == raw,
      orElse: () => MdkMessageOutcome.unprocessable,
    );
  }
}

class MdkProcessedMessage {
  const MdkProcessedMessage({
    required this.outcome,
    required this.mlsGroupIdHex,
    required this.messageEventIdHex,
    required this.wrapperEventIdHex,
    required this.pubkeyHex,
    required this.kind,
    required this.content,
    required this.createdAt,
    required this.state,
  });

  final MdkMessageOutcome outcome;
  final String mlsGroupIdHex;
  final String messageEventIdHex;
  final String wrapperEventIdHex;
  final String pubkeyHex;
  final int kind;
  final String content;
  final int createdAt;
  final String state;
}

class MdkService {
  bool _bridgeInitialized = false;

  Future<void> ensureInitialized() async {
    if (_bridgeInitialized) {
      return;
    }

    await MdkBridgeApi.init();
    final root = await getApplicationSupportDirectory();
    final dataDir = p.join(root.path, 'mdk');
    await bridge_api.initMdkUnencrypted(dataDir: dataDir);
    _bridgeInitialized = true;
  }

  Future<String> bridgeVersion() async {
    await ensureInitialized();
    return bridge_api.bridgeVersion();
  }

  Future<String> mdkDbPath() async {
    await ensureInitialized();
    return bridge_api.mdkDbPath();
  }

  Future<int> groupCount() async {
    await ensureInitialized();
    return bridge_api.groupCount();
  }

  Future<List<String>> groupSummaries() async {
    await ensureInitialized();
    return bridge_api.groupSummaries();
  }

  Future<List<MdkGroupSummary>> getGroupSummaries() async {
    await ensureInitialized();
    final result = await bridge_api.getGroupSummaries();
    return result
        .map(
          (group) => MdkGroupSummary(
            mlsGroupIdHex: group.mlsGroupIdHex,
            nostrGroupIdHex: group.nostrGroupIdHex,
            name: group.name,
            description: group.description,
            memberCount: group.memberCount,
            adminPubkeysHex: group.adminPubkeysHex,
          ),
        )
        .toList(growable: false);
  }

  Future<KeyPackageEventData> createKeyPackageEvent({
    required String publicKeyHex,
    required List<String> relays,
  }) async {
    await ensureInitialized();
    final result = await bridge_api.createKeyPackageEvent(
      publicKeyHex: publicKeyHex,
      relays: relays,
    );
    return KeyPackageEventData(
      content: result.content,
      tagsJson: result.tagsJson,
      hashRefHex: result.hashRefHex,
    );
  }

  Future<List<MdkPendingWelcome>> getPendingWelcomes() async {
    await ensureInitialized();
    final result = await bridge_api.getPendingWelcomeSummaries();
    return result
        .map(
          (welcome) => MdkPendingWelcome(
            welcomeEventIdHex: welcome.welcomeEventIdHex,
            wrapperEventIdHex: welcome.wrapperEventIdHex,
            mlsGroupIdHex: welcome.mlsGroupIdHex,
            nostrGroupIdHex: welcome.nostrGroupIdHex,
            groupName: welcome.groupName,
            groupDescription: welcome.groupDescription,
            memberCount: welcome.memberCount,
            welcomerPubkeyHex: welcome.welcomerPubkeyHex,
            relays: welcome.relays,
            state: welcome.state,
          ),
        )
        .toList(growable: false);
  }

  Future<List<MdkValidationNote>> validateOwnershipAssumptions() async {
    final version = await bridgeVersion();
    final count = await groupCount();

    return [
      MdkValidationNote(topic: 'bridge', status: 'Connected: $version'),
      MdkValidationNote(
        topic: 'storage',
        status: 'Initialized successfully at ${await mdkDbPath()}',
      ),
      MdkValidationNote(
        topic: 'groups',
        status: 'Bridge can query local group state. Count=$count',
      ),
      const MdkValidationNote(
        topic: 'next',
        status:
            'Wire createGroup/createMessage/processMessage/encryptMedia next.',
      ),
    ];
  }

  Future<MdkGroupSummary> createGroup({
    required String creatorPublicKeyHex,
    required String name,
    required String description,
    required List<String> relays,
    List<String> memberKeyPackageEventJsons = const [],
  }) async {
    await ensureInitialized();
    final result = await bridge_api.createLocalGroup(
      creatorPublicKeyHex: creatorPublicKeyHex,
      name: name,
      description: description,
      relays: relays,
      memberKeyPackageEventJsons: memberKeyPackageEventJsons,
    );
    return MdkGroupSummary(
      mlsGroupIdHex: result.mlsGroupIdHex,
      nostrGroupIdHex: result.nostrGroupIdHex,
      name: result.name,
      description: result.description,
      memberCount: result.memberCount,
      adminPubkeysHex: result.adminPubkeysHex,
    );
  }

  Future<MdkCreateGroupResult> createGroupWithWelcomes({
    required String creatorPublicKeyHex,
    required String name,
    required String description,
    required List<String> relays,
    List<String> memberKeyPackageEventJsons = const [],
  }) async {
    await ensureInitialized();
    final result = await bridge_api.createLocalGroupWithWelcomes(
      creatorPublicKeyHex: creatorPublicKeyHex,
      name: name,
      description: description,
      relays: relays,
      memberKeyPackageEventJsons: memberKeyPackageEventJsons,
    );
    return MdkCreateGroupResult(
      group: MdkGroupSummary(
        mlsGroupIdHex: result.group.mlsGroupIdHex,
        nostrGroupIdHex: result.group.nostrGroupIdHex,
        name: result.group.name,
        description: result.group.description,
        memberCount: result.group.memberCount,
        adminPubkeysHex: result.group.adminPubkeysHex,
      ),
      welcomeRumorJsons: result.welcomeRumorJsons,
    );
  }

  Future<MdkPendingWelcome> processWelcomeRumor({
    required String welcomeRumorJson,
  }) async {
    await ensureInitialized();
    final result = await bridge_api.processWelcomeRumor(
      welcomeRumorJson: welcomeRumorJson,
    );
    return MdkPendingWelcome(
      welcomeEventIdHex: result.welcomeEventIdHex,
      wrapperEventIdHex: result.wrapperEventIdHex,
      mlsGroupIdHex: result.mlsGroupIdHex,
      nostrGroupIdHex: result.nostrGroupIdHex,
      groupName: result.groupName,
      groupDescription: result.groupDescription,
      memberCount: result.memberCount,
      welcomerPubkeyHex: result.welcomerPubkeyHex,
      relays: result.relays,
      state: result.state,
    );
  }

  Future<MdkGroupSummary> acceptPendingWelcome({
    required String welcomeEventIdHex,
  }) async {
    await ensureInitialized();
    final result = await bridge_api.acceptPendingWelcome(
      welcomeEventIdHex: welcomeEventIdHex,
    );
    return MdkGroupSummary(
      mlsGroupIdHex: result.mlsGroupIdHex,
      nostrGroupIdHex: result.nostrGroupIdHex,
      name: result.name,
      description: result.description,
      memberCount: result.memberCount,
      adminPubkeysHex: result.adminPubkeysHex,
    );
  }

  Future<List<String>> getGroupMembers({
    required String mlsGroupIdHex,
  }) async {
    await ensureInitialized();
    return bridge_api.getGroupMembers(mlsGroupIdHex: mlsGroupIdHex);
  }

  Future<MdkGroupUpdate> removeGroupMembers({
    required String mlsGroupIdHex,
    required List<String> memberPubkeysHex,
  }) async {
    await ensureInitialized();
    final result = await bridge_api.removeGroupMembers(
      mlsGroupIdHex: mlsGroupIdHex,
      memberPubkeysHex: memberPubkeysHex,
    );
    return MdkGroupUpdate(
      wrapperEventJson: result.wrapperEventJson,
      wrapperEventIdHex: result.wrapperEventIdHex,
      mlsGroupIdHex: result.mlsGroupIdHex,
    );
  }

  Future<MdkCreatedMessage> createApplicationMessage({
    required String mlsGroupIdHex,
    required String senderPublicKeyHex,
    required int kind,
    required String content,
    String? tagsJson,
    int? createdAt,
  }) async {
    await ensureInitialized();
    final result = await bridge_api.createApplicationMessage(
      mlsGroupIdHex: mlsGroupIdHex,
      senderPublicKeyHex: senderPublicKeyHex,
      kind: kind,
      content: content,
      tagsJson: tagsJson,
      createdAt: createdAt == null ? null : BigInt.from(createdAt),
    );
    return MdkCreatedMessage(
      wrapperEventJson: result.wrapperEventJson,
      wrapperEventIdHex: result.wrapperEventIdHex,
      rumorEventIdHex: result.rumorEventIdHex,
      mlsGroupIdHex: result.mlsGroupIdHex,
    );
  }

  Future<MdkProcessedMessage> processMessageEvent({
    required String eventJson,
  }) async {
    await ensureInitialized();
    final result = await bridge_api.processMessageEvent(eventJson: eventJson);
    return MdkProcessedMessage(
      outcome: MdkMessageOutcome.fromValue(result.outcome),
      mlsGroupIdHex: result.mlsGroupIdHex,
      messageEventIdHex: result.messageEventIdHex,
      wrapperEventIdHex: result.wrapperEventIdHex,
      pubkeyHex: result.pubkeyHex,
      kind: result.kind,
      content: result.content,
      createdAt: result.createdAt.toInt(),
      state: result.state,
    );
  }

  Future<MdkEncryptedMedia> encryptMedia({
    required String mlsGroupIdHex,
    required List<int> bytes,
    required String mimeType,
    required String filename,
  }) async {
    await ensureInitialized();
    final result = await bridge_api.encryptMedia(
      mlsGroupIdHex: mlsGroupIdHex,
      bytes: bytes,
      mimeType: mimeType,
      filename: filename,
    );
    return MdkEncryptedMedia(
      encryptedBytes: result.encryptedData,
      encryptedHashHex: result.encryptedHashHex,
      originalHashHex: result.originalHashHex,
      mimeType: result.mimeType,
      filename: result.filename,
      originalSize: result.originalSize.toInt(),
      encryptedSize: result.encryptedSize.toInt(),
      nonceHex: result.nonceHex,
      schemeVersion: result.schemeVersion,
      epoch: result.epoch.toInt(),
    );
  }

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
    await ensureInitialized();
    return bridge_api.decryptMedia(
      mlsGroupIdHex: mlsGroupIdHex,
      encryptedBytes: encryptedBytes,
      originalHashHex: originalHashHex,
      mimeType: mimeType,
      filename: filename,
      nonceHex: nonceHex,
      schemeVersion: schemeVersion,
      url: url,
    );
  }
}
