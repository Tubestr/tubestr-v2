import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/services/mdk/mdk_service.dart';

import '../../test_support/service_fakes.dart';

void main() {
  const existingGroup = MdkGroupSummary(
    mlsGroupIdHex: 'existing-group',
    nostrGroupIdHex: 'existing-nostr-group',
    name: 'Lee & Noah',
    description: 'Connected Lee with Noah',
    memberCount: 2,
    adminPubkeysHex: ['local-parent'],
  );

  const duplicateWelcome = MdkPendingWelcome(
    welcomeEventIdHex: 'welcome-event',
    wrapperEventIdHex: 'wrapper-event',
    mlsGroupIdHex: 'new-group',
    nostrGroupIdHex: 'new-nostr-group',
    groupName: 'Duplicate Family',
    groupDescription: 'Duplicate welcome',
    memberCount: 2,
    welcomerPubkeyHex: 'remote-parent',
    relays: ['wss://relay.example'],
    state: 'pending',
  );

  test('findConnectedGroupForMember matches active group membership', () async {
    final service = _DedupeOnlyMdkService(
      groups: const [existingGroup],
      membersByGroup: const {
        'existing-group': ['local-parent', 'remote-parent'],
      },
    );

    final group = await service.findConnectedGroupForMember(
      memberPubkeyHex: 'remote-parent',
    );

    expect(group, existingGroup);
  });

  test(
    'acceptPendingWelcome stops before bridge accept when already connected',
    () async {
      final service = _DedupeOnlyMdkService(
        groups: const [existingGroup],
        membersByGroup: const {
          'existing-group': ['local-parent', 'remote-parent'],
        },
        pendingWelcomes: const [duplicateWelcome],
      );

      await expectLater(
        service.acceptPendingWelcome(welcomeEventIdHex: 'welcome-event'),
        throwsA(isA<MdkAlreadyConnectedException>()),
      );
    },
  );

  test(
    'getPendingWelcomes collapses duplicate welcomes from the same parent',
    () async {
      final service = FakeMdkService()
        ..pendingWelcomesResult = const [
          duplicateWelcome,
          MdkPendingWelcome(
            welcomeEventIdHex: 'welcome-event-2',
            wrapperEventIdHex: 'wrapper-event-2',
            mlsGroupIdHex: 'new-group-2',
            nostrGroupIdHex: 'new-nostr-group-2',
            groupName: 'Duplicate Family 2',
            groupDescription: 'Duplicate welcome',
            memberCount: 2,
            welcomerPubkeyHex: 'REMOTE-PARENT',
            relays: ['wss://relay.example'],
            state: 'pending',
          ),
        ];

      final welcomes = await service.getPendingWelcomes();

      expect(welcomes, hasLength(1));
      expect(welcomes.single.welcomeEventIdHex, 'welcome-event');
    },
  );
}

class _DedupeOnlyMdkService extends MdkService {
  _DedupeOnlyMdkService({
    this.groups = const [],
    this.membersByGroup = const {},
    this.pendingWelcomes = const [],
  });

  final List<MdkGroupSummary> groups;
  final Map<String, List<String>> membersByGroup;
  final List<MdkPendingWelcome> pendingWelcomes;

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<List<MdkGroupSummary>> getGroupSummaries() async => groups;

  @override
  Future<List<String>> getGroupMembers({required String mlsGroupIdHex}) async {
    return membersByGroup[mlsGroupIdHex] ?? const [];
  }

  @override
  Future<List<MdkPendingWelcome>> getPendingWelcomes({
    bool includeAlreadyConnected = false,
  }) async {
    return pendingWelcomes;
  }
}
