import 'dart:io';

import 'package:mytube/core/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/marmot/message_models.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/approval/content_scan_service.dart';
import 'package:mytube/services/approval/media_signal_extraction_service.dart';
import 'package:mytube/services/approval/video_approval_service.dart';
import 'package:mytube/services/offline/offline_action_store.dart';
import 'package:mytube/services/share/share_history_service.dart';
import 'package:mytube/services/share/video_share_coordinator.dart';

import '../../test_support/service_fakes.dart';

void main() {
  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub1parent',
    nsec: 'nsec1parent',
    createdAtIso: '2026-03-15T00:00:00Z',
  );

  VideoApprovalService buildApprovalService(AppDatabase database) {
    return VideoApprovalService(
      database: database,
      scanService: const ContentScanService(),
      signalExtractionService: MediaSignalExtractionService(
        extractSignals: (video) async => MediaSignalExtractionResult(
          cvLabels: video.cvLabels,
          faceCount: video.faceCount,
          loudness: video.loudness,
        ),
      ),
    );
  }

  test(
    'createUploadedShareMessage uses share time for the event and preserves media created time in payload',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'video-share-coordinator-test',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      final videoFile = File('${tempDir.path}/clip.mp4')
        ..writeAsBytesSync(List<int>.from('video-bytes'.codeUnits));
      final thumbFile = File('${tempDir.path}/thumb.jpg')
        ..writeAsBytesSync(List<int>.from('thumb-bytes'.codeUnits));

      final mediaCreatedAt = DateTime.utc(2026, 2, 1, 12);
      final localVideo = LocalVideo(
        id: 'video-1',
        profileId: 'child-1',
        filePath: videoFile.path,
        thumbPath: thumbFile.path,
        title: 'Backyard song',
        durationSeconds: 12.5,
        createdAt: mediaCreatedAt,
        lastPlayedAt: null,
        playCount: 0,
        completionRate: 0,
        replayRate: 0,
        liked: false,
        hidden: false,
        tags: const <String>[],
        cvLabels: const <String>[],
        faceCount: 0,
        loudness: 0,
        reportedAt: null,
        reportReason: null,
        approvalStatus: 'approved',
        approvedAt: null,
        approvedByParentKey: null,
        scanVersion: 0,
        highestRiskCategory: null,
        scanConfidence: null,
        reviewReasons: const <String>[],
        scanResults: null,
        scanCompletedAt: null,
      );

      final blossomClient = FakeBlossomClient(unavailableServer: 'unused');
      final mdkService = FakeMdkService();
      final nostrService = FakeNostrService()
        ..blossomServers = const ['https://blossom.example'];
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final coordinator = VideoShareCoordinator(
        database: database,
        videoApprovalService: buildApprovalService(database),
        blossomClient: blossomClient,
        mdkService: mdkService,
        nostrService: nostrService,
        offlineActionStore: OfflineActionStore(database: database),
        shareHistoryService: ShareHistoryService(database: database),
      );

      final beforeShare = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await coordinator.createUploadedShareMessage(
        identity: identity,
        localVideo: localVideo,
        childDisplayName: 'Emma',
        mlsGroupIdHex: 'group-1',
      );
      final afterShare = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final payload = VideoShareMessage.decode(
        mdkService.lastCreatedMessageContent!,
      );

      expect(
        payload.meta.createdAt,
        mediaCreatedAt.millisecondsSinceEpoch ~/ 1000,
      );
      expect(payload.ts, inInclusiveRange(beforeShare, afterShare));
      expect(
        mdkService.lastCreatedMessageCreatedAt,
        inInclusiveRange(beforeShare, afterShare),
      );
      expect(payload.ts, mdkService.lastCreatedMessageCreatedAt);
    },
  );

  test('shareLocalVideo queues when relay publish fails', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'video-share-coordinator-queue-test',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final videoFile = File('${tempDir.path}/clip.mp4')
      ..writeAsBytesSync(List<int>.from('video-bytes'.codeUnits));
    final thumbFile = File('${tempDir.path}/thumb.jpg')
      ..writeAsBytesSync(List<int>.from('thumb-bytes'.codeUnits));
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.upsertProfile(
      id: 'child-1',
      name: 'Emma',
      theme: 'campfire',
      avatarAsset: 'avatar.png',
    );
    await database.saveLocalVideo(
      videoId: 'video-1',
      profileId: 'child-1',
      filePath: videoFile.path,
      thumbPath: thumbFile.path,
      title: 'Backyard song',
      approvalStatus: 'approved',
    );

    final blossomClient = FakeBlossomClient(unavailableServer: 'unused');
    final mdkService = FakeMdkService();
    final nostrService = FakeNostrService()
      ..blossomServers = const ['https://blossom.example']
      ..throwOnPublishSignedEvent = true;
    final coordinator = VideoShareCoordinator(
      database: database,
      videoApprovalService: buildApprovalService(database),
      blossomClient: blossomClient,
      mdkService: mdkService,
      nostrService: nostrService,
      offlineActionStore: OfflineActionStore(database: database),
      shareHistoryService: ShareHistoryService(database: database),
    );

    await expectLater(
      () => coordinator.shareLocalVideo(
        identity: identity,
        videoId: 'video-1',
        profileId: 'child-1',
        childDisplayName: 'Emma',
        mlsGroupIdHex: 'group-1',
      ),
      throwsA(isA<StateError>()),
    );

    final queued = await database.getSetting(
      AppConstants.offlineActionQueueSettingKey,
    );
    expect(queued, isNotNull);
    expect(queued, contains('shareVideo'));
    final history = await ShareHistoryService(database: database).load();
    expect(history.first.status, 'queued');
  });

  test('loadEligibleShareGroups excludes safety and solo groups', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final coordinator = VideoShareCoordinator(
      database: database,
      videoApprovalService: buildApprovalService(database),
      blossomClient: FakeBlossomClient(unavailableServer: 'unused'),
      mdkService: FakeMdkService()
        ..groupSummariesResult = [
          fakeGroupSummary(
            mlsGroupIdHex: 'solo-group',
            nostrGroupIdHex: 'nostr-solo',
            name: 'Family Space',
            description: 'Only me',
            memberCount: 1,
          ),
          fakeGroupSummary(
            mlsGroupIdHex: 'family-group',
            nostrGroupIdHex: 'nostr-family',
            name: 'Lee & Sam',
            description: 'Shared family group',
            memberCount: 2,
          ),
          fakeGroupSummary(
            mlsGroupIdHex: 'safety-group',
            nostrGroupIdHex: 'nostr-safety',
            name: AppConstants.safetyHqGroupName,
            description: 'Moderator group',
            memberCount: 2,
          ),
        ],
      nostrService: FakeNostrService(),
      offlineActionStore: OfflineActionStore(database: database),
      shareHistoryService: ShareHistoryService(database: database),
    );

    final groups = await coordinator.loadEligibleShareGroups();

    expect(groups.map((group) => group.mlsGroupIdHex), ['family-group']);
  });

  test(
    'shareLocalVideoToEligibleGroups publishes to all family groups',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'video-share-coordinator-multi-group-test',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      final videoFile = File('${tempDir.path}/clip.mp4')
        ..writeAsBytesSync(List<int>.from('video-bytes'.codeUnits));
      final thumbFile = File('${tempDir.path}/thumb.jpg')
        ..writeAsBytesSync(List<int>.from('thumb-bytes'.codeUnits));
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await database.upsertProfile(
        id: 'child-1',
        name: 'Emma',
        theme: 'campfire',
        avatarAsset: 'avatar.png',
      );
      await database.saveLocalVideo(
        videoId: 'video-1',
        profileId: 'child-1',
        filePath: videoFile.path,
        thumbPath: thumbFile.path,
        title: 'Backyard song',
        approvalStatus: 'approved',
      );

      final mdkService = FakeMdkService()
        ..groupSummariesResult = [
          fakeGroupSummary(
            mlsGroupIdHex: 'solo-group',
            nostrGroupIdHex: 'nostr-solo',
            name: 'Old Family Space',
            description: 'Only me',
            memberCount: 1,
          ),
          fakeGroupSummary(
            mlsGroupIdHex: 'family-a',
            nostrGroupIdHex: 'nostr-family-a',
            name: 'Lee & Sam',
            description: 'First family',
            memberCount: 2,
          ),
          fakeGroupSummary(
            mlsGroupIdHex: 'family-b',
            nostrGroupIdHex: 'nostr-family-b',
            name: 'Lee & Robin',
            description: 'Second family',
            memberCount: 3,
          ),
        ];
      final nostrService = FakeNostrService()
        ..blossomServers = const ['https://blossom.example'];
      final coordinator = VideoShareCoordinator(
        database: database,
        videoApprovalService: buildApprovalService(database),
        blossomClient: FakeBlossomClient(unavailableServer: 'unused'),
        mdkService: mdkService,
        nostrService: nostrService,
        offlineActionStore: OfflineActionStore(database: database),
        shareHistoryService: ShareHistoryService(database: database),
      );

      final result = await coordinator.shareLocalVideoToEligibleGroups(
        identity: identity,
        videoId: 'video-1',
        profileId: 'child-1',
        childDisplayName: 'Emma',
      );

      expect(result.sharedGroupIds, ['family-a', 'family-b']);
      expect(result.queuedGroupIds, isEmpty);
      expect(mdkService.createdMessageGroupIds, ['family-a', 'family-b']);
      expect(nostrService.publishedEventJsons, hasLength(2));
    },
  );

  test(
    'createUploadedShareMessage mirrors uploads across configured Blossom servers',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'video-share-coordinator-mirror-test',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      final videoFile = File('${tempDir.path}/clip.mp4')
        ..writeAsBytesSync(List<int>.from('video-bytes'.codeUnits));
      final thumbFile = File('${tempDir.path}/thumb.jpg')
        ..writeAsBytesSync(List<int>.from('thumb-bytes'.codeUnits));
      final localVideo = LocalVideo(
        id: 'video-2',
        profileId: 'child-1',
        filePath: videoFile.path,
        thumbPath: thumbFile.path,
        title: 'Mirrored clip',
        durationSeconds: 5,
        createdAt: DateTime.utc(2026, 3, 1),
        lastPlayedAt: null,
        playCount: 0,
        completionRate: 0,
        replayRate: 0,
        liked: false,
        hidden: false,
        tags: const <String>[],
        cvLabels: const <String>[],
        faceCount: 0,
        loudness: 0,
        reportedAt: null,
        reportReason: null,
        approvalStatus: 'approved',
        approvedAt: null,
        approvedByParentKey: null,
        scanVersion: 0,
        highestRiskCategory: null,
        scanConfidence: null,
        reviewReasons: const <String>[],
        scanResults: null,
        scanCompletedAt: null,
      );
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final blossomClient = FakeBlossomClient(unavailableServer: 'unused');
      final mdkService = FakeMdkService();
      final coordinator = VideoShareCoordinator(
        database: database,
        videoApprovalService: buildApprovalService(database),
        blossomClient: blossomClient,
        mdkService: mdkService,
        nostrService: FakeNostrService()
          ..blossomServers = const [
            'https://blossom-a.example',
            'https://blossom-b.example',
          ],
        offlineActionStore: OfflineActionStore(database: database),
        shareHistoryService: ShareHistoryService(database: database),
      );

      final event = await coordinator.createUploadedShareMessage(
        identity: identity,
        localVideo: localVideo,
        childDisplayName: 'Emma',
        mlsGroupIdHex: 'group-1',
      );

      final payload = VideoShareMessage.decode(
        mdkService.lastCreatedMessageContent!,
      );
      expect(event.wrapperEventJson, isNotEmpty);
      expect(
        blossomClient.uploadServers,
        equals([
          'https://blossom-a.example',
          'https://blossom-b.example',
          'https://blossom-a.example',
          'https://blossom-b.example',
        ]),
      );
      expect(
        payload.blob.servers,
        equals(['https://blossom-a.example', 'https://blossom-b.example']),
      );
      expect(
        payload.thumb.servers,
        equals(['https://blossom-a.example', 'https://blossom-b.example']),
      );
    },
  );

  test(
    'createUploadedShareMessage uses BUD-11 style auth for Blossom uploads',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'video-share-coordinator-auth-test',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      final videoFile = File('${tempDir.path}/clip.mp4')
        ..writeAsBytesSync(List<int>.from('video-bytes'.codeUnits));
      final thumbFile = File('${tempDir.path}/thumb.jpg')
        ..writeAsBytesSync(List<int>.from('thumb-bytes'.codeUnits));
      final localVideo = LocalVideo(
        id: 'video-auth',
        profileId: 'child-1',
        filePath: videoFile.path,
        thumbPath: thumbFile.path,
        title: 'Authorized clip',
        durationSeconds: 5,
        createdAt: DateTime.utc(2026, 3, 1),
        lastPlayedAt: null,
        playCount: 0,
        completionRate: 0,
        replayRate: 0,
        liked: false,
        hidden: false,
        tags: const <String>[],
        cvLabels: const <String>[],
        faceCount: 0,
        loudness: 0,
        reportedAt: null,
        reportReason: null,
        approvalStatus: 'approved',
        approvedAt: null,
        approvedByParentKey: null,
        scanVersion: 0,
        highestRiskCategory: null,
        scanConfidence: null,
        reviewReasons: const <String>[],
        scanResults: null,
        scanCompletedAt: null,
      );
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final blossomClient = FakeBlossomClient(unavailableServer: 'unused');
      final nostrService = FakeNostrService()
        ..blossomServers = const ['https://blossom.tubestr.app'];
      final coordinator = VideoShareCoordinator(
        database: database,
        videoApprovalService: buildApprovalService(database),
        blossomClient: blossomClient,
        mdkService: FakeMdkService(),
        nostrService: nostrService,
        offlineActionStore: OfflineActionStore(database: database),
        shareHistoryService: ShareHistoryService(database: database),
      );

      await coordinator.createUploadedShareMessage(
        identity: identity,
        localVideo: localVideo,
        childDisplayName: 'Emma',
        mlsGroupIdHex: 'group-1',
      );

      expect(blossomClient.uploadAuthHeaders, hasLength(2));
      for (final header in blossomClient.uploadAuthHeaders) {
        expect(header, isNotNull);
        expect(header!, startsWith('Nostr '));
        expect(header.contains('='), isFalse);
        expect(header.contains('+'), isFalse);
        expect(header.contains('/'), isFalse);
      }
      expect(nostrService.lastCreatedSignedEventKind, 24242);
      expect(
        nostrService.lastCreatedSignedEventContent,
        'Authorize Blossom upload',
      );
      expect(
        nostrService.lastCreatedSignedEventTags,
        containsAll(<List<String>>[
          ['t', 'upload'],
          ['server', 'blossom.tubestr.app'],
          ['u', 'https://blossom.tubestr.app/upload'],
          ['method', 'PUT'],
        ]),
      );
    },
  );

  test(
    'createUploadedShareMessage keeps successful mirrors when one upload server fails',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'video-share-coordinator-partial-mirror-test',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      final videoFile = File('${tempDir.path}/clip.mp4')
        ..writeAsBytesSync(List<int>.from('video-bytes'.codeUnits));
      final thumbFile = File('${tempDir.path}/thumb.jpg')
        ..writeAsBytesSync(List<int>.from('thumb-bytes'.codeUnits));
      final localVideo = LocalVideo(
        id: 'video-3',
        profileId: 'child-1',
        filePath: videoFile.path,
        thumbPath: thumbFile.path,
        title: 'Partial mirror clip',
        durationSeconds: 5,
        createdAt: DateTime.utc(2026, 3, 1),
        lastPlayedAt: null,
        playCount: 0,
        completionRate: 0,
        replayRate: 0,
        liked: false,
        hidden: false,
        tags: const <String>[],
        cvLabels: const <String>[],
        faceCount: 0,
        loudness: 0,
        reportedAt: null,
        reportReason: null,
        approvalStatus: 'approved',
        approvedAt: null,
        approvedByParentKey: null,
        scanVersion: 0,
        highestRiskCategory: null,
        scanConfidence: null,
        reviewReasons: const <String>[],
        scanResults: null,
        scanCompletedAt: null,
      );
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final blossomClient = FakeBlossomClient(unavailableServer: 'unused')
        ..failingUploadServers.add('https://blossom-b.example');
      final mdkService = FakeMdkService();
      final coordinator = VideoShareCoordinator(
        database: database,
        videoApprovalService: buildApprovalService(database),
        blossomClient: blossomClient,
        mdkService: mdkService,
        nostrService: FakeNostrService()
          ..blossomServers = const [
            'https://blossom-a.example',
            'https://blossom-b.example',
          ],
        offlineActionStore: OfflineActionStore(database: database),
        shareHistoryService: ShareHistoryService(database: database),
      );

      await coordinator.createUploadedShareMessage(
        identity: identity,
        localVideo: localVideo,
        childDisplayName: 'Emma',
        mlsGroupIdHex: 'group-1',
      );

      final payload = VideoShareMessage.decode(
        mdkService.lastCreatedMessageContent!,
      );
      expect(payload.blob.servers, equals(['https://blossom-a.example']));
      expect(payload.thumb.servers, equals(['https://blossom-a.example']));
    },
  );

  test('shareLocalVideo scans an unscanned safe clip before sharing', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'video-share-coordinator-scan-test',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final videoFile = File('${tempDir.path}/clip.mp4')
      ..writeAsBytesSync(List<int>.from('video-bytes'.codeUnits));
    final thumbFile = File('${tempDir.path}/thumb.jpg')
      ..writeAsBytesSync(List<int>.from('thumb-bytes'.codeUnits));
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.upsertProfile(
      id: 'child-1',
      name: 'Emma',
      theme: 'campfire',
      avatarAsset: 'avatar.png',
    );
    await database.saveLocalVideo(
      videoId: 'video-1',
      profileId: 'child-1',
      filePath: videoFile.path,
      thumbPath: thumbFile.path,
      title: 'Backyard song',
      approvalStatus: 'approved',
      scanResults: null,
      scanCompletedAt: null,
    );

    final coordinator = VideoShareCoordinator(
      database: database,
      videoApprovalService: buildApprovalService(database),
      blossomClient: FakeBlossomClient(unavailableServer: 'unused'),
      mdkService: FakeMdkService()
        ..groupSummariesResult = [
          fakeGroupSummary(
            mlsGroupIdHex: 'family-a',
            nostrGroupIdHex: 'nostr-family-a',
            name: 'Lee & Sam',
            description: 'First family',
            memberCount: 2,
          ),
        ],
      nostrService: FakeNostrService()
        ..blossomServers = const ['https://blossom.example'],
      offlineActionStore: OfflineActionStore(database: database),
      shareHistoryService: ShareHistoryService(database: database),
    );

    await coordinator.shareLocalVideoToEligibleGroups(
      identity: identity,
      videoId: 'video-1',
      profileId: 'child-1',
      childDisplayName: 'Emma',
    );

    final saved = await database.getLocalVideoById('video-1');
    expect(saved?.scanResults, isNotNull);
    expect(saved?.scanCompletedAt, isNotNull);
  });
}
