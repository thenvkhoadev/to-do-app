import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/social/presentation/providers/story_state_providers.dart';
import 'package:to_do_app/features/social/presentation/providers/story_provider.dart';
import 'package:to_do_app/features/social/data/models/story_model.dart';
import 'package:to_do_app/features/social/presentation/widgets/story_privacy_modal.dart';
import 'package:to_do_app/features/social/presentation/widgets/story_music_dialog.dart';
import 'package:to_do_app/features/social/presentation/widgets/draggable_overlay.dart';
import 'package:to_do_app/features/social/presentation/widgets/premium_toast.dart';

class StoryCreatorView extends ConsumerStatefulWidget {
  const StoryCreatorView({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<StoryCreatorView> createState() => _StoryCreatorViewState();
}

class _StoryCreatorViewState extends ConsumerState<StoryCreatorView> {
  bool _expandBackgrounds = false;
  bool _showMusicDialog = false;
  bool _showAltTextPanel = false;
  bool _showColorPicker = false;
  String? _selectedOverlayId; // Currently active text overlay
  
  // For text story emoji picker
  bool _showEmojiPicker = false;
  
  // Video Story preview controller
  VideoPlayerController? _videoPlayerController;
  String? _currentVideoPath;

  // Unified audio player for the editor
  late final AudioPlayer _audioPlayer;
  StreamSubscription<Duration>? _audioPositionSubscription;

  final TextEditingController _textStoryController = TextEditingController();
  final FocusNode _textStoryFocus = FocusNode();

  final TextEditingController _overlayTextController = TextEditingController();
  final FocusNode _overlayTextFocus = FocusNode();

  final TextEditingController _altTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _textStoryController.addListener(() {
      ref.read(storyCreatorProvider.notifier).setText(_textStoryController.text);
    });

    _audioPositionSubscription = _audioPlayer.positionStream.listen((position) {
      final state = ref.read(storyCreatorProvider);
      if (state != null && state.musicOverlay != null && state.musicOverlay!.audioUrl.isNotEmpty) {
        final overlay = state.musicOverlay!;
        final startMs = overlay.startTimeSec * 1000;
        final durationMs = overlay.durationSec * 1000;
        final endMs = startMs + durationMs;
        
        if (position.inMilliseconds >= endMs) {
          _audioPlayer.seek(Duration(milliseconds: startMs));
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPositionSubscription?.cancel();
    _audioPlayer.dispose();
    _textStoryController.dispose();
    _textStoryFocus.dispose();
    _overlayTextController.dispose();
    _overlayTextFocus.dispose();
    _altTextController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    final state = ref.read(storyCreatorProvider);
    if (state == null) return true;
    if (state.screenType == CreatorScreenType.select) return true;
    
    bool hasChanges = false;
    if (state.screenType == CreatorScreenType.text) {
      hasChanges = state.text.trim().isNotEmpty || state.musicOverlay != null;
    } else if (state.screenType == CreatorScreenType.image) {
      hasChanges = state.imageFile != null || state.textOverlays.isNotEmpty || state.musicOverlay != null;
    } else if (state.screenType == CreatorScreenType.video) {
      hasChanges = state.videoFile != null || state.textOverlays.isNotEmpty || state.musicOverlay != null;
    }

    if (!hasChanges) return true;

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
    return leave ?? false;
  }

  Future<void> _initVideoPlayer(String path) async {
    if (_videoPlayerController != null) {
      await _videoPlayerController!.dispose();
    }
    
    if (kIsWeb) {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(path));
    } else {
      _videoPlayerController = VideoPlayerController.file(File(path));
    }

    try {
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setLooping(true);
      await _videoPlayerController!.play();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading video preview: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        ref.read(storyCreatorProvider.notifier).setImageFile(image);
        _altTextController.text = "Có vẻ là một hình ảnh đẹp từ thiết bị"; // default AI text
      }
    } catch (e) {
      PremiumToast.show(context, 'Lỗi chọn ảnh: $e', isError: true);
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    try {
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        ref.read(storyCreatorProvider.notifier).setVideoFile(video);
      }
    } catch (e) {
      PremiumToast.show(context, 'Lỗi chọn video: $e', isError: true);
    }
  }

  void _openPrivacySettings() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const StoryPrivacyModal(),
    );
    if (result != null) {
      PremiumToast.show(context, 'Đã cập nhật quyền riêng tư: $result');
    }
  }

  Future<void> _shareStory() async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;

    final state = ref.read(storyCreatorProvider);
    if (state == null) return;
    final service = ref.read(storyServiceProvider);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      if (state.screenType == CreatorScreenType.text) {
        // Publish Text Story
        final autoData = {
          'text': state.text,
          'fontFamily': state.fontFamily,
          'backgroundColorIndex': state.backgroundColorIndex,
        };
        if (state.musicOverlay != null) {
          autoData['music'] = state.musicOverlay!.toJson();
        }

        await service.createStory(
          authorId: currentUser.id,
          contentType: StoryContentType.text,
          autoData: autoData,
        );
      } else if (state.screenType == CreatorScreenType.image && state.imageFile != null) {
        // Upload photo and Publish Image Story
        final mediaUrl = await service.uploadStoryPhoto(currentUser.id, state.imageFile!);
        
        final autoData = <String, dynamic>{
          'zoom': state.zoom,
          'rotation': state.rotation,
          'panX': state.panX,
          'panY': state.panY,
          'altText': state.altText,
          'imageFit': state.imageFit.name,
        };

        if (state.textOverlays.isNotEmpty) {
          autoData['textOverlays'] = state.textOverlays.map((o) => o.toJson()).toList();
        }

        if (state.musicOverlay != null) {
          autoData['music'] = state.musicOverlay!.toJson();
        }

        await service.createStory(
          authorId: currentUser.id,
          contentType: StoryContentType.photo,
          mediaUrl: mediaUrl,
          autoData: autoData,
        );
      } else if (state.screenType == CreatorScreenType.video && state.videoFile != null) {
        // Upload video and Publish Video Story
        final mediaUrl = await service.uploadStoryVideo(currentUser.id, state.videoFile!);
        
        final autoData = <String, dynamic>{
          'altText': state.altText,
        };

        if (state.textOverlays.isNotEmpty) {
          autoData['textOverlays'] = state.textOverlays.map((o) => o.toJson()).toList();
        }

        if (state.musicOverlay != null) {
          autoData['music'] = state.musicOverlay!.toJson();
        }

        await service.createStory(
          authorId: currentUser.id,
          contentType: StoryContentType.video,
          mediaUrl: mediaUrl,
          autoData: autoData,
        );
      }

      // Close loading & view
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ref.read(storyCreatorProvider.notifier).reset();
        widget.onClose();
        PremiumToast.show(context, 'Đã chia sẻ tin thành công!');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        PremiumToast.show(context, 'Lỗi đăng tin: $e', isError: true);
      }
    }
  }

  void _addTextOverlay() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final overlay = TextOverlay(
      id: id,
      text: 'Chạm để sửa',
      color: Colors.white,
      x: 0.5,
      y: 0.4,
      scale: 1.0,
    );
    ref.read(storyCreatorProvider.notifier).addTextOverlay(overlay);
    setState(() {
      _selectedOverlayId = id;
      _overlayTextController.text = 'Chạm để sửa';
      _showColorPicker = true;
      _showAltTextPanel = false;
      _showMusicDialog = false;
    });
  }

  int _getMaxMusicDuration(StoryCreatorState creatorState) {
    if (creatorState.screenType == CreatorScreenType.video) {
      if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
        final videoDurSec = _videoPlayerController!.value.duration.inSeconds;
        return videoDurSec.clamp(5, 90);
      }
      return 90;
    }
    return 30;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final creatorState = ref.watch(storyCreatorProvider);

    ref.listen<StoryCreatorState?>(storyCreatorProvider, (oldState, newState) async {
      if (newState == null) {
        await _audioPlayer.stop();
        return;
      }
      final oldOverlay = oldState?.musicOverlay;
      final newOverlay = newState.musicOverlay;
      if (newOverlay != oldOverlay) {
        if (newOverlay == null || newOverlay.audioUrl.isEmpty) {
          await _audioPlayer.stop();
        } else if (oldOverlay?.audioUrl != newOverlay.audioUrl) {
          try {
            await _audioPlayer.stop();
            await _audioPlayer.setUrl(newOverlay.audioUrl);
            await _audioPlayer.setVolume(newOverlay.volume);
            await _audioPlayer.seek(Duration(seconds: newOverlay.startTimeSec));
            await _audioPlayer.play();
          } catch (e) {
            debugPrint('Error playing music in editor: $e');
          }
        } else {
          await _audioPlayer.setVolume(newOverlay.volume);
          if (oldOverlay?.startTimeSec != newOverlay.startTimeSec) {
            await _audioPlayer.seek(Duration(seconds: newOverlay.startTimeSec));
          }
        }
      }
    });

    if (creatorState != null && creatorState.screenType == CreatorScreenType.video && creatorState.videoFile != null) {
      final newPath = creatorState.videoFile!.path;
      if (_currentVideoPath != newPath) {
        _currentVideoPath = newPath;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initVideoPlayer(newPath);
        });
      }
    } else {
      if (_currentVideoPath != null) {
        _currentVideoPath = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _videoPlayerController?.dispose();
          _videoPlayerController = null;
          if (mounted) setState(() {});
        });
      }
    }

    if (creatorState == null) return const SizedBox.shrink();
    final userProfile = ref.watch(userProfileProvider).valueOrNull;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1200;

    final Widget layoutBody;
    if (!isDesktop) {
      layoutBody = _buildMobileLayout(context, creatorState, userProfile);
    } else {
      layoutBody = Row(
        children: [
          // 1. LEFT SIDEBAR (width 360px)
          Container(
            width: 360,
            color: const Color(0xFF1C1A2E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sidebar Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        onPressed: () async {
                          if (await _confirmDiscard()) {
                            ref.read(storyCreatorProvider.notifier).reset();
                            widget.onClose();
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tin của bạn',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openPrivacySettings,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .1),
                          ),
                          child: const Icon(Icons.settings, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // User Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: (userProfile?.avatarUrl != null && userProfile!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(userProfile.avatarUrl!)
                            : null,
                        backgroundColor: Colors.grey.shade800,
                        child: (userProfile?.avatarUrl == null || userProfile!.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        userProfile?.fullName ?? userProfile?.username ?? 'Vu Khoa',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 24),

                // Creator controls area based on screen type
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildSidebarControls(creatorState),
                  ),
                ),

                // Footer Action Buttons
                if (creatorState.screenType != CreatorScreenType.select)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              if (await _confirmDiscard()) {
                                ref.read(storyCreatorProvider.notifier).reset();
                                setState(() {
                                  _selectedOverlayId = null;
                                  _showMusicDialog = false;
                                  _showAltTextPanel = false;
                                  _showColorPicker = false;
                                });
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Bỏ', style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _shareStory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C5CFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Chia sẻ lên tin', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Vertical divider
          Container(width: 1, color: Colors.white12),

          // 2. CENTER PREVIEW AREA & RIGHT PANEL
          Expanded(
            child: Container(
              color: const Color(0xFF0E0D16),
              child: Row(
                children: [
                  // Center Canvas
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCanvasPreview(creatorState),
                        
                        // Under-canvas controls (only for image creator)
                        if (creatorState.screenType == CreatorScreenType.image && creatorState.imageFile != null)
                          _buildImageControls(creatorState),
                      ],
                    ),
                  ),

                  // Right Panel (e.g. Color Picker, Alt Text Panel, Music Dialog)
                  if (_showColorPicker || _showAltTextPanel || _showMusicDialog) ...[
                    Container(width: 1, color: Colors.white10),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: _buildRightPanel(creatorState),
                    ),
                    const SizedBox(width: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        layoutBody,
        if (_showMusicDialog && !isDesktop)
          Positioned.fill(
            child: Material(
              color: Colors.black.withValues(alpha: .5),
              child: StoryMusicDialog(
                audioPlayer: _audioPlayer,
                onSongSelected: (song) {
                  final maxDur = _getMaxMusicDuration(creatorState);
                  final defaultDur = song.durationSec < maxDur ? song.durationSec : maxDur;
                  final overlay = MusicOverlay(
                    title: song.title,
                    artist: song.artist,
                    coverUrl: song.coverUrl,
                    audioUrl: song.audioUrl,
                    startTimeSec: 0,
                    durationSec: defaultDur,
                    layoutStyle: 6, // Style 6: Only music (no card overlay)
                  );
                  ref.read(storyCreatorProvider.notifier).setMusicOverlay(overlay);
                  setState(() {
                    _showMusicDialog = false;
                    _selectedOverlayId = 'music';
                  });
                  PremiumToast.show(context, 'Đã chọn bài: ${song.title}');
                },
                onClose: () {
                  setState(() {
                    _showMusicDialog = false;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  // BUILDER: Left Sidebar Controls based on Screen Type
  Widget _buildSidebarControls(StoryCreatorState creatorState) {
    switch (creatorState.screenType) {
      case CreatorScreenType.select:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Chọn loại tin bạn muốn đăng để bắt đầu chia sẻ những khoảnh khắc năng suất của bạn.',
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
          ),
        );

      case CreatorScreenType.text:
        final fontList = ['Gọn Gàng', 'Bình Thường', 'Kiểu Cách', 'Tiêu Đề'];
        final gradients = ref.watch(storyGradientsList);
        final visibleGradientsCount = _expandBackgrounds ? gradients.length : 14;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Font Select trigger dropdown (image6)
              const Text('PHÔNG CHỮ', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF2D2D2D),
                    value: creatorState.fontFamily,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    borderRadius: BorderRadius.circular(8),
                    items: fontList.map((String font) {
                      final isActive = creatorState.fontFamily == font;
                      return DropdownMenuItem<String>(
                        value: font,
                        child: Row(
                          children: [
                            if (isActive)
                              const Icon(Icons.check, color: Color(0xFF7C5CFF), size: 16)
                            else
                              const SizedBox(width: 16),
                            const SizedBox(width: 8),
                            Text(
                              font,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(storyCreatorProvider.notifier).setFontFamily(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Background swatches grid (image5 & image7)
              const Text('PHÔNG NỀN', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Màu chuyển sắc', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              
              // Swatches Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: visibleGradientsCount,
                itemBuilder: (context, index) {
                  final gradient = gradients[index];
                  final isSelected = creatorState.backgroundColorIndex == index;

                  return GestureDetector(
                    onTap: () {
                      ref.read(storyCreatorProvider.notifier).setBackgroundColorIndex(index);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: gradient,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      transform: isSelected ? Matrix4.identity().scaled(1.1) : null,
                    ),
                  );
                },
              ),

              // Expand/collapse button
              Center(
                child: IconButton(
                  icon: Icon(
                    _expandBackgrounds ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white54,
                  ),
                  onPressed: () {
                    setState(() {
                      _expandBackgrounds = !_expandBackgrounds;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Add Music Button
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .06),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white),
                  ),
                  title: const Text(
                    'Thêm nhạc',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  trailing: (creatorState.musicOverlay != null && creatorState.musicOverlay!.audioUrl.isNotEmpty)
                      ? const Icon(Icons.check_circle, color: Color(0xFF7C5CFF), size: 18)
                      : const Icon(Icons.chevron_right, color: Colors.white24),
                  onTap: () {
                    setState(() {
                      _showMusicDialog = !_showMusicDialog;
                      _showColorPicker = false;
                      _showAltTextPanel = false;
                    });
                  },
                ),
              ),
              _buildMusicConfigPanel(creatorState),
            ],
          ),
        );

      case CreatorScreenType.image:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Fit Options (Vừa khung / Đầy màn hình)
              const Text('ĐỊNH DẠNG ẢNH', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(storyCreatorProvider.notifier).setImageFit(ImageFitType.fit);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: creatorState.imageFit == ImageFitType.fit
                              ? const Color(0xFF7C5CFF).withValues(alpha: .2)
                              : Colors.white.withValues(alpha: .04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: creatorState.imageFit == ImageFitType.fit
                                ? const Color(0xFF7C5CFF)
                                : Colors.white24,
                            width: 1.5,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.aspect_ratio_rounded, color: Colors.white),
                            SizedBox(height: 4),
                            Text('Vừa khung (9:16)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(storyCreatorProvider.notifier).setImageFit(ImageFitType.cover);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: creatorState.imageFit == ImageFitType.cover
                              ? const Color(0xFF7C5CFF).withValues(alpha: .2)
                              : Colors.white.withValues(alpha: .04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: creatorState.imageFit == ImageFitType.cover
                                ? const Color(0xFF7C5CFF)
                                : Colors.white24,
                            width: 1.5,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.fullscreen_rounded, color: Colors.white),
                            SizedBox(height: 4),
                            Text('Đầy màn hình', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Option 1: Thêm văn bản
              _buildSidebarOption(
                icon: Icons.title_rounded,
                title: 'Thêm văn bản',
                onTap: _addTextOverlay,
              ),
              const SizedBox(height: 12),

              // Option 2: Thêm nhạc
              _buildSidebarOption(
                icon: Icons.music_note_rounded,
                title: 'Thêm nhạc',
                subtitle: (creatorState.musicOverlay != null && creatorState.musicOverlay!.audioUrl.isNotEmpty) ? creatorState.musicOverlay!.title : null,
                onTap: () {
                  setState(() {
                    _showMusicDialog = !_showMusicDialog;
                    _showColorPicker = false;
                    _showAltTextPanel = false;
                  });
                },
              ),
              _buildMusicConfigPanel(creatorState),
              const SizedBox(height: 12),

              // Option 3: Văn bản thay thế (Alt text)
              _buildSidebarOption(
                icon: Icons.accessibility_new_rounded,
                title: 'Văn bản thay thế',
                onTap: () {
                  setState(() {
                    _showAltTextPanel = !_showAltTextPanel;
                    _showColorPicker = false;
                    _showMusicDialog = false;
                  });
                },
              ),

              if (creatorState.imageFit == ImageFitType.fit) ...[
                const SizedBox(height: 20),
                const Text('PHÔNG NỀN', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: ref.read(storyGradientsList).length,
                    itemBuilder: (context, index) {
                      final gradient = ref.read(storyGradientsList)[index];
                      final isSelected = creatorState.backgroundColorIndex == index;
                      return GestureDetector(
                        onTap: () {
                          ref.read(storyCreatorProvider.notifier).setBackgroundColorIndex(index);
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: gradient,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );

      case CreatorScreenType.video:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Option 1: Thêm văn bản
              _buildSidebarOption(
                icon: Icons.title_rounded,
                title: 'Thêm văn bản',
                onTap: _addTextOverlay,
              ),
              const SizedBox(height: 12),

              // Option 2: Thêm nhạc
              _buildSidebarOption(
                icon: Icons.music_note_rounded,
                title: 'Thêm nhạc',
                subtitle: (creatorState.musicOverlay != null && creatorState.musicOverlay!.audioUrl.isNotEmpty) ? creatorState.musicOverlay!.title : null,
                onTap: () {
                  setState(() {
                    _showMusicDialog = !_showMusicDialog;
                    _showColorPicker = false;
                    _showAltTextPanel = false;
                  });
                },
              ),
              _buildMusicConfigPanel(creatorState),
              
              // Video original volume slider
              const SizedBox(height: 20),
              const Text('ÂM THANH VIDEO', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: .06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Âm lượng Video', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          '${((creatorState.musicOverlay?.originalVolume ?? 1.0) * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                    Slider(
                      value: creatorState.musicOverlay?.originalVolume ?? 1.0,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF7C5CFF),
                      inactiveColor: Colors.white10,
                      onChanged: (val) {
                        final currentOverlay = creatorState.musicOverlay ??
                            MusicOverlay(title: '', artist: '', coverUrl: '', audioUrl: '');
                        ref.read(storyCreatorProvider.notifier).setMusicOverlay(
                              currentOverlay.copyWith(originalVolume: val),
                            );
                        _videoPlayerController?.setVolume(val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildMusicConfigPanel(StoryCreatorState creatorState) {
    if (creatorState.musicOverlay == null || creatorState.musicOverlay!.audioUrl.isEmpty) return const SizedBox.shrink();

    final allSongs = ref.watch(mockSongsProvider).valueOrNull ?? [];
    final currentSong = allSongs.firstWhere(
      (s) => s.audioUrl == creatorState.musicOverlay!.audioUrl,
      orElse: () => StorySong(
        id: '',
        title: creatorState.musicOverlay!.title,
        artist: creatorState.musicOverlay!.artist,
        coverUrl: creatorState.musicOverlay!.coverUrl,
        audioUrl: creatorState.musicOverlay!.audioUrl,
        category: '',
        durationSec: 180,
      ),
    );
    final int songDurationSec = currentSong.durationSec;

    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Playback controls (Play, Pause, Progress Bar, Duration)
            const Text('TRÌNH PHÁT NHẠC', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<PlayerState>(
              stream: _audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final playing = playerState?.playing ?? false;
                return Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                        color: const Color(0xFF7C5CFF),
                        size: 32,
                      ),
                      onPressed: () {
                        if (playing) {
                          _audioPlayer.pause();
                        } else {
                          _audioPlayer.play();
                        }
                      },
                    ),
                    Expanded(
                      child: StreamBuilder<Duration>(
                        stream: _audioPlayer.positionStream,
                        builder: (context, posSnapshot) {
                          final position = posSnapshot.data ?? Duration.zero;
                          final startSec = creatorState.musicOverlay!.startTimeSec;
                          final durSec = creatorState.musicOverlay!.durationSec;
                          
                          // Calculate relative position within the segment
                          final relativeMs = (position.inMilliseconds - startSec * 1000).clamp(0, durSec * 1000);
                          final double value = durSec > 0 ? (relativeMs / (durSec * 1000)) : 0.0;
                          
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                ),
                                child: Slider(
                                  value: value,
                                  activeColor: const Color(0xFF7C5CFF),
                                  inactiveColor: Colors.white10,
                                  onChanged: (val) {
                                    final targetMs = (startSec * 1000) + (val * durSec * 1000);
                                    _audioPlayer.seek(Duration(milliseconds: targetMs.toInt()));
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatTime(relativeMs ~/ 1000), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                    Text('${durSec}s', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Start position slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bắt đầu từ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  _formatTime(creatorState.musicOverlay!.startTimeSec),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            Slider(
              value: creatorState.musicOverlay!.startTimeSec.toDouble(),
              min: 0.0,
              max: (songDurationSec - creatorState.musicOverlay!.durationSec).toDouble().clamp(0.0, songDurationSec.toDouble()),
              activeColor: const Color(0xFF7C5CFF),
              inactiveColor: Colors.white10,
              onChanged: (val) {
                ref.read(storyCreatorProvider.notifier).setMusicOverlay(
                      creatorState.musicOverlay!.copyWith(startTimeSec: val.toInt()),
                    );
              },
            ),
            const SizedBox(height: 12),

            // Duration slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Thời lượng phát', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  '${creatorState.musicOverlay!.durationSec} giây',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            Slider(
              value: creatorState.musicOverlay!.durationSec.toDouble(),
              min: 5.0,
              max: _getMaxMusicDuration(creatorState).toDouble(),
              activeColor: const Color(0xFF7C5CFF),
              inactiveColor: Colors.white10,
              onChanged: (val) {
                final newDuration = val.toInt();
                int newStart = creatorState.musicOverlay!.startTimeSec;
                if (newStart + newDuration > songDurationSec) {
                  newStart = (songDurationSec - newDuration).clamp(0, songDurationSec);
                }
                ref.read(storyCreatorProvider.notifier).setMusicOverlay(
                      creatorState.musicOverlay!.copyWith(
                        durationSec: newDuration,
                        startTimeSec: newStart,
                      ),
                    );
              },
            ),
            const SizedBox(height: 12),

            // Music volume
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Âm lượng Nhạc', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${(creatorState.musicOverlay!.volume * 100).toInt()}%', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
            Slider(
              value: creatorState.musicOverlay!.volume,
              min: 0.0,
              max: 1.0,
              activeColor: const Color(0xFF7C5CFF),
              inactiveColor: Colors.white10,
              onChanged: (val) {
                ref.read(storyCreatorProvider.notifier).setMusicOverlay(
                      creatorState.musicOverlay!.copyWith(volume: val),
                    );
              },
            ),
            const SizedBox(height: 12),
            const Text('KIỂU HIỂN THỊ THẺ NHẠC',
                style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(8, (index) {
                final isActive = creatorState.musicOverlay!.layoutStyle == index;
                IconData styleIcon = Icons.portrait_rounded;
                if (index == 1) styleIcon = Icons.developer_board_rounded;
                if (index == 2) styleIcon = Icons.splitscreen_rounded;
                if (index == 3) styleIcon = Icons.album_rounded;
                if (index == 4) styleIcon = Icons.format_align_center_rounded;
                if (index == 5) styleIcon = Icons.equalizer_rounded;
                if (index == 6) styleIcon = Icons.waves_rounded;
                if (index == 7) styleIcon = Icons.music_note_rounded;

                return GestureDetector(
                  onTap: () {
                    ref.read(storyCreatorProvider.notifier).setMusicOverlay(
                          creatorState.musicOverlay!.copyWith(layoutStyle: index),
                        );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: isActive ? .15 : .06),
                      border: Border.all(
                        color: isActive ? const Color(0xFF7C5CFF) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        styleIcon,
                        color: isActive ? const Color(0xFF7C5CFF) : Colors.white70,
                        size: 16,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF7C5CFF), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }

  // BUILDER: Canvas Story Preview (Aspect ratio 9/16)
  Widget _buildCanvasPreview(StoryCreatorState creatorState) {
    if (creatorState.screenType == CreatorScreenType.select) {
      // 3 Cards layout for choosing types (image3)
      return Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Card: Image Creator
              _buildTypeCard(
                title: 'Tạo tin dạng ảnh',
                subtitle: 'Chọn hình ảnh để thêm văn bản, nhạc',
                colors: [const Color(0xFF6EC6F5), const Color(0xFF4A90E2)],
                icon: Icons.image_outlined,
                onTap: _pickImage,
              ),
              const SizedBox(width: 24),
              // Card: Video Creator
              _buildTypeCard(
                title: 'Tạo tin dạng video',
                subtitle: 'Chọn video từ thiết bị của bạn',
                colors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                icon: Icons.video_library_rounded,
                onTap: _pickVideo,
              ),
              const SizedBox(width: 24),
              // Card: Text Creator
              _buildTypeCard(
                title: 'Tạo tin dạng văn bản',
                subtitle: 'Gõ chữ trên nền màu chuyển sắc',
                colors: [const Color(0xFFC678DD), const Color(0xFFE96FA0)],
                icon: Icons.title_rounded,
                onTap: () {
                  ref.read(storyCreatorProvider.notifier).setScreenType(CreatorScreenType.text);
                },
              ),
            ],
          ),
        ),
      );
    }

    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double canvasHeight = (screenHeight - 180).clamp(320.0, 520.0);
    final double canvasWidth = canvasHeight * (9 / 16);

    Widget background;

    if (creatorState.screenType == CreatorScreenType.text) {
      // Background gradient based on selected index
      final gradients = ref.read(storyGradientsList);
      background = Container(
        decoration: BoxDecoration(
          gradient: gradients[creatorState.backgroundColorIndex],
        ),
      );
    } else if (creatorState.screenType == CreatorScreenType.video) {
      if (creatorState.videoFile != null && _videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
        background = Center(
          child: AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          ),
        );
      } else {
        background = const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
    } else {
      // Background Image
      if (creatorState.imageFile != null) {
        final transform = Matrix4.identity()
          ..translate(creatorState.panX, creatorState.panY)
          ..rotateZ(creatorState.rotation * math.pi / 180)
          ..scale(creatorState.zoom);

        final isCover = creatorState.imageFit == ImageFitType.cover;
        final fit = isCover ? BoxFit.cover : BoxFit.contain;
        final gradients = ref.read(storyGradientsList);

        background = Container(
          decoration: BoxDecoration(
            gradient: !isCover ? gradients[creatorState.backgroundColorIndex] : null,
            color: isCover ? null : const Color(0xFF1E1E1E),
          ),
          child: ClipRect(
            child: Transform(
              transform: transform,
              alignment: Alignment.center,
              child: kIsWeb
                  ? Image.network(
                      creatorState.imageFile!.path,
                      width: double.infinity,
                      height: double.infinity,
                      fit: fit,
                    )
                  : Image.file(
                      File(creatorState.imageFile!.path),
                      width: double.infinity,
                      height: double.infinity,
                      fit: fit,
                    ),
            ),
          ),
        );
      } else {
        background = Container(color: Colors.grey.shade900);
      }
    }

    return Container(
      width: canvasWidth,
      height: canvasHeight,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 1. Background (Image or Gradient)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_showEmojiPicker) {
                    setState(() {
                      _showEmojiPicker = false;
                    });
                  }
                },
                child: background,
              ),
            ),

            // 2. Interactive text box for Text Story (centered blinking cursor field)
            if (creatorState.screenType == CreatorScreenType.text)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _textStoryController,
                    focusNode: _textStoryFocus,
                    maxLines: null,
                    textAlign: TextAlign.center,
                    cursorColor: Colors.white,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: creatorState.fontFamily == 'Tiêu Đề' ? FontWeight.w900 : FontWeight.bold,
                      fontFamily: creatorState.fontFamily == 'Bình Thường'
                          ? 'sans-serif'
                          : creatorState.fontFamily == 'Kiểu Cách'
                              ? 'Georgia'
                              : 'monospace',
                      shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Bắt đầu nhập',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

            // 3. Render Draggable Text Overlays (only for Image & Video Creator)
            if (creatorState.screenType == CreatorScreenType.image || creatorState.screenType == CreatorScreenType.video)
              ...creatorState.textOverlays.map((overlay) {
                final isSelected = _selectedOverlayId == overlay.id;
                return DraggableTextOverlayWidget(
                  overlay: overlay,
                  canvasWidth: canvasWidth,
                  canvasHeight: canvasHeight,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedOverlayId = overlay.id;
                      _overlayTextController.text = overlay.text;
                      _showColorPicker = true;
                      _showAltTextPanel = false;
                    });
                  },
                  onUpdate: (updated) {
                    ref.read(storyCreatorProvider.notifier).updateTextOverlay(updated);
                  },
                  onDelete: () {
                    ref.read(storyCreatorProvider.notifier).removeTextOverlay(overlay.id);
                    setState(() {
                      if (_selectedOverlayId == overlay.id) {
                        _selectedOverlayId = null;
                        _showColorPicker = false;
                      }
                    });
                  },
                );
              }),

            // 4. Render Draggable Music Overlay Card (if selected)
            if (creatorState.musicOverlay != null && creatorState.musicOverlay!.audioUrl.isNotEmpty) ...[
              DraggableMusicOverlayWidget(
                overlay: creatorState.musicOverlay!,
                canvasWidth: canvasWidth,
                canvasHeight: canvasHeight,
                isSelected: _selectedOverlayId == 'music',
                onTap: () {
                  setState(() {
                    _selectedOverlayId = 'music';
                    _showColorPicker = true;
                    _showAltTextPanel = false;
                    _showMusicDialog = false;
                  });
                },
                onUpdate: (updated) {
                  ref.read(storyCreatorProvider.notifier).setMusicOverlay(updated);
                },
                onDelete: () {
                  ref.read(storyCreatorProvider.notifier).setMusicOverlay(null);
                  setState(() {
                    if (_selectedOverlayId == 'music') {
                      _selectedOverlayId = null;
                    }
                  });
                },
              ),
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOverlayId = 'music';
                      _showColorPicker = true;
                      _showAltTextPanel = false;
                      _showMusicDialog = false;
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.music_note_rounded, color: Color(0xFF7C5CFF), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${creatorState.musicOverlay!.title} - ${creatorState.musicOverlay!.artist}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // 5. Text story emoji button 😊 (bottom-right)
            if (creatorState.screenType == CreatorScreenType.text)
              Positioned(
                bottom: 12,
                right: 12,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showEmojiPicker = !_showEmojiPicker;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black26,
                      ),
                      child: const Text('😊', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
              ),

            // Emoji Selection Bubble Popup
            if (_showEmojiPicker && creatorState.screenType == CreatorScreenType.text)
              Positioned(
                bottom: 50,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242526),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                  ),
                  child: Row(
                    children: ['👍', '❤️', '😍', '😂', '😮', '😢', '🔥'].map((emoji) {
                      return GestureDetector(
                        onTap: () {
                          final cursorVal = _textStoryController.text;
                          _textStoryController.text = cursorVal + emoji;
                          setState(() {
                            _showEmojiPicker = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(emoji, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // BUILDER: Image Zoom / Rotate / Pan Controls (image12)
  Widget _buildImageControls(StoryCreatorState creatorState) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Zoom Slider and Rotate [⟲ Xoay] Row
          Row(
            children: [
              const Icon(Icons.remove, color: Colors.white30, size: 16),
              Expanded(
                child: Slider(
                  value: creatorState.zoom,
                  min: 1.0,
                  max: 3.0,
                  activeColor: const Color(0xFF7C5CFF),
                  inactiveColor: Colors.white24,
                  onChanged: (val) {
                    ref.read(storyCreatorProvider.notifier).setZoom(val);
                  },
                ),
              ),
              const Icon(Icons.add, color: Colors.white30, size: 16),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final newRotation = (creatorState.rotation + 90) % 360;
                  ref.read(storyCreatorProvider.notifier).setRotation(newRotation);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.rotate_left_rounded, size: 14),
                label: const Text('Xoay', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

          // Custom horizontal scroll / pan simulation track
          if (creatorState.zoom > 1.0) ...[
            const SizedBox(height: 6),
            const Text(
              'Drag image in the preview to pan',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onPanUpdate: (details) {
                final double px = (creatorState.panX + details.delta.dx).clamp(-100.0, 100.0);
                final double py = (creatorState.panY + details.delta.dy).clamp(-100.0, 100.0);
                ref.read(storyCreatorProvider.notifier).setPan(px, py);
              },
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C5CFF),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // BUILDER: Right drawer panel (image8 / image13 / image15)
  Widget _buildRightPanel(StoryCreatorState creatorState) {
    if (_showMusicDialog) {
      return Container(
        width: 360,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: StoryMusicDialog(
            audioPlayer: _audioPlayer,
            isInline: true,
            onSongSelected: (song) {
              final maxDur = _getMaxMusicDuration(creatorState);
              final defaultDur = song.durationSec < maxDur ? song.durationSec : maxDur;
              final overlay = MusicOverlay(
                title: song.title,
                artist: song.artist,
                coverUrl: song.coverUrl,
                audioUrl: song.audioUrl,
                startTimeSec: 0,
                durationSec: defaultDur,
                layoutStyle: 6, // Default to audio-only
              );
              ref.read(storyCreatorProvider.notifier).setMusicOverlay(overlay);
              setState(() {
                _showMusicDialog = false;
                _selectedOverlayId = 'music';
              });
              PremiumToast.show(context, 'Đã chọn bài: ${song.title}');
            },
            onClose: () {
              setState(() {
                _showMusicDialog = false;
              });
            },
          ),
        ),
      );
    }

    if (_showColorPicker && _selectedOverlayId != null) {
      final textColors = [
        Colors.white,
        Colors.black,
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.purple,
        Colors.pink,
        Colors.teal,
        Colors.amber,
        Colors.cyan,
        Colors.deepOrange,
        Colors.indigo,
        Colors.lime,
        Colors.lightBlue,
        Colors.deepPurple,
        Colors.brown,
        Colors.grey,
        Colors.blueGrey,
        const Color(0xFF7C5CFF),
      ];

      final hasTextOverlay = creatorState.textOverlays.any((o) => o.id == _selectedOverlayId);
      final isText = _selectedOverlayId != 'music' && hasTextOverlay;
      final TextOverlay? activeTextOverlay = isText
          ? creatorState.textOverlays.firstWhere((o) => o.id == _selectedOverlayId)
          : null;

      return Container(
        width: MediaQuery.sizeOf(context).width >= 600 ? 320 : double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF242526),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isText ? 'Chỉnh sửa chữ' : 'Chỉnh sửa nhạc',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                  onPressed: () => setState(() => _showColorPicker = false),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 16),

            if (isText && activeTextOverlay != null) ...[
              // Input Field
              const Text('VĂN BẢN', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _overlayTextController,
                focusNode: _overlayTextFocus,
                onChanged: (val) {
                  ref.read(storyCreatorProvider.notifier).updateTextOverlay(
                        activeTextOverlay.copyWith(text: val),
                      );
                },
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .06),
                  hintText: 'Nhập nội dung...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 16),

              // Color Swatches
              const Text('MÀU CHỮ', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: textColors.map((color) {
                  final isSelected = activeTextOverlay.color == color;
                  return GestureDetector(
                    onTap: () {
                      ref.read(storyCreatorProvider.notifier).updateTextOverlay(
                            activeTextOverlay.copyWith(color: color),
                          );
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            if (!isText && creatorState.musicOverlay != null) ...[
              // Song details card matching Image 2
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: .06)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        creatorState.musicOverlay!.coverUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.music_note_rounded, color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            creatorState.musicOverlay!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            creatorState.musicOverlay!.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(storyCreatorProvider.notifier).setMusicOverlay(null);
                        setState(() {
                          _selectedOverlayId = null;
                          _showColorPicker = false;
                        });
                      },
                      child: const Text('Gỡ', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Choose music card visual style (image17)
              const Text('KIỂU HIỂN THỊ THẺ NHẠC',
                  style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(4, (index) {
                  final isActive = creatorState.musicOverlay!.layoutStyle == index;
                  IconData styleIcon = Icons.portrait_rounded;
                  if (index == 1) styleIcon = Icons.developer_board_rounded;
                  if (index == 2) styleIcon = Icons.splitscreen_rounded;
                  if (index == 3) styleIcon = Icons.horizontal_rule_rounded;

                  return GestureDetector(
                    onTap: () {
                      ref.read(storyCreatorProvider.notifier).setMusicOverlay(
                            creatorState.musicOverlay!.copyWith(layoutStyle: index),
                          );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: isActive ? .15 : .06),
                        border: Border.all(
                          color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          styleIcon,
                          color: isActive ? const Color(0xFF3B82F6) : Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      );
    }

    if (_showAltTextPanel) {
      return Container(
        width: MediaQuery.sizeOf(context).width >= 600 ? 320 : double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.accessibility_new_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Văn bản thay thế',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                  onPressed: () => setState(() => _showAltTextPanel = false),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 16),
            const Text(
              'Sử dụng văn bản thay thế đã tạo cho ảnh này hoặc thêm văn bản thay thế tuỳ chỉnh:',
              style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Option 1: AI auto text
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Có thể là hình ảnh về một hoặc nhiều người, đám cưới và bãi biển',
                  style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.3),
                ),
                trailing: Radio<bool>(
                  value: true,
                  groupValue: creatorState.isAltTextAI,
                  activeColor: const Color(0xFF7C5CFF),
                  onChanged: (val) {
                    ref.read(storyCreatorProvider.notifier).setAltText(
                          'Có thể là hình ảnh về một hoặc nhiều người, đám cưới và bãi biển',
                          true,
                        );
                  },
                ),
              ),
            ),
            const Divider(color: Colors.white10),

            // Option 2: Custom Text Area
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Văn bản thay thế tuỳ chỉnh', style: TextStyle(color: Colors.white70, fontSize: 13)),
                trailing: Radio<bool>(
                  value: false,
                  groupValue: creatorState.isAltTextAI,
                  activeColor: const Color(0xFF7C5CFF),
                  onChanged: (val) {
                    ref.read(storyCreatorProvider.notifier).setAltText(
                          _altTextController.text,
                          false,
                        );
                  },
                ),
              ),
            ),

            if (!creatorState.isAltTextAI) ...[
              const SizedBox(height: 6),
              TextField(
                controller: _altTextController,
                maxLines: 3,
                onChanged: (val) {
                  ref.read(storyCreatorProvider.notifier).setAltText(val, false);
                },
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Nhập mô tả hình ảnh...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF7C5CFF), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF7C5CFF), width: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // Type Selector Card Builder (image3)
  Widget _buildTypeCard({
    required String title,
    required String subtitle,
    required List<Color> colors,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 260,
          height: 380,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black38,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, StoryCreatorState creatorState, UserProfileModel? userProfile) {
    if (creatorState.screenType == CreatorScreenType.select) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0E17),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onClose,
          ),
          title: const Text(
            'Tạo tin mới',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _openPrivacySettings,
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTypeCard(
                  title: 'Tạo tin dạng ảnh',
                  subtitle: 'Chọn hình ảnh để thêm văn bản, nhạc',
                  colors: [const Color(0xFF6EC6F5), const Color(0xFF4A90E2)],
                  icon: Icons.image_outlined,
                  onTap: _pickImage,
                ),
                const SizedBox(height: 24),
                _buildTypeCard(
                  title: 'Tạo tin dạng video',
                  subtitle: 'Chọn video từ thiết bị của bạn',
                  colors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                  icon: Icons.video_library_rounded,
                  onTap: _pickVideo,
                ),
                const SizedBox(height: 24),
                _buildTypeCard(
                  title: 'Tạo tin dạng văn bản',
                  subtitle: 'Gõ chữ trên nền màu chuyển sắc',
                  colors: [const Color(0xFFC678DD), const Color(0xFFE96FA0)],
                  icon: Icons.title_rounded,
                  onTap: () {
                    ref.read(storyCreatorProvider.notifier).setScreenType(CreatorScreenType.text);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }


    if (creatorState.screenType == CreatorScreenType.text) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0E17),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _confirmDiscard()) {
                ref.read(storyCreatorProvider.notifier).startCreating();
              }
            },
          ),
          title: const Text('Tạo tin văn bản', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildCanvasPreview(creatorState),
                  ),
                ),
              ),
            ),
            Container(
              color: const Color(0xFF1C1A2E),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildFontDropdownMobile(creatorState),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showMusicDialog = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: creatorState.musicOverlay != null ? const Color(0xFF7C5CFF) : Colors.white.withValues(alpha: .06),
                          ),
                          child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('PHÔNG NỀN', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildSwatchesRowMobile(creatorState),
                  const SizedBox(height: 16),
                  _buildMobileFooterActions(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Image Creator
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            if (await _confirmDiscard()) {
              ref.read(storyCreatorProvider.notifier).startCreating();
            }
          },
        ),
        title: const Text('Tạo tin ảnh', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildCanvasPreview(creatorState),
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  top: 24,
                  child: Column(
                    children: [
                      _buildFloatingCircleButton(
                        icon: Icons.title_rounded,
                        onTap: _addTextOverlay,
                      ),
                      const SizedBox(height: 12),
                      _buildFloatingCircleButton(
                        icon: Icons.music_note_rounded,
                        active: creatorState.musicOverlay != null,
                        onTap: () {
                          setState(() {
                            _showMusicDialog = true;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFloatingCircleButton(
                        icon: Icons.accessibility_new_rounded,
                        onTap: () {
                          setState(() {
                            _showAltTextPanel = true;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFloatingCircleButton(
                        icon: creatorState.imageFit == ImageFitType.fit
                            ? Icons.aspect_ratio_rounded
                            : Icons.fullscreen_rounded,
                        onTap: () {
                          final newFit = creatorState.imageFit == ImageFitType.fit
                              ? ImageFitType.cover
                              : ImageFitType.fit;
                          ref.read(storyCreatorProvider.notifier).setImageFit(newFit);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showColorPicker || _showAltTextPanel)
            Container(
              color: const Color(0xFF1C1A2E),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _buildRightPanel(creatorState),
            )
          else ...[
            _buildImageControls(creatorState),
            const SizedBox(height: 8),
            Container(
              color: const Color(0xFF1C1A2E),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _buildMobileFooterActions(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingCircleButton({required IconData icon, bool active = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0xFF7C5CFF) : Colors.black54,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildFontDropdownMobile(StoryCreatorState creatorState) {
    final fontList = ['Gọn Gàng', 'Bình Thường', 'Kiểu Cách', 'Tiêu Đề'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF2D2D2D),
          value: creatorState.fontFamily,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          isExpanded: true,
          borderRadius: BorderRadius.circular(8),
          items: fontList.map((String font) {
            final isActive = creatorState.fontFamily == font;
            return DropdownMenuItem<String>(
              value: font,
              child: Text(
                font,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              ref.read(storyCreatorProvider.notifier).setFontFamily(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSwatchesRowMobile(StoryCreatorState creatorState) {
    final gradients = ref.watch(storyGradientsList);
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: gradients.length,
        itemBuilder: (context, index) {
          final gradient = gradients[index];
          final isSelected = creatorState.backgroundColorIndex == index;
          return GestureDetector(
            onTap: () {
              ref.read(storyCreatorProvider.notifier).setBackgroundColorIndex(index);
            },
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileFooterActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              ref.read(storyCreatorProvider.notifier).reset();
              setState(() {
                _selectedOverlayId = null;
                _showMusicDialog = false;
                _showAltTextPanel = false;
                _showColorPicker = false;
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Bỏ', style: TextStyle(color: Colors.white70)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _shareStory,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C5CFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Chia sẻ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
