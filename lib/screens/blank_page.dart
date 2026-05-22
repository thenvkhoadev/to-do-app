import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/constants/colors.dart';
import 'package:to_do_app/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:to_do_app/screens/sign_in_page.dart';

class BlankPage extends StatefulWidget {
  const BlankPage({super.key});

  @override
  State<BlankPage> createState() => _BlankPageState();
}

class _BlankPageState extends State<BlankPage> {
  int _selectedIndex = 0;

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _DashboardBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _DashboardTopBar(
                selectedIndex: _selectedIndex,
                onTabSelected: _selectTab,
              ),
              Expanded(child: _DashboardTabView(selectedIndex: _selectedIndex)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _MobileBottomNav(
        selectedIndex: _selectedIndex,
        onTabSelected: _selectTab,
      ),
    );
  }
}

class _DashboardTabView extends StatelessWidget {
  const _DashboardTabView({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return switch (selectedIndex) {
      1 => const TasksScreen(),
      _ => const _DashboardContent(),
    };
  }
}

class _DashboardBackground extends StatelessWidget {
  const _DashboardBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFF11131C))),
        Positioned(
          top: -120,
          left: -120,
          child: _GlowOrb(
            size: 420,
            color: NexusColors.primaryContainer.withOpacity(0.22),
          ),
        ),
        Positioned(
          right: -100,
          bottom: MediaQuery.sizeOf(context).height * 0.18,
          child: _GlowOrb(
            size: 360,
            color: NexusColors.secondary.withOpacity(0.12),
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
        boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 70)],
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    final user = Supabase.instance.client.auth.currentUser;
    final username =
        (user?.userMetadata?['username'] ??
                user?.userMetadata?['full_name'] ??
                user?.email ??
                'U')
            .toString()
            .trim();
    final initial =
        username.isEmpty ? 'U' : username.characters.first.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: NexusColors.surface.withOpacity(0.72),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.26),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 48 : 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: NexusColors.primaryContainer,
                  child: Icon(Icons.person_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Nexus AI',
                  style: TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const Spacer(),
                if (isWide) ...[
                  _TopNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    active: selectedIndex == 0,
                    onTap: () => onTabSelected(0),
                  ),
                  const SizedBox(width: 12),
                  _TopNavItem(
                    icon: Icons.check_circle_rounded,
                    label: 'Tasks',
                    active: selectedIndex == 1,
                    onTap: () => onTabSelected(1),
                  ),
                  const SizedBox(width: 12),
                  _TopNavItem(
                    icon: Icons.smart_toy_rounded,
                    label: 'Nexus',
                    active: selectedIndex == 2,
                    onTap: () => onTabSelected(2),
                  ),
                  const SizedBox(width: 20),
                ],
                Tooltip(
                  message: 'Sign out',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SignInPage()),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: NexusColors.surfaceContainerHigh,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: NexusColors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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

class _TopNavItem extends StatefulWidget {
  const _TopNavItem({
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
  State<_TopNavItem> createState() => _TopNavItemState();
}

class _TopNavItemState extends State<_TopNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || _hovered;
    final color =
        highlighted ? NexusColors.primary : NexusColors.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                highlighted
                    ? Colors.white.withOpacity(0.08)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final horizontalPadding = width >= 760 ? 48.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        32,
        horizontalPadding,
        120,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              isWide
                  ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 8, child: _WelcomeSection()),
                      SizedBox(width: 24),
                      Expanded(flex: 4, child: _DailyScoreCard()),
                    ],
                  )
                  : const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WelcomeSection(),
                      SizedBox(height: 24),
                      _DailyScoreCard(),
                    ],
                  ),
              const SizedBox(height: 24),
              const _NexusInsightCard(),
              const SizedBox(height: 24),
              isWide
                  ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 8, child: _ActivePrioritiesSection()),
                      SizedBox(width: 24),
                      Expanded(flex: 4, child: _RightRail()),
                    ],
                  )
                  : const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ActivePrioritiesSection(),
                      SizedBox(height: 24),
                      _RightRail(),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Good morning, Alex',
            style: TextStyle(
              color: NexusColors.onSurfaceVariant,
              fontSize: 18,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ready for deep focus?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.8,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 620,
            child: Text(
              'Your optimal flow state usually begins around 9:30 AM. You have 3 high-priority tasks queued.',
              style: TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyScoreCard extends StatelessWidget {
  const _DailyScoreCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardGlassPanel(
      minHeight: 220,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    NexusColors.primaryContainer.withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 0,
            child: Text(
              'DAILY SCORE',
              style: TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 138,
              height: 138,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 0.76,
                      strokeWidth: 9,
                      backgroundColor: Colors.white.withOpacity(0.10),
                      valueColor: const AlwaysStoppedAnimation(
                        NexusColors.primaryContainer,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '76',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'FLOW',
                        style: TextStyle(
                          color: NexusColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
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

class _NexusInsightCard extends StatelessWidget {
  const _NexusInsightCard();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            NexusColors.primaryContainer.withOpacity(0.5),
            NexusColors.secondary.withOpacity(0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: NexusColors.secondary.withOpacity(0.18),
            blurRadius: 28,
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(isWide ? 28 : 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E).withOpacity(0.92),
          borderRadius: BorderRadius.circular(23),
        ),
        child:
            isWide
                ? const Row(
                  children: [
                    Expanded(child: _InsightCopy()),
                    SizedBox(width: 24),
                    _InitiateButton(),
                  ],
                )
                : const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InsightCopy(),
                    SizedBox(height: 20),
                    _InitiateButton(),
                  ],
                ),
      ),
    );
  }
}

class _InsightCopy extends StatelessWidget {
  const _InsightCopy();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _InsightIcon(),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'NEXUS INSIGHT',
                    style: TextStyle(
                      color: NexusColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                  SizedBox(width: 8),
                  _PulseDot(),
                ],
              ),
              SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  text: 'Based on your flow, start your ',
                  children: [
                    TextSpan(
                      text: 'Product Design',
                      style: TextStyle(color: Color(0xFFA78BFA)),
                    ),
                    TextSpan(text: ' task now.'),
                  ],
                ),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightIcon extends StatelessWidget {
  const _InsightIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: NexusColors.secondary.withOpacity(0.18),
        border: Border.all(color: NexusColors.secondary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: NexusColors.secondary.withOpacity(0.25),
            blurRadius: 20,
          ),
        ],
      ),
      child: const Icon(Icons.smart_toy_rounded, color: NexusColors.secondary),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: NexusColors.secondary,
      ),
    );
  }
}

