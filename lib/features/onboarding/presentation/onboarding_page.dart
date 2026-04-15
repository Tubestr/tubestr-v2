import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../domain/models/parent_identity.dart';
import '../../../shared_ui/components/confetti_view.dart';
import '../../../shared_ui/components/nook_decorations.dart';
import '../../../shared_ui/components/qr_scanner_sheet.dart';
import '../../../shared_ui/components/external_page_view.dart';
import '../../../shared_ui/motion/app_motion.dart';
import '../../app_shell/presentation/app_shell.dart';
import 'models/onboarding_flow_state.dart';
import 'widgets/onboarding_bootstrap_widgets.dart';
import 'widgets/onboarding_step_widgets.dart';

class AppBootstrapPage extends ConsumerStatefulWidget {
  const AppBootstrapPage({super.key});

  @override
  ConsumerState<AppBootstrapPage> createState() => _AppBootstrapPageState();
}

class _AppBootstrapPageState extends ConsumerState<AppBootstrapPage> {
  bool _currentKeyPackagePublishInFlight = false;
  String? _currentKeyPackagePublishedForPubkey;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(betaFunnelServiceProvider).trackAppStarted());
  }

  void _publishCurrentKeyPackageOnce(ParentIdentity identity) {
    if (_currentKeyPackagePublishInFlight ||
        _currentKeyPackagePublishedForPubkey == identity.publicKeyHex) {
      return;
    }
    _currentKeyPackagePublishInFlight = true;
    unawaited(() async {
      try {
        await ref
            .read(familyConnectionServiceProvider)
            .publishCurrentKeyPackage(identity: identity);
        _currentKeyPackagePublishedForPubkey = identity.publicKeyHex;
      } catch (_) {
        _currentKeyPackagePublishedForPubkey = null;
      } finally {
        _currentKeyPackagePublishInFlight = false;
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    final identityAsync = ref.watch(parentIdentityProvider);
    final profilesAsync = ref.watch(profilesProvider);

    return identityAsync.when(
      data: (identity) {
        if (identity != null) {
          _publishCurrentKeyPackageOnce(identity);
        }
        return profilesAsync.when(
          data: (profiles) {
            if (identity == null || profiles.isEmpty) {
              return OnboardingPage(identity: identity);
            }
            final selectedId = ref.watch(selectedProfileIdProvider);
            final profileExists =
                selectedId != null && profiles.any((p) => p.id == selectedId);
            if (!profileExists && profiles.isNotEmpty) {
              Future.microtask(() {
                ref.read(selectedProfileIdProvider.notifier).state =
                    profiles.first.id;
              });
            }
            return const AppShell();
          },
          loading: () => const OnboardingLoadingScreen(),
          error: (error, _) => OnboardingErrorScreen(error: error),
        );
      },
      loading: () => const OnboardingLoadingScreen(),
      error: (error, _) => OnboardingErrorScreen(error: error),
    );
  }
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, required this.identity});

  final ParentIdentity? identity;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  OnboardingFlowState _flow = const OnboardingFlowState();
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _restoreKeyController = TextEditingController();
  final _introController = PageController();
  bool _consentAccepted = false;

  @override
  void initState() {
    super.initState();
    if (widget.identity != null) {
      _flow = _flow.copyWith(step: OnboardingStep.childProfiles);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _birthYearController.dispose();
    _restoreKeyController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != null && widget.identity == null) {
      _nameController.clear();
      _displayNameController.clear();
      _birthYearController.clear();
      _restoreKeyController.clear();
      _consentAccepted = false;
      _flow = const OnboardingFlowState();
    }
  }

  void _goToStep(OnboardingStep step) {
    if (_flow.step != step) {
      HapticFeedback.selectionClick();
    }
    setState(() => _flow = _flow.copyWith(step: step));
  }

  void _setIntroPage(int page) {
    if (_flow.introPage != page) {
      HapticFeedback.selectionClick();
    }
    setState(() => _flow = _flow.copyWith(introPage: page));
  }

  void _setChildTheme(ThemeDescriptor theme) {
    setState(() => _flow = _flow.copyWith(childTheme: theme));
  }

  void _setConsentAccepted(bool value) {
    if (_consentAccepted == value) {
      return;
    }
    setState(() => _consentAccepted = value);
  }

  String? _parentEligibilityMessage() {
    final trimmedYear = _birthYearController.text.trim();
    final currentYear = DateTime.now().year;
    if (trimmedYear.isEmpty) {
      return 'Enter the parent account holder\'s birth year before continuing.';
    }

    final birthYear = int.tryParse(trimmedYear);
    if (birthYear == null || trimmedYear.length != 4) {
      return 'Enter a valid four-digit birth year.';
    }
    if (birthYear < 1900 || birthYear > currentYear) {
      return 'Enter a birth year between 1900 and $currentYear.';
    }
    if (currentYear - birthYear < 18) {
      return 'Tubestr parent accounts must be created by an adult who is 18 or older.';
    }
    if (!_consentAccepted) {
      return 'Confirm the parent consent statement before generating the parent key.';
    }
    return null;
  }

  Future<void> _openPrivacyPolicy() async {
    await openExternalPageWithFallback(
      context,
      title: 'Privacy Policy',
      url: AppConstants.privacyUrl,
    );
  }

  void _refreshParentState() {
    ref.invalidate(parentIdentityProvider);
    ref.invalidate(parentDisplayNameProvider);
    ref.invalidate(offlineActionsProvider);
  }

  Future<void> _createIdentity() async {
    final messenger = ScaffoldMessenger.of(context);
    final eligibilityMessage = _parentEligibilityMessage();
    if (eligibilityMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(eligibilityMessage)));
      return;
    }
    setState(() => _flow = _flow.copyWith(busy: true));
    try {
      final identity = await ref
          .read(identityServiceProvider)
          .createParentIdentity();
      final displayName = _displayNameController.text.trim();
      if (displayName.isNotEmpty) {
        try {
          await ref
              .read(parentProfileServiceProvider)
              .publishLocalProfile(
                identity: identity,
                displayName: displayName,
              );
        } catch (_) {
          // Non-blocking by product decision; queued retry handles offline cases.
        }
      }
      _refreshParentState();
      if (!mounted) {
        return;
      }
      await HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Parent key created. Save your backup before you continue.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _flow = _flow.copyWith(busy: false));
      }
    }
  }

  Future<void> _restoreIdentity() async {
    setState(() {
      _flow = _flow.copyWith(
        busy: true,
        step: OnboardingStep.recovery,
        recoverySucceeded: null,
        recoveryMessage: 'Checking your saved parent key...',
      );
    });
    try {
      await ref
          .read(identityServiceProvider)
          .importParentIdentity(_restoreKeyController.text);
      _refreshParentState();
      if (!mounted) {
        return;
      }
      await HapticFeedback.mediumImpact();
      setState(() {
        _flow = _flow.copyWith(
          busy: false,
          recoverySucceeded: true,
          recoveryMessage:
              'Parent account restored on this device. In v2, child profiles are local, so you can add the children you want on this device next.',
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _flow = _flow.copyWith(
          busy: false,
          recoverySucceeded: false,
          recoveryMessage: _restoreErrorMessage(error),
        );
      });
    }
  }

  Future<void> _scanRestoreKey() async {
    final scanned = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const QrScannerSheet(
        title: 'Scan Backup Key',
        instructions: 'Point the camera at your saved parent backup QR code.',
      ),
    );
    if (!mounted || scanned == null || scanned.isEmpty) {
      return;
    }
    _restoreKeyController.text = scanned;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup key added. Restore when you are ready.'),
      ),
    );
  }

  String _restoreErrorMessage(Object error) {
    if (error is FormatException) {
      return 'That backup key doesn\'t look complete yet. Paste the full `nsec1...` key or 64-character backup key and try again.';
    }
    return 'We could not restore that backup key yet. Please double-check it and try again.';
  }

  Future<bool> _addChild({bool showValidationMessage = false}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (showValidationMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a child name before continuing.'),
          ),
        );
      }
      return false;
    }
    setState(() => _flow = _flow.copyWith(busy: true));
    try {
      await ref
          .read(identityServiceProvider)
          .createChildProfile(name: name, theme: _flow.childTheme);
      if (!mounted) {
        return true;
      }
      ref.invalidate(profilesProvider);
      unawaited(
        ref
            .read(betaFunnelServiceProvider)
            .trackChildProfileCreated(surface: 'onboarding'),
      );
      _nameController.clear();
      setState(() => _flow = _flow.copyWith(busy: false));
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _flow = _flow.copyWith(busy: false));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not add that child profile yet.'),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _finishChildProfiles(List<Profile> profiles) async {
    if (_flow.busy) {
      return;
    }
    var hasProfiles = profiles.isNotEmpty;
    if (_nameController.text.trim().isNotEmpty) {
      final added = await _addChild(showValidationMessage: true);
      if (!added || !mounted) {
        return;
      }
      hasProfiles = true;
    }
    if (!hasProfiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one child profile to finish setup.'),
        ),
      );
      return;
    }
    _goToStep(OnboardingStep.permissions);
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _flow = _flow.copyWith(busy: true, permissionError: null);
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final controller = CameraController(
          cameras.first,
          ResolutionPreset.low,
          enableAudio: true,
        );
        try {
          await controller.initialize();
        } finally {
          await controller.dispose();
        }
      }
      if (!mounted) {
        return;
      }
      setState(() => _flow = _flow.copyWith(busy: false));
      await _finish();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _flow = _flow.copyWith(
          busy: false,
          permissionError:
              'We could not get camera and microphone access yet. You can try again now or allow them later in Settings.',
        );
      });
    }
  }

  Future<void> _finish() async {
    final onboardingMode =
        widget.identity != null || _flow.recoverySucceeded == true
        ? 'restore_parent'
        : 'new_parent';
    await ref.read(safetyHqServiceProvider).queueJoin();
    unawaited(
      ref
          .read(betaFunnelServiceProvider)
          .trackParentOnboardingCompleted(mode: onboardingMode),
    );
    HapticFeedback.mediumImpact();
    setState(() {
      _flow = _flow.copyWith(
        showCelebration: true,
        step: OnboardingStep.complete,
      );
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        ref.invalidate(parentIdentityProvider);
        ref.invalidate(profilesProvider);
        // Eagerly set the selected profile so it's ready before AppShell builds
        final profiles = ref.read(profilesProvider).valueOrNull ?? const [];
        if (profiles.isNotEmpty) {
          ref.read(selectedProfileIdProvider.notifier).state =
              profiles.first.id;
        }
      }
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _flow = _flow.copyWith(showCelebration: false));
      }
    });
  }

  int get _progressIndex => switch (_flow.step) {
    OnboardingStep.intro => 0,
    OnboardingStep.roleSelect => 0,
    OnboardingStep.parentKey => 1,
    OnboardingStep.restoreKey => 1,
    OnboardingStep.recovery => 1,
    OnboardingStep.childProfiles => 2,
    OnboardingStep.permissions => 3,
    OnboardingStep.complete => 4,
  };

  String? get _progressLabel => switch (_flow.step) {
    OnboardingStep.roleSelect => 'Getting started',
    OnboardingStep.parentKey ||
    OnboardingStep.restoreKey ||
    OnboardingStep.recovery => 'Parent account',
    OnboardingStep.childProfiles => 'Child profiles',
    OnboardingStep.permissions => 'Almost done',
    _ => null,
  };

  Widget _buildCurrentStep({
    required KidPalette palette,
    required List<Profile> profiles,
    required ParentIdentity? identity,
  }) {
    return switch (_flow.step) {
      OnboardingStep.intro => OnboardingIntroSlides(
        key: const ValueKey('intro'),
        controller: _introController,
        page: _flow.introPage,
        palette: palette,
        onPageChanged: _setIntroPage,
        onNext: () {
          if (_flow.introPage < 4) {
            _introController.nextPage(
              duration: AppMotion.duration(context, AppMotion.layoutChange),
              curve: AppMotion.easeOutQuint,
            );
          } else {
            _goToStep(OnboardingStep.roleSelect);
          }
        },
        onSkip: () => _goToStep(OnboardingStep.roleSelect),
      ),
      OnboardingStep.roleSelect => OnboardingRoleSelectStep(
        key: const ValueKey('role'),
        palette: palette,
        onNewParent: () => _goToStep(OnboardingStep.parentKey),
        onRestore: () => _goToStep(OnboardingStep.restoreKey),
      ),
      OnboardingStep.parentKey => OnboardingParentKeyStep(
        key: const ValueKey('parentKey'),
        identity: identity,
        displayNameController: _displayNameController,
        birthYearController: _birthYearController,
        palette: palette,
        busy: _flow.busy,
        consentAccepted: _consentAccepted,
        eligibilityMessage: identity == null
            ? _parentEligibilityMessage()
            : null,
        onGenerate: _createIdentity,
        onBirthYearChanged: (_) => setState(() {}),
        onConsentChanged: _setConsentAccepted,
        onOpenPrivacyPolicy: _openPrivacyPolicy,
        onContinue: () => _goToStep(OnboardingStep.childProfiles),
      ),
      OnboardingStep.restoreKey => OnboardingRestoreKeyStep(
        key: const ValueKey('restoreKey'),
        palette: palette,
        restoreController: _restoreKeyController,
        busy: _flow.busy,
        onRestore: _restoreIdentity,
        onScanQr: _scanRestoreKey,
      ),
      OnboardingStep.recovery => OnboardingRecoveryStep(
        key: const ValueKey('recovery'),
        palette: palette,
        busy: _flow.busy,
        succeeded: _flow.recoverySucceeded,
        message: _flow.recoveryMessage,
        onContinue: _flow.recoverySucceeded == true
            ? () => _goToStep(OnboardingStep.childProfiles)
            : null,
        onTryAgain: _flow.busy
            ? null
            : () => _goToStep(OnboardingStep.restoreKey),
      ),
      OnboardingStep.childProfiles => OnboardingChildProfilesStep(
        key: const ValueKey('childProfiles'),
        palette: palette,
        profiles: profiles,
        nameController: _nameController,
        theme: _flow.childTheme,
        busy: _flow.busy,
        onThemeChanged: _setChildTheme,
        onAdd: () => unawaited(_addChild(showValidationMessage: true)),
        onFinish: () => unawaited(_finishChildProfiles(profiles)),
      ),
      OnboardingStep.permissions => OnboardingPermissionsStep(
        key: const ValueKey('permissions'),
        palette: palette,
        busy: _flow.busy,
        error: _flow.permissionError,
        onAllow: _requestPermissions,
        onSkip: _finish,
      ),
      OnboardingStep.complete => OnboardingCompleteStep(
        key: const ValueKey('complete'),
        palette: palette,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(activeThemeProvider);
    final palette = theme.palette;
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
    final identity =
        ref.watch(parentIdentityProvider).valueOrNull ?? widget.identity;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: NookAppBackground(palette: palette, theme: theme),
          ),
          Positioned.fill(
            child: ConfettiView(
              play: _flow.showCelebration,
              colors: [
                palette.accent,
                palette.accentSecondary,
                palette.success,
                palette.warning,
                palette.panel,
              ],
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  if (_flow.step != OnboardingStep.intro &&
                      _flow.step != OnboardingStep.complete)
                    OnboardingProgressBar(
                      currentStep: _progressIndex,
                      totalSteps: 4,
                      palette: palette,
                      label: _progressLabel,
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
                                const Offset(0, 0.06),
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
                      child: _buildCurrentStep(
                        palette: palette,
                        profiles: profiles,
                        identity: identity,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
