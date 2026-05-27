import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/features/tasks/data/mock/mock_task_repository.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/floating_ai_button.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_card.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_filter_chips.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_search_field.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/tasks_bottom_navbar.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class TasksMobileLayout extends StatelessWidget {
  const TasksMobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = const MockTaskRepository();
    final today = repository.today();
    final upcoming = repository.upcoming();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      floatingActionButton: const FloatingAIButton(addIcon: true),
      bottomNavigationBar: const TasksBottomNavBar(),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 132),
                sliver: SliverList.list(
                  children: [
                    const TaskSearchField(),
                    const SizedBox(height: 16),
                    const TaskFilterChips(),
                    const SizedBox(height: 28),
                    _SectionHeader(title: 'Today', trailing: '66% COMPLETED'),
                    const SizedBox(height: 16),
                    ...today.take(4).map((task) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TaskCard(task: task, mobile: true))),
                    const SizedBox(height: 18),
                    const _CompactAiCard(),
                    const SizedBox(height: 30),
                    _SectionHeader(title: 'Upcoming'),
                    const SizedBox(height: 16),
                    ...upcoming.map((task) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _UpcomingTile(task: task))),
                  ],
                ),
              ),
            ],
          ),
          const Positioned(top: 0, left: 0, right: 0, child: _MobileTasksTopBar()),
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
            decoration: BoxDecoration(color: DashboardColors.surface.withValues(alpha: .42), border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08)))),
            child: Row(children: [const ProfileAvatar(radius: 17), const SizedBox(width: 12), ShaderMask(shaderCallback: (rect) => const LinearGradient(colors: [DashboardColors.primary, DashboardColors.secondary]).createShader(rect), child: const Text('TaskFlow AI', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))), const Spacer(), IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded, color: DashboardColors.primary)), IconButton(onPressed: () => context.go('/settings'), icon: const Icon(Icons.settings_rounded, color: DashboardColors.primary))]),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(title, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -.4)), const Spacer(), if (trailing != null) Text(trailing!, style: const TextStyle(color: DashboardColors.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1))]);
}

class _CompactAiCard extends StatelessWidget {
  const _CompactAiCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [DashboardColors.primary.withValues(alpha: .12), DashboardColors.secondary.withValues(alpha: .08)]), border: Border.all(color: DashboardColors.primary.withValues(alpha: .18))),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.auto_awesome_rounded, color: DashboardColors.primary), SizedBox(width: 12), Expanded(child: Text('AI suggests batching marketing coordination and stakeholder review after your current focus block.', style: TextStyle(color: DashboardColors.onSurfaceVariant, height: 1.45, fontStyle: FontStyle.italic)))]),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.task});
  final TaskBoardItem task;
  @override
  Widget build(BuildContext context) {
    final parts = (task.dueLabel ?? 'OCT 24').split(' ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .035), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .08))),
      child: Row(children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: DashboardColors.surfaceHigh.withValues(alpha: .55), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: .06))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(parts.first, style: const TextStyle(color: DashboardColors.outline, fontSize: 10, fontWeight: FontWeight.w900)), Text(parts.length > 1 ? parts.last : '24', style: const TextStyle(color: DashboardColors.primary, fontSize: 18, fontWeight: FontWeight.w900))])), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.title, style: const TextStyle(color: DashboardColors.onSurface, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(task.estimate, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12))]))]),
    );
  }
}
