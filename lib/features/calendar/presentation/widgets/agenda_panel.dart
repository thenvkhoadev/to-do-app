import 'dart:ui';
import 'package:flutter/material.dart';

class AgendaPanelEvent {
  const AgendaPanelEvent({
    required this.start,
    required this.title,
    this.taskId,
    this.subtitle,
    this.color,
    this.durationMinutes = 30,
    this.status = 'Scheduled',
    this.priority = 'Medium',
    this.type = 'Task',
  });

  final DateTime start;
  final String title;
  final String? taskId;
  final String? subtitle;
  final Color? color;
  final int durationMinutes;
  final String status;
  final String priority;
  final String type;
}

class AgendaPanel extends StatefulWidget {
  const AgendaPanel({
    required this.date,
    this.events = const [],
    this.aiSuggestion,
    this.onAcceptSuggestion,
    this.onDismissSuggestion,
    this.isLoading = false,
    this.errorMessage,
    this.onHideAgenda,
    this.onCreateTask,
    this.onEventTap,
    super.key,
  });

  final DateTime date;
  final List<AgendaPanelEvent> events;
  final String? aiSuggestion;
  final VoidCallback? onAcceptSuggestion;
  final VoidCallback? onDismissSuggestion;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onHideAgenda;
  final VoidCallback? onCreateTask;
  final ValueChanged<AgendaPanelEvent>? onEventTap;

  @override
  State<AgendaPanel> createState() => _AgendaPanelState();
}

class SelectDateAgendaPrompt extends StatefulWidget {
  const SelectDateAgendaPrompt({
    this.compact = false,
    this.onHideAgenda,
    this.onCreateTask,
    super.key,
  });

  final bool compact;
  final VoidCallback? onHideAgenda;
  final VoidCallback? onCreateTask;

  @override
  State<SelectDateAgendaPrompt> createState() => _SelectDateAgendaPromptState();
}

class _SelectDateAgendaPromptState extends State<SelectDateAgendaPrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: .96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(widget.compact ? 24 : 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: .055),
              primary.withValues(alpha: .07),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(color: primary.withValues(alpha: .10), blurRadius: 30),
          ],
        ),
        child: Stack(
          children: [
            if (widget.onHideAgenda != null)
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  onPressed: widget.onHideAgenda,
                  icon: const Icon(Icons.close_fullscreen_rounded),
                  tooltip: 'Hide agenda',
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: widget.compact ? 62 : 78,
                    height: widget.compact ? 62 : 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: .12),
                      border: Border.all(color: primary.withValues(alpha: .26)),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: primary,
                      size: widget.compact ? 30 : 38,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Select a date',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a day from the calendar\nto view tasks and events.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                    height: 1.45,
                  ),
                ),
                if (widget.onCreateTask != null) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: widget.onCreateTask,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Task'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 10,
                      shadowColor: primary.withValues(alpha: .35),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaPanelState extends State<AgendaPanel> {
  String _selectedFilter = 'All';
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final selectedDateTasks =
        widget.events
            .where((task) => _sameDay(task.start, widget.date))
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final taskCount =
        selectedDateTasks.where((task) => task.type != 'Meeting').length;
    final meetingCount =
        selectedDateTasks.where((task) => task.type == 'Meeting').length;
    final completedCount =
        selectedDateTasks.where((task) => _isCompleted(task.status)).length;
    final focusMinutes = selectedDateTasks
        .where((task) => task.type != 'Meeting')
        .fold<int>(0, (total, task) => total + task.durationMinutes);
    final filteredTasks = _filterEvents(selectedDateTasks);
    final hasConflicts = _hasConflicts(selectedDateTasks);

    return SingleChildScrollView(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder:
              (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
          child:
              _isExpanded
                  ? _ExpandedAgenda(
                    key: ValueKey('expanded-${_dateKey(widget.date)}'),
                    date: widget.date,
                    taskCount: taskCount,
                    meetingCount: meetingCount,
                    completedCount: completedCount,
                    focusMinutes: focusMinutes,
                    selectedDateTasks: selectedDateTasks,
                    filteredTasks: filteredTasks,
                    hasConflicts: hasConflicts,
                    selectedFilter: _selectedFilter,
                    isLoading: widget.isLoading,
                    errorMessage: widget.errorMessage,
                    aiSuggestion: widget.aiSuggestion,
                    onAcceptSuggestion: widget.onAcceptSuggestion,
                    onDismissSuggestion: widget.onDismissSuggestion,
                    onFilterSelected:
                        (filter) => setState(() => _selectedFilter = filter),
                    onToggleExpanded:
                        () => setState(() => _isExpanded = !_isExpanded),
                    onHideAgenda: widget.onHideAgenda,
                    onCreateTask: widget.onCreateTask,
                    nextEvent: _nextEvent(selectedDateTasks),
                    onEventTap: widget.onEventTap,
                  )
                  : _CollapsedAgenda(
                    key: ValueKey('collapsed-${_dateKey(widget.date)}'),
                    date: widget.date,
                    taskCount: taskCount,
                    onToggleExpanded:
                        () => setState(() => _isExpanded = !_isExpanded),
                  ),
        ),
      ),
    );
  }

  List<AgendaPanelEvent> _filterEvents(List<AgendaPanelEvent> events) {
    return switch (_selectedFilter) {
      'Tasks' => events.where((event) => event.type != 'Meeting').toList(),
      'Meetings' => events.where((event) => event.type == 'Meeting').toList(),
      'Reminders' => events.where((event) => event.type == 'Reminder').toList(),
      'Completed' =>
        events.where((event) => event.status == 'Completed').toList(),
      _ => events,
    };
  }

  AgendaPanelEvent? _nextEvent(List<AgendaPanelEvent> events) {
    final now = DateTime.now();
    for (final event in events) {
      if (event.start.isAfter(now)) return event;
    }
    return events.isEmpty ? null : events.first;
  }
}

