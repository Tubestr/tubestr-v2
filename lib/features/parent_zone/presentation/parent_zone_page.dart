import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../domain/marmot/invite_transport_models.dart';
import '../../../domain/models/remote_share_projection.dart';
import '../../../services/mdk/mdk_service.dart';
import 'models/parent_zone_models.dart';
import 'widgets/parent_zone_connections_section.dart';
import 'widgets/parent_zone_family_section.dart';
import 'widgets/parent_zone_overview_section.dart';
import 'widgets/parent_zone_pin_views.dart';
import 'widgets/parent_zone_settings_section.dart';
import 'widgets/parent_zone_sidebar.dart';

class ParentZoneContent extends ConsumerStatefulWidget {
  const ParentZoneContent({super.key});

  @override
  ConsumerState<ParentZoneContent> createState() => _ParentZoneContentState();
}

class _ParentZoneContentState extends ConsumerState<ParentZoneContent> {
  bool _isUnlocked = false;
  bool _needsPinSetup = false;
  bool _checkingPin = true;

  String _pinEntry = '';
  String? _pinError;
  String _newPin = '';
  String _confirmPin = '';

  bool _sidebarOpen = false;
  ParentZoneSection _section = ParentZoneSection.overview;

  final _nameController = TextEditingController();
  final _relayController = TextEditingController();
  final _blossomController = TextEditingController();
  final _pinManagementController = TextEditingController();
  final _eventImportController = TextEditingController();
  final _inviteImportController = TextEditingController();
  ThemeDescriptor _childTheme = ThemeDescriptor.campfire;

  late Future<ParentZoneMdkDebugState> _mdkDebugFuture;

  bool _isGeneratingInvitePacket = false;
  bool _isCreatingWelcome = false;
  bool _isAcceptingWelcome = false;
  bool _isCreatingDebugShare = false;
  bool _isImportingDebugEvent = false;
  Uri? _queuedDeepLinkUri;

  @override
  void initState() {
    super.initState();
    _mdkDebugFuture = _loadMdkDebugState();
    _checkPin();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relayController.dispose();
    _blossomController.dispose();
    _pinManagementController.dispose();
    _eventImportController.dispose();
    _inviteImportController.dispose();
    super.dispose();
  }

  Future<void> _checkPin() async {
    final hasPin = await ref.read(parentAuthServiceProvider).hasPin();
    if (!mounted) {
      return;
    }
    setState(() {
      _needsPinSetup = !hasPin;
      _checkingPin = false;
      if (!hasPin) {
        _isUnlocked = false;
      }
    });
  }

  Future<void> _verifyPin() async {
    if (_pinEntry.length < 4) {
      return;
    }
    final ok = await ref.read(parentAuthServiceProvider).verifyPin(_pinEntry);
    if (!mounted) {
      return;
    }
    if (ok) {
      setState(() {
        _isUnlocked = true;
        _pinError = null;
      });
      unawaited(_consumeQueuedDeepLinkIfPossible());
    } else {
      setState(() {
        _pinEntry = '';
        _pinError = 'Incorrect PIN';
      });
    }
  }

  Future<void> _saveNewPin() async {
    if (_newPin.length < 4 || _newPin != _confirmPin) {
      setState(() => _pinError = 'PINs must match (4 digits)');
      return;
    }
    await ref.read(parentAuthServiceProvider).setPin(_newPin);
    if (!mounted) {
      return;
    }
    setState(() {
      _isUnlocked = true;
      _needsPinSetup = false;
      _pinError = null;
    });
    unawaited(_consumeQueuedDeepLinkIfPossible());
  }

