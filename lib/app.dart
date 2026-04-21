import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_mode.dart';
import 'l10n/app_localizations.dart';

class MyTubeApp extends ConsumerWidget {
  const MyTubeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeDescriptor = ref.watch(activeThemeProvider);
    final appearanceMode = ref.watch(activeAppearanceModeProvider);
    final locale = ref.watch(activeLocaleProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      locale: locale,
      theme: buildAppTheme(themeDescriptor, brightness: Brightness.light),
      darkTheme: buildAppTheme(themeDescriptor, brightness: Brightness.dark),
      themeMode: appearanceMode.materialThemeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
