import 'dart:typed_data';

import 'package:bech32/bech32.dart';

String? encodeNpub(String publicKeyHex) {
  final sanitized = publicKeyHex.trim().toLowerCase();
  if (sanitized.isEmpty || sanitized.length.isOdd) {
    return null;
  }

  try {
    final bytes = Uint8List.fromList([
      for (var i = 0; i < sanitized.length; i += 2)
        int.parse(sanitized.substring(i, i + 2), radix: 16),
    ]);
    final words = _convertBits(bytes, from: 8, to: 5, pad: true);
    return bech32.encode(Bech32('npub', words), 1000);
  } catch (_) {
    return null;
  }
}

String formatPublicKeyLabel(String publicKeyHex) {
  return encodeNpub(publicKeyHex) ?? publicKeyHex;
}

String formatCompactPublicKeyLabel(String publicKeyHex) {
  final display = formatPublicKeyLabel(publicKeyHex);
  if (display.length <= 20) {
    return display;
  }
  return '${display.substring(0, 10)}…${display.substring(display.length - 8)}';
}

List<int> _convertBits(
  List<int> data, {
  required int from,
  required int to,
  required bool pad,
}) {
  var acc = 0;
  var bits = 0;
  final result = <int>[];
  final maxValue = (1 << to) - 1;

  for (final value in data) {
    if (value < 0 || value >> from != 0) {
      throw const FormatException('Invalid bit group');
    }
    acc = (acc << from) | value;
    bits += from;
    while (bits >= to) {
      bits -= to;
      result.add((acc >> bits) & maxValue);
    }
  }

  if (pad) {
    if (bits > 0) {
      result.add((acc << (to - bits)) & maxValue);
    }
  } else if (bits >= from || ((acc << (to - bits)) & maxValue) != 0) {
    throw const FormatException('Invalid padding');
  }

  return result;
}