bool _hasConflicts(List<AgendaPanelEvent> events) {
  for (var index = 0; index < events.length - 1; index++) {
    final currentEnd = events[index].start.add(
      Duration(minutes: events[index].durationMinutes),
    );
    if (currentEnd.isAfter(events[index + 1].start)) return true;
  }
  return false;
}

class _ExpandedAgenda extends StatelessWidget {
  const _ExpandedAgenda({
    required this.date,
    required this.taskCount,
    required this.meetingCount,
    required this.completedCount,
    required this.focusMinutes,
    required this.selectedDateTasks,
    required this.filteredTasks,
    required this.hasConflicts,
    required this.selectedFilter,
    required this.isLoading,
    required this.errorMessage,
    required this.onFilterSelected,
    required this.onToggleExpanded,
    required this.nextEvent,
    this.onHideAgenda,
    this.onCreateTask,
    this.aiSuggestion,
    this.onAcceptSuggestion,
    this.onDismissSuggestion,
    this.onEventTap,
    super.key,
  });

  final DateTime date;
  final int taskCount;
  final int meetingCount;
  final int completedCount;
  final int focusMinutes;
  final List<AgendaPanelEvent> selectedDateTasks;
  final List<AgendaPanelEvent> filteredTasks;
  final bool hasConflicts;
  final String selectedFilter;
  final bool isLoading;
  final String? errorMessage;
  final String? aiSuggestion;
  final VoidCallback? onAcceptSuggestion;
  final VoidCallback? onDismissSuggestion;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback onToggleExpanded;
  final AgendaPanelEvent? nextEvent;
  final VoidCallback? onHideAgenda;
  final VoidCallback? onCreateTask;
  final ValueChanged<AgendaPanelEvent>? onEventTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AgendaHeader(
            date: date,
            taskCount: taskCount,
            meetingCount: meetingCount,
            isExpanded: true,
            onToggleExpanded: onToggleExpanded,
            onHideAgenda: onHideAgenda,
          ),
          const SizedBox(height: 18),
          const _AgendaLoadingCard(),
        ],
      );
    }

    if (errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AgendaHeader(
            date: date,
            taskCount: taskCount,
            meetingCount: meetingCount,
            isExpanded: true,
            onToggleExpanded: onToggleExpanded,
            onHideAgenda: onHideAgenda,
          ),
          const SizedBox(height: 18),
          _AgendaErrorCard(message: errorMessage!),
        ],
      );
    }

    if (selectedDateTasks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AgendaHeader(
            date: date,
            taskCount: taskCount,
            meetingCount: meetingCount,
            isExpanded: true,
            onToggleExpanded: onToggleExpanded,
            onHideAgenda: onHideAgenda,
          ),
          const SizedBox(height: 18),
          _EmptyAgenda(
            key: ValueKey('empty-${_dateKey(date)}'),
            onCreateTask: onCreateTask,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AgendaHeader(
          date: date,
          taskCount: taskCount,
          meetingCount: meetingCount,
          isExpanded: true,
          onToggleExpanded: onToggleExpanded,
          onHideAgenda: onHideAgenda,
        ),
        const SizedBox(height: 18),
        _DayOverview(
          taskCount: taskCount,
          meetingCount: meetingCount,
          focusMinutes: focusMinutes,
          completedCount: completedCount,
        ),
        const SizedBox(height: 18),
        const _AiSummaryCard(),
        const SizedBox(height: 24),
        _AiOptimizationCard(
          text:
              aiSuggestion ??
              'You have ${selectedDateTasks.length} scheduled items. Should I optimize your day?',
          onAccept: onAcceptSuggestion,
          onDismiss: onDismissSuggestion,
        ),
        const SizedBox(height: 18),
        if (hasConflicts) ...[
          const _ScheduleConflictCard(),
          const SizedBox(height: 18),
        ],
        _QuickFilters(
          selectedFilter: selectedFilter,
          onSelected: onFilterSelected,
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder:
              (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
          child:
              filteredTasks.isEmpty
                  ? _EmptyAgenda(
                    key: ValueKey(
                      'filtered-empty-${_dateKey(date)}-$selectedFilter',
                    ),
                    onCreateTask: onCreateTask,
                  )
                  : _AgendaTimeline(
                    key: ValueKey('timeline-${_dateKey(date)}-$selectedFilter'),
                    events: filteredTasks,
                    onEventTap: onEventTap,
                  ),
        ),
        const SizedBox(height: 4),
        _NextTaskCard(event: nextEvent),
        const SizedBox(height: 18),
        const _ProductivityScoreCard(),
        const SizedBox(height: 18),
        const _TeamAvailabilityCard(),
        const SizedBox(height: 18),
        const _UpcomingDeadlineCard(),
        const SizedBox(height: 18),
        const _FocusSessionCard(),
        const SizedBox(height: 18),
        const _FloatingScheduleOptimizerCard(),
      ],
    );
  }
}

