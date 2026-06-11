import 'package:to_do_app/features/tasks/data/datasource/task_remote_datasource.dart';
import 'package:to_do_app/features/tasks/data/models/task_model.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/domain/repository/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._remoteDataSource);

  final TaskRemoteDataSource _remoteDataSource;

  @override
  Stream<List<NexusTask>> watchTasks(String userId) {
    return _remoteDataSource
        .watchTasks(userId)
        .map((tasks) => tasks.map((t) => t.toEntity()).toList());
  }

  @override
  Future<NexusTask> createTask(NexusTask task) async {
    final model = await _remoteDataSource.createTask(_toModel(task));
    return model.toEntity();
  }

  @override
  Future<void> updateTask(NexusTask task) =>
      _remoteDataSource.updateTask(_toModel(task));

  @override
  Future<void> deleteTask(String id) => _remoteDataSource.deleteTask(id);

  @override
  Future<bool> fetchXpAwarded(String taskId) =>
      _remoteDataSource.fetchXpAwarded(taskId);

  @override
  Future<void> seedSampleTasks(String userId, String? categoryId) =>
      _remoteDataSource.seedSampleTasks(userId, categoryId);

  TaskModel _toModel(NexusTask task) => TaskModel(
        id: task.id,
        userId: task.userId,
        title: task.title,
        description: task.description,
        categoryId: task.categoryId,
        priority: task.priority,
        status: task.status,
        aiGenerated: task.aiGenerated,
        dueDate: task.dueDate,
        reminderAt: task.reminderAt,
        completedAt: task.completedAt,
        xpAwarded: task.xpAwarded,
        parentTaskId: task.parentTaskId,
        sortOrder: task.sortOrder,
        estimatedMinutes: task.estimatedMinutes,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
        deletedAt: task.deletedAt,
        tagIds: task.tagIds,
        assigneeIds: task.assigneeIds,
      );
}
