import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/marmot/invite_transport_models.dart';

void main() {
  test('group invite packet round trips', () {
    const packet = GroupInvitePacket(
      publicKeyHex: 'pubkey-123',
      createdAt: 1710460800,
    );

    final encoded = packet.encode();
    final decoded = GroupInvitePacket.decode(encoded);

    expect(encoded, startsWith('nook://family-invite'));
    expect(decoded.publicKeyHex, 'pubkey-123');
    expect(decoded.createdAt, 1710460800);
    expect(decoded.toJson()['v'], 1);
  });
}
