import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/core/storage/secure_storage_service.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/social/data/models/activity_post_model.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';

class FeedService {
  FeedService(this._client);
  final SupabaseClient _client;

  // Stream feed posts (Discover / Friends)
  Stream<List<ActivityPostModel>> watchFeedPosts({
    required String currentUserId,
    required List<String> friendIds,
    required bool isDiscover,
  }) {
    return _client
        .from('activity_feed')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((rows) async {
          if (rows.isEmpty) return [];

          // Filter by user ID if it's the Friends feed
          var filteredRows = rows;
          if (!isDiscover) {
            final allowedIds = [currentUserId, ...friendIds];
            filteredRows = rows.where((row) {
              return allowedIds.contains(row['user_id'] as String);
            }).toList();
          }

          if (filteredRows.isEmpty) return [];

          // Identify shared post IDs
          final sharedPostIds = filteredRows
              .where((r) => r['type'] == 'share' && r['reference_id'] != null)
              .map((r) => r['reference_id'] as String)
              .toSet()
              .toList();

          List<Map<String, dynamic>> sharedPostRows = [];
          if (sharedPostIds.isNotEmpty) {
            try {
              sharedPostRows = await _client
                  .from('activity_feed')
                  .select()
                  .inFilter('id', sharedPostIds);
            } catch (e) {
              debugPrint('Error fetching shared posts: $e');
            }
          }

          // Combine main and shared posts to avoid duplicates and gather all relevant IDs
          final allRowsMap = <String, Map<String, dynamic>>{};
          for (final r in filteredRows) {
            allRowsMap[r['id'] as String] = r;
          }
          for (final r in sharedPostRows) {
            allRowsMap[r['id'] as String] = r;
          }
          final allRows = allRowsMap.values.toList();

          // Fetch author profiles
          final authorIds = allRows.map((r) => r['user_id'] as String).toSet().toList();
          final authorsData = await _client
              .from('users')
              .select('id, username, full_name, avatar_url, level')
              .inFilter('id', authorIds);

          final authorsMap = {
            for (final row in authorsData)
              row['id'].toString(): row
          };

          final postIds = allRows.map((r) => r['id'] as String).toList();

          // Fetch likes / reactions
          final likesData = await _client
              .from('activity_post_likes')
              .select('post_id, user_id, reaction_type, users:user_id(username, full_name, avatar_url)')
              .inFilter('post_id', postIds);

          final reactionsMap = <String, Map<String, String>>{};
          final reactorNamesMap = <String, Map<String, String>>{};
          final reactorAvatarsMap = <String, Map<String, String>>{};
          for (final row in likesData) {
            final postId = row['post_id'] as String;
            final userId = row['user_id'] as String;
            final rType = row['reaction_type'] as String? ?? 'like';
            reactionsMap.putIfAbsent(postId, () => {})[userId] = rType;

            final userMap = row['users'] as Map<String, dynamic>? ?? {};
            final reactorName = userMap['full_name']?.toString() ?? userMap['username']?.toString() ?? 'Người dùng';
            reactorNamesMap.putIfAbsent(postId, () => {})[userId] = reactorName;

            final reactorAvatar = userMap['avatar_url']?.toString() ?? '';
            reactorAvatarsMap.putIfAbsent(postId, () => {})[userId] = reactorAvatar;
          }

          // Fetch comments
          final commentsData = await _client
              .from('activity_post_comments')
              .select('id, post_id, user_id, content, created_at, updated_at, parent_comment_id, is_pinned')
              .inFilter('post_id', postIds)
              .order('created_at', ascending: true);

          // Fetch comment reactions (safely catch if table does not exist)
          final commentIds = (commentsData as List).map((c) => c['id'] as String).toList();
          final commentReactionsMap = <String, Map<String, String>>{}; // commentId -> (userId -> reactionType)
          if (commentIds.isNotEmpty) {
            try {
              final commentReactionsData = await _client
                  .from('activity_comment_reactions')
                  .select('comment_id, user_id, reaction_type')
                  .inFilter('comment_id', commentIds);
              for (final row in commentReactionsData) {
                final commentId = row['comment_id'] as String;
                final rUserId = row['user_id'] as String;
                final rType = row['reaction_type'] as String? ?? 'like';
                commentReactionsMap.putIfAbsent(commentId, () => {})[rUserId] = rType;
              }
            } catch (e) {
              debugPrint('Error fetching activity_comment_reactions: $e');
            }
          }

          // Get comment authors profiles
          final commentAuthorIds = (commentsData as List).map((c) => c['user_id'] as String).toSet().toList();
          final commentAuthorsMap = <String, Map<String, dynamic>>{};
          if (commentAuthorIds.isNotEmpty) {
            final cAuthors = await _client
                .from('users')
                .select('id, username, full_name, avatar_url, level')
                .inFilter('id', commentAuthorIds);
            for (final row in cAuthors) {
              commentAuthorsMap[row['id'].toString()] = row;
            }
          }

          // Group comments by postId
          final commentsMap = <String, List<ActivityCommentModel>>{};
          final visualRepliesMap = <String, List<ActivityCommentModel>>{};
          final visualParentIdMap = <String, String>{};
          final authorIdMap = <String, String>{};

          for (final row in commentsData) {
            final postId = row['post_id'] as String;
            final commentId = row['id'] as String;
            final cAuthorId = row['user_id'] as String;
            final cAuthor = commentAuthorsMap[cAuthorId] ?? {};
            final authorName = cAuthor['full_name']?.toString() ?? cAuthor['username']?.toString() ?? 'Người dùng';
            final authorAvatar = cAuthor['avatar_url']?.toString() ?? '';
            final authorLevel = cAuthor['level'] as int? ?? 1;
            final authorUsername = cAuthor['username']?.toString();
            final cReactions = commentReactionsMap[commentId] ?? {};
            final parentId = row['parent_comment_id'] as String?;

            final replies = visualRepliesMap.putIfAbsent(commentId, () => []);

            if (parentId == null) {
              // Main comment
              final comment = ActivityCommentModel.fromJson(
                row,
                authorName: authorName,
                authorAvatarUrl: authorAvatar,
                authorLevel: authorLevel,
                reactions: cReactions,
                replies: replies,
                authorUsername: authorUsername,
              );
              commentsMap.putIfAbsent(postId, () => []).add(comment);
              authorIdMap[commentId] = cAuthorId;
            } else {
              // Reply
              final dbParentId = parentId;
              String visualParentId = dbParentId;

              // Determine visualParentId:
              // If the DB parent is not a main comment (its ID is not in authorIdMap or has a visual parent itself)
              final isDbParentMainComment = authorIdMap.containsKey(dbParentId) && !visualParentIdMap.containsKey(dbParentId);
              if (!isDbParentMainComment) {
                // DB parent is a reply
                final parentAuthorId = authorIdMap[dbParentId];
                if (cAuthorId == parentAuthorId) {
                  // Same author, so visual parent is the visual parent of the DB parent
                  visualParentId = visualParentIdMap[dbParentId] ?? dbParentId;
                } else {
                  // Different author, so visual parent is the DB parent (indented)
                  visualParentId = dbParentId;
                }
              }

              final reply = ActivityCommentModel.fromJson(
                row,
                authorName: authorName,
                authorAvatarUrl: authorAvatar,
                authorLevel: authorLevel,
                reactions: cReactions,
                replies: replies,
                authorUsername: authorUsername,
              );

              visualRepliesMap.putIfAbsent(visualParentId, () => []).add(reply);
              visualParentIdMap[commentId] = visualParentId;
              authorIdMap[commentId] = cAuthorId;
            }
          }

          // Construct shared posts map first
          final Map<String, ActivityPostModel> sharedPostsMap = {};
          for (final row in sharedPostRows) {
            final authorId = row['user_id'] as String;
            final author = authorsMap[authorId] ?? {};
            final authorName = author['full_name']?.toString() ?? author['username']?.toString() ?? 'Người dùng';
            final authorAvatar = author['avatar_url']?.toString() ?? '';
            final authorLevel = author['level'] as int? ?? 1;

            final postId = row['id'] as String;
            final postReactions = reactionsMap[postId] ?? {};
            final postReactorNames = reactorNamesMap[postId] ?? {};
            final postReactorAvatars = reactorAvatarsMap[postId] ?? {};
            final comments = commentsMap[postId] ?? [];

            sharedPostsMap[postId] = ActivityPostModel.fromJson(
              row,
              authorName: authorName,
              authorAvatarUrl: authorAvatar,
              authorLevel: authorLevel,
              reactions: postReactions,
              reactorNames: postReactorNames,
              reactorAvatars: postReactorAvatars,
              comments: comments,
            );
          }

          return filteredRows.map((row) {
            final authorId = row['user_id'] as String;
            final author = authorsMap[authorId] ?? {};
            final authorName = author['full_name']?.toString() ?? author['username']?.toString() ?? 'Người dùng';
            final authorAvatar = author['avatar_url']?.toString() ?? '';
            final authorLevel = author['level'] as int? ?? 1;

            final postId = row['id'] as String;
            final postReactions = reactionsMap[postId] ?? {};
            final postReactorNames = reactorNamesMap[postId] ?? {};
            final postReactorAvatars = reactorAvatarsMap[postId] ?? {};
            final comments = commentsMap[postId] ?? [];

            final sharedPost = row['type'] == 'share' && row['reference_id'] != null
                ? sharedPostsMap[row['reference_id'] as String]
                : null;

            return ActivityPostModel.fromJson(
              row,
              authorName: authorName,
              authorAvatarUrl: authorAvatar,
              authorLevel: authorLevel,
              reactions: postReactions,
              reactorNames: postReactorNames,
              reactorAvatars: postReactorAvatars,
              comments: comments,
            ).copyWith(sharedPost: sharedPost);
          }).toList();
        });
  }

