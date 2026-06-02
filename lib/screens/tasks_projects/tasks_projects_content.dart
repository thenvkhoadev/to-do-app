import 'package:flutter/material.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_models.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_actions.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_ai_panel.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_analytics.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_card.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_command_palette.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_header.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_insights.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_preview_overlay.dart';

class TasksProjectsDesktopContent extends StatefulWidget {
  const TasksProjectsDesktopContent({
    this.onNewTask,
    this.onViewDetails,
    this.searchQuery,
    super.key,
  });

  final VoidCallback? onNewTask;
  final ValueChanged<TasksProjectItem>? onViewDetails;
  final String? searchQuery;

  @override
  State<TasksProjectsDesktopContent> createState() =>
      _TasksProjectsDesktopContentState();
}

class _TasksProjectsDesktopContentState
    extends State<TasksProjectsDesktopContent> {
  TasksProjectItem? _previewItem;

  void _openPreview(TasksProjectItem item) {
    if (item.kind == TasksProjectCardKind.add) return;
    setState(() => _previewItem = item);
  }

  void _closePreview() => setState(() => _previewItem = null);

  @override
  Widget build(BuildContext context) {
    return TasksProjectsCommandScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1180;
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TasksProjectsHeader(onNewTask: widget.onNewTask),
                    const SizedBox(height: 18),
                    const TasksProjectsSmartInsightBanner(),
                    const SizedBox(height: 14),
                    const TasksProjectsMiniStatsRow(),
                    if (!wide) ...[
                      const SizedBox(height: 14),
                      const TasksProjectsAnalyticsStrip(),
                    ],
                    const SizedBox(height: 18),
                    wide
                        ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _DesktopGrid(
                                twoColumns: true,
                                onOpenPreview: _openPreview,
                                onNewTask: widget.onNewTask,
                                searchQuery: widget.searchQuery,
                              ),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 340,
                              child: _ProjectsRightRail(
                                onNewTask: widget.onNewTask,
                              ),
                            ),
                          ],
                        )
                        : _DesktopGrid(
                          twoColumns: constraints.maxWidth >= 720,
                          onOpenPreview: _openPreview,
                          onNewTask: widget.onNewTask,
                          searchQuery: widget.searchQuery,
                        ),
                  ],
                ),
              ),
              if (_previewItem != null)
                Positioned.fill(
                  child: TaskPreviewOverlay(
                    item: _previewItem!,
                    visible: true,
                    onClose: _closePreview,
                    onViewDetails: widget.onViewDetails,
                  ),
                ),
            ],
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
      padding:
          compact
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(16, 96, 16, 128),
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
  const _ProjectsRightRail({this.onNewTask});

  final VoidCallback? onNewTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TasksProjectsAiAssistantPanel(),
        const SizedBox(height: 14),
        const TasksProjectsCircularAnalytics(),
        const SizedBox(height: 14),
        const TasksProjectsHeatmap(),
        const SizedBox(height: 14),
        const TasksProjectsActivityTimeline(),
        const SizedBox(height: 14),
        TasksProjectsQuickActionDock(compact: true, onNewTask: onNewTask),
      ],
    );
  }
}

class _DesktopGrid extends StatelessWidget {
  const _DesktopGrid({
    required this.twoColumns,
    this.onOpenPreview,
    this.onNewTask,
    this.searchQuery,
  });

  final bool twoColumns;
  final ValueChanged<TasksProjectItem>? onOpenPreview;
  final VoidCallback? onNewTask;
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    final query = (searchQuery ?? '').trim().toLowerCase();
    final items =
        query.isEmpty
            ? tasksProjectItems
            : tasksProjectItems
                .where(
                  (item) =>
                      item.kind == TasksProjectCardKind.add ||
                      item.title.toLowerCase().contains(query) ||
                      item.description.toLowerCase().contains(query) ||
                      item.badge.toLowerCase().contains(query),
                )
                .toList();
    return ScrollbarTheme(
      data: ScrollbarTheme.of(context).copyWith(
        thumbVisibility: WidgetStateProperty.all(false),
        trackVisibility: WidgetStateProperty.all(false),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(right: 48, bottom: 8),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: twoColumns ? 2 : 1,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          mainAxisExtent: 242,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return TasksProjectsCard(
            item: item,
            onTap:
                item.kind == TasksProjectCardKind.add
                    ? onNewTask
                    : () => onOpenPreview?.call(item),
          );
        },
      ),
    );
  }
}
