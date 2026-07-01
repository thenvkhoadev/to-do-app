import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/workspace/workspace_provider.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/feed_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/features/social/presentation/widgets/activity_post_card.dart';
import 'package:to_do_app/features/social/presentation/screens/friend_profile_screen.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart' show DesktopTopbar;

class SocialProfileScreen extends ConsumerStatefulWidget {
  const SocialProfileScreen({super.key});

  @override
  ConsumerState<SocialProfileScreen> createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends ConsumerState<SocialProfileScreen> {
  int _activeTab = 0; // 0: Posts, 1: Photos, 2: Friends, 3: About

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DesktopTopbar(),
        Expanded(
          child: profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const Center(
                  child: Text('Profile not found', style: TextStyle(color: Colors.white70)),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section (Cover, Avatar, Names)
                    _buildHeader(context, profile),
                    const SizedBox(height: 24),
                    // Navigation Tabs
                    _buildTabs(),
                    const SizedBox(height: 24),
                    // Tab Content
                    _buildTabContent(profile),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: DashboardColors.primary),
            ),
            error: (e, s) => Center(
              child: Text('Error loading profile: $e', style: const TextStyle(color: Colors.redAccent)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, dynamic profile) {
    final displayName = profile.fullName ?? profile.username ?? 'No Name';
    final userBio = profile.bio ?? 'No bio yet...';
    final occupation = profile.occupation ?? 'Nexus Member';

    return Container(
      decoration: BoxDecoration(
        color: DashboardColors.surfaceHigh.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DashboardColors.primary.withValues(alpha: .7),
                    DashboardColors.secondary.withValues(alpha: .7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: profile.coverUrl != null && profile.coverUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(profile.coverUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            // User Meta
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: DashboardColors.surface, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                            ? Image.network(profile.avatarUrl!, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.person, color: Colors.white30, size: 48),
                              ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Name & Bio
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.work_rounded, size: 14, color: DashboardColors.primary.withValues(alpha: .7)),
                              const SizedBox(width: 6),
                              Text(
                                occupation,
                                style: const TextStyle(
                                  color: DashboardColors.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userBio,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final tabLabels = ['Posts', 'Photos', 'Friends', 'About'];
    return Container(
      decoration: BoxDecoration(
        color: DashboardColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .04)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabLabels.length, (index) {
          final isSelected = _activeTab == index;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? DashboardColors.surfaceHigh : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tabLabels[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : DashboardColors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(dynamic profile) {
    switch (_activeTab) {
      case 0:
        return _buildPostsTab(profile);
      case 1:
        return _buildPhotosTab(profile);
      case 2:
        return _buildFriendsTab(profile);
      case 3:
        return _buildAboutTab(profile);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPostsTab(dynamic profile) {
    final postsAsync = ref.watch(feedPostsProvider);

    return postsAsync.when(
      data: (posts) {
        final userPosts = posts.where((post) => post.userId == profile.id).toList();

        if (userPosts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'No posts yet.',
                style: TextStyle(color: DashboardColors.onSurfaceVariant),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: userPosts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return ActivityPostCard(post: userPosts[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildPhotosTab(dynamic profile) {
    final postsAsync = ref.watch(feedPostsProvider);

    return postsAsync.when(
      data: (posts) {
        final userPosts = posts.where((post) => post.userId == profile.id).toList();
        final photos = <String>[];

        for (final post in userPosts) {
          final mediaUrl = post.mediaUrl;
          final metaUrls = post.metaData?['media_urls'] as List<dynamic>?;
          if (mediaUrl != null && mediaUrl.isNotEmpty) photos.add(mediaUrl);
          if (metaUrls != null) {
            photos.addAll(metaUrls.cast<String>());
          }
        }

        if (photos.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'No photos yet.',
                style: TextStyle(color: DashboardColors.onSurfaceVariant),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: DashboardColors.surfaceLow,
                  image: DecorationImage(
                    image: NetworkImage(photos[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildFriendsTab(dynamic profile) {
    final friends = ref.watch(friendsListProvider);

    if (friends.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Text(
            'No friends yet.',
            style: TextStyle(color: DashboardColors.onSurfaceVariant),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 80,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        final name = friend.fullName ?? friend.username ?? 'No name';
        final bio = friend.bio ?? 'Nexus member';

        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FriendProfileScreen(
                      profile: friend,
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: DashboardColors.surfaceHigh.withValues(alpha: .4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .06)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty
                        ? Image.network(friend.avatarUrl!, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.person, color: Colors.white30, size: 24),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab(dynamic profile) {
    final coreTech = profile.coreTech ?? [];

    return Container(
      decoration: BoxDecoration(
        color: DashboardColors.surfaceHigh.withValues(alpha: .4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'About Me',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.email_rounded, size: 16, color: DashboardColors.primary),
              const SizedBox(width: 12),
              const Text('Email:', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13)),
              const SizedBox(width: 8),
              Text(profile.email, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          if (profile.locationNode != null && profile.locationNode!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: DashboardColors.primary),
                const SizedBox(width: 12),
                const Text('Location:', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13)),
                const SizedBox(width: 8),
                Text(profile.locationNode!, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ],
          if (coreTech.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Skills & Tech Stack',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(coreTech.length, (index) {
                return Container(
                  decoration: BoxDecoration(
                    color: DashboardColors.primary.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DashboardColors.primary.withValues(alpha: .25)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    coreTech[index],
                    style: const TextStyle(color: DashboardColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
