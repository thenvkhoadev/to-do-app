import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/shared/widgets/nexus_glass_panel.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  static const _highPriorityTasks = [
    _TaskItem(
      title: 'Finalize Q3 Roadmap Presentation',
      description:
          'Incorporate latest AI usage metrics and adjust the timeline for the Nexus 2.0 rollout.',
      priority: 'High',
      time: '14:00',
      subtasks: '3 Subtasks',
      attachments: '2',
      isHighPriority: true,
    ),
    _TaskItem(
      title: 'Review User Feedback (Auto-Generated)',
      description:
          'Nexus AI identified 15 negative sentiment tickets regarding the new search feature.',
      time: '16:30',
      subtasks: '1 Subtask',
      isAiGenerated: true,
    ),
  ];

  static const _standardTasks = [
    _TaskItem(
      title: 'Weekly Sync prep',
      priority: 'Med',
      time: '10:00',
      attachments: '1',
    ),
    _TaskItem(title: 'Buy coffee beans', priority: 'Low', isMuted: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: const _AddTaskButton(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final horizontalPadding = constraints.maxWidth >= 760 ? 48.0 : 16.0;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    32,
                    horizontalPadding,
                    140,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SearchAndFilters(),
                            const SizedBox(height: 36),
                            const _TimeTabs(),
                            const SizedBox(height: 32),
                            _TaskBoard(isWide: isWide),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NexusGlassPanel(
          padding: EdgeInsets.zero,
          radius: 16,
          glowColor: NexusColors.primaryContainer.withValues(alpha: 0.18),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search tasks, AI insights...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 22,
              ),
              hintStyle: TextStyle(
                color: NexusColors.onSurfaceVariant.withValues(alpha: 0.72),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(label: 'All Work', selected: true),
              _FilterChip(label: 'Personal'),
              _FilterChip(label: 'Health'),
              _FilterChip(
                label: 'Nexus Suggestions',
                icon: Icons.auto_awesome_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false, this.icon});

  final String label;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FilterChip(
        selected: selected,
        onSelected: (_) {},
        avatar: icon == null ? null : Icon(icon, size: 18),
        label: Text(label),
        labelStyle: TextStyle(
          color:
              selected ? NexusColors.onSurface : NexusColors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.4,
        ),
        backgroundColor: NexusColors.surfaceContainer,
        selectedColor: NexusColors.primaryContainer.withValues(alpha: 0.72),
        side: BorderSide(
          color: Colors.white.withValues(alpha: selected ? 0 : 0.06),
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        showCheckmark: false,
      ),
    );
  }
}

class _TimeTabs extends StatelessWidget {
  const _TimeTabs();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      child: Row(
        children: const [
          _TimeTab(label: 'Today', selected: true, showDot: true),
          _TimeTab(label: 'Upcoming'),
          _TimeTab(label: 'Completed'),
          _TimeTab(label: 'Overdue', danger: true),
        ],
      ),
    );
  }
}

class _TimeTab extends StatelessWidget {
  const _TimeTab({
    required this.label,
    this.selected = false,
    this.showDot = false,
    this.danger = false,
  });

  final String label;
  final bool selected;
  final bool showDot;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color =
        selected
            ? NexusColors.primary
            : danger
            ? NexusColors.error
            : NexusColors.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? NexusColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
              if (showDot)
                Positioned(
                  right: -12,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: NexusColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskBoard extends StatelessWidget {
  const _TaskBoard({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final highColumn = const _TaskColumn(
      title: 'High Priority',
      indicatorColor: NexusColors.error,
      tasks: TasksScreen._highPriorityTasks,
    );
    final standardColumn = const _TaskColumn(
      title: 'Standard Priority',
      indicatorColor: NexusColors.secondary,
      tasks: TasksScreen._standardTasks,
    );

    if (!isWide) {
      return Column(
        children: [highColumn, const SizedBox(height: 24), standardColumn],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: highColumn),
        const SizedBox(width: 32),
        Expanded(child: standardColumn),
      ],
    );
  }
}

class _TaskColumn extends StatelessWidget {
  const _TaskColumn({
    required this.title,
    required this.indicatorColor,
    required this.tasks,
  });

  final String title;
  final Color indicatorColor;
  final List<_TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...tasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _TaskCard(task: task),
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final _TaskItem task;

  @override
  Widget build(BuildContext context) {
    final priorityColor =
        task.isHighPriority
            ? NexusColors.error
            : task.priority == 'Med'
            ? NexusColors.secondary
            : NexusColors.onSurfaceVariant;

    return Opacity(
      opacity: task.isMuted ? 0.7 : 1,
      child: Stack(
        children: [
          NexusGlassPanel(
            padding: const EdgeInsets.all(24),
            borderColor:
                task.isAiGenerated
                    ? NexusColors.primary.withValues(alpha: 0.36)
                    : null,
            glowColor:
                task.isAiGenerated
                    ? NexusColors.primaryContainer.withValues(alpha: 0.22)
                    : null,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _CompletionButton(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      if (task.priority != null) ...[
                        const SizedBox(width: 8),
                        _PriorityBadge(
                          label: task.priority!,
                          color: priorityColor,
                        ),
                      ],
                    ],
                  ),
                  if (task.description != null) ...[
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.only(left: 42),
                      child: Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: NexusColors.onSurfaceVariant,
                          height: 1.55,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                  if (task.hasMeta) ...[
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.only(left: 42),
                      child: _TaskMeta(task: task),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (task.isAiGenerated)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: NexusColors.primaryContainer.withValues(alpha: 0.22),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: NexusColors.primary,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompletionButton extends StatelessWidget {
  const _CompletionButton();

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {},
      radius: 24,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: NexusColors.onSurfaceVariant, width: 2),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: NexusColors.primary,
          size: 19,
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _TaskMeta extends StatelessWidget {
  const _TaskMeta({required this.task});

  final _TaskItem task;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [
              if (task.subtasks != null)
                _MetaPill(
                  icon: Icons.account_tree_rounded,
                  label: task.subtasks!,
                  highlighted: true,
                ),
              if (task.attachments != null)
                _MetaPill(
                  icon: Icons.attach_file_rounded,
                  label: task.attachments!,
                ),
            ],
          ),
        ),
        if (task.time != null)
          _MetaPill(
            icon: Icons.schedule_rounded,
            label: task.time!,
            highlighted: true,
          ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color =
        highlighted ? NexusColors.secondary : NexusColors.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AddTaskButton extends StatelessWidget {
  const _AddTaskButton();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {},
      tooltip: 'Add task',
      backgroundColor: NexusColors.primary,
      foregroundColor: NexusColors.onPrimary,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded, size: 34),
    );
  }
}

class _TaskItem {
  const _TaskItem({
    required this.title,
    this.description,
    this.priority,
    this.time,
    this.subtasks,
    this.attachments,
    this.isHighPriority = false,
    this.isAiGenerated = false,
    this.isMuted = false,
  });

  final String title;
  final String? description;
  final String? priority;
  final String? time;
  final String? subtasks;
  final String? attachments;
  final bool isHighPriority;
  final bool isAiGenerated;
  final bool isMuted;

  bool get hasMeta => time != null || subtasks != null || attachments != null;
}
