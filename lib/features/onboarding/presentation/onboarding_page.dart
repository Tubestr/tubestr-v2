import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../domain/models/parent_identity.dart';
import '../../../shared_ui/components/confetti_view.dart';
import '../../../shared_ui/components/kid_scaffold.dart';
import '../../../shared_ui/components/nook_decorations.dart';
import '../../app_shell/presentation/app_shell.dart';

// ---------------------------------------------------------------------------
// Bootstrap — decides between onboarding and main shell
// ---------------------------------------------------------------------------

class AppBootstrapPage extends ConsumerWidget {
  const AppBootstrapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(parentIdentityProvider);
    final profilesAsync = ref.watch(profilesProvider);

    return identityAsync.when(
      data: (identity) {
        return profilesAsync.when(
          data: (profiles) {
            if (identity == null || profiles.isEmpty) {
              return OnboardingPage(identity: identity);
            }
            final selectedId = ref.watch(selectedProfileIdProvider);
            if (selectedId == null && profiles.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(selectedProfileIdProvider.notifier).state =
                    profiles.first.id;
              });
            }
            return const AppShell();
          },
          loading: () => const _LoadingScreen(),
          error: (error, _) => _ErrorScreen(error: error),
        );
      },
      loading: () => const _LoadingScreen(),
      error: (error, _) => _ErrorScreen(error: error),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Something went wrong: $error')));
  }
}

// ---------------------------------------------------------------------------
// Onboarding — multi-step flow matching v1 design
// ---------------------------------------------------------------------------

