import 'package:flutter/material.dart';

class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({
    required this.focusedDate,
    required this.selectedDate,
    required this.onDateSelected,
    super.key,
  });

  final DateTime focusedDate;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final dates = _monthGridDates(focusedDate);

    return Column(
      children: [
        const _WeekdayRow(),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: dates.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemBuilder: (context, index) {
              final date = dates[index];
              return _MonthDateCell(
                date: date,
                events: _eventsFor(date),
                isCurrentMonth: date.month == focusedDate.month,
                isToday: _isSameDate(date, DateTime.now()),
                isSelected:
                    selectedDate != null && _isSameDate(date, selectedDate!),
                onTap: () => onDateSelected(date),
              );
            },
          ),
        ),
      ],
    );
  }

  List<DateTime> _monthGridDates(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final startOffset = firstDay.weekday - DateTime.monday;
    final startDate = firstDay.subtract(Duration(days: startOffset));

    return List.generate(42, (index) => startDate.add(Duration(days: index)));
  }

  List<_MonthEvent> _eventsFor(DateTime date) {
    final day = date.day;
    if (day % 11 == 0) {
      return const [
        _MonthEvent.ai(),
        _MonthEvent.meeting(),
        _MonthEvent.urgent(),
        _MonthEvent.done(),
        _MonthEvent.meeting(),
      ];
    }
    if (day % 7 == 0) {
      return const [
        _MonthEvent.urgent(title: 'Sprint Review'),
        _MonthEvent.ai(),
        _MonthEvent.meeting(),
      ];
    }
    if (day % 5 == 0) return const [_MonthEvent.meeting(), _MonthEvent.done()];
    if (day % 3 == 0) return const [_MonthEvent.ai()];
    return const [];
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: [
        for (final weekday in weekdays)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                weekday,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthDateCell extends StatefulWidget {
  const _MonthDateCell({
    required this.date,
    required this.events,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final List<_MonthEvent> events;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_MonthDateCell> createState() => _MonthDateCellState();
}

class _MonthDateCellState extends State<_MonthDateCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor =
        widget.isCurrentMonth
            ? colorScheme.onSurface
            : colorScheme.onSurface.withValues(alpha: .38);
    final visible = widget.events.take(3).toList();
    final overflow = widget.events.length - visible.length;
    final priority =
        widget.events.where((event) => event.title != null).firstOrNull;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.015 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color:
                widget.isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: .92)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
                decoration: BoxDecoration(
                  border:
                      widget.isToday || widget.isSelected
                          ? Border.all(
                            color: colorScheme.primary.withValues(
                              alpha: widget.isSelected ? .85 : .75,
                            ),
                            width: 1.5,
                          )
                          : Border.all(
                            color: Colors.white.withValues(
                              alpha: _hovered ? .10 : .04,
                            ),
                          ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      _hovered || widget.isSelected
                          ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: widget.isSelected ? .14 : .08,
                              ),
                              blurRadius: 16,
                            ),
                          ]
                          : null,
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.date.day}',
                      style: TextStyle(
                        color:
                            widget.isSelected
                                ? colorScheme.onPrimaryContainer
                                : textColor,
                        fontWeight:
                            widget.isToday || widget.isSelected
                                ? FontWeight.w700
                                : null,
                      ),
                    ),
                    const Spacer(),
                    if (priority != null && widget.isSelected)
                      _EventPreviewPill(event: priority),
                    if (visible.isNotEmpty) ...[
                      if (priority != null && widget.isSelected)
                        const SizedBox(height: 5),
                      _EventDots(
                        events: visible,
                        overflow: overflow,
                        selected: widget.isSelected,
                        hovered: _hovered,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventDots extends StatelessWidget {
  const _EventDots({
    required this.events,
    required this.overflow,
    required this.selected,
    required this.hovered,
  });

  final List<_MonthEvent> events;
  final int overflow;
  final bool selected;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final event in events)
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: hovered ? 6 : 5,
            height: hovered ? 6 : 5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: event.color.withValues(alpha: selected ? .95 : .72),
              boxShadow: [
                BoxShadow(
                  color: event.color.withValues(alpha: selected ? .30 : .18),
                  blurRadius: selected ? 8 : 5,
                ),
              ],
            ),
          ),
        if (overflow > 0)
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Text(
              '+$overflow',
              style: TextStyle(
                color:
                    selected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Colors.white60,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _EventPreviewPill extends StatelessWidget {
  const _EventPreviewPill({required this.event});

  final _MonthEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 20, maxHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: event.color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: event.color.withValues(alpha: .24)),
      ),
      child: Center(
        child: Text(
          event.title!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: event.color,
            fontSize: 9,
            height: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MonthEvent {
  const _MonthEvent.ai() : color = const Color(0xFFA78BFA), title = null;
  const _MonthEvent.meeting() : color = const Color(0xFF60A5FA), title = null;
  const _MonthEvent.urgent({this.title}) : color = const Color(0xFFFB923C);
  const _MonthEvent.done() : color = const Color(0xFF34D399), title = null;

  final Color color;
  final String? title;
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
