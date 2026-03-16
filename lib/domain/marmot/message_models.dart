import 'dart:convert';

class MarmotMessageFormatException implements FormatException {
  MarmotMessageFormatException(this.message);

  @override
  final String message;

  @override
  final int? offset = null;

  @override
  final Object? source = null;

  @override
  String toString() => 'MarmotMessageFormatException: $message';
}

class VideoMeta {
  const VideoMeta({
    required this.title,
    required this.durationSeconds,
    required this.createdAt,
  });

  final String title;
  final double durationSeconds;
  final int createdAt;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'dur': durationSeconds,
      'created_at': createdAt,
    };
  }

  factory VideoMeta.fromJson(Map<String, dynamic> json) {
    return VideoMeta(
      title: _requiredString(json, 'title'),
      durationSeconds: _requiredDouble(json, 'dur'),
      createdAt: _requiredInt(json, 'created_at'),
    );
  }
}

class BlobDescriptor {
  const BlobDescriptor({
    required this.hash,
    required this.servers,
    required this.mime,
    required this.length,
    this.originalHash,
    this.nonce,
    this.filename,
    this.schemeVersion,
  });

  final String hash;
  final List<String> servers;
  final String mime;
  final int length;
  final String? originalHash;
  final String? nonce;
  final String? filename;
  final String? schemeVersion;

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'servers': servers,
      'mime': mime,
      'len': length,
      'orig_hash': originalHash,
      'nonce': nonce,
      'filename': filename,
      'scheme': schemeVersion,
    };
  }

  factory BlobDescriptor.fromJson(Map<String, dynamic> json) {
    return BlobDescriptor(
      hash: _requiredString(json, 'hash'),
      servers: _requiredStringList(json, 'servers'),
      mime: _requiredString(json, 'mime'),
      length: _requiredInt(json, 'len'),
      originalHash: _optionalString(json, 'orig_hash'),
      nonce: _optionalString(json, 'nonce'),
      filename: _optionalString(json, 'filename'),
      schemeVersion: _optionalString(json, 'scheme'),
    );
  }
}

class MediaDescriptor {
  const MediaDescriptor({
    required this.algorithm,
    required this.epoch,
  });

  final String algorithm;
  final String epoch;

  Map<String, dynamic> toJson() {
    return {
      'alg': algorithm,
      'epoch': epoch,
    };
  }

  factory MediaDescriptor.fromJson(Map<String, dynamic> json) {
    return MediaDescriptor(
      algorithm: _requiredString(json, 'alg'),
      epoch: _requiredString(json, 'epoch'),
    );
  }
}

class PolicyDescriptor {
  const PolicyDescriptor({
    required this.version,
    this.expiresAt,
  });

  final int version;
  final int? expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'expires_at': expiresAt,
    };
  }

  factory PolicyDescriptor.fromJson(Map<String, dynamic> json) {
    final rawExpiresAt = json['expires_at'];
    return PolicyDescriptor(
      version: _requiredInt(json, 'version'),
      expiresAt: rawExpiresAt == null ? null : _coerceInt(rawExpiresAt, 'expires_at'),
    );
  }
}

class VideoShareMessage {
  static const type = 'mytube/video_share';

  const VideoShareMessage({
    required this.videoId,
    required this.childProfileId,
    required this.childDisplayName,
    required this.meta,
    required this.blob,
    required this.thumb,
    required this.media,
    required this.policy,
    required this.by,
    required this.ts,
  });

  final String videoId;
  final String childProfileId;
  final String childDisplayName;
  final VideoMeta meta;
  final BlobDescriptor blob;
  final BlobDescriptor thumb;
  final MediaDescriptor media;
  final PolicyDescriptor policy;
  final String by;
  final int ts;

  Map<String, dynamic> toJson() {
    return {
      't': type,
      'video_id': videoId,
      'child_profile_id': childProfileId,
      'child_display_name': childDisplayName,
      'meta': meta.toJson(),
      'blob': blob.toJson(),
      'thumb': thumb.toJson(),
      'media': media.toJson(),
      'policy': policy.toJson(),
      'by': by,
      'ts': ts,
    };
  }

  String encode() => jsonEncode(toJson());

  factory VideoShareMessage.fromJson(Map<String, dynamic> json) {
    _requireType(json, type);
    return VideoShareMessage(
      videoId: _requiredString(json, 'video_id'),
      childProfileId: _requiredString(json, 'child_profile_id'),
      childDisplayName: _requiredString(json, 'child_display_name'),
      meta: VideoMeta.fromJson(_requiredMap(json, 'meta')),
      blob: BlobDescriptor.fromJson(_requiredMap(json, 'blob')),
      thumb: BlobDescriptor.fromJson(_requiredMap(json, 'thumb')),
      media: MediaDescriptor.fromJson(_requiredMap(json, 'media')),
      policy: PolicyDescriptor.fromJson(_requiredMap(json, 'policy')),
      by: _requiredString(json, 'by'),
      ts: _requiredInt(json, 'ts'),
    );
  }

