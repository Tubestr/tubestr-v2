import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/services/app_reset_service.dart';
import 'package:mytube/services/auth/parent_auth_service.dart';
import 'package:mytube/services/identity/identity_service.dart';
import 'package:mytube/services/mdk/mdk_service.dart';

class _BucketedSecureStoragePlatform extends FlutterSecureStoragePlatform {
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

class _NoopMdkService extends MdkService {
  bool resetCalled = false;

  @override
  Future<void> resetLocalState() async {
    resetCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late FlutterSecureStoragePlatform originalPlatform;
  late Directory documentsDirectory;
  late Directory supportDirectory;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    originalPlatform = FlutterSecureStoragePlatform.instance;
    FlutterSecureStoragePlatform.instance = _BucketedSecureStoragePlatform();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    documentsDirectory = await Directory.systemTemp.createTemp(
      'tubestr_reset_docs_',
    );
    supportDirectory = await Directory.systemTemp.createTemp(
      'tubestr_reset_support_',
    );
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    FlutterSecureStoragePlatform.instance = originalPlatform;
    await database.close();
    if (await documentsDirectory.exists()) {
      await documentsDirectory.delete(recursive: true);
    }
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  test(
    'resetApp can refresh parent identity before profile rows are cleared',
    () async {
      const storage = FlutterSecureStorage();
      final identityService = IdentityService(
        secureStorage: storage,
        database: database,
      );
      final authService = ParentAuthService(storage);
      final mdkService = _NoopMdkService();
      final resetService = AppResetService(
        database: database,
        identityService: identityService,
        parentAuthService: authService,
        mdkService: mdkService,
        documentsDirectoryProvider: () async => documentsDirectory,
        supportDirectoryProvider: () async => supportDirectory,
      );

      await identityService.importParentIdentity(
        '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
      );
      await authService.setPin('1234');
      await database.upsertProfile(
        id: 'kid-1',
        name: 'Kid',
        theme: 'campfire',
        avatarAsset: 'avatar',
      );
      await Directory('${documentsDirectory.path}/videos').create();
      await File(
        '${documentsDirectory.path}/videos/clip.mp4',
      ).writeAsString('clip');

      var hookSawClearedIdentity = false;
      var hookSawClearedPin = false;
      var hookSawProfilesBeforeClear = false;

      await resetService.resetApp(
        afterCredentialsCleared: () async {
          hookSawClearedIdentity = await identityService.loadIdentity() == null;
          hookSawClearedPin = !await authService.hasPin();
          hookSawProfilesBeforeClear =
              (await database.watchProfiles().first).isNotEmpty;
        },
      );

      expect(hookSawClearedIdentity, isTrue);
      expect(hookSawClearedPin, isTrue);
      expect(hookSawProfilesBeforeClear, isTrue);
      expect(await database.watchProfiles().first, isEmpty);
      expect(
        await Directory('${documentsDirectory.path}/videos').exists(),
        isFalse,
      );
      expect(mdkService.resetCalled, isTrue);
    },
  );
}
