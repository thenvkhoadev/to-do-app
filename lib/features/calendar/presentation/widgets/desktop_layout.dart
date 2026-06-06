import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class CalendarDesktopLayout extends StatelessWidget {
  const CalendarDesktopLayout({
    required this.title,
    required this.selectedView,
    required this.onViewChanged,
    required this.calendar,
    required this.agenda,
    this.agendaVisible = true,
    this.onToggleAgenda,
    this.onToday,
    this.onPrevious,
    this.onNext,
    super.key,
  });

  final String title;
  final CalendarDesktopView selectedView;
  final ValueChanged<CalendarDesktopView> onViewChanged;
  final Widget calendar;
  final Widget agenda;
  final bool agendaVisible;
  final VoidCallback? onToggleAgenda;
  final VoidCallback? onToday;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CalendarDesktopTopNav(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CalendarDesktopToolbar(
                      title: title,
                      selectedView: selectedView,
                      onViewChanged: onViewChanged,
                      onToday: onToday,
                      onPrevious: onPrevious,
                      onNext: onNext,
                      agendaVisible: agendaVisible,
                      onToggleAgenda: onToggleAgenda,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: CalendarGlassPanel(child: calendar),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child:
                    agendaVisible
                        ? CalendarAgendaPanel(
                          key: const ValueKey('agenda'),
                          child: agenda,
                        )
                        : const SizedBox.shrink(key: ValueKey('agenda-hidden')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum CalendarDesktopView { month, week, day }

class CalendarDesktopTopNav extends StatelessWidget {
  const CalendarDesktopTopNav({super.key});

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
          child: const Row(
            children: [
              _CalendarSearchBar(),
              Spacer(),
              _CalendarTopIcon(
                icon: Icons.notifications_none_rounded,
                badge: true,
              ),
              SizedBox(width: 12),
              _CalendarTopIcon(icon: Icons.bolt_rounded),
              SizedBox(width: 12),
              ProfileAvatar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarSearchBar extends StatelessWidget {
  const _CalendarSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: DashboardColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, size: 20),
          SizedBox(width: 10),
          Text(
            'Search events or schedules...',
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

class _CalendarTopIcon extends StatelessWidget {
  const _CalendarTopIcon({required this.icon, this.badge = false});

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

class CalendarDesktopToolbar extends StatelessWidget {
  const CalendarDesktopToolbar({
    required this.title,
    required this.selectedView,
    required this.onViewChanged,
    this.onToday,
    this.onPrevious,
    this.onNext,
    this.agendaVisible = true,
    this.onToggleAgenda,
    super.key,
  });

  final String title;
  final CalendarDesktopView selectedView;
  final ValueChanged<CalendarDesktopView> onViewChanged;
  final VoidCallback? onToday;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool agendaVisible;
  final VoidCallback? onToggleAgenda;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .52),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          OutlinedButton(onPressed: onToday, child: const Text('Today')),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: onToggleAgenda,
            icon: Icon(
              agendaVisible
                  ? Icons.close_fullscreen_rounded
                  : Icons.view_agenda_rounded,
              size: 18,
            ),
            label: Text(agendaVisible ? 'Hide Agenda' : 'Agenda'),
          ),
          const SizedBox(width: 14),
          CalendarViewSwitcher(
            selectedView: selectedView,
            onViewChanged: onViewChanged,
          ),
        ],
      ),
    );
  }
}

class CalendarViewSwitcher extends StatelessWidget {
  const CalendarViewSwitcher({
    required this.selectedView,
    required this.onViewChanged,
    super.key,
  });

  final CalendarDesktopView selectedView;
  final ValueChanged<CalendarDesktopView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CalendarDesktopView>(
      segments: const [
        ButtonSegment(value: CalendarDesktopView.month, label: Text('Month')),
        ButtonSegment(value: CalendarDesktopView.week, label: Text('Week')),
        ButtonSegment(value: CalendarDesktopView.day, label: Text('Day')),
      ],
      selected: {selectedView},
      onSelectionChanged: (value) => onViewChanged(value.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.white.withValues(alpha: .05);
        }),
      ),
    );
  }
}

class CalendarAgendaPanel extends StatelessWidget {
  const CalendarAgendaPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final width = screenWidth >= 1600 ? 420.0 : 380.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1020).withValues(alpha: .82),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class CalendarGlassPanel extends StatelessWidget {
  const CalendarGlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .56),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .24),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}
