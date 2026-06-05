import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/tasks/data/models/task_subtask_model.dart';

class SubtaskRemoteDataSource {
  SubtaskRemoteDataSource(this._client);
  final SupabaseClient _client;

  Future<List<TaskSubtaskModel>> getSubtasks(String taskId) async {
    final response = await _client
        .from('task_subtasks')
        .select()
        .eq('task_id', taskId)
        .order('created_at', ascending: true);
    return (response as List<dynamic>)
        .map((json) => TaskSubtaskModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TaskSubtaskModel> createSubtask(TaskSubtaskModel subtask) async {
    final response = await _client
        .from('task_subtasks')
        .insert(subtask.toJson())
        .select()
        .single();
    return TaskSubtaskModel.fromJson(response);
  }

  Future<void> updateSubtask(String id, Map<String, dynamic> updates) async {
    await _client.from('task_subtasks').update(updates).eq('id', id);
  }

  Future<void> deleteSubtask(String id) async {
    await _client.from('task_subtasks').delete().eq('id', id);
  }

  Future<void> insertMultipleSubtasks(List<TaskSubtaskModel> subtasks) async {
    if (subtasks.isEmpty) return;
    final rows = subtasks.map((e) => e.toJson()).toList();
    await _client.from('task_subtasks').insert(rows);
  }
}
