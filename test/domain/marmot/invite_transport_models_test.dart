import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/marmot/invite_transport_models.dart';

void main() {
  test('group invite packet round trips', () {
    const packet = GroupInvitePacket(
      publicKeyHex: 'pubkey-123',
      createdAt: 1710460800,
      inviterDisplayName: 'Lee',
    );

    final encoded = packet.encode();
    final decoded = GroupInvitePacket.decode(encoded);

    expect(encoded, startsWith('tubestr://family-invite'));
    expect(decoded.publicKeyHex, 'pubkey-123');
    expect(decoded.createdAt, 1710460800);
    expect(decoded.inviterDisplayName, 'Lee');
    expect(decoded.toJson()['v'], 1);
  });

  test('group invite packet decodes legacy nook links', () {
    final encoded = Uri(
      scheme: 'nook',
      host: GroupInvitePacket.deepLinkHost,
      queryParameters: <String, String>{
        'v': '1',
        'data':
            'eyJ0IjoibXl0dWJlL2dyb3VwX2ludml0ZV9wYWNrZXQiLCJ2IjoxLCJwdWJrZXkiOiJwdWJrZXktMTIzIiwiY3JlYXRlZF9hdCI6MTcxMDQ2MDgwMCwiaW52aXRlcl9uYW1lIjoiTGVlIn0',
      },
    ).toString();

    final decoded = GroupInvitePacket.decode(encoded);

    expect(decoded.publicKeyHex, 'pubkey-123');
    expect(decoded.createdAt, 1710460800);
    expect(decoded.inviterDisplayName, 'Lee');
  });
}
