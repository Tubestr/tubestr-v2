import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart' as bip340;
import 'package:ndk/shared/nips/nip01/helpers.dart';
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
  static final RegExp _hexKeyPattern = RegExp(r'^[0-9a-fA-F]{64}$');
  static const IOSOptions _syncedAppleOptions = IOSOptions(
    synchronizable: true,
    accessibility: KeychainAccessibility.first_unlock,
  );
  static const AppleOptions _syncedMacOptions = MacOsOptions(
    synchronizable: true,
    accessibility: KeychainAccessibility.first_unlock,
  );

  Future<ParentIdentity?> loadIdentity() async {
    final raw = await _readParentIdentityRaw();
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

    await _persistParentIdentity(identity);
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'true');
    return identity;
  }

  Future<ParentIdentity> importParentIdentity(String rawInput) async {
    final identity = parseImportedIdentity(rawInput);
    await _persistParentIdentity(identity);
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'true');
    return identity;
  }

  Future<void> clearIdentity() async {
    await _secureStorage.delete(key: AppConstants.parentIdentityStorageKey);
    await _secureStorage.delete(
      key: AppConstants.parentIdentityStorageKey,
      iOptions: _syncedAppleOptions,
      mOptions: _syncedMacOptions,
    );
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

  @visibleForTesting
  static ParentIdentity parseImportedIdentity(
    String rawInput, {
    DateTime? createdAt,
  }) {
    final privateKeyHex = _decodeImportedPrivateKeyHex(rawInput);
    final publicKeyHex = bip340.Bip340.getPublicKey(privateKeyHex);
    final timestamp = (createdAt ?? DateTime.now()).toUtc().toIso8601String();
    return ParentIdentity(
      publicKeyHex: publicKeyHex,
      privateKeyHex: privateKeyHex,
      npub: Helpers.encodeBech32(publicKeyHex, 'npub'),
      nsec: Helpers.encodeBech32(privateKeyHex, 'nsec'),
      createdAtIso: timestamp,
    );
  }

  static String _decodeImportedPrivateKeyHex(String rawInput) {
    final normalized = rawInput
        .trim()
        .replaceFirst(RegExp(r'^nostr:', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) {
      throw const FormatException('Enter your parent private key to continue.');
    }
    if (_hexKeyPattern.hasMatch(normalized)) {
      return normalized.toLowerCase();
    }

    final decoded = Helpers.decodeBech32(normalized.toLowerCase());
    final privateKeyHex = decoded.first;
    final hrp = decoded.length > 1 ? decoded[1] : '';
    if (hrp == 'nsec' && _hexKeyPattern.hasMatch(privateKeyHex)) {
      return privateKeyHex.toLowerCase();
    }

    throw const FormatException(
      'Enter a valid `nsec1...` or 64-character hex private key.',
    );
  }

  Future<String?> _readParentIdentityRaw() async {
    final synced = await _secureStorage.read(
      key: AppConstants.parentIdentityStorageKey,
      iOptions: _syncedAppleOptions,
      mOptions: _syncedMacOptions,
    );
    if (synced != null && synced.isNotEmpty) {
      return synced;
    }

    final local = await _secureStorage.read(
      key: AppConstants.parentIdentityStorageKey,
    );
    if (local != null && local.isNotEmpty) {
      await _secureStorage.write(
        key: AppConstants.parentIdentityStorageKey,
        value: local,
        iOptions: _syncedAppleOptions,
        mOptions: _syncedMacOptions,
      );
    }
    return local;
  }

  Future<void> _persistParentIdentity(ParentIdentity identity) async {
    final encoded = identity.encode();
    await _secureStorage.write(
      key: AppConstants.parentIdentityStorageKey,
      value: encoded,
    );
    await _secureStorage.write(
      key: AppConstants.parentIdentityStorageKey,
      value: encoded,
      iOptions: _syncedAppleOptions,
      mOptions: _syncedMacOptions,
    );
  }
}
