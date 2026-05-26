import 'package:flutter/material.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/agenda_panel.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/calendar_month_view.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/day_view.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/desktop_layout.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/mobile_layout.dart'
    as mobile;
import 'package:to_do_app/features/calendar/presentation/widgets/week_view.dart';
import 'package:to_do_app/widgets/dashboard/mobile_dashboard_widgets.dart';

enum CalendarView { month, week, day }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarView _view = CalendarView.month;
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  DayCalendarEvent? _selectedEvent;

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
      _selectedDate = nextDate;
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
            calendar: _calendarContent,
            agenda:
                _selectedEvent == null
                    ? AgendaPanel(date: _selectedDate, events: _agendaEvents)
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
          timelineAgenda: DayView(
            date: _selectedDate,
            events: _dayEvents,
            onEventTap: (event) => setState(() => _selectedEvent = event),
          ),
          bottomNavigation: MobileBottomNavBar(
            bottomInset: MediaQuery.paddingOf(context).bottom,
          ),
          onAdd: () {},
        );
      },
    );
  }

  Widget get _calendarContent {
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
      CalendarView.day => DayView(
        date: _selectedDate,
        events: _dayEvents,
        onEventTap: (event) => setState(() => _selectedEvent = event),
      ),
    };
  }

  List<DayCalendarEvent> get _dayEvents {
    return _mockEvents.map((event) {
      final start = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        event.hour,
        event.minute,
      );
      return DayCalendarEvent(
        start: start,
        end: start.add(Duration(minutes: event.durationMinutes)),
        title: event.title,
        subtitle: event.subtitle,
        color: event.color,
        category: event.category,
        location: event.location,
        participants: event.participants,
      );
    }).toList();
  }

  List<AgendaPanelEvent> get _agendaEvents {
    return _mockEvents.map((event) {
      return AgendaPanelEvent(
        start: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          event.hour,
          event.minute,
        ),
        title: event.title,
        subtitle: event.subtitle,
        color: event.color,
      );
    }).toList();
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

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class _MockCalendarEvent {
  const _MockCalendarEvent({
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.category,
    this.location,
    this.participants = const [],
  });

  final int hour;
  final int minute;
  final int durationMinutes;
  final String title;
  final String subtitle;
  final Color color;
  final String category;
  final String? location;
  final List<String> participants;
}

const _mockEvents = [
  _MockCalendarEvent(
    hour: 9,
    minute: 0,
    durationMinutes: 60,
    title: 'Daily planning',
    subtitle: 'Review priorities and blockers',
    color: Color(0xFF7C3AED),
    category: 'Focus',
    location: 'Deep Work Room',
    participants: ['Khoa Nguyen', 'AI Planner'],
  ),
  _MockCalendarEvent(
    hour: 11,
    minute: 30,
    durationMinutes: 90,
    title: 'Project sync',
    subtitle: 'Dashboard calendar rollout',
    color: Color(0xFF06B6D4),
    category: 'Meeting',
    location: 'Google Meet',
    participants: ['Design Team', 'Product Team', 'Khoa Nguyen'],
  ),
  _MockCalendarEvent(
    hour: 14,
    minute: 0,
    durationMinutes: 75,
    title: 'Task review',
    subtitle: 'Validate selected sprint items',
    color: Color(0xFFF97316),
    category: 'Review',
    location: 'Sprint Board',
    participants: ['Khoa Nguyen', 'QA Lead'],
  ),
  _MockCalendarEvent(
    hour: 16,
    minute: 15,
    durationMinutes: 45,
    title: 'AI follow-up',
    subtitle: 'Generate next action list',
    color: Color(0xFF22C55E),
    category: 'AI',
    location: 'Assistant Workspace',
    participants: ['Khoa Nguyen', 'TaskFlow AI'],
  ),
];
