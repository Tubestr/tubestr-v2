import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart' as bip340;
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/theme_descriptor.dart';
import '../../domain/models/parent_identity.dart';

class IdentityService {
  IdentityService({
    required FlutterSecureStorage secureStorage,
    required AppDatabase database,
  }) : _secureStorage = secureStorage,
       _database = database;

  final FlutterSecureStorage _secureStorage;
  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<ParentIdentity?> loadIdentity() async {
    final raw = await _secureStorage.read(
      key: AppConstants.parentIdentityStorageKey,
    );
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return ParentIdentity.decode(raw);
  }

  Future<ParentIdentity> createParentIdentity() async {
    final keyPair = bip340.Bip340.generatePrivateKey();
    final identity = ParentIdentity(
      publicKeyHex: keyPair.publicKey,
      privateKeyHex: keyPair.privateKey ?? '',
      npub: keyPair.publicKeyBech32 ?? '',
      nsec: keyPair.privateKeyBech32 ?? '',
      createdAtIso: DateTime.now().toUtc().toIso8601String(),
    );

    await _secureStorage.write(
      key: AppConstants.parentIdentityStorageKey,
      value: identity.encode(),
    );
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'true');
    return identity;
  }

  Future<void> clearIdentity() async {
    await _secureStorage.delete(key: AppConstants.parentIdentityStorageKey);
  }

  Future<void> createChildProfile({
    required String name,
    required ThemeDescriptor theme,
  }) async {
    final profileId = _uuid.v4();
    await _database.upsertProfile(
      id: profileId,
      name: name.trim(),
      theme: theme.name,
      avatarAsset: theme.defaultAvatarAsset,
    );
    final inheritedGroupId = await _database.getPrimaryGroupIdForAnyProfile();
    if (inheritedGroupId != null && inheritedGroupId.isNotEmpty) {
      await _database.setPrimaryGroupForProfile(
        profileId: profileId,
        mlsGroupId: inheritedGroupId,
      );
    }
  }
}