  // Create post
  Future<void> createPost({
    required String userId,
    required String type,
    String? referenceId,
    required String content,
    String? mediaUrl,
    Map<String, dynamic>? metaData,
  }) async {
    await _client.from('activity_feed').insert({
      'user_id': userId,
      'type': type,
      'reference_id': referenceId,
      'content': content,
      'media_url': mediaUrl,
      'meta_data': metaData,
    });
  }

  // Share post
  Future<void> sharePost({
    required String userId,
    required String originalPostId,
    required String content,
  }) async {
    // 1. Create share post
    await createPost(
      userId: userId,
      type: 'share',
      referenceId: originalPostId,
      content: content,
    );

    // 2. Increment shares count in original post
    try {
      final postData = await _client
          .from('activity_feed')
          .select('meta_data')
          .eq('id', originalPostId)
          .single();

      final meta = Map<String, dynamic>.from(postData['meta_data'] as Map? ?? {});
      final currentShares = meta['sharesCount'] as int? ?? 0;
      meta['sharesCount'] = currentShares + 1;

      await _client
          .from('activity_feed')
          .update({'meta_data': meta})
          .eq('id', originalPostId);
    } catch (e) {
      debugPrint('Error incrementing shares count: $e');
    }
  }

  // Toggle like/reaction
  Future<void> toggleLike(String postId, String userId) async {
    await toggleReaction(postId, userId, 'like');
  }

