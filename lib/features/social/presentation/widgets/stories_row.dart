import 'package:flutter/material.dart';
import 'package:to_do_app/features/social/data/models/story_model.dart';
import 'package:to_do_app/features/social/presentation/widgets/story_avatar_ring.dart';

class StoriesRow extends StatelessWidget {
  const StoriesRow({
    super.key,
    required this.groupedStories,
    this.currentUserAvatarUrl,
    this.onCreateStoryTap,
    this.onAuthorStoryTap,
  });

  // Stories grouped by authorId
  final Map<String, List<StoryModel>> groupedStories;
  final String? currentUserAvatarUrl;
  final VoidCallback? onCreateStoryTap;
  final void Function(String authorId, List<StoryModel> stories)? onAuthorStoryTap;

  @override
  Widget build(BuildContext context) {
    final authorIds = groupedStories.keys.toList();

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: authorIds.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return StoryAvatarRing(
              isCreateItem: true,
              currentUserAvatarUrl: currentUserAvatarUrl,
              onTap: onCreateStoryTap,
            );
          }

          final authorId = authorIds[index - 1];
          final authorStories = groupedStories[authorId]!;
          // Use the first story as representational (usually all stories of this author share same author info)
          final representativeStory = authorStories.first;

          // Check if there is any unseen story in this author's list
          // For simplicity, we can determine unseen if current user ID is not in viewedByUserIds.
          // In the mock or provider, we can flag this.
          // Let's pass a custom StoryModel that has the aggregate unseen status
          final hasUnseen = authorStories.any((story) => story.viewedByUserIds.isEmpty);

          // We create a dummy story representing the author
          final displayStory = representativeStory.copyWith(
            viewedByUserIds: hasUnseen ? [] : ['viewed'], // if unseen, viewedByUserIds is empty, else not empty
          );

          return StoryAvatarRing(
            story: displayStory,
            onTap: () {
              if (onAuthorStoryTap != null) {
                onAuthorStoryTap!(authorId, authorStories);
              }
            },
          );
        },
      ),
    );
  }
}
