import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/screens/archived/models/archived_task_model.dart';

class ArchivedTasksRepository {
  ArchivedTasksRepository(this._client);

  final SupabaseClient _client;

  Stream<List<ArchivedTask>> watch(String userId) {
    return _client
        .from('archived_tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((rows) async {
          final tasks = rows.map(ArchivedTask.fromJson).toList();
          if (tasks.isEmpty) return tasks;

          // Fetch assignees from task_assignees join table
          final ids = tasks.map((t) => t.id).toList();
          final assigneeRows = await _client
              .from('task_assignees')
              .select('task_id, user_id')
              .inFilter('task_id', ids);

          final assigneeMap = <String, List<String>>{};
          for (final row in assigneeRows as List) {
            final tid = row['task_id'].toString();
            final uid = row['user_id'].toString();
            assigneeMap.putIfAbsent(tid, () => []).add(uid);
          }

          return tasks.map((t) {
            final ids = assigneeMap[t.id] ?? t.assigneeIds;
            return ArchivedTask(
              id: t.id,
              userId: t.userId,
              title: t.title,
              description: t.description,
              categoryId: t.categoryId,
              priority: t.priority,
              status: t.status,
              aiGenerated: t.aiGenerated,
              dueDate: t.dueDate,
              reminderAt: t.reminderAt,
              completedAt: t.completedAt,
              parentTaskId: t.parentTaskId,
              sortOrder: t.sortOrder,
              estimatedMinutes: t.estimatedMinutes,
              tagIds: t.tagIds,
              assigneeIds: ids,
              createdAt: t.createdAt,
              updatedAt: t.updatedAt,
              deletedAt: t.deletedAt,
              archivedAt: t.archivedAt,
            );
          }).toList();
        });
  }

  Future<void> restore(ArchivedTask task) async {
    // Step 1: Upsert full task back with all original fields
    await _client.from('tasks').upsert({
      'id': task.id,
      'user_id': task.userId,
      'title': task.title,
      'description': task.description,
      'category_id': task.categoryId,
      'priority': task.priority,
      'status': task.status, // Restore original status exactly as archived
      'ai_generated': task.aiGenerated,
      'due_date': task.dueDate?.toUtc().toIso8601String(),
      'reminder_at': task.reminderAt?.toUtc().toIso8601String(),
      'completed_at': task.completedAt?.toUtc().toIso8601String(),
      'parent_task_id': task.parentTaskId,
      'sort_order': task.sortOrder,
      'estimated_minutes': task.estimatedMinutes,
      'created_at': task.createdAt?.toUtc().toIso8601String(),
      'deleted_at': null,
    }, onConflict: 'id');

    // Step 2: Explicit update to guarantee deleted_at is cleared
    await _client
        .from('tasks')
        .update({'deleted_at': null})
        .eq('id', task.id);

    // Step 3: Restore tags
    if (task.tagIds.isNotEmpty) {
      await _client.from('task_tags').delete().eq('task_id', task.id);
      await _client.from('task_tags').insert(
        task.tagIds.map((tagId) => {'task_id': task.id, 'tag_id': tagId}).toList(),
      );
    }

    // Step 4: Restore assignees
    if (task.assigneeIds.isNotEmpty) {
      await _client.from('task_assignees').delete().eq('task_id', task.id);
      await _client.from('task_assignees').insert(
        task.assigneeIds.map((uid) => {'task_id': task.id, 'user_id': uid}).toList(),
      );
    }

    // Step 5: Remove from archived_tasks
    await _client.from('archived_tasks').delete().eq('id', task.id);
  }

  Future<void> deletePermanently(String id) async {
    await _client.from('archived_tasks').delete().eq('id', id);
  }
}

final archivedTasksRepositoryProvider =
    Provider<ArchivedTasksRepository>((ref) {
  return ArchivedTasksRepository(ref.watch(supabaseClientProvider));
});

final archivedTasksProvider =
    StreamProvider.autoDispose<List<ArchivedTask>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(archivedTasksRepositoryProvider).watch(user.id);
});

