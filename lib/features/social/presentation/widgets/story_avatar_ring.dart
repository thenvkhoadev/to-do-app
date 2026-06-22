import 'package:flutter/material.dart';
import 'package:to_do_app/theme/design_tokens.dart';
import 'package:to_do_app/features/social/data/models/story_model.dart';

class StoryAvatarRing extends StatelessWidget {
  const StoryAvatarRing({
    super.key,
    this.story,
    this.isCreateItem = false,
    this.currentUserAvatarUrl,
    this.onTap,
  });

  final StoryModel? story;
  final bool isCreateItem;
  final String? currentUserAvatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnseen = story != null && story!.viewedByUserIds.isEmpty;
    final avatarUrl = isCreateItem ? currentUserAvatarUrl : story?.authorAvatarUrl;
    final name = isCreateItem ? 'Tạo tin' : (story?.authorName ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 230,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // 1. Story Background
              if (isCreateItem)
                Column(
                  children: [
                    Expanded(
                      flex: 7,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          image: avatarUrl != null && avatarUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white24, size: 48)
                            : null,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFF1E1E2E),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'Tạo tin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Friends story card background
                _buildStoryCardBackground(),

              // 2. Gradient Overlay for readability of name text
              if (!isCreateItem)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black54],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

              // 3. Plus Icon Button for Create Item
              if (isCreateItem)
                Positioned(
                  top: 144, // center it on the boundary (230 * 0.7 = 161. 161 - (34/2) = 144)
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: DesignTokens.gradientPrimary,
                        border: Border.all(color: const Color(0xFF13131C), width: 2.5),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // 4. Author Avatar at top-left
              if (!isCreateItem)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasUnseen ? DesignTokens.gradientPrimary : null,
                      color: hasUnseen ? null : Colors.grey.shade700,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignTokens.bgPrimary,
                      ),
                      child: CircleAvatar(
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        backgroundColor: Colors.grey.shade900,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white54, size: 20)
                            : null,
                      ),
                    ),
                  ),
                ),

              // 5. Author Name at bottom-left
              if (!isCreateItem)
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCardBackground() {
    if (story == null) return Container(color: Colors.grey.shade900);

    final media = story!.mediaUrl;
    if (story!.contentType == StoryContentType.photo && media != null && media.isNotEmpty) {
      return Image.network(
        media,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    // Default gradient colors for generated story types
    LinearGradient grad = const LinearGradient(
      colors: [Color(0xFF7C5CFF), Color(0xFFA78BFA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    String label = '';
    IconData icon = Icons.star_rounded;

    if (story!.contentType == StoryContentType.taskSummary) {
      grad = const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      final count = story!.autoData?['taskCount'] ?? 0;
      label = '$count task';
      icon = Icons.check_circle_outline_rounded;
    } else if (story!.contentType == StoryContentType.streak) {
      grad = const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      final streak = story!.autoData?['streakCount'] ?? 0;
      label = '$streak ngày';
      icon = Icons.local_fire_department_rounded;
    } else if (story!.contentType == StoryContentType.achievement) {
      grad = const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      label = story!.autoData?['title']?.toString() ?? 'Kỷ lục';
      icon = Icons.emoji_events_rounded;
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: grad),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(
              icon,
              size: 110,
              color: Colors.white.withValues(alpha: .15),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
