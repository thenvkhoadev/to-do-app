import 'package:flutter/material.dart';
import 'package:to_do_app/core/utils/description_utils.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

enum TaskBoardStatus { draft, todo, inProgress, completed }

enum TaskBoardPriority { urgent, high, medium, low, done }

extension TaskBoardStatusUI on TaskBoardStatus {
  String get displayLabel => switch (this) {
        TaskBoardStatus.draft => 'Draft',
        TaskBoardStatus.todo => 'To-Do',
        TaskBoardStatus.inProgress => 'In Progress',
        TaskBoardStatus.completed => 'Completed',
      };

  IconData get displayIcon => switch (this) {
        TaskBoardStatus.draft => Icons.lightbulb_outline_rounded,
        TaskBoardStatus.todo => Icons.flag_rounded,
        TaskBoardStatus.inProgress => Icons.bolt_rounded,
        TaskBoardStatus.completed => Icons.verified_rounded,
      };

  Color get displayColor => switch (this) {
        TaskBoardStatus.draft => const Color(0xFFA855F7),
        TaskBoardStatus.todo => const Color(0xFF5B8CFF),
        TaskBoardStatus.inProgress => const Color(0xFFFFB020),
        TaskBoardStatus.completed => const Color(0xFF34C759),
      };

  String get tagline => switch (this) {
        TaskBoardStatus.draft => 'Brainstorms · Future features',
        TaskBoardStatus.todo => 'Ready to execute',
        TaskBoardStatus.inProgress => 'Current focus',
        TaskBoardStatus.completed => 'Completed successfully',
      };
}

class TaskBoardItem {
  const TaskBoardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.estimate,
    required this.assignee,
    required this.progress,
    required this.tags,
    this.aiSuggestion,
    this.completed = false,
    this.dueLabel,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.creatorName,
    this.userId,
  });

  final String id;
  final String title;
  final String description;
  final TaskBoardStatus status;
  final TaskBoardPriority priority;
  final String estimate;
  final String assignee;
  final double progress;
  final List<String> tags;
  final String? aiSuggestion;
  final bool completed;
  final String? dueLabel;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? creatorName;
  final String? userId;

  String get plainTextDescription => parseDescriptionToPlainText(description);

  String get priorityLabel => switch (priority) {
    TaskBoardPriority.urgent => 'Urgent',
    TaskBoardPriority.high => 'High Priority',
    TaskBoardPriority.medium => 'Med Priority',
    TaskBoardPriority.low => 'Low Priority',
    TaskBoardPriority.done => 'Done',
  };

  Color get priorityColor => switch (priority) {
    TaskBoardPriority.urgent => DashboardColors.error,
    TaskBoardPriority.high => DashboardColors.error,
    TaskBoardPriority.medium => DashboardColors.secondary,
    TaskBoardPriority.low => DashboardColors.tertiary,
    TaskBoardPriority.done => DashboardColors.secondary,
  };
}

class TaskColumnData {
  const TaskColumnData({
    required this.title,
    required this.status,
    required this.tasks,
  });

  final String title;
  final TaskBoardStatus status;
  final List<TaskBoardItem> tasks;
}
