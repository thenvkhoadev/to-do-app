enum StoryContentType { photo, taskSummary, streak, achievement }

class StoryModel {
  final String id;
  final String authorId;
  final String authorAvatarUrl;
  final String authorName;
  final StoryContentType contentType;
  final String? mediaUrl; // null if auto-generated card
  final Map<String, dynamic>? autoData; // e.g. {taskCount: 5, xp: 250}
  final DateTime createdAt;
  final DateTime expiresAt; // createdAt + 24h
  final List<String> viewedByUserIds;

  StoryModel({
    required this.id,
    required this.authorId,
    required this.authorAvatarUrl,
    required this.authorName,
    required this.contentType,
    this.mediaUrl,
    this.autoData,
    required this.createdAt,
    required this.expiresAt,
    required this.viewedByUserIds,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json, {
    required String authorName,
    required String authorAvatarUrl,
    List<String> viewedByUserIds = const [],
  }) {
    final contentTypeStr = json['content_type'] as String? ?? 'photo';
    StoryContentType contentType;
    switch (contentTypeStr) {
      case 'taskSummary':
        contentType = StoryContentType.taskSummary;
        break;
      case 'streak':
        contentType = StoryContentType.streak;
        break;
      case 'achievement':
        contentType = StoryContentType.achievement;
        break;
      case 'photo':
      default:
        contentType = StoryContentType.photo;
    }

    return StoryModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorAvatarUrl: authorAvatarUrl,
      authorName: authorName,
      contentType: contentType,
      mediaUrl: json['media_url'] as String?,
      autoData: json['auto_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      viewedByUserIds: viewedByUserIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author_id': authorId,
      'content_type': contentType.name,
      'media_url': mediaUrl,
      'auto_data': autoData,
      'created_at': createdAt.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
    };
  }

  StoryModel copyWith({
    String? id,
    String? authorId,
    String? authorAvatarUrl,
    String? authorName,
    StoryContentType? contentType,
    String? mediaUrl,
    Map<String, dynamic>? autoData,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewedByUserIds,
  }) {
    return StoryModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorName: authorName ?? this.authorName,
      contentType: contentType ?? this.contentType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      autoData: autoData ?? this.autoData,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewedByUserIds: viewedByUserIds ?? this.viewedByUserIds,
    );
  }
}

extension StoryStatus on StoryModel {
  bool isViewedBy(String userId) => viewedByUserIds.contains(userId);
}
