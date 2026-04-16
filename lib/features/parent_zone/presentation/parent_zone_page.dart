import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/nostr/nostr_key_format.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../domain/marmot/invite_transport_models.dart';
import '../../../domain/models/remote_share_projection.dart';
import '../../../shared_ui/components/external_page_view.dart';
import '../../../shared_ui/components/qr_scanner_sheet.dart';
import '../../../shared_ui/motion/app_motion.dart';
import '../../../services/connections/family_connection_service.dart';
import '../../../services/mdk/mdk_service.dart';
import '../../../services/sync/sync_coordinator.dart';
import 'models/parent_zone_models.dart';
import 'widgets/parent_zone_account_section.dart';
import 'widgets/parent_zone_activity_section.dart';
import 'widgets/parent_zone_children_section.dart';
import 'widgets/parent_zone_dashboard_section.dart';
import 'widgets/parent_zone_diagnostics_section.dart';
import 'widgets/parent_zone_family_spaces_section.dart';
import 'widgets/parent_zone_network_section.dart';
import 'widgets/parent_zone_pin_views.dart';
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
  ParentZoneSection _section = ParentZoneSection.dashboard;

  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _relayController = TextEditingController();
  final _blossomController = TextEditingController();
  final _pinManagementController = TextEditingController();
  final _inviteImportController = TextEditingController();
  ThemeDescriptor _childTheme = ThemeDescriptor.campfire;
  String? _syncedDisplayName;

  late Future<ParentZoneMdkDebugState> _mdkDebugFuture;

  bool _isGeneratingInvitePacket = false;
  bool _currentInviteKeyPublishInFlight = false;
  bool _publishedCurrentInviteKeyThisSession = false;
  bool _isCreatingWelcome = false;
  bool _isAcceptingWelcome = false;
  bool _isResettingApp = false;
  bool _isDeletingAccount = false;
  bool _approvalRequired = false;
  Uri? _queuedDeepLinkUri;
  Timer? _pendingWelcomePollTimer;
  bool _pendingWelcomePollInFlight = false;
  int _pendingWelcomePollsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _mdkDebugFuture = _loadMdkDebugState();
    _checkPin();
    unawaited(_loadSettingsState());
  }

  @override
  void dispose() {
    _pendingWelcomePollTimer?.cancel();
    _nameController.dispose();
    _displayNameController.dispose();
    _relayController.dispose();
    _blossomController.dispose();
    _pinManagementController.dispose();
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

  Future<void> _loadSettingsState() async {
    final displayName = await ref
        .read(parentProfileServiceProvider)
        .loadLocalDisplayName();
    final approvalRequired = await ref
        .read(videoApprovalServiceProvider)
        .isApprovalRequired();
    if (!mounted) {
      return;
    }
    _syncDisplayNameController(displayName);
    setState(() => _approvalRequired = approvalRequired);
  }

  void _syncDisplayNameController(String? displayName) {
    final normalized = displayName?.trim() ?? '';
    final current = _displayNameController.text.trim();
    final lastSynced = _syncedDisplayName ?? '';
    if (current == normalized) {
      _syncedDisplayName = normalized;
      return;
    }
    final canReplace = current.isEmpty || current == lastSynced;
    if (!canReplace) {
      return;
    }
    _displayNameController.value = _displayNameController.value.copyWith(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
      composing: TextRange.empty,
    );
    _syncedDisplayName = normalized;
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
      await HapticFeedback.mediumImpact();
      setState(() {
        _isUnlocked = true;
        _pinError = null;
      });
      _consumePendingSectionIfPossible();
      _maybePublishCurrentInviteKey(_section);
      unawaited(_consumeQueuedDeepLinkIfPossible());
    } else {
      await HapticFeedback.heavyImpact();
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
    await HapticFeedback.mediumImpact();
    setState(() {
      _isUnlocked = true;
      _needsPinSetup = false;
      _pinError = null;
    });
    _consumePendingSectionIfPossible();
    _maybePublishCurrentInviteKey(_section);
    unawaited(_consumeQueuedDeepLinkIfPossible());
  }

  void _lockParentZone() {
    if (!mounted || _needsPinSetup) {
      return;
    }
    setState(() {
      _isUnlocked = false;
      _sidebarOpen = false;
      _pinEntry = '';
      _pinError = null;
    });
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
    setState(() {
      _mdkDebugFuture = _loadMdkDebugState();
    });
    _maybePublishCurrentInviteKey(_section);
  }

  void _selectSection(ParentZoneSection section, {bool closeSidebar = false}) {
    setState(() {
      _section = section;
      if (closeSidebar) {
        _sidebarOpen = false;
      }
    });
    _maybePublishCurrentInviteKey(section);
  }

  void _maybePublishCurrentInviteKey(ParentZoneSection section) {
    if (!_isUnlocked || section != ParentZoneSection.familySpaces) {
      return;
    }
    unawaited(_ensureCurrentInviteKeyPublished());
  }

  Future<void> _ensureCurrentInviteKeyPublished() async {
    if (_currentInviteKeyPublishInFlight ||
        _publishedCurrentInviteKeyThisSession) {
      return;
    }
    _currentInviteKeyPublishInFlight = true;
    try {
      final identity = await ref.read(parentIdentityProvider.future);
      if (!mounted || identity == null) {
        return;
      }
      await ref
          .read(familyConnectionServiceProvider)
          .publishCurrentKeyPackage(identity: identity);
      _publishedCurrentInviteKeyThisSession = true;
    } catch (_) {
      _publishedCurrentInviteKeyThisSession = false;
    } finally {
      _currentInviteKeyPublishInFlight = false;
    }
  }

  void _startPendingWelcomePolling({int attempts = 45}) {
    _pendingWelcomePollTimer?.cancel();
    _pendingWelcomePollsRemaining = attempts;
    _pendingWelcomePollInFlight = false;
    _pendingWelcomePollTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (_pendingWelcomePollInFlight || !mounted) {
        return;
      }
      _pendingWelcomePollInFlight = true;
      unawaited(() async {
        try {
          final state = await _loadMdkDebugState();
          if (!mounted) {
            return;
          }
          final shouldStop =
              state.pendingWelcomes.isNotEmpty ||
              _pendingWelcomePollsRemaining <= 1;
          setState(() {
            _mdkDebugFuture = Future<ParentZoneMdkDebugState>.value(state);
          });
          if (shouldStop) {
            timer.cancel();
            _pendingWelcomePollTimer = null;
          }
        } finally {
          _pendingWelcomePollsRemaining -= 1;
          _pendingWelcomePollInFlight = false;
        }
      }());
    });
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
      _pendingWelcomePollTimer?.cancel();
      _pendingWelcomePollTimer = null;
      await ref
          .read(appDatabaseProvider)
          .assignPrimaryGroupToProfilesIfMissing(group.mlsGroupIdHex);
      await ref
          .read(syncCoordinatorProvider)
          .refreshSubscriptions(trigger: SyncRefreshTrigger.groupChange);
      if (!mounted) {
        return;
      }
      ref.invalidate(mdkGroupSummariesProvider);
      await HapticFeedback.mediumImpact();
      messenger.showSnackBar(SnackBar(content: Text('Joined ${group.name}')));
    } on MdkAlreadyConnectedException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAcceptingWelcome = false;
        _mdkDebugFuture = _loadMdkDebugState();
      });
      _pendingWelcomePollTimer?.cancel();
      _pendingWelcomePollTimer = null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_alreadyConnectedMessage(error))));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isAcceptingWelcome = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We couldn\'t finish joining that family space yet. Please try again.',
          ),
        ),
      );
    }
  }

  String _alreadyConnectedMessage(MdkAlreadyConnectedException error) {
    final groupName = error.group.name.trim();
    if (groupName.isEmpty) {
      return 'You\'re already connected.';
    }
    return 'You\'re already connected in $groupName.';
  }

  String _alreadyPendingMessage(FamilyConnectionAlreadyPendingException error) {
    final groupName = error.group.name.trim();
    if (groupName.isEmpty) {
      return 'Connection already sent. They can approve it in Parent Zone.';
    }
    return 'Connection already sent for $groupName. They can approve it in Parent Zone.';
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
        final qrSize = (MediaQuery.sizeOf(context).width - 120).clamp(
          0.0,
          240.0,
        );
        return SimpleDialog(
          title: Text(title, textAlign: TextAlign.center),
          children: [
            Center(
              child: SizedBox(
                width: qrSize,
                height: qrSize,
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: qrSize,
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
                Builder(
                  builder: (context) => OutlinedButton.icon(
                    onPressed: () async {
                      final box = context.findRenderObject() as RenderBox?;
                      final origin = box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : null;
                      if (shareText != null && shareText.isNotEmpty) {
                        await SharePlus.instance.share(
                          ShareParams(
                            text: shareText,
                            sharePositionOrigin: origin,
                          ),
                        );
                      } else if (payloadUri != null && payloadUri.hasScheme) {
                        await SharePlus.instance.share(
                          ShareParams(
                            uri: payloadUri,
                            sharePositionOrigin: origin,
                          ),
                        );
                      } else {
                        await SharePlus.instance.share(
                          ShareParams(
                            text: payload,
                            sharePositionOrigin: origin,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.ios_share_rounded, size: 16),
                    label: const Text('Share'),
                  ),
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
      builder: (_) => const QrScannerSheet(
        instructions: 'Point the camera at a family invite QR code.',
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
      try {
        await ref
            .read(syncCoordinatorProvider)
            .refreshSubscriptions(trigger: SyncRefreshTrigger.manual);
      } catch (error) {
        debugPrint('Family invite sync refresh failed: $error');
      }
      final result = await ref
          .read(familyConnectionServiceProvider)
          .createInvite(identity: identity);
      _publishedCurrentInviteKeyThisSession = true;
      unawaited(ref.read(betaFunnelServiceProvider).trackFamilyInviteCreated());
      if (!mounted) {
        return;
      }
      setState(() => _isGeneratingInvitePacket = false);
      _startPendingWelcomePolling();
      _showQrDialog(
        title: 'Your Invite Code',
        payload: result.payload,
        shareText:
            '''
Tubestr Family Invite

Open this link on the other parent's device:
${result.payload}
''',
      );
    } catch (error, stackTrace) {
      debugPrint('Family invite creation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() => _isGeneratingInvitePacket = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We couldn\'t create an invite just yet. Please try again.',
          ),
        ),
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
      unawaited(
        ref
            .read(betaFunnelServiceProvider)
            .trackFamilyInviteConnected(
              publishedWelcomeCount: result.publishedWelcomeCount,
            ),
      );
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
      await ref
          .read(syncCoordinatorProvider)
          .refreshSubscriptions(trigger: SyncRefreshTrigger.groupChange);
      if (!mounted) {
        return;
      }
      ref.invalidate(mdkGroupSummariesProvider);
      _inviteImportController.clear();
      if (clearPendingDeepLink) {
        ref.read(pendingDeepLinkProvider.notifier).state = null;
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
    } on MdkAlreadyConnectedException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCreatingWelcome = false;
        _mdkDebugFuture = _loadMdkDebugState();
      });
      _inviteImportController.clear();
      if (clearPendingDeepLink) {
        ref.read(pendingDeepLinkProvider.notifier).state = null;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_alreadyConnectedMessage(error))));
    } on FamilyConnectionAlreadyPendingException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCreatingWelcome = false;
        _mdkDebugFuture = _loadMdkDebugState();
      });
      _inviteImportController.clear();
      if (clearPendingDeepLink) {
        ref.read(pendingDeepLinkProvider.notifier).state = null;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_alreadyPendingMessage(error))));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isCreatingWelcome = false);
      if (clearPendingDeepLink) {
        ref.read(pendingDeepLinkProvider.notifier).state = null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We couldn\'t use that invite yet. Double-check it and try again.',
          ),
        ),
      );
    }
  }

  void _queueDeepLink(Uri uri) {
    setState(() {
      _queuedDeepLinkUri = uri;
      _section = ParentZoneSection.familySpaces;
    });
    _maybePublishCurrentInviteKey(ParentZoneSection.familySpaces);
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

  void _consumePendingSectionIfPossible() {
    final pending = ref.read(pendingParentZoneSectionProvider);
    if (pending == null || !_isUnlocked) {
      return;
    }
    final section = ParentZoneSection.values
        .where((s) => s.name == pending)
        .firstOrNull;
    ref.read(pendingParentZoneSectionProvider.notifier).state = null;
    if (section != null) {
      _selectSection(section);
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
    unawaited(
      ref
          .read(betaFunnelServiceProvider)
          .trackChildProfileCreated(surface: 'parent_zone'),
    );
    _nameController.clear();
    await HapticFeedback.mediumImpact();
  }

  Future<void> _deleteChild(String profileId) async {
    final profiles = ref.read(profilesProvider).valueOrNull ?? const [];
    final profile = profiles.where((p) => p.id == profileId).firstOrNull;
    final childName = profile?.name ?? 'this child profile';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete $childName?'),
          content: const Text(
            'This will permanently remove the child profile and delete any videos and media stored on behalf of this profile from Tubestr-managed servers. Clips already delivered to other family members remain on their devices.\n\nThis cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete profile'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final identity = ref.read(parentIdentityProvider).valueOrNull;
    final result = await ref
        .read(childProfileDeletionServiceProvider)
        .deleteProfile(profileId: profileId, identity: identity);
    if (!mounted) {
      return;
    }
    if (result.deletedProfile) {
      await HapticFeedback.mediumImpact();
    }
    final message = result.deletedProfile
        ? result.usedManagedCleanup
              ? 'Profile deleted. ${result.deletedBlobCount} file${result.deletedBlobCount == 1 ? '' : 's'} removed from Tubestr servers.'
              : 'Profile deleted.'
        : 'We could not finish deleting $childName yet because ${result.failedDeleteCount} file${result.failedDeleteCount == 1 ? '' : 's'} could not be removed from Tubestr servers. Try again when the connection is stable.';
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approveVideo(String videoId) async {
    final identity = ref.read(parentIdentityProvider).valueOrNull;
    if (identity == null) {
      return;
    }
    await ref
        .read(videoApprovalServiceProvider)
        .approveVideo(
          videoId: videoId,
          parentPublicKeyHex: identity.publicKeyHex,
        );
    await HapticFeedback.mediumImpact();
  }

  Future<void> _rejectVideo(String videoId) async {
    final identity = ref.read(parentIdentityProvider).valueOrNull;
    if (identity == null) {
      return;
    }
    await ref
        .read(videoApprovalServiceProvider)
        .rejectVideo(
          videoId: videoId,
          parentPublicKeyHex: identity.publicKeyHex,
        );
    await HapticFeedback.mediumImpact();
  }

  Future<void> _saveDisplayName() async {
    final messenger = ScaffoldMessenger.of(context);
    final next = _displayNameController.text.trim();
    if (next.isEmpty) {
      return;
    }
    await ref.read(parentProfileServiceProvider).saveLocalDisplayName(next);
    ref.invalidate(parentDisplayNameProvider);
    if (!mounted) {
      return;
    }
    await HapticFeedback.lightImpact();
    messenger.showSnackBar(const SnackBar(content: Text('Saved display name')));
  }

  Future<void> _publishDisplayName() async {
    final identity = ref.read(parentIdentityProvider).valueOrNull;
    if (identity == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final next = _displayNameController.text.trim();
    if (next.isEmpty) {
      return;
    }
    try {
      await ref
          .read(parentProfileServiceProvider)
          .publishLocalProfile(identity: identity, displayName: next);
      ref.invalidate(parentDisplayNameProvider);
      ref.invalidate(resolvedParentProfileProvider(identity.publicKeyHex));
      ref.invalidate(offlineActionsProvider);
      if (!mounted) {
        return;
      }
      await HapticFeedback.lightImpact();
      messenger.showSnackBar(
        const SnackBar(content: Text('Published parent profile')),
      );
    } catch (error) {
      ref.invalidate(offlineActionsProvider);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'We couldn\'t publish your parent profile just yet. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _toggleApprovalRequired(bool value) async {
    await ref.read(videoApprovalServiceProvider).setApprovalRequired(value);
    if (!mounted) {
      return;
    }
    setState(() => _approvalRequired = value);
  }

  Future<void> _retryOfflineQueue() async {
    final messenger = ScaffoldMessenger.of(context);
    final actions = await ref.read(offlineActionStoreProvider).load();
    final totalBefore = actions.length;
    final flushed = await ref.read(offlineActionProcessorProvider).flush();
    ref.invalidate(offlineActionsProvider);
    ref.invalidate(shareHistoryProvider);
    ref.invalidate(reportsProvider);
    if (!mounted) {
      return;
    }
    await HapticFeedback.lightImpact();
    final message = switch ((flushed, totalBefore)) {
      (0, 0) => 'No queued actions to retry',
      (0, _) =>
        '$totalBefore action${totalBefore == 1 ? '' : 's'} still waiting — check your connection',
      (_, _) =>
        'Sent $flushed of $totalBefore queued action${totalBefore == 1 ? '' : 's'}',
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveRelay() async {
    final next = _relayController.text.trim();
    if (next.isEmpty) {
      return;
    }
    final relays = await ref.read(nostrServiceProvider).loadRelayList();
    await ref.read(nostrServiceProvider).saveRelayList([...relays, next]);
    _relayController.clear();
    await HapticFeedback.lightImpact();
  }

  Future<void> _removeRelay(String relay) async {
    final relays = await ref.read(nostrServiceProvider).loadRelayList();
    await ref
        .read(nostrServiceProvider)
        .saveRelayList(
          relays.where((item) => item != relay).toList(growable: false),
        );
    await HapticFeedback.lightImpact();
  }

  Future<void> _resetRelays() async {
    await ref
        .read(nostrServiceProvider)
        .saveRelayList(AppConstants.defaultRelays);
    await HapticFeedback.lightImpact();
  }

  Future<void> _reconnectRelays() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(nostrServiceProvider).connect();
    await ref
        .read(syncCoordinatorProvider)
        .refreshSubscriptions(trigger: SyncRefreshTrigger.reconnect);
    await ref.read(offlineActionProcessorProvider).flush();
    ref.invalidate(offlineActionsProvider);
    ref.invalidate(shareHistoryProvider);
    ref.invalidate(reportsProvider);
    if (!mounted) {
      return;
    }
    await HapticFeedback.lightImpact();
    messenger.showSnackBar(const SnackBar(content: Text('Relays reconnected')));
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
    await HapticFeedback.lightImpact();
  }

  Future<void> _publishBlossomServers(List<String> servers) async {
    final messenger = ScaffoldMessenger.of(context);
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
    await HapticFeedback.lightImpact();
    messenger.showSnackBar(
      const SnackBar(content: Text('Published Blossom server list')),
    );
  }

  Future<void> _updatePin() async {
    final messenger = ScaffoldMessenger.of(context);
    final pin = _pinManagementController.text.trim();
    if (pin.length < 4) {
      return;
    }
    await ref.read(parentAuthServiceProvider).setPin(pin);
    _pinManagementController.clear();
    if (!mounted) {
      return;
    }
    await HapticFeedback.lightImpact();
    messenger.showSnackBar(const SnackBar(content: Text('PIN updated')));
  }

  Future<void> _provisionSafetyHq() async {
    final identity = ref.read(parentIdentityProvider).valueOrNull;
    if (identity == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final safetyService = ref.read(safetyHqServiceProvider);
    try {
      await safetyService.queueJoin();
      final group = await safetyService.ensureProvisioned(identity: identity);
      await ref
          .read(syncCoordinatorProvider)
          .refreshSubscriptions(trigger: SyncRefreshTrigger.groupChange);
      final status = await safetyService.refreshEnrollment();
      if (status.isJoined) {
        await ref
            .read(reportCoordinatorProvider)
            .flushQueuedSafetyReports(identity: identity);
      }
      ref.invalidate(safetyHqStatusProvider);
      if (!mounted) {
        return;
      }
      await HapticFeedback.mediumImpact();
      final message = status.isJoined
          ? 'Safety HQ is connected and ready.'
          : group != null
          ? 'Safety HQ is connecting. We sent the setup welcome to the moderation service.'
          : 'Safety HQ is still connecting. Leave the app online for a moment and check again.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      ref.invalidate(safetyHqStatusProvider);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException
                ? error.message
                : 'We couldn\'t set up Safety HQ yet. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _resetApp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out & reset app?'),
          content: const Text(
            'This will remove the saved parent account from this device, clear the Parent Zone PIN, wipe local videos and cached shares, and clear the synced Apple-keychain copy Tubestr uses for automatic restore here. Make sure your recovery key is saved first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reset app'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await _performLocalReset();
  }

  Future<void> _performLocalReset() async {
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _isResettingApp = true);
    try {
      await container.read(syncCoordinatorProvider).stop();
      await container
          .read(appResetServiceProvider)
          .resetApp(
            afterCredentialsCleared: () async {
              container.invalidate(parentIdentityProvider);
              await container.read(parentIdentityProvider.future);
            },
          );
      _refreshProvidersAfterLocalReset(container);

      if (!mounted) {
        return;
      }
      setState(() {
        _isResettingApp = false;
        _isDeletingAccount = false;
        _isUnlocked = false;
        _checkingPin = false;
        _needsPinSetup = false;
        _pinEntry = '';
        _pinError = null;
        _newPin = '';
        _confirmPin = '';
        _sidebarOpen = false;
        _currentInviteKeyPublishInFlight = false;
        _publishedCurrentInviteKeyThisSession = false;
      });
      await HapticFeedback.heavyImpact();
    } catch (error) {
      container.invalidate(syncCoordinatorProvider);
      if (!mounted) {
        return;
      }
      setState(() {
        _isResettingApp = false;
        _isDeletingAccount = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We couldn\'t finish resetting this device yet. Please try again.',
          ),
        ),
      );
    }
  }

  void _refreshProvidersAfterLocalReset(ProviderContainer container) {
    container.invalidate(parentIdentityProvider);
    container.invalidate(parentDisplayNameProvider);
    container.invalidate(profilesProvider);

    container.read(selectedProfileIdProvider.notifier).state = null;
    container.read(appShellTabIndexProvider.notifier).state = 0;
    container.read(pendingDeepLinkProvider.notifier).state = null;
    container.read(pendingParentZoneSectionProvider.notifier).state = null;

    container.invalidate(syncCoordinatorProvider);
    container.invalidate(syncRevisionProvider);
    container.invalidate(videosForSelectedProfileProvider);
    container.invalidate(pendingApprovalVideosProvider);
    container.invalidate(remoteSharesProvider);
    container.invalidate(reportsProvider);
    container.invalidate(offlineActionsProvider);
    container.invalidate(shareHistoryProvider);
    container.invalidate(safetyHqStatusProvider);
    container.invalidate(mdkGroupSummariesProvider);
  }

  Future<void> _deleteParentAccount() async {
    final identity = ref.read(parentIdentityProvider).valueOrNull;
    if (identity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Create or restore the parent account on this device before deleting it.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete parent account?'),
          content: Text(
            'This permanently deletes Tubestr backend account records for ${identity.npub}. This also signs the device out after deletion succeeds. Any App Store or Play subscription must still be cancelled separately in Apple or Google billing settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep account'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete account'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isDeletingAccount = true);
    try {
      await ref
          .read(parentAccountDeletionServiceProvider)
          .deleteAccount(identity: identity);
      if (!mounted) {
        return;
      }
      await _performLocalReset();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parent account deleted from Tubestr backend records.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException
                ? error.message
                : 'We couldn\'t delete the parent account yet. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _openSupportPage() {
    return _openExternalPage(title: 'Support', url: AppConstants.supportUrl);
  }

  Future<void> _openPrivacyPolicy() {
    return _openExternalPage(
      title: 'Privacy Policy',
      url: AppConstants.privacyUrl,
    );
  }

  Future<void> _openTermsPage() {
    return _openExternalPage(title: 'Terms', url: AppConstants.termsUrl);
  }

  Future<void> _openExternalPage({
    required String title,
    required String url,
  }) async {
    await openExternalPageWithFallback(context, title: title, url: url);
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
          unawaited(
            ref
                .read(syncCoordinatorProvider)
                .refreshSubscriptions(trigger: SyncRefreshTrigger.groupChange),
          );
        },
      ),
    );
  }

  Widget _buildSectionContent() {
    return switch (_section) {
      ParentZoneSection.dashboard => ParentZoneDashboardSection(
        onSelectSection: _selectSection,
      ),
      ParentZoneSection.children => ParentZoneChildrenSection(
        nameController: _nameController,
        childTheme: _childTheme,
        approvalRequired: _approvalRequired,
        onThemeSelected: (theme) => setState(() => _childTheme = theme),
        onSaveChild: _saveChild,
        onDeleteChild: _deleteChild,
        onApproveVideo: _approveVideo,
        onRejectVideo: _rejectVideo,
        onToggleApprovalRequired: (value) {
          unawaited(_toggleApprovalRequired(value));
        },
      ),
      ParentZoneSection.familySpaces => ParentZoneFamilySpacesSection(
        mdkDebugFuture: _mdkDebugFuture,
        isGeneratingInvitePacket: _isGeneratingInvitePacket,
        isCreatingWelcome: _isCreatingWelcome,
        isAcceptingWelcome: _isAcceptingWelcome,
        inviteImportController: _inviteImportController,
        onCreateInvite: _createInvite,
        onScanAndProcessInvite: _scanAndProcessInvite,
        onProcessInviteInput: _processInviteInput,
        onAcceptPendingWelcome: _acceptPendingWelcome,
        onRefreshMdkState: _refreshMdkState,
        onManageGroup: _manageGroup,
      ),
      ParentZoneSection.activity => const ParentZoneActivitySection(),
      ParentZoneSection.account => ParentZoneAccountSection(
        displayNameController: _displayNameController,
        pinManagementController: _pinManagementController,
        onSaveDisplayName: _saveDisplayName,
        onPublishDisplayName: _publishDisplayName,
        onUpdatePin: _updatePin,
        onOpenSupport: _openSupportPage,
        onOpenPrivacyPolicy: _openPrivacyPolicy,
        onOpenTerms: _openTermsPage,
        onResetApp: _resetApp,
        onDeleteAccount: _deleteParentAccount,
        isDeletingAccount: _isDeletingAccount || _isResettingApp,
      ),
      ParentZoneSection.network => ParentZoneNetworkSection(
        relayController: _relayController,
        blossomController: _blossomController,
        onRefresh: () => setState(() {}),
        onRetryOfflineQueue: _retryOfflineQueue,
        onSaveRelays: _saveRelay,
        onRemoveRelay: _removeRelay,
        onResetRelays: _resetRelays,
        onReconnectRelays: _reconnectRelays,
        onSaveBlossomServers: _saveBlossomServer,
        onPublishBlossomServers: _publishBlossomServers,
        onProvisionSafetyHq: _provisionSafetyHq,
      ),
      ParentZoneSection.diagnostics => ParentZoneDiagnosticsSection(
        onRefreshPanel: () => setState(() {}),
        onRefreshSubscriptions: () {
          return ref
              .read(syncCoordinatorProvider)
              .refreshSubscriptions(trigger: SyncRefreshTrigger.manual);
        },
      ),
    };
  }

  ThemeData _buildParentZoneTheme(BuildContext context, KidPalette palette) {
    final base = Theme.of(context);
    final shell = Color.alphaBlend(
      palette.accent.withValues(alpha: 0.035),
      palette.backgroundTop,
    );
    final panel = Color.alphaBlend(
      palette.accent.withValues(alpha: 0.045),
      palette.panel,
    );
    final panelBorder = palette.panelBorder;
    final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.nunito(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: palette.ink,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: palette.ink,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: palette.ink,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: palette.ink,
      ),
      titleSmall: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: palette.ink,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: palette.ink,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: palette.ink,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: palette.mutedInk,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: base.colorScheme.onPrimary,
      ),
      labelMedium: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: palette.mutedInk,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: shell,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: panelBorder),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: palette.panel.withValues(alpha: 0.88),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.ink.withValues(alpha: 0.3)),
        ),
      ),
      dividerColor: panelBorder,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: base.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          side: BorderSide(color: panelBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(syncRevisionProvider, (previous, next) {
      if (!mounted) {
        return;
      }
      setState(() {
        _mdkDebugFuture = _loadMdkDebugState();
      });
    });
    final activeTab = ref.watch(appShellTabIndexProvider);
    final pendingDeepLink = ref.watch(pendingDeepLinkProvider);
    if (pendingDeepLink != null &&
        GroupInvitePacket.isSupportedScheme(pendingDeepLink.scheme) &&
        pendingDeepLink != _queuedDeepLinkUri) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _queueDeepLink(pendingDeepLink);
      });
    }
    final pendingSectionName = ref.watch(pendingParentZoneSectionProvider);
    if (pendingSectionName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _consumePendingSectionIfPossible();
      });
    }
    if (activeTab != 3 &&
        !_checkingPin &&
        !_needsPinSetup &&
        (_isUnlocked || _sidebarOpen || _pinEntry.isNotEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lockParentZone();
      });
    }
    if (activeTab != 3) {
      return const SizedBox.expand();
    }

    final palette = ref.watch(activePaletteProvider);
    final parentZoneTheme = _buildParentZoneTheme(context, palette);
    final parentLabel = ref.watch(parentDisplayNameProvider).valueOrNull;
    _syncDisplayNameController(parentLabel);
    if (_checkingPin) {
      return Theme(
        data: parentZoneTheme,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isUnlocked) {
      return Theme(
        data: parentZoneTheme,
        child: Stack(
          children: [
            Positioned.fill(child: _ParentZoneBackground(palette: palette)),
            _needsPinSetup
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
                      final nextEntry = '$_pinEntry$digit';
                      setState(() {
                        _pinEntry = nextEntry;
                        _pinError = null;
                      });
                      if (nextEntry.length == 4) {
                        unawaited(_verifyPin());
                      }
                    },
                    onDelete: () {
                      if (_pinEntry.isNotEmpty) {
                        setState(() {
                          _pinEntry = _pinEntry.substring(
                            0,
                            _pinEntry.length - 1,
                          );
                        });
                      }
                    },
                  ),
          ],
        ),
      );
    }

    return Theme(
      data: parentZoneTheme,
      child: Stack(
        children: [
          Positioned.fill(child: _ParentZoneBackground(palette: palette)),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ParentHeaderButton(
                        icon: Icons.menu_rounded,
                        tooltip: 'Open sections',
                        onPressed: () async {
                          await HapticFeedback.selectionClick();
                          setState(() => _sidebarOpen = true);
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parent Zone',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    letterSpacing: 0.8,
                                    color: palette.mutedInk,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(_section.label),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    height: 1,
                    color: palette.ink.withValues(alpha: 0.08),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.duration(
                      context,
                      AppMotion.layoutChange,
                    ),
                    switchInCurve: AppMotion.easeOutQuint,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation =
                          Tween<Offset>(
                            begin: AppMotion.offset(
                              context,
                              const Offset(0.02, 0),
                            ),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: AppMotion.easeOutQuint,
                            ),
                          );
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_section),
                      child: _buildSectionContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_sidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () async {
                  await HapticFeedback.selectionClick();
                  setState(() => _sidebarOpen = false);
                },
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
              ),
            ),
          Builder(
            builder: (context) {
              final sidebarWidth = MediaQuery.sizeOf(context).width < 600
                  ? MediaQuery.sizeOf(context).width * 0.85
                  : 300.0;
              return AnimatedPositioned(
                duration: AppMotion.duration(context, AppMotion.layoutChange),
                curve: AppMotion.easeOutQuint,
                left: _sidebarOpen ? 0 : -sidebarWidth,
                top: 0,
                bottom: 0,
                width: sidebarWidth,
                child: ParentZoneSidebar(
                  palette: palette,
                  parentLabel:
                      (parentLabel == null || parentLabel.trim().isEmpty)
                      ? 'Family controls'
                      : parentLabel.trim(),
                  accountHint: _needsPinSetup
                      ? 'PIN setup required'
                      : 'Protected by parent PIN',
                  selected: _section,
                  onSelect: (section) async {
                    await HapticFeedback.selectionClick();
                    _selectSection(section, closeSidebar: true);
                  },
                ),
              );
            },
          ),
          if (_isResettingApp)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.28),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _ParentZoneBackground extends StatelessWidget {
  const _ParentZoneBackground({required this.palette});

  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(
              palette.accent.withValues(alpha: 0.03),
              palette.backgroundTop,
            ),
            Color.alphaBlend(
              palette.accentSecondary.withValues(alpha: 0.04),
              palette.backgroundBottom,
            ),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    palette.accent.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: palette.ink.withValues(alpha: 0.03)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentHeaderButton extends StatelessWidget {
  const _ParentHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor =
        theme.textTheme.titleMedium?.color ?? theme.colorScheme.onSurface;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _GroupModerationSheet extends ConsumerStatefulWidget {
  const _GroupModerationSheet({required this.group, required this.onChanged});

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
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _working = true);
    try {
      await ref
          .read(moderationCoordinatorProvider)
          .deleteSharedVideo(
            identity: identity,
            projection: projection,
            reason: 'Removed by parent moderator',
          );
      if (!mounted) {
        return;
      }
      setState(() => _working = false);
      _refresh();
      await HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        SnackBar(content: Text('Deleted ${projection.title} for this family')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _working = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'We couldn\'t delete that shared video just yet. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _removeMember(String memberPubkeyHex) async {
    final identity = ref.read(parentIdentityProvider).valueOrNull;
    if (identity == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _working = true);
    try {
      await ref
          .read(moderationCoordinatorProvider)
          .removeMember(
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
      await HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        const SnackBar(content: Text('Removed member from family group')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _working = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'We couldn\'t remove that member just yet. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(activePaletteProvider);
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
                child: const Center(
                  child: Text(
                    'Moderation details need another moment to load.',
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    'Moderation Controls',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 0.8,
                      color: palette.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.group.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Delete shared videos or remove family members. These are separate actions.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.panel.withValues(alpha: 0.76),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.panelBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            _MemberTile(
                              memberPublicKeyHex: member,
                              currentIdentityHex: identity?.publicKeyHex,
                              working: _working,
                              onRemove: () => _removeMember(member),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.panel.withValues(alpha: 0.76),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.panelBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            _ModerationVideoRow(
                              share: share,
                              palette: palette,
                              working: _working,
                              onDelete: share.status == 'deleted'
                                  ? null
                                  : () => _deleteVideo(share),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Removing a member does not delete their past content automatically.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
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
  const _GroupModerationSnapshot({required this.members, required this.shares});

  final List<String> members;
  final List<RemoteShareProjection> shares;
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.memberPublicKeyHex,
    required this.currentIdentityHex,
    required this.working,
    required this.onRemove,
  });

  final String memberPublicKeyHex;
  final String? currentIdentityHex;
  final bool working;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);
    final isCurrentIdentity = memberPublicKeyHex == currentIdentityHex;
    final profile = isCurrentIdentity
        ? null
        : ref
              .watch(resolvedParentProfileProvider(memberPublicKeyHex))
              .valueOrNull;
    final displayKey = formatPublicKeyLabel(memberPublicKeyHex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (isCurrentIdentity ? palette.success : palette.accent)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCurrentIdentity
                  ? Icons.verified_user_rounded
                  : Icons.person_outline_rounded,
              color: isCurrentIdentity ? palette.success : palette.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentIdentity
                      ? 'You'
                      : (profile?.displayName.trim().isNotEmpty ?? false)
                      ? profile!.displayName
                      : formatCompactPublicKeyLabel(memberPublicKeyHex),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  isCurrentIdentity ? 'Current parent identity' : displayKey,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (!isCurrentIdentity)
            FilledButton.tonal(
              onPressed: working ? null : onRemove,
              child: Text(working ? 'Working…' : 'Remove'),
            ),
        ],
      ),
    );
  }
}

class _ModerationVideoRow extends StatelessWidget {
  const _ModerationVideoRow({
    required this.share,
    required this.palette,
    required this.working,
    required this.onDelete,
  });

  final RemoteShareProjection share;
  final KidPalette palette;
  final bool working;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final deleted = share.status == 'deleted';
    final tone = deleted ? palette.warning : palette.accentSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              deleted
                  ? Icons.delete_outline_rounded
                  : Icons.play_circle_outline_rounded,
              color: tone,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${share.displayName} · ${share.status}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (deleted)
            Text('Deleted', style: Theme.of(context).textTheme.bodySmall)
          else
            FilledButton.tonal(
              onPressed: working ? null : onDelete,
              child: Text(working ? 'Working…' : 'Delete'),
            ),
        ],
      ),
    );
  }
}
