import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/agenda_panel.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/calendar_month_view.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/day_view.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/desktop_layout.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/mobile_layout.dart'
    as mobile;
import 'package:to_do_app/features/calendar/presentation/widgets/week_view.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/widgets/dashboard/mobile_dashboard_widgets.dart';

enum CalendarView { month, week, day }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarView _view = CalendarView.month;
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  DayCalendarEvent? _selectedEvent;
  bool _agendaVisible = false;

  void _setView(CalendarView view) {
    setState(() => _view = view);
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _focusedDate = date;
      _selectedEvent = null;
    });
  }

  void _goToToday() {
    _selectDate(DateTime.now());
  }

  void _goToPrevious() {
    _moveDate(-1);
  }

  void _goToNext() {
    _moveDate(1);
  }

  void _moveDate(int direction) {
    final nextDate = _shiftDate(_focusedDate, direction);
    setState(() {
      _focusedDate = nextDate;
      _selectedDate = null;
      _selectedEvent = null;
    });
  }

  DateTime _shiftDate(DateTime date, int direction) {
    return switch (_view) {
      CalendarView.month => DateTime(
        date.year,
        date.month + direction,
        date.day,
      ),
      CalendarView.week => date.add(Duration(days: 7 * direction)),
      CalendarView.day => date.add(Duration(days: direction)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userTasksProvider);
    final allTasks = tasksAsync.valueOrNull ?? const <NexusTask>[];
    final selectedTasks = _selectedTasksFor(allTasks);
    final selectedDayEvents = _dayEventsFor(selectedTasks);
    final selectedAgendaEvents = _agendaEventsFor(selectedTasks);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return CalendarDesktopLayout(
            title: _title,
            selectedView: _desktopView,
            onViewChanged: (view) => _setView(CalendarView.values[view.index]),
            onToday: _goToToday,
            onPrevious: _goToPrevious,
            onNext: _goToNext,
            calendar: _calendarContent(selectedDayEvents),
            agendaVisible: _agendaVisible,
            onToggleAgenda:
                () => setState(() => _agendaVisible = !_agendaVisible),
            agenda:
                _selectedDate == null
                    ? SelectDateAgendaPrompt(
                      onHideAgenda:
                          () => setState(() => _agendaVisible = false),
                      onCreateTask: () => context.go('/tasks?newTask=1'),
                    )
                    : _selectedEvent == null
                    ? AgendaPanel(
                      date: _selectedDate!,
                      events: selectedAgendaEvents,
                      isLoading: tasksAsync.isLoading,
                      errorMessage:
                          tasksAsync.hasError
                              ? 'Unable to load tasks for this day.'
                              : null,
                      onHideAgenda:
                          () => setState(() => _agendaVisible = false),
                      onCreateTask: () => context.go('/tasks?newTask=1'),
                    )
                    : _EventDetailPanel(
                      event: _selectedEvent!,
                      onClose: () => setState(() => _selectedEvent = null),
                    ),
          );
        }

        return mobile.CalendarMobileLayout(
          title: _title,
          weekSelector: WeekView(
            selectedDate: _selectedDate,
            onDateSelected: _selectDate,
            onPreviousWeek: _goToPrevious,
            onNextWeek: _goToNext,
          ),
          timelineAgenda:
              _selectedDate == null
                  ? SelectDateAgendaPrompt(
                    compact: true,
                    onCreateTask: () => context.go('/tasks?newTask=1'),
                  )
                  : DayView(
                    date: _selectedDate!,
                    events: selectedDayEvents,
                    onEventTap:
                        (event) => setState(() => _selectedEvent = event),
                  ),
          bottomNavigation: MobileBottomNavBar(
            bottomInset: MediaQuery.paddingOf(context).bottom,
          ),
          actions: [
            IconButton(
              onPressed:
                  _selectedDate == null
                      ? null
                      : () =>
                          _openMobileAgenda(selectedAgendaEvents, tasksAsync),
              icon: const Icon(Icons.view_agenda_rounded),
            ),
          ],
          onAdd: () {},
        );
      },
    );
  }

  void _openMobileAgenda(
    List<AgendaPanelEvent> events,
    AsyncValue<List<NexusTask>> tasksAsync,
  ) {
    final date = _selectedDate;
    if (date == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: .78,
          minChildSize: .42,
          maxChildSize: .92,
          builder: (context, controller) {
            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: .10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .32),
                    blurRadius: 36,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: AgendaPanel(
                date: date,
                events: events,
                isLoading: tasksAsync.isLoading,
                errorMessage:
                    tasksAsync.hasError
                        ? 'Unable to load tasks for this day.'
                        : null,
                onCreateTask: () => context.go('/tasks?newTask=1'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _calendarContent(List<DayCalendarEvent> selectedDayEvents) {
    return switch (_view) {
      CalendarView.month => CalendarMonthView(
        focusedDate: _focusedDate,
        selectedDate: _selectedDate,
        onDateSelected: _selectDate,
      ),
      CalendarView.week => WeekView(
        selectedDate: _selectedDate,
        onDateSelected: _selectDate,
        onPreviousWeek: _goToPrevious,
        onNextWeek: _goToNext,
      ),
      CalendarView.day =>
        _selectedDate == null
            ? SelectDateAgendaPrompt(
              compact: true,
              onCreateTask: () => context.go('/tasks?newTask=1'),
            )
            : DayView(
              date: _selectedDate!,
              events: selectedDayEvents,
              onEventTap: (event) => setState(() => _selectedEvent = event),
            ),
    };
  }

  List<NexusTask> _selectedTasksFor(List<NexusTask> tasks) {
    final selectedDate = _selectedDate;
    if (selectedDate == null) return const [];

    return tasks
        .where(
          (task) =>
              task.dueDate != null && _sameDay(task.dueDate!, selectedDate),
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  List<DayCalendarEvent> _dayEventsFor(List<NexusTask> tasks) {
    return tasks.map((task) {
      final start = task.dueDate!;
      return DayCalendarEvent(
        start: start,
        end: start.add(const Duration(minutes: 45)),
        title: task.title,
        subtitle: task.description ?? task.category,
        color: _taskColor(task),
        category: task.category,
        participants: const [],
      );
    }).toList();
  }

  List<AgendaPanelEvent> _agendaEventsFor(List<NexusTask> tasks) {
    return tasks.map((task) {
      return AgendaPanelEvent(
        start: task.dueDate!,
        title: task.title,
        subtitle: task.description ?? task.category,
        color: _taskColor(task),
        durationMinutes: 45,
        status: task.status,
        priority: task.priority,
        type: _agendaType(task),
      );
    }).toList();
  }

  Color _taskColor(NexusTask task) {
    final priority = task.priority.toLowerCase();
    final status = task.status.toLowerCase();
    final category = task.category.toLowerCase();

    if (status.contains('complete')) return const Color(0xFF22C55E);
    if (priority.contains('high')) return const Color(0xFFF97316);
    if (priority.contains('low')) return const Color(0xFF06B6D4);
    if (category.contains('meeting')) return const Color(0xFF8B5CF6);
    return const Color(0xFF7C3AED);
  }

  String _agendaType(NexusTask task) {
    final category = task.category.toLowerCase();
    if (category.contains('meeting')) return 'Meeting';
    if (category.contains('reminder')) return 'Reminder';
    return 'Task';
  }

  CalendarDesktopView get _desktopView {
    return CalendarDesktopView.values[_view.index];
  }

  String get _title {
    final date =
        '${_focusedDate.day}/${_focusedDate.month}/${_focusedDate.year}';
    return switch (_view) {
      CalendarView.month => '${_focusedDate.month}/${_focusedDate.year}',
      CalendarView.week => 'Week of $date',
      CalendarView.day => date,
    };
  }
}

class _EventDetailPanel extends StatelessWidget {
  const _EventDetailPanel({required this.event, required this.onClose});

  final DayCalendarEvent event;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final color = event.color ?? Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Event Detail',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: .35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.category ?? 'Event',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.subtitle ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _DetailRow(
            icon: Icons.schedule_rounded,
            label: '${_time(event.start)} - ${_time(event.end)}',
          ),
          if (event.location != null)
            _DetailRow(icon: Icons.location_on_rounded, label: event.location!),
          if (event.participants.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Participants',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final name in event.participants) _ParticipantRow(name: name),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit Event'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(name.characters.first.toUpperCase()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
