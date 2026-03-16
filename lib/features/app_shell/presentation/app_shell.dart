import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/deep_link_service.dart';
import '../../../core/theme/theme_descriptor.dart';
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

class _AppShellState extends ConsumerState<AppShell> {
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _checkPinSetup();
    ref.read(syncCoordinatorProvider).start();
    _bindDeepLinks();
    unawaited(_startBackgroundTasks());
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPinSetup() async {
    final hasPin = await ref.read(parentAuthServiceProvider).hasPin();
    if (!hasPin && mounted) {
      ref.read(appShellTabIndexProvider.notifier).state = 3;
    }
  }

  Future<void> _startBackgroundTasks() async {
    final identity = await ref.read(identityServiceProvider).loadIdentity();
    if (identity == null) {
      return;
    }

    final safetyGroup = await ref
        .read(safetyHqServiceProvider)
        .ensureProvisioned(identity: identity);
    if (safetyGroup != null) {
      await ref.read(syncCoordinatorProvider).refreshSubscriptions();
    }
    await ref.read(reportCoordinatorProvider).flushQueuedSafetyReports(
      identity: identity,
    );
    ref.invalidate(safetyHqStatusProvider);
    ref.invalidate(reportsProvider);
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
    final palette = ref.watch(activeThemeProvider).palette;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Themed background (hidden behind capture camera)
          Positioned.fill(child: NookAppBackground(palette: palette)),

          // Tab content
          IndexedStack(
            index: tab,
            children: const [
              HomeFeedContent(),
              CaptureContent(),
              EditorHubContent(),
              ParentZoneContent(),
            ],
          ),

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
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.videocam_rounded, label: 'Capture'),
    (icon: Icons.auto_awesome, label: 'Editor'),
    (icon: Icons.shield_rounded, label: 'Parent Zone'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            border: Border(
              top: BorderSide(color: palette.panelBorder, width: 0.5),
            ),
          ),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                if (i > 0)
                  SizedBox(
                    height: 28,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 0.5,
                      color: palette.panelBorder,
                    ),
                  ),
                Expanded(
                  child: _TabButton(
                    icon: _tabs[i].icon,
                    label: _tabs[i].label,
                    isActive: i == currentIndex,
                    accentColor: palette.accent,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? accentColor : Colors.grey.shade500;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
