import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/constants.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/marmot/message_models.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/engagement/like_coordinator.dart';
import 'package:mytube/services/offline/offline_action_store.dart';

import '../../test_support/service_fakes.dart';

void main() {
  late AppDatabase database;
  late FakeMdkService mdk;
  late FakeNostrService nostr;
  late LikeCoordinator coordinator;

  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub-parent',
    nsec: 'nsec-parent',
    createdAtIso: '2026-03-15T00:00:00.000Z',
  );

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    mdk = FakeMdkService();
    nostr = FakeNostrService();
    coordinator = LikeCoordinator(
      database: database,
      mdkService: mdk,
      nostrService: nostr,
      offlineActionStore: OfflineActionStore(database: database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'setLocalVideoLiked updates local video state for ranking/player UI',
    () async {
      await database.upsertProfile(
        id: 'child-1',
        name: 'Emma',
        theme: 'campfire',
        avatarAsset: 'avatar.png',
      );
      await database.saveLocalVideo(
        videoId: 'video-1',
        profileId: 'child-1',
        filePath: '/tmp/video.mp4',
        thumbPath: '/tmp/video.jpg',
        title: 'Backyard',
      );

      await coordinator.setLocalVideoLiked(videoId: 'video-1', liked: true);

      final saved = await database.getLatestLocalVideo(profileId: 'child-1');
      expect(saved, isNotNull);
      expect(saved!.liked, isTrue);
    },
  );

  test(
    'sendRemoteLike publishes kind 4546 and stores a local projection',
    () async {
      await coordinator.sendRemoteLike(
        identity: identity,
        videoId: 'remote-video',
        childProfileId: 'child-1',
        mlsGroupIdHex: 'family-group',
      );

      final likeCount = await database
          .watchLikeCountForVideo('remote-video')
          .first;
      final payload = LikeMessage.fromJson(
        jsonDecode(mdk.lastCreatedMessageContent!) as Map<String, dynamic>,
      );

      expect(mdk.lastCreatedMessageKind, MarmotKinds.like);
      expect(mdk.lastCreatedMessageGroupId, 'family-group');
      expect(nostr.publishedEventJsons, hasLength(1));
      expect(payload.videoId, 'remote-video');
      expect(payload.childProfileId, 'child-1');
      expect(likeCount, 1);
    },
  );

  test('sendRemoteLike queues action when relay publish fails', () async {
    nostr.throwOnPublishSignedEvent = true;

    await expectLater(
      () => coordinator.sendRemoteLike(
        identity: identity,
        videoId: 'remote-video',
        childProfileId: 'child-1',
        mlsGroupIdHex: 'family-group',
      ),
      throwsA(isA<StateError>()),
    );

    final queued = await database.getSetting(
      AppConstants.offlineActionQueueSettingKey,
    );
    expect(queued, isNotNull);
    expect(queued, contains('sendLike'));
  });
}
