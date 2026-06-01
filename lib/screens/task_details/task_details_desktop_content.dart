import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_models.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskDetailsDesktopContent extends StatelessWidget {
  const TaskDetailsDesktopContent({
    required this.item,
    required this.onBack,
    super.key,
  });

  final TasksProjectItem item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _AmbientGlows(),
        Column(
          children: [
            _TaskDetailsHeader(item: item, onBack: onBack),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1100;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 110),
                    child:
                        wide
                            ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _LeftColumn(item: item),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 5,
                                  child: _RightColumn(item: item),
                                ),
                              ],
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LeftColumn(item: item),
                                const SizedBox(height: 32),
                                _RightColumn(item: item),
                              ],
                            ),
                  );
                },
              ),
            ),
          ],
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 28,
          child: _AiSuggestionDock(),
        ),
        const Positioned(right: 32, bottom: 32, child: _FloatingDetailsFab()),
        const Positioned(
          right: 104,
          bottom: 34,
          child: _CommandPaletteButton(),
        ),
      ],
    );
  }
}

class _TaskDetailsHeader extends StatelessWidget {
  const _TaskDetailsHeader({required this.item, required this.onBack});

  final TasksProjectItem item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: DashboardColors.surface.withValues(alpha: .42),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: DashboardColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              _Pill(label: item.badge, color: item.accent),
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DashboardColors.outlineVariant.withValues(alpha: .45),
                ),
              ),
              Text(
                'TASK-${940 + item.kind.index}',
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const _DeepWorkButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.item});
  final TasksProjectItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TaskHero(item: item),
        const SizedBox(height: 24),
        _TaskMetadataCards(item: item),
        const SizedBox(height: 16),
        const _TeamPresenceRow(),
        const SizedBox(height: 24),
        const _SmartTabsSection(),
        const SizedBox(height: 24),
        const _FocusHistoryChart(),
        const SizedBox(height: 24),
        const _ContextualIntelligenceSection(),
        const SizedBox(height: 24),
        const _ProductivityEnhancements(),
      ],
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({required this.item});
  final TasksProjectItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AiAtomicExecutionPanel(progress: item.progress ?? .75),
        const SizedBox(height: 16),
        const _SmartPriorityHeatmap(),
        const SizedBox(height: 16),
        const _LiveActivityTimeline(),
        const SizedBox(height: 24),
        const _StrategyVisualizationCard(),
      ],
    );
  }
}

class _TaskHero extends StatelessWidget {
  const _TaskHero({required this.item});
  final TasksProjectItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 34,
                  height: 1.16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.4,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const _FocusTimerWidget(),
          ],
        ),
        const SizedBox(height: 14),
        const _AiInsightsCard(),
        const SizedBox(height: 16),
        Text(
          item.description,
          style: const TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 18,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        const _ExpandableSubtasksSection(),
      ],
    );
  }
}

