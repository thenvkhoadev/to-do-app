import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_search_field.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';
import 'package:to_do_app/features/streak/presentation/widgets/streak_topbar_button.dart';
import 'package:to_do_app/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart' show WorkspaceSwitcher;


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
              SizedBox(width: 32),
              WorkspaceSwitcher(),
              Spacer(),
              NotificationBellButton(),
              SizedBox(width: 10),
              StreakTopbarButton(),
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


