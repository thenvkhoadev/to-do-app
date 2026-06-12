import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskTimePickerCard extends StatefulWidget {
  const TaskTimePickerCard({
    required this.label,
    required this.icon,
    required this.initialHour,
    required this.initialMinute,
    required this.onChanged,
    super.key,
  });

  final String label;
  final IconData icon;
  final int initialHour;
  final int initialMinute;
  final void Function(int hour, int minute) onChanged;

  @override
  State<TaskTimePickerCard> createState() => _TaskTimePickerCardState();
}

class _TaskTimePickerCardState extends State<TaskTimePickerCard> {
  late int _hour;
  late int _minute;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _onHourChanged(int index) {
    setState(() => _hour = index);
    widget.onChanged(_hour, _minute);
  }

  void _onMinuteChanged(int index) {
    setState(() => _minute = index);
    widget.onChanged(_hour, _minute);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wheelWidth = constraints.maxWidth < 300
            ? 55.0
            : constraints.maxWidth < 500
                ? 65.0
                : 75.0;
        final itemExtent = 40.0;
        final pickerHeight = 180.0;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1117),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF262A35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label row
              Row(
                children: [
                  Icon(widget.icon, color: DashboardColors.primary, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Wheel pickers row
              SizedBox(
                height: pickerHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hour wheel
                    _WheelPicker(
                      controller: _hourController,
                      itemCount: 25,
                      itemExtent: itemExtent,
                      width: wheelWidth,
                      onChanged: _onHourChanged,
                      labelBuilder: (i) => i.toString().padLeft(2, '0'),
                      selectedIndex: _hour,
                    ),

                    // Separator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'h',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Minute wheel
                    _WheelPicker(
                      controller: _minuteController,
                      itemCount: 60,
                      itemExtent: itemExtent,
                      width: wheelWidth,
                      onChanged: _onMinuteChanged,
                      labelBuilder: (i) => i.toString().padLeft(2, '0'),
                      selectedIndex: _minute,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'm',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Total time summary
              Center(
                child: Text(
                  '${_hour}h ${_minute}m',
                  style: TextStyle(
                    color: DashboardColors.primary.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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


// ── Wheel Picker ──────────────────────────────────────────────────────────────

class _WheelPicker extends StatelessWidget {
  const _WheelPicker({
    required this.controller,
    required this.itemCount,
    required this.itemExtent,
    required this.width,
    required this.onChanged,
    required this.labelBuilder,
    required this.selectedIndex,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final double itemExtent;
  final double width;
  final ValueChanged<int> onChanged;
  final String Function(int) labelBuilder;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selected highlight overlay
          Container(
            height: itemExtent,
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DashboardColors.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
          // Picker
          CupertinoPicker(
            scrollController: controller,
            itemExtent: itemExtent,
            onSelectedItemChanged: onChanged,
            selectionOverlay: const SizedBox.shrink(),
            children: List.generate(itemCount, (i) {
              final isSelected = i == selectedIndex;
              return Center(
                child: Text(
                  labelBuilder(i),
                  style: TextStyle(
                    color: isSelected
                        ? DashboardColors.primary
                        : Colors.white.withValues(alpha: 0.45),
                    fontSize: isSelected ? 20 : 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
