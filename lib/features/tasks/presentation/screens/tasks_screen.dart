import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: const _AddTaskButton(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 40 : 16,
              isDesktop ? 32 : 24,
              isDesktop ? 40 : 16,
              isDesktop ? 48 : 132,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SearchPanel(),
                    const SizedBox(height: 20),
                    const _FilterRow(),
                    const SizedBox(height: 24),
                    const _TaskTabs(),
                    const SizedBox(height: 28),
                    isDesktop ? const _DesktopTaskLayout() : const _MobileTaskLayout(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DesktopTaskLayout extends StatelessWidget {
  const _DesktopTaskLayout();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _InsightRail()),
        SizedBox(width: 24),
        Expanded(flex: 6, child: _SprintBoard()),
        SizedBox(width: 24),
        Expanded(flex: 3, child: _FocusRail()),
      ],
    );
  }
}

class _MobileTaskLayout extends StatelessWidget {
  const _MobileTaskLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HighPrioritySection(),
        SizedBox(height: 32),
        _StandardSection(),
        SizedBox(height: 32),
        _InsightRail(),
      ],
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(8),
      radius: 24,
      glow: NexusColors.primaryContainer,
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, color: NexusColors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks, AI insights...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: NexusColors.outline),
              ),
              style: TextStyle(color: NexusColors.onSurface),
            ),
          ),
          Material(
            color: NexusColors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.auto_awesome_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TaskFilter(label: 'All Work', selected: true),
          _TaskFilter(label: 'Personal'),
          _TaskFilter(label: 'Health'),
          _TaskFilter(label: 'Nexus AI', icon: Icons.hub_rounded),
        ],
      ),
    );
  }
}

class _TaskFilter extends StatelessWidget {
  const _TaskFilter({required this.label, this.selected = false, this.icon});

  final String label;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: selected ? NexusColors.primary.withValues(alpha: 0.10) : NexusColors.surface.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? NexusColors.primary.withValues(alpha: 0.32) : Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: NexusColors.secondary, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(color: selected ? NexusColors.primary : NexusColors.onSurfaceVariant, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskTabs extends StatelessWidget {
  const _TaskTabs();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)))),
      child: const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TaskTab(label: 'Today', selected: true),
            _TaskTab(label: 'Upcoming'),
            _TaskTab(label: 'Completed'),
            _TaskTab(label: 'Overdue', danger: true),
          ],
        ),
      ),
    );
  }
}

class _TaskTab extends StatelessWidget {
  const _TaskTab({required this.label, this.selected = false, this.danger = false});

  final String label;
  final bool selected;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = selected ? NexusColors.secondary : danger ? NexusColors.error : NexusColors.onSurfaceVariant;

    return InkWell(
      onTap: () {},
      child: Container(
        width: 116,
        padding: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? NexusColors.secondary : Colors.transparent, width: 2)),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: selected ? FontWeight.w900 : FontWeight.w700)),
      ),
    );
  }
}

class _InsightRail extends StatelessWidget {
  const _InsightRail();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _FlowInsightCard(),
        SizedBox(height: 24),
        _QuickActionsCard(),
      ],
    );
  }
}

class _FlowInsightCard extends StatelessWidget {
  const _FlowInsightCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(icon: Icons.psychology_rounded, title: 'AI Insights Focus', color: NexusColors.secondary),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 0.86,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: const AlwaysStoppedAnimation(NexusColors.primary),
                    ),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('86', style: TextStyle(color: NexusColors.primary, fontSize: 34, fontWeight: FontWeight.w900, height: 1)),
                      SizedBox(height: 5),
                      Text('Flow Score', style: TextStyle(color: NexusColors.outline, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const _MetricBlock(label: 'Deep Work', value: '4h 12m', progress: 0.7),
          const SizedBox(height: 14),
          const _WarningBlock(),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionTitle(icon: Icons.bolt_rounded, title: 'Quick Actions'),
          SizedBox(height: 16),
          _QuickAction(icon: Icons.add_task_rounded, label: 'New AI Task', color: NexusColors.primary),
          SizedBox(height: 10),
          _QuickAction(icon: Icons.summarize_rounded, label: 'Generate Daily Brief', color: NexusColors.secondary),
        ],
      ),
    );
  }
}

class _SprintBoard extends StatelessWidget {
  const _SprintBoard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _SprintHeader(),
        SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _KanbanColumn(title: 'To Do', count: '3', tasks: [_KanbanTask.highAuth, _KanbanTask.lowTypography])),
            SizedBox(width: 16),
            Expanded(child: _KanbanColumn(title: 'In Progress', count: '1', active: true, tasks: [_KanbanTask.activePrompts])),
            SizedBox(width: 16),
            Expanded(child: _KanbanColumn(title: 'Done', count: '4', tasks: [_KanbanTask.doneAudit])),
          ],
        ),
      ],
    );
  }
}

