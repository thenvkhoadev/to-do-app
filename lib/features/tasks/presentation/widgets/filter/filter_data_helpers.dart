import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

Color parseFilterColor(String? value, [Color fallback = DashboardColors.primary]) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return fallback;
  final hex = raw.replaceFirst('#', '');
  final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

IconData filterIconFromName(String? name) {
  return switch ((name ?? '').toLowerCase()) {
    'work' || 'business' => Icons.work_outline_rounded,
    'person' || 'personal' => Icons.person_outline_rounded,
    'school' || 'learning' || 'study' => Icons.school_outlined,
    'favorite' || 'health' => Icons.favorite_border_rounded,
    'account_balance' || 'finance' => Icons.account_balance_outlined,
    'code' => Icons.code_rounded,
    'home' => Icons.home_outlined,
    _ => Icons.folder_outlined,
  };
}

String timeFilterLabel(TimeFilter filter) => switch (filter) {
  TimeFilter.dueToday => 'Due Today',
  TimeFilter.dueTomorrow => 'Due Tomorrow',
  TimeFilter.dueThisWeek => 'Due This Week',
  TimeFilter.dueNextWeek => 'Due Next Week',
  TimeFilter.overdue => 'Overdue',
  TimeFilter.completedToday => 'Completed Today',
  TimeFilter.completedThisWeek => 'Completed This Week',
  TimeFilter.createdToday => 'Created Today',
  TimeFilter.recentlyUpdated => 'Recently Updated',
};

String smartFilterLabel(SmartFilter filter) => switch (filter) {
  SmartFilter.myTasks => 'My Tasks',
  SmartFilter.dueToday => 'Due Today',
  SmartFilter.overdue => 'Overdue',
  SmartFilter.highPriority => 'High Priority',
  SmartFilter.completed => 'Completed',
  SmartFilter.recentlyAdded => 'Recently Added',
  SmartFilter.aiGenerated => 'AI Generated',
  SmartFilter.hasAttachments => 'Has Attachments',
  SmartFilter.unassigned => 'Unassigned',
  SmartFilter.archived => 'Archived',
};

String subtaskFilterLabel(SubtaskFilter filter) => switch (filter) {
  SubtaskFilter.hasSubtasks => 'Has Subtasks',
  SubtaskFilter.noSubtasks => 'No Subtasks',
  SubtaskFilter.completedSubtasks => 'Completed Subtasks',
  SubtaskFilter.incompleteSubtasks => 'Incomplete Subtasks',
};

bool isSameFilterDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime startOfFilterDay(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime startOfNextFilterWeek(DateTime now) {
  final today = startOfFilterDay(now);
  return today.add(Duration(days: DateTime.daysPerWeek - today.weekday + 1));
}

bool matchesTimeFilter(NexusTask task, TimeFilter filter) {
  final now = DateTime.now();
  final today = startOfFilterDay(now);
  final tomorrow = today.add(const Duration(days: 1));
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final nextWeekStart = weekStart.add(const Duration(days: 7));
  final followingWeekStart = nextWeekStart.add(const Duration(days: 7));
  final due = task.dueDate;
  return switch (filter) {
    TimeFilter.dueToday => due != null && isSameFilterDay(due, today),
    TimeFilter.dueTomorrow => due != null && isSameFilterDay(due, tomorrow),
    TimeFilter.dueThisWeek => due != null && !due.isBefore(weekStart) && due.isBefore(nextWeekStart),
    TimeFilter.dueNextWeek => due != null && !due.isBefore(nextWeekStart) && due.isBefore(followingWeekStart),
    TimeFilter.overdue => due != null && due.isBefore(today) && task.status != 'done',
    TimeFilter.completedToday => task.completedAt != null && isSameFilterDay(task.completedAt!, today),
    TimeFilter.completedThisWeek => task.completedAt != null && !task.completedAt!.isBefore(weekStart) && task.completedAt!.isBefore(nextWeekStart),
    TimeFilter.createdToday => task.createdAt != null && isSameFilterDay(task.createdAt!, today),
    TimeFilter.recentlyUpdated => task.updatedAt != null && task.updatedAt!.isAfter(now.subtract(const Duration(days: 3))),
  };
}
