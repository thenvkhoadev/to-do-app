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
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dates.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemBuilder: (context, index) {
              final date = dates[index];
              return _MonthDateCell(
                date: date,
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

class _MonthDateCell extends StatelessWidget {
  const _MonthDateCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor =
        isCurrentMonth
            ? colorScheme.onSurface
            : colorScheme.onSurface.withValues(alpha: .38);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border:
                  isToday
                      ? Border.all(color: colorScheme.primary, width: 1.5)
                      : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimaryContainer : textColor,
                fontWeight: isToday || isSelected ? FontWeight.w700 : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
