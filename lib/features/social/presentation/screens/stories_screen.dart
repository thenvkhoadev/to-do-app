import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/features/social/presentation/providers/story_provider.dart';
import 'package:to_do_app/features/social/presentation/widgets/story_avatar_ring.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/widgets/common/skeleton_fade.dart';
import 'package:to_do_app/widgets/common/skeletons/social_stories_skeleton.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart' show DesktopTopbar;
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/features/social/presentation/providers/story_state_providers.dart';
import 'package:to_do_app/core/utils/audio_unmute_helper.dart';

class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(activeStoriesProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currentUserAvatar = profileAsync.valueOrNull?.avatarUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DesktopTopbar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share moments and keep up with your friends.',
                  style: TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                SkeletonFade(
                  isLoading: storiesAsync.isLoading && !storiesAsync.hasValue,
                  skeleton: const SocialStoriesSkeleton(),
                  child: storiesAsync.when(
                    data: (groupedStories) {
                      final authorIds = groupedStories.keys.toList();
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 140,
                          mainAxisExtent: 210,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: authorIds.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return StoryAvatarRing(
                              isCreateItem: true,
                              currentUserAvatarUrl: currentUserAvatar,
                              onTap: () {
                                ref.read(storyCreatorProvider.notifier).startCreating();
                              },
                            );
                          }

                          final authorId = authorIds[index - 1];
                          final authorStories = groupedStories[authorId]!;
                          final representativeStory = authorStories.first;
                          final hasUnseen = authorStories.any((story) => story.viewedByUserIds.isEmpty);

                          final displayStory = representativeStory.copyWith(
                            viewedByUserIds: hasUnseen ? [] : ['viewed'],
                          );

                          return StoryAvatarRing(
                            story: displayStory,
                            onTap: () {
                              resumeWebAudio();
                              ref.read(storyViewerStateProvider.notifier).openViewer(authorId, 0);
                            },
                          );
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const Center(
                      child: Text(
                        'Failed to load stories.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
