import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/social/data/models/story_model.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';

// Service class for database interactions
class StoryService {
  StoryService(this._client);
  final SupabaseClient _client;

  // Stream active stories for the current user and their friends
  Stream<List<StoryModel>> watchActiveStories(String currentUserId, List<String> friendIds) {
    final allowedUserIds = [currentUserId, ...friendIds];
    
    return _client
        .from('stories')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((rows) async {
          if (rows.isEmpty) return [];

          // Filter by expiration and allowed user IDs
          final now = DateTime.now().toUtc();
          final filteredRows = rows.where((row) {
            final expiresAt = DateTime.parse(row['expires_at'] as String);
            final authorId = row['author_id'] as String;
            return expiresAt.isAfter(now) && allowedUserIds.contains(authorId);
          }).toList();

          if (filteredRows.isEmpty) return [];

          // Get author profiles
          final authorIds = filteredRows.map((r) => r['author_id'] as String).toSet().toList();
          final authorsData = await _client
              .from('users')
              .select('id, username, full_name, avatar_url')
              .inFilter('id', authorIds);

          final authorsMap = {
            for (final row in authorsData)
              row['id'].toString(): row
          };

          // Get story views
          final storyIds = filteredRows.map((r) => r['id'] as String).toList();
          final viewsData = await _client
              .from('story_views')
              .select('story_id, viewer_id')
              .inFilter('story_id', storyIds);

          // Group views by storyId
          final viewsMap = <String, List<String>>{};
          for (final row in viewsData) {
            final storyId = row['story_id'] as String;
            final viewerId = row['viewer_id'] as String;
            viewsMap.putIfAbsent(storyId, () => []).add(viewerId);
          }

          return filteredRows.map((row) {
            final authorId = row['author_id'] as String;
            final author = authorsMap[authorId] ?? {};
            final authorName = author['full_name']?.toString() ?? author['username']?.toString() ?? 'Người dùng';
            final authorAvatar = author['avatar_url']?.toString() ?? '';
            final storyId = row['id'] as String;
            final viewedBy = viewsMap[storyId] ?? [];

            return StoryModel.fromJson(
              row,
              authorName: authorName,
              authorAvatarUrl: authorAvatar,
              viewedByUserIds: viewedBy,
            );
          }).toList();
        });
  }

  // Mark story as viewed
  Future<void> viewStory(String storyId, String viewerId) async {
    try {
      await _client.from('story_views').insert({
        'story_id': storyId,
        'viewer_id': viewerId,
      });
    } catch (_) {
      // Story might already be viewed (duplicate key error), ignore it
    }
  }

  // Create new story
  Future<StoryModel> createStory({
    required String authorId,
    required StoryContentType contentType,
    String? mediaUrl,
    Map<String, dynamic>? autoData,
  }) async {
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(const Duration(hours: 24));

    final row = await _client.from('stories').insert({
      'author_id': authorId,
      'content_type': contentType.name,
      'media_url': mediaUrl,
      'auto_data': autoData,
      'expires_at': expiresAt.toIso8601String(),
    }).select().single();

    // Fetch author info to return a complete model
    final authorData = await _client
        .from('users')
        .select('username, full_name, avatar_url')
        .eq('id', authorId)
        .single();

    final authorName = authorData['full_name']?.toString() ?? authorData['username']?.toString() ?? 'Bạn';
    final authorAvatar = authorData['avatar_url']?.toString() ?? '';

    return StoryModel.fromJson(
      row,
      authorName: authorName,
      authorAvatarUrl: authorAvatar,
      viewedByUserIds: [],
    );
  }

  // Upload story photo
  Future<String> uploadStoryPhoto(String userId, XFile file) async {
    final fileBytes = await file.readAsBytes();
    final name = 'story_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$name';

    // Try uploading to 'stories' bucket, fall back to 'avatars' if not exists
    try {
      await _client.storage.from('stories').uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );
      return _client.storage.from('stories').getPublicUrl(path);
    } catch (_) {
      // Fallback
      await _client.storage.from('avatars').uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );
      return _client.storage.from('avatars').getPublicUrl(path);
    }
  }

  // Upload story video
  Future<String> uploadStoryVideo(String userId, XFile file) async {
    final fileBytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final name = 'story_video_${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '$userId/$name';

    try {
      await _client.storage.from('stories').uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(upsert: true, contentType: 'video/$ext'),
      );
      return _client.storage.from('stories').getPublicUrl(path);
    } catch (_) {
      // Fallback
      await _client.storage.from('avatars').uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(upsert: true, contentType: 'video/$ext'),
      );
      return _client.storage.from('avatars').getPublicUrl(path);
    }
  }
}

// Providers
final storyServiceProvider = Provider<StoryService>((ref) {
  return StoryService(ref.watch(supabaseClientProvider));
});

// Watch stories and group them by author ID
final activeStoriesProvider = StreamProvider<Map<String, List<StoryModel>>>((ref) {
  final currentUser = ref.watch(authControllerProvider).valueOrNull;
  if (currentUser == null) return const Stream.empty();

  final friends = ref.watch(friendsListProvider);
  final friendIds = friends.map((f) => f.id).toList();

  final service = ref.watch(storyServiceProvider);
  return service.watchActiveStories(currentUser.id, friendIds).map((stories) {
    final grouped = <String, List<StoryModel>>{};

    // Group stories by author ID
    for (final story in stories) {
      grouped.putIfAbsent(story.authorId, () => []).add(story);
    }

    // Sort: unseen stories first, then seen
    // An author's story block is unseen if ANY of the stories are not viewed by current user
    final sortedGrouped = <String, List<StoryModel>>{};
    final unseenList = <List<StoryModel>>[];
    final seenList = <List<StoryModel>>[];

    grouped.forEach((authorId, authorStories) {
      final isUnseen = authorStories.any((s) => !s.viewedByUserIds.contains(currentUser.id));
      if (isUnseen) {
        unseenList.add(authorStories);
      } else {
        seenList.add(authorStories);
      }
    });

    // Reconstruct sorted map (current user's stories are always placed first if present in stories row,
    // but the ListView handles starting '+ Tạo tin'. If current user posted a story, we can sort them nicely)
    for (final authorStories in unseenList) {
      final representative = authorStories.first;
      sortedGrouped[representative.authorId] = authorStories;
    }
    for (final authorStories in seenList) {
      final representative = authorStories.first;
      sortedGrouped[representative.authorId] = authorStories;
    }

    return sortedGrouped;
  });
});
