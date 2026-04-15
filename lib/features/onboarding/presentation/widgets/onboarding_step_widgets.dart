import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../domain/models/parent_identity.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../../../../shared_ui/motion/app_motion.dart';
import '../../../../shared_ui/components/private_key_export_card.dart';

class OnboardingCenteredStep extends StatelessWidget {
  const OnboardingCenteredStep({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.palette,
    this.label,
  });

  final int currentStep;
  final int totalSteps;
  final KidPalette palette;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: palette.mutedInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotion.stateChange),
                  curve: AppMotion.easeOutQuint,
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < totalSteps - 1 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isCompleted
                        ? palette.accent
                        : isCurrent
                        ? palette.accent.withValues(alpha: 0.55)
                        : palette.accent.withValues(alpha: 0.15),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class OnboardingIntroSlides extends StatelessWidget {
  const OnboardingIntroSlides({
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
    _OnboardingIntroSlideData(
      icon: Icons.family_restroom_rounded,
      title: 'Your Family\'s Private Space',
      subtitle:
          '${AppConstants.appName} is a video app built just for families. No ads, no algorithms, no strangers.',
      stepLabel: null,
      colors: [Color(0xFFE8794E), Color(0xFFF9B45E)],
    ),
    _OnboardingIntroSlideData(
      icon: Icons.key_rounded,
      title: 'Create Your Parent Key',
      subtitle:
          'First, you\'ll set up a secure parent identity. This key is yours alone and controls your family\'s account.',
      stepLabel: 'Step 1',
      colors: [Color(0xFF6E63A8), Color(0xFFE2C76C)],
    ),
    _OnboardingIntroSlideData(
      icon: Icons.child_care_rounded,
      title: 'Add Your Kids',
      subtitle:
          'Create a profile for each child with their own colorful theme. Each kid gets a personalized experience.',
      stepLabel: 'Step 2',
      colors: [Color(0xFF3FAE6F), Color(0xFF7A684A)],
    ),
    _OnboardingIntroSlideData(
      icon: Icons.videocam_rounded,
      title: 'Record & Edit Together',
      subtitle:
          'Kids can capture videos, add stickers, music, and effects in the Edit Studio. Creativity without the risk.',
      stepLabel: 'Step 3',
      colors: [Color(0xFF9C7AA8), Color(0xFFF2A7B7)],
    ),
    _OnboardingIntroSlideData(
      icon: Icons.shield_rounded,
      title: 'You Approve Everything',
      subtitle:
          'Every video goes through you first. Review, approve, and share only with family members you trust.',
      stepLabel: 'Step 4',
      colors: [Color(0xFF4A90D9), Color(0xFF67B8A7)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
            itemBuilder: (context, index) {
              final slide = _slides[index];
              final isActive = index == page;
              return AnimatedScale(
                duration: AppMotion.duration(context, AppMotion.stateChange),
                curve: AppMotion.easeOutQuint,
                scale: isActive ? 1.0 : 0.88,
                child: AnimatedSlide(
                  duration: AppMotion.duration(context, AppMotion.stateChange),
                  curve: AppMotion.easeOutQuint,
                  offset: isActive
                      ? Offset.zero
                      : AppMotion.offset(context, const Offset(0.03, 0.02)),
                  child: AnimatedOpacity(
                    duration: AppMotion.duration(
                      context,
                      AppMotion.stateChange,
                    ),
                    opacity: isActive ? 1 : 0.55,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          colors: slide.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (slide.stepLabel != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                slide.stepLabel!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          AnimatedScale(
                            duration: AppMotion.duration(
                              context,
                              AppMotion.stateChange,
                            ),
                            curve: AppMotion.easeOutQuint,
                            scale: isActive ? 1 : 0.9,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: Icon(
                                slide.icon,
                                size: 38,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              slide.title,
                              style: TextStyle(
                                fontSize: MediaQuery.sizeOf(context).width < 400
                                    ? 26.0
                                    : 30.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              slide.subtitle,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (index) {
            final active = index == page;
            return AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.stateChange),
              curve: AppMotion.easeOutQuint,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              child: Text(
                page < _slides.length - 1 ? 'Next' : 'Let\'s Get Started',
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class OnboardingRoleSelectStep extends StatelessWidget {
  const OnboardingRoleSelectStep({
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
    return OnboardingCenteredStep(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to ${AppConstants.appName}',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'First, we need to create your parent account. This only takes a minute.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: onNewParent,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Create new account'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: onRestore,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('I have a backup key'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingParentKeyStep extends StatelessWidget {
  const OnboardingParentKeyStep({
    super.key,
    required this.identity,
    required this.displayNameController,
    required this.birthYearController,
    required this.palette,
    required this.busy,
    required this.consentAccepted,
    required this.eligibilityMessage,
    required this.onGenerate,
    required this.onBirthYearChanged,
    required this.onConsentChanged,
    required this.onOpenPrivacyPolicy,
    required this.onContinue,
  });

  final ParentIdentity? identity;
  final TextEditingController displayNameController;
  final TextEditingController birthYearController;
  final KidPalette palette;
  final bool busy;
  final bool consentAccepted;
  final String? eligibilityMessage;
  final VoidCallback onGenerate;
  final ValueChanged<String> onBirthYearChanged;
  final ValueChanged<bool> onConsentChanged;
  final Future<void> Function() onOpenPrivacyPolicy;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return OnboardingCenteredStep(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
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
              'Create Your Parent Key',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your parent key is like your family\'s master password. It proves you\'re the parent and lets you manage everything.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: displayNameController,
              enabled: identity == null && !busy,
              decoration: const InputDecoration(
                labelText: 'Parent display name',
                hintText: 'Lee & Emma',
              ),
            ),
            if (identity == null) ...[
              const SizedBox(height: 14),
              TextField(
                controller: birthYearController,
                enabled: !busy,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: onBirthYearChanged,
                decoration: const InputDecoration(
                  labelText: 'Parent birth year',
                  hintText: '1988',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.panel.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: consentAccepted,
                          onChanged: busy
                              ? null
                              : (value) => onConsentChanged(value ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'I am 18 or older and I agree to the Tubestr privacy policy on behalf of any children whose profiles I create.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: busy
                            ? null
                            : () async {
                                await onOpenPrivacyPolicy();
                              },
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Read privacy policy'),
                      ),
                    ),
                  ],
                ),
              ),
              if (eligibilityMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  eligibilityMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 32),
            if (identity != null) ...[
              OnboardingParentPublicKeyCard(
                identity: identity!,
                palette: palette,
              ),
              const SizedBox(height: 16),
              PrivateKeyExportCard(
                secret: identity!.nsec,
                title: 'Parent backup key',
                description:
                    'Save this before you continue. It is the recovery path for your parent account.',
                shareText: _parentBackupShareText(identity!),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Your private key is the master backup for this parent account. Save it somewhere safe before continuing.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onContinue,
                  child: const Text('Continue to Child Profiles'),
                ),
              ),
            ] else ...[
              if (busy)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Preparing your secure parent key...'),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: eligibilityMessage == null ? onGenerate : null,
                    child: const Text('Generate Parent Key'),
                  ),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class OnboardingRestoreKeyStep extends StatelessWidget {
  const OnboardingRestoreKeyStep({
    super.key,
    required this.palette,
    required this.restoreController,
    required this.busy,
    required this.onRestore,
    required this.onScanQr,
  });

  final KidPalette palette;
  final TextEditingController restoreController;
  final bool busy;
  final VoidCallback onRestore;
  final VoidCallback onScanQr;

  @override
  Widget build(BuildContext context) {
    return OnboardingCenteredStep(
      child: Padding(
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
              child: Icon(
                Icons.restore_rounded,
                size: 36,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome Back',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Paste your saved `nsec1...` key or 64-character backup key. You can also scan the QR code if you saved one. If this device still has your parent account saved in secure storage or synced Apple Keychain, ${AppConstants.appName} will pick it up automatically on launch.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: restoreController,
              enabled: !busy,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Parent backup key',
                hintText: 'nsec1...',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onScanQr,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan QR Code'),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : onRestore,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('Restore'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingRecoveryStep extends StatelessWidget {
  const OnboardingRecoveryStep({
    super.key,
    required this.palette,
    required this.busy,
    required this.succeeded,
    required this.message,
    required this.onContinue,
    required this.onTryAgain,
  });

  final KidPalette palette;
  final bool busy;
  final bool? succeeded;
  final String? message;
  final VoidCallback? onContinue;
  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) {
    final stateColor = succeeded == false ? palette.warning : palette.success;

    return OnboardingCenteredStep(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stateColor.withValues(alpha: 0.12),
              ),
              child: Center(
                child: busy
                    ? const CircularProgressIndicator()
                    : Icon(
                        succeeded == true
                            ? Icons.verified_rounded
                            : Icons.warning_amber_rounded,
                        size: 42,
                        color: stateColor,
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              busy
                  ? 'Restoring your parent account'
                  : succeeded == true
                  ? 'Recovery complete'
                  : 'Recovery needs another try',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message ??
                  'We are checking your parent backup and preparing this device.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (succeeded == true)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: palette.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Parent key recovered',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (onTryAgain != null)
                  OutlinedButton(
                    onPressed: onTryAgain,
                    child: const Text('Try again'),
                  ),
                FilledButton(
                  onPressed: busy ? null : onContinue,
                  child: Text(succeeded == true ? 'Continue' : 'Restore first'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingChildProfilesStep extends StatelessWidget {
  const OnboardingChildProfilesStep({
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
  final List<Profile> profiles;
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
            'Who\'s in Your Family?',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a profile for each child. They\'ll each get their own themed space to watch and create videos.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
          ),
          const SizedBox(height: 24),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<ThemeDescriptor>(
                    segments: [
                      for (final themeOption in ThemeDescriptor.values)
                        ButtonSegment(
                          value: themeOption,
                          label: Text(
                            themeOption.label,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                    selected: {theme},
                    onSelectionChanged: busy
                        ? null
                        : (selection) => onThemeChanged(selection.first),
                  ),
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
              child: const Text('Complete Onboarding'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class OnboardingPermissionsStep extends StatelessWidget {
  const OnboardingPermissionsStep({
    super.key,
    required this.palette,
    required this.busy,
    required this.error,
    required this.onAllow,
    required this.onSkip,
  });

  final KidPalette palette;
  final bool busy;
  final String? error;
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return OnboardingCenteredStep(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accent.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.perm_camera_mic_rounded,
                size: 40,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'One Last Thing',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppConstants.appName} uses the camera for recording videos and scanning family invites, and the microphone for video sound.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
            ),
            const SizedBox(height: 24),
            FrostCard(
              child: Column(
                children: [
                  OnboardingPermissionRow(
                    icon: Icons.videocam_rounded,
                    title: 'Camera',
                    detail: 'Record clips and scan invite QR codes.',
                    palette: palette,
                  ),
                  const SizedBox(height: 12),
                  OnboardingPermissionRow(
                    icon: Icons.mic_rounded,
                    title: 'Microphone',
                    detail: 'Capture audio while recording videos.',
                    palette: palette,
                  ),
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: palette.warning.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: busy ? null : onAllow,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(busy ? 'Requesting Access...' : 'Allow Access'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: busy ? null : onSkip,
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPermissionRow extends StatelessWidget {
  const OnboardingPermissionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.palette,
  });

  final IconData icon;
  final String title;
  final String detail;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: palette.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OnboardingCompleteStep extends StatelessWidget {
  const OnboardingCompleteStep({super.key, required this.palette});

  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return OnboardingCenteredStep(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 72, color: palette.success),
            const SizedBox(height: 24),
            Text(
              'You\'re All Set!',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your family\'s ${AppConstants.appName} is ready.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingParentPublicKeyCard extends StatelessWidget {
  const OnboardingParentPublicKeyCard({
    super.key,
    required this.identity,
    required this.palette,
  });

  final ParentIdentity identity;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return FrostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: palette.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Parent public key',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            identity.npub,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: identity.npub));
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Public key copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}

class _OnboardingIntroSlideData {
  const _OnboardingIntroSlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.stepLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? stepLabel;
  final List<Color> colors;
}

String _parentBackupShareText(ParentIdentity identity) {
  return '''
Tubestr Parent Backup Key

Keep this private. Anyone with this key can control your family account.

${identity.nsec}
''';
}
