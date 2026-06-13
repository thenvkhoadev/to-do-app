import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/achievements/domain/achievement.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/xp/presentation/providers/xp_providers.dart';

/// Provider for streaming the count of comments written by the current user.
final userCommentsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return Stream.value(0);
  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('comments')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((rows) => rows.length);
});

/// Provider for streaming the count of attachments added to the user's tasks.
final userAttachmentsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return Stream.value(0);
  final tasks = ref.watch(userTasksProvider).valueOrNull ?? const <NexusTask>[];
  if (tasks.isEmpty) return Stream.value(0);
  final taskIds = tasks.map((t) => t.id).toSet();
  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('task_attachments')
      .stream(primaryKey: ['id'])
      .map((rows) => rows.where((row) => taskIds.contains(row['task_id'].toString())).length);
});

/// Provider for streaming the count of completed checklist subtasks under the user's tasks.
final userCompletedSubtasksCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return Stream.value(0);
  final tasks = ref.watch(userTasksProvider).valueOrNull ?? const <NexusTask>[];
  if (tasks.isEmpty) return Stream.value(0);
  final taskIds = tasks.map((t) => t.id).toSet();
  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('task_subtasks')
      .stream(primaryKey: ['id'])
      .map((rows) => rows.where((row) => row['is_done'] == true && taskIds.contains(row['task_id'].toString())).length);
});

/// Provider for streaming the count of archived tasks for the user.
final userArchivedTasksCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return Stream.value(0);
  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('archived_tasks')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((rows) => rows.length);
});

