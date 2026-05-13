import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: TikTokCloneApp()));
}

class TikTokCloneApp extends StatelessWidget {
  const TikTokCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TikTok Clone',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
      showPerformanceOverlay: const bool.fromEnvironment('PERF_OVERLAY'),
    );
  }
}