  Future<ParentZoneMdkDebugState> _loadMdkDebugState() async {
    final service = ref.read(mdkServiceProvider);
    final version = await service.bridgeVersion();
    final dbPath = await service.mdkDbPath();
    final groupCount = await service.groupCount();
    final groups = await service.getGroupSummaries();
    final pendingWelcomes = await service.getPendingWelcomes();
    return ParentZoneMdkDebugState(
      version: version,
      dbPath: dbPath,
      groupCount: groupCount,
      groups: groups,
      pendingWelcomes: pendingWelcomes,
    );
  }

  void _refreshMdkState() {
    setState(() => _mdkDebugFuture = _loadMdkDebugState());
  }

  Future<void> _acceptPendingWelcome(String welcomeEventIdHex) async {
    setState(() => _isAcceptingWelcome = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      final group = await ref
          .read(mdkServiceProvider)
          .acceptPendingWelcome(welcomeEventIdHex: welcomeEventIdHex);
      if (!mounted) {
        return;
      }
      setState(() {
        _isAcceptingWelcome = false;
        _mdkDebugFuture = _loadMdkDebugState();
      });
      await ref
          .read(appDatabaseProvider)
          .assignPrimaryGroupToProfilesIfMissing(group.mlsGroupIdHex);
      await ref.read(syncCoordinatorProvider).refreshSubscriptions();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('Joined ${group.name}')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isAcceptingWelcome = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  void _showQrDialog({
    required String title,
    required String payload,
    String? shareText,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final payloadUri = Uri.tryParse(payload);
        return SimpleDialog(
          title: Text(title, textAlign: TextAlign.center),
          children: [
            Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: payload));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (shareText != null && shareText.isNotEmpty) {
                      await SharePlus.instance.share(
                        ShareParams(text: shareText),
                      );
                    } else if (payloadUri != null && payloadUri.hasScheme) {
                      await SharePlus.instance.share(
                        ShareParams(uri: payloadUri),
                      );
                    } else {
                      await SharePlus.instance.share(
                        ShareParams(text: payload),
                      );
                    }
                  },
                  icon: const Icon(Icons.ios_share_rounded, size: 16),
                  label: const Text('Share'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<String?> _openScanner() {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _QrScannerSheet(),
    );
  }

  void _showPayloadDialog({required String title, required String payload}) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(child: SelectableText(payload)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: payload));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _createInvite() async {
    final identity = await ref.read(parentIdentityProvider.future);
    if (identity == null) {
      return;
    }
    setState(() => _isGeneratingInvitePacket = true);
    try {
      await ref.read(syncCoordinatorProvider).refreshSubscriptions();
      final result = await ref
          .read(familyConnectionServiceProvider)
          .createInvite(identity: identity);
      if (!mounted) {
        return;
      }
      setState(() => _isGeneratingInvitePacket = false);
      _showQrDialog(
        title: 'Your Invite Code',
        payload: result.payload,
        shareText:
            '''
Nook Family Invite

Open this link on the other parent's device:
${result.payload}
''',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isGeneratingInvitePacket = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create invite: $error')),
      );
    }
  }

  Future<void> _scanAndProcessInvite() async {
    final scanned = await _openScanner();
    if (!mounted || scanned == null || scanned.isEmpty) {
      return;
    }

    await _processInvitePayload(scanned);
  }

  Future<void> _processInviteInput() async {
    final raw = _inviteImportController.text.trim();
    if (raw.isEmpty) {
      return;
    }
    await _processInvitePayload(raw);
  }

  Future<void> _processInvitePayload(
    String invitePayload, {
    bool clearPendingDeepLink = false,
  }) async {
    final identity = await ref.read(parentIdentityProvider.future);
    if (identity == null) {
      if (clearPendingDeepLink) {
        ref.read(pendingDeepLinkProvider.notifier).state = null;
      }
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _isCreatingWelcome = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      final result = await ref
          .read(familyConnectionServiceProvider)
          .connectFromInvite(identity: identity, invitePayload: invitePayload);
      if (!mounted) {
        return;
      }
      setState(() {
        _isCreatingWelcome = false;
        _mdkDebugFuture = _loadMdkDebugState();
      });
      await ref
          .read(appDatabaseProvider)
          .assignPrimaryGroupToProfilesIfMissing(result.group.mlsGroupIdHex);
      await ref.read(syncCoordinatorProvider).refreshSubscriptions();
      _inviteImportController.clear();
      if (clearPendingDeepLink) {
        ref.read(pendingDeepLinkProvider.notifier).state = null;
      }
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.publishedWelcomeCount > 0
                ? 'Connection sent. They can approve it in Parent Zone.'
                : 'Group created.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isCreatingWelcome = false);
      if (clearPendingDeepLink) {
        ref.read(pendingDeepLinkProvider.notifier).state = null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not process invite: $error')),
      );
    }
  }

  void _queueDeepLink(Uri uri) {
    setState(() {
      _queuedDeepLinkUri = uri;
      _section = ParentZoneSection.connections;
    });
    unawaited(_consumeQueuedDeepLinkIfPossible());
  }

  Future<void> _consumeQueuedDeepLinkIfPossible() async {
    final queued = _queuedDeepLinkUri;
    if (queued == null || !_isUnlocked || _isCreatingWelcome) {
      return;
    }

    if (queued.host.toLowerCase() != GroupInvitePacket.deepLinkHost) {
      ref.read(pendingDeepLinkProvider.notifier).state = null;
      if (mounted) {
        setState(() => _queuedDeepLinkUri = null);
      } else {
        _queuedDeepLinkUri = null;
      }
      return;
    }

    if (mounted) {
      setState(() => _queuedDeepLinkUri = null);
    } else {
      _queuedDeepLinkUri = null;
    }

    await _processInvitePayload(queued.toString(), clearPendingDeepLink: true);
  }

  Future<void> _createDebugShareEvent({required bool publish}) async {
    final identity = await ref.read(parentIdentityProvider.future);
    if (identity == null) {
      return;
    }

    setState(() => _isCreatingDebugShare = true);

    try {
      final selectedProfileId = ref.read(selectedProfileIdProvider);
      final latestVideo = await ref
          .read(appDatabaseProvider)
          .getLatestLocalVideo(profileId: selectedProfileId);
      if (latestVideo == null) {
        throw StateError(
          'Capture a local video before creating a sample share.',
        );
      }

      final profile = (ref.read(profilesProvider).valueOrNull ?? const [])
          .firstWhere(
            (item) => item.id == latestVideo.profileId,
            orElse: () =>
                throw StateError('Profile for latest video not found.'),
          );
      final groups = await ref.read(mdkServiceProvider).getGroupSummaries();
      if (groups.isEmpty) {
        throw StateError('Create or join a family connection first.');
      }

      final event = await ref
          .read(videoShareCoordinatorProvider)
          .createUploadedShareMessage(
            identity: identity,
            localVideo: latestVideo,
            childDisplayName: profile.name,
            mlsGroupIdHex: groups.first.mlsGroupIdHex,
          );

      if (publish) {
        final relays = await ref.read(nostrServiceProvider).loadRelayList();
        await ref
            .read(videoShareCoordinatorProvider)
            .publishSignedGroupMessage(
              identity: identity,
              signedEventJson: event.wrapperEventJson,
              relays: relays,
            );
      }

      if (!mounted) {
        return;
      }

      setState(() => _isCreatingDebugShare = false);
      _showPayloadDialog(
        title: publish ? 'Published Share Event' : 'Share Event',
        payload: event.wrapperEventJson,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isCreatingDebugShare = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _importDebugGroupEvent() async {
    final raw = _eventImportController.text.trim();
    if (raw.isEmpty) {
      return;
    }

    setState(() => _isImportingDebugEvent = true);
    try {
      final result = await ref
          .read(syncCoordinatorProvider)
          .processIncomingEventJson(eventJson: raw);
      if (!mounted) {
        return;
      }

      setState(() => _isImportingDebugEvent = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.reason)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isImportingDebugEvent = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _saveChild() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    await ref
        .read(identityServiceProvider)
        .createChildProfile(name: name, theme: _childTheme);
    _nameController.clear();
  }

  Future<void> _deleteChild(String profileId) {
    return ref.read(appDatabaseProvider).deleteProfileById(profileId);
  }

  Future<void> _saveRelay() async {
    final next = _relayController.text.trim();
    if (next.isEmpty) {
      return;
    }
    final relays = await ref.read(nostrServiceProvider).loadRelayList();
    await ref.read(nostrServiceProvider).saveRelayList([...relays, next]);
    _relayController.clear();
  }

  Future<void> _saveBlossomServer() async {
    final next = _blossomController.text.trim();
    if (next.isEmpty) {
      return;
    }
    final servers = await ref
        .read(nostrServiceProvider)
        .loadBlossomServerList();
    await ref.read(nostrServiceProvider).saveBlossomServerList([
      ...servers,
      next,
    ]);
    _blossomController.clear();
  }

  Future<void> _publishBlossomServers(List<String> servers) async {
    final identity = ref.read(parentIdentityProvider).valueOrNull;
    if (identity == null) {
      return;
    }
    await ref
        .read(nostrServiceProvider)
        .publishBlossomServerList(identity: identity, servers: servers);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Published Blossom server list')),
    );
  }

  Future<void> _updatePin() async {
    final pin = _pinManagementController.text.trim();
    if (pin.length < 4) {
      return;
    }
    await ref.read(parentAuthServiceProvider).setPin(pin);
    _pinManagementController.clear();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PIN updated')));
  }

  Future<void> _provisionSafetyHq() async {
    final identity = ref.read(parentIdentityProvider).valueOrNull;
    if (identity == null) {
      return;
    }
    final group = await ref
        .read(safetyHqServiceProvider)
        .ensureProvisioned(identity: identity);
    await ref.read(syncCoordinatorProvider).refreshSubscriptions();
    ref.invalidate(safetyHqStatusProvider);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          group == null
              ? 'Safety HQ already provisioned'
              : 'Provisioned ${group.name}',
        ),
      ),
    );
  }

  Future<void> _manageGroup(MdkGroupSummary group) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _GroupModerationSheet(
        group: group,
        onChanged: () {
          _refreshMdkState();
          unawaited(ref.read(syncCoordinatorProvider).refreshSubscriptions());
        },
      ),
    );
  }

