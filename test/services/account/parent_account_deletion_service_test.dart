import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/account/parent_account_deletion_service.dart';

import '../../test_support/service_fakes.dart';

class _QueuedHttpInterceptor extends Interceptor {
  _QueuedHttpInterceptor(this._handler);

  final Response<dynamic> Function(RequestOptions options) _handler;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.resolve(_handler(options));
  }
}

void main() {
  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub1parent',
    nsec: 'nsec1parent',
    createdAtIso: '2026-03-19T00:00:00Z',
  );

  test(
    'deleteAccount fetches challenge, signs delete auth, and parses counts',
    () async {
      final dio = Dio();
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        _QueuedHttpInterceptor((options) {
          requests.add(options);
          if (options.method == 'POST' &&
              options.path == 'https://api.tubestr.app/auth/challenge') {
            return Response<Map<String, dynamic>>(
              requestOptions: options,
              data: const {'challenge': 'fresh-challenge'},
            );
          }
          if (options.method == 'DELETE' &&
              options.path == 'https://api.tubestr.app/account') {
            return Response<Map<String, dynamic>>(
              requestOptions: options,
              data: const {
                'npub': 'npub1parent',
                'deleted': {
                  'uploads': 2,
                  'entitlements': 1,
                  'usage': 1,
                  'users': 1,
                },
              },
            );
          }
          throw StateError(
            'Unexpected request: ${options.method} ${options.path}',
          );
        }),
      );
      final nostrService = FakeNostrService();
      final service = ParentAccountDeletionService(
        dio: dio,
        nostrService: nostrService,
      );

      final result = await service.deleteAccount(identity: identity);

      expect(requests, hasLength(2));
      expect(nostrService.lastCreatedSignedEventKind, 27235);
      expect(
        nostrService.lastCreatedSignedEventContent,
        'challenge=fresh-challenge&method=DELETE&url=%2Faccount',
      );
      expect(requests.last.headers['authorization'], startsWith('Nostr '));
      expect(result.npub, identity.npub);
      expect(result.deleted['uploads'], 2);
      expect(result.deleted['entitlements'], 1);
      expect(result.deleted['usage'], 1);
      expect(result.deleted['users'], 1);
    },
  );
}
