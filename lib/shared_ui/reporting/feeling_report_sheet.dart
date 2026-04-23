import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/theme/radii.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_descriptor.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';

enum ReportFeeling {
  uncomfortable('😕', 'inappropriate', 1),
  sad('😢', 'harassment', 1),
  confused('🤔', 'inappropriate', 2),
  scared('😨', 'unsafe', 2),
  angry('😠', 'illegal', 3);

  const ReportFeeling(this.emoji, this.reason, this.minimumLevel);

  final String emoji;
  final String reason;
  final int minimumLevel;

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    ReportFeeling.uncomfortable => l10n.reportFeelingUncomfortable,
    ReportFeeling.sad => l10n.reportFeelingSad,
    ReportFeeling.confused => l10n.reportFeelingConfused,
    ReportFeeling.scared => l10n.reportFeelingScared,
    ReportFeeling.angry => l10n.reportFeelingAngry,
  };
}

enum ReportActionOption {
  tellThem(icon: Icons.pan_tool_alt_rounded, level: 1),
  hideVideos(icon: Icons.visibility_off_rounded, level: 2),
  blockThem(icon: Icons.gpp_bad_rounded, level: 3);

  const ReportActionOption({required this.icon, required this.level});

  final IconData icon;
  final int level;

  String localizedTitle(AppLocalizations l10n) => switch (this) {
    ReportActionOption.tellThem => l10n.reportActionTell,
    ReportActionOption.hideVideos => l10n.reportActionHide,
    ReportActionOption.blockThem => l10n.reportActionBlock,
  };

  String localizedSubtitle(AppLocalizations l10n) => switch (this) {
    ReportActionOption.tellThem => l10n.reportActionTellSubtitle,
    ReportActionOption.hideVideos => l10n.reportActionHideSubtitle,
    ReportActionOption.blockThem => l10n.reportActionBlockSubtitle,
  };
}

class FeelingReportSubmission {
  const FeelingReportSubmission({required this.feeling, required this.action});

  final ReportFeeling feeling;
  final ReportActionOption action;

  int get level =>
      action.level > feeling.minimumLevel ? action.level : feeling.minimumLevel;

  String get recipientType => switch (level) {
    1 => 'local',
    2 => 'local_parent',
    _ => 'family',
  };

  String get destinationLabel => switch (level) {
    1 => 'Stays on this device',
    2 => 'Your parent',
    _ => 'Both families',
  };

  String get levelLabel => switch (level) {
    1 => 'Level 1 · Noted',
    2 => 'Level 2 · Parent help',
    _ => 'Level 3 · Family alert',
  };

  String get helperText => switch (level) {
    1 =>
      'This stays on your device so you can talk about it with a grown-up later.',
    2 => 'This lets your parent know so they can check in with you.',
    _ =>
      'This sends an alert to both families so the grown-ups can sort it out.',
  };

  String get reason => feeling.reason;

  String get note => '${feeling.reason} · ${action.name}';

  String localizedDestinationLabel(AppLocalizations l10n) => switch (level) {
    1 => l10n.reportDestinationLocal,
    2 => l10n.reportDestinationParent,
    _ => l10n.reportDestinationFamily,
  };

  String localizedLevelLabel(AppLocalizations l10n) => switch (level) {
    1 => l10n.reportLevelNoted,
    2 => l10n.reportLevelParentHelp,
    _ => l10n.reportLevelFamilyAlert,
  };

  String localizedHelperText(AppLocalizations l10n) => switch (level) {
    1 => l10n.reportLevelOneExplanation,
    2 => l10n.reportLevelTwoExplanation,
    _ => l10n.reportLevelThreeExplanation,
  };

  String localizedNote(AppLocalizations l10n) =>
      '${feeling.localizedLabel(l10n)} · ${action.localizedTitle(l10n)}';
}

class FeelingReportSheet extends ConsumerStatefulWidget {
  const FeelingReportSheet({super.key, required this.onSubmit});

  final Future<void> Function(FeelingReportSubmission submission) onSubmit;

  @override
  ConsumerState<FeelingReportSheet> createState() => _FeelingReportSheetState();
}

enum _ReportStep { feeling, action, confirm }

class _FeelingReportSheetState extends ConsumerState<FeelingReportSheet> {
  _ReportStep _step = _ReportStep.feeling;
  ReportFeeling? _feeling;
  ReportActionOption? _action;
  bool _submitting = false;

  List<ReportActionOption> get _availableActions {
    final feeling = _feeling;
    if (feeling == null) {
      return const [];
    }
    return ReportActionOption.values
        .where((option) => option.level >= feeling.minimumLevel)
        .toList(growable: false);
  }

