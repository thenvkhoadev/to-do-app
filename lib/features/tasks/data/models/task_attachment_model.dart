class TaskAttachmentModel {
  const TaskAttachmentModel({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.fileUrl,
    this.createdAt,
  });

  final String id;
  final String taskId;
  final String fileName;
  final String fileUrl;
  final DateTime? createdAt;

  String get mimeType {
    final parts = fileName.split('.');
    if (parts.length < 2) return 'application/octet-stream';
    final ext = parts.last.toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
  }

  factory TaskAttachmentModel.fromJson(Map<String, dynamic> json) {
    return TaskAttachmentModel(
      id: json['id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'task_id': taskId,
        'file_name': fileName,
        'file_url': fileUrl,
        'created_at': createdAt?.toIso8601String(),
      };
}
