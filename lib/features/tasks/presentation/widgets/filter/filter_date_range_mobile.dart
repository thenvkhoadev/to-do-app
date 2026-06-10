import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterDateRangeMobile extends StatelessWidget {
  const FilterDateRangeMobile({
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
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('DATE RANGE'),
            Row(
              children: [
                _PresetChip(
                  label: 'Today',
                  active: preset == DateRangePreset.today,
                  onTap: () => onPresetChanged(DateRangePreset.today),
                ),
                const SizedBox(width: 8),
                _PresetChip(
                  label: 'This Week',
                  active: preset == DateRangePreset.thisWeek,
                  onTap: () => onPresetChanged(DateRangePreset.thisWeek),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Start Date',
                value: startDate == null ? null : fmt.format(startDate!),
                onTap: () async {
                  final picked = await _pickDate(
                    context,
                    startDate ?? DateTime.now(),
                    DateTime(2020),
                  );
                  if (picked != null) onRangeChanged(picked, endDate);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                label: 'End Date',
                value: endDate == null ? null : fmt.format(endDate!),
                onTap: () async {
                  final picked = await _pickDate(
                    context,
                    endDate ?? startDate ?? DateTime.now(),
                    startDate ?? DateTime(2020),
                  );
                  if (picked != null) onRangeChanged(startDate, picked);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<DateTime?> _pickDate(
    BuildContext context,
    DateTime initialDate,
    DateTime firstDate,
  ) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2030),
      builder:
          (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFE1DFFF),
                onPrimary: Color(0xFF131449),
                surface: Color(0xFF1F2021),
                onSurface: DashboardColors.onSurface,
              ),
            ),
            child: child!,
          ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
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
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color:
              active
                  ? DashboardColors.secondary.withValues(alpha: .10)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                active
                    ? DashboardColors.secondary.withValues(alpha: .20)
                    : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? DashboardColors.secondary : const Color(0xFFC7C5D0),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.onTap, this.value});
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFC7C5D0),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1C1D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Select...',
                    style: TextStyle(
                      color:
                          value == null
                              ? const Color(0xFFC7C5D0)
                              : DashboardColors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFFC7C5D0),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
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
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );
}
