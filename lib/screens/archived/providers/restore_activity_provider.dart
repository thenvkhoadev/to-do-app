import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';

class RestoreEvent {
  RestoreEvent({
    required this.taskId,
    required this.taskTitle,
    required this.userName,
    required this.timestamp,
  });

  final String taskId;
  final String taskTitle;
  final String userName;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'userName': userName,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RestoreEvent.fromJson(Map<String, dynamic> j) => RestoreEvent(
        taskId: j['taskId']?.toString() ?? '',
        taskTitle: j['taskTitle']?.toString() ?? '',
        userName: j['userName']?.toString() ?? '',
        timestamp: DateTime.parse(j['timestamp'].toString()),
      );
}

class RestoreActivityNotifier extends StateNotifier<List<RestoreEvent>> {
  RestoreActivityNotifier(this._ref) : super([]) {
    _load();
  }

  final Ref _ref;
  static const _storageKey = 'archive_restore_activity_log';

  Future<void> _load() async {
    try {
      final storage = _ref.read(secureStorageServiceProvider);
      final raw = await storage.read(_storageKey);
      if (raw != null) {
        final List<dynamic> decoded = json.decode(raw);
        state = decoded
            .map((e) => RestoreEvent.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> _save() async {
    try {
      final storage = _ref.read(secureStorageServiceProvider);
      final encoded = json.encode(state.map((e) => e.toJson()).toList());
      await storage.write(_storageKey, encoded);
    } catch (_) {}
  }

  Future<void> log({
    required String taskId,
    required String taskTitle,
    required String userName,
  }) async {
    final event = RestoreEvent(
      taskId: taskId,
      taskTitle: taskTitle,
      userName: userName,
      timestamp: DateTime.now(),
    );
    state = [event, ...state].take(50).toList();
    await _save();
  }

  Future<void> clear() async {
    state = [];
    await _save();
  }
}

final restoreActivityProvider =
    StateNotifierProvider<RestoreActivityNotifier, List<RestoreEvent>>((ref) {
  return RestoreActivityNotifier(ref);
});