class _CollapsedAgenda extends StatelessWidget {
  const _CollapsedAgenda({
    required this.date,
    required this.taskCount,
    required this.onToggleExpanded,
    super.key,
  });

  final DateTime date;
  final int taskCount;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onToggleExpanded,
        child: Container(
          height: 92,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .045),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primary.withValues(alpha: .20)),
            boxShadow: [
              BoxShadow(color: primary.withValues(alpha: .10), blurRadius: 24),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.chevron_right_rounded, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Agenda',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_month(date)} ${date.day}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white60,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _Badge(label: '$taskCount Tasks', color: primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaHeader extends StatelessWidget {
  const _AgendaHeader({
    required this.date,
    required this.taskCount,
    required this.meetingCount,
    required this.isExpanded,
    required this.onToggleExpanded,
    this.onHideAgenda,
  });

  final DateTime date;
  final int taskCount;
  final int meetingCount;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback? onHideAgenda;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        IconButton(
          onPressed: onToggleExpanded,
          icon: Icon(
            isExpanded
                ? Icons.keyboard_arrow_down_rounded
                : Icons.chevron_right_rounded,
          ),
          color: primary,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Agenda',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _dateLabel(date),
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.white70),
                  ),
                  _SelectedDayBadge(date: date),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AgendaStatChip(label: '$taskCount Tasks'),
                  _AgendaStatChip(label: '$meetingCount Meetings'),
                ],
              ),
            ],
          ),
        ),
        if (onHideAgenda != null)
          IconButton(
            onPressed: onHideAgenda,
            icon: const Icon(Icons.close_fullscreen_rounded),
            color: primary,
            tooltip: 'Hide agenda',
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.today_rounded, color: primary, size: 22),
          ),
      ],
    );
  }
}

