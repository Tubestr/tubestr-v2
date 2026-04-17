import 'dart:convert';

/// A single entry in the NIP-51 kind-10000 mute list.
class MuteEntry {
  const MuteEntry({required this.pubkeyHex, this.reason, this.addedAt});

  final String pubkeyHex;
  final String? reason;
  final DateTime? addedAt;

  MuteEntry copyWith({String? pubkeyHex, String? reason, DateTime? addedAt}) {
    return MuteEntry(
      pubkeyHex: pubkeyHex ?? this.pubkeyHex,
      reason: reason ?? this.reason,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'pubkey_hex': pubkeyHex,
    if (reason != null) 'reason': reason,
    if (addedAt != null) 'added_at': addedAt!.toUtc().toIso8601String(),
  };

  factory MuteEntry.fromJson(Map<String, dynamic> json) {
    return MuteEntry(
      pubkeyHex: json['pubkey_hex']?.toString().trim() ?? '',
      reason: json['reason']?.toString(),
      addedAt: DateTime.tryParse(json['added_at']?.toString() ?? ''),
    );
  }
}

class MuteList {
  const MuteList({required this.entries, this.updatedAt});

  final List<MuteEntry> entries;
  final DateTime? updatedAt;

  List<String> get pubkeyHexes =>
      entries.map((e) => e.pubkeyHex).toList(growable: false);

  bool contains(String pubkeyHex) {
    final normalized = pubkeyHex.toLowerCase();
    for (final entry in entries) {
      if (entry.pubkeyHex.toLowerCase() == normalized) {
        return true;
      }
    }
    return false;
  }

  MuteList copyWith({List<MuteEntry>? entries, DateTime? updatedAt}) {
    return MuteList(
      entries: entries ?? this.entries,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'entries': entries.map((e) => e.toJson()).toList(growable: false),
    'updated_at': updatedAt?.toUtc().toIso8601String(),
  };

  String encode() => jsonEncode(toJson());

  factory MuteList.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    final entries = rawEntries is List
        ? rawEntries
              .whereType<Map>()
              .map((raw) => MuteEntry.fromJson(Map<String, dynamic>.from(raw)))
              .where((entry) => entry.pubkeyHex.isNotEmpty)
              .toList(growable: false)
        : const <MuteEntry>[];
    return MuteList(
      entries: entries,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  static MuteList decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return MuteList.fromJson(Map<String, dynamic>.from(decoded));
    }
    return const MuteList(entries: <MuteEntry>[]);
  }
}
