class TaskSubtaskModel {
  const TaskSubtaskModel({
    required this.id,
    required this.taskId,
    required this.title,
    this.isDone = false,
    this.createdAt,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isDone;
  final DateTime? createdAt;

  factory TaskSubtaskModel.fromJson(Map<String, dynamic> json) {
    return TaskSubtaskModel(
      id: json['id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      isDone: json['is_done'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'task_id': taskId,
        'title': title,
        'is_done': isDone,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  TaskSubtaskModel copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isDone,
    DateTime? createdAt,
  }) =>
      TaskSubtaskModel(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
        createdAt: createdAt ?? this.createdAt,
      );
}
