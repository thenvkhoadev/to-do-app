import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/constants/app_constants.dart';
import 'package:to_do_app/core/router/app_router.dart';
import 'package:to_do_app/core/theme/nexus_theme.dart';
import 'package:to_do_app/core/utils/app_lifecycle_observer.dart';
import 'package:to_do_app/features/xp/presentation/widgets/xp_overlay_shell.dart';

class NexusApp extends ConsumerWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: NexusTheme.dark(),
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => AppLifecycleObserver(
        child: XpOverlayShell(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
