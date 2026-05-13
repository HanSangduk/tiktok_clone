import 'package:go_router/go_router.dart';

import 'features/feed/feed_screen.dart';
import 'features/splash/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
  ],
);
