import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/constants/colors.dart';
import 'package:to_do_app/features/ai/presentation/screens/ai_screen.dart';
import 'package:to_do_app/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:to_do_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:to_do_app/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:to_do_app/screens/archived/archived_screen.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart'
    hide GlassCard, GlowOrb, GradientButton, SectionTitle;

class BlankPage extends StatefulWidget {
  const BlankPage({super.key});

  @override
  State<BlankPage> createState() => _BlankPageState();
}

class _BlankPageState extends State<BlankPage> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;

  void _selectTab(int index) => setState(() => _selectedIndex = index);
  void _toggleSidebar() {
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      extendBody: true,
      body: _NexusBackground(
        child:
            isDesktop
                ? _DesktopDashboardShell(
                  selectedIndex: _selectedIndex,
                  sidebarCollapsed: _sidebarCollapsed,
                  onTabSelected: _selectTab,
                  onToggleSidebar: _toggleSidebar,
                )
                : _MobileDashboardShell(
                  selectedIndex: _selectedIndex,
                  onTabSelected: _selectTab,
                ),
      ),
    );
  }
}

class _DesktopDashboardShell extends StatelessWidget {
  const _DesktopDashboardShell({
    required this.selectedIndex,
    required this.sidebarCollapsed,
    required this.onTabSelected,
    required this.onToggleSidebar,
  });

  final int selectedIndex;
  final bool sidebarCollapsed;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = sidebarCollapsed ? 88.0 : 280.0;

    return Stack(
      children: [
        Positioned.fill(
          top: 64,
          left: sidebarWidth,
          child: ProfileNavigationScope(
            onProfileSelected: () => onTabSelected(4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: _TabContent(
                key: ValueKey(selectedIndex),
                selectedIndex: selectedIndex,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 64,
          bottom: 0,
          child: _DesktopSidebar(
            collapsed: sidebarCollapsed,
            selectedIndex: selectedIndex,
            onTabSelected: onTabSelected,
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          child: _DesktopTopBar(
            sidebarWidth: sidebarWidth,
            sidebarCollapsed: sidebarCollapsed,
            onToggleSidebar: onToggleSidebar,
            onProfileSelected: () => onTabSelected(4),
          ),
        ),
      ],
    );
  }
}

class _MobileDashboardShell extends StatelessWidget {
  const _MobileDashboardShell({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _MobileTopBar(onProfileSelected: () => onTabSelected(4)),
            Expanded(
              child: ProfileNavigationScope(
                onProfileSelected: () => onTabSelected(4),
                child: _TabContent(selectedIndex: selectedIndex),
              ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
          child: _FloatingMobileNav(
            selectedIndex: selectedIndex,
            onTabSelected: onTabSelected,
          ),
        ),
      ],
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({required this.selectedIndex, super.key});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return switch (selectedIndex) {
      1 => const CalendarScreen(),
      2 => const TasksScreen(),
      3 => const AiScreen(),
      4 => const ProfileScreen(),
      5 => const ArchivedScreen(),
      _ => const _HomeDashboardContent(),
    };
  }
}

class _HomeDashboardContent extends StatelessWidget {
  const _HomeDashboardContent();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final isTablet = width >= 720;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 40 : 16,
        isDesktop ? 32 : 24,
        isDesktop ? 40 : 16,
        isDesktop ? 48 : 132,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop)
                const _DesktopHomeGrid()
              else
                Column(
                  children: [
                    if (isTablet)
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _FlowStateCard()),
                          SizedBox(width: 16),
                          Expanded(child: _NexusIntelligenceCard()),
                        ],
                      )
                    else
                      const Column(
                        children: [
                          _FlowStateCard(),
                          SizedBox(height: 16),
                          _NexusIntelligenceCard(),
                        ],
                      ),
                    const SizedBox(height: 16),
                    const _ActivePrioritiesCard(),
                    const SizedBox(height: 16),
                    const _DeepWorkCard(),
                    const SizedBox(height: 16),
                    const _TimelineCard(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopHomeGrid extends StatelessWidget {
  const _DesktopHomeGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1180) {
          return const Column(
            children: [
              _DesktopActiveSprintBoard(),
              SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _DesktopAiInsightsCard(),
                        SizedBox(height: 24),
                        _DesktopQuickActionsCard(),
                      ],
                    ),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _DesktopNexusFlowCard(),
                        SizedBox(height: 24),
                        _DesktopSmartScheduleCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _DesktopAiInsightsCard(),
                  SizedBox(height: 24),
                  _DesktopQuickActionsCard(),
                ],
              ),
            ),
            SizedBox(width: 24),
            Expanded(flex: 6, child: _DesktopActiveSprintBoard()),
            SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _DesktopNexusFlowCard(),
                  SizedBox(height: 24),
                  _DesktopSmartScheduleCard(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DesktopAiInsightsCard extends StatelessWidget {
  const _DesktopAiInsightsCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.psychology_rounded,
            label: 'AI Insights Focus',
            color: NexusColors.secondary,
          ),
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
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: const AlwaysStoppedAnimation(
                        NexusColors.primary,
                      ),
                    ),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '86',
                        style: TextStyle(
                          color: NexusColors.primary,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Flow Score',
                        style: TextStyle(
                          color: NexusColors.outline,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const _DesktopMetricBlock(
            label: 'Deep Work',
            value: '4h 12m',
            progress: 0.7,
          ),
          const SizedBox(height: 14),
          const _DesktopWarningBlock(),
        ],
      ),
    );
  }
}

