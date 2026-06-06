import 'dart:async';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/calendar_month_view.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/day_view.dart';

class WeekView extends StatefulWidget {
  const WeekView({
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
    this.taskEvents = const {},
    this.dayEvents = const [],
    this.onEventTap,
    super.key,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final Map<String, List<CalendarMonthEvent>> taskEvents;
  final List<DayCalendarEvent> dayEvents;
  final ValueChanged<DayCalendarEvent>? onEventTap;

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseDate = widget.selectedDate ?? _now;
    final weekStart = baseDate.subtract(Duration(days: baseDate.weekday - DateTime.monday));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 720;
        final pad = isDesktop ? 24.0 : 12.0;

        return Container(
          padding: EdgeInsets.all(pad),
          decoration: _glassDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WeekHeader(
                weekStart: weekStart,
                weekEnd: days.last,
                onPreviousWeek: widget.onPreviousWeek,
                onNextWeek: widget.onNextWeek,
              ),
              const SizedBox(height: 14),
              // Day tiles row
              SizedBox(
                height: isDesktop ? 80 : 72,
                child: Row(
                  children: [
                    SizedBox(width: isDesktop ? 52.0 : 40.0), // time gutter
                    ...days.map((day) {
                      final key = '${day.year}-${day.month}-${day.day}';
                      final events = widget.taskEvents[key] ?? [];
                      return Expanded(
                        child: _WeekDayTile(
                          date: day,
                          selected: widget.selectedDate != null && _isSameDate(day, widget.selectedDate!),
                          today: _isSameDate(day, _now),
                          events: events,
                          onTap: () => widget.onDateSelected(day),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Grid with tasks
              Expanded(
                child: _WeekGrid(
                  days: days,
                  now: _now,
                  dayEvents: widget.dayEvents,
                  timeWidth: isDesktop ? 52.0 : 40.0,
                  onEventTap: widget.onEventTap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.weekStart,
    required this.weekEnd,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_shortDate(weekStart)} – ${_shortDate(weekEnd)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: onPreviousWeek,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onNextWeek,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

// ── Day tile ──────────────────────────────────────────────────────────────────

class _WeekDayTile extends StatelessWidget {
  const _WeekDayTile({
    required this.date,
    required this.selected,
    required this.today,
    required this.onTap,
    this.events = const [],
  });

  final DateTime date;
  final bool selected;
  final bool today;
  final VoidCallback onTap;
  final List<CalendarMonthEvent> events;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer
              : today
                  ? cs.primary.withValues(alpha: .10)
                  : Colors.white.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: today ? cs.primary : Colors.white.withValues(alpha: .10),
            width: today ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdayShort(date),
              style: TextStyle(
                color: selected ? cs.onPrimaryContainer : Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? cs.onPrimaryContainer : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (events.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: events.take(3).map((e) => Container(
                  width: 4, height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: e.color,
                    shape: BoxShape.circle,
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Week Grid ─────────────────────────────────────────────────────────────────

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.days,
    required this.now,
    required this.dayEvents,
    required this.timeWidth,
    this.onEventTap,
  });

  final List<DateTime> days;
  final DateTime now;
  final List<DayCalendarEvent> dayEvents;
  final double timeWidth;
  final ValueChanged<DayCalendarEvent>? onEventTap;

  static const _hourHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = (constraints.maxWidth - timeWidth) / 7;

        return SingleChildScrollView(
          child: SizedBox(
            height: 24 * _hourHeight,
            child: Stack(
              children: [
                // Hour grid lines + time labels
                _WeekGridLines(timeWidth: timeWidth, hourHeight: _hourHeight),
                // Day column separators
                ...List.generate(7, (i) => Positioned(
                  left: timeWidth + i * colWidth,
                  top: 0,
                  bottom: 0,
                  width: 1,
                  child: Container(color: Colors.white.withValues(alpha: .05)),
                )),
                // Task blocks per day
                for (int di = 0; di < days.length; di++)
                  ..._buildDayBlocks(
                    context,
                    days[di],
                    left: timeWidth + di * colWidth,
                    colWidth: colWidth,
                  ),
                // Now line across full width (today only)
                if (_isSameWeek(now, days))
                  _NowIndicator(
                    now: now,
                    days: days,
                    timeWidth: timeWidth,
                    colWidth: colWidth,
                    hourHeight: _hourHeight,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDayBlocks(
    BuildContext context,
    DateTime day,
    {required double left, required double colWidth}
  ) {
    final events = dayEvents
        .where((e) => _isSameDate(e.start, day))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    if (events.isEmpty) return [];

    // Group overlapping events
    final groups = _buildOverlapGroups(events);
    final result = <Widget>[];

    for (final group in groups) {
      for (int i = 0; i < group.length; i++) {
        final e = group[i];
        final groupColW = (colWidth - 4 - (group.length - 1) * 2) / group.length;
        final blockLeft = left + 2 + i * (groupColW + 2);
        final startFrac = e.start.hour + e.start.minute / 60.0;
        final durMin = e.end.difference(e.start).inMinutes.clamp(15, 1440);
        final height = (durMin / 60.0 * _hourHeight - 2).clamp(22.0, double.infinity);
        final isShort = durMin < 35;
        final isLive = _isLive(e);

        result.add(Positioned(
          top: startFrac * _hourHeight,
          left: blockLeft,
          width: groupColW,
          height: height,
          child: _WeekTaskBlock(
            event: e,
            isShort: isShort,
            isLive: isLive,
            onTap: onEventTap == null ? null : () => onEventTap!(e),
          ),
        ));
      }
    }
    return result;
  }

  bool _isLive(DayCalendarEvent e) {
    final now2 = DateTime.now();
    return now2.isAfter(e.start) && now2.isBefore(e.end);
  }

  List<List<DayCalendarEvent>> _buildOverlapGroups(List<DayCalendarEvent> sorted) {
    if (sorted.isEmpty) return [];
    final groups = <List<DayCalendarEvent>>[];
    var current = [sorted.first];
    var groupEnd = sorted.first.end;
    for (int i = 1; i < sorted.length; i++) {
      final e = sorted[i];
      if (e.start.isBefore(groupEnd)) {
        current.add(e);
        if (e.end.isAfter(groupEnd)) groupEnd = e.end;
      } else {
        groups.add(current);
        current = [e];
        groupEnd = e.end;
      }
    }
    groups.add(current);
    return groups;
  }
}

// ── Task block ────────────────────────────────────────────────────────────────

class _WeekTaskBlock extends StatefulWidget {
  const _WeekTaskBlock({
    required this.event,
    required this.isShort,
    required this.isLive,
    this.onTap,
  });
  final DayCalendarEvent event;
  final bool isShort;
  final bool isLive;
  final VoidCallback? onTap;

  @override
  State<_WeekTaskBlock> createState() => _WeekTaskBlockState();
}

class _WeekTaskBlockState extends State<_WeekTaskBlock> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.event.color ?? Theme.of(context).colorScheme.primary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: color.withValues(alpha: _hovered ? .20 : .12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.isLive
                    ? color
                    : color.withValues(alpha: .30),
                width: widget.isLive ? 1.5 : 1,
              ),
              boxShadow: _hovered || widget.isLive
                  ? [BoxShadow(color: color.withValues(alpha: .18), blurRadius: 10)]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: color),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(4, widget.isShort ? 3 : 5, 4, widget.isShort ? 3 : 5),
                      child: widget.isShort
                          ? _ShortContent(event: widget.event, color: color, isLive: widget.isLive)
                          : _FullWeekContent(event: widget.event, color: color, isLive: widget.isLive),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortContent extends StatelessWidget {
  const _ShortContent({required this.event, required this.color, required this.isLive});
  final DayCalendarEvent event;
  final Color color;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isLive)
          Container(
            margin: const EdgeInsets.only(right: 3),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900)),
          ),
        Expanded(
          child: Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _FullWeekContent extends StatelessWidget {
  const _FullWeekContent({required this.event, required this.color, required this.isLive});
  final DayCalendarEvent event;
  final Color color;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLive)
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .5)),
          ),
        Text(
          event.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1.2),
        ),
        const SizedBox(height: 2),
        Text(
          '${_t(event.start)}–${_t(event.end)}',
          style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 9, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── Grid lines ────────────────────────────────────────────────────────────────

class _WeekGridLines extends StatelessWidget {
  const _WeekGridLines({required this.timeWidth, required this.hourHeight});
  final double timeWidth;
  final double hourHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(24, (hour) => SizedBox(
        height: hourHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: timeWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .30),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: .06)),
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

// ── Now indicator ─────────────────────────────────────────────────────────────

class _NowIndicator extends StatelessWidget {
  const _NowIndicator({
    required this.now,
    required this.days,
    required this.timeWidth,
    required this.colWidth,
    required this.hourHeight,
  });
  final DateTime now;
  final List<DateTime> days;
  final double timeWidth;
  final double colWidth;
  final double hourHeight;

  @override
  Widget build(BuildContext context) {
    final top = (now.hour + now.minute / 60.0) * hourHeight;
    final color = Theme.of(context).colorScheme.error;
    return Positioned(
      top: top,
      left: timeWidth - 6,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(child: Container(height: 1.5, color: color.withValues(alpha: .6))),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

BoxDecoration _glassDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.surface.withValues(alpha: .58),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.white.withValues(alpha: .10)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .24),
        blurRadius: 32,
        offset: const Offset(0, 18),
      ),
    ],
  );
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isSameWeek(DateTime date, List<DateTime> days) =>
    days.any((d) => _isSameDate(d, date));

String _weekdayShort(DateTime d) =>
    const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];

String _shortDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

String _t(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
