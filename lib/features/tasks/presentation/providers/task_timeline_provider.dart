import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';

class TaskActivity {
  final String id;
  final String taskId;
  final String actorName;
  final String action; // 'create', 'start', 'resume', 'pause', 'plan', 'complete', 'create_subtask', 'delete_subtask', 'complete_subtask', 'incomplete_subtask'
  final String detail; // e.g. "created this task", "Subtask 'Verify UI' completed"
  final DateTime timestamp;

  TaskActivity({
    required this.id,
    required this.taskId,
    required this.actorName,
    required this.action,
    required this.detail,
    required this.timestamp,
  });

  factory TaskActivity.fromJson(Map<String, dynamic> json) {
    return TaskActivity(
      id: json['id'].toString(),
      taskId: json['taskId'].toString(),
      actorName: json['actorName']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      timestamp: DateTime.parse(json['timestamp'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'actorName': actorName,
    'action': action,
    'detail': detail,
    'timestamp': timestamp.toIso8601String(),
  };
}

class TaskTimelineNotifier extends StateNotifier<List<TaskActivity>> {
  final Ref ref;
  final String taskId;

  TaskTimelineNotifier(this.ref, this.taskId) : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final jsonStr = await storage.read('task_timeline_$taskId');
      if (jsonStr != null) {
        final List<dynamic> decoded = json.decode(jsonStr);
        state = decoded.map((e) => TaskActivity.fromJson(e)).toList();
        return;
      }
    } catch (_) {}
    state = [];
  }

  Future<void> _save() async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final jsonStr = json.encode(state.map((e) => e.toJson()).toList());
      await storage.write('task_timeline_$taskId', jsonStr);
    } catch (_) {}
  }

  Future<void> seedInitialEvents(TaskBoardItem item, String currentUserName) async {
    // If state is already populated, do nothing
    if (state.isNotEmpty) return;

    final List<TaskActivity> initial = [];
    if (item.createdAt != null) {
      initial.add(TaskActivity(
        id: 'create_${item.id}',
        taskId: taskId,
        actorName: item.creatorName ?? currentUserName,
        action: 'create',
        detail: 'created this task',
        timestamp: item.createdAt!,
      ));
    }

    if (item.completed) {
      initial.add(TaskActivity(
        id: 'complete_${item.id}',
        taskId: taskId,
        actorName: currentUserName,
        action: 'complete',
        detail: 'completed this task',
        timestamp: item.updatedAt ?? DateTime.now(),
      ));
    } else if (item.status == TaskBoardStatus.inProgress) {
      initial.add(TaskActivity(
        id: 'start_${item.id}',
        taskId: taskId,
        actorName: currentUserName,
        action: 'start',
        detail: 'started this task',
        timestamp: item.updatedAt ?? DateTime.now(),
      ));
    }

    state = initial;
    await _save();
  }

  Future<void> addActivity({
    required String actorName,
    required String action,
    required String detail,
    DateTime? timestamp,
  }) async {
    // Ensure loaded
    if (state.isEmpty) {
      await _load();
    }
    final activity = TaskActivity(
      id: const Uuid().v4(),
      taskId: taskId,
      actorName: actorName,
      action: action,
      detail: detail,
      timestamp: timestamp ?? DateTime.now(),
    );
    state = [...state, activity];
    await _save();
  }
}

final taskTimelineProvider = StateNotifierProvider.family<TaskTimelineNotifier, List<TaskActivity>, String>((ref, taskId) {
  return TaskTimelineNotifier(ref, taskId);
});
