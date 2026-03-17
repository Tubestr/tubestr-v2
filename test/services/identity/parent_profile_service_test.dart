import 'dart:convert';

import 'package:mytube/core/constants.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/identity/parent_profile_service.dart';
import 'package:mytube/services/offline/offline_action_store.dart';
import 'package:ndk/entities.dart';

import '../../test_support/service_fakes.dart';

void main() {
  late AppDatabase database;
  late FakeNostrService nostr;
  late ParentProfileService service;

  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub-parent',
    nsec: 'nsec-parent',
    createdAtIso: '2026-03-15T00:00:00.000Z',
  );

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    nostr = FakeNostrService();
    service = ParentProfileService(
      database: database,
      nostrService: nostr,
      offlineActionStore: OfflineActionStore(database: database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'publishLocalProfile stores local name and broadcasts metadata',
    () async {
      final profile = await service.publishLocalProfile(
        identity: identity,
        displayName: 'Lee & Emma',
      );

      expect(profile.displayName, 'Lee & Emma');
      expect(await service.loadLocalDisplayName(), 'Lee & Emma');
      expect(nostr.lastPublishedDisplayName, 'Lee & Emma');
    },
  );

  test('resolveProfile fetches and caches a remote parent profile', () async {
    nostr.queryEventsResult = <Nip01Event>[
      Nip01Event(
        pubKey: 'remote-parent',
        kind: 0,
        tags: const [],
        content: jsonEncode(<String, dynamic>{
          'display_name': 'Noah\'s Family',
          'about': 'Friends from school',
        }),
        createdAt: DateTime.utc(2026, 3, 16).millisecondsSinceEpoch ~/ 1000,
      ),
    ];

    final profile = await service.resolveProfile(publicKeyHex: 'remote-parent');
    final cached = await service.resolveProfile(publicKeyHex: 'remote-parent');

    expect(profile?.displayName, 'Noah\'s Family');
    expect(cached?.displayName, 'Noah\'s Family');
    expect(nostr.lastQueryFilter?.authors, contains('remote-parent'));
  });

  test('publishLocalProfile queues retry when relay publish fails', () async {
    nostr.throwOnPublishParentProfile = true;

    await expectLater(
      () => service.publishLocalProfile(
        identity: identity,
        displayName: 'Lee & Emma',
      ),
      throwsA(isA<StateError>()),
    );

    final queued = await database.getSetting(
      AppConstants.offlineActionQueueSettingKey,
    );
    expect(queued, isNotNull);
    expect(queued, contains('publishParentProfile'));
  });
}
