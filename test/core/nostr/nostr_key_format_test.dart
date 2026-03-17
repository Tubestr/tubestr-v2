import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/nostr/nostr_key_format.dart';

void main() {
  test('encodeNpub converts a hex public key to bech32 npub', () {
    expect(
      encodeNpub(
        '7e7e9c42a91bfef19fa2c8e8bb350e534955a89bb79d4f7a1c8d4c43b6f3d8b7',
      ),
      startsWith('npub1'),
    );
  });

  test('formatCompactPublicKeyLabel prefers compact npub output', () {
    final formatted = formatCompactPublicKeyLabel(
      '7e7e9c42a91bfef19fa2c8e8bb350e534955a89bb79d4f7a1c8d4c43b6f3d8b7',
    );
    expect(formatted, startsWith('npub1'));
    expect(formatted, contains('…'));
  });
}
