import 'package:to_do_app/features/tasks/domain/entities/task.dart';

abstract interface class TaskRepository {
  Stream<List<NexusTask>> watchTasks(String userId);
  Future<NexusTask> createTask(NexusTask task);
  Future<void> updateTask(NexusTask task);
  Future<void> deleteTask(String id);
  Future<void> seedSampleTasks(String userId, String? categoryId);
}
