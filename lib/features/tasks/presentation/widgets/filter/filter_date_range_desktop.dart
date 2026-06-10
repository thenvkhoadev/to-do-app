import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterDateRangeDesktop extends StatefulWidget {
  const FilterDateRangeDesktop({
    required this.preset,
    required this.startDate,
    required this.endDate,
    required this.onPresetChanged,
    required this.onRangeChanged,
    super.key,
  });

  final DateRangePreset preset;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateRangePreset> onPresetChanged;
  final void Function(DateTime?, DateTime?) onRangeChanged;

  @override
  State<FilterDateRangeDesktop> createState() => _FilterDateRangeDesktopState();
}

class _FilterDateRangeDesktopState extends State<FilterDateRangeDesktop> {
  late DateTime _focusedMonth;
  DateTime? _selectedStart;
  DateTime? _selectedEnd;

  @override
  void initState() {
    super.initState();
    _selectedStart = widget.startDate;
    _selectedEnd = widget.endDate;
    _focusedMonth = widget.startDate ?? DateTime.now();
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (_selectedStart == null || _selectedEnd != null) {
        _selectedStart = day;
        _selectedEnd = null;
      } else if (day.isBefore(_selectedStart!)) {
        _selectedEnd = _selectedStart;
        _selectedStart = day;
      } else {
        _selectedEnd = day;
      }
    });
    widget.onRangeChanged(_selectedStart, _selectedEnd);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('DATE RANGE'),
        const SizedBox(height: 16),
        Row(
          children:
              [
                (DateRangePreset.today, 'Today'),
                (DateRangePreset.thisWeek, 'This Week'),
                (DateRangePreset.month, 'Month'),
              ].map((item) {
                final active = widget.preset == item.$1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: item.$1 == DateRangePreset.month ? 0 : 8,
                    ),
                    child: _PresetButton(
                      label: item.$2,
                      active: active,
                      onTap: () => widget.onPresetChanged(item.$1),
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1C1D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF46464F).withValues(alpha: .20),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _monthLabel(_focusedMonth),
                    style: const TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      _MonthButton(
                        icon: Icons.chevron_left,
                        onTap:
                            () => setState(
                              () =>
                                  _focusedMonth = DateTime(
                                    _focusedMonth.year,
                                    _focusedMonth.month - 1,
                                  ),
                            ),
                      ),
                      const SizedBox(width: 8),
                      _MonthButton(
                        icon: Icons.chevron_right,
                        onTap:
                            () => setState(
                              () =>
                                  _focusedMonth = DateTime(
                                    _focusedMonth.year,
                                    _focusedMonth.month + 1,
                                  ),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children:
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: const TextStyle(
                                  color: Color(0xFFC7C5D0),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 4),
              _calendarGrid(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _calendarGrid() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month);
    final startOffset = (first.weekday - 1) % 7;
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final rows = ((startOffset + daysInMonth) / 7).ceil();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: 30,
      ),
      itemCount: rows * 7,
      itemBuilder: (_, i) {
        final day = i - startOffset + 1;
        if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
        final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
        final isStart =
            _selectedStart != null && _sameDay(date, _selectedStart!);
        final isEnd = _selectedEnd != null && _sameDay(date, _selectedEnd!);
        final inRange =
            _selectedStart != null &&
            _selectedEnd != null &&
            date.isAfter(_selectedStart!) &&
            date.isBefore(_selectedEnd!);
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _onDayTap(date),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color:
                    isStart || isEnd
                        ? const Color(0xFFE1DFFF)
                        : inRange
                        ? const Color(0xFFE1DFFF).withValues(alpha: .20)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    color:
                        isStart || isEnd
                            ? const Color(0xFF131449)
                            : inRange
                            ? const Color(0xFFE1DFFF)
                            : DashboardColors.onSurface,
                    fontSize: 12,
                    fontWeight:
                        isStart || isEnd || inRange
                            ? FontWeight.w800
                            : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthLabel(DateTime date) {
    const names = [
      '',
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
    ];
    return '${names[date.month]} ${date.year}';
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              active
                  ? const Color(0xFFE1DFFF).withValues(alpha: .10)
                  : Colors.white.withValues(alpha: .03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                active
                    ? const Color(0xFFE1DFFF).withValues(alpha: .20)
                    : Colors.white.withValues(alpha: .08),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFFE1DFFF) : const Color(0xFFC7C5D0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Icon(icon, color: const Color(0xFFC7C5D0), size: 20),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFFC7C5D0),
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.12,
    ),
  );
}