  Widget _buildSectionContent() {
    return switch (_section) {
      ParentZoneSection.overview => ParentZoneOverviewSection(
        onSelectSection: (section) => setState(() => _section = section),
      ),
      ParentZoneSection.family => ParentZoneFamilySection(
        nameController: _nameController,
        childTheme: _childTheme,
        onThemeSelected: (theme) => setState(() => _childTheme = theme),
        onSaveChild: _saveChild,
        onDeleteChild: _deleteChild,
      ),
      ParentZoneSection.connections => ParentZoneConnectionsSection(
        mdkDebugFuture: _mdkDebugFuture,
        isGeneratingInvitePacket: _isGeneratingInvitePacket,
        isCreatingWelcome: _isCreatingWelcome,
        isAcceptingWelcome: _isAcceptingWelcome,
        isCreatingDebugShare: _isCreatingDebugShare,
        isImportingDebugEvent: _isImportingDebugEvent,
        eventImportController: _eventImportController,
        inviteImportController: _inviteImportController,
        onCreateInvite: _createInvite,
        onScanAndProcessInvite: _scanAndProcessInvite,
        onProcessInviteInput: _processInviteInput,
        onAcceptPendingWelcome: _acceptPendingWelcome,
        onRefreshMdkState: _refreshMdkState,
        onManageGroup: _manageGroup,
        onCreateDebugShareEvent: (publish) =>
            _createDebugShareEvent(publish: publish),
        onImportDebugGroupEvent: _importDebugGroupEvent,
      ),
      ParentZoneSection.settings => ParentZoneSettingsSection(
        relayController: _relayController,
        blossomController: _blossomController,
        pinManagementController: _pinManagementController,
        onRefresh: () => setState(() {}),
        onSaveRelays: _saveRelay,
        onSaveBlossomServers: _saveBlossomServer,
        onPublishBlossomServers: _publishBlossomServers,
        onUpdatePin: _updatePin,
        onProvisionSafetyHq: _provisionSafetyHq,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(syncRevisionProvider, (previous, next) {
      if (!mounted) {
        return;
      }
      setState(() => _mdkDebugFuture = _loadMdkDebugState());
    });
    final pendingDeepLink = ref.watch(pendingDeepLinkProvider);
    if (pendingDeepLink != null &&
        pendingDeepLink.scheme.toLowerCase() ==
            GroupInvitePacket.deepLinkScheme &&
        pendingDeepLink != _queuedDeepLinkUri) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _queueDeepLink(pendingDeepLink);
      });
    }

