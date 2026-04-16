import 'dart:async';
import 'dart:convert';

import 'package:ndk/entities.dart';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
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

class FamilyConnectionAlreadyPendingException implements Exception {
  const FamilyConnectionAlreadyPendingException({
    required this.memberPubkeyHex,
    required this.group,
  });

  final String memberPubkeyHex;
  final MdkGroupSummary group;

  @override
  String toString() =>
      'Connection already pending for $memberPubkeyHex in ${group.name}';
}

class FamilyConnectionService {
  static const _keyPackageResolveTimeout = Duration(seconds: 4);
  static const _pendingConnectionSettingPrefix =
      'family_pending_connection_v1:';

  FamilyConnectionService({
    required MdkService mdkService,
    required NostrService nostrService,
    AppDatabase? database,
    Future<String?> Function()? loadLocalDisplayName,
  }) : _mdkService = mdkService,
       _nostrService = nostrService,
       _database = database,
       _loadLocalDisplayName = loadLocalDisplayName;

  final MdkService _mdkService;
  final NostrService _nostrService;
  final AppDatabase? _database;
  final Future<String?> Function()? _loadLocalDisplayName;

  Future<FamilyInviteResult> createInvite({
    required ParentIdentity identity,
  }) async {
    final relays = _usableRelays(await _nostrService.loadRelayList());
    final inviterDisplayName = await _publishLocalProfileBestEffort(identity);
    final publishedKeyPackage = await _publishKeyPackageEvents(
      identity: identity,
      relays: relays,
      includeLegacyCompatibilityEvent: true,
    );

    final packet = GroupInvitePacket(
      publicKeyHex: identity.publicKeyHex,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      inviterDisplayName: inviterDisplayName,
    );

    return FamilyInviteResult(
      payload: packet.encode(),
      keyPackageEventJson: publishedKeyPackage.eventJson,
    );
  }

  Future<void> publishCurrentKeyPackage({
    required ParentIdentity identity,
  }) async {
    final relays = _usableRelays(await _nostrService.loadRelayList());
    await _publishLocalProfileBestEffort(identity);
    await _publishKeyPackageEvents(
      identity: identity,
      relays: relays,
      includeLegacyCompatibilityEvent: true,
    );
  }

  Future<FamilyConnectResult> connectFromInvite({
    required ParentIdentity identity,
    required String invitePayload,
  }) async {
    final packet = GroupInvitePacket.decode(invitePayload);
    final existingGroup = await _mdkService.findConnectedGroupForMember(
      memberPubkeyHex: packet.publicKeyHex,
    );
    if (existingGroup != null) {
      throw MdkAlreadyConnectedException(
        memberPubkeyHex: packet.publicKeyHex,
        group: existingGroup,
      );
    }

    final pendingGroup = await _loadPendingConnectionGroup(packet.publicKeyHex);
    if (pendingGroup != null) {
      throw FamilyConnectionAlreadyPendingException(
        memberPubkeyHex: packet.publicKeyHex,
        group: pendingGroup,
      );
    }

    final relays = _usableRelays(await _nostrService.loadRelayList());
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
    if (publishedWelcomeCount > 0) {
      await _savePendingConnectionGroup(packet.publicKeyHex, result.group);
    }

    return FamilyConnectResult(
      group: result.group,
      publishedWelcomeCount: publishedWelcomeCount,
    );
  }

