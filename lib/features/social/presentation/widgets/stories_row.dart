import 'package:flutter/material.dart';
import 'package:to_do_app/features/social/data/models/story_model.dart';
import 'package:to_do_app/features/social/presentation/widgets/story_avatar_ring.dart';

class StoriesRow extends StatefulWidget {
  const StoriesRow({
    super.key,
    required this.groupedStories,
    this.currentUserAvatarUrl,
    this.onCreateStoryTap,
    this.onAuthorStoryTap,
  });

  final Map<String, List<StoryModel>> groupedStories;
  final String? currentUserAvatarUrl;
  final VoidCallback? onCreateStoryTap;
  final void Function(String authorId, List<StoryModel> stories)? onAuthorStoryTap;

  @override
  State<StoriesRow> createState() => _StoriesRowState();
}

class _StoriesRowState extends State<StoriesRow> {
  late ScrollController _scrollController;
  bool _showScrollRightButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // Check after build if list is scrollable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollable();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    _checkScrollable();
  }

  void _checkScrollable() {
    if (!mounted) return;
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final isScrollable = maxScroll > 0 && currentScroll < maxScroll - 5;
      if (_showScrollRightButton != isScrollable) {
        setState(() {
          _showScrollRightButton = isScrollable;
        });
      }
    }
  }

  void _scrollRight() {
    if (_scrollController.hasClients) {
      final target = _scrollController.offset + 250;
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        target.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(covariant StoriesRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollable();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authorIds = widget.groupedStories.keys.toList();

    return Container(
      height: 215,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        children: [
          // Horizontal scrolling list
          Positioned.fill(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              itemCount: authorIds.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return StoryAvatarRing(
                    isCreateItem: true,
                    currentUserAvatarUrl: widget.currentUserAvatarUrl,
                    onTap: widget.onCreateStoryTap,
                  );
                }

                final authorId = authorIds[index - 1];
                final authorStories = widget.groupedStories[authorId]!;
                final representativeStory = authorStories.first;

                final hasUnseen = authorStories.any((story) => story.viewedByUserIds.isEmpty);

                final displayStory = representativeStory.copyWith(
                  viewedByUserIds: hasUnseen ? [] : ['viewed'],
                );

                return StoryAvatarRing(
                  story: displayStory,
                  onTap: () {
                    if (widget.onAuthorStoryTap != null) {
                      widget.onAuthorStoryTap!(authorId, authorStories);
                    }
                  },
                );
              },
            ),
          ),

          // Scroll Right Floating Button
          if (_showScrollRightButton)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _scrollRight,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
