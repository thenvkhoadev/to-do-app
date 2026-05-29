import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/features/ai/presentation/screens/ai_screen.dart';
import 'package:to_do_app/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:to_do_app/screens/analytics/analytics_screen.dart';
import 'package:to_do_app/screens/new_tasks/desktop/desktop_layout.dart';
import 'package:to_do_app/screens/settings/settings_screen.dart';
import 'package:to_do_app/screens/profile/user_profile_screen.dart';
import 'package:to_do_app/screens/support/support_screen.dart';
import 'package:to_do_app/screens/task_details/task_details_desktop_content.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_content.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_models.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class DesktopDashboardLayout extends StatefulWidget {
  const DesktopDashboardLayout({super.key});

  @override
  State<DesktopDashboardLayout> createState() => _DesktopDashboardLayoutState();
}

class _DesktopDashboardLayoutState extends State<DesktopDashboardLayout> {
  int _selectedIndex = 0;
  TasksProjectItem? _detailsItem;

  void _openTaskDetails(TasksProjectItem item) => setState(() => _detailsItem = item);

  void _closeTaskDetails() => setState(() => _detailsItem = null);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DesktopSidebar(
          selectedIndex: _selectedIndex,
          onSelected: (index) => setState(() {
            _detailsItem = null;
            _selectedIndex = index;
          }),
        ),
        Expanded(
          child: ProfileNavigationScope(
            onProfileSelected: () => setState(() => _selectedIndex = 7),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child:
                  _detailsItem != null
                      ? TaskDetailsDesktopContent(
                        key: ValueKey('dashboard-task-details-${_detailsItem!.title}'),
                        item: _detailsItem!,
                        onBack: _closeTaskDetails,
                      )
                      : switch (_selectedIndex) {
                0 => _DashboardMainPane(
                  key: const ValueKey('dashboard-main'),
                  onProfileTap: () => setState(() => _selectedIndex = 7),
                ),
                1 => _ProjectsBoardPane(
                  key: const ValueKey('projects-board'),
                  onProfileTap: () => setState(() => _selectedIndex = 7),
                  onNewTask: () => setState(() => _selectedIndex = 8),
                  onViewDetails: _openTaskDetails,
                ),
                2 => const DesktopAiAssistantContent(
                  key: ValueKey('ai-assistant'),
                ),
                3 => const CalendarScreen(key: ValueKey('calendar')),
                4 => const AnalyticsScreen(
                  key: ValueKey('analytics'),
                  embeddedInDashboard: true,
                ),
                5 => const SettingsScreen(
                  key: ValueKey('settings'),
                  embeddedInDashboard: true,
                ),
                6 => const SupportScreen(
                  key: ValueKey('support'),
                  embeddedInDashboard: true,
                ),
                7 => const _ProfilePane(key: ValueKey('profile')),
                8 => NewTasksDesktopLayout(
                  key: const ValueKey('new-task'),
                  onClose: () => setState(() => _selectedIndex = 0),
                ),
                _ => _DashboardSectionPlaceholder(index: _selectedIndex),
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardMainPane extends StatelessWidget {
  const _DashboardMainPane({super.key, required this.onProfileTap});

  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DesktopTopbar(onProfileTap: onProfileTap),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(DashboardSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: DashboardSpacing.desktopMaxWidth,
                      ),
                      child: const _DesktopDashboardContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfilePane extends StatelessWidget {
  const _ProfilePane({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [DesktopTopbar(), Expanded(child: UserProfileScreen())],
    );
  }
}

class _ProjectsBoardPane extends StatelessWidget {
  const _ProjectsBoardPane({
    super.key,
    required this.onProfileTap,
    required this.onNewTask,
    required this.onViewDetails,
  });

  final VoidCallback onProfileTap;
  final VoidCallback onNewTask;
  final ValueChanged<TasksProjectItem> onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DesktopTopbar(onProfileTap: onProfileTap),
        Expanded(child: TasksProjectsDesktopContent(onNewTask: onNewTask, onViewDetails: onViewDetails)),
      ],
    );
  }
}

class _DashboardSectionPlaceholder extends StatelessWidget {
  const _DashboardSectionPlaceholder({required this.index});

  final int index;

  String get _title => switch (index) {
    1 => 'Projects',
    2 => 'Intelligence',
    3 => 'Calendar',
    4 => 'Analytics',
    5 => 'Settings',
    6 => 'Support',
    _ => 'Dashboard',
  };

  IconData get _icon => switch (index) {
    1 => Icons.account_tree_rounded,
    2 => Icons.psychology_rounded,
    3 => Icons.calendar_month_rounded,
    4 => Icons.query_stats_rounded,
    5 => Icons.settings_rounded,
    6 => Icons.help_outline_rounded,
    _ => Icons.dashboard_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('dashboard-section-$index'),
      children: [
        const DesktopTopbar(),
        Expanded(
          child: Center(
            child: GlassCard(
              padding: const EdgeInsets.all(34),
              child: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon, color: DashboardColors.primary, size: 44),
                    const SizedBox(height: 16),
                    Text(
                      _title,
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sidebar đang đứng yên trong Dashboard shell. Vùng nội dung bên phải đổi theo mục được chọn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopDashboardContent extends StatelessWidget {
  const _DesktopDashboardContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardHeader(),
        const SizedBox(height: DashboardSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 1000;
            if (stacked) {
              return const Column(
                children: [
                  FocusScoreCard(),
                  SizedBox(height: DashboardSpacing.md),
                  AIRecommendationCard(),
                  SizedBox(height: DashboardSpacing.md),
                  ProductivityChartCard(),
                  SizedBox(height: DashboardSpacing.md),
                  UpcomingScheduleCard(),
                  SizedBox(height: DashboardSpacing.md),
                  ActivityTimelineCard(),
                  SizedBox(height: DashboardSpacing.md),
                  InsightCard(),
                ],
              );
            }

            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 8,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: FocusScoreCard()),
                          SizedBox(width: DashboardSpacing.md),
                          Expanded(child: AIRecommendationCard()),
                        ],
                      ),
                      SizedBox(height: DashboardSpacing.md),
                      ProductivityChartCard(),
                    ],
                  ),
                ),
                SizedBox(width: DashboardSpacing.md),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      UpcomingScheduleCard(),
                      SizedBox(height: DashboardSpacing.md),
                      ActivityTimelineCard(),
                      SizedBox(height: DashboardSpacing.md),
                      InsightCard(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: DashboardSpacing.sidebar,
          padding: const EdgeInsets.fromLTRB(24, 32, 16, 20),
          decoration: BoxDecoration(
            color: DashboardColors.surfaceLowest.withValues(alpha: .8),
            border: Border(
              right: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .28),
                blurRadius: 28,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShaderMask(
                shaderCallback:
                    (rect) => const LinearGradient(
                      colors: [
                        DashboardColors.primary,
                        DashboardColors.secondary,
                      ],
                    ).createShader(rect),
                child: const Text(
                  'TaskFlow AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Deep Work Mode',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 40),
              _SidebarItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                active: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
              _SidebarItem(
                icon: Icons.account_tree_rounded,
                label: 'Projects',
                active: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
              _SidebarItem(
                icon: Icons.psychology_rounded,
                label: 'Intelligence',
                active: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
              _SidebarItem(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                active: selectedIndex == 3,
                onTap: () => onSelected(3),
              ),
              _SidebarItem(
                icon: Icons.query_stats_rounded,
                label: 'Analytics',
                active: selectedIndex == 4,
                onTap: () => onSelected(4),
              ),
              const Spacer(),
              GradientButton(
                label: 'New Task',
                icon: Icons.add_rounded,
                expanded: true,
                onPressed: () => onSelected(8),
              ),
              const SizedBox(height: 22),
              _SidebarItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                active: selectedIndex == 5,
                onTap: () => onSelected(5),
              ),
              _SidebarItem(
                icon: Icons.help_outline_rounded,
                label: 'Support',
                active: selectedIndex == 6,
                onTap: () => onSelected(6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color:
            active
                ? DashboardColors.primary.withValues(alpha: .1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border(
                right: BorderSide(
                  color: active ? DashboardColors.primary : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      active
                          ? DashboardColors.primary
                          : DashboardColors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        active
                            ? DashboardColors.primary
                            : DashboardColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
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

class DesktopTopbar extends StatelessWidget {
  const DesktopTopbar({this.onProfileTap, super.key});

  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: DashboardColors.surface.withValues(alpha: .5),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
          ),
          child: Row(
            children: [
              const SearchBarWidget(),
              const Spacer(),
              const _TopIcon(
                icon: Icons.notifications_none_rounded,
                badge: true,
              ),
              const SizedBox(width: 12),
              const _TopIcon(icon: Icons.bolt_rounded),
              const SizedBox(width: 12),
              ProfileAvatar(onTap: onProfileTap, showUsername: true),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: DashboardColors.surfaceLow,
        borderRadius: BorderRadius.circular(DashboardRadii.full),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, size: 20),
          SizedBox(width: 10),
          Text(
            'Search tasks or intelligence...',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon, this.badge = false});

  final IconData icon;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: DashboardColors.onSurface),
            ),
          ),
        ),
        if (badge)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: DashboardColors.error,
              ),
            ),
          ),
      ],
    );
  }
}

class FocusScoreCard extends StatelessWidget {
  const FocusScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnimatedHoverCard(
      glowColor: DashboardColors.primary,
      child: Column(
        children: [
          SectionTitle(label: "Today’s Focus Score"),
          SizedBox(height: 22),
          CircularScore(value: .85, label: 'Flow State', size: 190),
          SizedBox(height: 18),
          Text(
            'You are 12% more focused than last Monday.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class AIRecommendationCard extends StatelessWidget {
  const AIRecommendationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      glowColor: DashboardColors.secondary,
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -55,
            child: Icon(
              Icons.psychology_rounded,
              size: 170,
              color: DashboardColors.secondary.withValues(alpha: .07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SectionTitle(
                label: 'AI Recommendation',
                icon: Icons.psychology_rounded,
                color: DashboardColors.secondary,
              ),
              SizedBox(height: 18),
              Text(
                'Finalize Brand Guidelines for Project Helios',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 24,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  _Meta(icon: Icons.schedule_rounded, label: '45 min'),
                  SizedBox(width: 18),
                  _Meta(
                    icon: Icons.priority_high_rounded,
                    label: 'High Priority',
                  ),
                ],
              ),
              SizedBox(height: 34),
              GradientButton(
                label: 'Start Now',
                icon: Icons.arrow_forward_rounded,
                expanded: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: DashboardColors.onSurfaceVariant),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: DashboardColors.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    ],
  );
}

class ProductivityChartCard extends StatelessWidget {
  const ProductivityChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnimatedHoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SectionTitle(label: 'Weekly Productivity'),
              Spacer(),
              Text(
                'This Week',
                style: TextStyle(
                  color: DashboardColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          AnalyticsBars(),
        ],
      ),
    );
  }
}

class UpcomingScheduleCard extends StatelessWidget {
  const UpcomingScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Text(
                'Upcoming',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              Text(
                'View All',
                style: TextStyle(
                  color: DashboardColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _ScheduleRow(
            time: '10',
            meridiem: 'AM',
            title: 'Stakeholder Sync',
            subtitle: 'Google Meet • 45 min',
            color: DashboardColors.primary,
          ),
          _ScheduleRow(
            time: '02',
            meridiem: 'PM',
            title: 'Design Critique',
            subtitle: 'Conference Room B • 1h',
            color: DashboardColors.secondary,
          ),
          _ScheduleRow(
            time: '04',
            meridiem: 'PM',
            title: 'Weekly Retro',
            subtitle: 'Slack • 30 min',
            color: DashboardColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.time,
    required this.meridiem,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final String time;
  final String meridiem;
  final String title;
  final String subtitle;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  meridiem,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityTimelineCard extends StatelessWidget {
  const ActivityTimelineCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Recent Activity',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 18),
          _TimelineEvent(
            icon: Icons.check_rounded,
            color: DashboardColors.primary,
            text: 'Completed Mobile App v2.4 design sprint',
            time: '2 hours ago',
          ),
          _TimelineEvent(
            icon: Icons.edit_rounded,
            color: DashboardColors.secondary,
            text: 'Updated Project Helios documentation',
            time: '4 hours ago',
          ),
          _TimelineEvent(
            icon: Icons.chat_bubble_rounded,
            color: DashboardColors.tertiary,
            text: 'Sarah commented on User Flow UX',
            time: 'Yesterday',
          ),
        ],
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({
    required this.icon,
    required this.color,
    required this.text,
    required this.time,
  });
  final IconData icon;
  final Color color;
  final String text;
  final String time;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: DashboardColors.onPrimary, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    height: 1.35,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InsightCard extends StatelessWidget {
  const InsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(DashboardSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: DashboardColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“You tend to be most productive between 10 AM and 1 PM. I’ve blocked tomorrow for deep work.”',
                  style: TextStyle(
                    color: DashboardColors.onSurface,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '— TaskFlow Assistant',
                  style: TextStyle(
                    color: DashboardColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> signOutDashboard(BuildContext context) async {
  await Supabase.instance.client.auth.signOut();
  if (context.mounted) context.go('/login');
}
