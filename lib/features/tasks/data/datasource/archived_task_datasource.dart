import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/tasks/data/models/task_model.dart';

class ArchivedTaskDataSource {
  ArchivedTaskDataSource(this._client);

  final SupabaseClient _client;

  Future<void> archiveTask(TaskModel task) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('archived_tasks').insert({
      'id': task.id,
      'user_id': task.userId,
      'title': task.title,
      'description': task.description,
      'category_id': task.categoryId,
      'priority': task.priority,
      'status': task.status,
      'ai_generated': task.aiGenerated,
      'due_date': task.dueDate?.toUtc().toIso8601String(),
      'reminder_at': task.reminderAt?.toUtc().toIso8601String(),
      'completed_at': task.completedAt?.toUtc().toIso8601String(),
      'parent_task_id': task.parentTaskId,
      'sort_order': task.sortOrder,
      'estimated_minutes': task.estimatedMinutes,
      'tag_ids': task.tagIds,
      'assignee_ids': task.assigneeIds,
      'created_at': task.createdAt?.toUtc().toIso8601String(),
      'updated_at': now,
      'archived_at': now,
    });
  }
}
