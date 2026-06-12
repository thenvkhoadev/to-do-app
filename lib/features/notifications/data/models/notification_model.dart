import 'package:flutter/foundation.dart';

@immutable
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    this.taskId,
    this.xpAmount,
    this.level,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'task_completed', 'task_assigned', 'xp_earned', 'level_up', 'streak', 'ai', 'reminder', 'mention', 'system', 'friend_request'
  final bool read;
  final String? taskId;
  final int? xpAmount;
  final int? level;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      read: json['read'] as bool? ?? false,
      taskId: json['task_id']?.toString(),
      xpAmount: json['xp_amount'] as int?,
      level: json['level'] as int?,
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'read': read,
      'task_id': taskId,
      'xp_amount': xpAmount,
      'level': level,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    bool? read,
    String? taskId,
    int? xpAmount,
    int? level,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      read: read ?? this.read,
      taskId: taskId ?? this.taskId,
      xpAmount: xpAmount ?? this.xpAmount,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
