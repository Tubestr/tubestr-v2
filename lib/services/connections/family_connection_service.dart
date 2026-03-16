import 'dart:async';

import 'package:ndk/entities.dart';

import '../../core/constants.dart';
import '../../domain/marmot/invite_transport_models.dart';
import '../../domain/models/parent_identity.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';

class FamilyInviteResult {
  const FamilyInviteResult({
    required this.payload,
    required this.keyPackageEventJson,
  });

  final String payload;
  final String keyPackageEventJson;
}

class FamilyConnectResult {
  const FamilyConnectResult({
    required this.group,
    required this.publishedWelcomeCount,
  });

  final MdkGroupSummary group;
  final int publishedWelcomeCount;
}

class FamilyConnectionService {
  static const _keyPackageQueryTimeout = Duration(seconds: 2);
  static const _keyPackagePollWindow = Duration(seconds: 5);
  static const _keyPackagePollInterval = Duration(milliseconds: 250);

  FamilyConnectionService({
    required MdkService mdkService,
    required NostrService nostrService,
  })  : _mdkService = mdkService,
        _nostrService = nostrService;

  final MdkService _mdkService;
  final NostrService _nostrService;

  Future<FamilyInviteResult> createInvite({
    required ParentIdentity identity,
  }) async {
    final relays = await _nostrService.loadRelayList();
    final preview = await _mdkService.createKeyPackageEvent(
      publicKeyHex: identity.publicKeyHex,
      relays: relays,
    );
    final signedEventJson = await _nostrService.createSignedKeyPackageEventJson(
      identity: identity,
      content: preview.content,
      tagsJson: preview.tagsJson,
    );

    // Publish before showing the invite so scanners can discover the package
    // even if the invite is tiny and the scan happens a moment later.
    await _nostrService.publishSignedEventJson(
      identity: identity,
      eventJson: signedEventJson,
      relays: relays,
    );

    final packet = GroupInvitePacket(
      publicKeyHex: identity.publicKeyHex,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    return FamilyInviteResult(
      payload: packet.encode(),
      keyPackageEventJson: signedEventJson,
    );
  }

  Future<FamilyConnectResult> connectFromInvite({
    required ParentIdentity identity,
    required String invitePayload,
  }) async {
    final packet = GroupInvitePacket.decode(invitePayload);
    final relays = await _nostrService.loadRelayList();
    final groupName =
        'Family Space ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    final keyPackageEventsJson = await _resolveKeyPackageEvents(
      packet: packet,
      relays: relays,
    );
    final result = await _mdkService.createGroupWithWelcomes(
      creatorPublicKeyHex: identity.publicKeyHex,
      name: groupName,
      description: 'Created from scanned invite',
      relays: relays,
      memberKeyPackageEventJsons: keyPackageEventsJson,
    );

    var publishedWelcomeCount = 0;
    for (final rumorJson in result.welcomeRumorJsons) {
      await _nostrService.publishGiftWrappedRumor(
        identity: identity,
        rumorEventJson: rumorJson,
        recipientPublicKeyHex: packet.publicKeyHex,
        relays: relays,
      );
      publishedWelcomeCount += 1;
    }

    return FamilyConnectResult(
      group: result.group,
      publishedWelcomeCount: publishedWelcomeCount,
    );
  }

  Future<List<String>> _resolveKeyPackageEvents({
    required GroupInvitePacket packet,
    required List<String> relays,
  }) async {
    final queried = await _queryKeyPackages(
      publicKeyHex: packet.publicKeyHex,
      relays: relays,
    );
    if (queried.isNotEmpty) {
      return queried;
    }

    final polled = await _pollForKeyPackages(
      publicKeyHex: packet.publicKeyHex,
      relays: relays,
    );
    if (polled.isNotEmpty) {
      return polled;
    }

    final finalAttempt = await _queryKeyPackages(
      publicKeyHex: packet.publicKeyHex,
      relays: relays,
      timeout: const Duration(seconds: 1),
    );
    if (finalAttempt.isNotEmpty) {
      return finalAttempt;
    }

    throw StateError(
      'No key packages found for this invite yet. Ask the other parent to refresh the invite and try again.',
    );
  }

  Future<List<String>> _queryKeyPackages({
    required String publicKeyHex,
    required List<String> relays,
    Duration timeout = _keyPackageQueryTimeout,
  }) async {
    final events = await _nostrService.queryEvents(
      relays: relays,
      timeout: timeout,
      filter: Filter(
        authors: [publicKeyHex],
        kinds: [MarmotKinds.keyPackage],
        limit: 20,
      ),
    );
    return _dedupeEventJson(events);
  }

  Future<List<String>> _pollForKeyPackages({
    required String publicKeyHex,
    required List<String> relays,
  }) async {
    final subscriptionId =
        'mytube.keypkg.${publicKeyHex.substring(0, publicKeyHex.length.clamp(0, 16))}.${DateTime.now().microsecondsSinceEpoch}';
    final response = await _nostrService.subscribe(
      subscriptionId: subscriptionId,
      relays: relays,
      filter: Filter(
        authors: [publicKeyHex],
        kinds: [MarmotKinds.keyPackage],
        limit: 20,
      ),
    );

    final collectedById = <String, Nip01Event>{};
    late final StreamSubscription<Nip01Event> subscription;
    subscription = response.stream.listen((event) {
      if (event.pubKey != publicKeyHex ||
          event.kind != MarmotKinds.keyPackage) {
        return;
      }
      collectedById[event.id] = event;
    });

    try {
      final iterations =
          _keyPackagePollWindow.inMilliseconds ~/ _keyPackagePollInterval.inMilliseconds;
      for (var i = 0; i < iterations; i += 1) {
        await Future<void>.delayed(_keyPackagePollInterval);
        if (collectedById.isNotEmpty) {
          break;
        }
      }
    } finally {
      await subscription.cancel();
      await _nostrService.unsubscribe(subscriptionId);
    }

    return _dedupeEventJson(collectedById.values);
  }

  List<String> _dedupeEventJson(Iterable<Nip01Event> events) {
    final byId = <String, String>{};
    for (final event in events) {
      byId[event.id] = Nip01EventModel.fromEntity(event).toJsonString();
    }
    return byId.values.toList(growable: false);
  }
}