class _TaskMetadataCards extends StatelessWidget {
  const _TaskMetadataCards({required this.item});
  final TasksProjectItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetadataCard(
            label: 'PRIORITY',
            value: _priorityLabel(item),
            icon: Icons.error_rounded,
            color: DashboardColors.error,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetadataCard(
            label: 'DEADLINE',
            value: item.metaRight ?? 'Today',
            icon: Icons.calendar_today_rounded,
            color: DashboardColors.onSurface,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetadataCard(
            label: 'PROJECT',
            value: item.badge,
            icon: Icons.folder_rounded,
            color: DashboardColors.tertiary,
          ),
        ),
      ],
    );
  }

  String _priorityLabel(TasksProjectItem item) => switch (item.kind) {
    TasksProjectCardKind.urgent || TasksProjectCardKind.priority => 'High',
    TasksProjectCardKind.review => 'Medium',
    _ => 'Smart',
  };
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DashboardColors.surfaceHigh.withValues(alpha: .34),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusHistoryChart extends StatelessWidget {
  const _FocusHistoryChart();

  @override
  Widget build(BuildContext context) {
    const bars = [.40, .60, .30, .90, .55, .75, .45, .85, .25, .95];
    return _GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Focus History',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _LegendDot(color: DashboardColors.primary.withValues(alpha: .40)),
              const SizedBox(width: 8),
              const _LegendDot(color: DashboardColors.primary),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                bars.length,
                (index) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _ChartBar(
                      value: bars[index],
                      active: index == bars.length - 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Text(
                '14 Oct',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Spacer(),
              Text(
                'Today',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({required this.value, required this.active});
  final double value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: Duration(milliseconds: active ? 900 : 650),
      curve: Curves.easeOutCubic,
      builder:
          (context, animated, _) => Tooltip(
            message:
                active ? '4.8h' : '${(animated * 4.8).toStringAsFixed(1)}h',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 150 * animated,
              decoration: BoxDecoration(
                color:
                    active
                        ? DashboardColors.primary
                        : DashboardColors.primary.withValues(alpha: .20),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                boxShadow:
                    active
                        ? [
                          BoxShadow(
                            color: DashboardColors.primary.withValues(
                              alpha: .28,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, -5),
                          ),
                        ]
                        : null,
              ),
            ),
          ),
    );
  }
}

class _ContextualIntelligenceSection extends StatelessWidget {
  const _ContextualIntelligenceSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.hub_rounded, color: DashboardColors.secondary, size: 20),
            SizedBox(width: 8),
            Text(
              'Contextual Intelligence',
              style: TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _KnowledgeGraphPreview(),
        const SizedBox(height: 14),
        const _ContextInsightCard(
          icon: Icons.mail_rounded,
          color: DashboardColors.primary,
          title: 'Fwd: AI Infrastructure Updates',
          subtitle:
              'From CTO - Contains critical cost metrics for next quarter...',
        ),
        const SizedBox(height: 12),
        const _ContextInsightCard(
          icon: Icons.description_rounded,
          color: DashboardColors.secondary,
          title: 'Q3 Competitive Landscape.pdf',
          subtitle: "AI-extracted summary: 12 references to 'NEXUS AI'...",
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _AssetCard(
                icon: Icons.table_chart_rounded,
                title: 'Revenue_Projections.xlsx',
                color: DashboardColors.tertiary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _AssetCard(
                icon: Icons.analytics_rounded,
                title: 'Market_Analysis_v4.pdf',
                color: DashboardColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContextInsightCard extends StatelessWidget {
  const _ContextInsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => _HoverScale(
    child: _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DashboardColors.surfaceHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.open_in_new_rounded,
            color: DashboardColors.onSurfaceVariant,
            size: 18,
          ),
        ],
      ),
    ),
  );
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.icon,
    required this.title,
    required this.color,
  });
  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => _HoverScale(
    child: _GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.open_in_new_rounded,
            color: DashboardColors.onSurfaceVariant,
            size: 16,
          ),
        ],
      ),
    ),
  );
}

class _ProductivityEnhancements extends StatelessWidget {
  const _ProductivityEnhancements();

