import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/player/presentation/player_page.dart';
import '../../shared_ui/motion/app_motion.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppBootstrapPage()),
      GoRoute(
        path: '/player/:videoId',
        pageBuilder: (context, state) => AppMotion.fadeThroughPage(
          context: context,
          state: state,
          fullscreenDialog: true,
          child: PlayerPage(videoId: state.pathParameters['videoId'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/player/remote/:remoteShareId',
        pageBuilder: (context, state) => AppMotion.fadeThroughPage(
          context: context,
          state: state,
          fullscreenDialog: true,
          child: PlayerPage(
            remoteShareId: state.pathParameters['remoteShareId'] ?? '',
          ),
        ),
      ),
    ],
  );
});
