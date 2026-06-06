import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

import 'widgets/desktop/desktop_task_header.dart';
import 'widgets/desktop/desktop_hero_stats.dart';
import 'widgets/desktop/desktop_task_description.dart';
import 'widgets/desktop/desktop_subtasks.dart';
import 'widgets/desktop/desktop_attachments.dart';
import 'widgets/desktop/desktop_timeline.dart';
import 'widgets/desktop/desktop_ai_panel.dart';
import 'widgets/desktop/desktop_status_stepper.dart';
import 'widgets/desktop/desktop_focus_forecast.dart';
import 'widgets/mobile/mobile_task_header.dart';
import 'widgets/mobile/mobile_health_score.dart';
import 'widgets/mobile/mobile_status_flow.dart';
import 'widgets/mobile/mobile_info_grid.dart';
import 'widgets/mobile/mobile_focus_forecast.dart';
import 'widgets/mobile/mobile_assignees.dart';
import 'widgets/mobile/mobile_description.dart';
import 'widgets/mobile/mobile_subtasks.dart';
import 'widgets/mobile/mobile_attachments.dart';
import 'widgets/mobile/mobile_timeline.dart';

const _desktopBreakpoint = 1200.0;

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({
    required this.item,
    required this.onBack,
    super.key,
  });

  final TaskBoardItem item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= _desktopBreakpoint) {
          return _DesktopLayout(item: item, onBack: onBack);
        }
        return _MobileLayout(item: item, onBack: onBack);
      },
    );
  }
}

// ── Desktop layout ─────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.item, required this.onBack});
  final TaskBoardItem item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DashboardColors.background,
      child: Column(
        children: [
          DesktopTaskHeader(item: item, onBack: onBack),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1100;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 32, 40, 80),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _DesktopLeftColumn(item: item),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 3,
                              child: _DesktopRightColumn(item: item),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DesktopLeftColumn(item: item),
                            const SizedBox(height: 24),
                            _DesktopRightColumn(item: item),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopLeftColumn extends StatelessWidget {
  const _DesktopLeftColumn({required this.item});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopHeroStats(item: item),
        const SizedBox(height: 24),
        DesktopTaskDescription(item: item),
        const SizedBox(height: 24),
        DesktopSubtasks(taskId: item.id),
        const SizedBox(height: 24),
        DesktopAttachments(taskId: item.id),
        const SizedBox(height: 24),
        DesktopTimeline(item: item),
      ],
    );
  }
}

class _DesktopRightColumn extends StatelessWidget {
  const _DesktopRightColumn({required this.item});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DesktopAiPanel(),
        const SizedBox(height: 24),
        DesktopStatusStepper(status: item.status),
        const SizedBox(height: 24),
        DesktopFocusForecast(item: item),
      ],
    );
  }
}

// ── Mobile layout ───────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.item, required this.onBack});
  final TaskBoardItem item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Top AppBar
              SliverAppBar(
                pinned: true,
                backgroundColor: DashboardColors.surface.withValues(alpha: .85),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: DashboardColors.onSurface),
                  onPressed: onBack,
                ),
                title: const Text(
                  'Task Detail',
                  style: TextStyle(
                    color: DashboardColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.01,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded,
                        color: DashboardColors.onSurface),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded,
                        color: DashboardColors.onSurface),
                    onPressed: () {},
                  ),
                ],
              ),
              // Hero header (full-width, no padding)
              SliverToBoxAdapter(
                child: MobileTaskHeader(item: item, onBack: onBack),
              ),
              // All content sections with padding
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Transform.translate(
                      offset: const Offset(0, -32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MobileHealthScore(score: 92, probability: 87),
                          const SizedBox(height: 16),
                          MobileStatusFlow(status: item.status),
                          const SizedBox(height: 16),
                          MobileInfoGrid(item: item),
                          const SizedBox(height: 16),
                          const MobileFocusForecast(),
                          const SizedBox(height: 24),
                          MobileAssignees(item: item),
                          const SizedBox(height: 24),
                          MobileDescription(item: item),
                          const SizedBox(height: 24),
                          MobileSubtasks(taskId: item.id),
                          const SizedBox(height: 24),
                          MobileAttachments(taskId: item.id),
                          const SizedBox(height: 24),
                          MobileTimeline(item: item),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          // FAB
          Positioned(
            bottom: 88,
            right: 16,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: DashboardColors.primaryContainer,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: DashboardColors.primary.withValues(alpha: .25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.play_circle_rounded,
                  color: DashboardColors.onPrimary, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
