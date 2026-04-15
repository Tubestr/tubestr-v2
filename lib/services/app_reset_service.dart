import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/storage/app_database.dart';
import 'auth/parent_auth_service.dart';
import 'identity/identity_service.dart';
import 'mdk/mdk_service.dart';

class AppResetService {
  AppResetService({
    required AppDatabase database,
    required IdentityService identityService,
    required ParentAuthService parentAuthService,
    required MdkService mdkService,
    Future<Directory> Function()? documentsDirectoryProvider,
    Future<Directory> Function()? supportDirectoryProvider,
  }) : _database = database,
       _identityService = identityService,
       _parentAuthService = parentAuthService,
       _mdkService = mdkService,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  final AppDatabase _database;
  final IdentityService _identityService;
  final ParentAuthService _parentAuthService;
  final MdkService _mdkService;
  final Future<Directory> Function() _documentsDirectoryProvider;
  final Future<Directory> Function() _supportDirectoryProvider;

  Future<void> resetApp({
    FutureOr<void> Function()? afterCredentialsCleared,
  }) async {
    await _identityService.clearIdentity();
    await _parentAuthService.clearPin();
    await afterCredentialsCleared?.call();
    await _database.clearAllData();
    await _deleteAppOwnedFiles();
    await _mdkService.resetLocalState();
  }

  Future<void> _deleteAppOwnedFiles() async {
    final documents = await _documentsDirectoryProvider();
    final support = await _supportDirectoryProvider();

    await _deleteDirectoryIfExists(Directory(p.join(documents.path, 'videos')));
    await _deleteDirectoryIfExists(
      Directory(p.join(documents.path, 'thumbnails')),
    );

    await _deleteDirectoryIfExists(
      Directory(p.join(support.path, 'remote_cache')),
    );
    await _deleteDirectoryIfExists(
      Directory(p.join(support.path, 'editor_exports')),
    );
    await _deleteDirectoryIfExists(
      Directory(p.join(support.path, 'editor_stickers')),
    );
  }

  Future<void> _deleteDirectoryIfExists(Directory directory) async {
    if (!await directory.exists()) {
      return;
    }
    await directory.delete(recursive: true);
  }
}
