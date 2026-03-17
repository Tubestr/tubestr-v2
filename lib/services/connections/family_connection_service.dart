import 'dart:async';
import 'dart:convert';

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
    Future<String?> Function()? loadLocalDisplayName,
  }) : _mdkService = mdkService,
       _nostrService = nostrService,
       _loadLocalDisplayName = loadLocalDisplayName;

  final MdkService _mdkService;
  final NostrService _nostrService;
  final Future<String?> Function()? _loadLocalDisplayName;

  Future<FamilyInviteResult> createInvite({
    required ParentIdentity identity,
  }) async {
    final relays = await _nostrService.loadRelayList();
    final inviterDisplayName = (await _loadLocalDisplayName?.call())?.trim();
    if (inviterDisplayName != null && inviterDisplayName.isNotEmpty) {
      try {
        await _nostrService.publishParentProfile(
          identity: identity,
          displayName: inviterDisplayName,
        );
      } catch (_) {
        // Best effort only. The invite packet also carries the local name.
      }
    }
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
    final keyPackageEventId = await _nostrService.publishSignedEventJson(
      identity: identity,
      eventJson: signedEventJson,
      relays: relays,
    );

    final packet = GroupInvitePacket(
      publicKeyHex: identity.publicKeyHex,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      keyPackageEventId: keyPackageEventId,
      inviterDisplayName: inviterDisplayName,
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
    final inviterName = packet.inviterDisplayName?.trim().isNotEmpty == true
        ? packet.inviterDisplayName!.trim()
        : await _resolveInviterDisplayName(
            publicKeyHex: packet.publicKeyHex,
            relays: relays,
          );
    final inviteeName = (await _loadLocalDisplayName?.call())?.trim();
    if (inviteeName != null && inviteeName.isNotEmpty) {
      try {
        await _nostrService.publishParentProfile(
          identity: identity,
          displayName: inviteeName,
        );
      } catch (_) {
        // Best effort only. The group name still carries the local name.
      }
    }
    final groupName = _buildGroupName(
      inviterName: inviterName,
      inviteeName: inviteeName,
    );
    final description = _buildGroupDescription(
      inviterName: inviterName,
      inviteeName: inviteeName,
    );
    final keyPackageEventsJson = await _resolveKeyPackageEvents(
      packet: packet,
      relays: relays,
    );
    final result = await _mdkService.createGroupWithWelcomes(
      creatorPublicKeyHex: identity.publicKeyHex,
      name: groupName,
      description: description,
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

  Future<String?> _resolveInviterDisplayName({
    required String publicKeyHex,
    required List<String> relays,
  }) async {
    final events = await _nostrService.queryEvents(
      filter: Filter(authors: [publicKeyHex], kinds: const [0], limit: 1),
      relays: relays,
      timeout: const Duration(seconds: 2),
    );
    if (events.isEmpty) {
      return null;
    }
    final content = jsonDecode(events.first.content);
    if (content is! Map<String, dynamic>) {
      return null;
    }
    final displayName =
        content['display_name']?.toString().trim() ??
        content['displayName']?.toString().trim() ??
        content['name']?.toString().trim();
    if (displayName == null || displayName.isEmpty) {
      return null;
    }
    return displayName;
  }

  String _buildGroupName({String? inviterName, String? inviteeName}) {
    final names = <String>[];
    for (final name in [inviterName, inviteeName]) {
      final trimmed = name?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        continue;
      }
      if (!names.any(
        (existing) => existing.toLowerCase() == trimmed.toLowerCase(),
      )) {
        names.add(trimmed);
      }
    }

    if (names.length >= 2) {
      return '${names[0]} & ${names[1]}';
    }
    if (names.length == 1) {
      final name = names.first;
      if (name.toLowerCase().contains('family')) {
        return name;
      }
      return '$name Family';
    }
    return 'Family Space';
  }

  String _buildGroupDescription({String? inviterName, String? inviteeName}) {
    final groupName = _buildGroupName(
      inviterName: inviterName,
      inviteeName: inviteeName,
    );
    if (groupName == 'Family Space') {
      return 'Created from scanned invite';
    }
    final inviter = inviterName?.trim();
    final invitee = inviteeName?.trim();
    if (inviter != null &&
        inviter.isNotEmpty &&
        invitee != null &&
        invitee.isNotEmpty) {
      return 'Connected $inviter with $invitee';
    }
    if (inviter != null && inviter.isNotEmpty) {
      return 'Connected with $inviter';
    }
    if (invitee != null && invitee.isNotEmpty) {
      return 'Connected with $invitee';
    }
    return 'Created from scanned invite';
  }

  Future<List<String>> _resolveKeyPackageEvents({
    required GroupInvitePacket packet,
    required List<String> relays,
  }) async {
    final queried = await _queryKeyPackages(
      packet: packet,
      publicKeyHex: packet.publicKeyHex,
      relays: relays,
    );
    if (queried.isNotEmpty) {
      return queried;
    }

    final polled = await _pollForKeyPackages(
      packet: packet,
      publicKeyHex: packet.publicKeyHex,
      relays: relays,
    );
    if (polled.isNotEmpty) {
      return polled;
    }

    final finalAttempt = await _queryKeyPackages(
      packet: packet,
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
    required GroupInvitePacket packet,
    required String publicKeyHex,
    required List<String> relays,
    Duration timeout = _keyPackageQueryTimeout,
  }) async {
    final events = await _nostrService.queryEvents(
      relays: relays,
      timeout: timeout,
      filter: Filter(
        ids:
            packet.keyPackageEventId == null ||
                packet.keyPackageEventId!.isEmpty
            ? null
            : [packet.keyPackageEventId!],
        authors: [publicKeyHex],
        kinds: [MarmotKinds.keyPackage],
        limit: 20,
      ),
    );
    return _dedupeEventJson(events);
  }

  Future<List<String>> _pollForKeyPackages({
    required GroupInvitePacket packet,
    required String publicKeyHex,
    required List<String> relays,
  }) async {
    final subscriptionId =
        'mytube.keypkg.${publicKeyHex.substring(0, publicKeyHex.length.clamp(0, 16))}.${DateTime.now().microsecondsSinceEpoch}';
    final response = await _nostrService.subscribe(
      subscriptionId: subscriptionId,
      relays: relays,
      filter: Filter(
        ids:
            packet.keyPackageEventId == null ||
                packet.keyPackageEventId!.isEmpty
            ? null
            : [packet.keyPackageEventId!],
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
          _keyPackagePollWindow.inMilliseconds ~/
          _keyPackagePollInterval.inMilliseconds;
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
