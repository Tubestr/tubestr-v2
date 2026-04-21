import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/theme/spacing.dart';

class KidLayoutSpec {
  const KidLayoutSpec({
    required this.isTablet,
    required this.isLargeTablet,
    required this.maxContentWidth,
    required this.comfortablePadding,
    required this.feedGridColumns,
  });

  final bool isTablet;
  final bool isLargeTablet;
  final double maxContentWidth;
  final double comfortablePadding;
  final int feedGridColumns;

  static KidLayoutSpec fromWidth(double width) {
    if (width >= 1400) {
      return const KidLayoutSpec(
        isTablet: true,
        isLargeTablet: true,
        maxContentWidth: 1440,
        comfortablePadding: AppSpacing.xxxl,
        feedGridColumns: 4,
      );
    }
    if (width >= 900) {
      return const KidLayoutSpec(
        isTablet: true,
        isLargeTablet: false,
        maxContentWidth: 1200,
        comfortablePadding: AppSpacing.xxl,
        feedGridColumns: 3,
      );
    }
    return const KidLayoutSpec(
      isTablet: false,
      isLargeTablet: false,
      maxContentWidth: 680,
      comfortablePadding: AppSpacing.xl,
      feedGridColumns: 1,
    );
  }
}

class KidScaffold extends ConsumerWidget {
  const KidScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.maxContentWidth,
    this.centerBody = false,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final double? maxContentWidth;
  final bool centerBody;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);

    return Scaffold(
      extendBody: true,
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.backgroundTop, palette.backgroundBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = KidLayoutSpec.fromWidth(constraints.maxWidth);
                  final body = centerBody
                      ? KidContentFrame(
                          maxWidth: maxContentWidth ?? layout.maxContentWidth,
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.comfortablePadding,
                          ),
                          child: child,
                        )
                      : child;

                  return body;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KidContentFrame extends StatelessWidget {
  const KidContentFrame({
    super.key,
    required this.child,
    required this.maxWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class FrostCard extends StatelessWidget {
  const FrostCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: padding, child: child),
    );
  }
}
