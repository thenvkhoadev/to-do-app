import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:to_do_app/theme/design_tokens.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/social/data/models/story_model.dart';
import 'package:to_do_app/features/social/presentation/providers/feed_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/story_provider.dart';
import 'package:to_do_app/features/social/presentation/widgets/stories_row.dart';
import 'package:to_do_app/features/social/presentation/widgets/story_viewer.dart';
import 'package:to_do_app/features/social/presentation/widgets/story_create_sheet.dart';
import 'package:to_do_app/features/social/presentation/widgets/post_composer_card.dart';
import 'package:to_do_app/features/social/presentation/widgets/activity_post_card.dart';
import 'package:to_do_app/features/social/presentation/widgets/empty_feed_state.dart';
import 'package:to_do_app/features/social/presentation/widgets/feed_right_sidebar.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key, this.onFindFriends});

  final VoidCallback? onFindFriends;

  void _openStoryViewer(BuildContext context, WidgetRef ref, List<StoryModel> stories) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return StoryViewer(
          stories: stories,
          onClose: () => Navigator.pop(context),
          onStorySeen: (storyId) async {
            final currentUser = ref.read(authControllerProvider).valueOrNull;
            if (currentUser != null) {
              await ref.read(storyServiceProvider).viewStory(storyId, currentUser.id);
            }
          },
        );
      },
    );
  }

  void _openStoryCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StoryCreateSheet(
          onCreatePhotoStory: (file) => _createPhotoStory(context, ref, file),
          onCreateTaskStory: (count, xp) => _createTaskStory(context, ref, count, xp),
          onCreateStreakStory: (streak) => _createStreakStory(context, ref, streak),
          onCreateAchievementStory: (title, desc) => _createAchievementStory(context, ref, title, desc),
        );
      },
    );
  }

  Future<void> _createPhotoStory(BuildContext context, WidgetRef ref, XFile file) async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;
    final storyService = ref.read(storyServiceProvider);
    final mediaUrl = await storyService.uploadStoryPhoto(currentUser.id, file);
    await storyService.createStory(
      authorId: currentUser.id,
      contentType: StoryContentType.photo,
      mediaUrl: mediaUrl,
    );
  }

  Future<void> _createTaskStory(BuildContext context, WidgetRef ref, int count, int xp) async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;
    await ref.read(storyServiceProvider).createStory(
      authorId: currentUser.id,
      contentType: StoryContentType.taskSummary,
      autoData: {'taskCount': count, 'xp': xp},
    );
  }

  Future<void> _createStreakStory(BuildContext context, WidgetRef ref, int streak) async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;
    await ref.read(storyServiceProvider).createStory(
      authorId: currentUser.id,
      contentType: StoryContentType.streak,
      autoData: {'streakCount': streak},
    );
  }

  Future<void> _createAchievementStory(BuildContext context, WidgetRef ref, String title, String desc) async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;
    await ref.read(storyServiceProvider).createStory(
      authorId: currentUser.id,
      contentType: StoryContentType.achievement,
      autoData: {'title': title, 'desc': desc},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isDesktop = screenWidth >= 1200;

        if (isDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DesktopTopbar(),
              Expanded(
                child: Row(
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
                                _buildStoriesSection(context, ref),
                                const SizedBox(height: 16),
                                const PostComposerCard(),
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
                    // Right Sidebar (shown if width is wide enough)
                    if (screenWidth >= 1280)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: FeedRightSidebar(),
                      ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Mobile: Layout scroll is managed by the dashboard shell, so we return a Column
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStoriesSection(context, ref),
              const SizedBox(height: 16),
              const PostComposerCard(),
              const SizedBox(height: 16),
              _buildFeedToggle(context, ref),
              const SizedBox(height: 16),
              _buildPostsList(context, ref),
              const SizedBox(height: 24),
            ],
          );
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
          onCreateStoryTap: () => _openStoryCreateSheet(context, ref),
          onAuthorStoryTap: (authorId, stories) => _openStoryViewer(context, ref, stories),
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
