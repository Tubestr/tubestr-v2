import 'dart:convert';

enum OfflineActionType {
  shareVideo,
  sendLike,
  sendReaction,
  submitReport,
  publishParentProfile,
}

class OfflineAction {
  const OfflineAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.lastError,
  });

  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? lastError;

  OfflineAction copyWith({
    String? id,
    OfflineActionType? type,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? attemptCount,
    DateTime? lastAttemptAt,
    String? lastError,
    bool clearLastError = false,
  }) {
    return OfflineAction(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'payload': payload,
    'created_at': createdAt.toUtc().toIso8601String(),
    'attempt_count': attemptCount,
    'last_attempt_at': lastAttemptAt?.toUtc().toIso8601String(),
    'last_error': lastError,
  };

  String encode() => jsonEncode(toJson());

  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      id: json['id']?.toString() ?? '',
      type: OfflineActionType.values.byName(
        json['type']?.toString() ?? OfflineActionType.shareVideo.name,
      ),
      payload: Map<String, dynamic>.from(
        json['payload'] as Map? ?? const <String, dynamic>{},
      ),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 0,
      lastAttemptAt: DateTime.tryParse(
        json['last_attempt_at']?.toString() ?? '',
      )?.toLocal(),
      lastError: json['last_error']?.toString(),
    );
  }

  factory OfflineAction.decode(String raw) {
    return OfflineAction.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
