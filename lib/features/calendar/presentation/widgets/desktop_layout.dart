import 'package:flutter/material.dart';

class CalendarDesktopLayout extends StatelessWidget {
  const CalendarDesktopLayout({
    required this.title,
    required this.selectedView,
    required this.onViewChanged,
    required this.calendar,
    required this.agenda,
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
  final VoidCallback? onToday;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        CalendarAgendaPanel(child: agenda),
      ],
    );
  }
}

enum CalendarDesktopView { month, week, day }

class CalendarDesktopToolbar extends StatelessWidget {
  const CalendarDesktopToolbar({
    required this.title,
    required this.selectedView,
    required this.onViewChanged,
    this.onToday,
    this.onPrevious,
    this.onNext,
    super.key,
  });

  final String title;
  final CalendarDesktopView selectedView;
  final ValueChanged<CalendarDesktopView> onViewChanged;
  final VoidCallback? onToday;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

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
    return Container(
      width: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .42),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
      ),
      child: CalendarGlassPanel(child: child),
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
