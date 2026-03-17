import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/services/media/remote_media_service.dart';

import '../../test_support/service_fakes.dart';

void main() {
  test(
    'downloadVideo falls back to fetched blossom servers and caches media',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      await database.upsertRemoteShareProjection(
        videoId: 'video-1',
        mlsGroupId: 'group-1',
        senderParentKey: 'sender-parent',
        childProfileId: 'child-1',
        childDisplayName: 'Emma',
        blobHash: 'blob-1',
        thumbHash: 'thumb-1',
        epoch: '1',
        mime: 'video/mp4',
        metadataJson:
            '{"t":"mytube/video_share","video_id":"video-1","child_profile_id":"child-1","child_display_name":"Emma","meta":{"title":"Song","dur":12.5,"created_at":1710460800},"blob":{"hash":"blob-1","servers":["https://snapshot.example"],"mime":"video/mp4","len":321,"orig_hash":"orig-video","nonce":"nonce-video","filename":"clip.mp4","scheme":"mip04-v2"},"thumb":{"hash":"thumb-1","servers":["https://snapshot.example"],"mime":"image/jpeg","len":111,"orig_hash":"orig-thumb","nonce":"nonce-thumb","filename":"thumb.jpg","scheme":"mip04-v2"},"media":{"alg":"mip04","epoch":"1"},"policy":{"version":2,"expires_at":null},"by":"sender-parent","ts":1710460800}',
      );
      final share = await database
          .watchRemoteShareProjections()
          .map((items) => items.firstWhere((item) => item.videoId == 'video-1'))
          .first;

      final tempDir = await Directory.systemTemp.createTemp(
        'remote-media-test',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      final blossomClient = FakeBlossomClient();
      final mdkService = FakeMdkService();
      final nostrService = FakeNostrService()
        ..fetchedBlossomServers = const ['https://fallback.example'];
      final service = RemoteMediaService(
        database: database,
        blossomClient: blossomClient,
        mdkService: mdkService,
        nostrService: nostrService,
        supportDirectoryProvider: () async => tempDir,
      );

      final path = await service.downloadVideo(share);
      final cached = await database.getRemoteAssetByRemoteShareId(
        share.remoteShareId,
      );
      final shares = await database.watchShareRecords().first;

      expect(File(path).existsSync(), isTrue);
      expect(cached?.localMediaPath, path);
      expect(cached?.localThumbPath, isNotNull);
      expect(File(cached!.localThumbPath!).existsSync(), isTrue);
      expect(shares.single.status, 'downloaded');
      expect(blossomClient.attempts, hasLength(4));
      expect(blossomClient.attempts[0], ['https://snapshot.example']);
      expect(blossomClient.attempts[1], ['https://fallback.example']);
      expect(blossomClient.attempts[2], ['https://snapshot.example']);
      expect(blossomClient.attempts[3], ['https://fallback.example']);
      expect(mdkService.lastDecryptUrl, 'https://fallback.example/thumb-1');
    },
  );

  test(
    'downloadVideo reports the actual preferred server that succeeded',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      await database.upsertRemoteShareProjection(
        videoId: 'video-2',
        mlsGroupId: 'group-1',
        senderParentKey: 'sender-parent',
        childProfileId: 'child-1',
        childDisplayName: 'Emma',
        blobHash: 'blob-2',
        thumbHash: 'thumb-2',
        epoch: '1',
        mime: 'video/mp4',
        metadataJson:
            '{"t":"mytube/video_share","video_id":"video-2","child_profile_id":"child-1","child_display_name":"Emma","meta":{"title":"Song","dur":12.5,"created_at":1710460800},"blob":{"hash":"blob-2","servers":["https://snapshot.example","https://preferred.example"],"mime":"video/mp4","len":321,"orig_hash":"orig-video","nonce":"nonce-video","filename":"clip.mp4","scheme":"mip04-v2"},"thumb":{"hash":"thumb-2","servers":["https://snapshot.example","https://preferred.example"],"mime":"image/jpeg","len":111,"orig_hash":"orig-thumb","nonce":"nonce-thumb","filename":"thumb.jpg","scheme":"mip04-v2"},"media":{"alg":"mip04","epoch":"1"},"policy":{"version":2,"expires_at":null},"by":"sender-parent","ts":1710460800}',
      );
      final share = await database
          .watchRemoteShareProjections()
          .map((items) => items.firstWhere((item) => item.videoId == 'video-2'))
          .first;

      final tempDir = await Directory.systemTemp.createTemp(
        'remote-media-preferred-server-test',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      final blossomClient = FakeBlossomClient();
      final mdkService = FakeMdkService();
      final nostrService = FakeNostrService();
      final service = RemoteMediaService(
        database: database,
        blossomClient: blossomClient,
        mdkService: mdkService,
        nostrService: nostrService,
        supportDirectoryProvider: () async => tempDir,
      );

      await service.downloadVideo(share);

      expect(
        blossomClient.attempts,
        containsAllInOrder([
          ['https://snapshot.example'],
          ['https://preferred.example'],
        ]),
      );
      expect(mdkService.lastDecryptUrl, 'https://preferred.example/thumb-2');
    },
  );

  test(
    'ensureVideoAvailable redownloads when cached media file is invalid',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final tempDir = await Directory.systemTemp.createTemp(
        'remote-media-invalid-cache-test',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      final staleFile = File('${tempDir.path}/stale.mp4')
        ..writeAsStringSync('not-an-mp4');

      await database.upsertRemoteShareProjection(
        videoId: 'video-3',
        mlsGroupId: 'group-1',
        senderParentKey: 'sender-parent',
        childProfileId: 'child-1',
        childDisplayName: 'Emma',
        blobHash: 'blob-3',
        thumbHash: 'thumb-3',
        epoch: '1',
        mime: 'video/mp4',
        metadataJson:
            '{"t":"mytube/video_share","video_id":"video-3","child_profile_id":"child-1","child_display_name":"Emma","meta":{"title":"Song","dur":12.5,"created_at":1710460800},"blob":{"hash":"blob-3","servers":["https://snapshot.example"],"mime":"video/mp4","len":321,"orig_hash":"orig-video","nonce":"nonce-video","filename":"clip.mp4","scheme":"mip04-v2"},"thumb":{"hash":"thumb-3","servers":["https://snapshot.example"],"mime":"image/jpeg","len":111,"orig_hash":"orig-thumb","nonce":"nonce-thumb","filename":"thumb.jpg","scheme":"mip04-v2"},"media":{"alg":"mip04","epoch":"1"},"policy":{"version":2,"expires_at":null},"by":"sender-parent","ts":1710460800}',
        localMediaPath: staleFile.path,
      );
      final share = await database
          .watchRemoteShareProjections()
          .map((items) => items.firstWhere((item) => item.videoId == 'video-3'))
          .first;

      final service = RemoteMediaService(
        database: database,
        blossomClient: FakeBlossomClient(),
        mdkService: FakeMdkService(),
        nostrService: FakeNostrService(),
        supportDirectoryProvider: () async => tempDir,
      );

      final repairedPath = await service.ensureVideoAvailable(share);
      final repairedBytes = await File(repairedPath).readAsBytes();
      final cached = await database.getRemoteAssetByRemoteShareId(
        share.remoteShareId,
      );

      expect(repairedPath, isNot(staleFile.path));
      expect(await staleFile.exists(), isFalse);
      expect(repairedBytes.sublist(4, 8), [0x66, 0x74, 0x79, 0x70]);
      expect(cached?.localMediaPath, repairedPath);
    },
  );
}
