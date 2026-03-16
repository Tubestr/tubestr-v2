import 'dart:convert';

class ParentIdentity {
  const ParentIdentity({
    required this.publicKeyHex,
    required this.privateKeyHex,
    required this.npub,
    required this.nsec,
    required this.createdAtIso,
  });

  final String publicKeyHex;
  final String privateKeyHex;
  final String npub;
  final String nsec;
  final String createdAtIso;

  DateTime get createdAt => DateTime.parse(createdAtIso);

  ParentIdentity copyWith({
    String? publicKeyHex,
    String? privateKeyHex,
    String? npub,
    String? nsec,
    String? createdAtIso,
  }) {
    return ParentIdentity(
      publicKeyHex: publicKeyHex ?? this.publicKeyHex,
      privateKeyHex: privateKeyHex ?? this.privateKeyHex,
      npub: npub ?? this.npub,
      nsec: nsec ?? this.nsec,
      createdAtIso: createdAtIso ?? this.createdAtIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'public_key_hex': publicKeyHex,
      'private_key_hex': privateKeyHex,
      'npub': npub,
      'nsec': nsec,
      'created_at': createdAtIso,
    };
  }

  String encode() => jsonEncode(toJson());

  static ParentIdentity fromJson(Map<String, dynamic> json) {
    return ParentIdentity(
      publicKeyHex: json['public_key_hex'] as String,
      privateKeyHex: json['private_key_hex'] as String,
      npub: json['npub'] as String,
      nsec: json['nsec'] as String,
      createdAtIso: json['created_at'] as String,
    );
  }

  static ParentIdentity decode(String raw) {
    return fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
