import 'package:to_do_app/features/tasks/domain/entities/task.dart';

class TaskModel {
  const TaskModel({
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
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.tagIds = const [],
    this.assigneeIds = const [],
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
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final List<String> tagIds;
  final List<String> assigneeIds;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
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
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseDate(json['deleted_at']),
      tagIds: (json['tag_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      assigneeIds: (json['assignee_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  static DateTime? _parseDate(dynamic val) =>
      val == null ? null : DateTime.tryParse(val.toString());

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'priority': priority,
        'status': status,
        'ai_generated': aiGenerated,
        'due_date': dueDate?.toUtc().toIso8601String(),
        'reminder_at': reminderAt?.toUtc().toIso8601String(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'parent_task_id': parentTaskId,
        'sort_order': sortOrder,
        'estimated_minutes': estimatedMinutes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'description': description,
        'category_id': categoryId,
        'priority': priority,
        'status': status,
        'ai_generated': aiGenerated,
        'due_date': dueDate?.toUtc().toIso8601String(),
        'reminder_at': reminderAt?.toUtc().toIso8601String(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'parent_task_id': parentTaskId,
        'sort_order': sortOrder,
        'estimated_minutes': estimatedMinutes,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  NexusTask toEntity() => NexusTask(
        id: id,
        userId: userId,
        title: title,
        description: description,
        categoryId: categoryId,
        priority: priority,
        status: status,
        aiGenerated: aiGenerated,
        dueDate: dueDate,
        reminderAt: reminderAt,
        completedAt: completedAt,
        parentTaskId: parentTaskId,
        sortOrder: sortOrder,
        estimatedMinutes: estimatedMinutes,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        tagIds: tagIds,
        assigneeIds: assigneeIds,
      );
}