    final palette = ref.watch(activeThemeProvider).palette;
    if (_checkingPin) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_isUnlocked) {
      return _needsPinSetup
          ? ParentZonePinSetupView(
              palette: palette,
              pinError: _pinError,
              onNewPinChanged: (value) => _newPin = value,
              onConfirmPinChanged: (value) => _confirmPin = value,
              onSavePin: _saveNewPin,
            )
          : ParentZonePinEntryView(
              palette: palette,
              pinEntry: _pinEntry,
              pinError: _pinError,
              onDigit: (digit) {
                if (_pinEntry.length >= 4) {
                  return;
                }
                setState(() {
                  _pinEntry += digit;
                  _pinError = null;
                });
              },
              onDelete: () {
                if (_pinEntry.isNotEmpty) {
                  setState(() {
                    _pinEntry = _pinEntry.substring(0, _pinEntry.length - 1);
                  });
                }
              },
              onSubmit: _verifyPin,
            );
    }

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => setState(() => _sidebarOpen = true),
                    ),
                    Text(
                      _section.label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.lock_outline_rounded),
                      tooltip: 'Lock',
                      onPressed: () => setState(() => _isUnlocked = false),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildSectionContent()),
            ],
          ),
        ),
        if (_sidebarOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _sidebarOpen = false),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: _sidebarOpen ? 0 : -280,
          top: 0,
          bottom: 0,
          width: 280,
          child: ParentZoneSidebar(
            palette: palette,
            parentNpub:
                ref.watch(parentIdentityProvider).valueOrNull?.npub ?? '',
            selected: _section,
            onSelect: (section) => setState(() {
              _section = section;
              _sidebarOpen = false;
            }),
          ),
        ),
      ],
    );
  }
}

