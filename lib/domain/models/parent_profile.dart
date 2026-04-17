import 'dart:convert';

class ParentProfile {
  const ParentProfile({
    required this.publicKeyHex,
    required this.displayName,
    this.about,
    this.updatedAt,
    this.cachedAt,
  });

  final String publicKeyHex;
  final String displayName;
  final String? about;
  final DateTime? updatedAt;
  final DateTime? cachedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'public_key_hex': publicKeyHex,
    'display_name': displayName,
    'about': about,
    'updated_at': updatedAt?.toUtc().toIso8601String(),
    'cached_at': cachedAt?.toUtc().toIso8601String(),
  };

  String encode() => jsonEncode(toJson());

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      publicKeyHex: json['public_key_hex']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      about: json['about']?.toString(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      cachedAt: DateTime.tryParse(json['cached_at']?.toString() ?? ''),
    );
  }

  factory ParentProfile.decode(String raw) {
    return ParentProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
