import 'package:flutter_test/flutter_test.dart';
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
          tagsJson: '[["relay","wss://relay.example"]]',
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
      expect(packet.keyPackageEventId, 'event-id');
      expect(packet.inviterDisplayName, 'Lee');
      expect(
        result.keyPackageEventJson,
        '{"kind":443,"content":"key-package-content"}',
      );
      expect(nostr.lastPublishedEventJson, result.keyPackageEventJson);
    },
  );

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
            kind: 443,
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
    },
  );
}
