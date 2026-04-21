import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/constants.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/marmot/invite_transport_models.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/connections/family_connection_service.dart';
import 'package:mytube/services/mdk/mdk_service.dart';
import 'package:ndk/entities.dart';

import '../../test_support/service_fakes.dart';

void main() {
  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub1parent',
    nsec: 'nsec1parent',
    createdAtIso: '2026-03-15T00:00:00Z',
  );

  test(
    'createInvite publishes a relay-discoverable key package and returns a compact invite',
    () async {
      final mdk = FakeMdkService()
        ..keyPackageEventData = const KeyPackageEventData(
          content: 'key-package-content',
          tagsJson:
              '[["d","30443-hash"],["encoding","base64"],["mls_proposals","0x000a"]]',
          tags443Json: '[["encoding","base64"],["mls_proposals","0x000a"]]',
          hashRefHex: 'hash-ref',
        );
      final nostr = FakeNostrService();
      final service = FamilyConnectionService(
        mdkService: mdk,
        nostrService: nostr,
        loadLocalDisplayName: () async => 'Lee',
      );

      final result = await service.createInvite(identity: identity);
      final packet = GroupInvitePacket.decode(result.payload);

      expect(result.payload, startsWith('tubestr://family-invite'));
      expect(result.payload, isNot(contains('key_package_event_json')));
      expect(packet.keyPackageEventId, isNull);
      expect(packet.inviterDisplayName, 'Lee');
      expect(
        result.keyPackageEventJson,
        '{"kind":30443,"content":"key-package-content"}',
      );
      expect(nostr.publishedEventJsons, [
        '{"kind":10051,"content":""}',
        result.keyPackageEventJson,
        '{"kind":443,"content":"key-package-content"}',
      ]);
      expect(nostr.createdSignedEventKinds, [
        MarmotKinds.keyPackageRelays,
        MarmotKinds.legacyKeyPackage,
      ]);
      expect(nostr.createdSignedEventTags.first, [
        ['relay', 'wss://relay.example'],
      ]);
      expect(
        nostr.lastCreatedSignedKeyPackageTagsJson,
        '[["d","30443-hash"],["encoding","base64"],["mls_proposals","0x000a"]]',
      );
      expect(nostr.lastCreatedSignedEventKind, MarmotKinds.legacyKeyPackage);
      expect(nostr.lastCreatedSignedEventTags, [
        ['encoding', 'base64'],
        ['mls_proposals', '0x000a'],
      ]);
    },
  );

  test(
    'publishCurrentKeyPackage republishes the current key package quietly',
    () async {
      final mdk = FakeMdkService()
        ..keyPackageEventData = const KeyPackageEventData(
          content: 'fresh-key-package-content',
          tagsJson:
              '[["d","30443-hash"],["encoding","base64"],["mls_proposals","0x000a"]]',
          tags443Json: '[["encoding","base64"],["mls_proposals","0x000a"]]',
          hashRefHex: 'hash-ref',
        );
      final nostr = FakeNostrService();
      final service = FamilyConnectionService(
        mdkService: mdk,
        nostrService: nostr,
        loadLocalDisplayName: () async => 'Lee',
      );

      await service.publishCurrentKeyPackage(identity: identity);

      expect(nostr.publishedEventJsons, [
        '{"kind":10051,"content":""}',
        '{"kind":30443,"content":"fresh-key-package-content"}',
        '{"kind":443,"content":"fresh-key-package-content"}',
      ]);
      expect(nostr.publishedEventRelays, [
        ['wss://relay.example', ...AppConstants.defaultRelays],
        ['wss://relay.example'],
        ['wss://relay.example'],
      ]);
      expect(nostr.lastPublishedDisplayName, 'Lee');
      expect(nostr.createdSignedEventKinds, [
        MarmotKinds.keyPackageRelays,
        MarmotKinds.legacyKeyPackage,
      ]);
      expect(nostr.createdSignedEventTags.first, [
        ['relay', 'wss://relay.example'],
      ]);
      expect(
        nostr.lastCreatedSignedKeyPackageTagsJson,
        '[["d","30443-hash"],["encoding","base64"],["mls_proposals","0x000a"]]',
      );
      expect(nostr.lastCreatedSignedEventKind, MarmotKinds.legacyKeyPackage);
      expect(nostr.lastCreatedSignedEventTags, [
        ['encoding', 'base64'],
        ['mls_proposals', '0x000a'],
      ]);
    },
  );

  test(
    'createInvite still works if key package relay discovery publish fails',
    () async {
      final mdk = FakeMdkService()
        ..keyPackageEventData = const KeyPackageEventData(
          content: 'key-package-content',
          tagsJson:
              '[["d","30443-hash"],["encoding","base64"],["mls_proposals","0x000a"]]',
          tags443Json: '[["encoding","base64"],["mls_proposals","0x000a"]]',
          hashRefHex: 'hash-ref',
        );
      final nostr = FakeNostrService()..throwOnPublishSignedEventCall = 1;
      final service = FamilyConnectionService(
        mdkService: mdk,
        nostrService: nostr,
      );

      final result = await service.createInvite(identity: identity);

      expect(result.payload, startsWith('tubestr://family-invite'));
      expect(nostr.publishSignedEventCallCount, 3);
      expect(nostr.createdSignedEventKinds, [
        MarmotKinds.keyPackageRelays,
        MarmotKinds.legacyKeyPackage,
      ]);
      expect(nostr.publishedEventJsons, [
        '{"kind":30443,"content":"key-package-content"}',
        '{"kind":443,"content":"key-package-content"}',
      ]);
    },
  );

  test('createInvite ignores malformed relay entries', () async {
    final mdk = FakeMdkService()
      ..keyPackageEventData = const KeyPackageEventData(
        content: 'key-package-content',
        tagsJson:
            '[["d","30443-hash"],["encoding","base64"],["mls_proposals","0x000a"]]',
        hashRefHex: 'hash-ref',
      );
    final nostr = FakeNostrService()
      ..relayList = const [
        'not-a-relay',
        'https://relay.example',
        'wss://relay.example',
        'wss://relay.example',
      ];
    final service = FamilyConnectionService(
      mdkService: mdk,
      nostrService: nostr,
    );

    await service.createInvite(identity: identity);

    expect(mdk.lastCreateKeyPackageRelays, ['wss://relay.example']);
    expect(nostr.createdSignedEventTags.first, [
      ['relay', 'wss://relay.example'],
    ]);
    expect(nostr.lastCreatedSignedEventTags, [
      ['encoding', 'base64'],
      ['mls_proposals', '0x000a'],
    ]);
  });

  test(
    'connectFromInvite creates a group from relay-discovered key packages and gift-wraps welcomes back',
    () async {
      final mdk = FakeMdkService()
        ..createGroupResult = const MdkCreateGroupResult(
          group: MdkGroupSummary(
            mlsGroupIdHex: 'mls-group',
            nostrGroupIdHex: 'nostr-group',
            name: 'Family Space',
            description: 'Created from scanned invite',
            memberCount: 2,
            adminPubkeysHex: ['parent-pubkey'],
          ),
          welcomeRumorJsons: ['{"kind":444,"content":"welcome"}'],
        );
      final nostr = FakeNostrService()
        ..queryEventsResult = [
          Nip01Event(
            id: 'meta-1',
            pubKey: 'remote-parent',
            createdAt: 1710460790,
            kind: 0,
            tags: const [],
            content: '{"display_name":"Lee & Emma"}',
            sig: 'sig-meta',
          ),
          Nip01Event(
            id: 'keypkg-1',
            pubKey: 'remote-parent',
            createdAt: 1710460800,
            kind: MarmotKinds.legacyKeyPackage,
            tags: const [],
            content: 'key-package-content',
            sig: 'sig-1',
          ),
        ];
      final service = FamilyConnectionService(
        mdkService: mdk,
        nostrService: nostr,
        loadLocalDisplayName: () async => 'Noah',
      );

      final payload = const GroupInvitePacket(
        publicKeyHex: 'remote-parent',
        createdAt: 1710460800,
        keyPackageEventId: 'keypkg-1',
        inviterDisplayName: 'Lee',
      ).encode();

      final result = await service.connectFromInvite(
        identity: identity,
        invitePayload: payload,
      );

      expect(result.group.name, 'Lee & Noah');
      expect(mdk.lastCreateGroupDescription, 'Connected Lee with Noah');
      expect(result.publishedWelcomeCount, 1);
      expect(nostr.lastGiftWrapRecipient, 'remote-parent');
      expect(nostr.lastGiftWrapRumorJson, '{"kind":444,"content":"welcome"}');
      expect(nostr.subscriptionFilters.values.single.kinds, [
        MarmotKinds.keyPackage,
        MarmotKinds.legacyKeyPackage,
      ]);
    },
  );

  test(
    'connectFromInvite stops when the inviter is already connected',
    () async {
      final mdk = FakeMdkService()
        ..groupSummariesResult = const [
          MdkGroupSummary(
            mlsGroupIdHex: 'existing-group',
            nostrGroupIdHex: 'existing-nostr-group',
            name: 'Lee & Noah',
            description: 'Connected Lee with Noah',
            memberCount: 2,
            adminPubkeysHex: ['parent-pubkey'],
          ),
        ]
        ..groupMembersResult = const ['parent-pubkey', 'remote-parent'];
      final nostr = FakeNostrService();
      final service = FamilyConnectionService(
        mdkService: mdk,
        nostrService: nostr,
        loadLocalDisplayName: () async => 'Noah',
      );

      final payload = const GroupInvitePacket(
        publicKeyHex: 'remote-parent',
        createdAt: 1710460800,
        inviterDisplayName: 'Lee',
      ).encode();

      await expectLater(
        service.connectFromInvite(identity: identity, invitePayload: payload),
        throwsA(isA<MdkAlreadyConnectedException>()),
      );
      expect(mdk.lastCreateGroupName, isNull);
      expect(nostr.lastGiftWrapRecipient, isNull);
    },
  );

  test(
    'connectFromInvite stops when a previous scan already sent a welcome',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final mdk = FakeMdkService()
        ..createGroupResult = const MdkCreateGroupResult(
          group: MdkGroupSummary(
            mlsGroupIdHex: 'pending-group',
            nostrGroupIdHex: 'pending-nostr-group',
            name: 'Lee & Noah',
            description: 'Connected Lee with Noah',
            memberCount: 2,
            adminPubkeysHex: ['parent-pubkey'],
          ),
          welcomeRumorJsons: ['{"kind":444,"content":"welcome"}'],
        );
      final nostr = FakeNostrService()
        ..queryEventsResult = [
          Nip01Event(
            id: 'keypkg-1',
            pubKey: 'remote-parent',
            createdAt: 1710460800,
            kind: MarmotKinds.legacyKeyPackage,
            tags: const [],
            content: 'key-package-content',
            sig: 'sig-1',
          ),
        ];
      final service = FamilyConnectionService(
        mdkService: mdk,
        nostrService: nostr,
        database: database,
        loadLocalDisplayName: () async => 'Noah',
      );
      final payload = const GroupInvitePacket(
        publicKeyHex: 'remote-parent',
        createdAt: 1710460800,
        keyPackageEventId: 'keypkg-1',
        inviterDisplayName: 'Lee',
      ).encode();

      await service.connectFromInvite(
        identity: identity,
        invitePayload: payload,
      );

      // Simulate the MLS group existing after the first connection
      mdk.groupSummariesResult = [mdk.createGroupResult!.group];

      await expectLater(
        service.connectFromInvite(identity: identity, invitePayload: payload),
        throwsA(isA<FamilyConnectionAlreadyPendingException>()),
      );
      expect(mdk.createGroupWithWelcomesCallCount, 1);
      expect(nostr.lastGiftWrapRecipient, 'remote-parent');
    },
  );

  test(
    'author resolution prefers current key packages over legacy events',
    () async {
      final mdk = FakeMdkService()
        ..createGroupResult = const MdkCreateGroupResult(
          group: MdkGroupSummary(
            mlsGroupIdHex: 'mls-group',
            nostrGroupIdHex: 'nostr-group',
            name: 'Family Space',
            description: 'Created from scanned invite',
            memberCount: 2,
            adminPubkeysHex: ['parent-pubkey'],
          ),
          welcomeRumorJsons: [],
        );
      final nostr = FakeNostrService()
        ..queryEventsResult = [
          Nip01Event(
            id: 'legacy-kp',
            pubKey: 'remote-parent',
            createdAt: 1710460801,
            kind: MarmotKinds.legacyKeyPackage,
            tags: const [],
            content: 'legacy-key-package-content',
            sig: 'sig-legacy',
          ),
          Nip01Event(
            id: 'current-kp',
            pubKey: 'remote-parent',
            createdAt: 1710460800,
            kind: MarmotKinds.keyPackage,
            tags: const [
              ['mls_proposals', '0x000a'],
            ],
            content: 'current-key-package-content',
            sig: 'sig-current',
          ),
        ];
      final service = FamilyConnectionService(
        mdkService: mdk,
        nostrService: nostr,
      );

      await service.connectFromInvite(
        identity: identity,
        invitePayload: const GroupInvitePacket(
          publicKeyHex: 'remote-parent',
          createdAt: 1710460800,
        ).encode(),
      );

      expect(
        mdk.lastCreateGroupWithWelcomesMemberKeyPackageEventJsons.single,
        contains('"kind":30443'),
      );
      expect(
        mdk.lastCreateGroupWithWelcomesMemberKeyPackageEventJsons.single,
        contains('current-key-package-content'),
      );
      expect(nostr.lastQueryFilter!.kinds, [
        MarmotKinds.keyPackage,
        MarmotKinds.legacyKeyPackage,
      ]);
    },
  );
}
