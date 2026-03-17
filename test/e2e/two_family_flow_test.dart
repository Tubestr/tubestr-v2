import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/models/remote_share_identity.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/domain/models/remote_share_projection.dart';

import '../test_support/e2e_harness.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test(
    'two families can connect, share, sync, download, decrypt, like, and report',
    () async {
      final relayBus = LoopbackRelayBus();
      final mdkWorld = LoopbackMdkWorld();
      final blossom = InMemoryBlossomClient();

      final familyA = await FamilyAppHarness.create(
        relayBus: relayBus,
        mdkWorld: mdkWorld,
        blossom: blossom,
        identity: const ParentIdentity(
          publicKeyHex: 'family-a-parent',
          privateKeyHex: 'family-a-private',
          npub: 'npub-family-a',
          nsec: 'nsec-family-a',
          createdAtIso: '2026-03-15T00:00:00.000Z',
        ),
        childId: 'family-a-child',
        childName: 'Emma',
      );
      final familyB = await FamilyAppHarness.create(
        relayBus: relayBus,
        mdkWorld: mdkWorld,
        blossom: blossom,
        identity: const ParentIdentity(
          publicKeyHex: 'family-b-parent',
          privateKeyHex: 'family-b-private',
          npub: 'npub-family-b',
          nsec: 'nsec-family-b',
          createdAtIso: '2026-03-15T00:00:00.000Z',
        ),
        childId: 'family-b-child',
        childName: 'Noah',
      );
      addTearDown(familyA.dispose);
      addTearDown(familyB.dispose);

      await familyA.syncCoordinator.start();
      await familyB.syncCoordinator.start();

      final invite = await familyB.connectionService.createInvite(
        identity: familyB.identity,
      );
      final connectResult = await familyA.connectionService.connectFromInvite(
        identity: familyA.identity,
        invitePayload: invite.payload,
      );
      await familyA.database.assignPrimaryGroupToProfilesIfMissing(
        connectResult.group.mlsGroupIdHex,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final pendingWelcomes = await familyB.mdk.getPendingWelcomes();
      expect(pendingWelcomes, isNotEmpty);

      final joinedGroup = await familyB.mdk.acceptPendingWelcome(
        welcomeEventIdHex: pendingWelcomes.first.welcomeEventIdHex,
      );
      await familyB.database.assignPrimaryGroupToProfilesIfMissing(
        joinedGroup.mlsGroupIdHex,
      );

      await familyA.syncCoordinator.refreshSubscriptions();
      await familyB.syncCoordinator.refreshSubscriptions();

      const originalVideoBytes = <int>[
        0x00,
        0x00,
        0x00,
        0x18,
        0x66,
        0x74,
        0x79,
        0x70,
        1,
        3,
        3,
        7,
        9,
        2,
        1,
        4,
        8,
        6,
      ];
      const originalThumbBytes = <int>[0xFF, 0xD8, 0xFF, 8, 6, 7, 5, 3, 0, 9];
      final localVideoPath = File('${familyA.rootDir.path}/share-video.mp4');
      final localThumbPath = File('${familyA.rootDir.path}/share-thumb.jpg');
      await localVideoPath.writeAsBytes(originalVideoBytes, flush: true);
      await localThumbPath.writeAsBytes(originalThumbBytes, flush: true);

      await familyA.database.saveLocalVideo(
        videoId: 'shared-video-1',
        profileId: familyA.childId,
        filePath: localVideoPath.path,
        thumbPath: localThumbPath.path,
        title: 'Backyard adventure',
        durationSeconds: 12.5,
      );
      final localVideo = await familyA.database.getLatestLocalVideo(
        profileId: familyA.childId,
      );
      expect(localVideo, isNotNull);

      final shareMessage = await familyA.shareCoordinator
          .createUploadedShareMessage(
            identity: familyA.identity,
            localVideo: localVideo!,
            childDisplayName: familyA.childName,
            mlsGroupIdHex: connectResult.group.mlsGroupIdHex,
          );
      await familyA.shareCoordinator.publishSignedGroupMessage(
        identity: familyA.identity,
        signedEventJson: shareMessage.wrapperEventJson,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final remoteShareId = buildRemoteShareId(
        senderParentKey: familyA.identity.publicKeyHex,
        mlsGroupId: connectResult.group.mlsGroupIdHex,
        videoId: 'shared-video-1',
      );
      final remoteProjection = await familyB.database
          .watchRemoteShareProjectionByRemoteShareId(remoteShareId)
          .firstWhere((projection) => projection != null);
      expect(remoteProjection, isNotNull);
      expect(remoteProjection!.childDisplayName, familyA.childName);

      final downloadedPath = await familyB.remoteMediaService.downloadVideo(
        remoteProjection,
      );
      final downloadedFile = File(downloadedPath);
      expect(downloadedFile.existsSync(), isTrue);
      expect(await downloadedFile.readAsBytes(), originalVideoBytes);

      await familyB.likeCoordinator.sendRemoteLike(
        identity: familyB.identity,
        videoId: remoteProjection.videoId,
        childProfileId: familyB.childId,
        mlsGroupIdHex: remoteProjection.mlsGroupId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final familyALikeCount = await familyA.database
          .watchLikeCountForVideo('shared-video-1')
          .first;
      expect(familyALikeCount, 1);

      final reportResult = await familyB.reportCoordinator.submitReport(
        identity: familyB.identity,
        videoId: remoteProjection.videoId,
        subjectChildId: familyB.childId,
        blobHash: remoteProjection.blobHash,
        reporterChildId: familyB.childId,
        reason: 'inappropriate',
        note: 'Please check this one',
        level: 1,
        recipientType: 'group',
      );
      expect(reportResult.familyPublished, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final familyAReports = await familyA.database.watchReports().first;
      expect(familyAReports.where((report) => !report.isOutbound), isNotEmpty);
      expect(
        familyAReports.firstWhere((report) => !report.isOutbound).reason,
        'inappropriate',
      );

      final familyBReports = await familyB.database.watchReports().first;
      expect(familyBReports.where((report) => report.isOutbound), isNotEmpty);

      final deletePath = downloadedFile.path;
      await familyA.lifecycleCoordinator.publishDelete(
        identity: familyA.identity,
        mlsGroupIdHex: connectResult.group.mlsGroupIdHex,
        videoId: remoteProjection.videoId,
        blobHash: remoteProjection.blobHash!,
        reason: 'owner deleted',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final deletedProjection = await familyB.database
          .watchRemoteShareProjectionByRemoteShareId(remoteShareId)
          .firstWhere(
            (projection) =>
                projection != null && projection.status == 'deleted',
          );
      expect(deletedProjection, isNotNull);
      expect(File(deletePath).existsSync(), isFalse);
    },
  );

  test('queued family actions replay after relay recovery', () async {
    final relayBus = LoopbackRelayBus();
    final mdkWorld = LoopbackMdkWorld();
    final blossom = InMemoryBlossomClient();

    final familyA = await FamilyAppHarness.create(
      relayBus: relayBus,
      mdkWorld: mdkWorld,
      blossom: blossom,
      identity: const ParentIdentity(
        publicKeyHex: 'family-a-parent',
        privateKeyHex: 'family-a-private',
        npub: 'npub-family-a',
        nsec: 'nsec-family-a',
        createdAtIso: '2026-03-15T00:00:00.000Z',
      ),
      childId: 'family-a-child',
      childName: 'Emma',
    );
    final familyB = await FamilyAppHarness.create(
      relayBus: relayBus,
      mdkWorld: mdkWorld,
      blossom: blossom,
      identity: const ParentIdentity(
        publicKeyHex: 'family-b-parent',
        privateKeyHex: 'family-b-private',
        npub: 'npub-family-b',
        nsec: 'nsec-family-b',
        createdAtIso: '2026-03-15T00:00:00.000Z',
      ),
      childId: 'family-b-child',
      childName: 'Noah',
    );
    addTearDown(familyA.dispose);
    addTearDown(familyB.dispose);

    await familyA.syncCoordinator.start();
    await familyB.syncCoordinator.start();

    final invite = await familyB.connectionService.createInvite(
      identity: familyB.identity,
    );
    final connectResult = await familyA.connectionService.connectFromInvite(
      identity: familyA.identity,
      invitePayload: invite.payload,
    );
    await familyA.database.assignPrimaryGroupToProfilesIfMissing(
      connectResult.group.mlsGroupIdHex,
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    final pendingWelcomes = await familyB.mdk.getPendingWelcomes();
    final joinedGroup = await familyB.mdk.acceptPendingWelcome(
      welcomeEventIdHex: pendingWelcomes.first.welcomeEventIdHex,
    );
    await familyB.database.assignPrimaryGroupToProfilesIfMissing(
      joinedGroup.mlsGroupIdHex,
    );

    await familyA.syncCoordinator.refreshSubscriptions();
    await familyB.syncCoordinator.refreshSubscriptions();

    final localVideoPath = File('${familyA.rootDir.path}/queued-video.mp4');
    final localThumbPath = File('${familyA.rootDir.path}/queued-thumb.jpg');
    await localVideoPath.writeAsBytes(const <int>[9, 8, 7, 6], flush: true);
    await localThumbPath.writeAsBytes(const <int>[4, 3, 2, 1], flush: true);
    await familyA.database.saveLocalVideo(
      videoId: 'queued-video-1',
      profileId: familyA.childId,
      filePath: localVideoPath.path,
      thumbPath: localThumbPath.path,
      title: 'Queued backyard',
      durationSeconds: 8,
      approvalStatus: 'approved',
    );

    familyA.nostr.failPublishes = true;
    await expectLater(
      () => familyA.parentProfileService.publishLocalProfile(
        identity: familyA.identity,
        displayName: 'Lee & Emma',
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      () => familyA.shareCoordinator.shareLocalVideo(
        identity: familyA.identity,
        videoId: 'queued-video-1',
        profileId: familyA.childId,
        childDisplayName: familyA.childName,
        mlsGroupIdHex: connectResult.group.mlsGroupIdHex,
      ),
      throwsA(isA<StateError>()),
    );
    expect(await familyA.offlineActionStore.load(), hasLength(2));

    familyA.nostr.failPublishes = false;
    final flushedA = await familyA.offlineActionProcessor.flush();
    expect(flushedA, 2);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    final remoteShareId = buildRemoteShareId(
      senderParentKey: familyA.identity.publicKeyHex,
      mlsGroupId: connectResult.group.mlsGroupIdHex,
      videoId: 'queued-video-1',
    );
    final remoteProjection = await familyB.database
        .watchRemoteShareProjectionByRemoteShareId(remoteShareId)
        .firstWhere((projection) => projection != null);
    expect(remoteProjection, isNotNull);
    final projection = remoteProjection!;

    final resolvedParent = await familyB.parentProfileService.resolveProfile(
      publicKeyHex: familyA.identity.publicKeyHex,
      refresh: true,
    );
    expect(resolvedParent?.displayName, 'Lee & Emma');

    familyB.nostr.failPublishes = true;
    await expectLater(
      () => familyB.likeCoordinator.sendRemoteLike(
        identity: familyB.identity,
        videoId: projection.videoId,
        childProfileId: familyB.childId,
        mlsGroupIdHex: projection.mlsGroupId,
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      () => familyB.reportCoordinator.submitReport(
        identity: familyB.identity,
        videoId: projection.videoId,
        subjectChildId: familyB.childId,
        blobHash: projection.blobHash,
        reporterChildId: familyB.childId,
        reason: 'offline concern',
        level: 1,
        recipientType: 'group',
      ),
      throwsA(isA<StateError>()),
    );
    expect(await familyB.offlineActionStore.load(), hasLength(2));

    familyB.nostr.failPublishes = false;
    final flushedB = await familyB.offlineActionProcessor.flush();
    expect(flushedB, 2);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    final likeCount = await familyA.database
        .watchLikeCountForVideo('queued-video-1')
        .first;
    expect(likeCount, 1);
    final inboundReports = await familyA.database.watchReports().first;
    expect(
      inboundReports.any(
        (report) => !report.isOutbound && report.reason == 'offline concern',
      ),
      isTrue,
    );
  });

  test(
    'delete video and remove member stay independent moderation actions',
    () async {
      final relayBus = LoopbackRelayBus();
      final mdkWorld = LoopbackMdkWorld();
      final blossom = InMemoryBlossomClient();

      final familyA = await FamilyAppHarness.create(
        relayBus: relayBus,
        mdkWorld: mdkWorld,
        blossom: blossom,
        identity: const ParentIdentity(
          publicKeyHex: 'family-a-parent',
          privateKeyHex: 'family-a-private',
          npub: 'npub-family-a',
          nsec: 'nsec-family-a',
          createdAtIso: '2026-03-15T00:00:00.000Z',
        ),
        childId: 'family-a-child',
        childName: 'Emma',
      );
      final familyB = await FamilyAppHarness.create(
        relayBus: relayBus,
        mdkWorld: mdkWorld,
        blossom: blossom,
        identity: const ParentIdentity(
          publicKeyHex: 'family-b-parent',
          privateKeyHex: 'family-b-private',
          npub: 'npub-family-b',
          nsec: 'nsec-family-b',
          createdAtIso: '2026-03-15T00:00:00.000Z',
        ),
        childId: 'family-b-child',
        childName: 'Noah',
      );
      addTearDown(familyA.dispose);
      addTearDown(familyB.dispose);

      await familyA.syncCoordinator.start();
      await familyB.syncCoordinator.start();

      final invite = await familyB.connectionService.createInvite(
        identity: familyB.identity,
      );
      final connectResult = await familyA.connectionService.connectFromInvite(
        identity: familyA.identity,
        invitePayload: invite.payload,
      );
      await familyA.database.assignPrimaryGroupToProfilesIfMissing(
        connectResult.group.mlsGroupIdHex,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final pendingWelcomes = await familyB.mdk.getPendingWelcomes();
      final joinedGroup = await familyB.mdk.acceptPendingWelcome(
        welcomeEventIdHex: pendingWelcomes.first.welcomeEventIdHex,
      );
      await familyB.database.assignPrimaryGroupToProfilesIfMissing(
        joinedGroup.mlsGroupIdHex,
      );

      await familyA.syncCoordinator.refreshSubscriptions();
      await familyB.syncCoordinator.refreshSubscriptions();

      Future<RemoteShareProjection> shareFromFamilyA(String videoId) async {
        final localVideoPath = File('${familyA.rootDir.path}/$videoId.mp4');
        final localThumbPath = File('${familyA.rootDir.path}/$videoId.jpg');
        await localVideoPath.writeAsBytes(const <int>[1, 2, 3, 4], flush: true);
        await localThumbPath.writeAsBytes(const <int>[4, 3, 2, 1], flush: true);
        await familyA.database.saveLocalVideo(
          videoId: videoId,
          profileId: familyA.childId,
          filePath: localVideoPath.path,
          thumbPath: localThumbPath.path,
          title: videoId,
          durationSeconds: 6,
          approvalStatus: 'approved',
        );
        await familyA.shareCoordinator.shareLocalVideo(
          identity: familyA.identity,
          videoId: videoId,
          profileId: familyA.childId,
          childDisplayName: familyA.childName,
          mlsGroupIdHex: connectResult.group.mlsGroupIdHex,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final remoteShareId = buildRemoteShareId(
          senderParentKey: familyA.identity.publicKeyHex,
          mlsGroupId: connectResult.group.mlsGroupIdHex,
          videoId: videoId,
        );
        return familyB.database
            .watchRemoteShareProjectionByRemoteShareId(remoteShareId)
            .firstWhere((projection) => projection != null)
            .then((projection) => projection!);
      }

      final firstProjection = await shareFromFamilyA('moderation-video-delete');

      await familyB.moderationCoordinator.deleteSharedVideo(
        identity: familyB.identity,
        projection: firstProjection,
        reason: 'needs review',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final membersAfterDelete = await familyA.mdk.getGroupMembers(
        mlsGroupIdHex: connectResult.group.mlsGroupIdHex,
      );
      expect(
        membersAfterDelete,
        containsAll([
          familyA.identity.publicKeyHex,
          familyB.identity.publicKeyHex,
        ]),
      );
      final deletedProjection = await familyB.database
          .watchRemoteShareProjectionByRemoteShareId(
            firstProjection.remoteShareId,
          )
          .firstWhere(
            (projection) =>
                projection != null && projection.status == 'deleted',
          );
      expect(deletedProjection, isNotNull);

      final secondProjection = await shareFromFamilyA(
        'moderation-video-remove',
      );

      await familyA.moderationCoordinator.removeMember(
        identity: familyA.identity,
        mlsGroupIdHex: connectResult.group.mlsGroupIdHex,
        memberPubkeyHex: familyB.identity.publicKeyHex,
        reason: 'separate action',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final membersAfterRemoval = await familyA.mdk.getGroupMembers(
        mlsGroupIdHex: connectResult.group.mlsGroupIdHex,
      );
      expect(membersAfterRemoval, contains(familyA.identity.publicKeyHex));
      expect(
        membersAfterRemoval,
        isNot(contains(familyB.identity.publicKeyHex)),
      );

      final stillAvailableProjection = await familyB.database
          .watchRemoteShareProjectionByRemoteShareId(
            secondProjection.remoteShareId,
          )
          .firstWhere((projection) => projection != null);
      expect(stillAvailableProjection, isNotNull);
      expect(stillAvailableProjection!.status, 'available');
    },
  );
}
