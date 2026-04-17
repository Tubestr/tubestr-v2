import 'dart:convert';

class BlossomServerList {
  const BlossomServerList({required this.servers, this.updatedAt});

  final List<String> servers;
  final DateTime? updatedAt;

  BlossomServerList copyWith({List<String>? servers, DateTime? updatedAt}) {
    return BlossomServerList(
      servers: servers ?? this.servers,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'servers': servers,
    'updated_at': updatedAt?.toUtc().toIso8601String(),
  };

  String encode() => jsonEncode(toJson());

  factory BlossomServerList.fromJson(Map<String, dynamic> json) {
    final rawServers = json['servers'];
    final servers = rawServers is List
        ? rawServers
              .map((item) => item.toString().trim())
              .where((url) => url.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    return BlossomServerList(
      servers: servers,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  /// Decodes either the new structured format or the legacy plain-array format.
  static BlossomServerList decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      final servers = decoded
          .map((item) => item.toString().trim())
          .where((url) => url.isNotEmpty)
          .toList(growable: false);
      return BlossomServerList(servers: servers);
    }
    if (decoded is Map) {
      return BlossomServerList.fromJson(Map<String, dynamic>.from(decoded));
    }
    return const BlossomServerList(servers: <String>[]);
  }
}
