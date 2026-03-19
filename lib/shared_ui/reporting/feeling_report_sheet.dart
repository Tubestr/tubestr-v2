import 'package:flutter/material.dart';

enum ReportFeeling {
  uncomfortable('😕', 'Feels Weird', 'inappropriate', 1),
  sad('😢', 'Makes Me Sad', 'harassment', 1),
  confused('🤔', 'Confusing', 'inappropriate', 2),
  scared('😨', 'Scary', 'unsafe', 2),
  angry('😠', 'Really Bad', 'illegal', 3);

  const ReportFeeling(this.emoji, this.label, this.reason, this.minimumLevel);

  final String emoji;
  final String label;
  final String reason;
  final int minimumLevel;
}

enum ReportActionOption {
  tellThem(
    icon: Icons.pan_tool_alt_rounded,
    title: 'Just Tell Them',
    subtitle: 'Note it for yourself.',
    level: 1,
  ),
  hideVideos(
    icon: Icons.visibility_off_rounded,
    title: 'Hide Their Videos',
    subtitle: 'Let your parent know privately.',
    level: 2,
  ),
  blockThem(
    icon: Icons.gpp_bad_rounded,
    title: 'Block Them',
    subtitle: 'Alert both families.',
    level: 3,
  );

  const ReportActionOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.level,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int level;
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

  String get note => '${feeling.label} · ${action.title}';
}

class FeelingReportSheet extends StatefulWidget {
  const FeelingReportSheet({super.key, required this.onSubmit});

  final Future<void> Function(FeelingReportSubmission submission) onSubmit;

  @override
  State<FeelingReportSheet> createState() => _FeelingReportSheetState();
}

enum _ReportStep { feeling, action, confirm }

class _FeelingReportSheetState extends State<FeelingReportSheet> {
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
    return SafeArea(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF251D38), Color(0xFF171121)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(3, (index) {
                        final active = index <= _step.index;
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (_step) {
                    _ReportStep.feeling => _FeelingStep(
                      key: const ValueKey('feeling'),
                      theme: theme,
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
    required this.selected,
    required this.onSelected,
  });

  final ThemeData theme;
  final ReportFeeling? selected;
  final ValueChanged<ReportFeeling> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🎬', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(
          'How does this video make you feel?',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (final feeling in ReportFeeling.values)
              _FeelingButton(
                feeling: feeling,
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
    required this.feeling,
    required this.selected,
    required this.options,
    required this.onSelected,
    required this.onNext,
  });

  final ThemeData theme;
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
              Text(feeling.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                feeling.label,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'What should we do?',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (final option in options)
          _ActionButton(
            option: option,
            selected: selected == option,
            onTap: () => onSelected(option),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onNext, child: const Text('Next')),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    super.key,
    required this.theme,
    required this.feeling,
    required this.action,
    required this.submitting,
    required this.onSubmit,
  });

  final ThemeData theme;
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
    final accent = switch (submission.level) {
      1 => const Color(0xFF78C3FF),
      2 => const Color(0xFFFFB347),
      _ => const Color(0xFFFF7B7B),
    };
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(feeling.emoji, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Text(
          'Ready to send?',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          submission.levelLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.86),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Text(
            submission.destinationLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          submission.helperText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
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
                : const Text('Send'),
          ),
        ),
      ],
    );
  }
}

class _FeelingButton extends StatelessWidget {
  const _FeelingButton({
    required this.feeling,
    required this.selected,
    required this.onTap,
  });

  final ReportFeeling feeling;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.22)
          : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(feeling.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              feeling.label,
              style: const TextStyle(
                color: Colors.white,
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
    required this.selected,
    required this.onTap,
  });

  final ReportActionOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (option.level) {
      1 => const Color(0xFF78C3FF),
      2 => const Color(0xFFFFB347),
      _ => const Color(0xFFFF7B7B),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(option.icon, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
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
