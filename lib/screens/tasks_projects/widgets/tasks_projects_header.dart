import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TasksProjectsHeader extends StatelessWidget {
  const TasksProjectsHeader({this.mobile = false, super.key});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      'Active Projects',
      style: TextStyle(
        color: DashboardColors.onSurface,
        fontSize: mobile ? 24 : 32,
        fontWeight: FontWeight.w600,
        letterSpacing: mobile ? 0 : -.3,
        height: 1.2,
      ),
    );
    final subtitle = Text(
      'Focusing on 12 high-impact tasks today.',
      style: TextStyle(
        color: DashboardColors.onSurfaceVariant,
        fontSize: mobile ? 14 : 16,
        height: 1.5,
      ),
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 4),
          subtitle,
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _HeaderButton(
                  label: 'Filter',
                  icon: Icons.filter_list_rounded,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _HeaderButton(
                  label: 'New Task',
                  icon: Icons.add_rounded,
                  gradient: true,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 4), subtitle],
          ),
        ),
        const SizedBox(width: 24),
        const _HeaderButton(label: 'Filter', icon: Icons.filter_list_rounded),
        const SizedBox(width: 12),
        const _HeaderButton(
          label: 'New Task',
          icon: Icons.add_rounded,
          gradient: true,
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.label,
    required this.icon,
    this.gradient = false,
  });

  final String label;
  final IconData icon;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient:
            gradient
                ? const LinearGradient(
                  colors: [
                    DashboardColors.primaryContainer,
                    DashboardColors.secondaryContainer,
                  ],
                )
                : null,
        color: gradient ? null : Colors.white.withValues(alpha: .03),
        borderRadius: BorderRadius.circular(999),
        border:
            gradient
                ? null
                : Border.all(color: Colors.white.withValues(alpha: .1)),
        boxShadow:
            gradient
                ? [
                  BoxShadow(
                    color: DashboardColors.primary.withValues(alpha: .15),
                    blurRadius: 30,
                  ),
                ]
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: gradient ? Colors.white : DashboardColors.onSurface,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: gradient ? Colors.white : DashboardColors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
