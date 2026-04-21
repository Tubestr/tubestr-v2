import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../domain/models/parent_identity.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../../../../shared_ui/motion/app_motion.dart';
import '../../../../shared_ui/components/private_key_export_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_x.dart';
import '../../../../l10n/l10n.dart';

class OnboardingCenteredStep extends StatelessWidget {
  const OnboardingCenteredStep({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - AppSpacing.xxl,
            ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                    right: index < totalSteps - 1 ? AppSpacing.xs : 0,
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

  List<_OnboardingIntroSlideData> _buildSlides(
    AppLocalizations l10n,
    Brightness brightness,
  ) => [
    _OnboardingIntroSlideData(
      icon: Icons.family_restroom_rounded,
      title: l10n.onboardingIntroTitle,
      subtitle: l10n.onboardingIntroSubtitle,
      stepLabel: null,
      palette: ThemeDescriptor.campfire.paletteFor(brightness),
    ),
    _OnboardingIntroSlideData(
      icon: Icons.key_rounded,
      title: l10n.onboardingParentKeyTitle,
      subtitle: l10n.onboardingParentKeySubtitle,
      stepLabel: l10n.onboardingStepOne,
      palette: ThemeDescriptor.starlight.paletteFor(brightness),
    ),
    _OnboardingIntroSlideData(
      icon: Icons.child_care_rounded,
      title: l10n.onboardingKidsTitle,
      subtitle: l10n.onboardingKidsSubtitle,
      stepLabel: l10n.onboardingStepTwo,
      palette: ThemeDescriptor.treehouse.paletteFor(brightness),
    ),
    _OnboardingIntroSlideData(
      icon: Icons.videocam_rounded,
      title: l10n.onboardingCreateTitle,
      subtitle: l10n.onboardingCreateSubtitle,
      stepLabel: l10n.onboardingStepThree,
      palette: ThemeDescriptor.blanketFort.paletteFor(brightness),
    ),
    _OnboardingIntroSlideData(
      icon: Icons.shield_rounded,
      title: l10n.onboardingApproveTitle,
      subtitle: l10n.onboardingApproveSubtitle,
      stepLabel: l10n.onboardingStepFour,
      palette: palette,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final slides = _buildSlides(context.l10n, Theme.of(context).brightness);
    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: palette.mediaSurfaceSubtle,
                foregroundColor: palette.mediaInk,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
              onPressed: onSkip,
              child: Text(context.l10n.actionSkip),
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: controller,
            itemCount: slides.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final slide = slides[index];
              final foreground = slide.palette.onAccent;
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
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxxl,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.cardAll,
                        gradient: LinearGradient(
                          colors: [
                            slide.palette.accent,
                            slide.palette.accentSecondary,
                          ],
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
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: foreground.withValues(alpha: 0.18),
                                borderRadius: AppRadii.pillAll,
                              ),
                              child: Text(
                                slide.stepLabel!,
                                style: TextStyle(
                                  fontSize: AppTextSize.label,
                                  fontWeight: FontWeight.w700,
                                  color: foreground,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
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
                                color: foreground.withValues(alpha: 0.18),
                              ),
                              child: Icon(
                                slide.icon,
                                size: AppIconSize.empty,
                                color: foreground,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxl,
                            ),
                            child: Text(
                              slide.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: foreground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxxl,
                            ),
                            child: Text(
                              slide.subtitle,
                              style: TextStyle(
                                height: 1.4,
                                color: foreground.withValues(alpha: 0.86),
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
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (index) {
            final active = index == page;
            return AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.stateChange),
              curve: AppMotion.easeOutQuint,
              width: active ? AppSpacing.xxl : AppSpacing.sm,
              height: AppSpacing.sm,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              decoration: BoxDecoration(
                borderRadius: AppRadii.xsAll,
                color: active
                    ? palette.accent
                    : palette.accent.withValues(alpha: 0.25),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              child: Text(
                page < slides.length - 1
                    ? context.l10n.actionNext
                    : context.l10n.onboardingGetStarted,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.onboardingWelcomeTitle,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.onboardingRoleSelectSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.section),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: onNewParent,
                icon: const Icon(Icons.auto_awesome),
                label: Text(context.l10n.onboardingCreateNewAccount),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: onRestore,
                icon: const Icon(Icons.restore_rounded),
                label: Text(context.l10n.onboardingHaveBackupKey),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accent.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.key_rounded,
                size: AppIconSize.empty,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              context.l10n.onboardingParentKeyTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.onboardingParentKeyHelp,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: displayNameController,
              enabled: identity == null && !busy,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: context.l10n.onboardingParentDisplayName,
                hintText: context.l10n.onboardingDisplayNameHint,
              ),
            ),
            if (identity == null) ...[
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: birthYearController,
                enabled: !busy,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: onBirthYearChanged,
                decoration: InputDecoration(
                  labelText: context.l10n.onboardingParentBirthYear,
                  hintText: context.l10n.onboardingBirthYearHint,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: palette.surfaceSubtle,
                  borderRadius: AppRadii.xlAll,
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
                          child: InkWell(
                            onTap: busy
                                ? null
                                : () => onConsentChanged(!consentAccepted),
                            borderRadius: AppRadii.smAll,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.md,
                                bottom: AppSpacing.md,
                                right: AppSpacing.sm,
                              ),
                              child: Text(
                                'I am 18 or older and I agree to the Tubestr privacy policy on behalf of any children whose profiles I create.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
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
                        label: Text(context.l10n.onboardingReadPrivacyPolicy),
                      ),
                    ),
                  ],
                ),
              ),
              if (eligibilityMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  eligibilityMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.xxxl),
            if (identity != null) ...[
              OnboardingParentPublicKeyCard(
                identity: identity!,
                palette: palette,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrivateKeyExportCard(
                secret: identity!.nsec,
                title: context.l10n.onboardingBackupKeyCardTitle,
                description:
                    'Save this before you continue. It is the recovery path for your parent account.',
                shareText: _parentBackupShareText(identity!),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: palette.warning.withValues(alpha: 0.10),
                  borderRadius: AppRadii.xlAll,
                ),
                child: Text(
                  context.l10n.onboardingPrivateKeyHelp,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onContinue,
                  child: Text(context.l10n.onboardingContinueChildProfiles),
                ),
              ),
            ] else ...[
              if (busy)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(context.l10n.onboardingPreparingKey),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: eligibilityMessage == null ? onGenerate : null,
                    child: Text(context.l10n.onboardingGenerateParentKey),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.xxl),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
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
                size: AppIconSize.empty,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              context.l10n.onboardingWelcomeBackTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.onboardingRestoreKeySubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            TextField(
              controller: restoreController,
              enabled: !busy,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.l10n.onboardingParentBackupKey,
                hintText: 'nsec1...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onScanQr,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(context.l10n.onboardingScanQrCode),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : onRestore,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: Text(context.l10n.actionRestore),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
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
                        size: AppIconSize.hero,
                        color: stateColor,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              busy
                  ? context.l10n.onboardingRestoringParentAccount
                  : succeeded == true
                  ? context.l10n.onboardingRecoveryComplete
                  : context.l10n.onboardingRecoveryNeedsRetry,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ??
                  'We are checking your parent backup and preparing this device.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (succeeded == true)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: palette.success.withValues(alpha: 0.12),
                  borderRadius: AppRadii.pillAll,
                ),
                child: Text(
                  context.l10n.onboardingParentKeyRecovered,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              alignment: WrapAlignment.center,
              children: [
                if (onTryAgain != null)
                  OutlinedButton(
                    onPressed: onTryAgain,
                    child: Text(context.l10n.actionTryAgain),
                  ),
                FilledButton(
                  onPressed: busy ? null : onContinue,
                  child: Text(
                    succeeded == true
                        ? context.l10n.actionContinue
                        : context.l10n.onboardingRestoreFirst,
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: ListView(
        children: [
          const SizedBox(height: AppSpacing.section),
          Text(
            context.l10n.onboardingWhoFamily,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add a profile for each child. They\'ll each get their own themed space to watch and create videos.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (profiles.isNotEmpty) ...[
            for (final profile in profiles)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FrostCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
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
                          ).paletteFor(Theme.of(context).brightness).accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        context.l10n.themeLabel(
                          ThemeDescriptorX.fromStorage(profile.theme),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
          FrostCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.onboardingAddChildProfile,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameController,
                  enabled: !busy,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: context.l10n.onboardingName,
                    hintText: context.l10n.onboardingChildNameHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.l10n.onboardingTheme,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<ThemeDescriptor>(
                    segments: [
                      for (final themeOption in ThemeDescriptor.values)
                        ButtonSegment(
                          value: themeOption,
                          label: Text(
                            context.l10n.themeLabel(themeOption),
                            style: const TextStyle(fontSize: AppTextSize.label),
                          ),
                        ),
                    ],
                    selected: {theme},
                    onSelectionChanged: busy
                        ? null
                        : (selection) => onThemeChanged(selection.first),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: busy ? null : onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.l10n.onboardingAddChildProfile),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onFinish,
              child: Text(context.l10n.onboardingComplete),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
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
                size: AppIconSize.hero,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              context.l10n.onboardingOneLastThing,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.onboardingAppPermissionsDetail,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.mutedInk),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FrostCard(
              child: Column(
                children: [
                  OnboardingPermissionRow(
                    icon: Icons.videocam_rounded,
                    title: context.l10n.onboardingCamera,
                    detail: context.l10n.onboardingCameraPermissionDetail,
                    palette: palette,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OnboardingPermissionRow(
                    icon: Icons.mic_rounded,
                    title: context.l10n.onboardingMicrophone,
                    detail: context.l10n.onboardingMicrophonePermissionDetail,
                    palette: palette,
                  ),
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.warning.withValues(alpha: 0.12),
                  borderRadius: AppRadii.lgAll,
                  border: Border.all(
                    color: palette.warning.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: AppTextSize.label,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: busy ? null : onAllow,
                icon: busy
                    ? const SizedBox(
                        width: AppIconSize.md,
                        height: AppIconSize.md,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  busy
                      ? context.l10n.onboardingRequestingAccess
                      : context.l10n.onboardingAllowAccess,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: busy ? null : onSkip,
              child: Text(context.l10n.actionSkipForNow),
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
            borderRadius: AppRadii.mdAll,
          ),
          child: Icon(icon, color: palette.accent),
        ),
        const SizedBox(width: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.xs),
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
            Icon(
              Icons.verified_rounded,
              size: AppIconSize.billboard,
              color: palette.success,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              context.l10n.onboardingCompleteTitle,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.onboardingCompleteSubtitle,
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
                size: AppIconSize.lg,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.l10n.onboardingParentPublicKey,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            identity.npub,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: identity.npub));
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.publicKeyCopied)),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: AppIconSize.sm),
            label: Text(context.l10n.actionCopy),
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
    required this.palette,
    this.stepLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? stepLabel;
  final KidPalette palette;
}

String _parentBackupShareText(ParentIdentity identity) {
  return '''
Tubestr Parent Backup Key

Keep this private. Anyone with this key can control your family account.

${identity.nsec}
''';
}