  Future<MdkGroupSummary?> _loadPendingConnectionGroup(
    String memberPubkeyHex,
  ) async {
    final raw = await _database?.getSetting(
      _pendingConnectionSettingKey(memberPubkeyHex),
    );
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final adminPubkeys = decoded['admin_pubkeys_hex'];
      return MdkGroupSummary(
        mlsGroupIdHex: decoded['mls_group_id_hex']?.toString() ?? '',
        nostrGroupIdHex: decoded['nostr_group_id_hex']?.toString() ?? '',
        name: decoded['name']?.toString() ?? '',
        description: decoded['description']?.toString() ?? '',
        memberCount: (decoded['member_count'] as num?)?.toInt() ?? 0,
        adminPubkeysHex: adminPubkeys is List
            ? adminPubkeys.map((value) => value.toString()).toList()
            : const [],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePendingConnectionGroup(
    String memberPubkeyHex,
    MdkGroupSummary group,
  ) async {
    await _database?.putSetting(
      _pendingConnectionSettingKey(memberPubkeyHex),
      jsonEncode({
        'mls_group_id_hex': group.mlsGroupIdHex,
        'nostr_group_id_hex': group.nostrGroupIdHex,
        'name': group.name,
        'description': group.description,
        'member_count': group.memberCount,
        'admin_pubkeys_hex': group.adminPubkeysHex,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  String _pendingConnectionSettingKey(String memberPubkeyHex) {
    return '$_pendingConnectionSettingPrefix${memberPubkeyHex.toLowerCase()}';
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

  Future<String?> _publishLocalProfileBestEffort(
    ParentIdentity identity,
  ) async {
    final displayName = (await _loadLocalDisplayName?.call())?.trim();
    if (displayName == null || displayName.isEmpty) {
      return displayName;
    }
    try {
      await _nostrService.publishParentProfile(
        identity: identity,
        displayName: displayName,
      );
    } catch (_) {
      // Best effort only. Invites and groups still carry the local name.
    }
    return displayName;
  }

  Future<_PublishedKeyPackage> _publishKeyPackageEvents({
    required ParentIdentity identity,
    required List<String> relays,
    required bool includeLegacyCompatibilityEvent,
  }) async {
    await _publishKeyPackageRelayList(identity: identity, relays: relays);

    final preview = await _mdkService.createKeyPackageEvent(
      publicKeyHex: identity.publicKeyHex,
      relays: relays,
    );
    final currentTagsJson = preview.tags30443Json;
    final legacyTags = _legacyKeyPackageTags(_decodeTagsJson(currentTagsJson));
    final signedEventJson = await _nostrService.createSignedKeyPackageEventJson(
      identity: identity,
      content: preview.content,
      tagsJson: currentTagsJson,
    );

    // Publish as an addressable key package so current clients can discover
    // this parent even after older legacy packages are still on relays.
    await _nostrService.publishSignedEventJson(
      identity: identity,
      eventJson: signedEventJson,
      relays: relays,
    );

    if (includeLegacyCompatibilityEvent) {
      final legacyEventJson = await _nostrService.createSignedEventJson(
        identity: identity,
        kind: MarmotKinds.legacyKeyPackage,
        tags: legacyTags,
        content: preview.content,
      );
      await _nostrService.publishSignedEventJson(
        identity: identity,
        eventJson: legacyEventJson,
        relays: relays,
      );
    }

    return _PublishedKeyPackage(eventJson: signedEventJson);
  }

  Future<void> _publishKeyPackageRelayList({
    required ParentIdentity identity,
    required List<String> relays,
  }) async {
    try {
      final discoveryRelays = _mergeRelayLists(
        relays,
        AppConstants.defaultRelays,
      );
      final relayListEventJson = await _nostrService.createSignedEventJson(
        identity: identity,
        kind: MarmotKinds.keyPackageRelays,
        tags: relays
            .map((relay) => <String>['relay', relay])
            .toList(growable: false),
        content: '',
      );
      await _nostrService.publishSignedEventJson(
        identity: identity,
        eventJson: relayListEventJson,
        relays: discoveryRelays,
      );
    } catch (_) {
      // Discovery helps other clients find the KeyPackage relays, but invite
      // creation should still proceed if this announcement has a transient
      // relay failure.
    }
  }

  List<String> _mergeRelayLists(List<String> primary, List<String> secondary) {
    final seen = <String>{};
    final merged = <String>[];
    for (final relay in [...primary, ...secondary]) {
      if (seen.add(relay)) {
        merged.add(relay);
      }
    }
    return merged;
  }

  List<String> _usableRelays(List<String> relays) {
    final usable = <String>[];
    final seen = <String>{};
    for (final relay in relays) {
      final trimmed = relay.trim();
      final uri = Uri.tryParse(trimmed);
      if (uri == null ||
          uri.host.isEmpty ||
          (uri.scheme != 'ws' && uri.scheme != 'wss')) {
        continue;
      }
      if (seen.add(trimmed)) {
        usable.add(trimmed);
      }
    }
    return usable.isEmpty ? AppConstants.defaultRelays : usable;
  }

  List<List<String>> _legacyKeyPackageTags(List<List<String>> tags) {
    return tags
        .where((tag) => tag.isEmpty || tag.first != 'd')
        .map((tag) => List<String>.from(tag, growable: false))
        .toList(growable: false);
  }

  List<List<String>> _decodeTagsJson(String tagsJson) {
    final decoded = jsonDecode(tagsJson);
    if (decoded is! List) {
      throw const FormatException('Key package tags must be a JSON list');
    }
    return decoded
        .map((row) {
          if (row is! List) {
            throw const FormatException('Key package tag must be a JSON list');
          }
          return row.map((value) => value.toString()).toList(growable: false);
        })
        .toList(growable: false);
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
    final eventId = packet.keyPackageEventId;
    if (eventId != null && eventId.isNotEmpty) {
      return _resolveKeyPackageById(
        eventId: eventId,
        publicKeyHex: packet.publicKeyHex,
        relays: relays,
      );
    }
    return _resolveKeyPackageByAuthor(
      publicKeyHex: packet.publicKeyHex,
      relays: relays,
    );
  }

  /// Fast path: we know the exact event ID, resolve on first match.
  Future<List<String>> _resolveKeyPackageById({
    required String eventId,
    required String publicKeyHex,
    required List<String> relays,
  }) async {
    final subscriptionId =
        'mytube.keypkg.${publicKeyHex.substring(0, publicKeyHex.length.clamp(0, 16))}.${DateTime.now().microsecondsSinceEpoch}';
    final response = await _nostrService.subscribe(
      subscriptionId: subscriptionId,
      relays: relays,
      filter: Filter(
        ids: [eventId],
        authors: [publicKeyHex],
        kinds: MarmotKinds.keyPackageKinds,
        limit: 1,
      ),
    );

    final completer = Completer<String>();
    late final StreamSubscription<Nip01Event> subscription;
    subscription = response.stream.listen(
      (event) {
        if (event.pubKey != publicKeyHex ||
            !MarmotKinds.keyPackageKinds.contains(event.kind) ||
            event.id != eventId) {
          return;
        }
        if (!completer.isCompleted) {
          completer.complete(Nip01EventModel.fromEntity(event).toJsonString());
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );

    try {
      final eventJson = await completer.future.timeout(
        _keyPackageResolveTimeout,
      );
      return [eventJson];
    } on TimeoutException {
      throw StateError(
        'No key packages found for this invite yet. '
        'Ask the other parent to open Family Spaces or create a new invite.',
      );
    } finally {
      await subscription.cancel();
      await _nostrService.unsubscribe(subscriptionId);
    }
  }

  /// Legacy fallback: no event ID, collect candidates and pick the newest.
  Future<List<String>> _resolveKeyPackageByAuthor({
    required String publicKeyHex,
    required List<String> relays,
  }) async {
    final events = await _nostrService.queryEvents(
      relays: relays,
      timeout: _keyPackageResolveTimeout,
      filter: Filter(
        authors: [publicKeyHex],
        kinds: MarmotKinds.keyPackageKinds,
        limit: 20,
      ),
    );
    if (events.isEmpty) {
      throw StateError(
        'No key packages found for this invite yet. '
        'Ask the other parent to open Family Spaces or create a new invite.',
      );
    }
    final sorted = events.toList()
      ..sort((a, b) {
        final kindPriority =
            (b.kind == MarmotKinds.keyPackage ? 1 : 0) -
            (a.kind == MarmotKinds.keyPackage ? 1 : 0);
        if (kindPriority != 0) {
          return kindPriority;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    return [Nip01EventModel.fromEntity(sorted.first).toJsonString()];
  }
}

class _PublishedKeyPackage {
  const _PublishedKeyPackage({required this.eventJson});

  final String eventJson;
}
