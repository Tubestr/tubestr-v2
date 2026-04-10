import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/constants.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/mdk/mdk_service.dart';
import 'package:mytube/services/safety/safety_hq_service.dart';

import '../../test_support/service_fakes.dart';

class _SafetyHttpInterceptor extends Interceptor {
  _SafetyHttpInterceptor(this._handler);

  final Response<dynamic> Function(RequestOptions options) _handler;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.resolve(_handler(options));
  }
}

void main() {
  late AppDatabase database;
  late FakeMdkService mdk;
  late FakeNostrService nostr;
  late Dio dio;
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
          description: 'Backend-backed moderation inbox.',
          memberCount: 2,
          adminPubkeysHex: ['parent-pubkey'],
        ),
        welcomeRumorJsons: ['{"id":"welcome-rumor"}'],
      );
    nostr = FakeNostrService();
    dio = Dio()
      ..interceptors.add(
        _SafetyHttpInterceptor((options) {
          if (options.method == 'GET' &&
              options.path ==
                  'https://api.tubestr.app/v1/safety-hq/bootstrap') {
            return Response<Map<String, dynamic>>(
              requestOptions: options,
              data: const {
                'service_public_key_hex': 'backend-pubkey',
                'signed_key_package_event_json': '{"kind":443,"id":"kp"}',
                'key_package_event_id': 'kp',
                'relays': ['wss://relay.example', 'wss://relay.safety.example'],
                'version': 'v1',
                'generated_at': '2026-03-20T00:00:00Z',
              },
            );
          }
          throw StateError(
            'Unexpected request: ${options.method} ${options.path}',
          );
        }),
      );
    service = SafetyHqService(
      database: database,
      mdkService: mdk,
      nostrService: nostr,
      dio: dio,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'ensureProvisioned fetches bootstrap, creates welcomes, and tracks pending enrollment',
    () async {
      await service.queueJoin();

      final group = await service.ensureProvisioned(identity: identity);
      final status = await service.loadStatus();

      expect(group, isNotNull);
      expect(group!.name, AppConstants.safetyHqGroupName);
      expect(status.isJoined, isFalse);
      expect(status.isQueued, isFalse);
      expect(status.groupId, 'safety-group');
      expect(status.servicePublicKeyHex, 'backend-pubkey');
      expect(status.label, 'Connecting');
      expect(status.isProvisioning, isTrue);
      expect(mdk.lastCreateGroupWithWelcomesMemberKeyPackageEventJsons, [
        '{"kind":443,"id":"kp"}',
      ]);
      expect(nostr.lastGiftWrapRecipient, 'backend-pubkey');
      final relays = await service.loadProvisionedRelays();
      expect(relays, ['wss://relay.example', 'wss://relay.safety.example']);
    },
  );

  test('ensureProvisioned reuses an in-flight Safety HQ group', () async {
    await database.putSetting(
      AppConstants.safetyGroupIdSettingKey,
      'existing-safety',
    );
    await database.putSetting(
      AppConstants.safetyServicePubkeySettingKey,
      'backend-pubkey',
    );
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

    final group = await service.ensureProvisioned(identity: identity);
    final status = await service.loadStatus();

    expect(group, isNotNull);
    expect(group!.mlsGroupIdHex, 'existing-safety');
    expect(status.groupId, 'existing-safety');
    expect(status.isJoined, isFalse);
    expect(status.label, 'Connecting');
  });

  test('loadStatus explains queued state conservatively', () async {
    await service.queueJoin();

    final status = await service.loadStatus();

    expect(status.isQueued, isTrue);
    expect(status.isJoined, isFalse);
    expect(status.label, 'Queued');
    expect(status.detail, contains('queued'));
  });

  test(
    'refreshEnrollment marks Safety HQ as joined once backend becomes a member',
    () async {
      await database.putSetting(
        AppConstants.safetyGroupIdSettingKey,
        'safety-group',
      );
      await database.putSetting(
        AppConstants.safetyServicePubkeySettingKey,
        'backend-pubkey',
      );
      mdk.groupMembersResult = const ['parent-pubkey', 'backend-pubkey'];

      final status = await service.refreshEnrollment();

      expect(status.isQueued, isFalse);
      expect(status.isJoined, isTrue);
      expect(status.groupId, 'safety-group');
      expect(status.label, 'Provisioned');
      expect(status.isProvisioning, isFalse);
    },
  );

  test('saveProvisionedRelays persists the backend relay set', () async {
    await service.saveProvisionedRelays([
      'wss://relay.safety.example',
      '',
      '  wss://relay.backup.example  ',
    ]);

    final relays = await service.loadProvisionedRelays();

    expect(relays, [
      'wss://relay.safety.example',
      'wss://relay.backup.example',
    ]);
  });
}
