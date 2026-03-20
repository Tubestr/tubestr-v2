import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/constants.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/offline/offline_action_store.dart';
import 'package:mytube/services/safety/report_coordinator.dart';
import 'package:mytube/services/safety/safety_hq_service.dart';

import '../../test_support/service_fakes.dart';

void main() {
  late AppDatabase database;
  late FakeMdkService mdk;
  late FakeNostrService nostr;
  late SafetyHqService safetyHqService;
  late ReportCoordinator coordinator;

  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub-parent',
    nsec: 'nsec-parent',
    createdAtIso: '2026-03-15T00:00:00.000Z',
  );

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    mdk = FakeMdkService();
    nostr = FakeNostrService();
    safetyHqService = SafetyHqService(
      database: database,
      mdkService: mdk,
      nostrService: nostr,
      backendClient: FakeSafetyHqBackendClient(),
    );
    coordinator = ReportCoordinator(
      database: database,
      mdkService: mdk,
      nostrService: nostr,
      offlineActionStore: OfflineActionStore(database: database),
      safetyHqService: safetyHqService,
    );

    await database.upsertProfile(
      id: 'child-1',
      name: 'Emma',
      theme: 'campfire',
      avatarAsset: 'avatar.png',
    );
    await database.setPrimaryGroupForProfile(
      profileId: 'child-1',
      mlsGroupId: 'family-group',
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'submitReport delivers level 1 locally without publish or blob hash',
    () async {
      final result = await coordinator.submitReport(
        identity: identity,
        videoId: 'video-1',
        subjectChildId: 'child-1',
        reporterChildId: 'child-1',
        reason: 'inappropriate',
        level: 1,
        recipientType: 'local',
      );

      final savedReport = await (database.select(
        database.reports,
      )..where((tbl) => tbl.id.equals(result.reportId))).getSingle();

      expect(result.status, 'delivered');
      expect(result.familyPublished, isFalse);
      expect(result.safetyPublished, isFalse);
      expect(result.safetyQueued, isFalse);
      expect(savedReport.status, 'delivered');
      expect(savedReport.deliveredAt, isNotNull);
      expect(nostr.publishedEventJsons, isEmpty);
    },
  );

  test(
    'submitReport delivers level 2 locally without publish or blob hash',
    () async {
      final result = await coordinator.submitReport(
        identity: identity,
        videoId: 'video-2',
        subjectChildId: 'child-1',
        reporterChildId: 'child-1',
        reason: 'unsafe',
        level: 2,
        recipientType: 'local_parent',
      );

      final savedReport = await (database.select(
        database.reports,
      )..where((tbl) => tbl.id.equals(result.reportId))).getSingle();

      expect(result.status, 'delivered');
      expect(result.familyPublished, isFalse);
      expect(result.safetyPublished, isFalse);
      expect(result.safetyQueued, isFalse);
      expect(savedReport.status, 'delivered');
      expect(savedReport.deliveredAt, isNotNull);
      expect(nostr.publishedEventJsons, isEmpty);
    },
  );

  test(
    'submitReport publishes level 3 to family group and queues Safety HQ when absent',
    () async {
      final result = await coordinator.submitReport(
        identity: identity,
        videoId: 'video-3',
        subjectChildId: 'child-1',
        blobHash: 'blob-123',
        reporterChildId: 'child-1',
        reason: 'inappropriate',
        level: 3,
        recipientType: 'family',
      );

      final savedReport = await (database.select(
        database.reports,
      )..where((tbl) => tbl.id.equals(result.reportId))).getSingle();

      expect(result.status, 'queued_safety');
      expect(result.familyPublished, isTrue);
      expect(result.safetyPublished, isFalse);
      expect(result.safetyQueued, isTrue);
      expect(savedReport.status, 'queued_safety');
      expect(nostr.publishedEventJsons, hasLength(1));
      expect(mdk.lastCreatedMessageKind, MarmotKinds.report);
      expect(mdk.lastCreatedMessageGroupId, 'family-group');
    },
  );

  test(
    'submitReport publishes level 3 to both family and Safety HQ when provisioned',
    () async {
      await database.putSetting(AppConstants.safetyJoinedKey, 'true');
      await database.putSetting(
        AppConstants.safetyGroupIdSettingKey,
        'safety-group',
      );
      mdk.groupMembersResult = const [
        'parent-pubkey',
        AppConstants.safetyHqServicePublicKeyHex,
      ];

      final result = await coordinator.submitReport(
        identity: identity,
        videoId: 'video-4',
        subjectChildId: 'child-1',
        blobHash: 'blob-456',
        reporterChildId: 'child-1',
        reason: 'unsafe',
        level: 3,
        recipientType: 'family',
      );

      final savedReport = await (database.select(
        database.reports,
      )..where((tbl) => tbl.id.equals(result.reportId))).getSingle();

      expect(result.status, 'delivered');
      expect(result.familyPublished, isTrue);
      expect(result.safetyPublished, isTrue);
      expect(result.safetyQueued, isFalse);
      expect(savedReport.status, 'delivered');
      expect(nostr.publishedEventJsons, hasLength(2));
      expect(savedReport.deliveredAt, isNotNull);
    },
  );

  test(
    'submitReport keeps level 3 pending when blob hash is missing',
    () async {
      final result = await coordinator.submitReport(
        identity: identity,
        videoId: 'video-5',
        subjectChildId: 'child-1',
        reporterChildId: 'child-1',
        reason: 'unsafe',
        level: 3,
        recipientType: 'family',
      );

      final report = await (database.select(
        database.reports,
      )..where((tbl) => tbl.id.equals(result.reportId))).getSingle();

      expect(result.status, 'pending_blob_hash');
      expect(result.familyPublished, isFalse);
      expect(result.safetyPublished, isFalse);
      expect(result.safetyQueued, isFalse);
      expect(report.status, 'pending_blob_hash');
      expect(nostr.publishedEventJsons, isEmpty);
    },
  );

  test('submitReport queues level 3 offline when transport fails', () async {
    nostr.throwOnPublishSignedEvent = true;

    await expectLater(
      () => coordinator.submitReport(
        identity: identity,
        videoId: 'video-6',
        subjectChildId: 'child-1',
        blobHash: 'blob-789',
        reporterChildId: 'child-1',
        reason: 'unsafe',
        level: 3,
        recipientType: 'family',
      ),
      throwsA(isA<StateError>()),
    );

    final queued = await database.getSetting(
      AppConstants.offlineActionQueueSettingKey,
    );
    expect(queued, isNotNull);
    expect(queued, contains('submitReport'));
    final report = await (database.select(
      database.reports,
    )..where((tbl) => tbl.videoId.equals('video-6'))).getSingle();
    expect(report.status, 'queued_offline');
  });
}
