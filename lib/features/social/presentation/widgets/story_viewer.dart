import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/social/data/models/story_model.dart';
import 'package:to_do_app/features/social/presentation/providers/story_state_providers.dart';
import 'package:to_do_app/features/social/presentation/providers/story_provider.dart';
import 'package:to_do_app/features/social/presentation/widgets/premium_toast.dart';
import 'package:to_do_app/features/social/presentation/widgets/story_privacy_modal.dart';

class StoryViewer extends ConsumerStatefulWidget {
  const StoryViewer({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  ConsumerState<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<StoryViewer> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  bool _isMuted = false;
  AudioPlayer? _audioPlayer;
  VideoPlayerController? _storyVideoController;
  String? _currentViewerVideoUrl;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this);
    _animController.addStatusListener(_onAnimationStatusChange);

    _replyFocusNode.addListener(() {
      if (_replyFocusNode.hasFocus) {
        _animController.stop(); // Pause playback while typing
        _storyVideoController?.pause();
      } else {
        _animController.forward(); // Resume
        _storyVideoController?.play();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStoryTimer();
    });
  }

  @override
  void dispose() {
    _animController.removeStatusListener(_onAnimationStatusChange);
    _animController.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    if (_audioPlayer != null) {
      _audioPlayer!.dispose();
    }
    _storyVideoController?.dispose();
    super.dispose();
  }

  void _onAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goNextStory();
    }
  }

  Future<void> _playStoryMusic(StoryModel story) async {
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.stop();
      } catch (_) {}
    }

    final musicData = story.autoData?['music'] as Map<String, dynamic>?;
    if (musicData == null) return;

    final musicOverlay = MusicOverlay.fromJson(musicData);
    final audioUrl = musicOverlay.audioUrl;
    if (audioUrl.isEmpty) return;

    _audioPlayer ??= AudioPlayer();

    final viewerState = ref.read(storyViewerStateProvider);
    final isViewerPlaying = viewerState?.isPlaying ?? true;

    if (isViewerPlaying) {
      try {
        await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
        if (_isMuted) {
          await _audioPlayer!.setVolume(0.0);
        } else {
          await _audioPlayer!.setVolume(1.0);
        }
        await _audioPlayer!.play(UrlSource(audioUrl));
      } catch (_) {}
    }
  }

  Future<void> _initStoryVideo(StoryModel story) async {
    if (_storyVideoController != null) {
      final oldController = _storyVideoController!;
      _storyVideoController = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController.dispose();
      });
    }

    if (story.contentType != StoryContentType.video || story.mediaUrl == null || story.mediaUrl!.isEmpty) {
      _currentViewerVideoUrl = null;
      return;
    }

    final videoUrl = story.mediaUrl!;
    _currentViewerVideoUrl = videoUrl;

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _storyVideoController = controller;

    try {
      _animController.stop();

      await controller.initialize();
      if (_currentViewerVideoUrl != videoUrl) {
        controller.dispose();
        return;
      }

      await controller.setVolume(_isMuted ? 0.0 : 1.0);
      await controller.setLooping(false);

      final duration = controller.value.duration;
      _animController.duration = duration > Duration.zero ? duration : const Duration(seconds: 5);
      
      final viewerState = ref.read(storyViewerStateProvider);
      final isViewerPlaying = viewerState?.isPlaying ?? true;
      if (isViewerPlaying) {
        await controller.play();
        _animController.forward();
      }
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing story video: $e');
      _animController.duration = const Duration(seconds: 5);
      _animController.forward();
    }
  }

  void _startStoryTimer() {
    _animController.stop();
    _animController.reset();
    _animController.duration = const Duration(seconds: 5);
    
    final groupedStories = ref.read(activeStoriesProvider).valueOrNull ?? {};
    final viewerState = ref.read(storyViewerStateProvider);
    if (viewerState != null && viewerState.activeAuthorId != null) {
      final authorStories = groupedStories[viewerState.activeAuthorId] ?? [];
      if (authorStories.isNotEmpty) {
        final activeStoryIndex = viewerState.activeStoryIndex.clamp(0, authorStories.length - 1);
        final activeStory = authorStories[activeStoryIndex];
        _playStoryMusic(activeStory);
        _initStoryVideo(activeStory);
      }
      
      if (viewerState.isPlaying) {
        _animController.forward();
      }
    }
  }

  void _goNextStory() {
    final groupedStories = ref.read(activeStoriesProvider).valueOrNull ?? {};
    final viewerState = ref.read(storyViewerStateProvider);
    if (viewerState == null || viewerState.activeAuthorId == null) return;

    final authorStories = groupedStories[viewerState.activeAuthorId] ?? [];
    
    ref.read(storyViewerStateProvider.notifier).nextStory(
      authorStories.length,
      () {
        // Go to next author
        final authorIds = groupedStories.keys.toList();
        final currentIdx = authorIds.indexOf(viewerState.activeAuthorId!);
        if (currentIdx != -1 && currentIdx < authorIds.length - 1) {
          final nextAuthorId = authorIds[currentIdx + 1];
          ref.read(storyViewerStateProvider.notifier).openViewer(nextAuthorId, 0);
          _startStoryTimer();
        } else {
          // Finished all stories, close
          widget.onClose();
          ref.read(storyViewerStateProvider.notifier).closeViewer();
        }
      },
    );
    _startStoryTimer();
  }

  void _goPrevStory() {
    final groupedStories = ref.read(activeStoriesProvider).valueOrNull ?? {};
    final viewerState = ref.read(storyViewerStateProvider);
    if (viewerState == null || viewerState.activeAuthorId == null) return;

    ref.read(storyViewerStateProvider.notifier).prevStory(
      () {
        // Go to previous author
        final authorIds = groupedStories.keys.toList();
        final currentIdx = authorIds.indexOf(viewerState.activeAuthorId!);
        if (currentIdx > 0) {
          final prevAuthorId = authorIds[currentIdx - 1];
          final prevAuthorStories = groupedStories[prevAuthorId] ?? [];
          // Start from last story of previous author
          ref.read(storyViewerStateProvider.notifier).openViewer(prevAuthorId, prevAuthorStories.length - 1);
          _startStoryTimer();
        } else {
          // At first story of first author, close or restart
          widget.onClose();
          ref.read(storyViewerStateProvider.notifier).closeViewer();
        }
      },
    );
    _startStoryTimer();
  }

  void _selectAuthor(String authorId) {
    ref.read(storyViewerStateProvider.notifier).openViewer(authorId, 0);
    _startStoryTimer();
  }

  void _onTapDown(TapDownDetails details, double boxWidth) {
    final double dx = details.localPosition.dx;
    if (dx < boxWidth / 3) {
      _goPrevStory();
    } else {
      _goNextStory();
    }
  }

  void _sendReply(String text) async {
    if (text.trim().isEmpty) return;
    _replyController.clear();
    _replyFocusNode.unfocus();
    _animController.forward();
    
    PremiumToast.show(context, 'Đã gửi phản hồi: "$text"');
  }

  void _togglePlayPause() {
    final notifier = ref.read(storyViewerStateProvider.notifier);
    final state = ref.read(storyViewerStateProvider);
    if (state == null) return;
    
    final wasPlaying = state.isPlaying;
    notifier.setPlaying(!wasPlaying);
    if (wasPlaying) {
      _animController.stop();
      _storyVideoController?.pause();
      if (_audioPlayer != null) {
        _audioPlayer!.pause();
      }
    } else {
      _animController.forward();
      _storyVideoController?.play();
      if (_audioPlayer != null) {
        _audioPlayer!.resume();
      }
    }
  }

  void _openPrivacySettings() {
    _animController.stop();
    showDialog(
      context: context,
      builder: (_) => const StoryPrivacyModal(),
    ).then((_) {
      if (ref.read(storyViewerStateProvider)?.isPlaying == true) {
        _animController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedStories = ref.watch(activeStoriesProvider).valueOrNull ?? {};
    final viewerState = ref.watch(storyViewerStateProvider);
    final currentUser = ref.watch(authControllerProvider).valueOrNull;

    if (viewerState == null || viewerState.activeAuthorId == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final activeAuthorId = viewerState.activeAuthorId!;
    final authorStories = groupedStories[activeAuthorId] ?? [];
    if (authorStories.isEmpty) {
      return const Center(child: Text('Không có tin để hiển thị', style: TextStyle(color: Colors.white)));
    }

    final activeStoryIndex = viewerState.activeStoryIndex.clamp(0, authorStories.length - 1);
    final activeStory = authorStories[activeStoryIndex];

    // Trigger viewed event
    if (currentUser != null) {
      ref.read(storyServiceProvider).viewStory(activeStory.id, currentUser.id);
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1200;

    if (!isDesktop) {
      return _buildMobileViewer(context, activeStory, authorStories, groupedStories, activeAuthorId, activeStoryIndex, viewerState);
    }

    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double playerHeight = (screenHeight - 80).clamp(360.0, 560.0);
    final double playerWidth = playerHeight * (9 / 16);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // 1. LEFT SIDEBAR (width 360px)
          Container(
            width: 360,
            color: const Color(0xFF1C1A2E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (image2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tin',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: widget.onClose,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => PremiumToast.show(context, 'Mở kho lưu trữ tin...'),
                            child: const Text(
                              'Kho lưu trữ',
                              style: TextStyle(color: Color(0xFF1877F2), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Text(' · ', style: TextStyle(color: Colors.white30)),
                          GestureDetector(
                            onTap: _openPrivacySettings,
                            child: const Text(
                              'Cài đặt',
                              style: TextStyle(color: Color(0xFF1877F2), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 16),

                // List of authors
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Section: Tin của bạn
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Tin của bạn', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      if (currentUser != null && groupedStories.containsKey(currentUser.id)) ...[
                        _buildAuthorRow(currentUser.id, groupedStories[currentUser.id]!, activeAuthorId),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: InkWell(
                            onTap: () {
                              ref.read(storyViewerStateProvider.notifier).closeViewer();
                              ref.read(storyCreatorProvider.notifier).startCreating();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: .06),
                                    ),
                                    child: const Icon(Icons.add, color: Color(0xFF1877F2), size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tạo tin',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Bạn có thể chia sẻ ảnh hoặc viết gì đó.',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Section: Tất cả tin
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Tất cả tin', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      ...groupedStories.keys
                          .where((id) => currentUser == null || id != currentUser.id)
                          .map((id) => _buildAuthorRow(id, groupedStories[id]!, activeAuthorId)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Vertical divider
          Container(width: 1, color: Colors.white12),

          // 2. CENTER VIEWER (Black background)
          Expanded(
            child: Container(
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Floating Previous Button [<-] on the left (outside frame)
                  Positioned(
                    left: 24,
                    child: _buildNavigationButton(Icons.arrow_back_ios_new_rounded, _goPrevStory),
                  ),

                  // Floating Next Button [->] on the right (outside frame)
                  Positioned(
                    right: 24,
                    child: _buildNavigationButton(Icons.arrow_forward_ios_rounded, _goNextStory),
                  ),

                  // Story Frame (Aspect ratio 9:16)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: playerWidth,
                        height: playerHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // 1. Background Content
                              Positioned.fill(
                                child: _buildPlayerContent(activeStory),
                              ),
                              
                              // 2. GestureDetector overlay (handles tapping left/right) placed behind overlays & controls
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapDown: (details) => _onTapDown(details, playerWidth),
                                ),
                              ),

                              // 3. Overlay Layout (Text Overlays & Music Card)
                              Positioned.fill(
                                child: _buildStoryOverlays(activeStory, playerWidth, playerHeight),
                              ),

                              // 4. User Header Overlay
                              Positioned(
                                top: 22,
                                left: 12,
                                right: 12,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundImage: activeStory.authorAvatarUrl.isNotEmpty
                                          ? NetworkImage(activeStory.authorAvatarUrl)
                                          : null,
                                      backgroundColor: Colors.grey.shade800,
                                      child: activeStory.authorAvatarUrl.isEmpty
                                          ? const Icon(Icons.person, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          activeStory.authorName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                          ),
                                        ),
                                        Text(
                                          _timeAgo(activeStory.createdAt),
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: .7),
                                            fontSize: 11,
                                            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),

                                    // Action buttons: Mute, Play/Pause, Three-dots
                                    IconButton(
                                      icon: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                          color: Colors.white, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _isMuted = !_isMuted;
                                        });
                                        _storyVideoController?.setVolume(_isMuted ? 0.0 : 1.0);
                                        if (_audioPlayer != null) {
                                          _audioPlayer!.setVolume(_isMuted ? 0.0 : 1.0);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(viewerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.white, size: 20),
                                      onPressed: _togglePlayPause,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20),
                                      onPressed: () => PremiumToast.show(context, 'Mở cài đặt tin...'),
                                    ),
                                  ],
                                ),
                              ),

                              // 5. Progress Bars overlay (top)
                              Positioned(
                                top: 12,
                                left: 8,
                                right: 8,
                                child: Row(
                                  children: List.generate(
                                    authorStories.length,
                                    (index) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                        child: _buildProgressBar(index, activeStoryIndex),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 3. Reply and Reactions Bar
                      const SizedBox(height: 16),
                      _buildReplyBar(playerWidth),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int index, int activeIdx) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        double val = 0.0;
        if (index < activeIdx) {
          val = 1.0;
        } else if (index == activeIdx) {
          val = _animController.value;
        }
        return LinearProgressIndicator(
          value: val,
          backgroundColor: Colors.white.withValues(alpha: .3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 3,
          borderRadius: BorderRadius.circular(2),
        );
      },
    );
  }

  Widget _buildNavigationButton(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: .5),
            border: Border.all(color: Colors.white12, width: 1.5),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildAuthorRow(String authorId, List<StoryModel> stories, String activeId) {
    final representative = stories.first;
    final isActive = authorId == activeId;
    final hasUnseen = stories.any((s) => s.viewedByUserIds.isEmpty);

    return InkWell(
      onTap: () => _selectAuthor(authorId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Avatar with Ring
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasUnseen ? const Color(0xFF7C5CFF) : Colors.white30,
              ),
              child: CircleAvatar(
                backgroundImage: representative.authorAvatarUrl.isNotEmpty
                    ? NetworkImage(representative.authorAvatarUrl)
                    : null,
                backgroundColor: Colors.grey.shade900,
                child: representative.authorAvatarUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Name & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    representative.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stories.length} thẻ mới · ${_timeAgo(representative.createdAt)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerContent(StoryModel story) {
    if (story.contentType == StoryContentType.video && story.mediaUrl != null) {
      if (_storyVideoController != null && _storyVideoController!.value.isInitialized) {
        return Center(
          child: AspectRatio(
            aspectRatio: _storyVideoController!.value.aspectRatio,
            child: VideoPlayer(_storyVideoController!),
          ),
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white24),
        );
      }
    }

    if (story.contentType == StoryContentType.photo && story.mediaUrl != null) {
      final double z = (story.autoData?['zoom'] as num? ?? 1.0).toDouble();
      final double r = (story.autoData?['rotation'] as num? ?? 0.0).toDouble();
      final double px = (story.autoData?['panX'] as num? ?? 0.0).toDouble();
      final double py = (story.autoData?['panY'] as num? ?? 0.0).toDouble();
      
      final fitTypeStr = story.autoData?['imageFit'] as String?;
      final isFit = fitTypeStr == 'fit';

      final transform = Matrix4.identity()
        ..translate(px, py)
        ..rotateZ(r * math.pi / 180)
        ..scale(z);

      Widget imageWidget = Image.network(
        story.mediaUrl!,
        fit: isFit ? BoxFit.contain : BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white24));
        },
      );

      if (isFit) {
        imageWidget = Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: imageWidget,
        );
      }

      return Transform(
        transform: transform,
        alignment: Alignment.center,
        child: imageWidget,
      );
    }

    if (story.contentType == StoryContentType.text) {
      final text = story.autoData?['text'] ?? '';
      final bgIndex = story.autoData?['backgroundColorIndex'] ?? 0;
      final fontFamily = story.autoData?['fontFamily'] ?? 'Gọn Gàng';

      // Default gradients
      final gradients = const [
        LinearGradient(colors: [Color(0xFF1877F2), Color(0xFF00C6FF)]),
        LinearGradient(colors: [Color(0xFFC678DD), Color(0xFFE96FA0)]),
        LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
      ];
      final gradient = bgIndex < gradients.length ? gradients[bgIndex] : gradients[0];

      TextStyle textStyle = const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold);
      if (fontFamily == 'Bình Thường') {
        textStyle = textStyle.copyWith(fontFamily: 'sans-serif', fontWeight: FontWeight.normal);
      } else if (fontFamily == 'Kiểu Cách') {
        textStyle = textStyle.copyWith(fontFamily: 'Georgia', fontStyle: FontStyle.italic);
      } else if (fontFamily == 'Tiêu Đề') {
        textStyle = textStyle.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w900);
      }

      return Container(
        decoration: BoxDecoration(gradient: gradient),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      );
    }

    // Default generated cards
    LinearGradient grad = const LinearGradient(colors: [Color(0xFF7C5CFF), Color(0xFFA78BFA)]);
    String statText = '';
    String statLabel = '';
    String xpText = '';
    IconData icon = Icons.star;

    if (story.contentType == StoryContentType.taskSummary) {
      grad = const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]);
      final count = story.autoData?['taskCount'] ?? 0;
      final xp = story.autoData?['xp'] ?? 0;
      statText = '$count';
      statLabel = 'Công việc hoàn thành';
      xpText = '+$xp XP tích lũy';
      icon = Icons.check_circle_outline_rounded;
    } else if (story.contentType == StoryContentType.streak) {
      grad = const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF59E0B)]);
      final streak = story.autoData?['streakCount'] ?? 0;
      statText = '$streak';
      statLabel = 'ngày liên tiếp';
      xpText = 'Tiếp tục giữ vững chuỗi!';
      icon = Icons.local_fire_department_rounded;
    } else if (story.contentType == StoryContentType.achievement) {
      grad = const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF3B82F6)]);
      statText = '🏆';
      statLabel = story.autoData?['desc'] ?? '';
      xpText = story.autoData?['title'] ?? 'Thành tựu';
      icon = Icons.military_tech_rounded;
    }

    return Container(
      decoration: BoxDecoration(gradient: grad),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          if (statText != '🏆')
            Text(
              statText,
              style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900),
            ),
          const SizedBox(height: 8),
          Text(
            statLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              xpText,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // BUILDER: Text Overlays & Music Overlays on the Viewer Card
  Widget _buildStoryOverlays(StoryModel story, double canvasWidth, double canvasHeight) {
    final overlaysData = story.autoData?['textOverlays'] as List<dynamic>? ?? [];
    final textOverlays = overlaysData.map((o) => TextOverlay.fromJson(o as Map<String, dynamic>)).toList();

    final musicData = story.autoData?['music'] as Map<String, dynamic>?;
    final musicOverlay = musicData != null ? MusicOverlay.fromJson(musicData) : null;

    return Stack(
      children: [
        // Text Overlays (non-draggable, scaled)
        ...textOverlays.map((overlay) {
          final double posX = overlay.x * canvasWidth;
          final double posY = overlay.y * canvasHeight;
          final double scale = overlay.scale;

          const double baseWidth = 180;
          final double w = baseWidth * scale;

          return Positioned(
            left: posX - (w / 2),
            top: posY - (60 * scale / 2),
            child: Container(
              width: w,
              alignment: Alignment.center,
              child: Text(
                overlay.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: overlay.color,
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1))],
                ),
              ),
            ),
          );
        }),

        // Music Overlay Card (non-draggable, scaled)
        if (musicOverlay != null) () {
          final double posX = musicOverlay.x * canvasWidth;
          final double posY = musicOverlay.y * canvasHeight;
          final double scale = musicOverlay.scale;

          const double baseWidth = 150;
          const double baseHeight = 160;
          final double w = baseWidth * scale;
          final double h = baseHeight * scale;

          return Positioned(
            left: posX - (w / 2),
            top: posY - (h / 2),
            child: Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12 * scale),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        color: Colors.grey.shade900,
                        child: Image.network(
                          musicOverlay.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.music_note_rounded,
                            color: Colors.white24,
                            size: 40 * scale,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: const Color(0xA6000000),
                      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 6 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            musicOverlay.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.music_note_rounded, color: Colors.white70, size: 10 * scale),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  musicOverlay.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10 * scale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }(),
      ],
    );
  }

  // BUILDER: Bottom Reply and Reactions Bar
  Widget _buildReplyBar(double playerWidth) {
    return SizedBox(
      width: playerWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emojis Reactions Row (👍 ❤️ 😍 😂 😮 😢 😡)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['👍', '❤️', '😍', '😂', '😮', '😢', '😡'].map((emoji) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _sendReply(emoji),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .1),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Input Text Reply
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                height: 48,
                color: Colors.white.withValues(alpha: .1),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: TextField(
                  controller: _replyController,
                  focusNode: _replyFocusNode,
                  onSubmitted: _sendReply,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Gửi tin nhắn...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: .45), fontSize: 14),
                    border: InputBorder.none,
                    suffixIcon: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _sendReply(_replyController.text),
                        child: const Icon(Icons.send_rounded, color: Colors.white70, size: 20),
                      ),
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

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inHours >= 24) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Widget _buildMobileViewer(
    BuildContext context,
    StoryModel activeStory,
    List<StoryModel> authorStories,
    Map<String, List<StoryModel>> groupedStories,
    String activeAuthorId,
    int activeStoryIndex,
    StoryViewerState viewerState,
  ) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double screenWidth = MediaQuery.sizeOf(context).width;

    final double playerHeight = screenHeight;
    final double playerWidth = screenWidth;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: _buildPlayerContent(activeStory),
          ),
          
          // GestureDetector overlay (handles tapping left/right) placed behind overlays & controls
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) => _onTapDown(details, playerWidth),
            ),
          ),

          Positioned.fill(
            child: _buildStoryOverlays(activeStory, playerWidth, playerHeight),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 22,
            left: 12,
            right: 12,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: activeStory.authorAvatarUrl.isNotEmpty
                      ? NetworkImage(activeStory.authorAvatarUrl)
                      : null,
                  backgroundColor: Colors.grey.shade800,
                  child: activeStory.authorAvatarUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activeStory.authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                    Text(
                      _timeAgo(activeStory.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .7),
                        fontSize: 11,
                        shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                    _storyVideoController?.setVolume(_isMuted ? 0.0 : 1.0);
                    if (_audioPlayer != null) {
                      _audioPlayer!.setVolume(_isMuted ? 0.0 : 1.0);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(viewerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 20),
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 8,
            right: 8,
            child: Row(
              children: List.generate(
                authorStories.length,
                (index) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: _buildProgressBar(index, activeStoryIndex),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            left: 16,
            right: 16,
            child: _buildReplyBar(playerWidth - 32),
          ),
        ],
      ),
    );
  }
}
