import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DesktopStatusStepper extends StatelessWidget {
  const DesktopStatusStepper({required this.status, super.key});
  final TaskBoardStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(label: 'Draft', status: TaskBoardStatus.draft),
      _StepData(label: 'To Do', status: TaskBoardStatus.todo),
      _StepData(label: 'Active', status: TaskBoardStatus.inProgress),
      _StepData(label: 'Done', status: TaskBoardStatus.completed),
    ];
    final currentIndex = steps.indexWhere((s) => s.status == status);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EXECUTION FLOW',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(steps.length, (i) {
                final isDone = i < currentIndex;
                final isCurrent = i == currentIndex;
                final isLast = i == steps.length - 1;
                return _StepRow(
                  label: steps[i].label,
                  isDone: isDone,
                  isCurrent: isCurrent,
                  isLast: isLast,
                  subtitle: isDone
                      ? 'Completed'
                      : isCurrent
                          ? 'Up next in flow'
                          : null,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    this.subtitle,
  });
  final String label;
  final bool isDone, isCurrent, isLast;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final dotColor = isDone
        ? DashboardColors.primary
        : isCurrent
            ? Colors.transparent
            : Colors.transparent;
    final borderColor = isDone
        ? DashboardColors.primary
        : isCurrent
            ? DashboardColors.primary
            : Colors.white.withValues(alpha: .12);

    return Opacity(
      opacity: (!isDone && !isCurrent) ? 0.5 : 1.0,
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? DashboardColors.primary : dotColor,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: DashboardColors.onPrimary, size: 16)
                    : isCurrent
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: DashboardColors.primary,
                              ),
                            ),
                          )
                        : Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: .2),
                              ),
                            ),
                          ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color: Colors.white.withValues(alpha: .08),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isCurrent
                          ? DashboardColors.primary
                          : DashboardColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  const _StepData({required this.label, required this.status});
  final String label;
  final TaskBoardStatus status;
}