/// Provider for raw achievements list, dynamically derived from the profile and categories.
final achievementsProvider = Provider<List<Achievement>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final categories = ref.watch(userCategoriesProvider).valueOrNull ?? const [];
  final tasks = ref.watch(userTasksProvider).valueOrNull ?? const <NexusTask>[];

  if (profile == null) return const [];

  final completedTasks = profile.completedTasks;
  final streakDays = profile.streakCount;
  final completedTasksList = tasks.where((t) => t.status == 'done').toList();
  final realFocusMinutes = completedTasksList.fold<int>(0, (sum, t) => sum + (t.estimatedMinutes ?? 25));
  final realFocusSessions = completedTasksList.length;
  final focusHours = (realFocusMinutes / 60).round();
  final totalXp = profile.totalXp;
  final level = profile.level;
  final projectsCount = categories.length;

  final aiTasksCompleted = tasks.where((t) => t.status == 'done' && t.aiGenerated).length;
  final collabTasksCompleted = tasks.where((t) => t.status == 'done' && t.assigneeIds.isNotEmpty).length;

  final baseUnlockDate = profile.createdAt ?? DateTime.now().subtract(const Duration(days: 7));

  // Watch real counts providers
  final commentsCount = ref.watch(userCommentsCountProvider).valueOrNull ?? 0;
  final attachmentsCount = ref.watch(userAttachmentsCountProvider).valueOrNull ?? 0;
  final subtasksCompletedFromTable = ref.watch(userCompletedSubtasksCountProvider).valueOrNull ?? 0;
  final archivedTasksCount = ref.watch(userArchivedTasksCountProvider).valueOrNull ?? 0;
  final xpLogs = ref.watch(xpLogsProvider).valueOrNull ?? const [];
  final tagsList = ref.watch(userTagsProvider).valueOrNull ?? const [];

  final list = <Achievement>[];

  // Helper metadata
  final typeMetadata = {
    'tasks_completed': ('Task Completed', 'Complete {target} tasks', Icons.shield_rounded, 'tasks_completed', 'Tasks'),
    'tasks_created': ('Task Creator', 'Create {target} tasks', Icons.assignment_rounded, 'tasks_created', 'Tasks'),
    'subtasks_completed': ('Subtask Completer', 'Complete {target} subtasks', Icons.checklist_rounded, 'subtasks_completed', 'Tasks'),
    'total_xp': ('XP Collector', 'Earn {target} lifetime XP', Icons.bolt_rounded, 'total_xp', 'XP'),
    'level': ('Level Progression', 'Reach level {target}', Icons.rocket_rounded, 'level', 'XP'),
    'rank_reached': ('Rank Reached', 'Reach tier {target}', Icons.workspace_premium_rounded, 'rank_reached', 'XP'),
    'streak_count': ('Streak Builder', 'Keep a {target}-day completion streak', Icons.local_fire_department_rounded, 'streak_count', 'Streak'),
    'longest_streak': ('Longest Streak', 'Reach a personal best {target}-day streak', Icons.whatshot_rounded, 'longest_streak', 'Streak'),
    'projects_created': ('Project Manager', 'Organize tasks across {target} projects', Icons.folder_rounded, 'projects_created', 'Projects'),
    'focus_sessions': ('Deep Focus Sessions', 'Log {target} focus sessions', Icons.psychology_rounded, 'focus_sessions', 'Focus'),
    'focus_minutes': ('Focus Minutes', 'Log {target} focus minutes', Icons.hourglass_bottom_rounded, 'focus_minutes', 'Focus'),
    'comments_created': ('Comment Contributor', 'Write {target} comments', Icons.chat_bubble_rounded, 'comments_created', 'Social'),
    'assigned_tasks': ('Team Contributor', 'Complete {target} assigned tasks', Icons.people_rounded, 'assigned_tasks', 'Social'),
    'ai_tasks_created': ('AI Tasks Creator', 'Create {target} tasks with AI assistant', Icons.memory_rounded, 'ai_tasks_created', 'AI'),
    'completion_rate': ('Task Completion Rate', 'Maintain a {target}% completion rate', Icons.track_changes_rounded, 'completion_rate', 'Special'),
    'perfect_tasks': ('Perfect Execution', 'Complete {target} tasks without delay', Icons.diamond_rounded, 'perfect_tasks', 'Special'),
    'night_task': ('Night Owl Tasks', 'Complete {target} tasks at night', Icons.nights_stay_rounded, 'night_task', 'Special'),
    'early_task': ('Early Bird Tasks', 'Complete {target} tasks in the morning', Icons.wb_sunny_rounded, 'early_task', 'Special'),
    'fast_completion': ('Speed Demon', 'Complete {target} tasks under 5 minutes', Icons.speed_rounded, 'fast_completion', 'Special'),
    'categories_created': ('Category Organizer', 'Create {target} task categories', Icons.grid_view_rounded, 'categories_created', 'Projects'),
    'tags_created': ('Tag Labeler', 'Create {target} unique tags', Icons.local_offer_rounded, 'tags_created', 'Projects'),
    'archived_tasks': ('Task Archivist', 'Archive {target} completed tasks', Icons.archive_rounded, 'archived_tasks', 'Special'),
    'restored_tasks': ('Task Restorer', 'Restore {target} tasks from archive', Icons.restore_rounded, 'restored_tasks', 'Special'),
    'high_priority_tasks': ('High Priority Solver', 'Solve {target} high priority tasks', Icons.flag_rounded, 'high_priority_tasks', 'Special'),
    'urgent_tasks': ('Urgent Resolver', 'Solve {target} urgent tasks', Icons.notification_important_rounded, 'urgent_tasks', 'Special'),
    'due_date_completed': ('On-time Finisher', 'Complete {target} tasks before due date', Icons.calendar_today_rounded, 'due_date_completed', 'Special'),
    'overdue_avoided': ('Procrastination Shield', 'Avoid overdue on {target} tasks', Icons.security_rounded, 'overdue_avoided', 'Special'),
    'attachments_added': ('Asset Manager', 'Add {target} task attachments', Icons.attach_file_rounded, 'attachments_added', 'Special'),
    'special_milestone': ('Milestone Achiever', 'Unlock {target} special milestones', Icons.emoji_events_rounded, 'special_milestone', 'Special'),
  };

  int getTargetValue(String type, AchievementRarity rarity) {
    final index = rarity.index;
    switch (type) {
      case 'tasks_completed':
        return [10, 25, 50, 100, 200, 400, 800, 1500, 3000, 5000, 10000, 20000][index];
      case 'tasks_created':
        return [15, 35, 75, 150, 300, 600, 1200, 2500, 5000, 8000, 15000, 30000][index];
      case 'subtasks_completed':
        return [5, 15, 30, 60, 120, 250, 500, 1000, 2000, 4000, 8000, 15000][index];
      case 'total_xp':
        return [500, 1500, 3500, 8000, 18000, 40000, 90000, 200000, 450000, 1000000, 2500000, 6000000][index];
      case 'level':
        return [3, 5, 10, 15, 25, 35, 50, 70, 90, 110, 130, 150][index];
      case 'rank_reached':
        return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12][index];
      case 'streak_count':
        return [3, 5, 7, 14, 21, 30, 45, 60, 90, 120, 180, 365][index];
      case 'longest_streak':
        return [5, 7, 10, 21, 30, 45, 60, 90, 120, 180, 240, 365][index];
      case 'projects_created':
      case 'categories_created':
        return [2, 3, 5, 7, 10, 12, 15, 18, 22, 26, 30, 40][index];
      case 'focus_sessions':
        return [3, 8, 20, 40, 80, 150, 250, 400, 650, 1000, 1500, 2500][index];
      case 'focus_minutes':
        return [60, 180, 480, 1200, 2400, 5000, 10000, 20000, 40000, 75000, 120000, 200000][index];
      case 'comments_created':
        return [2, 5, 15, 35, 75, 150, 300, 600, 1200, 2500, 5000, 10000][index];
      case 'assigned_tasks':
        return [2, 4, 10, 20, 40, 80, 160, 300, 600, 1200, 2400, 5000][index];
      case 'ai_tasks_created':
        return [1, 3, 7, 15, 30, 60, 120, 250, 500, 1000, 2000, 4000][index];
      case 'completion_rate':
        return [10, 20, 35, 50, 65, 75, 80, 85, 90, 95, 98, 100][index];
      case 'perfect_tasks':
        return [1, 3, 7, 15, 30, 60, 120, 250, 500, 1000, 2000, 4000][index];
      case 'night_task':
        return [1, 3, 7, 15, 30, 60, 120, 250, 500, 1000, 2000, 4000][index];
      case 'early_task':
        return [1, 3, 7, 15, 30, 60, 120, 250, 500, 1000, 2000, 4000][index];
      case 'fast_completion':
        return [1, 3, 7, 15, 30, 60, 120, 250, 500, 1000, 2000, 4000][index];
      case 'tags_created':
        return [2, 5, 10, 20, 35, 60, 100, 180, 300, 500, 800, 1500][index];
      case 'archived_tasks':
        return [2, 5, 10, 20, 35, 60, 100, 180, 300, 500, 800, 1500][index];
      case 'restored_tasks':
        return [1, 2, 5, 10, 20, 40, 80, 150, 300, 500, 800, 1500][index];
      case 'high_priority_tasks':
        return [2, 5, 12, 25, 50, 100, 200, 400, 800, 1500, 3000, 6000][index];
      case 'urgent_tasks':
        return [1, 3, 7, 15, 30, 60, 120, 250, 500, 1000, 2000, 4000][index];
      case 'due_date_completed':
        return [2, 5, 12, 25, 50, 100, 200, 400, 800, 1500, 3000, 6000][index];
      case 'overdue_avoided':
        return [2, 5, 10, 20, 35, 60, 100, 180, 300, 500, 800, 1500][index];
      case 'attachments_added':
        return [2, 5, 10, 20, 35, 60, 100, 180, 300, 500, 800, 1500][index];
      case 'special_milestone':
        return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12][index];
      default:
        return (index + 1) * 10;
    }
  }

  int getCurrentValue(String type, int specialMilestoneCount) {
    switch (type) {
      case 'tasks_completed':
        return completedTasks;
      case 'tasks_created':
        return tasks.length;
      case 'subtasks_completed':
        final nestedSubtasks = tasks.where((t) => t.status == 'done' && t.parentTaskId != null).length;
        return subtasksCompletedFromTable + nestedSubtasks;
      case 'total_xp':
        return totalXp;
      case 'level':
        return level;
      case 'rank_reached':
        return (level / 5).floor().clamp(1, 12);
      case 'streak_count':
        return streakDays;
      case 'longest_streak':
        return profile.longestStreak;
      case 'projects_created':
      case 'categories_created':
        return projectsCount;
      case 'focus_sessions':
        return realFocusSessions;
      case 'focus_minutes':
        return realFocusMinutes;
      case 'comments_created':
        return commentsCount;
      case 'assigned_tasks':
        return collabTasksCompleted;
      case 'ai_tasks_created':
        return aiTasksCompleted;
      case 'completion_rate':
        if (tasks.isEmpty) return 0;
        final done = tasks.where((t) => t.status == 'done').length;
        return ((done / tasks.length) * 100).round();
      case 'perfect_tasks':
        return tasks.where((t) => t.status == 'done' && (t.dueDate == null || t.completedAt == null || !t.completedAt!.isAfter(t.dueDate!))).length;
      case 'night_task':
        return tasks.where((t) => t.status == 'done' && t.completedAt != null && (t.completedAt!.hour >= 23 || t.completedAt!.hour < 5)).length;
      case 'early_task':
        return tasks.where((t) => t.status == 'done' && t.completedAt != null && (t.completedAt!.hour >= 5 && t.completedAt!.hour < 9)).length;
      case 'fast_completion':
        return tasks.where((t) => t.status == 'done' && t.completedAt != null && t.createdAt != null && t.completedAt!.difference(t.createdAt!).inMinutes < 5).length;
      case 'tags_created':
        return tagsList.length;
      case 'archived_tasks':
        return archivedTasksCount;
      case 'restored_tasks':
        return xpLogs.where((log) => log.reason == 'Task Restored').length;
      case 'high_priority_tasks':
        return tasks.where((t) => t.status == 'done' && t.priority == 'high').length;
      case 'urgent_tasks':
        return tasks.where((t) => t.status == 'done' && t.priority == 'urgent').length;
      case 'due_date_completed':
        return tasks.where((t) => t.status == 'done' && t.completedAt != null && t.dueDate != null && !t.completedAt!.isAfter(t.dueDate!)).length;
      case 'overdue_avoided':
        return tasks.where((t) => t.status == 'done' && t.completedAt != null && t.dueDate != null && !t.completedAt!.isAfter(t.dueDate!)).length;
      case 'attachments_added':
        return attachmentsCount;
      case 'special_milestone':
        return specialMilestoneCount;
      default:
        return 0;
    }
  }

  // First pass: Build all achievements except special_milestone
  int specialMilestoneCount = 0;
  for (final entry in typeMetadata.entries) {
    final type = entry.key;
    if (type == 'special_milestone') continue;
    final meta = entry.value;
    for (final rarity in AchievementRarity.values) {
      final target = getTargetValue(type, rarity);
      final current = getCurrentValue(type, 0);
      final isUnlocked = current >= target;
      if (isUnlocked) {
        specialMilestoneCount++;
      }

      list.add(
        Achievement(
          id: '${type}_${rarity.name}',
          name: '${meta.$1} (${rarity.label})',
          description: meta.$2.replaceAll('{target}', target.toString()),
          icon: meta.$3,
          svgName: meta.$4,
          category: meta.$5,
          rarity: rarity,
          xpReward: 200 + rarity.index * 100,
          currentValue: current,
          targetValue: target,
          isUnlocked: isUnlocked,
          unlockedAt: isUnlocked ? baseUnlockDate.add(Duration(hours: rarity.index * 6)) : null,
        ),
      );
    }
  }

  // Second pass: Build special_milestone achievements using final milestone count
  final milestoneMeta = typeMetadata['special_milestone']!;
  for (final rarity in AchievementRarity.values) {
    final target = getTargetValue('special_milestone', rarity);
    final current = getCurrentValue('special_milestone', specialMilestoneCount);
    final isUnlocked = current >= target;

    list.add(
      Achievement(
        id: 'special_milestone_${rarity.name}',
        name: '${milestoneMeta.$1} (${rarity.label})',
        description: milestoneMeta.$2.replaceAll('{target}', target.toString()),
        icon: milestoneMeta.$3,
        svgName: milestoneMeta.$4,
        category: milestoneMeta.$5,
        rarity: rarity,
        xpReward: 200 + rarity.index * 100,
        currentValue: current,
        targetValue: target,
        isUnlocked: isUnlocked,
        unlockedAt: isUnlocked ? baseUnlockDate.add(Duration(hours: rarity.index * 6)) : null,
      ),
    );
  }

  return list;
});