enum _Step { intro, roleSelect, parentKey, childProfiles, complete }

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, required this.identity});

  final ParentIdentity? identity;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  _Step _step = _Step.intro;
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  ThemeDescriptor _childTheme = ThemeDescriptor.campfire;
  bool _busy = false;
  bool _showCelebration = false;
  int _introPage = 0;
  final _introController = PageController();

  @override
  void initState() {
    super.initState();
    if (widget.identity != null) {
      _step = _Step.childProfiles;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _introController.dispose();
    super.dispose();
  }

  void _nextStep(_Step step) => setState(() => _step = step);

  Future<void> _createIdentity() async {
    setState(() => _busy = true);
    final identity = await ref
        .read(identityServiceProvider)
        .createParentIdentity();
    final displayName = _displayNameController.text.trim();
    if (displayName.isNotEmpty) {
      try {
        await ref
            .read(parentProfileServiceProvider)
            .publishLocalProfile(identity: identity, displayName: displayName);
      } catch (_) {
        // Non-blocking by product decision; queued retry handles offline cases.
      }
    }
    ref.invalidate(parentIdentityProvider);
    ref.invalidate(parentDisplayNameProvider);
    ref.invalidate(offlineActionsProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    _nextStep(_Step.childProfiles);
  }

  Future<void> _addChild() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    await ref
        .read(identityServiceProvider)
        .createChildProfile(name: name, theme: _childTheme);
    _nameController.clear();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  void _finish() {
    HapticFeedback.mediumImpact();
    setState(() {
      _showCelebration = true;
      _step = _Step.complete;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        ref.invalidate(parentIdentityProvider);
        ref.invalidate(profilesProvider);
      }
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _showCelebration = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(activeThemeProvider).palette;
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
    final identity =
        ref.watch(parentIdentityProvider).valueOrNull ?? widget.identity;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: NookAppBackground(palette: palette)),
          Positioned.fill(
            child: ConfettiView(
              play: _showCelebration,
              colors: [
                palette.accent,
                palette.accentSecondary,
                palette.success,
                palette.warning,
                palette.panel,
              ],
            ),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: switch (_step) {
                _Step.intro => _IntroSlides(
                  key: const ValueKey('intro'),
                  controller: _introController,
                  page: _introPage,
                  palette: palette,
                  onPageChanged: (p) => setState(() => _introPage = p),
                  onNext: () {
                    if (_introPage < 3) {
                      _introController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _nextStep(_Step.roleSelect);
                    }
                  },
                  onSkip: () => _nextStep(_Step.roleSelect),
                ),
                _Step.roleSelect => _RoleSelect(
                  key: const ValueKey('role'),
                  palette: palette,
                  onNewParent: () => _nextStep(_Step.parentKey),
                  onRestore: null, // not yet implemented
                ),
                _Step.parentKey => _ParentKeyStep(
                  key: const ValueKey('parentKey'),
                  identity: identity,
                  displayNameController: _displayNameController,
                  palette: palette,
                  busy: _busy,
                  onGenerate: _createIdentity,
                ),
                _Step.childProfiles => _ChildProfilesStep(
                  key: const ValueKey('childProfiles'),
                  palette: palette,
                  profiles: profiles,
                  nameController: _nameController,
                  theme: _childTheme,
                  busy: _busy,
                  onThemeChanged: (t) => setState(() => _childTheme = t),
                  onAdd: _addChild,
                  onFinish: profiles.isNotEmpty ? _finish : null,
                ),
                _Step.complete => _CompleteStep(
                  key: const ValueKey('complete'),
                  palette: palette,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Introduction slides
// ---------------------------------------------------------------------------

class _IntroSlides extends StatelessWidget {
  const _IntroSlides({
    super.key,
    required this.controller,
    required this.page,
    required this.palette,
    required this.onPageChanged,
    required this.onNext,
    required this.onSkip,
  });

  final PageController controller;
  final int page;
  final KidPalette palette;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  static const _slides = [
    (
      icon: Icons.auto_awesome,
      title: 'Curated For Kids',
      sub: 'A safe, joyful space for your family\u2019s videos',
    ),
    (
      icon: Icons.videocam_rounded,
      title: 'Create Magical Moments',
      sub: 'Record, edit, and share with the people you trust',
    ),
    (
      icon: Icons.shield_rounded,
      title: 'Stay In Control',
      sub: 'Parent tools for moderation, connections, and privacy',
    ),
    (
      icon: Icons.people_rounded,
      title: 'Private By Design',
      sub: 'No algorithms, no ads\u2014just family',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Skip button
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onPressed: onSkip,
              child: const Text('Skip'),
            ),
          ),
        ),

        Expanded(
          child: PageView.builder(
            controller: controller,
            itemCount: _slides.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, i) {
              final slide = _slides[i];
              final colors = [
                [const Color(0xFFE8794E), const Color(0xFFF9B45E)],
                [const Color(0xFF6E63A8), const Color(0xFFE2C76C)],
                [const Color(0xFF3FAE6F), const Color(0xFF7A684A)],
                [const Color(0xFF9C7AA8), const Color(0xFFF2A7B7)],
              ][i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: Icon(slide.icon, size: 38, color: Colors.white),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      slide.title,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        slide.sub,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final active = i == page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: active ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: active
                    ? palette.accent
                    : palette.accent.withValues(alpha: 0.25),
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Next / Start Setup button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              child: Text(page < 3 ? 'Next' : 'Start Setup'),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Role selection
// ---------------------------------------------------------------------------

class _RoleSelect extends StatelessWidget {
  const _RoleSelect({
    super.key,
    required this.palette,
    required this.onNewParent,
    required this.onRestore,
  });

  final KidPalette palette;
  final VoidCallback onNewParent;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to Nook',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'How would you like to get started?',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: onNewParent,
              icon: const Icon(Icons.auto_awesome),
              label: const Text("I'm a new parent"),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: onRestore,
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Restore my account'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Parent key generation
// ---------------------------------------------------------------------------

class _ParentKeyStep extends StatelessWidget {
  const _ParentKeyStep({
    super.key,
    required this.identity,
    required this.displayNameController,
    required this.palette,
    required this.busy,
    required this.onGenerate,
  });

  final ParentIdentity? identity;
  final TextEditingController displayNameController;
  final KidPalette palette;
  final bool busy;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.accent.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.key_rounded, size: 36, color: palette.accent),
          ),
          const SizedBox(height: 24),
          Text(
            'Parent Identity',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We\u2019ll generate a secure cryptographic key that identifies you as the parent.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: displayNameController,
            decoration: const InputDecoration(
              labelText: 'Parent display name',
              hintText: 'Lee & Emma',
            ),
          ),
          const SizedBox(height: 32),
          if (identity != null) ...[
            FrostCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: palette.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Key Ready',
                        style: TextStyle(
                          color: palette.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    identity!.npub,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: identity!.npub));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy'),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (busy)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing your secure parent key\u2026'),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onGenerate,
                  child: const Text('Generate Parent Key'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4 — Child profile setup
// ---------------------------------------------------------------------------

class _ChildProfilesStep extends StatelessWidget {
  const _ChildProfilesStep({
    super.key,
    required this.palette,
    required this.profiles,
    required this.nameController,
    required this.theme,
    required this.busy,
    required this.onThemeChanged,
    required this.onAdd,
    required this.onFinish,
  });

  final KidPalette palette;
  final List<dynamic> profiles;
  final TextEditingController nameController;
  final ThemeDescriptor theme;
  final bool busy;
  final ValueChanged<ThemeDescriptor> onThemeChanged;
  final VoidCallback onAdd;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ListView(
        children: [
          const SizedBox(height: 40),
          Text(
            'Child Profiles',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add at least one child profile to get started.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
          ),
          const SizedBox(height: 24),

          // Existing children
          if (profiles.isNotEmpty) ...[
            for (final profile in profiles)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FrostCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ThemeDescriptorX.fromStorage(
                            profile.theme,
                          ).palette.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        ThemeDescriptorX.fromStorage(profile.theme).label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],

          // Add child form
          FrostCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Child Profile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Emma',
                  ),
                ),
                const SizedBox(height: 14),
                Text('Theme', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                SegmentedButton<ThemeDescriptor>(
                  segments: [
                    for (final t in ThemeDescriptor.values)
                      ButtonSegment(
                        value: t,
                        label: Text(
                          t.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                  selected: {theme},
                  onSelectionChanged: busy
                      ? null
                      : (s) => onThemeChanged(s.first),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: busy ? null : onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Child Profile'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onFinish,
              child: const Text('Finish Setup'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 5 — Complete
// ---------------------------------------------------------------------------

class _CompleteStep extends StatelessWidget {
  const _CompleteStep({super.key, required this.palette});

  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 72, color: palette.success),
          const SizedBox(height: 24),
          Text(
            'All Set!',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your family\u2019s Nook is ready.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
          ),
        ],
      ),
    );
  }
}