  @override
  Widget build(BuildContext context) => Row(
    children: const [
      Expanded(
        child: _MiniStat(
          label: 'Session',
          value: '2h 30m',
          icon: Icons.timer_rounded,
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: _MiniStat(
          label: 'Team',
          value: '4 live',
          icon: Icons.groups_rounded,
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: _MiniStat(
          label: 'AI Score',
          value: '94%',
          icon: Icons.auto_graph_rounded,
        ),
      ),
    ],
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Icon(icon, color: DashboardColors.tertiary, size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AiAtomicExecutionPanel extends StatelessWidget {
  const _AiAtomicExecutionPanel({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return _AiGlowContainer(
      child: Stack(
        children: [
          Positioned.fill(child: IgnorePointer(child: _ShimmerOverlay())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DashboardColors.primary.withValues(alpha: .18),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: DashboardColors.primary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Atomic Execution',
                      style: TextStyle(
                        color: DashboardColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _Pill(
                    label: 'AI GENERATED',
                    color: DashboardColors.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _ExecutionProgressItem(
                label: 'Market Gap Analysis',
                value: 1,
              ),
              const _ExecutionProgressItem(
                label: 'Roadmap Delta Calculation',
                value: .75,
              ),
              const _ExecutionProgressItem(
                label: 'Resource Allocation Audit',
                value: .40,
                color: DashboardColors.secondary,
              ),
              const _ExecutionProgressItem(
                label: 'Technical Feasibility Check',
                value: 0,
              ),
              const _ExecutionProgressItem(
                label: 'Final Strategy Compilation',
                value: 0,
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withValues(alpha: .08)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Regenerate Execution Plan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExecutionProgressItem extends StatelessWidget {
  const _ExecutionProgressItem({
    required this.label,
    required this.value,
    this.color = DashboardColors.primary,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: value == 0 ? DashboardColors.onSurfaceVariant : color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder:
                (context, animated, _) => LinearProgressIndicator(
                  value: animated,
                  minHeight: 6,
                  backgroundColor: DashboardColors.surfaceHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
          ),
        ),
      ],
    ),
  );
}

class _StrategyVisualizationCard extends StatelessWidget {
  const _StrategyVisualizationCard();

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Container(
        height: 192,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [
              DashboardColors.tertiary.withValues(alpha: .22),
              DashboardColors.secondary.withValues(alpha: .10),
              DashboardColors.surfaceLowest,
            ],
          ),
        ),
        child: Stack(
          children: [
            for (var i = 0; i < 9; i++)
              Positioned(
                left: 32.0 + i * 42,
                top: 32.0 + (i.isEven ? 18 : 72),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DashboardColors.primary.withValues(alpha: .75),
                    boxShadow: [
                      BoxShadow(
                        color: DashboardColors.primary.withValues(alpha: .32),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
            const Positioned(
              left: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROJECT VISUALIZATION',
                    style: TextStyle(
                      color: DashboardColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Market Trend Synthesis',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeepWorkButton extends StatelessWidget {
  const _DeepWorkButton();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .55, end: 1),
    duration: const Duration(milliseconds: 1200),
    curve: Curves.easeOutCubic,
    builder:
        (context, value, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.primary.withValues(
                  alpha: .14 + value * .08,
                ),
                blurRadius: 28,
              ),
            ],
          ),
          child: child,
        ),
    child: FilledButton.icon(
      onPressed:
          () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deep Work Mode activated')),
          ),
      icon: const Icon(Icons.track_changes_rounded),
      label: const Text('Enter Deep Work Mode'),
    ),
  );
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .03),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: child,
      ),
    ),
  );
}

class _AiGlowContainer extends StatelessWidget {
  const _AiGlowContainer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(32),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: DashboardColors.primary.withValues(alpha: .22),
          ),
          boxShadow: [
            BoxShadow(
              color: DashboardColors.primary.withValues(alpha: .15),
              blurRadius: 34,
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

class _HoverScale extends StatefulWidget {
  const _HoverScale({required this.child});
  final Widget child;
  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedScale(
      scale: _hovered ? 1.012 : 1,
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: .18)),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _ShimmerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: -1, end: 1),
    duration: const Duration(seconds: 2),
    curve: Curves.easeInOut,
    builder:
        (context, value, _) => FractionalTranslation(
          translation: Offset(value, 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: .04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
  );
}

class _AiInsightsCard extends StatelessWidget {
  const _AiInsightsCard();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .4, end: 1),
    duration: const Duration(milliseconds: 1000),
    curve: Curves.easeOutCubic,
    builder:
        (context, value, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                DashboardColors.primary.withValues(alpha: .18 * value),
                DashboardColors.secondary.withValues(alpha: .14),
                Colors.white.withValues(alpha: .03),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.primary.withValues(alpha: .10 * value),
                blurRadius: 28,
              ),
            ],
          ),
          child: child,
        ),
    child: _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: DashboardColors.tertiary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'AI Insights',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _InsightLine('82% roadmap alignment'),
          _InsightLine('Market volatility risk detected'),
          _InsightLine('Suggested release window: Q1'),
          _InsightLine('Resource allocation imbalance found'),
        ],
      ),
    ),
  );
}

class _InsightLine extends StatelessWidget {
  const _InsightLine(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: DashboardColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 13,
              height: 1.25,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TeamPresenceRow extends StatelessWidget {
  const _TeamPresenceRow();

  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: const [
        _PresenceAvatar(label: 'A', color: DashboardColors.primary),
        _OverlapAvatar(label: 'M', color: DashboardColors.secondary),
        _OverlapAvatar(label: 'K', color: DashboardColors.tertiary),
        SizedBox(width: 14),
        Expanded(
          child: Text(
            '3 collaborators active • Alex is typing • 12 live viewers',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _PulseDot(),
      ],
    ),
  );
}

class _PresenceAvatar extends StatelessWidget {
  const _PresenceAvatar({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      CircleAvatar(
        radius: 15,
        backgroundColor: color.withValues(alpha: .18),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const Positioned(right: -1, bottom: -1, child: _OnlineDot()),
    ],
  );
}

class _OverlapAvatar extends StatelessWidget {
  const _OverlapAvatar({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(-8, 0),
    child: _PresenceAvatar(label: label, color: color),
  );
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();
  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF7CFFB2),
      border: Border.all(color: DashboardColors.background, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF7CFFB2).withValues(alpha: .35),
          blurRadius: 8,
        ),
      ],
    ),
  );
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .4, end: 1),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    builder:
        (context, value, _) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DashboardColors.primary.withValues(alpha: value),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.primary.withValues(alpha: .35 * value),
                blurRadius: 14,
              ),
            ],
          ),
        ),
  );
}