class _DesktopQuickActionsCard extends StatelessWidget {
  const _DesktopQuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionLabel(
            icon: Icons.bolt_rounded,
            label: 'Quick Actions',
            color: NexusColors.onSurfaceVariant,
          ),
          SizedBox(height: 16),
          _DesktopActionRow(
            icon: Icons.add_task_rounded,
            label: 'New AI Task',
            color: NexusColors.primary,
          ),
          SizedBox(height: 10),
          _DesktopActionRow(
            icon: Icons.summarize_rounded,
            label: 'Generate Daily Brief',
            color: NexusColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _DesktopActiveSprintBoard extends StatelessWidget {
  const _DesktopActiveSprintBoard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 620;
        final columns = [
          const _DesktopKanbanColumn(
            title: 'To Do',
            count: '3',
            tasks: [_DesktopTask.auth, _DesktopTask.typography],
          ),
          const _DesktopKanbanColumn(
            title: 'In Progress',
            count: '1',
            active: true,
            tasks: [_DesktopTask.prompts],
          ),
          const _DesktopKanbanColumn(
            title: 'Done',
            count: '4',
            tasks: [_DesktopTask.audit],
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DesktopSprintHeader(),
            const SizedBox(height: 18),
            if (stacked)
              Column(
                children: [
                  for (final column in columns) ...[
                    column,
                    const SizedBox(height: 16),
                  ],
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: columns[0]),
                  const SizedBox(width: 16),
                  Expanded(child: columns[1]),
                  const SizedBox(width: 16),
                  Expanded(child: columns[2]),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _DesktopSprintHeader extends StatelessWidget {
  const _DesktopSprintHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Active Sprint',
            style: TextStyle(
              color: NexusColors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: const Row(
            children: [
              _SmallPulseDot(),
              SizedBox(width: 8),
              Text(
                'Syncing',
                style: TextStyle(
                  color: NexusColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopKanbanColumn extends StatelessWidget {
  const _DesktopKanbanColumn({
    required this.title,
    required this.count,
    required this.tasks,
    this.active = false,
  });

  final String title;
  final String count;
  final List<_DesktopTask> tasks;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: active ? NexusColors.primary : NexusColors.outline,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _DesktopCountPill(label: count, active: active),
          ],
        ),
        const SizedBox(height: 12),
        ...tasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DesktopTaskCard(task: task),
          ),
        ),
      ],
    );
  }
}

class _DesktopTaskCard extends StatelessWidget {
  const _DesktopTaskCard({required this.task});

  final _DesktopTask task;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: 14,
      glow: task.active ? NexusColors.primaryContainer : null,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TinyBadge(label: task.priority, color: task.color),
                  const Spacer(),
                  Icon(
                    Icons.more_horiz_rounded,
                    color: NexusColors.outline.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                task.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: NexusColors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              if (task.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NexusColors.outline,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _DesktopAvatarChip(label: task.assignee),
                  const Spacer(),
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: NexusColors.outline,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.comments,
                    style: const TextStyle(
                      color: NexusColors.outline,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopNexusFlowCard extends StatelessWidget {
  const _DesktopNexusFlowCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionLabel(
            icon: Icons.timer_rounded,
            label: 'Nexus Flow',
            color: NexusColors.secondary,
          ),
          SizedBox(height: 18),
          Text(
            '42m',
            style: TextStyle(
              color: NexusColors.secondary,
              fontSize: 46,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Remaining in deep work',
            style: TextStyle(
              color: NexusColors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 18),
          _DesktopMetricBlock(
            label: 'Focus Guard',
            value: 'Active',
            progress: 0.82,
          ),
        ],
      ),
    );
  }
}

class _DesktopSmartScheduleCard extends StatelessWidget {
  const _DesktopSmartScheduleCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionLabel(
            icon: Icons.event_rounded,
            label: 'Smart Schedule',
            color: NexusColors.primary,
          ),
          SizedBox(height: 18),
          _TimelineItem(time: '10:30 AM', title: 'Design Review', active: true),
          _TimelineItem(time: '2:00 PM', title: 'API Sync'),
          _TimelineItem(time: '4:30 PM', title: 'Sprint Planning'),
        ],
      ),
    );
  }
}

class _DesktopMetricBlock extends StatelessWidget {
  const _DesktopMetricBlock({
    required this.label,
    required this.value,
    required this.progress,
  });

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: NexusColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: NexusColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation(NexusColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopWarningBlock extends StatelessWidget {
  const _DesktopWarningBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NexusColors.tertiary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NexusColors.tertiary.withValues(alpha: 0.22)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: NexusColors.tertiary,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Continuous context switching detected. Suggesting a 15-min disconnect protocol.',
              style: TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopActionRow extends StatelessWidget {
  const _DesktopActionRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: NexusColors.onSurface,
                    fontWeight: FontWeight.w800,
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

class _DesktopCountPill extends StatelessWidget {
  const _DesktopCountPill({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            active
                ? NexusColors.primary.withValues(alpha: 0.20)
                : NexusColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? NexusColors.primary : NexusColors.outline,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DesktopAvatarChip extends StatelessWidget {
  const _DesktopAvatarChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(color: NexusColors.surfaceContainerHigh),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: NexusColors.onSurface,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallPulseDot extends StatelessWidget {
  const _SmallPulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: NexusColors.secondary,
        boxShadow: [
          BoxShadow(
            color: NexusColors.secondary.withValues(alpha: 0.75),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _DesktopTask {
  const _DesktopTask({
    required this.title,
    required this.priority,
    required this.color,
    required this.assignee,
    required this.comments,
    this.description,
    this.active = false,
  });

  final String title;
  final String priority;
  final Color color;
  final String assignee;
  final String comments;
  final String? description;
  final bool active;

  static const auth = _DesktopTask(
    title: 'Refactor Authentication Microservice',
    priority: 'High',
    color: NexusColors.tertiary,
    assignee: 'AR',
    comments: '2',
    description: 'Migrate legacy OAuth flow to the unified identity provider.',
  );
  static const typography = _DesktopTask(
    title: 'Update UI Typography Tokens',
    priority: 'Low',
    color: NexusColors.primary,
    assignee: 'JD',
    comments: '0',
  );
  static const prompts = _DesktopTask(
    title: 'Design System Generative Prompts',
    priority: 'Med',
    color: NexusColors.secondary,
    assignee: 'AI',
    comments: '5',
    description: 'Draft structural prompts for consistent Nexus UI output.',
    active: true,
  );
  static const audit = _DesktopTask(
    title: 'Clean Flutter Analyzer Warnings',
    priority: 'Done',
    color: NexusColors.secondary,
    assignee: 'KV',
    comments: '1',
  );
}

class _NexusBackground extends StatelessWidget {
  const _NexusBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFF070B14))),
        Positioned(
          top: -180,
          left: -120,
          child: _GlowOrb(
            size: 520,
            color: NexusColors.primaryContainer.withValues(alpha: 0.14),
          ),
        ),
        Positioned(
          right: -130,
          bottom: -120,
          child: _GlowOrb(
            size: 460,
            color: NexusColors.secondary.withValues(alpha: 0.12),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 130, spreadRadius: 80)],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.collapsed,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final bool collapsed;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: collapsed ? 88 : 280,
      padding: EdgeInsets.fromLTRB(
        collapsed ? 12 : 24,
        24,
        collapsed ? 12 : 24,
        20,
      ),
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainer.withValues(alpha: 0.72),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 24,
          ),
        ],
      ),
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DesktopBrandHeader(collapsed: collapsed),
                const SizedBox(height: 28),
                _DesktopProfileCard(
                  collapsed: collapsed,
                  onTap: () => onTabSelected(4),
                ),
                const SizedBox(height: 28),
                _DesktopDrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: 'NEXUS AI',
                  active: selectedIndex == 0,
                  collapsed: collapsed,
                  onTap: () => onTabSelected(0),
                ),
                _DesktopDrawerItem(
                  icon: Icons.folder_open_rounded,
                  label: 'Tasks',
                  active: selectedIndex == 1,
                  collapsed: collapsed,
                  onTap: () => onTabSelected(1),
                ),
                _DesktopDrawerItem(
                  icon: Icons.biotech_rounded,
                  label: 'AI Labs',
                  active: selectedIndex == 2,
                  collapsed: collapsed,
                  onTap: () => onTabSelected(2),
                ),
                _DesktopDrawerItem(
                  icon: Icons.auto_stories_rounded,
                  label: 'Library',
                  active: selectedIndex == 3,
                  collapsed: collapsed,
                  onTap: () => onTabSelected(3),
                ),
                _DesktopDrawerItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  active: selectedIndex == 4,
                  collapsed: collapsed,
                  onTap: () => onTabSelected(4),
                ),
                _DesktopDrawerItem(
                  icon: Icons.archive_rounded,
                  label: 'Archived',
                  active: selectedIndex == 5,
                  collapsed: collapsed,
                  onTap: () => onTabSelected(5),
                ),
                const Spacer(),
                _DesktopDrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  active: false,
                  collapsed: collapsed,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopBrandHeader extends StatelessWidget {
  const _DesktopBrandHeader({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return const Center(
        child: _GradientIconBox(icon: Icons.graphic_eq_rounded, size: 36),
      );
    }

    return const Row(
      children: [
        _GradientIconBox(icon: Icons.graphic_eq_rounded, size: 40),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Nexus AI',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: NexusColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopProfileCard extends StatelessWidget {
  const _DesktopProfileCard({required this.collapsed, required this.onTap});

  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Center(child: _UserAvatar(small: true, onTap: onTap));
    }

    return Row(
      children: [
        _UserAvatar(small: false, onTap: onTap),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alex Rivera',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: NexusColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Pro Plan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: NexusColors.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.sidebarWidth,
    required this.sidebarCollapsed,
    required this.onToggleSidebar,
    required this.onProfileSelected,
  });

  final double sidebarWidth;
  final bool sidebarCollapsed;
  final VoidCallback onToggleSidebar;
  final VoidCallback onProfileSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainer.withValues(alpha: 0.72),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: sidebarWidth - 24,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: sidebarCollapsed ? 'Open sidebar' : 'Close sidebar',
                onPressed: onToggleSidebar,
                icon: Icon(
                  sidebarCollapsed
                      ? Icons.menu_rounded
                      : Icons.chevron_left_rounded,
                  color: NexusColors.primary,
                ),
              ),
            ),
          ),
          const Text(
            'Nexus AI',
            style: TextStyle(
              color: NexusColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const Spacer(),
          const _SearchField(wide: true),
          const SizedBox(width: 18),
          _RoundAction(
            icon: Icons.notifications_none_rounded,
            badge: true,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _UserAvatar(onTap: onProfileSelected),
        ],
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({required this.onProfileSelected});

  final VoidCallback onProfileSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF070B14).withValues(alpha: 0.78),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _UserAvatar(small: true, onTap: onProfileSelected),
            ),
            const Text(
              'Nexus AI',
              style: TextStyle(
                color: NexusColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _RoundAction(
                icon: Icons.notifications_none_rounded,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({this.wide = false});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      constraints: BoxConstraints(maxWidth: wide ? 520 : 420),
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: NexusColors.onSurface, fontSize: 14),
        cursorColor: NexusColors.primary,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: NexusColors.onSurfaceVariant,
            size: 20,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          hintText:
              wide
                  ? 'Search tasks, insights, or commands (/)'
                  : 'Search Nexus...',
          hintStyle: const TextStyle(
            color: NexusColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        onSubmitted: (value) {
          final query = value.trim();
          if (query.isEmpty) return;
          context.go('/tasks?search=${Uri.encodeComponent(query)}');
        },
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.small = false, required this.onTap});

  final bool small;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final username =
        (metadata?['username'] ?? metadata?['full_name'] ?? user?.email ?? 'U')
            .toString()
            .trim();
    final avatarUrl =
        (metadata?['avatar_url'] ?? metadata?['avatarUrl'] ?? '')
            .toString()
            .trim();
    final initial =
        username.isEmpty ? '?' : username.characters.first.toUpperCase();

    return Tooltip(
      message: 'Open profile',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: CircleAvatar(
          radius: small ? 20 : 22,
          backgroundColor: NexusColors.surfaceContainerHigh,
          backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
          child:
              avatarUrl.isEmpty
                  ? Text(
                    initial,
                    style: const TextStyle(
                      color: NexusColors.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                  : null,
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: NexusColors.surfaceContainer.withValues(alpha: 0.65),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: NexusColors.onSurfaceVariant),
            ),
          ),
        ),
        if (badge)
          Positioned(
            top: 8,
            right: 9,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: NexusColors.tertiary,
              ),
            ),
          ),
      ],
    );
  }
}

class _NexusIntelligenceCard extends StatelessWidget {
  const _NexusIntelligenceCard();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return _GlassPanel(
      glow: NexusColors.primaryContainer,
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              Icons.insights_rounded,
              size: 132,
              color: NexusColors.primary.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(
                icon: Icons.auto_awesome_rounded,
                label: 'Nexus Intelligence',
                color: NexusColors.primary,
              ),
              const SizedBox(height: 14),
              Text.rich(
                const TextSpan(
                  text: 'Based on your current flow, begin the ',
                  children: [
                    TextSpan(
                      text: 'Product Design Task',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(text: ' now.'),
                  ],
                ),
                style: TextStyle(
                  color: NexusColors.onSurface,
                  fontSize: isMobile ? 24 : 30,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Cognitive load is balanced. Starting now can increase deep work retention by 24%.',
                style: TextStyle(
                  color: NexusColors.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 24),
              const _GradientButton(
                label: 'Initiate Task',
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowStateCard extends StatelessWidget {
  const _FlowStateCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      glow: NexusColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flow State',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 176,
              height: 176,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 0.76,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: const AlwaysStoppedAnimation(
                        NexusColors.secondary,
                      ),
                    ),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '76',
                        style: TextStyle(
                          color: NexusColors.secondary,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Optimal',
                        style: TextStyle(
                          color: NexusColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivePrioritiesCard extends StatelessWidget {
  const _ActivePrioritiesCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _CardHeader(title: 'Active Priorities', action: 'View All'),
        SizedBox(height: 14),
        _PriorityTile(
          title: 'Finalize Q3 Design System',
          badge: 'High Priority',
          time: '2h 30m',
          danger: true,
        ),
        SizedBox(height: 12),
        _PriorityTile(
          title: 'Review API Documentation',
          badge: 'Medium',
          time: '45m',
        ),
        SizedBox(height: 12),
        _PriorityTile(
          title: 'Prepare client presentation',
          badge: 'Today',
          time: '1h 15m',
        ),
      ],
    );
  }
}

class _DeepWorkCard extends StatelessWidget {
  const _DeepWorkCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: -28,
            child: Icon(
              Icons.timer_rounded,
              size: 132,
              color: NexusColors.primary.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Deep Work',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Block distractions for 90m',
                style: TextStyle(
                  color: NexusColors.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  _DurationChip(label: '25m'),
                  SizedBox(width: 8),
                  _DurationChip(label: '50m'),
                  SizedBox(width: 8),
                  _DurationChip(label: '90m', active: true),
                ],
              ),
              SizedBox(height: 18),
              _OutlinedAction(
                label: 'Start Session',
                icon: Icons.play_circle_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Timeline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 18),
          _TimelineItem(
            time: 'In 15 mins',
            title: 'Client Presentation',
            active: true,
          ),
          _TimelineItem(time: '2:00 PM', title: 'Tax Submission'),
          _TimelineItem(time: '4:30 PM', title: 'Design Review'),
        ],
      ),
    );
  }
}

class _FloatingMobileNav extends StatelessWidget {
  const _FloatingMobileNav({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: const Color(0xFF121628).withValues(alpha: 0.78),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: NexusColors.secondary.withValues(alpha: 0.20),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: NexusColors.primaryContainer.withValues(alpha: 0.16),
                blurRadius: 28,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _MobileNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Home',
                  active: selectedIndex == 0,
                  onTap: () => onTabSelected(0),
                ),
              ),
              Expanded(
                child: _MobileNavItem(
                  icon: Icons.event_rounded,
                  label: 'Calendar',
                  active: selectedIndex == 1,
                  onTap: () => onTabSelected(1),
                ),
              ),
              Expanded(
                child: _MobileNavItem(
                  icon: Icons.task_alt_rounded,
                  label: 'Tasks',
                  active: selectedIndex == 2,
                  onTap: () => onTabSelected(2),
                ),
              ),
              Expanded(
                child: _MobileNavItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Nexus',
                  active: selectedIndex == 3,
                  onTap: () => onTabSelected(3),
                ),
              ),
              Expanded(
                child: _MobileNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  active: selectedIndex == 4,
                  onTap: () => onTabSelected(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                active
                    ? NexusColors.secondary.withValues(alpha: 0.18)
                    : Colors.transparent,
            boxShadow:
                active
                    ? [
                      BoxShadow(
                        color: NexusColors.secondary.withValues(alpha: 0.32),
                        blurRadius: 18,
                      ),
                    ]
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    active
                        ? NexusColors.secondary
                        : NexusColors.onSurfaceVariant.withValues(alpha: 0.55),
                size: active ? 25 : 22,
              ),
              if (active) ...[
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: NexusColors.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopDrawerItem extends StatelessWidget {
  const _DesktopDrawerItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? NexusColors.primary : NexusColors.onSurfaceVariant;
    final item = Material(
      color:
          active
              ? NexusColors.primaryContainer.withValues(alpha: 0.20)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border:
                active && !collapsed
                    ? const Border(
                      right: BorderSide(color: NexusColors.primary, width: 4),
                    )
                    : null,
          ),
          child:
              collapsed
                  ? Center(child: Icon(icon, color: color, size: 22))
                  : Row(
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tooltip(message: label, child: item),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 28,
    this.glow,
  });

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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
          if (glow != null)
            BoxShadow(color: glow!.withValues(alpha: 0.14), blurRadius: 36),
        ],
      ),
      child: child,
    );
  }
}