class _QrScannerSheet extends StatefulWidget {
  const _QrScannerSheet();

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text('Scan QR', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      if (_hasScanned || capture.barcodes.isEmpty) {
                        return;
                      }
                      final value = capture.barcodes.first.rawValue;
                      if (value == null || value.isEmpty) {
                        return;
                      }
                      _hasScanned = true;
                      Navigator.of(context).pop(value);
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Point the camera at a family invite QR code.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupModerationSheet extends ConsumerStatefulWidget {
  const _GroupModerationSheet({
    required this.group,
    required this.onChanged,
  });

  final MdkGroupSummary group;
  final VoidCallback onChanged;

  @override
  ConsumerState<_GroupModerationSheet> createState() =>
      _GroupModerationSheetState();
}

class _GroupModerationSheetState extends ConsumerState<_GroupModerationSheet> {
  bool _working = false;
  late Future<_GroupModerationSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  Future<_GroupModerationSnapshot> _loadSnapshot() async {
    final members = await ref
        .read(mdkServiceProvider)
        .getGroupMembers(mlsGroupIdHex: widget.group.mlsGroupIdHex);
    final shares = await ref
        .read(appDatabaseProvider)
        .getRemoteShareProjectionsForGroup(widget.group.mlsGroupIdHex);
    return _GroupModerationSnapshot(members: members, shares: shares);
  }

  void _refresh() {
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
    widget.onChanged();
  }

  Future<void> _deleteVideo(RemoteShareProjection projection) async {
    final identity = ref.read(parentIdentityProvider).valueOrNull;
    if (identity == null) {
      return;
    }
    setState(() => _working = true);
    try {
      await ref.read(moderationCoordinatorProvider).deleteSharedVideo(
        identity: identity,
        projection: projection,
        reason: 'Removed by parent moderator',
      );
      if (!mounted) {
        return;
      }
      setState(() => _working = false);
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${projection.title} for this family')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _working = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _removeMember(String memberPubkeyHex) async {
    final identity = ref.read(parentIdentityProvider).valueOrNull;
    if (identity == null) {
      return;
    }
    setState(() => _working = true);
    try {
      await ref.read(moderationCoordinatorProvider).removeMember(
        identity: identity,
        mlsGroupIdHex: widget.group.mlsGroupIdHex,
        memberPubkeyHex: memberPubkeyHex,
        reason: 'Removed by parent moderator',
      );
      if (!mounted) {
        return;
      }
      setState(() => _working = false);
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed member from family group')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _working = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(activeThemeProvider).palette;
    final identity = ref.watch(parentIdentityProvider).valueOrNull;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: FutureBuilder<_GroupModerationSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 320,
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            }

            final data = snapshot.data!;
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 620),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    widget.group.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Delete shared videos or remove family members. These are separate actions.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Members',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (data.members.isEmpty)
                    Text(
                      'No member details available yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    for (final member in data.members)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          member == identity?.publicKeyHex
                              ? Icons.verified_user_rounded
                              : Icons.person_outline_rounded,
                          color: member == identity?.publicKeyHex
                              ? palette.success
                              : palette.accent,
                        ),
                        title: Text(
                          member == identity?.publicKeyHex
                              ? 'You'
                              : _truncateKey(member),
                        ),
                        subtitle: member == identity?.publicKeyHex
                            ? const Text('Current parent identity')
                            : Text(member),
                        trailing: member == identity?.publicKeyHex
                            ? null
                            : FilledButton.tonal(
                                onPressed: _working
                                    ? null
                                    : () => _removeMember(member),
                                child: Text(_working ? 'Working…' : 'Remove'),
                              ),
                      ),
                  const Divider(height: 28),
                  Text(
                    'Shared Videos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (data.shares.isEmpty)
                    Text(
                      'No shared videos from this family yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    for (final share in data.shares.take(8))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          share.status == 'deleted'
                              ? Icons.delete_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          color: share.status == 'deleted'
                              ? palette.warning
                              : palette.accentSecondary,
                        ),
                        title: Text(share.title),
                        subtitle: Text(
                          '${share.displayName} · ${share.status}',
                        ),
                        trailing: share.status == 'deleted'
                            ? const Text('Deleted')
                            : FilledButton.tonal(
                                onPressed: _working
                                    ? null
                                    : () => _deleteVideo(share),
                                child: Text(_working ? 'Working…' : 'Delete'),
                              ),
                      ),
                  const SizedBox(height: 8),
                  Text(
                    'Removing a member does not delete their past content automatically.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.mutedInk,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GroupModerationSnapshot {
  const _GroupModerationSnapshot({
    required this.members,
    required this.shares,
  });

  final List<String> members;
  final List<RemoteShareProjection> shares;
}

String _truncateKey(String value) {
  if (value.length <= 16) {
    return value;
  }
  return '${value.substring(0, 8)}…${value.substring(value.length - 6)}';
}
