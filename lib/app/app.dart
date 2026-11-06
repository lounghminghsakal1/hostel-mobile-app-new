import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import 'router/app_router.dart';

class HostelApp extends ConsumerWidget {
  const HostelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The whole theme comes from one palette; changing it re-colours the app.
    final palette = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(palette),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
