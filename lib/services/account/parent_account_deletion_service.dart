import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/models/parent_identity.dart';
import '../nostr/nostr_service.dart';

class ParentAccountDeletionResult {
  const ParentAccountDeletionResult({
    required this.npub,
    required this.deleted,
  });

  final String npub;
  final Map<String, int> deleted;
}

class ParentAccountDeletionService {
  ParentAccountDeletionService({
    required Dio dio,
    required NostrService nostrService,
    String? apiBaseUrl,
  }) : _dio = dio,
       _nostrService = nostrService,
       _apiBaseUrl = apiBaseUrl ?? defaultApiBaseUrl;

  final Dio _dio;
  final NostrService _nostrService;
  final String _apiBaseUrl;

  static const String defaultApiBaseUrl = String.fromEnvironment(
    'TUBESTR_API_URL',
    defaultValue: 'https://api.tubestr.app',
  );

  Future<ParentAccountDeletionResult> deleteAccount({
    required ParentIdentity identity,
  }) async {
    final baseUrl = _apiBaseUrl.trim();
    if (baseUrl.isEmpty) {
      throw const FormatException(
        'This build is missing the Tubestr account API URL.',
      );
    }

    final challengeResponse = await _dio.post<Map<String, dynamic>>(
      '$baseUrl/auth/challenge',
    );
    final challenge =
        challengeResponse.data?['challenge']?.toString().trim() ?? '';
    if (challenge.isEmpty) {
      throw const FormatException(
        'Tubestr account deletion could not get a fresh auth challenge.',
      );
    }

    final signedEventJson = await _nostrService.createSignedEventJson(
      identity: identity,
      kind: 27235,
      tags: const [],
      content: Uri(queryParameters: const <String, String>{})
          .replace(
            queryParameters: {
              'challenge': challenge,
              'method': 'DELETE',
              'url': '/account',
            },
          )
          .query,
    );
    final encodedEvent = base64Encode(utf8.encode(signedEventJson));

    final response = await _dio.delete<Map<String, dynamic>>(
      '$baseUrl/account',
      options: Options(headers: {'authorization': 'Nostr $encodedEvent'}),
    );

    final data = response.data ?? const <String, dynamic>{};
    final deletedRaw = data['deleted'];
    final deleted = <String, int>{};
    if (deletedRaw is Map) {
      for (final entry in deletedRaw.entries) {
        deleted[entry.key.toString()] = switch (entry.value) {
          final int count => count,
          final num count => count.toInt(),
          _ => 0,
        };
      }
    }

    return ParentAccountDeletionResult(
      npub: data['npub']?.toString() ?? identity.npub,
      deleted: deleted,
    );
  }
}
