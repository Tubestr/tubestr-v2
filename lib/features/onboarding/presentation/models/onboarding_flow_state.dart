import '../../../../core/theme/theme_descriptor.dart';

const _unset = Object();

enum OnboardingStep {
  intro,
  roleSelect,
  parentKey,
  restoreKey,
  recovery,
  childProfiles,
  permissions,
  complete,
}

class OnboardingFlowState {
  const OnboardingFlowState({
    this.step = OnboardingStep.intro,
    this.childTheme = ThemeDescriptor.campfire,
    this.busy = false,
    this.showCelebration = false,
    this.permissionError,
    this.recoveryMessage,
    this.recoverySucceeded,
    this.introPage = 0,
  });

  final OnboardingStep step;
  final ThemeDescriptor childTheme;
  final bool busy;
  final bool showCelebration;
  final String? permissionError;
  final String? recoveryMessage;
  final bool? recoverySucceeded;
  final int introPage;

  OnboardingFlowState copyWith({
    OnboardingStep? step,
    ThemeDescriptor? childTheme,
    bool? busy,
    bool? showCelebration,
    Object? permissionError = _unset,
    Object? recoveryMessage = _unset,
    Object? recoverySucceeded = _unset,
    int? introPage,
  }) {
    return OnboardingFlowState(
      step: step ?? this.step,
      childTheme: childTheme ?? this.childTheme,
      busy: busy ?? this.busy,
      showCelebration: showCelebration ?? this.showCelebration,
      permissionError: identical(permissionError, _unset)
          ? this.permissionError
          : permissionError as String?,
      recoveryMessage: identical(recoveryMessage, _unset)
          ? this.recoveryMessage
          : recoveryMessage as String?,
      recoverySucceeded: identical(recoverySucceeded, _unset)
          ? this.recoverySucceeded
          : recoverySucceeded as bool?,
      introPage: introPage ?? this.introPage,
    );
  }
}