class _GradientIconBox extends StatelessWidget {
  const _GradientIconBox({required this.icon, this.size = 48});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          colors: [NexusColors.primary, NexusColors.primaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: NexusColors.primaryContainer.withValues(alpha: 0.35),
            blurRadius: 18,
          ),
        ],
      ),
      child: Icon(icon, color: NexusColors.onPrimary),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [NexusColors.primaryContainer, NexusColors.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: NexusColors.primaryContainer.withValues(alpha: 0.28),
              blurRadius: 22,
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: NexusColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PriorityTile extends StatelessWidget {
  const _PriorityTile({
    required this.title,
    required this.badge,
    required this.time,
    this.danger = false,
  });

  final String title;
  final String badge;
  final String time;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final badgeColor = danger ? NexusColors.tertiary : NexusColors.secondary;

    return _GlassPanel(
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: NexusColors.outlineVariant, width: 2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _TinyBadge(label: badge, color: badgeColor),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: NexusColors.onSurfaceVariant,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            color: NexusColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.play_arrow_rounded,
            color: NexusColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color:
            active
                ? NexusColors.primaryContainer.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color:
              active
                  ? NexusColors.primary
                  : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? NexusColors.primary : NexusColors.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NexusColors.surfaceContainerHighest.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: NexusColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.time,
    required this.title,
    this.active = false,
  });

  final String time;
  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      active
                          ? NexusColors.secondary
                          : NexusColors.surfaceContainerHighest,
                  border: Border.all(color: const Color(0xFF070B14), width: 2),
                  boxShadow:
                      active
                          ? [
                            BoxShadow(
                              color: NexusColors.secondary.withValues(
                                alpha: 0.55,
                              ),
                              blurRadius: 12,
                            ),
                          ]
                          : null,
                ),
              ),
              Expanded(
                child: Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color:
                          active
                              ? NexusColors.secondary
                              : NexusColors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