class _InitiateButton extends StatelessWidget {
  const _InitiateButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NexusColors.primaryContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Initiate Task',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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

class _ActivePrioritiesSection extends StatelessWidget {
  const _ActivePrioritiesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Priorities',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'View All',
              style: TextStyle(
                color: NexusColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SizedBox(height: 18),
        _TaskPriorityTile(
          title: 'Design System Refactor',
          subtitle: 'Due Today • 2h est.',
          badge: 'High Priority',
        ),
        SizedBox(height: 12),
        _TaskPriorityTile(
          title: 'Weekly Sync Preparation',
          subtitle: 'In Progress • 45m left',
          active: true,
          progress: 0.6,
        ),
        SizedBox(height: 12),
        _TaskPriorityTile(
          title: 'Review Q3 Analytics',
          subtitle: 'Completed at 8:42 AM',
          completed: true,
        ),
      ],
    );
  }
}

class _TaskPriorityTile extends StatelessWidget {
  const _TaskPriorityTile({
    required this.title,
    required this.subtitle,
    this.badge,
    this.active = false,
    this.completed = false,
    this.progress,
  });

  final String title;
  final String subtitle;
  final String? badge;
  final bool active;
  final bool completed;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return _DashboardGlassPanel(
      padding: const EdgeInsets.all(16),
      radius: 16,
      opacity: completed ? 0.45 : 0.62,
      child: Row(
        children: [
          _TaskStatusIcon(active: active, completed: completed),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        completed ? NexusColors.onSurfaceVariant : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        active
                            ? NexusColors.secondary
                            : NexusColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: NexusColors.primaryContainer.withOpacity(0.18),
                border: Border.all(color: NexusColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'High Priority',
                style: TextStyle(
                  color: Color(0xFFB388FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (progress != null)
            SizedBox(
              width: 96,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: NexusColors.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation(
                    NexusColors.secondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskStatusIcon extends StatelessWidget {
  const _TaskStatusIcon({required this.active, required this.completed});

  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: NexusColors.secondary.withOpacity(0.16),
          border: Border.all(color: NexusColors.secondary.withOpacity(0.45)),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: NexusColors.secondary,
          size: 16,
        ),
      );
    }
    if (active) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: NexusColors.secondary.withOpacity(0.16),
          border: Border.all(color: NexusColors.secondary.withOpacity(0.35)),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: NexusColors.secondary,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: NexusColors.outline, width: 2),
      ),
    );
  }
}

class _RightRail extends StatelessWidget {
  const _RightRail();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FocusSessionCard(),
        SizedBox(height: 24),
        _UpcomingDeadlinesCard(),
      ],
    );
  }
}

class _FocusSessionCard extends StatelessWidget {
  const _FocusSessionCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 190,
      child: _DashboardGlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SmallIconBox(icon: Icons.timer_rounded),
                Icon(
                  Icons.arrow_outward_rounded,
                  color: NexusColors.onSurfaceVariant,
                ),
              ],
            ),
            Spacer(),
            Text(
              'Deep Work',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Start a 90m focus session',
              style: TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingDeadlinesCard extends StatelessWidget {
  const _UpcomingDeadlinesCard();

  @override
  Widget build(BuildContext context) {
    return const _DashboardGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPCOMING',
            style: TextStyle(
              color: NexusColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          SizedBox(height: 18),
          _DeadlineRow(
            day: '14',
            month: 'Oct',
            title: 'Client Presentation',
            subtitle: '2 days left',
            warning: true,
          ),
          SizedBox(height: 18),
          _DeadlineRow(
            day: '18',
            month: 'Oct',
            title: 'Sprint Planning',
            subtitle: 'Friday',
          ),
        ],
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({
    required this.day,
    required this.month,
    required this.title,
    required this.subtitle,
    this.warning = false,
  });

  final String day;
  final String month;
  final String title;
  final String subtitle;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              day,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              month,
              style: const TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.white.withOpacity(0.18)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        warning
                            ? const Color(0xFFFFB4AB)
                            : NexusColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallIconBox extends StatelessWidget {
  const _SmallIconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _DashboardGlassPanel extends StatelessWidget {
  const _DashboardGlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
    this.minHeight,
    this.opacity = 0.42,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double? minHeight;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding,
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainer.withOpacity(opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    if (isWide) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: NexusColors.surface.withOpacity(0.92),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: selectedIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _BottomNavItem(
                icon: Icons.check_circle_rounded,
                label: 'Tasks',
                active: selectedIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _BottomNavItem(
                icon: Icons.smart_toy_rounded,
                label: 'Nexus',
                active: selectedIndex == 2,
                onTap: () => onTabSelected(2),
              ),
              _BottomNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: selectedIndex == 3,
                onTap: () => onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
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
    final color = active ? NexusColors.primary : NexusColors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
