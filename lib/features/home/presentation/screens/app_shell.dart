import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/shared/widgets/nexus_background.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NexusBackground(child: SafeArea(child: navigationShell)),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(index),
            backgroundColor: NexusColors.surfaceContainer.withValues(alpha: 0.86),
            indicatorColor: NexusColors.primaryContainer.withValues(alpha: 0.35),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.task_alt_rounded), label: 'Tasks'),
              NavigationDestination(icon: Icon(Icons.auto_awesome_rounded), label: 'Nexus AI'),
              NavigationDestination(icon: Icon(Icons.event_rounded), label: 'Events'),
              NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
