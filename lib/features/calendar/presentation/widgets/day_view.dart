import 'package:flutter/material.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/event_card.dart';

class DayCalendarEvent {
  const DayCalendarEvent({
    required this.start,
    required this.end,
    required this.title,
    this.subtitle,
    this.color,
    this.category,
    this.location,
    this.participants = const [],
  });

  final DateTime start;
  final DateTime end;
  final String title;
  final String? subtitle;
  final Color? color;
  final String? category;
  final String? location;
  final List<String> participants;
}

class DayView extends StatelessWidget {
  const DayView({
    required this.date,
    this.events = const [],
    this.onEventTap,
    super.key,
  });

  final DateTime date;
  final List<DayCalendarEvent> events;
  final ValueChanged<DayCalendarEvent>? onEventTap;

  static const _hourHeight = 72.0;
  static const _timeWidth = 58.0;

  @override
  Widget build(BuildContext context) {
    final dayEvents =
        events.where((event) => _sameDay(event.start, date)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 720;
        final contentWidth =
            constraints.maxWidth - _timeWidth - (desktop ? 48 : 24);

        return Container(
          padding: EdgeInsets.all(desktop ? 24 : 12),
          decoration: _glass(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_weekday(date)}, ${date.day}/${date.month}/${date.year}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: 24 * _hourHeight,
                    child: Stack(
                      children: [
                        const _Grid(
                          hourHeight: _hourHeight,
                          timeWidth: _timeWidth,
                        ),
                        for (final event in dayEvents)
                          _EventBlock(
                            event: event,
                            hourHeight: _hourHeight,
                            left: _timeWidth,
                            width: contentWidth.clamp(180, double.infinity),
                            onTap:
                                onEventTap == null
                                    ? null
                                    : () => onEventTap!(event),
                          ),
                        if (_sameDay(date, DateTime.now()))
                          const _NowLine(
                            hourHeight: _hourHeight,
                            left: _timeWidth,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.hourHeight, required this.timeWidth});

  final double hourHeight;
  final double timeWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var hour = 0; hour < 24; hour++)
          SizedBox(
            height: hourHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: timeWidth,
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({
    required this.event,
    required this.hourHeight,
    required this.left,
    required this.width,
    this.onTap,
  });

  final DayCalendarEvent event;
  final double hourHeight;
  final double left;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final start = event.start.hour + event.start.minute / 60;
    final duration =
        event.end.difference(event.start).inMinutes.clamp(30, 1440) / 60;
    final color = event.color ?? Theme.of(context).colorScheme.primary;

    return Positioned(
      top: start * hourHeight,
      left: left,
      width: width,
      height: (duration * hourHeight - 6).clamp(132, double.infinity),
      child: Material(
        color: color.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: .55)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .16),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRect(
              child: CalendarEventCard(
                title: event.title,
                startTime: event.start,
                endTime: event.end,
                color: color,
                category: event.category,
                location: event.location,
                participants: event.participants,
                onTap: onTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NowLine extends StatelessWidget {
  const _NowLine({required this.hourHeight, required this.left});

  final double hourHeight;
  final double left;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final color = Theme.of(context).colorScheme.tertiary;

    return Positioned(
      top: (now.hour + now.minute / 60) * hourHeight,
      left: left - 7,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(child: Container(height: 2, color: color)),
        ],
      ),
    );
  }
}

BoxDecoration _glass(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.surface.withValues(alpha: .58),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.white.withValues(alpha: .10)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .28),
        blurRadius: 36,
        offset: const Offset(0, 18),
      ),
    ],
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekday(DateTime date) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
