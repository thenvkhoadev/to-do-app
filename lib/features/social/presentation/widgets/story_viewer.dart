import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:to_do_app/features/social/presentation/widgets/draggable_overlay.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/social/data/models/story_model.dart';
import 'package:to_do_app/features/social/presentation/providers/story_state_providers.dart';
import 'package:to_do_app/features/social/presentation/providers/story_provider.dart';
import 'package:to_do_app/features/social/presentation/widgets/premium_toast.dart';
import 'package:to_do_app/features/social/presentation/widgets/story_privacy_modal.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:dio/dio.dart';

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
  MusicOverlay? _currentPlayingMusic;
  final LayerLink _menuLayerLink = LayerLink();

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

    _currentPlayingMusic = musicOverlay;

    final isNewPlayer = _audioPlayer == null;
    _audioPlayer ??= AudioPlayer();

    if (isNewPlayer) {
      _audioPlayer!.positionStream.listen((pos) {
        if (_currentPlayingMusic != null) {
          final start = _currentPlayingMusic!.startTimeSec;
          final end = start + 15;
          if (pos.inSeconds >= end || pos.inSeconds < start) {
            _audioPlayer!.seek(Duration(seconds: start));
          }
        }
      });
    }

    final viewerState = ref.read(storyViewerStateProvider);
    final isViewerPlaying = viewerState?.isPlaying ?? true;

    if (isViewerPlaying) {
      try {
        if (_isMuted) {
          await _audioPlayer!.setVolume(0.0);
        } else {
          await _audioPlayer!.setVolume(musicOverlay.volume);
        }
        await _audioPlayer!.stop();
        await _audioPlayer!.setUrl(audioUrl);
        await _audioPlayer!.seek(Duration(seconds: musicOverlay.startTimeSec));
        await _audioPlayer!.play();
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

      double videoVolume = 1.0;
      final musicData = story.autoData?['music'] as Map<String, dynamic>?;
      if (musicData != null) {
        final musicOverlay = MusicOverlay.fromJson(musicData);
        videoVolume = musicOverlay.originalVolume;
      }

      await controller.setVolume(_isMuted ? 0.0 : videoVolume);
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

  void _showStoryMenu(BuildContext context, BuildContext triggerContext, StoryModel story, bool isMe) {
    // Pause story playback when menu is opened
    ref.read(storyViewerStateProvider.notifier).setPlaying(false);
    _storyVideoController?.pause();
    _animController.stop();
    
    StoryMenuOverlay.show(
      context: context,
      triggerContext: triggerContext,
      layerLink: _menuLayerLink,
      story: story,
      isMe: isMe,
      onDelete: () async {
        try {
          await ref.read(storyServiceProvider).deleteStory(story.id);
          if (!mounted) return;
          PremiumToast.show(context, 'Đã xóa tin thành công!');
          // Refresh active stories
          ref.invalidate(activeStoriesProvider);
          // Go to next story or close viewer if no more stories
          _goNextStory();
        } catch (e) {
          if (!mounted) return;
          PremiumToast.show(context, 'Lỗi khi xóa tin: $e');
        }
      },
      onReport: () {
        _openLyricsViewer(context, story);
      },
      onClose: () {
        if (!mounted) return;
        // Resume story playback when menu is closed
        ref.read(storyViewerStateProvider.notifier).setPlaying(true);
        _storyVideoController?.play();
        _animController.forward();
      },
    );
  }

  void _openLyricsViewer(BuildContext context, StoryModel story) {
    final musicData = story.autoData?['music'] as Map<String, dynamic>?;
    if (musicData == null) {
      PremiumToast.show(context, 'Bài viết này không chứa nhạc để hiển thị lời bài hát!');
      return;
    }
    final musicOverlay = MusicOverlay.fromJson(musicData);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return PremiumLyricsViewer(
          title: musicOverlay.title,
          artist: musicOverlay.artist,
          coverUrl: musicOverlay.coverUrl,
          audioPlayer: _audioPlayer,
          dio: ref.read(dioProvider),
          onPrevious: () {
            _goPrevStory();
            Navigator.of(context).pop();
          },
          onNext: () {
            _goNextStory();
            Navigator.of(context).pop();
          },
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
    );
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
        _audioPlayer!.play();
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
                                child: Builder(
                                  builder: (context) {
                                    final musicData = activeStory.autoData?['music'] as Map<String, dynamic>?;
                                    final musicOverlay = musicData != null ? MusicOverlay.fromJson(musicData) : null;
                                    return Row(
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
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                activeStory.authorName,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    _timeAgo(activeStory.createdAt),
                                                    style: TextStyle(
                                                      color: Colors.white.withValues(alpha: .7),
                                                      fontSize: 11,
                                                      shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                                                    ),
                                                  ),
                                                   if (musicOverlay != null && musicOverlay.audioUrl.isNotEmpty) ...[
                                                    const SizedBox(width: 6),
                                                    const Text('•', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                                    const SizedBox(width: 6),
                                                    const Icon(Icons.music_note_rounded, color: Color(0xFFC0A0FF), size: 12),
                                                    const SizedBox(width: 3),
                                                    Expanded(
                                                      child: Text(
                                                        '${musicOverlay.title} - ${musicOverlay.artist}',
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                        style: const TextStyle(
                                                          color: Color(0xFFE0D0FF),
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

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
                                    CompositedTransformTarget(
                                      link: _menuLayerLink,
                                      child: Builder(
                                        builder: (btnContext) {
                                          return IconButton(
                                            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20),
                                            onPressed: () {
                                              _showStoryMenu(context, btnContext, activeStory, activeStory.authorId == currentUser?.id);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
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
        if (musicOverlay != null && musicOverlay.layoutStyle != 6 && musicOverlay.audioUrl.isNotEmpty)
          ViewerMusicOverlayWidget(
            overlay: musicOverlay,
            canvasWidth: canvasWidth,
            canvasHeight: canvasHeight,
          ),
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
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
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
                      _audioPlayer!.setVolume(_isMuted ? 0.0 : (_currentPlayingMusic?.volume ?? 1.0));
                    }
                  },
                ),
                IconButton(
                  icon: Icon(viewerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 20),
                  onPressed: _togglePlayPause,
                ),
                CompositedTransformTarget(
                  link: _menuLayerLink,
                  child: Builder(
                    builder: (btnContext) {
                      return IconButton(
                        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20),
                        onPressed: () {
                          _showStoryMenu(context, btnContext, activeStory, activeStory.authorId == currentUser?.id);
                        },
                      );
                    },
                  ),
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

class ViewerMusicOverlayWidget extends StatefulWidget {
  const ViewerMusicOverlayWidget({
    super.key,
    required this.overlay,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  final MusicOverlay overlay;
  final double canvasWidth;
  final double canvasHeight;

  @override
  State<ViewerMusicOverlayWidget> createState() => _ViewerMusicOverlayWidgetState();
}

class _ViewerMusicOverlayWidgetState extends State<ViewerMusicOverlayWidget> {
  int _currentPosSec = 0;
  Timer? _timer;
  List<Map<String, dynamic>>? _lyrics;

  @override
  void initState() {
    super.initState();
    _currentPosSec = widget.overlay.startTimeSec;
    _loadRealLyrics();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _currentPosSec++;
          if (_currentPosSec >= widget.overlay.startTimeSec + 15) {
            _currentPosSec = widget.overlay.startTimeSec;
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ViewerMusicOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay.startTimeSec != widget.overlay.startTimeSec) {
      _currentPosSec = widget.overlay.startTimeSec;
    }
    if (oldWidget.overlay.title != widget.overlay.title ||
        oldWidget.overlay.artist != widget.overlay.artist) {
      _loadRealLyrics();
    }
  }

  Future<void> _loadRealLyrics() async {
    final res = await fetchRealLyrics(widget.overlay.title, widget.overlay.artist);
    if (mounted) {
      setState(() {
        _lyrics = res;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.overlay.scale;
    final int layoutStyle = widget.overlay.layoutStyle;

    // Style 6: Only music -> render nothing
    if (layoutStyle == 6) {
      return const SizedBox.shrink();
    }

    double baseWidth = 150;
    double baseHeight = 160;

    if (layoutStyle == 1) {
      baseWidth = 180;
      baseHeight = 64;
    } else if (layoutStyle == 2) {
      baseWidth = 180;
      baseHeight = 44;
    } else if (layoutStyle == 3) {
      baseWidth = 100;
      baseHeight = 120;
    } else if (layoutStyle == 4) {
      baseWidth = 220;
      baseHeight = 100;
    } else if (layoutStyle == 5) {
      baseWidth = 220;
      baseHeight = 60;
    }

    final double w = baseWidth * scale;
    final double h = baseHeight * scale;

    Widget cardChild;
    if (layoutStyle == 1) {
      // Horizontal Card
      cardChild = Container(
        color: const Color(0xE61A1A1A),
        padding: EdgeInsets.all(8 * scale),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6 * scale),
              child: Image.network(
                widget.overlay.coverUrl,
                width: 48 * scale,
                height: 48 * scale,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48 * scale,
                  height: 48 * scale,
                  color: Colors.grey.shade800,
                  child: Icon(Icons.music_note_rounded, color: Colors.white70, size: 20 * scale),
                ),
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.overlay.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 12 * scale, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    widget.overlay.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 10 * scale),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (layoutStyle == 2) {
      // Minimal Horizontal Banner
      cardChild = Container(
        color: const Color(0xE61A1A1A),
        padding: EdgeInsets.symmetric(horizontal: 10 * scale),
        child: Row(
          children: [
            Icon(Icons.music_note_rounded, color: const Color(0xFF7C5CFF), size: 16 * scale),
            SizedBox(width: 6 * scale),
            Expanded(
              child: Text(
                '${widget.overlay.title} • ${widget.overlay.artist}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 11 * scale, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    } else if (layoutStyle == 3) {
      // Circular / CD vinyl style
      cardChild = Column(
        children: [
          Container(
            width: 80 * scale,
            height: 80 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: ClipOval(
              child: Image.network(
                widget.overlay.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade900,
                  child: Icon(Icons.music_note_rounded, color: Colors.white70, size: 30 * scale),
                ),
              ),
            ),
          ),
          SizedBox(height: 6 * scale),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4 * scale),
            ),
            child: Text(
              widget.overlay.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 10 * scale, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    } else if (layoutStyle == 4) {
      // Centered scrolling lyrics
      final lyrics = _lyrics ?? getLyricsForSong(widget.overlay.title, widget.overlay.artist);
      final relativeSec = _currentPosSec - widget.overlay.startTimeSec;
      int activeIndex = 0;
      for (int i = 0; i < lyrics.length; i++) {
        if (relativeSec >= lyrics[i]['time']) {
          activeIndex = i;
        }
      }
      cardChild = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (offset) {
          final index = activeIndex - 1 + offset;
          final isCurrent = offset == 1;
          if (index < 0 || index >= lyrics.length) {
            return SizedBox(height: (isCurrent ? 24 : 18) * scale);
          }
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 1.0 * scale),
            child: SizedBox(
              height: (isCurrent ? 24 : 18) * scale,
              child: Center(
                child: Text(
                  lyrics[index]['text'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.white30,
                    fontSize: (isCurrent ? 14 : 11) * scale,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          );
        }),
      );
    } else if (layoutStyle == 5) {
      // Typewriter bold lyrics
      final lyrics = _lyrics ?? getLyricsForSong(widget.overlay.title, widget.overlay.artist);
      final relativeSec = _currentPosSec - widget.overlay.startTimeSec;
      int activeIndex = 0;
      for (int i = 0; i < lyrics.length; i++) {
        if (relativeSec >= lyrics[i]['time']) {
          activeIndex = i;
        }
      }
      final currentLine = lyrics[activeIndex]['text'] as String;
      cardChild = Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 12 * scale),
        child: Text(
          currentLine,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.yellowAccent,
            fontSize: 16 * scale,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
          ),
        ),
      );
    } else {
      // Style 0 (Default vertical card)
      cardChild = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade900,
              child: Image.network(
                widget.overlay.coverUrl,
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
                  widget.overlay.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.music_note_rounded, color: Colors.white70, size: 10 * scale),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        widget.overlay.artist,
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
      );
    }

    final double posX = widget.overlay.x * widget.canvasWidth;
    final double posY = widget.overlay.y * widget.canvasHeight;

    return Positioned(
      left: posX - (w / 2),
      top: posY - (h / 2),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: (layoutStyle == 4 || layoutStyle == 5) ? null : const Color(0xE61A1A1A),
          borderRadius: BorderRadius.circular(12 * scale),
          boxShadow: (layoutStyle == 4 || layoutStyle == 5)
              ? null
              : const [BoxShadow(color: Colors.black45, blurRadius: 8)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11 * scale),
          child: cardChild,
        ),
      ),
    );
  }
}

class StoryMenuOverlay extends StatefulWidget {
  final BuildContext triggerContext;
  final LayerLink layerLink;
  final StoryModel story;
  final bool isMe;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final VoidCallback onClose;

  const StoryMenuOverlay({
    super.key,
    required this.triggerContext,
    required this.layerLink,
    required this.story,
    required this.isMe,
    required this.onDelete,
    required this.onReport,
    required this.onClose,
  });

  static OverlayEntry? _currentOverlayEntry;

  static void closeCurrentMenu() {
    if (_currentOverlayEntry != null) {
      final entry = _currentOverlayEntry!;
      _currentOverlayEntry = null;
      try {
        entry.remove();
      } catch (_) {}
    }
  }

  static void show({
    required BuildContext context,
    required BuildContext triggerContext,
    required LayerLink layerLink,
    required StoryModel story,
    required bool isMe,
    required VoidCallback onDelete,
    required VoidCallback onReport,
    required VoidCallback onClose,
  }) {
    closeCurrentMenu();

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return StoryMenuOverlay(
          triggerContext: triggerContext,
          layerLink: layerLink,
          story: story,
          isMe: isMe,
          onDelete: onDelete,
          onReport: onReport,
          onClose: () {
            closeCurrentMenu();
            onClose();
          },
        );
      },
    );

    _currentOverlayEntry = overlayEntry;
    overlayState.insert(overlayEntry);
  }

  @override
  State<StoryMenuOverlay> createState() => _StoryMenuOverlayState();
}

class _StoryMenuOverlayState extends State<StoryMenuOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _scaleAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _close() {
    _animationController.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _close,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.transparent)),
          Positioned(
            width: 320,
            child: CompositedTransformFollower(
              link: widget.layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(8, 6),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      alignment: Alignment.topRight,
                      child: child,
                    ),
                  );
                },
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 18.0),
                        child: CustomPaint(
                          size: const Size(16, 8),
                          painter: _TrianglePointerPainter(
                            fillColor: const Color(0xFF222133),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF222133),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMenuItem(
                                icon: Icons.link_rounded,
                                title: 'Sao chép liên kết để chia sẻ tin này',
                                subtitle: 'Tin sẽ hiển thị với đối tượng của ${widget.story.authorName} trong 24 giờ.',
                                onTap: () {
                                  _close();
                                  final shareUrl = 'https://nexusai.to_do_app/stories/${widget.story.id}';
                                  Clipboard.setData(ClipboardData(text: shareUrl));
                                  PremiumToast.show(context, 'Đã sao chép liên kết chia sẻ tin!');
                                },
                              ),
                              if (widget.isMe) ...[
                                const Divider(color: Colors.white10, height: 1),
                                _buildMenuItem(
                                  icon: Icons.delete_outline_rounded,
                                  title: widget.story.contentType == StoryContentType.video ? 'Xóa video' : 'Xóa tin',
                                  titleColor: const Color(0xFFEF4444),
                                  iconColor: const Color(0xFFEF4444),
                                  onTap: () {
                                    _close();
                                    widget.onDelete();
                                  },
                                ),
                              ],
                              const Divider(color: Colors.white10, height: 1),
                              _buildMenuItem(
                                icon: Icons.music_note_rounded,
                                title: 'Lyrics',
                                onTap: () {
                                  _close();
                                  widget.onReport();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color titleColor = Colors.white,
    Color iconColor = Colors.white70,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePointerPainter extends CustomPainter {
  final Color fillColor;

  _TrianglePointerPainter({required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePointerPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor;
  }
}

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

class PremiumLyricsViewer extends StatefulWidget {
  final String title;
  final String artist;
  final String coverUrl;
  final AudioPlayer? audioPlayer;
  final Dio dio;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const PremiumLyricsViewer({
    super.key,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioPlayer,
    required this.dio,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  State<PremiumLyricsViewer> createState() => _PremiumLyricsViewerState();
}

class _PremiumLyricsViewerState extends State<PremiumLyricsViewer> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<LyricLine> _syncedLyrics = [];
  List<String> _plainLyrics = [];
  
  int _activeIndex = -1;
  double _activeLineProgress = 0.0;
  bool _showControls = true;
  double _lyricFontSize = 22.0;
  double _baseFontSize = 22.0;
  bool _isFavorited = false;
  
  // Animation for Favorite Heart
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;
  late Animation<double> _heartOpacityAnim;
  bool _showHeartAnim = false;

  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _lineKeys = [];
  
  StreamSubscription? _positionSubscription;
  Timer? _controlsTimer;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
    _setupAudioListeners();
    _resetControlsTimer();
    
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 40),
    ]).animate(_heartAnimController);
    
    _heartOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
    ]).animate(_heartAnimController);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _controlsTimer?.cancel();
    _scrollController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (_showControls) {
      _controlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _setupAudioListeners() {
    if (widget.audioPlayer != null) {
      _positionSubscription = widget.audioPlayer!.positionStream.listen((pos) {
        if (!mounted) return;
        _updateActiveLine(pos);
      });
    }
  }

  void _updateActiveLine(Duration currentPosition) {
    if (_syncedLyrics.isEmpty) return;
    
    int newIndex = -1;
    for (int i = 0; i < _syncedLyrics.length; i++) {
      if (currentPosition >= _syncedLyrics[i].time) {
        newIndex = i;
      } else {
        break;
      }
    }
    
    if (newIndex != _activeIndex) {
      setState(() {
        _activeIndex = newIndex;
      });
      _scrollToActiveLine();
    }

    if (_activeIndex >= 0) {
      final currentLineTime = _syncedLyrics[_activeIndex].time;
      final nextLineTime = _activeIndex < _syncedLyrics.length - 1
          ? _syncedLyrics[_activeIndex + 1].time
          : currentLineTime + const Duration(seconds: 8);
      
      final duration = nextLineTime - currentLineTime;
      final elapsed = currentPosition - currentLineTime;
      
      if (duration.inMilliseconds > 0) {
        setState(() {
          _activeLineProgress = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
        });
      }
    }
  }

  void _scrollToActiveLine() {
    if (_activeIndex < 0 || _activeIndex >= _lineKeys.length) return;
    final key = _lineKeys[_activeIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.45,
        );
      }
    });
  }

  String _cleanSearchTerm(String term) {
    String cleaned = term.replaceAll(RegExp(r'\([^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[[^\]]*\]'), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'\b(feat\.|ft\.|remix|official|lyric|video|audio)\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*-\s*'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.trim();
  }

  Future<void> _fetchLyrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await widget.dio.get(
        'https://lrclib.net/api/get',
        queryParameters: {
          'artist_name': _cleanSearchTerm(widget.artist),
          'track_name': _cleanSearchTerm(widget.title),
        },
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            'User-Agent': 'NexusStoryApp/1.0 (https://github.com/thenvkhoadev/to-do-app)',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final synced = data['syncedLyrics'] as String?;
        final plain = data['plainLyrics'] as String?;
        
        if (synced != null && synced.trim().isNotEmpty) {
          _syncedLyrics = _parseSyncedLyrics(synced);
          _lineKeys = List.generate(_syncedLyrics.length, (index) => GlobalKey());
        }
        
        if (plain != null && plain.trim().isNotEmpty) {
          _plainLyrics = plain.split('\n').map((l) => l.trim()).toList();
        }
      }
      
      if (_syncedLyrics.isEmpty && _plainLyrics.isEmpty) {
        _errorMessage = 'No lyrics available';
      }
    } catch (e) {
      debugPrint('Error fetching lyrics from LRCLIB: $e');
      _errorMessage = 'No lyrics available';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (widget.audioPlayer != null) {
          _updateActiveLine(widget.audioPlayer!.position);
        }
      }
    }
  }

  List<LyricLine> _parseSyncedLyrics(String syncedLyrics) {
    final lines = syncedLyrics.split('\n');
    final list = <LyricLine>[];
    final regExp = RegExp(r'^\[(\d+):(\d+)(?:[.:](\d+))?\](.*)$');
    
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      final match = regExp.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final msStr = match.group(3) ?? '0';
        final text = match.group(4)!.trim();
        
        int ms = int.parse(msStr);
        if (msStr.length == 2) {
          ms *= 10;
        } else if (msStr.length == 1) {
          ms *= 100;
        }
        
        final time = Duration(minutes: min, seconds: sec, milliseconds: ms);
        list.add(LyricLine(time: time, text: text));
      }
    }
    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  void _triggerHeartAnimation() {
    setState(() {
      _showHeartAnim = true;
    });
    _heartAnimController.forward(from: 0.0).then((_) {
      setState(() {
        _showHeartAnim = false;
      });
    });
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final bool isSynced = _syncedLyrics.isNotEmpty;
    final currentPos = widget.audioPlayer?.position ?? Duration.zero;
    final totalDur = widget.audioPlayer?.duration ?? const Duration(seconds: 15);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
          _resetControlsTimer();
        },
        onDoubleTap: () {
          setState(() {
            _isFavorited = !_isFavorited;
          });
          PremiumToast.show(context, _isFavorited ? 'Đã thêm vào bài hát yêu thích!' : 'Đã xóa khỏi bài hát yêu thích!');
          _triggerHeartAnimation();
        },
        onScaleStart: (details) {
          _baseFontSize = _lyricFontSize;
        },
        onScaleUpdate: (details) {
          setState(() {
            _lyricFontSize = (_baseFontSize * details.scale).clamp(14.0, 36.0);
          });
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.primaryDelta ?? 0.0;
          });
        },
        onVerticalDragEnd: (details) {
          if (_dragOffset > 100.0 || (details.primaryVelocity != null && details.primaryVelocity! > 300.0)) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              _dragOffset = 0.0;
            });
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: widget.coverUrl.isNotEmpty
                  ? Image.network(
                      widget.coverUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(color: const Color(0xFF1E1C30)),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.75),
                ),
              ),
            ),
            Positioned.fill(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white70))
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        )
                      : isSynced
                          ? SingleChildScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  const SizedBox(height: 240),
                                  ...List.generate(_syncedLyrics.length, (index) {
                                    final line = _syncedLyrics[index];
                                    final isActive = index == _activeIndex;
                                    
                                    final Widget child = isActive
                                        ? KaraokeText(
                                            text: line.text,
                                            progress: _activeLineProgress,
                                            style: TextStyle(
                                              fontSize: _lyricFontSize + 4,
                                              fontWeight: FontWeight.bold,
                                              shadows: const [Shadow(color: Colors.black87, blurRadius: 10)],
                                            ),
                                          )
                                        : Text(
                                            line.text,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.5),
                                              fontSize: _lyricFontSize,
                                              fontWeight: FontWeight.w500,
                                              shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                                            ),
                                            textAlign: TextAlign.center,
                                          );

                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onLongPress: () {
                                        Clipboard.setData(ClipboardData(text: line.text));
                                        PremiumToast.show(context, 'Đã sao chép: "${line.text}"');
                                      },
                                      child: Container(
                                        key: _lineKeys[index],
                                        width: double.infinity,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 28.0),
                                        child: isActive
                                            ? child
                                            : ImageFiltered(
                                                imageFilter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
                                                child: child,
                                              ),
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 360),
                                ],
                              ),
                            )
                          : Center(
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                                itemCount: _plainLyrics.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Text(
                                      _plainLyrics[index],
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: _lyricFontSize,
                                        fontWeight: FontWeight.w500,
                                        shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.artist,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (_showHeartAnim)
              Center(
                child: AnimatedBuilder(
                  animation: _heartAnimController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _heartOpacityAnim.value,
                      child: Transform.scale(
                        scale: _heartScaleAnim.value,
                        child: child,
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.red,
                    size: 90,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 15),
                    ],
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showControls ? MediaQuery.paddingOf(context).bottom + 20 : -180,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    color: Colors.white.withValues(alpha: 0.08),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(currentPos), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                            Text(_formatDuration(totalDur), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: currentPos.inMilliseconds.toDouble(),
                            max: totalDur.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                            onChanged: (val) {
                              widget.audioPlayer?.seek(Duration(milliseconds: val.toInt()));
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                              onPressed: widget.onPrevious,
                            ),
                            GestureDetector(
                              onTap: () {
                                if (widget.audioPlayer != null) {
                                  if (widget.audioPlayer!.playing) {
                                    widget.audioPlayer!.pause();
                                  } else {
                                    widget.audioPlayer!.play();
                                  }
                                  setState(() {});
                                }
                              },
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  (widget.audioPlayer?.playing ?? false) ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.black87,
                                  size: 32,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                              onPressed: widget.onNext,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KaraokeText extends StatelessWidget {
  final String text;
  final double progress;
  final TextStyle style;

  const KaraokeText({
    super.key,
    required this.text,
    required this.progress,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            style.color ?? Colors.white,
            (style.color ?? Colors.white).withValues(alpha: 0.35),
          ],
          stops: [progress, progress],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
