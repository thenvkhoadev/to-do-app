import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/layouts/tasks_desktop_layout.dart';
import 'package:to_do_app/features/tasks/presentation/layouts/tasks_mobile_layout.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DashboardTheme.dark(),
      child: Scaffold(
        backgroundColor: DashboardColors.background,
        body: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: DashboardColors.background)),
            Positioned(top: -180, left: -120, child: _Glow(size: 420, color: DashboardColors.primary.withValues(alpha: .12))),
            Positioned(bottom: -160, right: -120, child: _Glow(size: 460, color: DashboardColors.secondary.withValues(alpha: .12))),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 1100) {
                    return const TasksDesktopLayout();
                  }
                  return const TasksMobileLayout();
                },
              ),
            ),
            const Positioned(top: 0, left: 0, right: 0, child: _ProgressIndicatorLine()),
          ],
        ),
      ),
    );
  }
}

class _ProgressIndicatorLine extends StatelessWidget {
  const _ProgressIndicatorLine();

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: .66,
      minHeight: 2,
      backgroundColor: Colors.white.withValues(alpha: .05),
      valueColor: const AlwaysStoppedAnimation(DashboardColors.primary),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 140, spreadRadius: 70)]));
  }
}
