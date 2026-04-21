import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../../../../shared_ui/components/nook_decorations.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';

class OnboardingLoadingScreen extends ConsumerWidget {
  const OnboardingLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(activeThemeProvider);
    final palette = ref.watch(activePaletteProvider);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: NookAppBackground(palette: palette, theme: theme),
          ),
          SafeArea(
            child: OnboardingBootstrapStatusCard(
              palette: palette,
              icon: Icons.hourglass_top_rounded,
              title: context.l10n.onboardingOpeningApp,
              message: context.l10n.onboardingOpeningAppDetail,
              child: const CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingErrorScreen extends ConsumerWidget {
  const OnboardingErrorScreen({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(activeThemeProvider);
    final palette = ref.watch(activePaletteProvider);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: NookAppBackground(palette: palette, theme: theme),
          ),
          SafeArea(
            child: OnboardingBootstrapStatusCard(
              palette: palette,
              icon: Icons.refresh_rounded,
              title: context.l10n.onboardingBootstrapNeedsMoment,
              message: _friendlyBootstrapError(error, context.l10n),
              child: FilledButton.icon(
                onPressed: () {
                  ref.invalidate(parentIdentityProvider);
                  ref.invalidate(profilesProvider);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.actionTryAgain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingBootstrapStatusCard extends StatelessWidget {
  const OnboardingBootstrapStatusCard({
    super.key,
    required this.palette,
    required this.icon,
    required this.title,
    required this.message,
    required this.child,
  });

  final KidPalette palette;
  final IconData icon;
  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FrostCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.accent.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, size: 36, color: palette.accent),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _friendlyBootstrapError(Object error, AppLocalizations l10n) {
  final message = error.toString().toLowerCase();
  if (message.contains('secure') || message.contains('storage')) {
    return l10n.onboardingBootstrapReachFailed;
  }
  if (message.contains('database') || message.contains('sqlite')) {
    return l10n.onboardingBootstrapLibraryMoment;
  }
  return l10n.onboardingBootstrapGeneric;
}
