import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

enum TaskBoardStatus { todo, inProgress, completed }

enum TaskBoardPriority { high, medium, low, done }

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

  String get priorityLabel => switch (priority) {
    TaskBoardPriority.high => 'High Priority',
    TaskBoardPriority.medium => 'Med Priority',
    TaskBoardPriority.low => 'Low Priority',
    TaskBoardPriority.done => 'Done',
  };

  Color get priorityColor => switch (priority) {
    TaskBoardPriority.high => DashboardColors.error,
    TaskBoardPriority.medium => DashboardColors.secondary,
    TaskBoardPriority.low => DashboardColors.tertiary,
    TaskBoardPriority.done => DashboardColors.secondary,
  };
}

class TaskColumnData {
  const TaskColumnData({required this.title, required this.status, required this.tasks});

  final String title;
  final TaskBoardStatus status;
  final List<TaskBoardItem> tasks;
}