class _SmartTabsSection extends StatelessWidget {
  const _SmartTabsSection();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: _GlassPanel(
        padding: const EdgeInsets.all(10),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              isScrollable: true,
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.all(Radius.circular(999)),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(999)),
                color: Color(0x2E8083FF),
                border: Border.fromBorderSide(
                  BorderSide(color: DashboardColors.primary),
                ),
              ),
              labelColor: DashboardColors.primary,
              unselectedLabelColor: DashboardColors.onSurfaceVariant,
              labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Notes'),
                Tab(text: 'Activity'),
                Tab(text: 'Files'),
                Tab(text: 'AI'),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 88,
              child: TabBarView(
                children: [
                  _TabCopy(
                    'Roadmap context, key blockers, and active execution plan are synced.',
                  ),
                  _TabCopy(
                    'AI notes updated from meeting summary and linked documents.',
                  ),
                  _TabCopy('4 updates in the last 30 minutes.'),
                  _TabCopy('2 PDFs, 1 spreadsheet, 1 strategy board.'),
                  _TabCopy('AI recommends splitting into 4 milestones.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabCopy extends StatelessWidget {
  const _TabCopy(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: DashboardColors.onSurfaceVariant,
        height: 1.4,
      ),
    ),
  );
}

class _ExpandableSubtasksSection extends StatelessWidget {
  const _ExpandableSubtasksSection();
  @override
  Widget build(BuildContext context) => Column(
    children: const [
      _SubtaskExpansion(
        title: 'Strategic Research',
        progress: .82,
        items: ['Validate Q4 market signals', 'Compare release windows'],
      ),
      _SubtaskExpansion(
        title: 'Competitive Mapping',
        progress: .64,
        items: ['Review AI calendar tools', 'Tag pricing threats'],
      ),
      _SubtaskExpansion(
        title: 'Resource Planning',
        progress: .40,
        items: ['Balance design capacity', 'Flag engineering risk'],
      ),
    ],
  );
}

