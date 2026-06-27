import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:to_do_app/theme/design_tokens.dart';
import 'package:to_do_app/features/social/data/models/story_model.dart';
import 'package:to_do_app/features/social/presentation/providers/story_state_providers.dart';

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
        width: 116,
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            children: [
              // 1. Story Background
              if (isCreateItem)
                Column(
                  children: [
                    Expanded(
                      flex: 78,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          image: avatarUrl != null && avatarUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white24, size: 36)
                            : null,
                      ),
                    ),
                    Expanded(
                      flex: 22,
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFF242526),
                        child: const Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Tạo tin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
                Positioned.fill(child: _buildStoryCardBackground(context)),

              // 2. Gradient Overlay for readability of name text
              if (!isCreateItem)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                ),

              // 3. Plus Icon Button for Create Item
              if (isCreateItem)
                Positioned(
                  top: 140, // center it on the boundary (200 * 0.78 = 156. 156 - (32/2) = 140)
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1877F2),
                        border: Border.all(color: const Color(0xFF242526), width: 3.5),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 18,
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
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasUnseen ? const Color(0xFF1877F2) : Colors.white.withValues(alpha: 0.3),
                        width: hasUnseen ? 2.5 : 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      backgroundColor: Colors.grey.shade900,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.white54, size: 16)
                          : null,
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
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

  Widget _buildStoryCardBackground(BuildContext context) {
    if (story == null) return Container(color: Colors.grey.shade900);

    final media = story!.mediaUrl;
    if (story!.contentType == StoryContentType.video && media != null && media.isNotEmpty) {
      return VideoPreviewWidget(videoUrl: media);
    }

    if (story!.contentType == StoryContentType.photo && media != null && media.isNotEmpty) {
      return Image.network(
        media,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (story!.contentType == StoryContentType.text) {
      final text = story!.autoData?['text'] ?? '';
      final bgIndex = story!.autoData?['backgroundColorIndex'] ?? 0;
      final fontFamily = story!.autoData?['fontFamily'] ?? 'Gọn Gàng';
      
      // Select font style
      TextStyle fontStyle = const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold);
      if (fontFamily == 'Bình Thường') {
        fontStyle = fontStyle.copyWith(fontFamily: 'sans-serif', fontWeight: FontWeight.normal);
      } else if (fontFamily == 'Kiểu Cách') {
        fontStyle = fontStyle.copyWith(fontFamily: 'Georgia', fontStyle: FontStyle.italic);
      } else if (fontFamily == 'Tiêu Đề') {
        fontStyle = fontStyle.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w900);
      }

      // Default gradients
      final gradients = const [
        LinearGradient(colors: [Color(0xFF1877F2), Color(0xFF00C6FF)]),
        LinearGradient(colors: [Color(0xFFC678DD), Color(0xFFE96FA0)]),
        LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
      ];
      final gradient = bgIndex < gradients.length ? gradients[bgIndex] : gradients[0];

      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: gradient),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: fontStyle,
        ),
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
            right: -16,
            bottom: -16,
            child: Icon(
              icon,
              size: 64,
              color: Colors.white.withValues(alpha: .15),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

class VideoPreviewWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPreviewWidget({super.key, required this.videoUrl});

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized && _controller != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(color: Colors.white30, strokeWidth: 2),
      ),
    );
  }
}
