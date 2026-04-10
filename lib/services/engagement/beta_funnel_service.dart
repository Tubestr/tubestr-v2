import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/app_database.dart';
import '../identity/identity_service.dart';
import '../nostr/nostr_service.dart';

class BetaFunnelService {
  BetaFunnelService({
    required Dio dio,
    required NostrService nostrService,
    required IdentityService identityService,
    required AppDatabase database,
    String? apiBaseUrl,
    String? sessionId,
  }) : _dio = dio,
       _nostrService = nostrService,
       _identityService = identityService,
       _database = database,
       _apiBaseUrl = apiBaseUrl ?? defaultApiBaseUrl,
       _sessionId = sessionId ?? const Uuid().v4();

  static const String defaultApiBaseUrl = String.fromEnvironment(
    'TUBESTR_API_URL',
    defaultValue: 'https://api.tubestr.app',
  );
  static const String _firstPrivateShareTrackedKey =
      'beta_funnel:first_private_share_sent';

  final Dio _dio;
  final NostrService _nostrService;
  final IdentityService _identityService;
  final AppDatabase _database;
  final String _apiBaseUrl;
  final String _sessionId;

  Future<void> trackAppStarted() {
    return _postEvent(eventName: 'beta_app_started');
  }

  Future<void> trackParentOnboardingCompleted({required String mode}) {
    return _postEvent(
      eventName: 'beta_parent_onboarding_completed',
      context: {'mode': mode},
    );
  }

  Future<void> trackChildProfileCreated({required String surface}) {
    return _postEvent(
      eventName: 'beta_child_profile_created',
      context: {'surface': surface},
    );
  }

  Future<void> trackFamilyInviteCreated() {
    return _postEvent(eventName: 'beta_family_invite_created');
  }

  Future<void> trackFamilyInviteConnected({
    required int publishedWelcomeCount,
  }) {
    return _postEvent(
      eventName: 'beta_family_invite_connected',
      context: {'published_welcome_count': publishedWelcomeCount},
    );
  }

  Future<void> trackFirstPrivateShareSent({
    required int sharedGroupCount,
    required int queuedGroupCount,
  }) async {
    final alreadyTracked = await _database.getSetting(
      _firstPrivateShareTrackedKey,
    );
    if (alreadyTracked == 'true') {
      return;
    }

    final recorded = await _postEvent(
      eventName: 'beta_first_private_share_sent',
      context: {
        'shared_group_count': sharedGroupCount,
        'queued_group_count': queuedGroupCount,
      },
    );
    if (recorded) {
      await _database.putSetting(_firstPrivateShareTrackedKey, 'true');
    }
  }

  Future<bool> _postEvent({
    required String eventName,
    Map<String, Object?>? context,
  }) async {
    final baseUrl = _apiBaseUrl.trim();
    if (baseUrl.isEmpty) {
      return false;
    }

    try {
      final headers = await _buildAuthHeaders(
        method: 'POST',
        path: '/beta/funnel-events',
      );
      await _dio.post<Map<String, dynamic>>(
        '$baseUrl/beta/funnel-events',
        data: {
          'source': 'app',
          'event_name': eventName,
          'platform': _platformName,
          'session_id': _sessionId,
          if (context != null && context.isNotEmpty) 'context': context,
        },
        options: Options(headers: headers),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, String>> _buildAuthHeaders({
    required String method,
    required String path,
  }) async {
    final identity = await _identityService.loadIdentity();
    if (identity == null) {
      return const <String, String>{};
    }

    final baseUrl = _apiBaseUrl.trim();
    if (baseUrl.isEmpty) {
      return const <String, String>{};
    }

    final challengeResponse = await _dio.post<Map<String, dynamic>>(
      '$baseUrl/auth/challenge',
    );
    final challenge =
        challengeResponse.data?['challenge']?.toString().trim() ?? '';
    if (challenge.isEmpty) {
      return const <String, String>{};
    }

    final signedEventJson = await _nostrService.createSignedEventJson(
      identity: identity,
      kind: 27235,
      tags: const [],
      content: Uri(
        queryParameters: {
          'challenge': challenge,
          'method': method,
          'url': path,
        },
      ).query,
    );
    return <String, String>{
      'authorization': 'Nostr ${base64Encode(utf8.encode(signedEventJson))}',
    };
  }

  String get _platformName {
    if (kIsWeb) {
      return 'web';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
