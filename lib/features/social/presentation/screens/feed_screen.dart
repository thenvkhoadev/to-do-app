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
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';

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
              builder: (context) => PopScope(
                canPop: true,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) {
                    ref.read(storyCreatorProvider.notifier).reset();
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

    return storiesAsync.when(
      data: (groupedStories) {
        return StoriesRow(
          groupedStories: groupedStories,
          currentUserAvatarUrl: currentUserAvatar,
          onCreateStoryTap: () {
            ref.read(storyCreatorProvider.notifier).startCreating();
          },
          onAuthorStoryTap: (authorId, stories) {
            ref.read(storyViewerStateProvider.notifier).openViewer(authorId, 0);
          },
        );
      },
      loading: () => const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator(color: Colors.white24)),
      ),
      error: (_, __) => const SizedBox.shrink(),
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

    if (posts.isEmpty && postsAsync.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Colors.white24),
        ),
      );
    }

    if (posts.isEmpty && postsAsync.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Không thể tải bài viết: ${postsAsync.error}',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    if (posts.isEmpty) {
      return EmptyFeedState(onFindFriends: onFindFriends);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return ActivityPostCard(post: posts[index]);
      },
    );
  }
}
