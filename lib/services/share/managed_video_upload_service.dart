import 'dart:convert';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';

class ManagedUploadedBlob {
  const ManagedUploadedBlob({required this.hash, required this.servers});

  final String hash;
  final List<String> servers;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'hash': hash,
    'servers': servers,
  };

  factory ManagedUploadedBlob.fromJson(Map<String, dynamic> json) {
    final rawServers = json['servers'];
    return ManagedUploadedBlob(
      hash: json['hash']?.toString() ?? '',
      servers: rawServers is List
          ? rawServers
                .map((server) => server.toString().trim())
                .where((server) => server.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
    );
  }
}

class ManagedVideoUploadRecord {
  const ManagedVideoUploadRecord({
    required this.videoId,
    required this.profileId,
    required this.createdAt,
    required this.videoBlob,
    required this.thumbBlob,
  });

  final String videoId;
  final String profileId;
  final DateTime createdAt;
  final ManagedUploadedBlob videoBlob;
  final ManagedUploadedBlob thumbBlob;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'video_id': videoId,
    'profile_id': profileId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'video_blob': videoBlob.toJson(),
    'thumb_blob': thumbBlob.toJson(),
  };

  factory ManagedVideoUploadRecord.fromJson(Map<String, dynamic> json) {
    return ManagedVideoUploadRecord(
      videoId: json['video_id']?.toString() ?? '',
      profileId: json['profile_id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      videoBlob: ManagedUploadedBlob.fromJson(
        (json['video_blob'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      thumbBlob: ManagedUploadedBlob.fromJson(
        (json['thumb_blob'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }

  static List<ManagedVideoUploadRecord> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <ManagedVideoUploadRecord>[];
    }
    return decoded
        .whereType<Map>()
        .map(
          (entry) =>
              ManagedVideoUploadRecord.fromJson(entry.cast<String, dynamic>()),
        )
        .where(
          (entry) =>
              entry.videoId.isNotEmpty &&
              entry.profileId.isNotEmpty &&
              entry.videoBlob.hash.isNotEmpty &&
              entry.thumbBlob.hash.isNotEmpty,
        )
        .toList(growable: false);
  }

  static String encodeList(List<ManagedVideoUploadRecord> records) {
    return jsonEncode(records.map((record) => record.toJson()).toList());
  }
}

class ManagedVideoUploadService {
  ManagedVideoUploadService({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Future<List<ManagedVideoUploadRecord>> load() async {
    final raw = await _database.getSetting(
      AppConstants.managedVideoUploadsSettingKey,
    );
    if (raw == null || raw.isEmpty) {
      return const <ManagedVideoUploadRecord>[];
    }
    return ManagedVideoUploadRecord.decodeList(raw);
  }

  Future<List<ManagedVideoUploadRecord>> loadForProfile(
    String profileId,
  ) async {
    final records = await load();
    return records
        .where((record) => record.profileId == profileId)
        .toList(growable: false);
  }

  Future<void> recordUpload({
    required String videoId,
    required String profileId,
    required ManagedUploadedBlob videoBlob,
    required ManagedUploadedBlob thumbBlob,
  }) async {
    final current = await load();
    final updated = <ManagedVideoUploadRecord>[
      ManagedVideoUploadRecord(
        videoId: videoId,
        profileId: profileId,
        createdAt: DateTime.now(),
        videoBlob: videoBlob,
        thumbBlob: thumbBlob,
      ),
      ...current,
    ];
    await _database.putSetting(
      AppConstants.managedVideoUploadsSettingKey,
      ManagedVideoUploadRecord.encodeList(updated.take(200).toList()),
    );
  }

  Future<void> removeProfile(String profileId) async {
    final current = await load();
    final remaining = current
        .where((record) => record.profileId != profileId)
        .toList(growable: false);
    await _database.putSetting(
      AppConstants.managedVideoUploadsSettingKey,
      ManagedVideoUploadRecord.encodeList(remaining),
    );
  }
}
