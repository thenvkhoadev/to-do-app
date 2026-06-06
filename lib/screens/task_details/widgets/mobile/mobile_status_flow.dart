import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileStatusFlow extends StatelessWidget {
  const MobileStatusFlow({required this.status, super.key});
  final TaskBoardStatus status;

  static const _steps = ['Draft', 'Todo', 'Active', 'Done'];
  static const _statuses = [
    TaskBoardStatus.draft,
    TaskBoardStatus.todo,
    TaskBoardStatus.inProgress,
    TaskBoardStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final idx = _statuses.indexOf(status).clamp(0, _steps.length - 1);
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'STATUS FLOW',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${_steps[idx]} State',
                style: const TextStyle(
                  color: DashboardColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              // Track line
              Positioned(
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: idx / (_steps.length - 1),
                    minHeight: 2,
                    backgroundColor: Colors.white.withValues(alpha: .10),
                    valueColor:
                        const AlwaysStoppedAnimation(DashboardColors.primary),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_steps.length, (i) {
                  final done = i < idx;
                  final current = i == idx;
                  final future = i > idx;
                  return Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? DashboardColors.primaryContainer
                              : current
                                  ? Colors.transparent
                                  : DashboardColors.surface,
                          border: Border.all(
                            color: done || current
                                ? DashboardColors.primary
                                : Colors.white.withValues(alpha: .08),
                            width: 2,
                          ),
                        ),
                        child: done
                            ? const Icon(Icons.check_rounded,
                                color: DashboardColors.onPrimary, size: 16)
                            : current
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
                                        color: Colors.white
                                            .withValues(alpha: .20),
                                      ),
                                    ),
                                  ),
                      ),
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: future ? 0.4 : 1.0,
                        child: Text(
                          _steps[i],
                          style: TextStyle(
                            color: current
                                ? DashboardColors.primary
                                : DashboardColors.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: current
                                ? FontWeight.w700
                                : FontWeight.w600,
                            letterSpacing: .05,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(24),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: .12)),
                left: BorderSide(color: Colors.white.withValues(alpha: .05)),
                right: BorderSide(color: Colors.white.withValues(alpha: .05)),
                bottom: BorderSide(color: Colors.white.withValues(alpha: .05)),
              ),
            ),
            child: child,
          ),
        ),
      );
}
