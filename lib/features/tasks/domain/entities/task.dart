class NexusTask {
  const NexusTask({
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
    this.xpAwarded = false,
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
  final String priority; // low | medium | high | urgent
  final String status;   // todo | in_progress | done | cancelled
  final bool aiGenerated;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final DateTime? completedAt;
  final bool xpAwarded;
  final String? parentTaskId;
  final int sortOrder;
  final int? estimatedMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final List<String> tagIds;
  final List<String> assigneeIds;

  NexusTask copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? categoryId,
    String? priority,
    String? status,
    bool? aiGenerated,
    DateTime? dueDate,
    DateTime? reminderAt,
    DateTime? completedAt,
    bool? xpAwarded,
    String? parentTaskId,
    int? sortOrder,
    int? estimatedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<String>? tagIds,
    List<String>? assigneeIds,
  }) {
    return NexusTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      dueDate: dueDate ?? this.dueDate,
      reminderAt: reminderAt ?? this.reminderAt,
      completedAt: completedAt ?? this.completedAt,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      sortOrder: sortOrder ?? this.sortOrder,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      tagIds: tagIds ?? this.tagIds,
      assigneeIds: assigneeIds ?? this.assigneeIds,
    );
  }
}

