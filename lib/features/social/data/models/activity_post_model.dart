class ActivityPostModel {
  final String id;
  final String userId;
  final String authorName;
  final String authorAvatarUrl;
  final int authorLevel;
  final String type; // 'text' | 'task' | 'achievement' | 'poll'
  final String? referenceId;
  final String content;
  final String? mediaUrl;
  final Map<String, dynamic>? metaData;
  final DateTime createdAt;
  final List<String> likedByUserIds;
  final Map<String, String> reactions; // userId -> reactionType (e.g., 'like', 'heart', 'fire', 'clap', 'haha', 'wow', 'sad', 'angry')
  final Map<String, String> reactorNames; // userId -> userName
  final List<ActivityCommentModel> comments;

  ActivityPostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.authorLevel,
    required this.type,
    this.referenceId,
    required this.content,
    this.mediaUrl,
    this.metaData,
    required this.createdAt,
    required this.likedByUserIds,
    required this.reactions,
    required this.reactorNames,
    required this.comments,
  });

  factory ActivityPostModel.fromJson(
    Map<String, dynamic> json, {
    required String authorName,
    required String authorAvatarUrl,
    required int authorLevel,
    Map<String, String> reactions = const {},
    Map<String, String> reactorNames = const {},
    List<ActivityCommentModel> comments = const [],
  }) {
    return ActivityPostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      authorLevel: authorLevel,
      type: json['type'] as String? ?? 'text',
      referenceId: json['reference_id'] as String?,
      content: json['content'] as String? ?? '',
      mediaUrl: json['media_url'] as String?,
      metaData: json['meta_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      likedByUserIds: reactions.keys.toList(),
      reactions: reactions,
      reactorNames: reactorNames,
      comments: comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'reference_id': referenceId,
      'content': content,
      'media_url': mediaUrl,
      'meta_data': metaData,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  ActivityPostModel copyWith({
    String? id,
    String? userId,
    String? authorName,
    String? authorAvatarUrl,
    int? authorLevel,
    String? type,
    String? referenceId,
    String? content,
    String? mediaUrl,
    Map<String, dynamic>? metaData,
    DateTime? createdAt,
    List<String>? likedByUserIds,
    Map<String, String>? reactions,
    Map<String, String>? reactorNames,
    List<ActivityCommentModel>? comments,
  }) {
    return ActivityPostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorLevel: authorLevel ?? this.authorLevel,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metaData: metaData ?? this.metaData,
      createdAt: createdAt ?? this.createdAt,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
      reactions: reactions ?? this.reactions,
      reactorNames: reactorNames ?? this.reactorNames,
      comments: comments ?? this.comments,
    );
  }
}

class ActivityCommentModel {
  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String authorAvatarUrl;
  final String content;
  final DateTime createdAt;
  final Map<String, String> reactions; // userId -> reactionType (e.g. 'like', 'heart')

  ActivityCommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
    this.reactions = const {},
  });

  factory ActivityCommentModel.fromJson(
    Map<String, dynamic> json, {
    required String authorName,
    required String authorAvatarUrl,
    Map<String, String> reactions = const {},
  }) {
    return ActivityCommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      reactions: reactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  ActivityCommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? authorName,
    String? authorAvatarUrl,
    String? content,
    DateTime? createdAt,
    Map<String, String>? reactions,
  }) {
    return ActivityCommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
    );
  }
}