  Future<void> _submit() async {
    final feeling = _feeling;
    final action = _action;
    if (feeling == null || action == null) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        FeelingReportSubmission(feeling: feeling, action: action),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = ref.watch(activePaletteProvider);
    return SafeArea(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.surfaceStrong, palette.surfaceRaised],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(top: BorderSide(color: palette.panelBorder)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              if (_step == _ReportStep.feeling) {
                                Navigator.of(context).pop();
                              } else {
                                setState(() {
                                  _step = switch (_step) {
                                    _ReportStep.confirm => _ReportStep.action,
                                    _ReportStep.action => _ReportStep.feeling,
                                    _ReportStep.feeling => _ReportStep.feeling,
                                  };
                                });
                              }
                            },
                      icon: Icon(
                        _step == _ReportStep.feeling
                            ? Icons.close_rounded
                            : Icons.arrow_back_rounded,
                        color: palette.ink,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(3, (index) {
                        final active = index <= _step.index;
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? palette.accent
                                : palette.panelBorder,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    const SizedBox(width: AppSpacing.section),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (_step) {
                    _ReportStep.feeling => _FeelingStep(
                      key: const ValueKey('feeling'),
                      theme: theme,
                      palette: palette,
                      selected: _feeling,
                      onSelected: (feeling) async {
                        setState(() {
                          _feeling = feeling;
                          _action = null;
                        });
                        await Future<void>.delayed(
                          const Duration(milliseconds: 220),
                        );
                        if (mounted) {
                          setState(() => _step = _ReportStep.action);
                        }
                      },
                    ),
                    _ReportStep.action => _ActionStep(
                      key: const ValueKey('action'),
                      theme: theme,
                      palette: palette,
                      feeling: _feeling!,
                      selected: _action,
                      options: _availableActions,
                      onSelected: (action) {
                        setState(() => _action = action);
                      },
                      onNext: _action == null
                          ? null
                          : () => setState(() => _step = _ReportStep.confirm),
                    ),
                    _ReportStep.confirm => _ConfirmStep(
                      key: const ValueKey('confirm'),
                      theme: theme,
                      palette: palette,
                      feeling: _feeling!,
                      action: _action!,
                      submitting: _submitting,
                      onSubmit: _submit,
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeelingStep extends StatelessWidget {
  const _FeelingStep({
    super.key,
    required this.theme,
    required this.palette,
    required this.selected,
    required this.onSelected,
  });

  final ThemeData theme;
  final KidPalette palette;
  final ReportFeeling? selected;
  final ValueChanged<ReportFeeling> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🎬', style: TextStyle(fontSize: AppTextSize.emojiDisplay)),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.reportFeelingPrompt,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: palette.ink,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          children: [
            for (final feeling in ReportFeeling.values)
              _FeelingButton(
                feeling: feeling,
                palette: palette,
                selected: selected == feeling,
                onTap: () => onSelected(feeling),
              ),
          ],
        ),
      ],
    );
  }
}

class _ActionStep extends StatelessWidget {
  const _ActionStep({
    super.key,
    required this.theme,
    required this.palette,
    required this.feeling,
    required this.selected,
    required this.options,
    required this.onSelected,
    required this.onNext,
  });

  final ThemeData theme;
  final KidPalette palette;
  final ReportFeeling feeling;
  final ReportActionOption? selected;
  final List<ReportActionOption> options;
  final ValueChanged<ReportActionOption> onSelected;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                feeling.emoji,
                style: const TextStyle(fontSize: AppTextSize.emojiLarge),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                feeling.localizedLabel(context.l10n),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: palette.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          context.l10n.reportActionPrompt,
          style: theme.textTheme.titleLarge?.copyWith(
            color: palette.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final option in options)
          _ActionButton(
            option: option,
            palette: palette,
            selected: selected == option,
            onTap: () => onSelected(option),
          ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onNext,
            child: Text(context.l10n.actionNext),
          ),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    super.key,
    required this.theme,
    required this.palette,
    required this.feeling,
    required this.action,
    required this.submitting,
    required this.onSubmit,
  });

  final ThemeData theme;
  final KidPalette palette;
  final ReportFeeling feeling;
  final ReportActionOption action;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final submission = FeelingReportSubmission(
      feeling: feeling,
      action: action,
    );
    final accent = palette.reportAccentForLevel(submission.level);
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          feeling.emoji,
          style: const TextStyle(fontSize: AppTextSize.emojiHero),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.reportConfirmPrompt,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: palette.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          submission.localizedLevelLabel(context.l10n),
          style: theme.textTheme.titleMedium?.copyWith(color: palette.mutedInk),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: AppRadii.pillAll,
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Text(
            submission.localizedDestinationLabel(context.l10n),
            style: theme.textTheme.labelLarge?.copyWith(
              color: palette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          submission.localizedHelperText(context.l10n),
          style: theme.textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: submitting ? null : onSubmit,
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.actionSend),
          ),
        ),
      ],
    );
  }
}

class _FeelingButton extends StatelessWidget {
  const _FeelingButton({
    required this.feeling,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final ReportFeeling feeling;
  final KidPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.surfacePressed : palette.surfaceSubtle,
      borderRadius: AppRadii.xlAll,
      child: InkWell(
        borderRadius: AppRadii.xlAll,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              feeling.emoji,
              style: const TextStyle(fontSize: AppTextSize.emoji),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              feeling.localizedLabel(context.l10n),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.option,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final ReportActionOption option;
  final KidPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = palette.reportAccentForLevel(option.level);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.22)
            : palette.surfaceSubtle,
        borderRadius: AppRadii.xlAll,
        child: InkWell(
          borderRadius: AppRadii.xlAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(option.icon, color: accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.localizedTitle(context.l10n),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        option.localizedSubtitle(context.l10n),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: palette.mutedInk),
                      ),
                    ],
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