class _SelectedDayBadge extends StatelessWidget {
  const _SelectedDayBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final label = _sameDay(date, DateTime.now()) ? 'TODAY' : 'SELECTED DAY';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: .30)),
        boxShadow: [
          BoxShadow(color: primary.withValues(alpha: .12), blurRadius: 18),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _AgendaStatChip extends StatelessWidget {
  const _AgendaStatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white60,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DayOverview extends StatelessWidget {
  const _DayOverview({
    required this.taskCount,
    required this.meetingCount,
    required this.focusMinutes,
    required this.completedCount,
  });

  final int taskCount;
  final int meetingCount;
  final int focusMinutes;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: "Today's Overview"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                value: '$taskCount',
                label: 'Tasks',
                color: const Color(0xFF8B5CF6),
                icon: Icons.assignment_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewCard(
                value: '$meetingCount',
                label: 'Meetings',
                color: const Color(0xFF06B6D4),
                icon: Icons.groups_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewCard(
                value: _hoursLabel(focusMinutes),
                label: 'Focus',
                color: const Color(0xFF22C55E),
                icon: Icons.bolt_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewCard(
                value: '$completedCount',
                label: 'Done',
                color: const Color(0xFFF59E0B),
                icon: Icons.check_circle_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top accent line
          Positioned(
            left: 10,
            right: 10,
            top: 0,
            height: 2,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: color,
                    blurRadius: 4,
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                Icon(icon, color: color.withValues(alpha: 0.8), size: 16),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
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

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, secondary, const Color(0xFFDDB7FF)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1222).withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_awesome_rounded, color: primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AI Intelligent Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SummaryLine(label: '⚡ You have 3 high-priority tasks today.'),
                const SizedBox(height: 10),
                const _SummaryLine(label: '🎯 Best focus window:', value: '2PM - 5PM'),
                const SizedBox(height: 10),
                const _SummaryLine(label: '📊 Estimated workload:', value: 'Medium'),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary, secondary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Optimize Day', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Auto Schedule', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        children: [
          if (value != null)
            TextSpan(
              text: '\n$value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: Colors.white70, height: 1.35),
    );
  }
}

class _QuickFilters extends StatelessWidget {
  const _QuickFilters({required this.selectedFilter, required this.onSelected});

  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Tasks', 'Meetings', 'Reminders', 'Completed'];
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in filters)
            ChoiceChip(
              label: Text(filter),
              selected: selectedFilter == filter,
              onSelected: (_) => onSelected(filter),
              selectedColor: primary.withValues(alpha: .20),
              backgroundColor: Colors.white.withValues(alpha: .045),
              side: BorderSide(
                color:
                    selectedFilter == filter
                        ? primary.withValues(alpha: .45)
                        : Colors.white.withValues(alpha: .10),
              ),
              labelStyle: TextStyle(
                color: selectedFilter == filter ? Colors.white : Colors.white60,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _AiOptimizationCard extends StatelessWidget {
  const _AiOptimizationCard({
    required this.text,
    this.onAccept,
    this.onDismiss,
  });

  final String text;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: .18),
            secondary.withValues(alpha: .12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(color: primary.withValues(alpha: .12), blurRadius: 28),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            bottom: -42,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: .08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'AI OPTIMIZATION',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                text,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: onAccept ?? () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8083FF),
                      foregroundColor: Colors.white,
                      shadowColor: const Color(
                        0xFF8083FF,
                      ).withValues(alpha: .45),
                      elevation: 10,
                    ),
                    child: const Text('Optimize'),
                  ),
                  OutlinedButton(
                    onPressed: onDismiss ?? () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDDB7FF),
                      backgroundColor: const Color(
                        0xFFDDB7FF,
                      ).withValues(alpha: .12),
                      side: BorderSide(
                        color: const Color(0xFFDDB7FF).withValues(alpha: .35),
                      ),
                    ),
                    child: const Text('Dismiss'),
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

class _NextTaskCard extends StatelessWidget {
  const _NextTaskCard({required this.event});

  final AgendaPanelEvent? event;

  @override
  Widget build(BuildContext context) {
    final nextEvent = event;
    if (nextEvent == null) return const SizedBox.shrink();

    final primary = Theme.of(context).colorScheme.primary;
    return _PremiumCard(
      glowColor: primary,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Next Up'),
                const SizedBox(height: 8),
                Text(
                  nextEvent.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _Badge(label: _startsIn(nextEvent.start), color: primary),
        ],
      ),
    );
  }
}

class _ProductivityScoreCard extends StatelessWidget {
  const _ProductivityScoreCard();

  @override
  Widget build(BuildContext context) {
    const score = .87;
    final color = const Color(0xFF22C55E);
    return _PremiumCard(
      glowColor: color,
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withValues(alpha: .08),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text(
                  '87%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Productivity Score'),
                const SizedBox(height: 8),
                _MetricBar(label: 'Completion rate', value: .82, color: color),
                const SizedBox(height: 8),
                _MetricBar(
                  label: 'Focus score',
                  value: .91,
                  color: const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamAvailabilityCard extends StatelessWidget {
  const _TeamAvailabilityCard();

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      glowColor: const Color(0xFF06B6D4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Team Online'),
                const SizedBox(height: 10),
                const Text(
                  'Alex\nSarah\nJohn',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const _StackedAvatars(names: ['A', 'S', 'J']),
          const SizedBox(width: 12),
          _Badge(label: '3 Online', color: const Color(0xFF22C55E)),
        ],
      ),
    );
  }
}

class _UpcomingDeadlineCard extends StatelessWidget {
  const _UpcomingDeadlineCard();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFF59E0B);
    return _PremiumCard(
      glowColor: color,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Upcoming Deadline'),
                const SizedBox(height: 8),
                Text(
                  'Product Strategy Review',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _Badge(label: 'Due in 2 Days', color: color),
        ],
      ),
    );
  }
}

class _FocusSessionCard extends StatelessWidget {
  const _FocusSessionCard();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF8B5CF6);
    return _PremiumCard(
      glowColor: color,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: .72,
              strokeWidth: 5,
              backgroundColor: Colors.white.withValues(alpha: .08),
              valueColor: const AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Today\'s Focus'),
                const SizedBox(height: 6),
                Text(
                  '4h 32m',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _Badge(label: '7 day streak', color: color),
        ],
      ),
    );
  }
}

