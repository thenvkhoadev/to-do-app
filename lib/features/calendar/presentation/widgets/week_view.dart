import 'package:flutter/material.dart';

class WeekView extends StatelessWidget {
  const WeekView({
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
    super.key,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) {
    final baseDate = selectedDate ?? DateTime.now();
    final weekStart = baseDate.subtract(
      Duration(days: baseDate.weekday - DateTime.monday),
    );
    final days = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 720;

        return Container(
          padding: EdgeInsets.all(isDesktop ? 24 : 14),
          decoration: _glassDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WeekHeader(
                weekStart: weekStart,
                weekEnd: days.last,
                onPreviousWeek: onPreviousWeek,
                onNextWeek: onNextWeek,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: isDesktop ? 132 : 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  separatorBuilder:
                      (_, _) => SizedBox(width: isDesktop ? 12 : 8),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    return SizedBox(
                      width:
                          isDesktop ? (constraints.maxWidth - 48 - 72) / 7 : 74,
                      child: _WeekDayTile(
                        date: day,
                        selected:
                            selectedDate != null &&
                            _isSameDate(day, selectedDate!),
                        today: _isSameDate(day, DateTime.now()),
                        onTap: () => onDateSelected(day),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Expanded(child: _Timeline(date: baseDate, isDesktop: isDesktop)),
            ],
          ),
        );
      },
    );
  }
}

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
            '${_shortDate(weekStart)} - ${_shortDate(weekEnd)}',
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

class _WeekDayTile extends StatelessWidget {
  const _WeekDayTile({
    required this.date,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color:
          selected
              ? colors.primaryContainer
              : Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color:
                  today ? colors.primary : Colors.white.withValues(alpha: .10),
              width: today ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _weekday(date),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? colors.onPrimaryContainer : Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${date.day}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: selected ? colors.onPrimaryContainer : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (today) ...[
                const SizedBox(height: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.date, required this.isDesktop});

  final DateTime date;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(25, (index) => index);

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: hours.length,
      separatorBuilder:
          (_, _) =>
              Divider(color: Colors.white.withValues(alpha: .08), height: 1),
      itemBuilder: (context, index) {
        final hour = hours[index];
        return SizedBox(
          height: isDesktop ? 58 : 48,
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white54),
                ),
              ),
              Expanded(
                child: Text(
                  _isSameDate(date, DateTime.now()) &&
                          hour == DateTime.now().hour
                      ? 'Now'
                      : '',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
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

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _weekday(DateTime date) {
  return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday -
      1];
}

String _shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
