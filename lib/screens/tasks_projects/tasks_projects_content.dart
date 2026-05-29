import 'package:flutter/material.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_models.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_card.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_header.dart';

class TasksProjectsDesktopContent extends StatelessWidget {
  const TasksProjectsDesktopContent({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(32, 32, 32, 0),
              child: TasksProjectsHeader(),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: _DesktopGrid(twoColumns: constraints.maxWidth >= 1040),
              ),
            ),
          ],
        );
      },
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
                const SizedBox(height: 32),
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

