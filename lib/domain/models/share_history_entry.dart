import 'dart:convert';

class ShareHistoryEntry {
  const ShareHistoryEntry({
    required this.id,
    required this.videoId,
    required this.title,
    required this.childProfileId,
    required this.childDisplayName,
    required this.mlsGroupId,
    required this.status,
    required this.createdAt,
    this.eventId,
    this.error,
  });

  final String id;
  final String videoId;
  final String title;
  final String childProfileId;
  final String childDisplayName;
  final String mlsGroupId;
  final String status;
  final DateTime createdAt;
  final String? eventId;
  final String? error;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'video_id': videoId,
    'title': title,
    'child_profile_id': childProfileId,
    'child_display_name': childDisplayName,
    'mls_group_id': mlsGroupId,
    'status': status,
    'created_at': createdAt.toUtc().toIso8601String(),
    'event_id': eventId,
    'error': error,
  };

  factory ShareHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ShareHistoryEntry(
      id: json['id']?.toString() ?? '',
      videoId: json['video_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Shared video',
      childProfileId: json['child_profile_id']?.toString() ?? '',
      childDisplayName: json['child_display_name']?.toString() ?? '',
      mlsGroupId: json['mls_group_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'sent',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      eventId: json['event_id']?.toString(),
      error: json['error']?.toString(),
    );
  }

  static List<ShareHistoryEntry> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <ShareHistoryEntry>[];
    }
    return decoded
        .map((item) => ShareHistoryEntry.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static String encodeList(List<ShareHistoryEntry> entries) {
    return jsonEncode(entries.map((entry) => entry.toJson()).toList());
  }
}
