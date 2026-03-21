import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/account/child_profile_deletion_service.dart';
import 'package:mytube/services/share/managed_video_upload_service.dart';
import 'package:mytube/services/share/share_history_service.dart';

import '../../test_support/service_fakes.dart';

void main() {
  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub1parent',
    nsec: 'nsec1parent',
    createdAtIso: '2026-03-19T00:00:00Z',
  );

  test(
    'deleteProfile removes managed uploads with no delivered copies or reports',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await database.upsertProfile(
        id: 'child-1',
        name: 'Emma',
        theme: 'campfire',
        avatarAsset: 'avatar.png',
      );

      final managedUploads = ManagedVideoUploadService(database: database);
      await managedUploads.recordUpload(
        videoId: 'video-1',
        profileId: 'child-1',
        videoBlob: const ManagedUploadedBlob(
          hash: 'blob-1',
          servers: ['https://blossom-a.example', 'https://blossom-b.example'],
        ),
        thumbBlob: const ManagedUploadedBlob(
          hash: 'thumb-1',
          servers: ['https://blossom-a.example'],
        ),
      );

      final blossom = FakeBlossomClient(unavailableServer: 'unused');
      final nostr = FakeNostrService();
      final service = ChildProfileDeletionService(
        database: database,
        blossomClient: blossom,
        nostrService: nostr,
        shareHistoryService: ShareHistoryService(database: database),
        managedVideoUploadService: managedUploads,
      );

      final result = await service.deleteProfile(
        profileId: 'child-1',
        identity: identity,
      );

      expect(result.deletedBlobCount, 3);
      expect(result.retainedUploadCount, 0);
      expect(result.failedDeleteCount, 0);
      expect(result.deletedProfile, isTrue);
      expect(blossom.deletedHashes, ['blob-1', 'blob-1', 'thumb-1']);
      expect(blossom.deletedServers, [
        'https://blossom-a.example',
        'https://blossom-b.example',
        'https://blossom-a.example',
      ]);
      expect(nostr.lastCreatedSignedEventKind, 24242);
      expect(nostr.lastCreatedSignedEventContent, 'Authorize Blossom delete');
      expect(
        nostr.lastCreatedSignedEventTags,
        containsAll(<List<String>>[
          ['t', 'delete'],
          ['server', 'blossom-a.example'],
          ['method', 'DELETE'],
        ]),
      );
      expect(await database.watchProfiles().first, isEmpty);
      expect(await managedUploads.loadForProfile('child-1'), isEmpty);
    },
  );

  test('deleteProfile retains uploads with delivered copies', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.upsertProfile(
      id: 'child-1',
      name: 'Emma',
      theme: 'campfire',
      avatarAsset: 'avatar.png',
    );

    final managedUploads = ManagedVideoUploadService(database: database);
    await managedUploads.recordUpload(
      videoId: 'video-1',
      profileId: 'child-1',
      videoBlob: const ManagedUploadedBlob(
        hash: 'blob-1',
        servers: ['https://blossom.example'],
      ),
      thumbBlob: const ManagedUploadedBlob(
        hash: 'thumb-1',
        servers: ['https://blossom.example'],
      ),
    );
    await ShareHistoryService(database: database).recordSent(
      videoId: 'video-1',
      title: 'Backyard song',
      childProfileId: 'child-1',
      childDisplayName: 'Emma',
      mlsGroupId: 'group-1',
      eventId: 'event-1',
    );

    final blossom = FakeBlossomClient(unavailableServer: 'unused');
    final service = ChildProfileDeletionService(
      database: database,
      blossomClient: blossom,
      nostrService: FakeNostrService(),
      shareHistoryService: ShareHistoryService(database: database),
      managedVideoUploadService: managedUploads,
    );

    final result = await service.deleteProfile(
      profileId: 'child-1',
      identity: identity,
    );

    expect(result.deletedBlobCount, 0);
    expect(result.retainedUploadCount, 1);
    expect(blossom.deletedHashes, isEmpty);
    expect(result.deletedProfile, isTrue);
  });

  test('deleteProfile retains uploads referenced by reports', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.upsertProfile(
      id: 'child-1',
      name: 'Emma',
      theme: 'campfire',
      avatarAsset: 'avatar.png',
    );

    final managedUploads = ManagedVideoUploadService(database: database);
    await managedUploads.recordUpload(
      videoId: 'video-1',
      profileId: 'child-1',
      videoBlob: const ManagedUploadedBlob(
        hash: 'blob-1',
        servers: ['https://blossom.example'],
      ),
      thumbBlob: const ManagedUploadedBlob(
        hash: 'thumb-1',
        servers: ['https://blossom.example'],
      ),
    );
    await database.upsertReportRecord(
      reportId: 'report-1',
      videoId: 'video-1',
      subjectChildId: 'child-1',
      blobHash: 'blob-1',
      reason: 'unsafe',
      level: 3,
      recipientType: 'family',
      reporterParentKey: 'parent-pubkey',
      isOutbound: true,
      createdAt: DateTime.utc(2026, 3, 19),
    );

    final blossom = FakeBlossomClient(unavailableServer: 'unused');
    final service = ChildProfileDeletionService(
      database: database,
      blossomClient: blossom,
      nostrService: FakeNostrService(),
      shareHistoryService: ShareHistoryService(database: database),
      managedVideoUploadService: managedUploads,
    );

    final result = await service.deleteProfile(
      profileId: 'child-1',
      identity: identity,
    );

    expect(result.deletedBlobCount, 0);
    expect(result.retainedUploadCount, 1);
    expect(blossom.deletedHashes, isEmpty);
    expect(result.deletedProfile, isTrue);
  });

  test(
    'deleteProfile keeps retryable state when remote cleanup fails',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await database.upsertProfile(
        id: 'child-1',
        name: 'Emma',
        theme: 'campfire',
        avatarAsset: 'avatar.png',
      );

      final managedUploads = ManagedVideoUploadService(database: database);
      await managedUploads.recordUpload(
        videoId: 'video-1',
        profileId: 'child-1',
        videoBlob: const ManagedUploadedBlob(
          hash: 'blob-1',
          servers: ['https://blossom.example'],
        ),
        thumbBlob: const ManagedUploadedBlob(
          hash: 'thumb-1',
          servers: ['https://blossom.example'],
        ),
      );

      final blossom = FakeBlossomClient(unavailableServer: 'unused')
        ..failingDeleteServers.add('https://blossom.example');
      final service = ChildProfileDeletionService(
        database: database,
        blossomClient: blossom,
        nostrService: FakeNostrService(),
        shareHistoryService: ShareHistoryService(database: database),
        managedVideoUploadService: managedUploads,
      );

      final result = await service.deleteProfile(
        profileId: 'child-1',
        identity: identity,
      );

      expect(result.failedDeleteCount, 2);
      expect(result.deletedProfile, isFalse);
      expect(await database.watchProfiles().first, isNotEmpty);
      expect(await managedUploads.loadForProfile('child-1'), isNotEmpty);
    },
  );
}
