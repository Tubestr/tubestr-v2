import 'dart:convert';

import 'package:crypto/crypto.dart';

String buildRemoteShareId({
  required String senderParentKey,
  required String mlsGroupId,
  required String videoId,
}) {
  final seed = '$senderParentKey|$mlsGroupId|$videoId';
  return sha256.convert(utf8.encode(seed)).toString();
}
