import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/features/ai/presentation/screens/ai_screen.dart';
import 'package:to_do_app/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/screens/analytics/analytics_screen.dart';
import 'package:to_do_app/screens/new_tasks/desktop/desktop_layout.dart';
import 'package:to_do_app/screens/settings/settings_screen.dart';
import 'package:to_do_app/screens/profile/user_profile_screen.dart';
import 'package:to_do_app/screens/support/support_screen.dart';
import 'package:to_do_app/screens/task_details/task_details_desktop_content.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_content.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_models.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_enhancement_widgets.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class DesktopDashboardLayout extends StatefulWidget {
  const DesktopDashboardLayout({super.key});

  @override
  State<DesktopDashboardLayout> createState() => _DesktopDashboardLayoutState();
}

class _DesktopDashboardLayoutState extends State<DesktopDashboardLayout> {
  int _selectedIndex = 0;
  TaskBoardItem? _detailsItem;

  void _openTaskDetails(TaskBoardItem item) =>
      setState(() => _detailsItem = item);

  void _closeTaskDetails() => setState(() => _detailsItem = null);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DesktopSidebar(
          selectedIndex: _selectedIndex,
          onSelected:
              (index) => setState(() {
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
                        key: ValueKey(
                          'dashboard-task-details-${_detailsItem!.title}',
                        ),
                        item: _detailsItem!,
                        onBack: _closeTaskDetails,
                      )
                      : switch (_selectedIndex) {
                        0 => _DashboardMainPane(
                          key: const ValueKey('dashboard-main'),
                          onProfileTap:
                              () => setState(() => _selectedIndex = 7),
                          onNewTask: () => setState(() => _selectedIndex = 8),
                          onAskAI: () => setState(() => _selectedIndex = 2),
                          onSchedule: () => setState(() => _selectedIndex = 3),
                          onAnalytics: () => setState(() => _selectedIndex = 4),
                        ),
                        1 => _ProjectsBoardPane(
                          key: const ValueKey('projects-board'),
                          onProfileTap:
                              () => setState(() => _selectedIndex = 7),
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
                        7 => _ProfilePane(
                          key: const ValueKey('profile'),
                          onNewTask: () => setState(() => _selectedIndex = 8),
                          onProjects: () => setState(() => _selectedIndex = 1),
                        ),
                        8 => NewTasksDesktopLayout(
                          key: const ValueKey('new-task'),
                          onClose: () => setState(() => _selectedIndex = 0),
                        ),
                        _ => _DashboardSectionPlaceholder(
                          index: _selectedIndex,
                        ),
                      },
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardMainPane extends StatelessWidget {
  const _DashboardMainPane({
    super.key,
    required this.onProfileTap,
    required this.onNewTask,
    required this.onAskAI,
    required this.onSchedule,
    required this.onAnalytics,
  });

  final VoidCallback onProfileTap;
  final VoidCallback onNewTask;
  final VoidCallback onAskAI;
  final VoidCallback onSchedule;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DesktopTopbar(onProfileTap: onProfileTap),
        Expanded(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(DashboardSpacing.lg),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: DashboardSpacing.desktopMaxWidth,
                          ),
                          child: _DesktopDashboardContent(
                            onNewTask: onNewTask,
                            onAskAI: onAskAI,
                            onSchedule: onSchedule,
                            onAnalytics: onAnalytics,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Positioned(
                right: DashboardSpacing.lg,
                bottom: DashboardSpacing.lg,
                child: AIAssistantWidget(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfilePane extends StatelessWidget {
  const _ProfilePane({super.key, this.onNewTask, this.onProjects});

  final VoidCallback? onNewTask;
  final VoidCallback? onProjects;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DesktopTopbar(),
        Expanded(
          child: SectionNavigationScope(
            onNewTask: onNewTask ?? () {},
            onProjects: onProjects ?? () {},
            child: const UserProfileScreen(),
          ),
        ),
      ],
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
  final ValueChanged<TaskBoardItem> onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DesktopTopbar(onProfileTap: onProfileTap),
        Expanded(
          child: TasksProjectsDesktopContent(
            onNewTask: onNewTask,
            onViewDetails: onViewDetails,
          ),
        ),
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
  const _DesktopDashboardContent({
    required this.onNewTask,
    required this.onAskAI,
    required this.onSchedule,
    required this.onAnalytics,
  });

  final VoidCallback onNewTask;
  final VoidCallback onAskAI;
  final VoidCallback onSchedule;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardHeader(),
        const SizedBox(height: DashboardSpacing.md),
        QuickActionsGrid(
          onNewTask: onNewTask,
          onAskAI: onAskAI,
          onSchedule: onSchedule,
          onAnalytics: onAnalytics,
        ),
        const SizedBox(height: DashboardSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 1000;
            if (stacked) {
              return const Column(
                children: [
                  FocusScoreCard(),
                  SizedBox(height: DashboardSpacing.md),
                  CurrentFocusSessionCard(),
                  SizedBox(height: DashboardSpacing.md),
                  AIRecommendationCard(),
                  SizedBox(height: DashboardSpacing.md),
                  AIInsightsPanel(),
                  SizedBox(height: DashboardSpacing.md),
                  WeeklySummaryCard(),
                  SizedBox(height: DashboardSpacing.md),
                  ProductivityChartCard(),
                  SizedBox(height: DashboardSpacing.md),
                  QuarterGoalsCard(),
                  SizedBox(height: DashboardSpacing.md),
                  ActivityHeatmapCard(),
                  SizedBox(height: DashboardSpacing.md),
                  UpcomingScheduleCard(),
                  SizedBox(height: DashboardSpacing.md),
                  DailyChallengeCard(),
                  SizedBox(height: DashboardSpacing.md),
                  TeamActivityCard(),
                  SizedBox(height: DashboardSpacing.md),
                  ProjectHealthOverviewCard(),
                  SizedBox(height: DashboardSpacing.md),
                  ActivityTimelineCard(),
                  SizedBox(height: DashboardSpacing.md),
                  AchievementsCard(),
                  SizedBox(height: DashboardSpacing.md),
                  InsightCard(),
                  SizedBox(height: DashboardSpacing.md),
                  KnowledgeHubCard(),
                  SizedBox(height: DashboardSpacing.md),
                  FocusAudioCard(),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                FocusScoreCard(),
                                SizedBox(height: DashboardSpacing.md),
                                CurrentFocusSessionCard(),
                              ],
                            ),
                          ),
                          SizedBox(width: DashboardSpacing.md),
                          Expanded(
                            child: Column(
                              children: [
                                AIRecommendationCard(),
                                SizedBox(height: DashboardSpacing.md),
                                AIInsightsPanel(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: DashboardSpacing.md),
                      WeeklySummaryCard(),
                      SizedBox(height: DashboardSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: ProductivityChartCard()),
                          SizedBox(width: DashboardSpacing.md),
                          Expanded(flex: 2, child: ActivityHeatmapCard()),
                        ],
                      ),
                      SizedBox(height: DashboardSpacing.md),
                      QuarterGoalsCard(),
                      SizedBox(height: DashboardSpacing.md),
                      KnowledgeHubCard(),
                      SizedBox(height: DashboardSpacing.md),
                      FocusAudioCard(),
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
                      DailyChallengeCard(),
                      SizedBox(height: DashboardSpacing.md),
                      TeamActivityCard(),
                      SizedBox(height: DashboardSpacing.md),
                      ProjectHealthOverviewCard(),
                      SizedBox(height: DashboardSpacing.md),
                      ActivityTimelineCard(),
                      SizedBox(height: DashboardSpacing.md),
                      AchievementsCard(),
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
                  'NEXUS AI',
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 4),
              _SignOutButton(onTap: () => signOutDashboard(context)),
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
    final fg =
        active ? DashboardColors.primary : DashboardColors.onSurfaceVariant;
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
          mouseCursor: SystemMouseCursors.click,
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
                Icon(icon, color: fg),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium glass Sign Out button with hover glow + pressed states.
class _SignOutButton extends StatefulWidget {
  const _SignOutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _hover = false;
  bool _pressed = false;

  static const _pink = Color(0xFFFF788C); // rgba(255,120,140)

  @override
  Widget build(BuildContext context) {
    final bgAlpha = _pressed ? 0.28 : (_hover ? 0.20 : 0.12);
    final borderAlpha = _pressed ? 0.55 : (_hover ? 0.45 : 0.28);
    final textColor =
        _pressed
            ? Colors.white
            : (_hover ? const Color(0xFFFFF4F7) : const Color(0xFFFFD6E0));
    final iconColor =
        _pressed
            ? Colors.white
            : (_hover ? const Color(0xFFFFD6E0) : const Color(0xFFFFB7C8));
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: _pink.withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _pink.withValues(alpha: borderAlpha)),
            boxShadow:
                _pressed
                    ? [
                      BoxShadow(
                        color: _pink.withValues(alpha: 0.15),
                        blurRadius: 12,
                      ),
                    ]
                    : _hover
                    ? [
                      BoxShadow(
                        color: _pink.withValues(alpha: 0.20),
                        blurRadius: 24,
                      ),
                    ]
                    : null,
          ),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SearchBarWidget(),
                      const SizedBox(width: 24),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _TopIcon(
                            icon: Icons.notifications_none_rounded,
                            badge: true,
                          ),
                          const SizedBox(width: 12),
                          const _TopIcon(icon: Icons.bolt_rounded),
                          const SizedBox(width: 12),
                          const XPLevelCard(),
                          const SizedBox(width: 12),
                          ProfileAvatar(onTap: onProfileTap, showUsername: true),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  List<TasksProjectItem> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _hideSuggestions();
    });
  }

  @override
  void dispose() {
    _hideSuggestions();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateSuggestions(String value) {
    final query = value.trim().toLowerCase();
    _suggestions =
        query.isEmpty
            ? const []
            : tasksProjectItems
                .where(
                  (item) =>
                      item.kind != TasksProjectCardKind.add &&
                      (item.title.toLowerCase().contains(query) ||
                          item.description.toLowerCase().contains(query) ||
                          item.badge.toLowerCase().contains(query)),
                )
                .take(5)
                .toList();
    if (_suggestions.isEmpty) {
      _hideSuggestions();
    } else {
      _showSuggestions();
    }
  }

  void _showSuggestions() {
    _overlay?.remove();
    _overlay = OverlayEntry(
      builder:
          (context) => Positioned(
            width: 330,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 50),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DashboardColors.surfaceHigh.withValues(alpha: .96),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .35),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in _suggestions)
                        _SearchSuggestionTile(
                          item: item,
                          onTap: () {
                            _controller.text = item.title;
                            _controller.selection = TextSelection.collapsed(
                              offset: item.title.length,
                            );
                            _hideSuggestions();
                            _focusNode.unfocus();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _hideSuggestions() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        width: 330,
        height: 42,
        decoration: BoxDecoration(
          color: DashboardColors.surfaceLow,
          borderRadius: BorderRadius.circular(DashboardRadii.full),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 13,
          ),
          cursorColor: DashboardColors.primary,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded, size: 20),
            prefixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 42),
            hintText: 'Search tasks or intelligence...',
            hintStyle: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 13,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: _updateSuggestions,
          onSubmitted: _updateSuggestions,
        ),
      ),
    );
  }
}

class _SearchSuggestionTile extends StatelessWidget {
  const _SearchSuggestionTile({required this.item, required this.onTap});
  final TasksProjectItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: item.accent.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.manage_search_rounded,
                color: item.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 11,
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
                  '— NEXUS AI Assistant',
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
