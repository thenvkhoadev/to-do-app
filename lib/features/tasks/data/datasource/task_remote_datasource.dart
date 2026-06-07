import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/tasks/data/models/task_model.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource(this._client);

  final SupabaseClient _client;

  Stream<List<TaskModel>> watchTasks(String userId) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('sort_order')
        .map((rows) => rows
            .where((r) => r['deleted_at'] == null)
            .map(TaskModel.fromJson)
            .toList());
  }

  Future<TaskModel> createTask(TaskModel task) async {
    final data = await _client
        .from('tasks')
        .insert(task.toInsertJson())
        .select()
        .single();
    return TaskModel.fromJson(data);
  }

  Future<void> updateTask(TaskModel task) async {
    await _client
        .from('tasks')
        .update(task.toUpdateJson())
        .eq('id', task.id);
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> seedSampleTasks(String userId, String? categoryId) async {
    final now = DateTime.now().toUtc();
    final tasks = [
      {
        'user_id': userId,
        'title': 'Design system architecture',
        'description': 'Define core modules and data flow for the new platform.',
        'category_id': categoryId,
        'priority': 'high',
        'status': 'todo',
        'ai_generated': false,
        'due_date': now.add(const Duration(days: 3)).toIso8601String(),
        'estimated_minutes': 240,
        'sort_order': 0,
      },
      {
        'user_id': userId,
        'title': 'Write unit tests for auth module',
        'description': 'Cover sign-in, sign-up, and token refresh flows.',
        'category_id': categoryId,
        'priority': 'medium',
        'status': 'in_progress',
        'ai_generated': false,
        'due_date': now.add(const Duration(days: 5)).toIso8601String(),
        'estimated_minutes': 120,
        'sort_order': 1,
      },
      {
        'user_id': userId,
        'title': 'Review Q3 OKRs',
        'description': 'Align team goals with product roadmap.',
        'category_id': categoryId,
        'priority': 'urgent',
        'status': 'todo',
        'ai_generated': false,
        'due_date': now.add(const Duration(days: 1)).toIso8601String(),
        'estimated_minutes': 60,
        'sort_order': 2,
      },
      {
        'user_id': userId,
        'title': 'Refactor dashboard analytics',
        'description': 'Migrate mock data to live Supabase queries.',
        'category_id': categoryId,
        'priority': 'medium',
        'status': 'todo',
        'ai_generated': true,
        'due_date': now.add(const Duration(days: 7)).toIso8601String(),
        'estimated_minutes': 180,
        'sort_order': 3,
      },
      {
        'user_id': userId,
        'title': 'Deploy staging environment',
        'description': 'Set up CI/CD pipeline for the staging branch.',
        'category_id': categoryId,
        'priority': 'low',
        'status': 'done',
        'ai_generated': false,
        'due_date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'estimated_minutes': 90,
        'sort_order': 4,
      },
    ];
    await _client.from('tasks').insert(tasks);
  }
}
