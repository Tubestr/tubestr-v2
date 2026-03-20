import 'dart:convert';

class GroupInvitePacket {
  static const type = 'mytube/group_invite_packet';
  static const deepLinkScheme = 'nook';
  static const deepLinkHost = 'family-invite';

  const GroupInvitePacket({
    required this.publicKeyHex,
    required this.createdAt,
    this.keyPackageEventId,
    this.inviterDisplayName,
  });

  final String publicKeyHex;
  final int createdAt;
  final String? keyPackageEventId;
  final String? inviterDisplayName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      't': type,
      'v': 1,
      'pubkey': publicKeyHex,
      'created_at': createdAt,
      if (inviterDisplayName != null && inviterDisplayName!.trim().isNotEmpty)
        'inviter_name': inviterDisplayName!.trim(),
      if (keyPackageEventId != null && keyPackageEventId!.isNotEmpty)
        'event_id': keyPackageEventId,
    };
  }

  String get shareText =>
      '''
Tubestr Family Invite
Parent: ${inviterDisplayName?.trim().isNotEmpty == true ? inviterDisplayName!.trim() : publicKeyHex}

Open this link on the other parent's device:
${encode()}
''';

  String encode() {
    final payload = base64UrlEncode(utf8.encode(jsonEncode(toJson())));
    return Uri(
      scheme: deepLinkScheme,
      host: deepLinkHost,
      queryParameters: <String, String>{'v': '1', 'data': payload},
    ).toString();
  }

  factory GroupInvitePacket.fromJson(Map<String, dynamic> json) {
    if (json['t'] != type) {
      throw const FormatException('Invalid group invite packet type');
    }

    return GroupInvitePacket(
      publicKeyHex: json['pubkey'] as String,
      createdAt: (json['created_at'] as num).toInt(),
      keyPackageEventId: json['event_id']?.toString(),
      inviterDisplayName: json['inviter_name']?.toString(),
    );
  }

  factory GroupInvitePacket.decode(String raw) {
    final trimmed = raw.trim();
    final deepLinkPacket = _tryDecodeDeepLink(trimmed);
    if (deepLinkPacket != null) {
      return deepLinkPacket;
    }

    if (trimmed.startsWith('{')) {
      return GroupInvitePacket.fromJson(
        jsonDecode(trimmed) as Map<String, dynamic>,
      );
    }

    for (final token in trimmed.split(RegExp(r"[\s,;|<>()']+"))) {
      final candidate = token.trim();
      if (candidate.isEmpty) {
        continue;
      }
      final parsed = _tryDecodeDeepLink(candidate);
      if (parsed != null) {
        return parsed;
      }
    }

    throw const FormatException('Invalid group invite packet');
  }

  static GroupInvitePacket? _tryDecodeDeepLink(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme.toLowerCase() != deepLinkScheme ||
        uri.host.toLowerCase() != deepLinkHost) {
      return null;
    }
    final data = uri.queryParameters['data'];
    if (data == null || data.isEmpty) {
      return null;
    }
    final decoded = utf8.decode(base64Url.decode(base64Url.normalize(data)));
    return GroupInvitePacket.fromJson(
      jsonDecode(decoded) as Map<String, dynamic>,
    );
  }
}