class _FloatingScheduleOptimizerCard extends StatelessWidget {
  const _FloatingScheduleOptimizerCard();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return _PremiumCard(
      glowColor: primary,
      child: Row(
        children: [
          Icon(Icons.auto_fix_high_rounded, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Optimize Today\'s Schedule',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          FilledButton(onPressed: () {}, child: const Text('Optimize')),
        ],
      ),
    );
  }
}

class _ScheduleConflictCard extends StatelessWidget {
  const _ScheduleConflictCard();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFF97316);
    return _PremiumCard(
      glowColor: color,
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Schedule Conflict'),
                const SizedBox(height: 4),
                Text(
                  '2 overlapping events',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaLoadingCard extends StatelessWidget {
  const _AgendaLoadingCard();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return _PremiumCard(
      glowColor: primary,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Loading agenda...',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaErrorCard extends StatelessWidget {
  const _AgendaErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFF97316);
    return _PremiumCard(
      glowColor: color,
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.child, required this.glowColor});

  final Widget child;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: glowColor.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(color: glowColor.withValues(alpha: .12), blurRadius: 28),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: .08),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _StackedAvatars extends StatelessWidget {
  const _StackedAvatars({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    const avatarSize = 34.0;
    const overlap = 8.0;
    final step = avatarSize - overlap;

    return SizedBox(
      width: avatarSize + step * (names.length - 1),
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < names.length; index++)
            Positioned(
              left: index * step,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0F172A), width: 2),
                ),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: avatarSize / 2,
                      backgroundColor: const Color(0xFF1F2937),
                      child: Text(
                        names[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF111827),
                            width: 1.5,
                          ),
                        ),
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

class _AgendaTimeline extends StatelessWidget {
  const _AgendaTimeline({required this.events, this.onEventTap, super.key});

  final List<AgendaPanelEvent> events;
  final ValueChanged<AgendaPanelEvent>? onEventTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 11,
          top: 8,
          bottom: 0,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ),
        Column(
          children: [
            for (var index = 0; index < events.length; index++)
              _TimelineEntry(
                event: events[index],
                active: index == 0,
                onTap: onEventTap != null ? () => onEventTap!(events[index]) : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _TimelineEntry extends StatefulWidget {
  const _TimelineEntry({required this.event, required this.active, this.onTap});

  final AgendaPanelEvent event;
  final bool active;
  final VoidCallback? onTap;

  @override
  State<_TimelineEntry> createState() => _TimelineEntryState();
}

class _TimelineEntryState extends State<_TimelineEntry> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? Theme.of(context).colorScheme.primary
        : widget.event.color ?? Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -40,
            top: 6,
            child: _TimelineDot(color: color, active: widget.active),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    _time(widget.event.start),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: widget.active ? color : Colors.white60,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: color.withValues(alpha: widget.active ? .24 : .10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      borderRadius: BorderRadius.circular(18),
                      child: _AgendaCard(
                        event: widget.event,
                        color: color,
                        active: widget.active,
                        hovered: _hovered,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (active) {
      return Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          width: 14,
          height: 14,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        ),
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({
    required this.event,
    required this.color,
    required this.active,
    required this.hovered,
  });

  final AgendaPanelEvent event;
  final Color color;
  final bool active;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: hovered ? 0.10 : 0.06)
            : Colors.white.withValues(alpha: hovered ? 0.06 : 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active
              ? color.withValues(alpha: hovered ? 0.45 : 0.25)
              : Colors.white.withValues(alpha: hovered ? 0.18 : 0.07),
          width: 1.2,
        ),
        boxShadow: hovered || active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: hovered ? 0.16 : 0.08),
                  blurRadius: hovered ? 24 : 16,
                  offset: Offset(0, hovered ? 8 : 4),
                )
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 6,
                )
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (active)
                      Icon(Icons.auto_awesome_rounded, color: color, size: 16),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.subtitle ?? '${_time(event.start)} event',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white60,
                    height: 1.35,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AgendaMetaChip(
                      label: event.priority,
                      icon: Icons.flag_rounded,
                      color: _priorityColor(event.priority),
                    ),
                    _AgendaMetaChip(
                      label: event.status,
                      icon: Icons.check_circle_rounded,
                      color: _statusColor(event.status),
                    ),
                    _AgendaMetaChip(
                      label: _duration(event.durationMinutes),
                      icon: Icons.schedule_rounded,
                      color: Colors.white60,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent': return const Color(0xFFEF4444);
      case 'high': return const Color(0xFFF97316);
      case 'low': return const Color(0xFF3B82F6);
      default: return const Color(0xFF8B5CF6);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return const Color(0xFF22C55E);
      case 'in_progress':
      case 'inprogress':
        return const Color(0xFF8083FF);
      case 'draft':
        return const Color(0xFF908FA0);
      default:
        return const Color(0xFFADC6FF);
    }
  }
}

