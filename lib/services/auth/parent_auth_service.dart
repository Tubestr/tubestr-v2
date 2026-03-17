import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants.dart';

class ParentAuthService {
  ParentAuthService(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  Future<bool> hasPin() async {
    final value = await _secureStorage.read(key: AppConstants.parentPinStorageKey);
    return value != null && value.isNotEmpty;
  }

  Future<void> setPin(String pin) {
    final digest = sha256.convert(utf8.encode(pin)).toString();
    return _secureStorage.write(
      key: AppConstants.parentPinStorageKey,
      value: digest,
    );
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.read(key: AppConstants.parentPinStorageKey);
    if (stored == null) {
      return false;
    }
    final digest = sha256.convert(utf8.encode(pin)).toString();
    return stored == digest;
  }

  Future<void> clearPin() {
    return _secureStorage.delete(key: AppConstants.parentPinStorageKey);
  }
}