class _SubtaskExpansion extends StatelessWidget {
  const _SubtaskExpansion({
    required this.title,
    required this.progress,
    required this.items,
  });
  final String title;
  final double progress;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _GlassPanel(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            iconColor: DashboardColors.primary,
            collapsedIconColor: DashboardColors.onSurfaceVariant,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: DashboardColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: DashboardColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: DashboardColors.surfaceHighest,
                  valueColor: const AlwaysStoppedAnimation(
                    DashboardColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: DashboardColors.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KnowledgeGraphPreview extends StatelessWidget {
  const _KnowledgeGraphPreview();
  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      height: 118,
      child: Stack(
        children: const [
          _GraphLine(left: 46, top: 34, width: 130),
          _GraphLine(left: 164, top: 66, width: 110),
          _GraphNode(
            left: 18,
            top: 40,
            label: 'Docs',
            color: DashboardColors.primary,
          ),
          _GraphNode(
            left: 142,
            top: 18,
            label: 'Tasks',
            color: DashboardColors.secondary,
          ),
          _GraphNode(
            left: 246,
            top: 72,
            label: 'Q4',
            color: DashboardColors.tertiary,
          ),
          Positioned(
            left: 12,
            bottom: 0,
            child: Text(
              'AI mapped 9 relationships across docs, tasks, and roadmap risks.',
              style: TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GraphNode extends StatelessWidget {
  const _GraphNode({
    required this.left,
    required this.top,
    required this.label,
    required this.color,
  });
  final double left;
  final double top;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .18), blurRadius: 18),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _GraphLine extends StatelessWidget {
  const _GraphLine({
    required this.left,
    required this.top,
    required this.width,
  });
  final double left;
  final double top;
  final double width;
  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    child: Container(
      width: width,
      height: 1.2,
      color: DashboardColors.primary.withValues(alpha: .18),
    ),
  );
}

class _SmartPriorityHeatmap extends StatelessWidget {
  const _SmartPriorityHeatmap();
  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Priority Heatmap',
          style: TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 12),
        _HeatRow(label: 'High', value: .82, color: DashboardColors.error),
        _HeatRow(label: 'Medium', value: .58, color: DashboardColors.secondary),
        _HeatRow(label: 'Low', value: .28, color: DashboardColors.tertiary),
      ],
    ),
  );
}

class _HeatRow extends StatelessWidget {
  const _HeatRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 700),
                builder:
                    (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: DashboardColors.surfaceHighest,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveActivityTimeline extends StatelessWidget {
  const _LiveActivityTimeline();
  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Live Activity',
          style: TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 14),
        _ActivityLine('Alex updated roadmap'),
        _ActivityLine('AI summarized PDF'),
        _ActivityLine('Deadline modified'),
        _ActivityLine('New document attached'),
      ],
    ),
  );
}

class _ActivityLine extends StatelessWidget {
  const _ActivityLine(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        const _PulseDot(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FocusTimerWidget extends StatelessWidget {
  const _FocusTimerWidget();
  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            value: .68,
            strokeWidth: 3,
            color: DashboardColors.primary,
            backgroundColor: DashboardColors.surfaceHighest,
          ),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '45:22 Focus Session',
              style: TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Streak 6 • Score 94',
              style: TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AiSuggestionDock extends StatelessWidget {
  const _AiSuggestionDock();
  @override
  Widget build(BuildContext context) => Center(
    child: _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: DashboardColors.secondary,
            size: 18,
          ),
          const SizedBox(width: 10),
          const Text(
            'AI Suggestion: ',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'Split strategy review into 4 milestones',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 14),
          TextButton(onPressed: () {}, child: const Text('Apply')),
          TextButton(onPressed: () {}, child: const Text('Dismiss')),
        ],
      ),
    ),
  );
}

class _CommandPaletteButton extends StatelessWidget {
  const _CommandPaletteButton();
  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: EdgeInsets.zero,
    child: SizedBox(
      width: 52,
      height: 52,
      child: Center(
        child: Text(
          '⌘K',
          style: TextStyle(
            color: DashboardColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: DashboardColors.primary.withValues(alpha: .45),
                blurRadius: 16,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FloatingDetailsFab extends StatelessWidget {
  const _FloatingDetailsFab();
  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: DashboardColors.primary,
      boxShadow: [
        BoxShadow(
          color: DashboardColors.primary.withValues(alpha: .24),
          blurRadius: 28,
        ),
      ],
    ),
    child: const Icon(
      Icons.add_rounded,
      color: DashboardColors.onPrimaryContainer,
    ),
  );
}

class _AmbientGlows extends StatelessWidget {
  const _AmbientGlows();
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        top: 120,
        right: -100,
        child: _Glow(color: DashboardColors.primary.withValues(alpha: .11)),
      ),
      Positioned(
        bottom: 120,
        left: -120,
        child: _Glow(color: DashboardColors.secondary.withValues(alpha: .10)),
      ),
    ],
  );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 280,
    height: 280,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 110, spreadRadius: 50)],
    ),
  );
}
