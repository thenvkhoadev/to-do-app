class NexusTask {
  const NexusTask({
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
}
