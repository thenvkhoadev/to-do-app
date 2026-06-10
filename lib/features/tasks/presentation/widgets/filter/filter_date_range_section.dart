import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterDateRangeSection extends StatelessWidget {
  const FilterDateRangeSection({
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

  static const _presets = [
    (DateRangePreset.today, 'Today'),
    (DateRangePreset.thisWeek, 'This Week'),
    (DateRangePreset.month, 'This Month'),
    (DateRangePreset.custom, 'Custom'),
  ];

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _presets.map((item) {
                final (value, label) = item;
                final active = preset == value;
                return GestureDetector(
                  onTap: () => onPresetChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          active
                              ? DashboardColors.secondaryContainer.withValues(
                                alpha: .15,
                              )
                              : DashboardColors.surfaceLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            active
                                ? DashboardColors.secondary.withValues(
                                  alpha: .40,
                                )
                                : DashboardColors.outlineVariant.withValues(
                                  alpha: .15,
                                ),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color:
                            active
                                ? DashboardColors.secondary
                                : DashboardColors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _DateInput(
                value: startDate == null ? null : formatter.format(startDate!),
                hint: 'Jun 2, 2026',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) onRangeChanged(picked, endDate);
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: DashboardColors.onSurfaceVariant,
                size: 16,
              ),
            ),
            Expanded(
              child: _DateInput(
                value: endDate == null ? null : formatter.format(endDate!),
                hint: 'Jun 9, 2026',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) onRangeChanged(startDate, picked);
                },
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.calendar_month_outlined,
              color: DashboardColors.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ],
    );
  }
}

class _DateInput extends StatelessWidget {
  const _DateInput({required this.hint, required this.onTap, this.value});

  final String? value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DashboardColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Text(
        value ?? hint,
        style: TextStyle(
          color:
              value == null
                  ? DashboardColors.onSurfaceVariant
                  : DashboardColors.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