  factory VideoShareMessage.decode(String raw) {
    return VideoShareMessage.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}

class VideoLifecycleMessage {
  static const revokeType = 'mytube/video_revoke';
  static const deleteType = 'mytube/video_delete';

  const VideoLifecycleMessage({
    required this.type,
    required this.videoId,
    required this.blobHash,
    required this.by,
    required this.ts,
    this.reason,
  });

  final String type;
  final String videoId;
  final String blobHash;
  final String? reason;
  final String by;
  final int ts;

  Map<String, dynamic> toJson() {
    return {
      't': type,
      'video_id': videoId,
      'blob_hash': blobHash,
      'reason': reason,
      'by': by,
      'ts': ts,
    };
  }

  factory VideoLifecycleMessage.fromJson(Map<String, dynamic> json) {
    final messageType = _requiredString(json, 't');
    if (messageType != revokeType && messageType != deleteType) {
      throw MarmotMessageFormatException(
        'Expected lifecycle type "$revokeType" or "$deleteType" but found "$messageType"',
      );
    }

    return VideoLifecycleMessage(
      type: messageType,
      videoId: _requiredString(json, 'video_id'),
      blobHash: _requiredString(json, 'blob_hash'),
      reason: _optionalString(json, 'reason'),
      by: _requiredString(json, 'by'),
      ts: _requiredInt(json, 'ts'),
    );
  }
}

class LikeMessage {
  static const type = 'mytube/like';

  const LikeMessage({
    required this.videoId,
    required this.childProfileId,
    required this.by,
    required this.ts,
  });

  final String videoId;
  final String childProfileId;
  final String by;
  final int ts;

  Map<String, dynamic> toJson() {
    return {
      't': type,
      'video_id': videoId,
      'child_profile_id': childProfileId,
      'by': by,
      'ts': ts,
    };
  }

  factory LikeMessage.fromJson(Map<String, dynamic> json) {
    _requireType(json, type);
    return LikeMessage(
      videoId: _requiredString(json, 'video_id'),
      childProfileId: _requiredString(json, 'child_profile_id'),
      by: _requiredString(json, 'by'),
      ts: _requiredInt(json, 'ts'),
    );
  }
}

class ReportMessage {
  static const type = 'mytube/report';

  const ReportMessage({
    required this.reportId,
    required this.videoId,
    required this.subjectChildId,
    required this.blobHash,
    required this.reason,
    required this.level,
    required this.recipientType,
    required this.by,
    required this.ts,
    this.note,
    this.reporterChildId,
  });

  final String reportId;
  final String videoId;
  final String subjectChildId;
  final String blobHash;
  final String reason;
  final String? note;
  final int level;
  final String recipientType;
  final String? reporterChildId;
  final String by;
  final int ts;

  Map<String, dynamic> toJson() {
    return {
      't': type,
      'report_id': reportId,
      'video_id': videoId,
      'subject_child_id': subjectChildId,
      'blob_hash': blobHash,
      'reason': reason,
      'note': note,
      'level': level,
      'recipient_type': recipientType,
      'reporter_child_id': reporterChildId,
      'by': by,
      'ts': ts,
    };
  }

  factory ReportMessage.fromJson(Map<String, dynamic> json) {
    _requireType(json, type);
    return ReportMessage(
      reportId: _requiredString(json, 'report_id'),
      videoId: _requiredString(json, 'video_id'),
      subjectChildId: _requiredString(json, 'subject_child_id'),
      blobHash: _requiredString(json, 'blob_hash'),
      reason: _requiredString(json, 'reason'),
      note: _optionalString(json, 'note'),
      level: _requiredInt(json, 'level'),
      recipientType: _requiredString(json, 'recipient_type'),
      reporterChildId: _optionalString(json, 'reporter_child_id'),
      by: _requiredString(json, 'by'),
      ts: _requiredInt(json, 'ts'),
    );
  }
}

void _requireType(Map<String, dynamic> json, String expected) {
  final actual = _requiredString(json, 't');
  if (actual != expected) {
    throw MarmotMessageFormatException(
      'Expected message type "$expected" but found "$actual"',
    );
  }
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue),
    );
  }
  throw MarmotMessageFormatException('Missing or invalid "$key" object');
}

List<String> _requiredStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw MarmotMessageFormatException('Missing or invalid "$key" list');
  }
  return value.map((item) => item.toString()).toList(growable: false);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw MarmotMessageFormatException('Missing or invalid "$key" string');
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw MarmotMessageFormatException('Invalid "$key" string');
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  return _coerceInt(value, key);
}

int _coerceInt(Object? value, String key) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw MarmotMessageFormatException('Missing or invalid "$key" integer');
}

double _requiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  throw MarmotMessageFormatException('Missing or invalid "$key" number');
}
