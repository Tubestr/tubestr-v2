import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/constants.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/mdk/mdk_service.dart';
import 'package:mytube/services/safety/safety_hq_service.dart';

import '../../test_support/service_fakes.dart';

void main() {
  late AppDatabase database;
  late FakeMdkService mdk;
  late FakeNostrService nostr;
  late SafetyHqService service;

  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub-parent',
    nsec: 'nsec-parent',
    createdAtIso: '2026-03-15T00:00:00.000Z',
  );

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    mdk = FakeMdkService()
      ..createGroupSummaryResult = const MdkGroupSummary(
        mlsGroupIdHex: 'safety-group',
        nostrGroupIdHex: 'nostr-safety-group',
        name: AppConstants.safetyHqGroupName,
        description: 'App-managed moderation inbox.',
        memberCount: 1,
        adminPubkeysHex: ['parent-pubkey'],
      );
    nostr = FakeNostrService();
    service = SafetyHqService(
      database: database,
      mdkService: mdk,
      nostrService: nostr,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'ensureProvisioned creates and stores Safety HQ group when queued',
    () async {
      await service.queueJoin();

      final group = await service.ensureProvisioned(identity: identity);
      final status = await service.loadStatus();

      expect(group, isNotNull);
      expect(group!.name, AppConstants.safetyHqGroupName);
      expect(status.isJoined, isFalse);
      expect(status.isQueued, isFalse);
      expect(status.groupId, 'safety-group');
      expect(status.lastSyncAt, isNotNull);
      expect(status.label, 'Awaiting backend ack');
      expect(status.usesLocalPlaceholder, isTrue);
    },
  );

  test('ensureProvisioned reuses existing Safety HQ group', () async {
    mdk.groupSummariesResult = const [
      MdkGroupSummary(
        mlsGroupIdHex: 'existing-safety',
        nostrGroupIdHex: 'nostr-existing-safety',
        name: AppConstants.safetyHqGroupName,
        description: 'Already here',
        memberCount: 1,
        adminPubkeysHex: ['parent-pubkey'],
      ),
    ];

    final group = await service.ensureProvisioned(identity: identity);
    final status = await service.loadStatus();

    expect(group, isNotNull);
    expect(group!.mlsGroupIdHex, 'existing-safety');
    expect(status.groupId, 'existing-safety');
    expect(status.isJoined, isFalse);
    expect(status.label, 'Awaiting backend ack');
  });

  test('loadStatus explains queued state conservatively', () async {
    await service.queueJoin();

    final status = await service.loadStatus();

    expect(status.isQueued, isTrue);
    expect(status.isJoined, isFalse);
    expect(status.label, 'Queued');
    expect(status.detail, contains('Finish provisioning'));
  });

  test('acknowledgeBackendEnrollment marks Safety HQ as joined', () async {
    await service.acknowledgeBackendEnrollment(groupId: 'safety-group');

    final status = await service.loadStatus();

    expect(status.isQueued, isFalse);
    expect(status.isJoined, isTrue);
    expect(status.groupId, 'safety-group');
    expect(status.label, 'Provisioned');
    expect(status.usesLocalPlaceholder, isFalse);
  });

  test('saveProvisionedRelays persists the backend relay set', () async {
    await service.saveProvisionedRelays([
      'wss://relay.safety.example',
      '',
      '  wss://relay.backup.example  ',
    ]);

    final relays = await service.loadProvisionedRelays();

    expect(relays, [
      'wss://relay.safety.example',
      'wss://relay.backup.example',
    ]);
  });
}
