import 'package:flutter/material.dart';

class ArchivedTask {
  const ArchivedTask({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.categoryId,
    required this.priority,
    required this.status,
    this.aiGenerated = false,
    this.dueDate,
    this.reminderAt,
    this.completedAt,
    this.parentTaskId,
    this.sortOrder = 0,
    this.estimatedMinutes,
    this.tagIds = const [],
    this.assigneeIds = const [],
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.archivedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? categoryId;
  final String priority;
  final String status;
  final bool aiGenerated;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final DateTime? completedAt;
  final String? parentTaskId;
  final int sortOrder;
  final int? estimatedMinutes;
  final List<String> tagIds;
  final List<String> assigneeIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final DateTime? archivedAt;

  static DateTime? _parseDate(dynamic val) =>
      val == null ? null : DateTime.tryParse(val.toString());

  factory ArchivedTask.fromJson(Map<String, dynamic> json) => ArchivedTask(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        categoryId: json['category_id']?.toString(),
        priority: json['priority']?.toString() ?? 'medium',
        status: json['status']?.toString() ?? 'todo',
        aiGenerated: json['ai_generated'] == true,
        dueDate: _parseDate(json['due_date']),
        reminderAt: _parseDate(json['reminder_at']),
        completedAt: _parseDate(json['completed_at']),
        parentTaskId: json['parent_task_id']?.toString(),
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt(),
        tagIds: (json['tag_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        assigneeIds: (json['assignee_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
        deletedAt: _parseDate(json['deleted_at']),
        archivedAt: _parseDate(json['archived_at']),
      );

  String get estimatedLabel {
    if (estimatedMinutes == null) return '';
    final h = estimatedMinutes! ~/ 60;
    final m = estimatedMinutes! % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Color get priorityColor => switch (priority) {
        'urgent' => const Color(0xFFEF4444),
        'high' => const Color(0xFFF59E0B),
        'medium' => const Color(0xFF3B82F6),
        _ => const Color(0xFF22C55E),
      };

  String get priorityLabel => switch (priority) {
        'urgent' => 'Urgent',
        'high' => 'High',
        'medium' => 'Medium',
        _ => 'Low',
      };

  String get statusLabel => switch (status) {
        'done' => 'Done',
        'in_progress' => 'In Progress',
        'todo' => 'Todo',
        'draft' => 'Draft',
        _ => status,
      };
}
