import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/floating_ai_button.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/tasks_bottom_navbar.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_content.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class TasksMobileLayout extends StatelessWidget {
  const TasksMobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      floatingActionButton: const FloatingAIButton(addIcon: true),
      bottomNavigationBar: const TasksBottomNavBar(),
      body: Stack(
        children: [
          const CustomScrollView(slivers: [TasksProjectsMobileSliverBody()]),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _MobileTasksTopBar(),
          ),
        ],
      ),
    );
  }
}

class _MobileTasksTopBar extends StatelessWidget {
  const _MobileTasksTopBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: DashboardColors.surface.withValues(alpha: .42),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
              ),
            ),
            child: Row(
              children: [
                const ProfileAvatar(radius: 17),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback:
                      (rect) => const LinearGradient(
                        colors: [
                          DashboardColors.primary,
                          DashboardColors.secondary,
                        ],
                      ).createShader(rect),
                  child: const Text(
                    'NEXUS AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.search_rounded,
                    color: DashboardColors.primary,
                  ),
                ),
                IconButton(
                  onPressed: () => context.go('/settings'),
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: DashboardColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
