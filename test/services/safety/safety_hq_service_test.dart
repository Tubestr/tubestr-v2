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
  late FakeSafetyHqBackendClient backendClient;
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
      ..createGroupResult = const MdkCreateGroupResult(
        group: MdkGroupSummary(
          mlsGroupIdHex: 'safety-group',
          nostrGroupIdHex: 'nostr-safety-group',
          name: AppConstants.safetyHqGroupName,
          description: 'Platform moderation inbox.',
          memberCount: 2,
          adminPubkeysHex: ['parent-pubkey'],
        ),
        welcomeRumorJsons: ['{"id":"welcome-rumor"}'],
      )
      ..groupMembersResult = const [
        'parent-pubkey',
        AppConstants.safetyHqServicePublicKeyHex,
      ];
    nostr = FakeNostrService();
    backendClient = FakeSafetyHqBackendClient();
    service = SafetyHqService(
      database: database,
      mdkService: mdk,
      nostrService: nostr,
      backendClient: backendClient,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'ensureProvisioned fetches bootstrap, creates group, and publishes backend welcome',
    () async {
      await service.queueJoin();

      final group = await service.ensureProvisioned(identity: identity);
      final status = await service.loadStatus();

      expect(group, isNotNull);
      expect(group!.name, AppConstants.safetyHqGroupName);
      expect(
        nostr.lastGiftWrapRecipient,
        AppConstants.safetyHqServicePublicKeyHex,
      );
      expect(nostr.lastGiftWrapRumorJson, '{"id":"welcome-rumor"}');
      expect(status.isJoined, isTrue);
      expect(status.isQueued, isFalse);
      expect(status.needsRetry, isFalse);
      expect(status.groupId, 'safety-group');
      expect(status.lastSyncAt, isNotNull);
    },
  );

  test(
    'ensureProvisioned reuses existing backend-backed Safety HQ group',
    () async {
      mdk.groupSummariesResult = const [
        MdkGroupSummary(
          mlsGroupIdHex: 'existing-safety',
          nostrGroupIdHex: 'nostr-existing-safety',
          name: AppConstants.safetyHqGroupName,
          description: 'Already here',
          memberCount: 2,
          adminPubkeysHex: ['parent-pubkey'],
        ),
      ];
      mdk.groupMembersResult = const [
        'parent-pubkey',
        AppConstants.safetyHqServicePublicKeyHex,
      ];

      final group = await service.ensureProvisioned(identity: identity);
      final status = await service.loadStatus();

      expect(group, isNotNull);
      expect(group!.mlsGroupIdHex, 'existing-safety');
      expect(status.groupId, 'existing-safety');
      expect(status.isJoined, isTrue);
      expect(nostr.lastGiftWrapRecipient, isNull);
    },
  );

  test(
    'loadStatus does not treat local-only Safety HQ group as provisioned',
    () async {
      await database.putSetting(AppConstants.safetyJoinedKey, 'true');
      await database.putSetting(
        AppConstants.safetyGroupIdSettingKey,
        'legacy-local-group',
      );
      mdk.groupMembersResult = const ['parent-pubkey'];

      final status = await service.loadStatus();

      expect(status.isJoined, isFalse);
      expect(status.needsRetry, isTrue);
    },
  );
}
