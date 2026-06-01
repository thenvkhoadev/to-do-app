import 'package:to_do_app/features/tasks/domain/entities/task.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.aiGenerated = false,
    this.dueDate,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final String priority;
  final String status;
  final bool aiGenerated;
  final DateTime? dueDate;
  final DateTime? createdAt;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString() ?? 'General',
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'todo',
      aiGenerated: json['ai_generated'] == true,
      dueDate:
          json['due_date'] == null
              ? null
              : DateTime.tryParse(json['due_date'].toString()),
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'ai_generated': aiGenerated,
      'due_date': dueDate?.toUtc().toIso8601String(),
      'created_at': createdAt?.toUtc().toIso8601String(),
    };
  }

  NexusTask toEntity() => NexusTask(
    id: id,
    userId: userId,
    title: title,
    description: description,
    category: category,
    priority: priority,
    status: status,
    aiGenerated: aiGenerated,
    dueDate: dueDate,
    createdAt: createdAt,
  );
}
