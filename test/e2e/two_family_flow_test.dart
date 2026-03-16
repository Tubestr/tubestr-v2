import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/models/parent_identity.dart';

import '../test_support/e2e_harness.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('two families can connect, share, sync, download, decrypt, like, and report', () async {
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

    const originalVideoBytes = <int>[1, 3, 3, 7, 9, 2, 1, 4, 8, 6];
    const originalThumbBytes = <int>[8, 6, 7, 5, 3, 0, 9];
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

    final shareMessage = await familyA.shareCoordinator.createUploadedShareMessage(
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
    final remoteProjection = await familyB.database
        .watchRemoteShareProjectionByVideoId('shared-video-1')
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
    expect(
      familyAReports.where((report) => !report.isOutbound),
      isNotEmpty,
    );
    expect(
      familyAReports.firstWhere((report) => !report.isOutbound).reason,
      'inappropriate',
    );

    final familyBReports = await familyB.database.watchReports().first;
    expect(
      familyBReports.where((report) => report.isOutbound),
      isNotEmpty,
    );

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
        .watchRemoteShareProjectionByVideoId('shared-video-1')
        .firstWhere((projection) => projection != null && projection.status == 'deleted');
    expect(deletedProjection, isNotNull);
    expect(File(deletePath).existsSync(), isFalse);
  });
}
