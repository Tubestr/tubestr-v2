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

  test('ensureProvisioned creates and stores Safety HQ group when queued', () async {
    await service.queueJoin();

    final group = await service.ensureProvisioned(identity: identity);
    final status = await service.loadStatus();

    expect(group, isNotNull);
    expect(group!.name, AppConstants.safetyHqGroupName);
    expect(status.isJoined, isTrue);
    expect(status.isQueued, isFalse);
    expect(status.groupId, 'safety-group');
    expect(status.lastSyncAt, isNotNull);
  });

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
    expect(status.isJoined, isTrue);
  });
}
