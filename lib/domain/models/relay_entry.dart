import 'dart:convert';

enum RelayMarker {
  readWrite('rw'),
  read('r'),
  write('w');

  const RelayMarker(this.code);

  final String code;

  static RelayMarker fromCode(String? code) {
    switch (code) {
      case 'r':
      case 'read':
        return RelayMarker.read;
      case 'w':
      case 'write':
        return RelayMarker.write;
      default:
        return RelayMarker.readWrite;
    }
  }
}

class RelayEntry {
  const RelayEntry({required this.url, this.marker = RelayMarker.readWrite});

  final String url;
  final RelayMarker marker;

  RelayEntry copyWith({String? url, RelayMarker? marker}) {
    return RelayEntry(url: url ?? this.url, marker: marker ?? this.marker);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'url': url,
    'marker': marker.code,
  };

  factory RelayEntry.fromJson(Map<String, dynamic> json) {
    return RelayEntry(
      url: json['url']?.toString() ?? '',
      marker: RelayMarker.fromCode(json['marker']?.toString()),
    );
  }
}

class RelayList {
  const RelayList({required this.entries, this.updatedAt});

  final List<RelayEntry> entries;
  final DateTime? updatedAt;

  List<String> get urls =>
      entries.map((entry) => entry.url).toList(growable: false);

  RelayList copyWith({List<RelayEntry>? entries, DateTime? updatedAt}) {
    return RelayList(
      entries: entries ?? this.entries,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    'updated_at': updatedAt?.toUtc().toIso8601String(),
  };

  String encode() => jsonEncode(toJson());

  factory RelayList.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    final entries = rawEntries is List
        ? rawEntries
              .whereType<Map>()
              .map((raw) => RelayEntry.fromJson(Map<String, dynamic>.from(raw)))
              .where((entry) => entry.url.isNotEmpty)
              .toList(growable: false)
        : const <RelayEntry>[];
    return RelayList(
      entries: entries,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  /// Decodes either the new structured format or the legacy plain-array format.
  /// Legacy entries are treated as read+write with no known updatedAt.
  static RelayList decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      final entries = decoded
          .map((item) => item.toString().trim())
          .where((url) => url.isNotEmpty)
          .map((url) => RelayEntry(url: url))
          .toList(growable: false);
      return RelayList(entries: entries);
    }
    if (decoded is Map) {
      return RelayList.fromJson(Map<String, dynamic>.from(decoded));
    }
    return const RelayList(entries: <RelayEntry>[]);
  }
}
