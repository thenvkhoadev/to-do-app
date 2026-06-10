import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';

class DashboardStats {
  const DashboardStats({
    required this.tasks,
    required this.profile,
    required this.totalTasks,
    required this.completedTasks,
    required this.activeTasks,
    required this.overdueTasks,
    required this.dueTodayTasks,
    required this.highPriorityTasks,
    required this.completedTodayTasks,
    required this.weeklyCompletedCounts,
    required this.upcomingTasks,
    required this.recentTasks,
    required this.nextBestTask,
  });

  final List<NexusTask> tasks;
  final UserProfileModel? profile;
  final int totalTasks;
  final int completedTasks;
  final int activeTasks;
  final int overdueTasks;
  final int dueTodayTasks;
  final int highPriorityTasks;
  final int completedTodayTasks;
  final List<int> weeklyCompletedCounts;
  final List<NexusTask> upcomingTasks;
  final List<NexusTask> recentTasks;
  final NexusTask? nextBestTask;

  int get focusScore => profile?.focusScore ?? completionPercent;
  int get focusHours => profile?.focusHours ?? 0;
  int get streakDays => profile?.streakDays ?? 0;
  int get level => profile?.level ?? 1;
  int get currentXp => profile?.currentXp ?? 0;
  int get totalXp => profile?.totalXp ?? 0;

  int get completionPercent =>
      totalTasks == 0 ? 0 : ((completedTasks / totalTasks) * 100).round();

  double get focusProgress => (focusScore.clamp(0, 100) / 100).toDouble();

  String get headerSummary {
    if (totalTasks == 0) return 'No tasks yet. Create your first task to start tracking progress.';
    return 'You have $activeTasks active task${activeTasks == 1 ? '' : 's'}, '
        '$dueTodayTasks due today, and $completedTodayTasks completed today.';
  }

  String get focusSummary {
    if (totalTasks == 0) return 'Focus score will update as you create and complete tasks.';
    return '$completedTasks of $totalTasks task${totalTasks == 1 ? '' : 's'} completed.';
  }
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final tasks = ref.watch(userTasksProvider).valueOrNull ?? const <NexusTask>[];
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));

  final activeTasks = tasks.where((t) => t.status != 'done').length;
  final completedTasks = tasks.where((t) => t.status == 'done').length;
  final overdueTasks = tasks.where((t) {
    final due = t.dueDate;
    return due != null && due.isBefore(today) && t.status != 'done';
  }).length;
  final dueTodayTasks = tasks.where((t) {
    final due = t.dueDate;
    return due != null && due.year == today.year && due.month == today.month && due.day == today.day;
  }).length;
  final highPriorityTasks = tasks.where((t) => t.priority == 'high' || t.priority == 'urgent').length;
  final completedTodayTasks = tasks.where((t) {
    final completed = t.completedAt;
    return completed != null && completed.year == today.year && completed.month == today.month && completed.day == today.day;
  }).length;

  final weeklyCompletedCounts = List<int>.filled(7, 0);
  for (final task in tasks) {
    final completed = task.completedAt;
    if (completed == null || completed.isBefore(weekStart)) continue;
    final index = completed.weekday - 1;
    if (index >= 0 && index < 7) weeklyCompletedCounts[index]++;
  }

  final upcomingTasks = tasks
      .where((t) => t.dueDate != null && t.status != 'done' && !t.dueDate!.isBefore(today))
      .toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

  final recentTasks = [...tasks]
    ..sort((a, b) {
      final ad = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

  final candidates = tasks.where((t) => t.status != 'done').toList()
    ..sort((a, b) {
      final priority = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
      final pa = priority[a.priority] ?? 4;
      final pb = priority[b.priority] ?? 4;
      final priorityCompare = pa.compareTo(pb);
      if (priorityCompare != 0) return priorityCompare;
      final ad = a.dueDate ?? DateTime(9999);
      final bd = b.dueDate ?? DateTime(9999);
      return ad.compareTo(bd);
    });

  return DashboardStats(
    tasks: tasks,
    profile: profile,
    totalTasks: tasks.length,
    completedTasks: completedTasks,
    activeTasks: activeTasks,
    overdueTasks: overdueTasks,
    dueTodayTasks: dueTodayTasks,
    highPriorityTasks: highPriorityTasks,
    completedTodayTasks: completedTodayTasks,
    weeklyCompletedCounts: weeklyCompletedCounts,
    upcomingTasks: upcomingTasks.take(3).toList(),
    recentTasks: recentTasks.take(3).toList(),
    nextBestTask: candidates.isEmpty ? null : candidates.first,
  );
});
