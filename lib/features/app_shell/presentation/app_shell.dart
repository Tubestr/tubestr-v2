import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/deep_link_service.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../l10n/l10n.dart';
import '../../../services/sync/sync_coordinator.dart';
import '../../../shared_ui/components/nook_decorations.dart';
import '../../capture/presentation/capture_page.dart';
import '../../editor_hub/presentation/editor_hub_page.dart';
import '../../home_feed/presentation/home_feed_page.dart';
import '../../parent_zone/presentation/parent_zone_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPinSetup();
    ref.read(syncCoordinatorProvider).start();
    _bindDeepLinks();
    unawaited(_startBackgroundTasks());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeBackgroundTasks());
    }
  }

  Future<void> _checkPinSetup() async {
    final hasPin = await ref.read(parentAuthServiceProvider).hasPin();
    if (!hasPin && mounted) {
      ref.read(appShellTabIndexProvider.notifier).state = 3;
    }
  }

  Future<void> _startBackgroundTasks() async {
    await _hydrateUserLists();
    await _reconcileSafetyHq();
    await _flushOperationalQueues();
    ref.invalidate(resolvedParentProfileProvider);
  }

  Future<void> _flushOperationalQueues() async {
    await ref.read(offlineActionProcessorProvider).flush();
    ref.invalidate(reportsProvider);
    ref.invalidate(offlineActionsProvider);
    ref.invalidate(shareHistoryProvider);
  }

  Future<void> _resumeBackgroundTasks() async {
    await ref
        .read(syncCoordinatorProvider)
        .refreshSubscriptions(trigger: SyncRefreshTrigger.resume);
    await _hydrateUserLists();
    await _reconcileSafetyHq();
    await _flushOperationalQueues();
    ref.invalidate(resolvedParentProfileProvider);
  }

  Future<void> _hydrateUserLists() async {
    final identity = await ref.read(identityServiceProvider).loadIdentity();
    if (identity == null) {
      return;
    }
    try {
      await ref
          .read(userListSyncServiceProvider)
          .hydrateFromRelays(identity: identity);
    } catch (_) {
      // Hydrate is best-effort; never block startup/resume.
    }
    ref.invalidate(relayListProvider);
    ref.invalidate(blossomServerListProvider);
  }

  Future<void> _reconcileSafetyHq() async {
    final identity = await ref.read(identityServiceProvider).loadIdentity();
    if (identity == null) {
      ref.invalidate(safetyHqStatusProvider);
      return;
    }

    try {
      final safetyService = ref.read(safetyHqServiceProvider);
      final statusBefore = await safetyService.refreshEnrollment();
      if (statusBefore.isQueued || statusBefore.isProvisioning) {
        final safetyGroup = await safetyService.ensureProvisioned(
          identity: identity,
        );
        if (safetyGroup != null || statusBefore.isProvisioning) {
          await ref
              .read(syncCoordinatorProvider)
              .refreshSubscriptions(trigger: SyncRefreshTrigger.groupChange);
        }
      }

      final statusAfter = await safetyService.refreshEnrollment();
      if (statusAfter.isJoined) {
        await ref
            .read(reportCoordinatorProvider)
            .flushQueuedSafetyReports(identity: identity);
      }
    } catch (_) {
      // Safety HQ setup should never block the rest of app startup or resume work.
    }
    ref.invalidate(safetyHqStatusProvider);
  }

  void _bindDeepLinks() {
    final deepLinkService = ref.read(deepLinkServiceProvider);
    unawaited(_handleInitialDeepLink(deepLinkService));
    _deepLinkSubscription = deepLinkService.uriStream.listen(_handleDeepLink);
  }

  Future<void> _handleInitialDeepLink(DeepLinkService deepLinkService) async {
    final initialUri = await deepLinkService.getInitialUri();
    if (initialUri == null || !mounted) {
      return;
    }
    _handleDeepLink(initialUri);
  }

  void _handleDeepLink(Uri uri) {
    final deepLink = parseAppDeepLink(uri);
    if (deepLink == null || !mounted) {
      return;
    }

    ref.read(pendingDeepLinkProvider.notifier).state = uri;
    switch (deepLink.destination) {
      case AppDeepLinkDestination.parentZone:
        ref.read(appShellTabIndexProvider.notifier).state = 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(appShellTabIndexProvider);
    final theme = ref.watch(activeThemeProvider);
    final palette = ref.watch(activePaletteProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    const tabChildren = [
      HomeFeedContent(),
      CaptureContent(),
      EditorHubContent(),
      ParentZoneContent(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Themed background (hidden behind capture camera)
          Positioned.fill(
            child: NookAppBackground(palette: palette, theme: theme),
          ),

          // Tab content
          IndexedStack(index: tab, children: tabChildren),

          // Custom bottom tab bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _CustomTabBar(
              currentIndex: tab,
              palette: palette,
              bottomPadding: bottomPad,
              onTap: (i) =>
                  ref.read(appShellTabIndexProvider.notifier).state = i,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomTabBar extends StatelessWidget {
  const _CustomTabBar({
    required this.currentIndex,
    required this.palette,
    required this.bottomPadding,
    required this.onTap,
  });

  final int currentIndex;
  final KidPalette palette;
  final double bottomPadding;
  final ValueChanged<int> onTap;

  static const _tabs = [
    (icon: Icons.home_rounded, kind: _TabKind.standard),
    (icon: Icons.videocam_rounded, kind: _TabKind.capture),
    (icon: Icons.auto_awesome, kind: _TabKind.standard),
    (icon: Icons.shield_rounded, kind: _TabKind.control),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          palette.accent.withValues(alpha: 0.04),
          palette.panel.withValues(alpha: 0.96),
        ),
        border: Border(top: BorderSide(color: palette.panelBorder, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding + 8),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++) ...[
            if (i == 3) ...[
              // Visual separator before parent tab
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 1,
                  height: 28,
                  color: palette.panelBorder,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: _TabButton(
                icon: _tabs[i].icon,
                label: _tabLabel(context, i),
                kind: _tabs[i].kind,
                isActive: i == currentIndex,
                palette: palette,
                onTap: () {
                  if (i == currentIndex) {
                    return;
                  }
                  HapticFeedback.selectionClick();
                  onTap(i);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _tabLabel(BuildContext context, int index) => switch (index) {
    0 => context.l10n.tabHome,
    1 => context.l10n.tabCapture,
    2 => context.l10n.tabStudio,
    _ => context.l10n.tabParent,
  };
}

enum _TabKind { standard, capture, control }

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.kind,
    required this.isActive,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final _TabKind kind;
  final bool isActive;
  final KidPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = switch (kind) {
      _TabKind.capture => palette.mutedInk,
      _TabKind.control => palette.ink.withValues(alpha: 0.78),
      _TabKind.standard => palette.mutedInk,
    };
    final activeBackground = switch (kind) {
      _TabKind.capture => palette.accent.withValues(alpha: 0.18),
      _TabKind.control => palette.accent,
      _TabKind.standard => palette.accent.withValues(alpha: 0.14),
    };
    final color = isActive
        ? switch (kind) {
            _TabKind.capture => palette.accent,
            _TabKind.control => Theme.of(context).colorScheme.onPrimary,
            _TabKind.standard => palette.ink,
          }
        : inactiveColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: isActive ? activeBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? palette.panelBorder : Colors.transparent,
                width: 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color:
                            (kind == _TabKind.capture
                                    ? palette.accent
                                    : palette.ink)
                                .withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: kind == _TabKind.control ? 21 : 23,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: color,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
