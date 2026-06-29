import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/story_state_providers.dart';
import 'package:to_do_app/features/social/presentation/widgets/stories_row.dart';
import 'package:to_do_app/features/social/presentation/widgets/story_viewer.dart';
import 'package:to_do_app/features/social/presentation/widgets/story_creator_view.dart';
import 'package:to_do_app/features/social/presentation/widgets/post_composer_card.dart';
import 'package:to_do_app/features/social/presentation/widgets/activity_post_card.dart';
import 'package:to_do_app/features/social/presentation/widgets/empty_feed_state.dart';
import 'package:to_do_app/features/social/presentation/widgets/feed_right_sidebar.dart';
import 'package:to_do_app/features/social/presentation/providers/feed_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/story_provider.dart';
import 'package:to_do_app/widgets/common/skeleton_fade.dart';
import 'package:to_do_app/widgets/common/skeletons/social_stories_skeleton.dart';
import 'package:to_do_app/widgets/common/skeletons/social_post_skeleton.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';
import 'package:to_do_app/core/utils/audio_unmute_helper.dart';


class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key, this.onFindFriends});

  final VoidCallback? onFindFriends;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatorState = ref.watch(storyCreatorProvider);
    final viewerState = ref.watch(storyViewerStateProvider);

    final isViewing = viewerState != null && viewerState.activeAuthorId != null;
    final isCreating = creatorState != null;

    // Listen for creator state on mobile to push a fullscreen route
    ref.listen<StoryCreatorState?>(storyCreatorProvider, (previous, next) {
      final isDesktop = MediaQuery.sizeOf(context).width >= 1200;
      if (!isDesktop) {
        if (next != null && previous == null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Consumer(
                builder: (context, ref, child) {
                  final creatorState = ref.watch(storyCreatorProvider);
                  
                  bool hasChanges = false;
                  if (creatorState != null && creatorState.screenType != CreatorScreenType.select) {
                    if (creatorState.screenType == CreatorScreenType.text) {
                      hasChanges = creatorState.text.trim().isNotEmpty || creatorState.musicOverlay != null;
                    } else if (creatorState.screenType == CreatorScreenType.image) {
                      hasChanges = creatorState.imageFile != null || creatorState.textOverlays.isNotEmpty || creatorState.musicOverlay != null;
                    } else if (creatorState.screenType == CreatorScreenType.video) {
                      hasChanges = creatorState.videoFile != null || creatorState.textOverlays.isNotEmpty || creatorState.musicOverlay != null;
                    }
                  }

                  return PopScope(
                    canPop: !hasChanges,
                    onPopInvokedWithResult: (didPop, result) async {
                      if (didPop) return;

                      final leave = await showDialog<bool>(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: const Color(0xFF1E1C30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                            child: Container(
                              width: 400,
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Rời khỏi trang?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: .08),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white70, size: 16),
                                          onPressed: () => Navigator.of(context).pop(false),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  const Text(
                                    'Bạn đang chỉnh sửa tin. Bạn có muốn rời đi và hủy tất cả thay đổi không?',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15.0,
                                    ),
                                  ),
                                  const SizedBox(height: 24.0),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text(
                                          'Ở lại Trang',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16.0),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1877F2),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                          elevation: 0,
                                        ),
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text(
                                          'Rời khỏi Trang',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      if (leave == true) {
                        ref.read(storyCreatorProvider.notifier).reset();
                        Navigator.of(context).pop();
                      }
                    },
                    child: Scaffold(
                      body: StoryCreatorView(
                        onClose: () {
                          ref.read(storyCreatorProvider.notifier).reset();
                          Navigator.of(context).maybePop();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    });

    // Listen for viewer state on mobile to push a fullscreen route
    ref.listen<StoryViewerState?>(storyViewerStateProvider, (previous, next) {
      final isDesktop = MediaQuery.sizeOf(context).width >= 1200;
      if (!isDesktop) {
        if (next != null && previous == null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PopScope(
                canPop: true,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) {
                    ref.read(storyViewerStateProvider.notifier).closeViewer();
                  }
                },
                child: Scaffold(
                  backgroundColor: Colors.black,
                  body: StoryViewer(
                    onClose: () {
                      ref.read(storyViewerStateProvider.notifier).closeViewer();
                      Navigator.of(context).maybePop();
                    },
                  ),
                ),
              ),
            ),
          );
        }
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isDesktop = screenWidth >= 1200;

        Widget content;
        if (isViewing && isDesktop) {
          content = StoryViewer(
            onClose: () {
              ref.read(storyViewerStateProvider.notifier).closeViewer();
            },
          );
        } else if (isCreating && isDesktop) {
          content = StoryCreatorView(
            onClose: () {
              ref.read(storyCreatorProvider.notifier).reset();
            },
          );
        } else {
          // Normal Feed Layout
          content = isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Center Content Scroll Area
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const PostComposerCard(),
                                const SizedBox(height: 16),
                                _buildStoriesSection(context, ref),
                                const SizedBox(height: 16),
                                _buildFeedToggle(context, ref),
                                const SizedBox(height: 16),
                                _buildPostsList(context, ref),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Right Sidebar
                    if (screenWidth >= 1280)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: FeedRightSidebar(),
                      ),
                  ],
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const PostComposerCard(),
                        const SizedBox(height: 16),
                        _buildStoriesSection(context, ref),
                        const SizedBox(height: 16),
                        _buildFeedToggle(context, ref),
                        const SizedBox(height: 16),
                        _buildPostsList(context, ref),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
        }

        if (isDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DesktopTopbar(),
              Expanded(
                child: ClipRect(
                  child: content,
                ),
              ),
            ],
          );
        } else {
          return content;
        }
      },
    );
  }

  Widget _buildStoriesSection(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(activeStoriesProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final currentUserAvatar = profileAsync.valueOrNull?.avatarUrl;

    return SkeletonFade(
      isLoading: storiesAsync.isLoading && !storiesAsync.hasValue,
      skeleton: const SocialStoriesSkeleton(),
      child: storiesAsync.when(
        data: (groupedStories) {
          return StoriesRow(
            groupedStories: groupedStories,
            currentUserAvatarUrl: currentUserAvatar,
            onCreateStoryTap: () {
              ref.read(storyCreatorProvider.notifier).startCreating();
            },
            onAuthorStoryTap: (authorId, stories) {
              resumeWebAudio();
              ref.read(storyViewerStateProvider.notifier).openViewer(authorId, 0);
            },
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFeedToggle(BuildContext context, WidgetRef ref) {
    final isDiscover = ref.watch(isDiscoverFeedProvider);

    return Row(
      children: [
        _buildToggleItem(
          label: 'Dành cho bạn',
          active: isDiscover,
          onTap: () => ref.read(isDiscoverFeedProvider.notifier).state = true,
        ),
        const SizedBox(width: 8),
        _buildToggleItem(
          label: 'Bạn bè',
          active: !isDiscover,
          onTap: () => ref.read(isDiscoverFeedProvider.notifier).state = false,
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF7C5CFF).withValues(alpha: .15) : Colors.transparent,
          border: Border.all(
            color: active ? const Color(0xFF7C5CFF) : Colors.white.withValues(alpha: .08),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPostsList(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedPostsProvider);
    final posts = postsAsync.valueOrNull ?? [];

    final isLoading = postsAsync.isLoading && posts.isEmpty;

    return SkeletonFade(
      isLoading: isLoading,
      skeleton: Column(
        children: const [
          SocialPostSkeleton(),
          SocialPostSkeleton(),
          SocialPostSkeleton(),
        ],
      ),
      child: posts.isEmpty && postsAsync.hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Không thể tải bài viết: ${postsAsync.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          : posts.isEmpty
              ? EmptyFeedState(onFindFriends: onFindFriends)
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return ActivityPostCard(post: posts[index]);
                  },
                ),
    );
  }
}
