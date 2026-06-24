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
  final Map<String, String> reactorAvatars; // userId -> avatarUrl
  final List<ActivityCommentModel> comments;
  final ActivityPostModel? sharedPost;

  ActivityPostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.authorLevel,
    required this.type,
    this.sharedPost,
    this.referenceId,
    required this.content,
    this.mediaUrl,
    this.metaData,
    required this.createdAt,
    required this.likedByUserIds,
    required this.reactions,
    required this.reactorNames,
    required this.reactorAvatars,
    required this.comments,
  });

  factory ActivityPostModel.fromJson(
    Map<String, dynamic> json, {
    required String authorName,
    required String authorAvatarUrl,
    required int authorLevel,
    Map<String, String> reactions = const {},
    Map<String, String> reactorNames = const {},
    Map<String, String> reactorAvatars = const {},
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
      reactorAvatars: reactorAvatars,
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
    Map<String, String>? reactorAvatars,
    List<ActivityCommentModel>? comments,
    ActivityPostModel? sharedPost,
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
      reactorAvatars: reactorAvatars ?? this.reactorAvatars,
      comments: comments ?? this.comments,
      sharedPost: sharedPost ?? this.sharedPost,
    );
  }

  bool get commentsDisabled => metaData?['comments_disabled'] == true;
}

class ActivityCommentModel {
  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String authorAvatarUrl;
  final int authorLevel;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, String> reactions; // userId -> reactionType (e.g. 'like', 'heart')
  final String? parentCommentId;
  final List<ActivityCommentModel> replies;
  final bool isPinned;
  final String? authorUsername;

  ActivityCommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.authorAvatarUrl,
    this.authorLevel = 1,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.reactions = const {},
    this.parentCommentId,
    this.replies = const [],
    this.isPinned = false,
    this.authorUsername,
  });

  bool get isEdited => updatedAt != null && updatedAt!.difference(createdAt).inSeconds.abs() > 1;

  factory ActivityCommentModel.fromJson(
    Map<String, dynamic> json, {
    required String authorName,
    required String authorAvatarUrl,
    int authorLevel = 1,
    Map<String, String> reactions = const {},
    List<ActivityCommentModel> replies = const [],
    String? authorUsername,
  }) {
    return ActivityCommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      authorLevel: authorLevel,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String).toLocal() : null,
      reactions: reactions,
      parentCommentId: json['parent_comment_id'] as String?,
      replies: replies,
      isPinned: json['is_pinned'] as bool? ?? false,
      authorUsername: authorUsername,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'parent_comment_id': parentCommentId,
      'is_pinned': isPinned,
      'author_level': authorLevel,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }

  ActivityCommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? authorName,
    String? authorAvatarUrl,
    int? authorLevel,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? reactions,
    String? parentCommentId,
    List<ActivityCommentModel>? replies,
    bool? isPinned,
    String? authorUsername,
  }) {
    return ActivityCommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorLevel: authorLevel ?? this.authorLevel,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reactions: reactions ?? this.reactions,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
      isPinned: isPinned ?? this.isPinned,
      authorUsername: authorUsername ?? this.authorUsername,
    );
  }
}
