import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/constants.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/identity/identity_service.dart';
import 'package:mytube/services/mdk/mdk_service.dart';
import 'package:mytube/services/nostr/nostr_service.dart';
import 'package:mytube/services/offline/offline_action_store.dart';
import 'package:mytube/services/safety/report_coordinator.dart';
import 'package:mytube/services/safety/safety_hq_backend_client.dart';
import 'package:mytube/services/safety/safety_hq_service.dart';

const _runLiveSafetyHqTests = bool.fromEnvironment('RUN_LIVE_SAFETY_HQ_TESTS');
const _liveSafetyHqBaseUrl = String.fromEnvironment(
  'SAFETY_HQ_BASE_URL',
  defaultValue: AppConstants.safetyHqBackendDevBaseUrl,
);
const _opsPrivateKeyHex = String.fromEnvironment(
  'SAFETY_HQ_OPS_PRIVATE_KEY_HEX',
  defaultValue: '',
);

void main() {
  final originalHttpOverrides = HttpOverrides.current;
  setUpAll(() {
    HttpOverrides.global = null;
  });
  tearDownAll(() {
    HttpOverrides.global = originalHttpOverrides;
  });

  test(
    'live Safety HQ backend supports bootstrap, intake, read, and status update',
    () async {
      final tempRoot = await Directory.systemTemp.createTemp(
        'safety-hq-live-test-',
      );
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final dio = Dio();
      final backendClient = DioSafetyHqBackendClient(
        dio: dio,
        baseUrl: _liveSafetyHqBaseUrl,
      );
      final mdk = MdkService(supportDirectoryProvider: () async => tempRoot);
      final nostr = NdkNostrService(database);
      final safetyHqService = SafetyHqService(
        database: database,
        mdkService: mdk,
        nostrService: nostr,
        backendClient: backendClient,
      );
      final reportCoordinator = ReportCoordinator(
        database: database,
        mdkService: mdk,
        nostrService: nostr,
        offlineActionStore: OfflineActionStore(database: database),
        safetyHqService: safetyHqService,
      );
      addTearDown(() async {
        await database.close();
        await mdk.resetLocalState();
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
      });

      final identity = IdentityService.parseImportedIdentity(
        '1f1e1d1c1b1a191817161514131211100f0e0d0c0b0a09080706050403020100',
        createdAt: DateTime.utc(2026, 3, 19),
      );
      final opsIdentity = _opsPrivateKeyHex.trim().isEmpty
          ? identity
          : IdentityService.parseImportedIdentity(
              _opsPrivateKeyHex.trim(),
              createdAt: DateTime.utc(2026, 3, 19),
            );

      final healthResponse = await dio.get<Map<String, dynamic>>(
        '$_liveSafetyHqBaseUrl/health',
      );
      expect(healthResponse.data?['ok'], isTrue);
      final baselineMetrics = await _loadSafetyMetrics(
        dio,
        '$_liveSafetyHqBaseUrl/metrics',
      );

      final bootstrap = await backendClient.fetchBootstrap();
      expect(
        bootstrap.servicePublicKeyHex,
        AppConstants.safetyHqServicePublicKeyHex,
      );
      expect(bootstrap.relays, isNotEmpty);
      await nostr.saveRelayList(bootstrap.relays);

      await database.upsertProfile(
        id: 'live-child',
        name: 'Live Child',
        theme: 'campfire',
        avatarAsset: 'avatar.png',
      );

      final provisionedGroup = await safetyHqService.ensureProvisioned(
        identity: identity,
      );
      expect(provisionedGroup, isNotNull);
      final joinedMetrics = await _pollForWelcomeAndJoinMetrics(
        dio: dio,
        metricsUrl: '$_liveSafetyHqBaseUrl/metrics',
        baseline: baselineMetrics,
      );
      expect(
        joinedMetrics.welcomesReceived,
        greaterThanOrEqualTo(baselineMetrics.welcomesReceived + 1),
      );
      expect(
        joinedMetrics.groupsJoined,
        greaterThanOrEqualTo(baselineMetrics.groupsJoined + 1),
      );

      final reportResult = await reportCoordinator.submitReport(
        identity: identity,
        videoId: 'live-video-${DateTime.now().millisecondsSinceEpoch}',
        subjectChildId: 'live-child',
        blobHash: 'blob-${DateTime.now().microsecondsSinceEpoch}',
        reporterChildId: 'live-child',
        reason: 'unsafe',
        note: 'live backend integration test',
        level: 3,
        recipientType: 'safety_hq',
      );
      expect(reportResult.safetyPublished, isTrue);
      final advancedMetrics = await _pollForReportMetrics(
        dio: dio,
        metricsUrl: '$_liveSafetyHqBaseUrl/metrics',
        baseline: joinedMetrics,
      );
      expect(
        advancedMetrics.reportsReceived,
        greaterThanOrEqualTo(joinedMetrics.reportsReceived + 1),
      );

      final caseUri = Uri.parse(
        '$_liveSafetyHqBaseUrl/v1/safety-hq/cases/${reportResult.reportId}',
      );
      final caseBody = await _pollForCase(
        dio: dio,
        nostr: nostr,
        identity: opsIdentity,
        uri: caseUri,
      );
      expect(caseBody['report_id'], reportResult.reportId);
      expect(caseBody['status'], 'new');

      final listUri = Uri.parse('$_liveSafetyHqBaseUrl/v1/safety-hq/cases');
      final listResponse = await _authorizedGet<List<dynamic>>(
        dio: dio,
        nostr: nostr,
        identity: opsIdentity,
        uri: listUri,
      );
      expect(
        listResponse.data?.whereType<Map<String, dynamic>>().any(
          (item) => item['report_id'] == reportResult.reportId,
        ),
        isTrue,
      );

      final updateUri = Uri.parse(
        '$_liveSafetyHqBaseUrl/v1/safety-hq/cases/${reportResult.reportId}/status',
      );
      const updateBodyJson = '{"status":"triaged"}';
      final updateResponse = await _authorizedPost<dynamic>(
        dio: dio,
        nostr: nostr,
        identity: opsIdentity,
        uri: updateUri,
        bodyJson: updateBodyJson,
      );
      expect(updateResponse.statusCode, anyOf(equals(200), equals(204)));

      final updatedCaseBody = await _pollForCase(
        dio: dio,
        nostr: nostr,
        identity: opsIdentity,
        uri: caseUri,
        expectedStatus: 'triaged',
      );
      expect(updatedCaseBody['status'], 'triaged');
    },
    skip: !_runLiveSafetyHqTests,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

class _SafetyMetricsSnapshot {
  const _SafetyMetricsSnapshot({
    required this.welcomesReceived,
    required this.groupsJoined,
    required this.reportsReceived,
    required this.decryptFailures,
  });

  final int welcomesReceived;
  final int groupsJoined;
  final int reportsReceived;
  final int decryptFailures;
}

Future<String> _buildNip98Header({
  required NostrService nostr,
  required ParentIdentity identity,
  required String method,
  required Uri uri,
  String? bodyJson,
  bool useUrlSafeBase64 = false,
}) async {
  final tags = <List<String>>[
    ['u', uri.toString()],
    ['method', method.toUpperCase()],
    if (bodyJson != null)
      ['payload', sha256.convert(utf8.encode(bodyJson)).toString()],
  ];
  final eventJson = await nostr.createSignedEventJson(
    identity: identity,
    kind: 27235,
    tags: tags,
    content: '',
  );
  final bytes = utf8.encode(eventJson);
  final encoded = useUrlSafeBase64
      ? base64Url.encode(bytes).replaceAll('=', '')
      : base64.encode(bytes);
  return 'Nostr $encoded';
}

Future<Response<T>> _authorizedGet<T>({
  required Dio dio,
  required NostrService nostr,
  required ParentIdentity identity,
  required Uri uri,
}) async {
  try {
    final header = await _buildNip98Header(
      nostr: nostr,
      identity: identity,
      method: 'GET',
      uri: uri,
    );
    return await dio.get<T>(
      uri.toString(),
      options: Options(
        headers: {'authorization': header},
        responseType: ResponseType.json,
      ),
    );
  } on DioException catch (error) {
    if (error.response?.statusCode != 401) {
      rethrow;
    }
    final fallbackHeader = await _buildNip98Header(
      nostr: nostr,
      identity: identity,
      method: 'GET',
      uri: uri,
      useUrlSafeBase64: true,
    );
    return dio.get<T>(
      uri.toString(),
      options: Options(
        headers: {'authorization': fallbackHeader},
        responseType: ResponseType.json,
      ),
    );
  }
}

Future<Response<T>> _authorizedPost<T>({
  required Dio dio,
  required NostrService nostr,
  required ParentIdentity identity,
  required Uri uri,
  required String bodyJson,
}) async {
  try {
    final header = await _buildNip98Header(
      nostr: nostr,
      identity: identity,
      method: 'POST',
      uri: uri,
      bodyJson: bodyJson,
    );
    return await dio.post<T>(
      uri.toString(),
      data: bodyJson,
      options: Options(
        headers: {'authorization': header, 'content-type': 'application/json'},
        responseType: ResponseType.json,
      ),
    );
  } on DioException catch (error) {
    if (error.response?.statusCode != 401) {
      rethrow;
    }
    final fallbackHeader = await _buildNip98Header(
      nostr: nostr,
      identity: identity,
      method: 'POST',
      uri: uri,
      bodyJson: bodyJson,
      useUrlSafeBase64: true,
    );
    return dio.post<T>(
      uri.toString(),
      data: bodyJson,
      options: Options(
        headers: {
          'authorization': fallbackHeader,
          'content-type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );
  }
}

Future<_SafetyMetricsSnapshot> _loadSafetyMetrics(
  Dio dio,
  String metricsUrl,
) async {
  final response = await dio.get<Map<String, dynamic>>(metricsUrl);
  final safety = response.data?['safety_hq'];
  if (safety is! Map<String, dynamic>) {
    throw StateError('Unexpected metrics payload: ${response.data}');
  }
  return _SafetyMetricsSnapshot(
    welcomesReceived: (safety['welcomes_received'] as num?)?.toInt() ?? 0,
    groupsJoined: (safety['groups_joined'] as num?)?.toInt() ?? 0,
    reportsReceived: (safety['reports_received'] as num?)?.toInt() ?? 0,
    decryptFailures: (safety['decrypt_failures'] as num?)?.toInt() ?? 0,
  );
}

Future<_SafetyMetricsSnapshot> _pollForWelcomeAndJoinMetrics({
  required Dio dio,
  required String metricsUrl,
  required _SafetyMetricsSnapshot baseline,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    final snapshot = await _loadSafetyMetrics(dio, metricsUrl);
    final joinAdvanced =
        snapshot.welcomesReceived > baseline.welcomesReceived &&
        snapshot.groupsJoined > baseline.groupsJoined;
    if (joinAdvanced) {
      return snapshot;
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  final latest = await _loadSafetyMetrics(dio, metricsUrl);
  throw StateError(
    'Safety HQ metrics did not advance after welcome publish. '
    'baseline=(welcomes=${baseline.welcomesReceived}, groups=${baseline.groupsJoined}, reports=${baseline.reportsReceived}, decrypt_failures=${baseline.decryptFailures}) '
    'latest=(welcomes=${latest.welcomesReceived}, groups=${latest.groupsJoined}, reports=${latest.reportsReceived}, decrypt_failures=${latest.decryptFailures})',
  );
}

Future<_SafetyMetricsSnapshot> _pollForReportMetrics({
  required Dio dio,
  required String metricsUrl,
  required _SafetyMetricsSnapshot baseline,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    final snapshot = await _loadSafetyMetrics(dio, metricsUrl);
    if (snapshot.reportsReceived > baseline.reportsReceived) {
      return snapshot;
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  final latest = await _loadSafetyMetrics(dio, metricsUrl);
  throw StateError(
    'Safety HQ report metrics did not advance after report publish. '
    'baseline=(welcomes=${baseline.welcomesReceived}, groups=${baseline.groupsJoined}, reports=${baseline.reportsReceived}, decrypt_failures=${baseline.decryptFailures}) '
    'latest=(welcomes=${latest.welcomesReceived}, groups=${latest.groupsJoined}, reports=${latest.reportsReceived}, decrypt_failures=${latest.decryptFailures})',
  );
}

Future<Map<String, dynamic>> _pollForCase({
  required Dio dio,
  required NostrService nostr,
  required ParentIdentity identity,
  required Uri uri,
  String? expectedStatus,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    try {
      final response = await _authorizedGet<Map<String, dynamic>>(
        dio: dio,
        nostr: nostr,
        identity: identity,
        uri: uri,
      );
      final body = response.data;
      if (body != null &&
          (expectedStatus == null || body['status'] == expectedStatus)) {
        return body;
      }
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode != 404) {
        rethrow;
      }
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  throw StateError('Timed out waiting for Safety HQ case at ${uri.toString()}');
}