class _SprintHeader extends StatelessWidget {
  const _SprintHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Text('Active Sprint', style: TextStyle(color: NexusColors.onSurface, fontSize: 24, fontWeight: FontWeight.w900))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.10))),
          child: const Row(
            children: [
              _PulseDot(),
              SizedBox(width: 8),
              Text('Syncing', style: TextStyle(color: NexusColors.secondary, fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({required this.title, required this.count, required this.tasks, this.active = false});

  final String title;
  final String count;
  final List<_KanbanTask> tasks;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title.toUpperCase(), style: TextStyle(color: active ? NexusColors.primary : NexusColors.outline, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
            _CountPill(label: count, active: active),
          ],
        ),
        const SizedBox(height: 12),
        ...tasks.map((task) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _KanbanTaskCard(task: task))),
      ],
    );
  }
}

class _KanbanTaskCard extends StatelessWidget {
  const _KanbanTaskCard({required this.task});

  final _KanbanTask task;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: 14,
      glow: task.active ? NexusColors.primaryContainer : null,
      child: Stack(
        children: [
          if (task.active)
            const Positioned(left: 0, top: 0, right: 0, child: SizedBox(height: 2, child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [NexusColors.primary, NexusColors.secondary]))))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PriorityBadge(label: task.priority, color: task.color),
                  const Spacer(),
                  Icon(Icons.more_horiz_rounded, color: NexusColors.outline.withValues(alpha: 0.7), size: 18),
                ],
              ),
              const SizedBox(height: 14),
              Text(task.title, style: const TextStyle(color: NexusColors.onSurface, fontWeight: FontWeight.w800, fontSize: 15, height: 1.3)),
              if (task.description != null) ...[
                const SizedBox(height: 8),
                Text(task.description!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NexusColors.outline, fontSize: 12, height: 1.45)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _AvatarChip(label: task.assignee),
                  const Spacer(),
                  Icon(Icons.chat_bubble_outline_rounded, color: NexusColors.outline.withValues(alpha: 0.8), size: 15),
                  const SizedBox(width: 4),
                  Text(task.comments, style: const TextStyle(color: NexusColors.outline, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighPrioritySection extends StatelessWidget {
  const _HighPrioritySection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(icon: Icons.flag_rounded, title: 'High Priority', color: NexusColors.error),
        SizedBox(height: 16),
        _MobileTaskCard(title: 'Finalize Q3 Roadmap', due: 'Due 5:00 PM', badge: 'P1', badgeColor: NexusColors.error, insight: '3 pending tickets show high negative sentiment. Prioritize review before finalizing roadmap.', tag: 'Strategy'),
        SizedBox(height: 16),
        _MobileTaskCard(title: 'Review User Feedback', due: 'In 2 hours', badge: 'P2', badgeColor: NexusColors.tertiary, tag: 'Product'),
      ],
    );
  }
}

class _StandardSection extends StatelessWidget {
  const _StandardSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(icon: Icons.check_circle_rounded, title: 'Standard', color: NexusColors.secondary),
        SizedBox(height: 16),
        _MobileTaskCard(title: 'Weekly Sync prep', due: 'Tomorrow', badge: 'P3', badgeColor: NexusColors.secondary, tag: 'Meetings', muted: true),
      ],
    );
  }
}

class _MobileTaskCard extends StatelessWidget {
  const _MobileTaskCard({required this.title, required this.due, required this.badge, required this.badgeColor, required this.tag, this.insight, this.muted = false});

  final String title;
  final String due;
  final String badge;
  final Color badgeColor;
  final String tag;
  final String? insight;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: muted ? 0.82 : 1,
      child: _GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TaskCheckBox(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: NexusColors.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Row(children: [const Icon(Icons.schedule_rounded, color: NexusColors.onSurfaceVariant, size: 14), const SizedBox(width: 5), Text(due, style: const TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700))]),
                    ],
                  ),
                ),
                _PriorityBadge(label: badge, color: badgeColor),
              ],
            ),
            if (insight != null) ...[
              const SizedBox(height: 18),
              _AiInsight(text: insight!),
            ],
            const SizedBox(height: 18),
            _TagPill(label: tag),
          ],
        ),
      ),
    );
  }
}

class _FocusRail extends StatelessWidget {
  const _FocusRail();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _DeepWorkStatusCard(),
        SizedBox(height: 24),
        _UpcomingBlockersCard(),
      ],
    );
  }
}