  // Toggle specific reaction type
  Future<void> toggleReaction(String postId, String userId, String reactionType) async {
    final existing = await _client
        .from('activity_post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      if (existing['reaction_type'] == reactionType) {
        // If same reaction, remove it
        await _client
            .from('activity_post_likes')
            .delete()
            .eq('id', existing['id']);
      } else {
        // If different reaction, delete first and then insert to bypass update RLS limitation
        await _client
            .from('activity_post_likes')
            .delete()
            .eq('id', existing['id']);
        await _client.from('activity_post_likes').insert({
          'post_id': postId,
          'user_id': userId,
          'reaction_type': reactionType,
        });
      }
    } else {
      // Add new reaction
      await _client.from('activity_post_likes').insert({
        'post_id': postId,
        'user_id': userId,
        'reaction_type': reactionType,
      });
    }
  }

  // Add comment
  Future<void> addComment(String postId, String userId, String content) async {
    await _client.from('activity_post_comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });
  }

  // Add reply to comment
  Future<void> addReply(String postId, String userId, String parentCommentId, String content) async {
    await _client.from('activity_post_comments').insert({
      'post_id': postId,
      'user_id': userId,
      'parent_comment_id': parentCommentId,
      'content': content,
    });
  }

  // Toggle comment pin
  Future<void> togglePinComment(String commentId, bool pin) async {
    await _client.from('activity_post_comments').update({
      'is_pinned': pin,
    }).eq('id', commentId);
  }

  // Edit comment
  Future<void> editComment(String commentId, String content) async {
    final response = await _client.from('activity_post_comments').update({
      'content': content,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', commentId).select();

    if (response.isEmpty) {
      throw Exception('Không có quyền sửa hoặc bình luận không tồn tại (Lỗi RLS)');
    }
  }

  // Delete comment
  Future<void> deleteComment(String commentId) async {
    await _client.from('activity_post_comments').delete().eq('id', commentId);
  }

  // Toggle specific comment reaction type
  Future<void> toggleCommentReaction(String commentId, String userId, String reactionType) async {
    final existing = await _client
        .from('activity_comment_reactions')
        .select()
        .eq('comment_id', commentId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      if (existing['reaction_type'] == reactionType) {
        // If same reaction, remove it
        await _client
            .from('activity_comment_reactions')
            .delete()
            .eq('id', existing['id']);
      } else {
        // If different reaction, delete first and then insert to bypass update RLS limitation
        await _client
            .from('activity_comment_reactions')
            .delete()
            .eq('id', existing['id']);
        await _client.from('activity_comment_reactions').insert({
          'comment_id': commentId,
          'user_id': userId,
          'reaction_type': reactionType,
        });
      }
    } else {
      // Add new reaction
      await _client.from('activity_comment_reactions').insert({
        'comment_id': commentId,
        'user_id': userId,
        'reaction_type': reactionType,
      });
    }
  }

  // Vote on poll
  Future<void> voteOnPoll(String postId, String userId, String option) async {
    final postData = await _client
        .from('activity_feed')
        .select('meta_data')
        .eq('id', postId)
        .single();

    final meta = Map<String, dynamic>.from(postData['meta_data'] as Map? ?? {});
    final votes = Map<String, dynamic>.from(meta['votes'] as Map? ?? {});

    // Save user vote
    votes[userId] = option;
    meta['votes'] = votes;

    await _client
        .from('activity_feed')
        .update({'meta_data': meta})
        .eq('id', postId);
  }
}

// Providers
final feedServiceProvider = Provider<FeedService>((ref) {
  return FeedService(ref.watch(supabaseClientProvider));
});

// Discover vs Friends toggle provider
final isDiscoverFeedProvider = StateProvider<bool>((ref) => true);

// Stream of feed posts
final feedPostsProvider = StreamProvider<List<ActivityPostModel>>((ref) {
  final currentUser = ref.watch(authControllerProvider).valueOrNull;
  if (currentUser == null) return const Stream.empty();

  final friends = ref.watch(friendsListProvider);
  final friendIds = friends.map((f) => f.id).toList();

  final isDiscover = ref.watch(isDiscoverFeedProvider);
  final service = ref.watch(feedServiceProvider);

  final blockedUserIds = ref.watch(blockedUserIdsProvider);
  final hiddenCommentIds = ref.watch(hiddenCommentIdsProvider);

  // Set up realtime subscriptions for likes, comments, and comment reactions
  final supabase = ref.watch(supabaseClientProvider);

  final likesChannel = supabase.channel('realtime_feed_likes').onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'activity_post_likes',
    callback: (payload) {
      ref.invalidateSelf();
    },
  )..subscribe();

  final commentsChannel = supabase.channel('realtime_feed_comments').onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'activity_post_comments',
    callback: (payload) {
      ref.invalidateSelf();
    },
  )..subscribe();

  final commentReactionsChannel = supabase.channel('realtime_feed_comment_reactions').onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'activity_comment_reactions',
    callback: (payload) {
      ref.invalidateSelf();
    },
  )..subscribe();

  ref.onDispose(() {
    likesChannel.unsubscribe();
    commentsChannel.unsubscribe();
    commentReactionsChannel.unsubscribe();
  });

  return service.watchFeedPosts(
    currentUserId: currentUser.id,
    friendIds: friendIds,
    isDiscover: isDiscover,
  ).map((posts) {
    return posts
        .where((post) => !blockedUserIds.contains(post.userId))
        .map((post) {
          final filteredComments = post.comments
              .where((comment) => !blockedUserIds.contains(comment.userId) && !hiddenCommentIds.contains(comment.id))
              .map((comment) {
                final filteredReplies = comment.replies
                    .where((reply) => !blockedUserIds.contains(reply.userId) && !hiddenCommentIds.contains(reply.id))
                    .toList();
                return comment.copyWith(replies: filteredReplies);
              })
              .toList();
          return post.copyWith(comments: filteredComments);
        })
        .toList();
  });
});

class BlockedUserIdsNotifier extends StateNotifier<Set<String>> {
  BlockedUserIdsNotifier(this._storage) : super({}) {
    _load();
  }

  final SecureStorageService _storage;
  static const _key = 'blocked_user_ids';

  Future<void> _load() async {
    final value = await _storage.read(_key);
    if (value != null && value.isNotEmpty) {
      state = value.split(',').toSet();
    }
  }

  Future<void> blockUser(String userId) async {
    final newState = {...state, userId};
    state = newState;
    await _storage.write(_key, newState.toList().join(','));
  }

  Future<void> unblockUser(String userId) async {
    final newState = {...state}..remove(userId);
    state = newState;
    await _storage.write(_key, newState.toList().join(','));
  }
}

final blockedUserIdsProvider = StateNotifierProvider<BlockedUserIdsNotifier, Set<String>>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return BlockedUserIdsNotifier(storage);
});

final hiddenCommentIdsProvider = StateProvider<Set<String>>((ref) => {});

final commentSortOptionProvider = StateProvider.family<String, String>((ref, postId) => 'newest');