class _AgendaMetaChip extends StatelessWidget {
  const _AgendaMetaChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda({this.onCreateTask, super.key});

  final VoidCallback? onCreateTask;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: primary.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(Icons.event_available_rounded, color: primary, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'No tasks scheduled',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy your free day or prepare your next goal.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: FilledButton.icon(
              onPressed: onCreateTask ?? () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text(
                'Schedule Task',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dateLabel(DateTime date) =>
    '${_weekday(date)}, ${_month(date)} ${date.day}, ${date.year}';

String _weekday(DateTime date) =>
    const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][date.weekday - 1];

String _month(DateTime date) =>
    const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][date.month - 1];

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _duration(int minutes) => minutes == 1 ? '1 min' : '$minutes mins';

String _hoursLabel(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  return remainingMinutes == 0 ? '${hours}h' : '${hours}h ${remainingMinutes}m';
}

bool _isCompleted(String status) => status.toLowerCase().contains('complete');

String _startsIn(DateTime start) {
  final minutes = start.difference(DateTime.now()).inMinutes;
  if (minutes <= 0) return 'Starts now';
  if (minutes < 60) return 'Starts in $minutes mins';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  return remainingMinutes == 0
      ? 'Starts in ${hours}h'
      : 'Starts in ${hours}h ${remainingMinutes}m';
}

String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';
