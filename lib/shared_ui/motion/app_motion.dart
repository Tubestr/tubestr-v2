import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppMotion {
  const AppMotion._();

  static const Curve easeOutQuart = Cubic(0.25, 1, 0.5, 1);
  static const Curve easeOutQuint = Cubic(0.22, 1, 0.36, 1);
  static const Curve easeOutExpo = Cubic(0.16, 1, 0.3, 1);

  static const Duration instantFeedback = Duration(milliseconds: 140);
  static const Duration stateChange = Duration(milliseconds: 240);
  static const Duration layoutChange = Duration(milliseconds: 340);
  static const Duration entrance = Duration(milliseconds: 420);
  static const Duration exit = Duration(milliseconds: 220);

  static bool reduceMotion(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      return false;
    }
    return mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
  }

  static Duration duration(
    BuildContext context,
    Duration normal, {
    Duration reduced = Duration.zero,
  }) {
    return reduceMotion(context) ? reduced : normal;
  }

  static Offset offset(BuildContext context, Offset normal) {
    return reduceMotion(context) ? Offset.zero : normal;
  }

  static CustomTransitionPage<void> fadeThroughPage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    bool fullscreenDialog = false,
  }) {
    final reduced = reduceMotion(context);
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      fullscreenDialog: fullscreenDialog,
      transitionDuration: reduced ? Duration.zero : entrance,
      reverseTransitionDuration: reduced ? Duration.zero : exit,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: easeOutQuint,
          reverseCurve: Curves.linear,
        );
        final slide = Tween<Offset>(
          begin: reduced ? Offset.zero : const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  static Route<T> modalRoute<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool fullscreenDialog = false,
  }) {
    final reduced = reduceMotion(context);
    return PageRouteBuilder<T>(
      fullscreenDialog: fullscreenDialog,
      transitionDuration: reduced ? Duration.zero : entrance,
      reverseTransitionDuration: reduced ? Duration.zero : exit,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: easeOutQuint,
          reverseCurve: Curves.linear,
        );
        final slide = Tween<Offset>(
          begin: reduced ? Offset.zero : const Offset(0.03, 0.02),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
