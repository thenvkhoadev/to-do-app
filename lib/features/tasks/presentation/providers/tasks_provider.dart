import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/tasks/data/datasource/attachment_datasource.dart';
import 'package:to_do_app/features/tasks/data/datasource/category_tag_datasource.dart';
import 'package:to_do_app/features/tasks/data/datasource/task_remote_datasource.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/features/tasks/data/repository/task_repository_impl.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/domain/repository/task_repository.dart';
import 'package:to_do_app/features/tasks/data/models/task_attachment_model.dart';
import 'package:to_do_app/features/tasks/data/models/task_subtask_model.dart';
import 'package:to_do_app/features/tasks/data/datasource/subtask_datasource.dart';

// ── datasource providers ──────────────────────────────────────────────────

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSource(ref.watch(supabaseClientProvider));
});

final categoryDataSourceProvider = Provider<CategoryRemoteDataSource>((ref) {
  return CategoryRemoteDataSource(ref.watch(supabaseClientProvider));
});

final tagDataSourceProvider = Provider<TagRemoteDataSource>((ref) {
  return TagRemoteDataSource(ref.watch(supabaseClientProvider));
});

final attachmentDataSourceProvider =
    Provider<AttachmentRemoteDataSource>((ref) {
  return AttachmentRemoteDataSource(ref.watch(supabaseClientProvider));
});

final subtaskDataSourceProvider = Provider<SubtaskRemoteDataSource>((ref) {
  return SubtaskRemoteDataSource(ref.watch(supabaseClientProvider));
});

// ── repository provider ───────────────────────────────────────────────────

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(ref.watch(taskRemoteDataSourceProvider));
});

// ── stream providers ──────────────────────────────────────────────────────

final userTasksProvider = StreamProvider<List<NexusTask>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(taskRepositoryProvider).watchTasks(user.id);
});

final userCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) {
    debugPrint('userCategoriesProvider: User is null');
    return const Stream.empty();
  }
  debugPrint('userCategoriesProvider: Fetching categories for ${user.id}');
  return ref.watch(categoryDataSourceProvider).watchCategories(user.id).handleError((err) {
    debugPrint('Error in userCategoriesProvider: $err');
  }).map((event) {
    debugPrint('userCategoriesProvider: Loaded ${event.length} categories');
    return event;
  });
});

final userTagsProvider = StreamProvider<List<TagModel>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) {
    debugPrint('userTagsProvider: User is null');
    return const Stream.empty();
  }
  debugPrint('userTagsProvider: Fetching tags for ${user.id}');
  return ref.watch(tagDataSourceProvider).watchTags(user.id).handleError((err) {
    debugPrint('Error in userTagsProvider: $err');
  }).map((event) {
    debugPrint('userTagsProvider: Loaded ${event.length} tags');
    return event;
  });
});

// ── task creation notifier ────────────────────────────────────────────────

class TaskCreationState {
  const TaskCreationState({this.isLoading = false, this.error});
  final bool isLoading;
  final String? error;
  TaskCreationState copyWith({bool? isLoading, String? error}) =>
      TaskCreationState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class TaskCreationNotifier extends StateNotifier<TaskCreationState> {
  TaskCreationNotifier(this._repo, this._categoryDs, this._tagDs, this._attachmentDs, this._subtaskDs)
      : super(const TaskCreationState());

  final TaskRepository _repo;
  final CategoryRemoteDataSource _categoryDs;
  final TagRemoteDataSource _tagDs;
  final AttachmentRemoteDataSource _attachmentDs;
  final SubtaskRemoteDataSource _subtaskDs;

  Future<NexusTask?> createTask({
    required String userId,
    required String title,
    String? description,
    String? categoryId,
    String priority = 'medium',
    String status = 'todo',
    bool aiGenerated = false,
    DateTime? dueDate,
    DateTime? reminderAt,
    int? estimatedMinutes,
    List<String> tagIds = const [],
    List<PlatformFileInfo> attachments = const [],
    List<String> assigneeIds = const [],
    List<String> subtaskTitles = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final task = NexusTask(
        id: '',
        userId: userId,
        title: title,
        description: description,
        categoryId: categoryId,
        priority: priority,
        status: status,
        aiGenerated: aiGenerated,
        dueDate: dueDate,
        reminderAt: reminderAt,
        estimatedMinutes: estimatedMinutes,
      );
      final created = await _repo.createTask(task);
      if (tagIds.isNotEmpty) {
        await _tagDs.setTaskTags(created.id, tagIds);
      }
      if (attachments.isNotEmpty) {
        await _attachmentDs.uploadAttachments(
          taskId: created.id,
          userId: userId,
          files: attachments,
        );
      }
      if (subtaskTitles.isNotEmpty) {
        final subtasks = subtaskTitles
            .map((t) => TaskSubtaskModel(
                  id: '',
                  taskId: created.id,
                  title: t,
                  isDone: false,
                ))
            .toList();
        await _subtaskDs.insertMultipleSubtasks(subtasks);
      }
      if (assigneeIds.isNotEmpty) {
        final supabase = Supabase.instance.client;
        final rows = assigneeIds.map((uid) => {
          'task_id': created.id,
          'user_id': uid,
        }).toList();
        await supabase.from('task_assignees').insert(rows);
      }
      state = state.copyWith(isLoading: false);
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Seeds default categories, tags and sample tasks for a new user.
  Future<void> seedUserData(String userId) async {
    try {
      final categories = await _categoryDs.seedDefaultCategories(userId);
      final tags = await _tagDs.seedDefaultTags(userId);
      final workCategoryId = categories.isNotEmpty ? categories.first.id : null;
      await _repo.seedSampleTasks(userId, workCategoryId);

      // Tag the first sample task with the first two tags if available
      final tasks = await _repo.watchTasks(userId).first;
      if (tasks.isNotEmpty && tags.length >= 2) {
        await _tagDs.setTaskTags(
            tasks.first.id, [tags[0].id, tags[1].id]);
      }
    } catch (_) {
      // seed is best-effort
    }
  }
}

final taskCreationProvider =
    StateNotifierProvider<TaskCreationNotifier, TaskCreationState>((ref) {
  return TaskCreationNotifier(
    ref.watch(taskRepositoryProvider),
    ref.watch(categoryDataSourceProvider),
    ref.watch(tagDataSourceProvider),
    ref.watch(attachmentDataSourceProvider),
    ref.watch(subtaskDataSourceProvider),
  );
});

final taskAttachmentsProvider = FutureProvider.family<List<TaskAttachmentModel>, String>((ref, taskId) {
  return ref.watch(attachmentDataSourceProvider).getAttachments(taskId);
});

final taskSubtasksProvider = FutureProvider.family<List<TaskSubtaskModel>, String>((ref, taskId) {
  return ref.watch(subtaskDataSourceProvider).getSubtasks(taskId);
});

final taskAssigneeIdsProvider = FutureProvider.family<List<String>, String>((ref, taskId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final data = await supabase
      .from('task_assignees')
      .select('user_id')
      .eq('task_id', taskId);
  return (data as List).map((e) => e['user_id'].toString()).toList();
});

final taskTagIdsProvider = FutureProvider.family<List<String>, String>((ref, taskId) async {
  return ref.read(tagDataSourceProvider).getTaskTagIds(taskId);
});


