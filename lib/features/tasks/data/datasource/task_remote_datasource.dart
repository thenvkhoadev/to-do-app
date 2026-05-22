import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/tasks/data/models/task_model.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource(this._client);

  final SupabaseClient _client;

  Stream<List<TaskModel>> watchTasks(String userId) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((rows) => rows.map(TaskModel.fromJson).toList());
  }

  Future<void> createTask(TaskModel task) async {
    await _client.from('tasks').insert(task.toJson());
  }

  Future<void> updateTask(TaskModel task) async {
    await _client.from('tasks').update(task.toJson()).eq('id', task.id);
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }
}
