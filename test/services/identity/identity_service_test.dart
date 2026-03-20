import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/constants.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/services/identity/identity_service.dart';

class _BucketedSecureStoragePlatform extends FlutterSecureStoragePlatform {
  _BucketedSecureStoragePlatform();

  final Map<String, Map<String, String>> buckets = {
    'local': <String, String>{},
    'synced': <String, String>{},
  };

  String _bucketKey(Map<String, String> options) {
    return options['synchronizable'] == 'true' ? 'synced' : 'local';
  }

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async {
    return buckets[_bucketKey(options)]!.containsKey(key);
  }

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    buckets[_bucketKey(options)]!.remove(key);
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    buckets[_bucketKey(options)]!.clear();
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    return buckets[_bucketKey(options)]![key];
  }

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async {
    return Map<String, String>.from(buckets[_bucketKey(options)]!);
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    buckets[_bucketKey(options)]![key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late FlutterSecureStorage storage;
  late IdentityService service;
  late FlutterSecureStoragePlatform originalPlatform;
  late _BucketedSecureStoragePlatform testPlatform;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    originalPlatform = FlutterSecureStoragePlatform.instance;
    testPlatform = _BucketedSecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = testPlatform;
    database = AppDatabase.forTesting(NativeDatabase.memory());
    storage = const FlutterSecureStorage();
    service = IdentityService(secureStorage: storage, database: database);
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    FlutterSecureStoragePlatform.instance = originalPlatform;
    await database.close();
  });

  test('parseImportedIdentity accepts nsec and raw hex forms', () {
    const privateKeyHex =
        '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';

    final fromHex = IdentityService.parseImportedIdentity(
      privateKeyHex,
      createdAt: DateTime.utc(2026, 3, 17),
    );
    final fromNsec = IdentityService.parseImportedIdentity(
      fromHex.nsec,
      createdAt: DateTime.utc(2026, 3, 17),
    );

    expect(fromNsec.privateKeyHex, privateKeyHex);
    expect(fromNsec.publicKeyHex, fromHex.publicKeyHex);
    expect(fromNsec.npub, fromHex.npub);
    expect(fromNsec.nsec, fromHex.nsec);
  });

  test('importParentIdentity persists and can be loaded back', () async {
    const privateKeyHex =
        '1f1e1d1c1b1a191817161514131211100f0e0d0c0b0a09080706050403020100';

    final imported = await service.importParentIdentity(privateKeyHex);
    final loaded = await service.loadIdentity();

    expect(loaded, isNotNull);
    expect(loaded!.privateKeyHex, imported.privateKeyHex);
    expect(loaded.nsec, imported.nsec);
    expect(
      testPlatform.buckets['local']![AppConstants.parentIdentityStorageKey],
      isNotEmpty,
    );
    expect(
      testPlatform.buckets['synced']![AppConstants.parentIdentityStorageKey],
      isNotEmpty,
    );
  });

  test(
    'loadIdentity migrates a legacy local-only key into synced storage',
    () async {
      const privateKeyHex =
          'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd';
      final legacyIdentity = IdentityService.parseImportedIdentity(
        privateKeyHex,
        createdAt: DateTime.utc(2026, 3, 17),
      );
      testPlatform.buckets['local']![AppConstants.parentIdentityStorageKey] =
          legacyIdentity.encode();

      final loaded = await service.loadIdentity();

      expect(loaded, isNotNull);
      expect(loaded!.privateKeyHex, privateKeyHex);
      expect(
        testPlatform.buckets['synced']![AppConstants.parentIdentityStorageKey],
        legacyIdentity.encode(),
      );
    },
  );

  test(
    'clearIdentity removes both local and synced parent key copies',
    () async {
      const privateKeyHex =
          '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';

      await service.importParentIdentity(privateKeyHex);
      await service.clearIdentity();

      expect(await service.loadIdentity(), isNull);
      expect(
        testPlatform.buckets['local']![AppConstants.parentIdentityStorageKey],
        isNull,
      );
      expect(
        testPlatform.buckets['synced']![AppConstants.parentIdentityStorageKey],
        isNull,
      );
    },
  );
}
