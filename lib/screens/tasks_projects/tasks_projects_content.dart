import 'package:flutter/material.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_models.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_actions.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_ai_panel.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_analytics.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_card.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_command_palette.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_header.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_insights.dart';

class TasksProjectsDesktopContent extends StatelessWidget {
  const TasksProjectsDesktopContent({this.onNewTask, super.key});

  final VoidCallback? onNewTask;

  @override
  Widget build(BuildContext context) {
    return TasksProjectsCommandScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1180;
          return Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
            child: Column(
              children: [
                TasksProjectsHeader(onNewTask: onNewTask),
                const SizedBox(height: 18),
                const TasksProjectsSmartInsightBanner(),
                const SizedBox(height: 14),
                const TasksProjectsMiniStatsRow(),
                if (!wide) ...[
                  const SizedBox(height: 14),
                  const TasksProjectsAnalyticsStrip(),
                ],
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Expanded(child: _DesktopGrid(twoColumns: true)),
                              SizedBox(width: 24),
                              SizedBox(width: 340, child: _ProjectsRightRail()),
                            ],
                          )
                        : _DesktopGrid(twoColumns: constraints.maxWidth >= 1040),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TasksProjectsMobileSliverBody extends StatelessWidget {
  const TasksProjectsMobileSliverBody({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: compact ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 96, 16, 128),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TasksProjectsHeader(mobile: true),
                const SizedBox(height: 18),
                const TasksProjectsSmartInsightBanner(compact: true),
                const SizedBox(height: 14),
                const TasksProjectsMiniStatsRow(compact: true),
                const SizedBox(height: 14),
                const TasksProjectsAnalyticsStrip(compact: true),
                const SizedBox(height: 22),
                ...tasksProjectItems
                    .take(4)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TasksProjectsCard(item: item, mobile: true),
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

class _ProjectsRightRail extends StatelessWidget {
  const _ProjectsRightRail();

  @override
  Widget build(BuildContext context) {
    return Column(
        children: const [
          TasksProjectsAiAssistantPanel(),
          SizedBox(height: 14),
          TasksProjectsCircularAnalytics(),
          SizedBox(height: 14),
          TasksProjectsHeatmap(),
          SizedBox(height: 14),
          TasksProjectsActivityTimeline(),
          SizedBox(height: 14),
          TasksProjectsQuickActionDock(compact: true),
        ],
      );
  }
}

class _DesktopGrid extends StatelessWidget {
  const _DesktopGrid({required this.twoColumns});

  final bool twoColumns;

  @override
  Widget build(BuildContext context) {
    return ScrollbarTheme(
      data: ScrollbarTheme.of(context).copyWith(
        thumbVisibility: WidgetStateProperty.all(false),
        trackVisibility: WidgetStateProperty.all(false),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(right: 32, bottom: 8),
        itemCount: tasksProjectItems.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: twoColumns ? 2 : 1,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 242,
      ),
        itemBuilder:
            (context, index) => TasksProjectsCard(item: tasksProjectItems[index]),
      ),
    );
  }
}

