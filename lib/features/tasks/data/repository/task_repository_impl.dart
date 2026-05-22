import 'package:to_do_app/features/tasks/data/datasource/task_remote_datasource.dart';
import 'package:to_do_app/features/tasks/data/models/task_model.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/domain/repository/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._remoteDataSource);

  final TaskRemoteDataSource _remoteDataSource;

  @override
  Stream<List<NexusTask>> watchTasks(String userId) {
    return _remoteDataSource.watchTasks(userId).map((tasks) => tasks.map((task) => task.toEntity()).toList());
  }

  @override
  Future<void> createTask(NexusTask task) => _remoteDataSource.createTask(_toModel(task));

  @override
  Future<void> updateTask(NexusTask task) => _remoteDataSource.updateTask(_toModel(task));

  @override
  Future<void> deleteTask(String id) => _remoteDataSource.deleteTask(id);

  TaskModel _toModel(NexusTask task) {
    return TaskModel(
      id: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      category: task.category,
      priority: task.priority,
      status: task.status,
      aiGenerated: task.aiGenerated,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
    );
  }
}
