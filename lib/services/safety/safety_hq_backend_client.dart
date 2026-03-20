import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants.dart';

class SafetyHqBootstrapData {
  const SafetyHqBootstrapData({
    required this.servicePublicKeyHex,
    required this.signedKeyPackageEventJson,
    required this.keyPackageEventId,
    required this.relays,
    required this.version,
    required this.generatedAt,
  });

  final String servicePublicKeyHex;
  final String signedKeyPackageEventJson;
  final String keyPackageEventId;
  final List<String> relays;
  final String version;
  final DateTime? generatedAt;

  factory SafetyHqBootstrapData.fromJson(Map<String, dynamic> json) {
    final rawRelays = json['relays'];
    return SafetyHqBootstrapData(
      servicePublicKeyHex:
          json['service_public_key_hex']?.toString().trim().toLowerCase() ?? '',
      signedKeyPackageEventJson:
          json['signed_key_package_event_json']?.toString() ?? '',
      keyPackageEventId: json['key_package_event_id']?.toString() ?? '',
      relays: rawRelays is List
          ? rawRelays
                .map((relay) => relay.toString().trim())
                .where((relay) => relay.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
      version: json['version']?.toString() ?? '',
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? ''),
    );
  }
}

abstract class SafetyHqBackendClient {
  Future<SafetyHqBootstrapData> fetchBootstrap();
}

class DioSafetyHqBackendClient implements SafetyHqBackendClient {
  DioSafetyHqBackendClient({required Dio dio, String? baseUrl})
    : _dio = dio,
      _baseUrl =
          (baseUrl ??
                  (kReleaseMode
                      ? AppConstants.safetyHqBackendProdBaseUrl
                      : AppConstants.safetyHqBackendDevBaseUrl))
              .trim();

  final Dio _dio;
  final String _baseUrl;

  @override
  Future<SafetyHqBootstrapData> fetchBootstrap() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/v1/safety-hq/bootstrap',
    );
    final payload = response.data;
    if (payload == null) {
      throw const FormatException('Safety HQ bootstrap response was empty.');
    }

    final bootstrap = SafetyHqBootstrapData.fromJson(payload);
    if (bootstrap.servicePublicKeyHex.isEmpty) {
      throw const FormatException(
        'Safety HQ bootstrap response did not include service_public_key_hex.',
      );
    }
    if (bootstrap.signedKeyPackageEventJson.isEmpty) {
      throw const FormatException(
        'Safety HQ bootstrap response did not include signed_key_package_event_json.',
      );
    }
    return bootstrap;
  }
}
