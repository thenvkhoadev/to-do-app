import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_search_field.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class TasksTopbar extends StatelessWidget {
  const TasksTopbar({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: DashboardColors.surface.withValues(alpha: .50),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .16),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Row(
            children: [
              TaskSearchField(desktop: true),
              SizedBox(width: 32),
              _TopTab(label: 'All Tasks', selected: true),
              _TopTab(label: 'Team Flux'),
              _TopTab(label: 'Personal'),
              Spacer(),
              _TopIcon(icon: Icons.notifications_none_rounded),
              SizedBox(width: 10),
              _TopIcon(icon: Icons.bolt_rounded, active: true),
              SizedBox(width: 14),
              ProfileAvatar(radius: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  const _TopTab({required this.label, this.selected = false});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 22),
    child: Text(
      label,
      style: TextStyle(
        color:
            selected
                ? DashboardColors.primary
                : DashboardColors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
        decoration: selected ? TextDecoration.underline : null,
        decorationColor: DashboardColors.primary,
        decorationThickness: 2,
      ),
    ),
  );
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon, this.active = false});
  final IconData icon;
  final bool active;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: () {},
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(
          icon,
          color:
              active
                  ? DashboardColors.primary
                  : DashboardColors.onSurfaceVariant,
        ),
      ),
    ),
  );
}