class _DeepWorkStatusCard extends StatelessWidget {
  const _DeepWorkStatusCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionTitle(icon: Icons.timer_rounded, title: 'Deep Work', color: NexusColors.secondary),
          SizedBox(height: 16),
          Text('Remaining in deep work', style: TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('42m', style: TextStyle(color: NexusColors.secondary, fontSize: 42, fontWeight: FontWeight.w900, height: 1)),
          SizedBox(height: 18),
          _MetricBlock(label: 'Focus Guard', value: 'Active', progress: 0.82),
        ],
      ),
    );
  }
}

class _UpcomingBlockersCard extends StatelessWidget {
  const _UpcomingBlockersCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionTitle(icon: Icons.warning_rounded, title: 'Blockers', color: NexusColors.error),
          SizedBox(height: 16),
          _MiniBlocker(title: 'Auth API review', subtitle: 'Needs backend confirmation'),
          _MiniBlocker(title: 'Design tokens', subtitle: 'Waiting on final scale'),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.padding = const EdgeInsets.all(24), this.radius = 24, this.glow});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: NexusColors.surface.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 26, offset: const Offset(0, 16)),
          if (glow != null) BoxShadow(color: glow!.withValues(alpha: 0.14), blurRadius: 30),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.color = NexusColors.onSurfaceVariant});

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.4))]);
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title, required this.color});

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: const TextStyle(color: NexusColors.onSurface, fontSize: 24, fontWeight: FontWeight.w900))]);
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value, required this.progress});

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w800)), Text(value, style: const TextStyle(color: NexusColors.secondary, fontSize: 12, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 9),
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: Colors.white.withValues(alpha: 0.10), valueColor: const AlwaysStoppedAnimation(NexusColors.secondary))),
        ],
      ),
    );
  }
}

class _WarningBlock extends StatelessWidget {
  const _WarningBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(color: NexusColors.error.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12), border: Border.all(color: NexusColors.error.withValues(alpha: 0.22))),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: NexusColors.error, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text('Context switching detected. Suggesting a 15-min disconnect protocol.', style: TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 12, height: 1.4))),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
          child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(color: NexusColors.onSurface, fontWeight: FontWeight.w800)))]),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.24))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: active ? NexusColors.primary.withValues(alpha: 0.20) : NexusColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Text(label, style: TextStyle(color: active ? NexusColors.primary : NexusColors.outline, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  const _AvatarChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.10), border: Border.all(color: NexusColors.surfaceContainerHigh)),
      child: Text(label, style: const TextStyle(color: NexusColors.onSurface, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

class _TaskCheckBox extends StatelessWidget {
  const _TaskCheckBox();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {},
      child: Container(width: 26, height: 26, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: NexusColors.outlineVariant, width: 2))),
    );
  }
}

class _AiInsight extends StatelessWidget {
  const _AiInsight({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: NexusColors.primaryContainer.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16), border: Border.all(color: NexusColors.primary.withValues(alpha: 0.20))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology_rounded, color: NexusColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 13, height: 1.45))),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: NexusColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Text(label.toUpperCase(), style: const TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: NexusColors.secondary, boxShadow: [BoxShadow(color: NexusColors.secondary.withValues(alpha: 0.75), blurRadius: 10)]));
  }
}

class _MiniBlocker extends StatelessWidget {
  const _MiniBlocker({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle_rounded, size: 9, color: NexusColors.error),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: NexusColors.onSurface, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 12))])),
        ],
      ),
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
      backgroundColor: NexusColors.primaryContainer,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.add_rounded, size: 32),
    );
  }
}

class _KanbanTask {
  const _KanbanTask({required this.title, required this.priority, required this.color, required this.assignee, required this.comments, this.description, this.active = false});

  final String title;
  final String priority;
  final Color color;
  final String assignee;
  final String comments;
  final String? description;
  final bool active;

  static const highAuth = _KanbanTask(title: 'Refactor Authentication Microservice', priority: 'High', color: NexusColors.error, assignee: 'AR', comments: '2', description: 'Migrate legacy OAuth flow to the unified identity provider.');
  static const lowTypography = _KanbanTask(title: 'Update UI Typography Tokens', priority: 'Low', color: NexusColors.primary, assignee: 'JD', comments: '0');
  static const activePrompts = _KanbanTask(title: 'Design System Generative Prompts', priority: 'Med', color: NexusColors.secondary, assignee: 'AI', comments: '5', description: 'Draft structural prompts for consistent Nexus UI output.', active: true);
  static const doneAudit = _KanbanTask(title: 'Clean Flutter Analyzer Warnings', priority: 'Done', color: NexusColors.success, assignee: 'KV', comments: '1');
}