/// UI filters state model.
class AchievementsFilterState {
  const AchievementsFilterState({
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.selectedStatus = 'All', // 'All', 'Unlocked', 'Locked', 'Rare'
  });

  final String searchQuery;
  final String selectedCategory;
  final String selectedStatus;

  AchievementsFilterState copyWith({
    String? searchQuery,
    String? selectedCategory,
    String? selectedStatus,
  }) {
    return AchievementsFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

/// Provider to handle state of current filters.
final achievementsFilterProvider = StateProvider<AchievementsFilterState>((ref) {
  return const AchievementsFilterState();
});

/// Provider that returns achievements matching the active filters.
final filteredAchievementsProvider = Provider<List<Achievement>>((ref) {
  final rawList = ref.watch(achievementsProvider);
  final filters = ref.watch(achievementsFilterProvider);

  ref.listen(achievementsFilterProvider, (prev, next) {
    ref.read(achievementsPageProvider.notifier).state = 1;
  });

  return rawList.where((achievement) {
    // Search query filter.
    final nameLower = achievement.name.toLowerCase();
    final descLower = achievement.description.toLowerCase();
    final queryLower = filters.searchQuery.toLowerCase();
    if (filters.searchQuery.isNotEmpty &&
        !nameLower.contains(queryLower) &&
        !descLower.contains(queryLower)) {
      return false;
    }

    // Category filter.
    if (filters.selectedCategory != 'All' &&
        achievement.category != filters.selectedCategory) {
      return false;
    }

    // Status filter.
    if (filters.selectedStatus == 'Unlocked' && !achievement.isUnlocked) {
      return false;
    }
    if (filters.selectedStatus == 'Locked' && achievement.isUnlocked) {
      return false;
    }
    if (filters.selectedStatus == 'Rare' &&
        achievement.rarity.index < AchievementRarity.diamond.index) {
      return false;
    }

    return true;
  }).toList();
});

/// Class representing computed statistics for achievements.
class AchievementsStats {
  const AchievementsStats({
    required this.totalUnlocked,
    required this.totalCount,
    required this.rareUnlockedCount,
    required this.highestRarityUnlocked,
  });

  final int totalUnlocked;
  final int totalCount;
  final int rareUnlockedCount;
  final AchievementRarity? highestRarityUnlocked;

  int get unlockPercentage => totalCount == 0 ? 0 : ((totalUnlocked / totalCount) * 100).round();
}

/// Provider to derive statistics from the raw achievements list.
final achievementsStatsProvider = Provider<AchievementsStats>((ref) {
  final achievements = ref.watch(achievementsProvider);
  final unlocked = achievements.where((a) => a.isUnlocked).toList();

  int rareCount = unlocked
      .where((a) => a.rarity.index >= AchievementRarity.diamond.index)
      .length;

  AchievementRarity? highestRarity;
  for (final achievement in unlocked) {
    if (highestRarity == null || achievement.rarity.index > highestRarity.index) {
      highestRarity = achievement.rarity;
    }
  }

  return AchievementsStats(
    totalUnlocked: unlocked.length,
    totalCount: achievements.length,
    rareUnlockedCount: rareCount,
    highestRarityUnlocked: highestRarity,
  );
});

/// Provider for recently unlocked achievements.
final recentlyUnlockedAchievementsProvider = Provider<List<Achievement>>((ref) {
  final achievements = ref.watch(achievementsProvider);
  final unlocked = achievements.where((a) => a.isUnlocked && a.unlockedAt != null).toList();

  // Sort by unlock date descending, then by rarity descending.
  unlocked.sort((a, b) {
    final dateCompare = b.unlockedAt!.compareTo(a.unlockedAt!);
    if (dateCompare != 0) return dateCompare;
    return b.rarity.index.compareTo(a.rarity.index);
  });

  return unlocked.toList();
});

/// Provider for locked achievements (closest to completion first).
final lockedAchievementsProvider = Provider<List<Achievement>>((ref) {
  final achievements = ref.watch(achievementsProvider);
  final locked = achievements.where((a) => !a.isUnlocked).toList();

  // Sort by progress descending, so achievements closest to completion come first.
  locked.sort((a, b) => b.progress.compareTo(a.progress));

  return locked;
});

/// Provider for active page of achievements list.
final achievementsPageProvider = StateProvider<int>((ref) => 1);

/// Number of items to display per page.
final achievementsItemsPerPageProvider = Provider<int>((ref) => 16);

/// Provider for paginated achievements.
final paginatedAchievementsProvider = Provider<List<Achievement>>((ref) {
  final filtered = ref.watch(filteredAchievementsProvider);
  final page = ref.watch(achievementsPageProvider);
  final limit = ref.watch(achievementsItemsPerPageProvider);

  final startIndex = (page - 1) * limit;
  if (startIndex >= filtered.length) return const [];

  final endIndex = startIndex + limit;
  return filtered.sublist(startIndex, endIndex.clamp(0, filtered.length));
});

/// Provider for total page count of achievements.
final achievementsTotalPagesProvider = Provider<int>((ref) {
  final filtered = ref.watch(filteredAchievementsProvider);
  final limit = ref.watch(achievementsItemsPerPageProvider);
  if (filtered.isEmpty) return 1;
  return (filtered.length / limit).ceil();
});

