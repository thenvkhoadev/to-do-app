import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_state.dart';
import 'package:to_do_app/features/social/presentation/widgets/activity_post_card.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/core/utils/permission_helper.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

class MessageChatWindow extends ConsumerStatefulWidget {
  const MessageChatWindow({super.key});

  @override
  ConsumerState<MessageChatWindow> createState() => _MessageChatWindowState();
}

class _MessageChatWindowState extends ConsumerState<MessageChatWindow> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  ChatMessage? _replyingTo;
  String? _attachedImagePath;
  bool _showEmojiPicker = false;
  double? _uploadProgress;

  final LayerLink _emojiLink = LayerLink();
  final LayerLink _gifLink = LayerLink();
  final LayerLink _stickerLink = LayerLink();
  final LayerLink _taskLink = LayerLink();
  final LayerLink _plusLink = LayerLink();
  final LayerLink _callMoreLink = LayerLink();

  String? _activePickerTab;
  bool _isTaskPickerOpen = false;
  bool _isPlusMenuOpen = false;

  // Call status state
  bool _isCallActive = false;
  bool _isCallVideo = false;
  bool _isCallMinimized = false;
  int _callDurationSeconds = 0;
  bool _callMicOn = true;
  bool _callVideoOn = true;
  bool _callOpponentVideoOn = true;
  _CallState _callState = _CallState.calling;
  Timer? _callConnectTimer;
  Timer? _callDurationTimer;
  late final AudioPlayer _callAudioPlayer = AudioPlayer();
  bool _showCallToasts = true;
  bool _isCallMoreMenuOpen = false;

  late final AnimationController _callPulseController;
  CameraController? _callCameraController;

  Future<void> _initCallCameraController() async {
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return;
    }
    try {
      final cameraGranted = await PermissionHelper.requestCamera();
      if (!cameraGranted) return;

      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final ctrl = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await ctrl.initialize();
      if (mounted) {
        setState(() {
          _callCameraController = ctrl;
        });
      }
    } catch (e) {
      debugPrint('Error initializing call camera: $e');
    }
  }

  void _disposeCallCameraController() {
    _callCameraController?.dispose();
    _callCameraController = null;
  }

  @override
  void initState() {
    super.initState();
    _callPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    CommentMediaPickerOverlay.close();
    TaskPickerOverlay.close();
    PlusMenuOverlay.close();
    _callPulseController.dispose();
    _callAudioPlayer.dispose();
    _callConnectTimer?.cancel();
    _callDurationTimer?.cancel();
    _disposeCallCameraController();
    super.dispose();
  }

  Future<void> _pickMedia(ChatThread thread) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.media,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final extension = file.extension?.toLowerCase() ?? '';
        final isGif = extension == 'gif';
        final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(extension);
        
        setState(() {
          _uploadProgress = 0.0;
        });

        ref.read(chatThreadsProvider.notifier).sendMessage(
          thread.id,
          file.name,
          type: isVideo ? MessageType.video : (isGif ? MessageType.gif : MessageType.image),
          mediaUrl: file.path,
          fileName: file.name,
          fileSize: file.size,
          onUploadProgress: (progress) {
            setState(() {
              _uploadProgress = progress >= 1.0 ? null : progress;
            });
          },
        );
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
      setState(() {
        _uploadProgress = null;
      });
    }
  }

  void _capturePhoto(ChatThread thread) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _CameraCaptureDialog(
          thread: thread,
          onPhotoCaptured: (path) {
            setState(() {
              _uploadProgress = 0.0;
            });
            ref.read(chatThreadsProvider.notifier).sendMessage(
              thread.id,
              'Chụp ảnh từ máy ảnh',
              type: MessageType.image,
              mediaUrl: path,
              onUploadProgress: (progress) {
                setState(() {
                  _uploadProgress = progress >= 1.0 ? null : progress;
                });
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickAttachmentFile(ChatThread thread) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        setState(() {
          _uploadProgress = 0.0;
        });
        ref.read(chatThreadsProvider.notifier).sendMessage(
          thread.id,
          file.name,
          type: MessageType.file,
          mediaUrl: file.path,
          fileName: file.name,
          fileSize: file.size,
          onUploadProgress: (progress) {
            setState(() {
              _uploadProgress = progress >= 1.0 ? null : progress;
            });
          },
        );
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      setState(() {
        _uploadProgress = null;
      });
    }
  }

  void _toggleMediaPicker(String tab, ChatThread thread) {
    if (_activePickerTab == tab) {
      CommentMediaPickerOverlay.close();
      setState(() {
        _activePickerTab = null;
      });
    } else {
      setState(() {
        _activePickerTab = tab;
      });
      final bool isTyping = _textController.text.trim().isNotEmpty;
      final LayerLink targetLink = isTyping ? _plusLink : (tab == 'emoji' ? _emojiLink : (tab == 'sticker' ? _stickerLink : _gifLink));

      CommentMediaPickerOverlay.show(
        context: context,
        triggerContext: context,
        emojiLink: tab == 'emoji' && !isTyping ? _emojiLink : targetLink,
        gifLink: tab == 'gif' && !isTyping ? _gifLink : targetLink,
        stickerLink: tab == 'sticker' && !isTyping ? _stickerLink : targetLink,
        initialTab: tab,
        onTabChanged: (newTab) {
          setState(() {
            _activePickerTab = newTab;
          });
        },
        onEmojiSelected: (emoji) {
          _textController.text += emoji;
          setState(() {
            _activePickerTab = null;
          });
        },
        onGifSelected: (gifUrl, gifName) {
          ref.read(chatThreadsProvider.notifier).sendMessage(
            thread.id,
            gifName,
            type: MessageType.gif,
            mediaUrl: gifUrl,
          );
          setState(() {
            _activePickerTab = null;
          });
        },
        onStickerSelected: (stickerUrl, stickerName) {
          ref.read(chatThreadsProvider.notifier).sendMessage(
            thread.id,
            stickerName,
            type: MessageType.sticker,
            mediaUrl: stickerUrl,
          );
          setState(() {
            _activePickerTab = null;
          });
        },
        onClose: () {
          setState(() {
            _activePickerTab = null;
          });
        },
        preferLeft: true,
      );
    }
  }

  void _toggleTaskPicker(ChatThread thread) {
    if (_isTaskPickerOpen) {
      TaskPickerOverlay.close();
      setState(() {
        _isTaskPickerOpen = false;
      });
    } else {
      final tasksAsync = ref.read(userTasksProvider);
      final tasks = tasksAsync.valueOrNull ?? [];
      
      setState(() {
        _isTaskPickerOpen = true;
      });

      final bool isTyping = _textController.text.trim().isNotEmpty;
      final LayerLink targetLink = isTyping ? _plusLink : _taskLink;

      TaskPickerOverlay.show(
        context: context,
        link: targetLink,
        tasks: tasks,
        onTaskSelected: (task) {
          ref.read(chatThreadsProvider.notifier).sendMessage(
            thread.id,
            task.title,
            type: MessageType.task,
            metaTitle: task.title,
            metaSubtitle: 'Độ ưu tiên: ${task.priority.toUpperCase()} | Trạng thái: ${task.status.toUpperCase()}',
          );
          setState(() {
            _isTaskPickerOpen = false;
          });
        },
        onClose: () {
          setState(() {
            _isTaskPickerOpen = false;
          });
        },
      );
    }
  }

  void _togglePlusMenu(ChatThread thread) {
    if (_isPlusMenuOpen) {
      PlusMenuOverlay.close();
      setState(() {
        _isPlusMenuOpen = false;
      });
    } else {
      setState(() {
        _isPlusMenuOpen = true;
      });

      PlusMenuOverlay.show(
        context: context,
        link: _plusLink,
        onSendAudio: () {
          _togglePlusMenu(thread);
          ref.read(voiceRecordingProvider.notifier).startRecording();
        },
        onAttachFile: () {
          _togglePlusMenu(thread);
          _pickAttachmentFile(thread);
        },
        onSticker: () {
          _togglePlusMenu(thread);
          _toggleMediaPicker('sticker', thread);
        },
        onGif: () {
          _togglePlusMenu(thread);
          _toggleMediaPicker('gif', thread);
        },
        onCapture: () {
          _togglePlusMenu(thread);
          _capturePhoto(thread);
        },
        onShareTask: () {
          _togglePlusMenu(thread);
          _toggleTaskPicker(thread);
        },
        onClose: () {
          setState(() {
            _isPlusMenuOpen = false;
          });
        },
      );
    }
  }

  void _startCall(ChatThread thread, {required bool isVideo}) {
    setState(() {
      _isCallActive = true;
      _isCallVideo = isVideo;
      _isCallMinimized = false;
      _callMicOn = true;
      _callVideoOn = isVideo;
      _callOpponentVideoOn = true;
      _showCallToasts = true;
      _callState = _CallState.calling;
      _callDurationSeconds = 0;
    });

    ref.read(isCallActiveProvider.notifier).state = true;
    ref.read(isCallMinimizedProvider.notifier).state = false;

    _playRingtone();

    if (isVideo) {
      _initCallCameraController();
    }

    _callConnectTimer?.cancel();
    _callConnectTimer = Timer(const Duration(seconds: 6), () {
      _connectCall();
    });

    // Auto-hide device toasts after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showCallToasts = false;
        });
      }
    });
  }

  void _playRingtone() async {
    try {
      await _callAudioPlayer.setUrl('https://tiengdong.com/wp-content/uploads/Nhac-chuong-cuoc-goi-Messenger-www_tiengdong_com.mp3');
      await _callAudioPlayer.setLoopMode(LoopMode.one);
      await _callAudioPlayer.play();
    } catch (e) {
      debugPrint('Ringtone play error: $e');
    }
  }

  void _connectCall() async {
    try {
      await _callAudioPlayer.stop();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _callState = _CallState.connected;
      });
      _startDurationTimer();
    }
  }

  void _startDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  void _hangUpCall() async {
    _callConnectTimer?.cancel();
    _callDurationTimer?.cancel();
    _disposeCallCameraController();
    try {
      await _callAudioPlayer.stop();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _callState = _CallState.ended;
      });
    }
  }

  void _closeCall() {
    _callConnectTimer?.cancel();
    _callDurationTimer?.cancel();
    _disposeCallCameraController();
    try {
      _callAudioPlayer.stop();
    } catch (_) {}

    setState(() {
      _isCallActive = false;
      _isCallMinimized = false;
    });

    ref.read(isCallActiveProvider.notifier).state = false;
    ref.read(isCallMinimizedProvider.notifier).state = false;
  }

  String _formatCallDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleSend() {
    final activeId = ref.read(activeThreadIdProvider);
    if (activeId == null) return;

    final text = _textController.text.trim();
    if (text.isEmpty && _attachedImagePath == null) return;

    if (_attachedImagePath != null) {
      setState(() {
        _uploadProgress = 0.0;
      });
      ref.read(chatThreadsProvider.notifier).sendMessage(
        activeId,
        'Gửi một hình ảnh',
        type: MessageType.image,
        mediaUrl: _attachedImagePath,
        replyTo: _replyingTo,
        onUploadProgress: (progress) {
          setState(() {
            _uploadProgress = progress >= 1.0 ? null : progress;
          });
        },
      );
      _attachedImagePath = null;
    } else {
      ref.read(chatThreadsProvider.notifier).sendMessage(
        activeId,
        text,
        replyTo: _replyingTo,
      );
    }

    _textController.clear();
    setState(() {
      _replyingTo = null;
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeId = ref.watch(activeThreadIdProvider);
    final threads = ref.watch(chatThreadsProvider);
    final rightSidebarVisible = ref.watch(isRightSidebarVisibleProvider);
    final videoViewer = ref.watch(activeVideoViewerProvider);

    if (activeId == null) {
      return _buildEmptyState();
    }

    final threadIndex = threads.indexWhere((t) => t.id == activeId);
    if (threadIndex == -1) {
      return _buildEmptyState();
    }
    final thread = threads[threadIndex];

    return Material(
      color: const Color(0xFF0A0A0A), // Solid black background matching Messenger Desktop
      child: Column(
        children: [
          // Chat Header (always visible navbar)
          _buildChatHeader(thread, rightSidebarVisible),
          const Divider(height: 1, color: Color(0xFF242526)),
          
          if (_uploadProgress != null)
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0084FF)),
              minHeight: 3,
            ),
          
          if (_isCallActive && !_isCallMinimized)
            // Full calling view replacing the chat body
            Expanded(
              child: _buildFullCallScreen(thread),
            )
          else ...[
            // Minimized Audio/Video Call Bar (Green banner right below navbar)
            if (_isCallActive && _isCallMinimized)
              _buildMiniAudioCallBar(thread),
              
            // Regular Message Area
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: thread.messages.length + (thread.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == thread.messages.length) {
                        return _buildTypingIndicator(thread);
                      }
                      final message = thread.messages[index];
                      final isMe = message.senderId == 'me';
                      final showReceipt = index == thread.messages.length - 1 && isMe;
                      final groupPosition = _getGroupPosition(thread.messages, index);

                      return _InteractiveMessageRow(
                        key: ValueKey('msg-${message.id}'),
                        message: message,
                        isMe: isMe,
                        showReceipt: showReceipt,
                        thread: thread,
                        groupPosition: groupPosition,
                        onReply: (msg) {
                          setState(() {
                            _replyingTo = msg;
                          });
                        },
                        onReact: (msg, emoji) {
                          ref.read(chatThreadsProvider.notifier).addReaction(thread.id, msg.id, emoji);
                        },
                        onShowReactionPicker: (btnContext, msg, pos) {
                          _showReactionPicker(btnContext, pos, msg);
                        },
                      );
                    },
                  ),
                  
                  if (_showEmojiPicker)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildFacebookEmojiPicker(),
                    ),
                    
                  // Draggable/Positioned mini video call preview
                  if (_isCallActive && _isCallMinimized && _isCallVideo)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: _buildMiniVideoCallDialog(thread),
                    ),
                ],
              ),
            ),
            // Composer attachment & reply preview overlays
            if (_replyingTo != null) _buildReplyPreviewOverlay(),
            if (_attachedImagePath != null) _buildAttachmentPreviewOverlay(),
            // Bottom Composer Input
            _buildBottomComposer(thread),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0084FF).withValues(alpha: .08),
              ),
              child: const Icon(
                Icons.forum_rounded,
                color: Color(0xFF0084FF),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Conversation Selected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn một hội thoại hoặc bắt đầu trò chuyện mới.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader(ChatThread thread, bool rightSidebarVisible) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF3A3B3C),
            child: Text(
              thread.avatarInitials,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  thread.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  thread.online ? 'Đang hoạt động' : (thread.lastActive ?? 'Ngoại tuyến'),
                  style: TextStyle(
                    color: thread.online ? const Color(0xFF31A24C) : Colors.white38,
                    fontSize: 12,
                    fontWeight: thread.online ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Actions Buttons
          _buildHeaderIconButton(Icons.phone_rounded, () => _startCall(thread, isVideo: false)),
          _buildHeaderIconButton(Icons.videocam_rounded, () => _startCall(thread, isVideo: true)),
          _buildHeaderIconButton(Icons.search_rounded, () {}),
          _buildHeaderIconButton(
            rightSidebarVisible ? Icons.info_rounded : Icons.info_outline_rounded,
            () {
              ref.read(isRightSidebarVisibleProvider.notifier).state = !rightSidebarVisible;
            },
            color: rightSidebarVisible ? const Color(0xFF0084FF) : Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, VoidCallback onTap, {Color color = Colors.white70}) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        hoverColor: const Color(0xFF242526),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }


  Widget _buildTypingIndicator(ChatThread thread) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF3A3B3C),
            child: Text(
              thread.avatarInitials,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF242526),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Text('Đang nhập', style: TextStyle(color: Colors.white38, fontSize: 13)),
                SizedBox(width: 6),
                _BouncingDots(size: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreviewOverlay() {
    return Container(
      color: const Color(0xFF242526),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: Color(0xFF0084FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang trả lời ${_replyingTo!.senderName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingTo!.text,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreviewOverlay() {
    return Container(
      color: const Color(0xFF242526),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.image_rounded, color: Color(0xFF0084FF), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Hình ảnh đã đính kèm (Sẵn sàng gửi)',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
            onPressed: () => setState(() => _attachedImagePath = null),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomComposer(ChatThread thread) {
    final recState = ref.watch(voiceRecordingProvider);
    final isRecording = recState.status == VoiceRecordingStatus.recording;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: isRecording
          ? _buildRecordingBar(thread)
          : _buildComposerBar(thread),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildRecordingBar(ChatThread thread) {
    final recState = ref.watch(voiceRecordingProvider);

    return Container(
      key: const ValueKey('recording_bar'),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // ✕ Cancel (dark circle button with blue cross)
          GestureDetector(
            onTap: () => ref.read(voiceRecordingProvider.notifier).cancelRecording(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF242526),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Color(0xFF0084FF), size: 20),
            ),
          ),
          const SizedBox(width: 8),

          // Blue Bar Container
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0084FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Stop button (white circle with blue square)
                  GestureDetector(
                    onTap: () => ref.read(voiceRecordingProvider.notifier).cancelRecording(), // Stop also cancels
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.stop_rounded, color: Color(0xFF0084FF), size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Progress bar / Waveform
                  Expanded(
                    child: _PulseProgressBar(amplitude: recState.amplitude),
                  ),
                  const SizedBox(width: 12),

                  // Timer Pill (white background with blue text)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDuration(recState.elapsed),
                      style: const TextStyle(
                        color: Color(0xFF0084FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ➤ Send (dark circle button with white border and blue plane)
          GestureDetector(
            onTap: () async {
              final path = await ref.read(voiceRecordingProvider.notifier).stopAndSend();
              if (path != null) {
                ref.read(chatThreadsProvider.notifier).sendMessage(
                  thread.id,
                  '🎤 Tin nhắn thoại (${_formatDuration(recState.elapsed)})',
                  type: MessageType.voice,
                  mediaUrl: path,
                );
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF242526),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2), // White outline border
              ),
              child: const Icon(Icons.send_rounded, color: Color(0xFF0084FF), size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerBar(ChatThread thread) {
    final bool isTyping = _textController.text.trim().isNotEmpty;

    return Container(
      key: const ValueKey('composer_bar'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          if (isTyping) ...[
            // Collapsed state: just show + or x toggle button
            CompositedTransformTarget(
              link: _plusLink,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isPlusMenuOpen ? Icons.cancel_rounded : Icons.add_circle_rounded,
                  color: const Color(0xFF0084FF),
                  size: 32,
                ),
                onPressed: () => _togglePlusMenu(thread),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            // Full expanded options state
            _buildComposerOptionButton(Icons.attach_file_rounded, () => _pickAttachmentFile(thread)),
            _buildComposerOptionButton(Icons.camera_alt_rounded, () => _capturePhoto(thread)),
            _buildComposerOptionButton(Icons.image_rounded, () => _pickMedia(thread)),
            CompositedTransformTarget(
              link: _stickerLink,
              child: _buildComposerOptionButton(Icons.sticky_note_2_rounded, () => _toggleMediaPicker('sticker', thread)),
            ),
            CompositedTransformTarget(
              link: _gifLink,
              child: _buildComposerOptionButton(Icons.gif_box_rounded, () => _toggleMediaPicker('gif', thread)),
            ),
            CompositedTransformTarget(
              link: _taskLink,
              child: _buildComposerOptionButton(Icons.task_alt_rounded, () => _toggleTaskPicker(thread)),
            ),
            _buildComposerOptionButton(Icons.mic_rounded, () {
              ref.read(voiceRecordingProvider.notifier).startRecording();
            }),
            const SizedBox(width: 8),
          ],
          
          // TextInput
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF242526),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _inputFocus,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 8,
                      minLines: 1,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Aa',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  CompositedTransformTarget(
                    link: _emojiLink,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.emoji_emotions_rounded,
                        color: Color(0xFF0084FF), // Blue icon matching Messenger
                        size: 22,
                      ),
                      onPressed: () => _toggleMediaPicker('emoji', thread),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Right Send/Like Button
          _buildSendOrLikeButton(
            isSending: _textController.text.trim().isNotEmpty || _attachedImagePath != null,
            onTap: () {
              if (_textController.text.trim().isEmpty && _attachedImagePath == null) {
                _textController.text = '👍';
              }
              _handleSend();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComposerOptionButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: const Color(0xFF0084FF), size: 22), // Blue icon matching Messenger
      padding: const EdgeInsets.symmetric(horizontal: 5),
      constraints: const BoxConstraints(),
      onPressed: onTap,
    );
  }

  Widget _buildSendOrLikeButton({required bool isSending, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(
            isSending ? Icons.send_rounded : Icons.thumb_up_rounded,
            color: const Color(0xFF0084FF), // Keep send/like icon blue
            size: isSending ? 22 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildFacebookEmojiPicker() {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '😡', '👌', '🎉', '🔥', '✨', '👀', '💯'];
    return Container(
      color: const Color(0xFF242526),
      height: 120,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Biểu tượng cảm xúc', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                onPressed: () => setState(() => _showEmojiPicker = false),
              ),
            ],
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 6,
              children: emojis.map((emoji) {
                return InkWell(
                  onTap: () {
                    _textController.text += emoji;
                    setState(() {
                      _showEmojiPicker = false;
                    });
                  },
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showReactionPicker(BuildContext context, Offset position, ChatMessage message) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];
    final activeId = ref.read(activeThreadIdProvider);
    if (activeId == null) return;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy - 80, position.dx + 1, position.dy - 40),
      color: const Color(0xFF242526),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: emojis.map((emoji) {
              return InkWell(
                onTap: () {
                  ref.read(chatThreadsProvider.notifier).addReaction(activeId, message.id, emoji);
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList(),
          ),
        ),
        PopupMenuItem(
          onTap: () {
            setState(() {
              _replyingTo = message;
            });
          },
          child: const Row(
            children: [
              Icon(Icons.reply_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('Trả lời', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullCallScreen(ChatThread thread) {
    return Container(
      color: const Color(0xFF0F0F10),
      child: Stack(
        children: [
          // Minimize Bar / Actions Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button to minimize call
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isCallMinimized = true;
                    });
                    ref.read(isCallMinimizedProvider.notifier).state = true;
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 13),
                  label: const Text(
                    'Quay lại tin nhắn',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                // More options button
                CompositedTransformTarget(
                  link: _callMoreLink,
                  child: IconButton(
                    icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      setState(() {
                        _isCallMoreMenuOpen = !_isCallMoreMenuOpen;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Fixed Caller Name and Call Duration
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  thread.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _callState == _CallState.calling
                      ? 'Đang gọi...'
                      : _callState == _CallState.connected
                          ? _formatCallDuration(_callDurationSeconds)
                          : 'Cuộc gọi đã kết thúc',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          ),

          // Caller/Recipient avatar and status
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                if (_callState == _CallState.calling)
                  AnimatedBuilder(
                    animation: _callPulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 108 + (40 * _callPulseController.value),
                            height: 108 + (40 * _callPulseController.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0084FF).withValues(alpha: 0.15 * (1 - _callPulseController.value)),
                            ),
                          ),
                          Container(
                            width: 108 + (80 * _callPulseController.value),
                            height: 108 + (80 * _callPulseController.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0084FF).withValues(alpha: 0.05 * (1 - _callPulseController.value)),
                            ),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: _buildCallAvatar(thread),
                  )
                else
                  _buildCallAvatar(thread),

                // Post-call actions
                if (_callState == _CallState.ended) ...[
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => _startCall(thread, isVideo: _isCallVideo),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFF31A24C),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isCallVideo ? Icons.videocam_rounded : Icons.call_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Gọi lại', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 48),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _closeCall,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFF333333),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Đóng', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Connected device toasts
          if (_showCallToasts && _callState == _CallState.calling)
            Positioned(
              top: 80,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildCallConnectedDeviceToast(
                    icon: Icons.mic_rounded,
                    text: 'Micro được kết nối: External Microphone (Realtek(R) Audio)',
                  ),
                  const SizedBox(height: 8),
                  _buildCallConnectedDeviceToast(
                    icon: Icons.volume_up_rounded,
                    text: 'Loa được kết nối: FxSound Speakers (FxSound Audio Enhancer)',
                  ),
                ],
              ),
            ),

          // Fullscreen Webcam preview overlay (bottom right)
          if (_callState != _CallState.ended && _isCallVideo)
            Positioned(
              bottom: 110,
              right: 16,
              child: Container(
                width: 140,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _callVideoOn
                      ? Stack(
                          children: [
                            _callCameraController != null && _callCameraController!.value.isInitialized
                                ? CameraPreview(_callCameraController!)
                                : Image.network(
                                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=300',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Bạn',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: const Color(0xFF1F2022),
                          child: const Center(
                            child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 36),
                          ),
                        ),
                ),
              ),
            ),

          // Call Control Bottom Bar
          if (_callState != _CallState.ended)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCallScreenControlButton(
                    Icons.screen_share_rounded,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đang chuẩn bị chia sẻ màn hình...')),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildCallScreenControlButton(
                    Icons.person_add_rounded,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đang tìm kiếm danh bạ để mời...')),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildCallScreenControlToggle(
                    Icons.videocam_rounded,
                    Icons.videocam_off_rounded,
                    _callVideoOn,
                    () {
                      setState(() {
                        _callVideoOn = !_callVideoOn;
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildCallScreenControlToggle(
                    Icons.mic_rounded,
                    Icons.mic_off_rounded,
                    _callMicOn,
                    () {
                      setState(() {
                        _callMicOn = !_callMicOn;
                      });
                    },
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: _hangUpCall,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFA3E3E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: const Icon(
                        Icons.call_end_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // More Options Dropdown menu popup
          if (_isCallMoreMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _isCallMoreMenuOpen = false),
                child: Stack(
                  children: [
                    Positioned(
                      width: 220,
                      child: CompositedTransformFollower(
                        link: _callMoreLink,
                        showWhenUnlinked: false,
                        offset: const Offset(-180, 40),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF242526),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCallMoreMenuItem(
                                icon: Icons.fullscreen_rounded,
                                text: 'Chuyển sang toàn màn hình',
                                onTap: () {
                                  setState(() => _isCallMoreMenuOpen = false);
                                },
                              ),
                              const Divider(color: Colors.white10, height: 1, thickness: 1),
                              _buildCallMoreMenuItem(
                                icon: Icons.settings_rounded,
                                text: 'Cài đặt thiết bị',
                                onTap: () {
                                  setState(() => _isCallMoreMenuOpen = false);
                                },
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildCallAvatar(ChatThread thread) {
    return CircleAvatar(
      radius: 54,
      backgroundColor: const Color(0xFF333333),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(54),
        child: Image.network(
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
          fit: BoxFit.cover,
          width: 108,
          height: 108,
        ),
      ),
    );
  }

  Widget _buildCallConnectedDeviceToast({required IconData icon, required String text}) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2022).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF333333),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallScreenControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildCallScreenControlToggle(IconData onIcon, IconData offIcon, bool isAct, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isAct ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isAct ? onIcon : offIcon,
          color: isAct ? Colors.white : Colors.black,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildCallMoreMenuItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAudioCallBar(ChatThread thread) {
    return GestureDetector(
      onTap: () {
        setState(() => _isCallMinimized = false);
        ref.read(isCallMinimizedProvider.notifier).state = false;
      },
      child: Container(
        height: 44,
        color: const Color(0xFF31A24C),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'Cuộc gọi đang hoạt động: ${thread.name}',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              _formatCallDuration(_callDurationSeconds),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniVideoCallDialog(ChatThread thread) {
    return Container(
      width: 140,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Cameras render logic
            Positioned.fill(
              child: _buildMiniVideoLayout(thread),
            ),

            // Hover / Click Overlay to return fullscreen
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() => _isCallMinimized = false);
                    ref.read(isCallMinimizedProvider.notifier).state = false;
                  },
                  child: Container(
                    color: Colors.black26,
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_full_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Toàn màn hình',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
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

  Widget _buildMiniVideoLayout(ChatThread thread) {
    // 1. Both cameras are ON
    if (_callVideoOn && _callOpponentVideoOn) {
      return Column(
        children: [
          // Top 50%: Opponent camera
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
              ),
              child: Image.network(
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // Bottom 50%: Your camera
          Expanded(
            child: _callCameraController != null && _callCameraController!.value.isInitialized
                ? CameraPreview(_callCameraController!)
                : Image.network(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=300',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
          ),
        ],
      );
    }
    // 2. Only opponent camera is ON
    if (!_callVideoOn && _callOpponentVideoOn) {
      return Image.network(
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (_callVideoOn && !_callOpponentVideoOn) {
      return _callCameraController != null && _callCameraController!.value.isInitialized
          ? CameraPreview(_callCameraController!)
          : Image.network(
              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=300',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
    }
    // 4. Both cameras are OFF -> show opponent avatar
    return Container(
      color: const Color(0xFF1E2022),
      child: Center(
        child: CircleAvatar(
          radius: 32,
          backgroundColor: const Color(0xFF333333),
          backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100'),
        ),
      ),
    );
  }

  BubbleGroupPosition _getGroupPosition(List<ChatMessage> messages, int index) {
    if (index < 0 || index >= messages.length) return BubbleGroupPosition.single;
    
    final current = messages[index];
    final senderId = current.senderId;
    
    final hasPrev = index > 0;
    final hasNext = index < messages.length - 1;
    
    final prev = hasPrev ? messages[index - 1] : null;
    final next = hasNext ? messages[index + 1] : null;
    
    final isPrevSame = prev != null && 
        prev.senderId == senderId && 
        current.timestamp.difference(prev.timestamp).inMinutes < 2;
    final isNextSame = next != null && 
        next.senderId == senderId && 
        next.timestamp.difference(current.timestamp).inMinutes < 2;
    
    if (isPrevSame && isNextSame) {
      return BubbleGroupPosition.middle;
    } else if (isPrevSame) {
      return BubbleGroupPosition.end;
    } else if (isNextSame) {
      return BubbleGroupPosition.start;
    } else {
      return BubbleGroupPosition.single;
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final BubbleGroupPosition groupPosition;
  final bool hasReply;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.groupPosition,
    this.hasReply = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.image || message.type == MessageType.gif || message.type == MessageType.sticker) {
      final url = message.mediaUrl;
      ImageProvider imgProvider = const NetworkImage('https://picsum.photos/400/300');
      if (url != null && url.isNotEmpty) {
        if (url.startsWith('http://') || url.startsWith('https://')) {
          imgProvider = NetworkImage(url);
        } else {
          imgProvider = FileImage(File(url));
        }
      }
      return Container(
        width: 220,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: _getBubbleBorderRadius(isMe, groupPosition, hasReply: hasReply),
          image: DecorationImage(
            image: imgProvider,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (message.type == MessageType.video) {
      return _VideoMessageBubble(message: message);
    }

    if (message.type == MessageType.file) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF0084FF) : const Color(0xFF303031),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.fileName ?? message.text,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.fileSize != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${(message.fileSize! / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (message.type == MessageType.task) {
      return Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF242526),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0084FF).withValues(alpha: .2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.task_alt_rounded, color: Color(0xFF0084FF), size: 18),
                SizedBox(width: 8),
                Text('Task Share Card', style: TextStyle(color: Color(0xFF0084FF), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(message.metaTitle ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(message.metaSubtitle ?? '', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      );
    }

    if (message.type == MessageType.voice) {
      return _VoiceMessageBubble(message: message, isMe: isMe);
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF0084FF) : const Color(0xFF2C2C2E),
        borderRadius: _getBubbleBorderRadius(isMe, groupPosition, hasReply: hasReply),
      ),
      child: Text(
        message.text,
        style: const TextStyle(color: Colors.white, fontSize: 14.5),
      ),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  final double size;
  const _BouncingDots({this.size = 4});

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            double delay = index * 0.2;
            double progress = (_controller.value - delay).clamp(0.0, 1.0);
            if (progress > 0.5) progress = 1.0 - progress;
            double offset = progress * 8.0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              transform: Matrix4.translationValues(0, -offset, 0),
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                color: Colors.white54,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}


class _PulseProgressBar extends StatelessWidget {
  final double amplitude;

  const _PulseProgressBar({required this.amplitude});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fillWidth = (constraints.maxWidth * amplitude.clamp(0.05, 1.0)).clamp(0.0, constraints.maxWidth);
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Track
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Fill
            Container(
              height: 4,
              width: fillWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Dot
            Positioned(
              left: (fillWidth - 6).clamp(0.0, constraints.maxWidth - 12),
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VoiceMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;

  const _VoiceMessageBubble({required this.message, required this.isMe});

  @override
  State<_VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<_VoiceMessageBubble> {
  bool _isPlaying = false;
  int _currentSeconds = 0;
  Timer? _playbackTimer;
  late int _durationInSeconds;

  @override
  void initState() {
    super.initState();
    _durationInSeconds = _parseDuration(widget.message.text);
  }

  int _parseDuration(String text) {
    try {
      final regExp = RegExp(r'\((\d+):(\d+)\)');
      final match = regExp.firstMatch(text);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        return minutes * 60 + seconds;
      }
    } catch (_) {}
    return 5;
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(1, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _togglePlay() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
        if (_currentSeconds >= _durationInSeconds) {
          _currentSeconds = 0;
        }
      });
      _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_currentSeconds < _durationInSeconds) {
              _currentSeconds++;
            } else {
              _currentSeconds = 0;
              _isPlaying = false;
              _playbackTimer?.cancel();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final progress = _durationInSeconds > 0 ? _currentSeconds / _durationInSeconds : 0.0;
    const barCount = 18;

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF0084FF) : const Color(0xFF303031),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play button
          Material(
            color: isMe ? Colors.white : const Color(0xFF0084FF),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _togglePlay,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isMe ? const Color(0xFF0084FF) : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Waveform bars
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(barCount, (index) {
                    final isActive = index / barCount <= progress;
                    final heights = [8, 12, 16, 14, 10, 14, 18, 12, 10, 16, 20, 14, 8, 12, 16, 10, 12, 8];
                    final h = (heights[index % heights.length]).toDouble();

                    return Container(
                      width: 2.5,
                      height: h,
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isMe ? Colors.white : const Color(0xFF0084FF))
                            : (isMe ? Colors.white.withValues(alpha: 0.4) : Colors.white24),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                // Playback time
                Text(
                  _isPlaying ? _formatTime(_currentSeconds) : _formatTime(_durationInSeconds),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TaskPickerOverlay {
  static OverlayEntry? _entry;

  static void show({
    required BuildContext context,
    required LayerLink link,
    required List<NexusTask> tasks,
    required Function(NexusTask task) onTaskSelected,
    required VoidCallback onClose,
  }) {
    close();

    final overlayState = Overlay.of(context);
    
    _entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 280,
          height: 300,
          child: CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            offset: const Offset(0, -310), // Position above the task icon
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF242526),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chia sẻ nhiệm vụ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              close();
                              onClose();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.close_rounded, size: 16, color: Colors.white38),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    Expanded(
                      child: tasks.isEmpty
                          ? const Center(
                              child: Text(
                                'Không có nhiệm vụ nào',
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    onTap: () {
                                      onTaskSelected(task);
                                      close();
                                      onClose();
                                    },
                                    dense: true,
                                    leading: const Icon(
                                      Icons.task_alt_rounded,
                                      color: Color(0xFF0084FF),
                                      size: 18,
                                    ),
                                    title: Text(
                                      task.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Độ ưu tiên: ${task.priority.toUpperCase()}',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_entry!);
  }

  static void close() {
    _entry?.remove();
    _entry = null;
  }
}

class _CameraCaptureDialog extends StatefulWidget {
  final ChatThread thread;
  final Function(String path) onPhotoCaptured;

  const _CameraCaptureDialog({required this.thread, required this.onPhotoCaptured});

  @override
  State<_CameraCaptureDialog> createState() => _CameraCaptureDialogState();
}

class _CameraCaptureDialogState extends State<_CameraCaptureDialog> {
  CameraController? _controller;
  bool _isCaptured = false;
  String? _photoPath;
  bool _isFlashOn = false;
  bool _isRotated = false;
  bool _showFlashScreen = false;
  bool _hasCameraHardware = true;
  List<CameraDescription> _cameras = [];
  int _selectedCamera = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      setState(() {
        _hasCameraHardware = false;
      });
      return;
    }
    try {
      final cameraGranted = await PermissionHelper.requestCamera();
      if (!cameraGranted) return;

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _hasCameraHardware = false;
        });
        return;
      }
      await _startCamera(_cameras[_selectedCamera]);
    } catch (_) {
      setState(() {
        _hasCameraHardware = false;
      });
    }
  }

  Future<void> _startCamera(CameraDescription cam) async {
    _controller?.dispose();
    final ctrl = CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await ctrl.initialize();
      if (mounted) {
        setState(() {
          _controller = ctrl;
          _hasCameraHardware = true;
        });
      }
    } catch (_) {
      setState(() {
        _hasCameraHardware = false;
      });
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _selectedCamera = (_selectedCamera + 1) % _cameras.length;
    await _startCamera(_cameras[_selectedCamera]);
  }

  Future<void> _toggleFlash() async {
    _isFlashOn = !_isFlashOn;
    await _controller?.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  final List<String> _simulatedPhotos = [
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=600',
    'https://images.unsplash.com/photo-1472214222541-d510753a8707?w=600',
    'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=600',
    'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?w=600',
  ];

  Future<void> _capture() async {
    setState(() {
      _showFlashScreen = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _showFlashScreen = false;
        });
      }
    });

    if (_controller != null && _controller!.value.isInitialized && _hasCameraHardware) {
      try {
        final XFile file = await _controller!.takePicture();
        if (mounted) {
          setState(() {
            _isCaptured = true;
            _photoPath = file.path;
          });
        }
        return;
      } catch (e) {
        debugPrint('Error taking photo: $e');
      }
    }

    // Fallback simulation
    if (mounted) {
      setState(() {
        _isCaptured = true;
        final randomIndex = DateTime.now().millisecond % _simulatedPhotos.length;
        _photoPath = _simulatedPhotos[randomIndex];
      });
    }
  }

  void _retake() {
    setState(() {
      _isCaptured = false;
      _photoPath = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 380,
        height: 600,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isFlashOn ? Colors.yellow : Colors.white70,
                      ),
                      onPressed: _hasCameraHardware ? _toggleFlash : () {
                        setState(() {
                          _isFlashOn = !_isFlashOn;
                        });
                      },
                    ),
                    const Text(
                      'MÁY ẢNH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Viewfinder / Preview
              Expanded(
                child: Stack(
                  children: [
                    if (!_isCaptured)
                      Positioned.fill(
                        child: Container(
                          color: const Color(0xFF1C1F2B),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: _controller != null && _controller!.value.isInitialized && _hasCameraHardware
                                    ? CameraPreview(_controller!)
                                    : Opacity(
                                        opacity: 0.7,
                                        child: Image.network(
                                          _isRotated 
                                            ? 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600'
                                            : 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _CameraGridPainter(),
                                ),
                              ),
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.8), width: 1.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.fiber_manual_record, color: Colors.red, size: 10),
                                        SizedBox(width: 4),
                                        Text(
                                          'LIVE',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_photoPath != null)
                        Positioned.fill(
                          child: _photoPath!.startsWith('http')
                              ? Image.network(
                                  _photoPath!,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_photoPath!),
                                  fit: BoxFit.cover,
                                ),
                        ),

                      if (_showFlashScreen)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),

                // Bottom control bar
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: !_isCaptured
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_library_rounded, color: Colors.white70, size: 28),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          GestureDetector(
                            onTap: _capture,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70, size: 28),
                            onPressed: _hasCameraHardware ? _flipCamera : () {
                              setState(() {
                                _isRotated = !_isRotated;
                              });
                            },
                          ),
                        ],
                      )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _retake,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF333333),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Chụp lại', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_photoPath != null) {
                              widget.onPhotoCaptured(_photoPath!);
                            }
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0084FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Gửi ảnh', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 0.5;

    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);

    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlusMenuOverlay {
  static OverlayEntry? _entry;

  static void show({
    required BuildContext context,
    required LayerLink link,
    required VoidCallback onSendAudio,
    required VoidCallback onAttachFile,
    required VoidCallback onSticker,
    required VoidCallback onGif,
    required VoidCallback onCapture,
    required VoidCallback onShareTask,
    required VoidCallback onClose,
  }) {
    close();

    final overlayState = Overlay.of(context);

    _entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 320,
          height: 290,
          child: CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            offset: const Offset(-8, -300),
            child: _PlusMenuWidget(
              onSendAudio: onSendAudio,
              onAttachFile: onAttachFile,
              onSticker: onSticker,
              onGif: onGif,
              onCapture: onCapture,
              onShareTask: onShareTask,
              onClose: onClose,
            ),
          ),
        );
      },
    );

    overlayState.insert(_entry!);
  }

  static void close() {
    _entry?.remove();
    _entry = null;
  }
}

class _PlusMenuWidget extends StatelessWidget {
  final VoidCallback onSendAudio;
  final VoidCallback onAttachFile;
  final VoidCallback onSticker;
  final VoidCallback onGif;
  final VoidCallback onCapture;
  final VoidCallback onShareTask;
  final VoidCallback onClose;

  const _PlusMenuWidget({
    required this.onSendAudio,
    required this.onAttachFile,
    required this.onSticker,
    required this.onGif,
    required this.onCapture,
    required this.onShareTask,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF242526),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMenuItem(
                    icon: Icons.mic_rounded,
                    title: 'Gửi clip âm thanh',
                    onTap: onSendAudio,
                    isFirst: true,
                  ),
                  _buildMenuItem(
                    icon: Icons.insert_drive_file_rounded,
                    title: 'Đính kèm file có kích thước tối đa là 25MB',
                    onTap: onAttachFile,
                  ),
                  _buildMenuItem(
                    icon: Icons.sticky_note_2_rounded,
                    title: 'Chọn nhãn dán',
                    onTap: onSticker,
                  ),
                  _buildMenuItem(
                    icon: Icons.gif_box_rounded,
                    title: 'Chọn file GIF',
                    onTap: onGif,
                  ),
                  _buildMenuItem(
                    icon: Icons.camera_alt_rounded,
                    title: 'Chụp ảnh từ thiết bị',
                    onTap: onCapture,
                  ),
                  _buildMenuItem(
                    icon: Icons.task_alt_rounded,
                    title: 'Chia sẻ nhiệm vụ',
                    onTap: onShareTask,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18.0),
          child: CustomPaint(
            size: const Size(16, 8),
            painter: _TrianglePainter(
              color: const Color(0xFF242526),
              pointingUp: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isFirst = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: isFirst 
            ? Border.all(color: const Color(0xFF0084FF), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF0084FF), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool pointingUp;

  _TrianglePainter({required this.color, required this.pointingUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (pointingUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _CallState { calling, connected, ended }

class _MessengerCallScreen extends StatefulWidget {
  final ChatThread thread;
  final bool isVideo;

  const _MessengerCallScreen({required this.thread, required this.isVideo});

  @override
  State<_MessengerCallScreen> createState() => _MessengerCallScreenState();
}

class _MessengerCallScreenState extends State<_MessengerCallScreen> with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  _CallState _state = _CallState.calling;
  int _durationSeconds = 0;
  Timer? _simulatedConnectTimer;
  Timer? _durationTimer;
  bool _isMicOn = true;
  bool _isVideoOn = true;
  bool _showToasts = true;
  bool _isMoreMenuOpen = false;

  late final AnimationController _pulseController;
  final LayerLink _moreMenuLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _isVideoOn = widget.isVideo;
    _player = AudioPlayer();

    // Pulse animation for avatar calling state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startCallingState();

    // Auto-hide connected devices toast after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showToasts = false;
        });
      }
    });
  }

  void _startCallingState() async {
    setState(() {
      _state = _CallState.calling;
      _durationSeconds = 0;
    });

    // Play ringtone
    try {
      await _player.setUrl('https://tiengdong.com/wp-content/uploads/Nhac-chuong-cuoc-goi-Messenger-www_tiengdong_com.mp3');
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
    } catch (e) {
      debugPrint('Ringtone play error: $e');
    }

    _simulatedConnectTimer?.cancel();
    _simulatedConnectTimer = Timer(const Duration(seconds: 6), () {
      _connectCall();
    });
  }

  void _connectCall() async {
    // Stop ringtone
    try {
      await _player.stop();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _state = _CallState.connected;
      });
      _startDurationTimer();
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _durationSeconds++;
        });
      }
    });
  }

  void _hangUp() async {
    _simulatedConnectTimer?.cancel();
    _durationTimer?.cancel();
    try {
      await _player.stop();
    } catch (_) {}

    setState(() {
      _state = _CallState.ended;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simulatedConnectTimer?.cancel();
    _durationTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleMoreMenu() {
    setState(() {
      _isMoreMenuOpen = !_isMoreMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      body: SafeArea(
        child: Stack(
          children: [
            // Top Navigation & Actions Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Caller identity info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF333333),
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Vu',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  // Wave and more buttons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.back_hand_rounded, color: Colors.white, size: 20),
                        onPressed: () {
                          // Simple visual gesture feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang vẫy tay chào Giang Đức 👋'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      CompositedTransformTarget(
                        link: _moreMenuLink,
                        child: IconButton(
                          icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20),
                          onPressed: _toggleMoreMenu,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Immersive Calling center elements
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_state == _CallState.calling)
                    // Animated pulsing circles for calling state
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 108 + (40 * _pulseController.value),
                              height: 108 + (40 * _pulseController.value),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0084FF).withValues(alpha: 0.15 * (1 - _pulseController.value)),
                              ),
                            ),
                            Container(
                              width: 108 + (80 * _pulseController.value),
                              height: 108 + (80 * _pulseController.value),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0084FF).withValues(alpha: 0.05 * (1 - _pulseController.value)),
                              ),
                            ),
                            child!,
                          ],
                        );
                      },
                      child: _buildAvatarCircle(thread),
                    )
                  else
                    _buildAvatarCircle(thread),

                  const SizedBox(height: 20),
                  Text(
                    thread.name,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _state == _CallState.calling
                        ? 'Đang gọi...'
                        : _state == _CallState.connected
                            ? _formatDuration(_durationSeconds)
                            : 'Cuộc gọi đã kết thúc',
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  
                  // Retake/Call back controls if ended
                  if (_state == _CallState.ended) ...[
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Gọi lại (Call back)
                        Column(
                          children: [
                            GestureDetector(
                              onTap: _startCallingState,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF31A24C),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Gọi lại', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(width: 48),
                        // Đóng (Close)
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF333333),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Đóng', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Connected devices toasts (top right)
            if (_showToasts && _state == _CallState.calling)
              Positioned(
                top: 60,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildConnectedDeviceToast(
                      icon: Icons.mic_rounded,
                      text: 'Micro được kết nối: External Microphone (Realtek(R) Audio)',
                    ),
                    const SizedBox(height: 8),
                    _buildConnectedDeviceToast(
                      icon: Icons.volume_up_rounded,
                      text: 'Loa được kết nối: FxSound Speakers (FxSound Audio Enhancer)',
                    ),
                  ],
                ),
              ),

            // Video preview overlay card (bottom right)
            if (_state != _CallState.ended && (widget.isVideo || !_isVideoOn))
              Positioned(
                bottom: 120,
                right: 16,
                child: Container(
                  width: 140,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 10),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _isVideoOn
                        ? Stack(
                            children: [
                              Image.network(
                                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=300',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Bạn',
                                    style: TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            color: const Color(0xFF1F2022),
                            child: const Center(
                              child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 36),
                            ),
                          ),
                  ),
                ),
              ),

            // More Options Dropdown Popup
            if (_isMoreMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => setState(() => _isMoreMenuOpen = false),
                  child: Stack(
                    children: [
                      Positioned(
                        width: 240,
                        child: CompositedTransformFollower(
                          link: _moreMenuLink,
                          showWhenUnlinked: false,
                          offset: const Offset(-200, 32),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF242526),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMoreMenuItem(
                                  icon: Icons.fullscreen_rounded,
                                  text: 'Chuyển sang toàn màn hình',
                                  onTap: () {
                                    setState(() => _isMoreMenuOpen = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đang chuyển sang toàn màn hình...')),
                                    );
                                  },
                                ),
                                const Divider(color: Colors.white10, height: 1, thickness: 1),
                                _buildMoreMenuItem(
                                  icon: Icons.settings_rounded,
                                  text: 'Cài đặt thiết bị',
                                  onTap: () {
                                    setState(() => _isMoreMenuOpen = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đang mở cài đặt thiết bị...')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Call Controller Bottom Bar
            if (_state != _CallState.ended)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Share screen button
                    _buildCallControlButton(
                      Icons.screen_share_rounded,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang chuẩn bị chia sẻ màn hình...')),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    // Add person button
                    _buildCallControlButton(
                      Icons.person_add_rounded,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang tìm kiếm danh bạ để mời vào cuộc gọi...')),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    // Video camera toggle button
                    _buildCallControlToggle(
                      Icons.videocam_rounded,
                      Icons.videocam_off_rounded,
                      _isVideoOn,
                      () {
                        setState(() {
                          _isVideoOn = !_isVideoOn;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    // Microphone mute button
                    _buildCallControlToggle(
                      Icons.mic_rounded,
                      Icons.mic_off_rounded,
                      _isMicOn,
                      () {
                        setState(() {
                          _isMicOn = !_isMicOn;
                        });
                      },
                    ),
                    const SizedBox(width: 24),
                    // Hangup/End call button
                    GestureDetector(
                      onTap: _hangUp,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFA3E3E),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(ChatThread thread) {
    return CircleAvatar(
      radius: 54,
      backgroundColor: const Color(0xFF333333),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(54),
        child: Image.network(
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200', // Beautiful recipient avatar
          fit: BoxFit.cover,
          width: 108,
          height: 108,
        ),
      ),
    );
  }

  Widget _buildConnectedDeviceToast({required IconData icon, required String text}) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2022).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF333333),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildCallControlToggle(
    IconData onIcon,
    IconData offIcon,
    bool isActivated,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isActivated ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isActivated ? onIcon : offIcon,
          color: isActivated ? Colors.white : Colors.black,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMoreMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoMessageBubble extends ConsumerStatefulWidget {
  final ChatMessage message;
  const _VideoMessageBubble({required this.message});

  @override
  ConsumerState<_VideoMessageBubble> createState() => _VideoMessageBubbleState();
}

class _VideoMessageBubbleState extends ConsumerState<_VideoMessageBubble> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  Timer? _playButtonTimer;
  bool _isHovered = false;
  bool _showPlayButton = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    final url = widget.message.mediaUrl;
    if (url == null || url.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        _controller = VideoPlayerController.file(File(url));
      }

      _controller!.initialize().then((_) {
        if (mounted) {
          _controller!.setLooping(true);
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((err) {
        debugPrint('Error initializing video controller: $err');
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
    } catch (e) {
      debugPrint('Error creating video controller: $e');
      setState(() => _hasError = true);
    }
  }

  @override
  void didUpdateWidget(_VideoMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.mediaUrl != widget.message.mediaUrl) {
      _controller?.dispose();
      _isInitialized = false;
      _hasError = false;
      _initVideo();
    }
  }

  @override
  void dispose() {
    _playButtonTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSending = widget.message.status == MessageStatus.sending;

    double displayWidth = 220;
    double displayHeight = 160;

    if (_isInitialized && _controller != null) {
      final aspectRatio = _controller!.value.aspectRatio;
      if (aspectRatio > 0) {
        if (aspectRatio < 1.0) {
          // Vertical video (e.g. 9:16)
          displayWidth = 180;
          displayHeight = 180 / aspectRatio;
          if (displayHeight > 280) {
            displayHeight = 280;
            displayWidth = 280 * aspectRatio;
          }
        } else {
          // Horizontal video (e.g. 16:9)
          displayWidth = 220;
          displayHeight = 220 / aspectRatio;
          if (displayHeight < 120) {
            displayHeight = 120;
          }
        }
      }
    }

    final showControls = !_isInitialized || isSending || _hasError || 
        !_controller!.value.isPlaying || _isHovered || _showPlayButton;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          final activeId = ref.read(activeThreadIdProvider);
          final threads = ref.read(chatThreadsProvider);
          final threadIndex = threads.indexWhere((t) => t.id == activeId);
          if (threadIndex == -1) return;
          final thread = threads[threadIndex];
          final videoMessages = thread.messages.where((m) => m.type == MessageType.video).toList();
          final initialIndex = videoMessages.indexWhere((m) => m.id == widget.message.id);

          ref.read(activeVideoViewerProvider.notifier).state = ActiveVideoViewerState(
            videoMessages: videoMessages,
            currentIndex: initialIndex != -1 ? initialIndex : 0,
          );
        },
        child: Container(
          width: displayWidth,
          height: displayHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF242526),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video preview / player
              if (_isInitialized && _controller != null)
                Positioned.fill(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                )
              else
                const Positioned.fill(
                  child: Icon(Icons.video_library_rounded, color: Colors.white24, size: 40),
                ),

              // Play/Pause button or loading indicator at the play circle position
              if (showControls)
                if (isSending || !_isInitialized)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0084FF)),
                    ),
                  )
                else if (_hasError)
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40)
                else
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_controller!.value.isPlaying) {
                          _controller!.pause();
                          _showPlayButton = true;
                          _playButtonTimer?.cancel();
                        } else {
                          _controller!.play();
                          _showPlayButton = true;
                          _playButtonTimer?.cancel();
                          _playButtonTimer = Timer(const Duration(seconds: 2), () {
                            if (mounted && _controller!.value.isPlaying) {
                              setState(() {
                                _showPlayButton = false;
                              });
                            }
                          });
                        }
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForwardMessageDialog extends ConsumerStatefulWidget {
  final String mediaUrl;
  final MessageType messageType;
  final String text;

  const _ForwardMessageDialog({
    required this.mediaUrl,
    required this.messageType,
    required this.text,
    super.key,
  });

  @override
  ConsumerState<_ForwardMessageDialog> createState() => _ForwardMessageDialogState();
}

class _ForwardMessageDialogState extends ConsumerState<_ForwardMessageDialog> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  final Set<String> _sentUserIds = {}; // Track which users we forwarded to

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final supabase = Supabase.instance.client;
      final myUserId = supabase.auth.currentUser?.id;
      if (myUserId == null) return;

      final data = await supabase
          .from('users')
          .select('id, full_name, username, email, avatar_url')
          .neq('id', myUserId)
          .limit(20);

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users for forward: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((u) {
      final name = ((u['full_name'] ?? u['username'] ?? u['email'] ?? '') as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: const Color(0xFF242526),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chuyển tiếp',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search Input
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người và nhóm',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                fillColor: const Color(0xFF18191A),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mới đây',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // User List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                      ? const Center(
                          child: Text('Không tìm thấy người dùng', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        )
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final userId = user['id'] as String;
                            final name = user['full_name'] ?? user['username'] ?? user['email'] ?? 'User';
                            final avatar = user['avatar_url'] as String?;
                            final alreadySent = _sentUserIds.contains(userId);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF3B3C3D),
                                    backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                                    child: avatar == null
                                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white))
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: alreadySent
                                        ? null
                                        : () async {
                                            setState(() {
                                              _sentUserIds.add(userId);
                                            });
                                            try {
                                              final convId = await ref
                                                  .read(chatThreadsProvider.notifier)
                                                  .createOrGetConversation(userId);
                                              await ref.read(chatThreadsProvider.notifier).sendMessage(
                                                convId,
                                                widget.text,
                                                type: widget.messageType,
                                                mediaUrl: widget.mediaUrl,
                                              );
                                            } catch (e) {
                                              debugPrint('Error forwarding message: $e');
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: alreadySent ? Colors.white10 : const Color(0xFF0084FF),
                                      disabledBackgroundColor: Colors.white10,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      minimumSize: const Size(60, 32),
                                    ),
                                    child: Text(
                                      alreadySent ? 'Đã gửi' : 'Gửi',
                                      style: TextStyle(
                                        color: alreadySent ? Colors.white38 : Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoFullscreenViewer extends StatefulWidget {
  final List<ChatMessage> videoMessages;
  final int initialIndex;

  const _VideoFullscreenViewer({
    required this.videoMessages,
    required this.initialIndex,
    super.key,
  });

  @override
  State<_VideoFullscreenViewer> createState() => _VideoFullscreenViewerState();
}

class _VideoFullscreenViewerState extends State<_VideoFullscreenViewer> {
  late int _currentIndex;
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initVideo();
  }

  void _initVideo() {
    setState(() {
      _isInitialized = false;
      _hasError = false;
    });
    _controller?.dispose();

    if (widget.videoMessages.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    final msg = widget.videoMessages[_currentIndex];
    final url = msg.mediaUrl;
    if (url == null || url.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        _controller = VideoPlayerController.file(File(url));
      }

      _controller!.initialize().then((_) {
        if (mounted) {
          _controller!.setLooping(true);
          _controller!.play();
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((err) {
        debugPrint('Error fullscreen video init: $err');
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
    } catch (e) {
      debugPrint('Error creating fullscreen video controller: $e');
      setState(() => _hasError = true);
    }
  }

  void _prevVideo() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _initVideo();
      });
    }
  }

  void _nextVideo() {
    if (_currentIndex < widget.videoMessages.length - 1) {
      setState(() {
        _currentIndex++;
        _initVideo();
      });
    }
  }

  Future<void> _downloadVideo() async {
    final msg = widget.videoMessages[_currentIndex];
    final url = msg.mediaUrl;
    if (url == null || url.isEmpty) return;

    if (!url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video đã có sẵn trên thiết bị.')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dio = Dio();
      final dir = await getTemporaryDirectory();
      final fileExt = url.split('.').last.split('?').first;
      final savePath = '${dir.path}/downloaded_video_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      String userMessage = 'Tải video thành công!';
      if (Platform.isWindows) {
        final home = Platform.environment['USERPROFILE'];
        if (home != null) {
          final destDir = Directory('$home/Downloads');
          if (await destDir.exists()) {
            final destPath = '${destDir.path}/NEXUS_Video_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
            await File(savePath).copy(destPath);
            userMessage = 'Đã lưu video vào thư mục Downloads!';
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage)),
        );
      }
    } catch (e) {
      debugPrint('Error downloading video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tải video thất bại.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _forwardVideo() {
    final msg = widget.videoMessages[_currentIndex];
    showDialog(
      context: context,
      builder: (context) => _ForwardMessageDialog(
        mediaUrl: msg.mediaUrl ?? '',
        messageType: MessageType.video,
        text: msg.text,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPrev = _currentIndex > 0;
    final hasNext = _currentIndex < widget.videoMessages.length - 1;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: Stack(
        children: [
          // Center Video Player
          Center(
            child: _isInitialized && _controller != null
                ? AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  )
                : _hasError
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          SizedBox(height: 8),
                          Text('Không thể tải video', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      )
                    : const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0084FF)),
                      ),
          ),

          // Left Navigation Button
          if (hasPrev)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 36),
                  onPressed: _prevVideo,
                ),
              ),
            ),

          // Right Navigation Button
          if (hasNext)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 36),
                  onPressed: _nextVideo,
                ),
              ),
            ),

          // Top Header Bar
          Positioned(
            top: 24,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back / Exit button
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                // Action buttons: Download & Share
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isDownloading)
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 16),
                        child: CircularProgressIndicator(
                          value: _downloadProgress,
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0084FF)),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.download_rounded, color: Colors.white, size: 26),
                        onPressed: _downloadVideo,
                        tooltip: 'Lưu về thiết bị',
                      ),
                    IconButton(
                      icon: const Icon(Icons.reply_rounded, color: Colors.white, size: 26),
                      onPressed: _forwardVideo,
                      tooltip: 'Chuyển tiếp',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatVideoViewer extends ConsumerStatefulWidget {
  final ActiveVideoViewerState viewerState;

  const ChatVideoViewer({
    required this.viewerState,
  });

  @override
  ConsumerState<ChatVideoViewer> createState() => ChatVideoViewerState();
}

class ChatVideoViewerState extends ConsumerState<ChatVideoViewer> {
  late int _currentIndex;
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  final ScrollController _thumbScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.viewerState.currentIndex;
    _initVideo();
  }

  void _initVideo() {
    setState(() {
      _isInitialized = false;
      _hasError = false;
    });
    _controller?.dispose();

    if (widget.viewerState.videoMessages.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    final msg = widget.viewerState.videoMessages[_currentIndex];
    final url = msg.mediaUrl;
    if (url == null || url.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        _controller = VideoPlayerController.file(File(url));
      }

      _controller!.initialize().then((_) {
        if (mounted) {
          _controller!.setLooping(true);
          _controller!.play();
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((err) {
        debugPrint('Error viewer video init: $err');
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
    } catch (e) {
      debugPrint('Error creating viewer video controller: $e');
      setState(() => _hasError = true);
    }
  }

  void _prevVideo() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _initVideo();
      });
    }
  }

  void _nextVideo() {
    if (_currentIndex < widget.viewerState.videoMessages.length - 1) {
      setState(() {
        _currentIndex++;
        _initVideo();
      });
    }
  }

  void _showAnimatedNotificationDialog(BuildContext context, String message, bool isSuccess) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curveValue = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curveValue,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: const Color(0xFF242526),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSuccess ? 'Thành công' : 'Thất bại',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0084FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    ),
                    child: const Text('Đóng', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadVideo() async {
    final msg = widget.viewerState.videoMessages[_currentIndex];
    final url = msg.mediaUrl;
    if (url == null || url.isEmpty) return;

    if (!url.startsWith('http')) {
      _showAnimatedNotificationDialog(context, 'Video đã có sẵn trên thiết bị.', false);
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dio = Dio();
      final dir = await getTemporaryDirectory();
      final fileExt = url.split('.').last.split('?').first;
      final savePath = '${dir.path}/downloaded_video_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      String userMessage = 'Tải video thành công!';
      if (Platform.isWindows) {
        final home = Platform.environment['USERPROFILE'];
        if (home != null) {
          final destDir = Directory('$home/Downloads');
          if (await destDir.exists()) {
            final destPath = '${destDir.path}/NEXUS_Video_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
            await File(savePath).copy(destPath);
            userMessage = 'Đã lưu video vào thư mục Downloads!';
          }
        }
      }

      if (mounted) {
        _showAnimatedNotificationDialog(context, userMessage, true);
      }
    } catch (e) {
      debugPrint('Error downloading video: $e');
      if (mounted) {
        _showAnimatedNotificationDialog(context, 'Tải video thất bại.', false);
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _forwardVideo() {
    final msg = widget.viewerState.videoMessages[_currentIndex];
    showDialog(
      context: context,
      builder: (context) => _ForwardMessageDialog(
        mediaUrl: msg.mediaUrl ?? '',
        messageType: MessageType.video,
        text: msg.text,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _thumbScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPrev = _currentIndex > 0;
    final hasNext = _currentIndex < widget.viewerState.videoMessages.length - 1;

    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Column(
        children: [
          // Header inside the viewer area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back / Close button (X or Back Arrow)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                  onPressed: () {
                    ref.read(activeVideoViewerProvider.notifier).state = null;
                  },
                ),
                // Action buttons: Download & Share
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isDownloading)
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 16),
                        child: CircularProgressIndicator(
                          value: _downloadProgress,
                          strokeWidth: 2.0,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0084FF)),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
                        onPressed: _downloadVideo,
                        tooltip: 'Lưu về thiết bị',
                      ),
                    IconButton(
                      icon: const Icon(Icons.reply_rounded, color: Colors.white, size: 22),
                      onPressed: _forwardVideo,
                      tooltip: 'Chuyển tiếp',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Middle Video Area
          Expanded(
            child: Stack(
              children: [
                // Video Player
                Center(
                  child: _isInitialized && _controller != null
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : _hasError
                          ? const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                                SizedBox(height: 8),
                                Text('Không thể tải video', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            )
                          : const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0084FF)),
                            ),
                ),

                // Left Navigation Button
                if (hasPrev)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 30),
                        onPressed: _prevVideo,
                      ),
                    ),
                  ),

                // Right Navigation Button
                if (hasNext)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 30),
                        onPressed: _nextVideo,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Horizontal Thumbnail list
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.black26,
              border: Border(
                top: BorderSide(color: Colors.white12, width: 0.5),
              ),
            ),
            child: ListView.builder(
              controller: _thumbScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.viewerState.videoMessages.length,
              itemBuilder: (context, index) {
                final msg = widget.viewerState.videoMessages[index];
                final isSelected = index == _currentIndex;

                return _VideoThumbnailItem(
                  message: msg,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                      _initVideo();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoThumbnailItem extends StatefulWidget {
  final ChatMessage message;
  final bool isSelected;
  final VoidCallback onTap;

  const _VideoThumbnailItem({
    required this.message,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_VideoThumbnailItem> createState() => _VideoThumbnailItemState();
}

class _VideoThumbnailItemState extends State<_VideoThumbnailItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final url = widget.message.mediaUrl;
    if (url == null || url.isEmpty) return;

    try {
      if (url.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        _controller = VideoPlayerController.file(File(url));
      }
      _controller!.initialize().then((_) {
        if (mounted) {
          _controller!.setLooping(true);
          _controller!.play();
          _controller!.setVolume(0.0);
          setState(() => _isInitialized = true);
        }
      });
    } catch (e) {
      debugPrint('Error init thumbnail: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 70,
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isSelected ? const Color(0xFF0084FF) : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: Colors.black38,
        ),
        clipBehavior: Clip.antiAlias,
        child: _isInitialized && _controller != null
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              )
            : const Center(
                child: Icon(Icons.video_library_rounded, size: 20, color: Colors.white30),
              ),
      ),
    );
  }
}

// ==========================================
// BUBBLE GROUPING & INTERACTIVE HOVER ACTIONS
// ==========================================

enum BubbleGroupPosition { start, middle, end, single }

BorderRadius _getBubbleBorderRadius(bool isMe, BubbleGroupPosition position, {bool hasReply = false}) {
  const double rMax = 18.0;
  const double rMin = 4.0;

  if (hasReply) {
    // If this bubble follows a reply quote preview block directly on top, flatten top corners to attach
    return BorderRadius.only(
      topLeft: const Radius.circular(rMin),
      topRight: const Radius.circular(rMin),
      bottomLeft: Radius.circular(isMe ? rMax : rMin),
      bottomRight: Radius.circular(isMe ? rMin : rMax),
    );
  }

  if (isMe) {
    switch (position) {
      case BubbleGroupPosition.start:
        return const BorderRadius.only(
          topLeft: Radius.circular(rMax),
          bottomLeft: Radius.circular(rMax),
          topRight: Radius.circular(rMax),
          bottomRight: Radius.circular(rMin),
        );
      case BubbleGroupPosition.middle:
        return const BorderRadius.only(
          topLeft: Radius.circular(rMax),
          bottomLeft: Radius.circular(rMax),
          topRight: Radius.circular(rMin),
          bottomRight: Radius.circular(rMin),
        );
      case BubbleGroupPosition.end:
        return const BorderRadius.only(
          topLeft: Radius.circular(rMax),
          bottomLeft: Radius.circular(rMax),
          topRight: Radius.circular(rMin),
          bottomRight: Radius.circular(rMax),
        );
      case BubbleGroupPosition.single:
        return const BorderRadius.only(
          topLeft: Radius.circular(rMax),
          bottomLeft: Radius.circular(rMax),
          topRight: Radius.circular(rMax),
          bottomRight: Radius.circular(rMin),
        );
    }
  } else {
    switch (position) {
      case BubbleGroupPosition.start:
        return const BorderRadius.only(
          topLeft: Radius.circular(rMax),
          bottomLeft: Radius.circular(rMin),
          topRight: Radius.circular(rMax),
          bottomRight: Radius.circular(rMax),
        );
      case BubbleGroupPosition.middle:
        return const BorderRadius.only(
          topLeft: Radius.circular(rMin),
          bottomLeft: Radius.circular(rMin),
          topRight: Radius.circular(rMax),
          bottomRight: Radius.circular(rMax),
        );
      case BubbleGroupPosition.end:
        return const BorderRadius.only(
          topLeft: Radius.circular(rMin),
          bottomLeft: Radius.circular(rMax),
          topRight: Radius.circular(rMax),
          bottomRight: Radius.circular(rMax),
        );
      case BubbleGroupPosition.single:
        return const BorderRadius.only(
          topLeft: Radius.circular(rMax),
          bottomLeft: Radius.circular(rMin),
          topRight: Radius.circular(rMax),
          bottomRight: Radius.circular(rMax),
        );
    }
  }
}

class _InteractiveMessageRow extends ConsumerStatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showReceipt;
  final ChatThread thread;
  final BubbleGroupPosition groupPosition;
  final void Function(ChatMessage) onReply;
  final void Function(ChatMessage, String) onReact;
  final void Function(BuildContext, ChatMessage, Offset) onShowReactionPicker;

  const _InteractiveMessageRow({
    super.key,
    required this.message,
    required this.isMe,
    required this.showReceipt,
    required this.thread,
    required this.groupPosition,
    required this.onReply,
    required this.onReact,
    required this.onShowReactionPicker,
  });

  @override
  ConsumerState<_InteractiveMessageRow> createState() => _InteractiveMessageRowState();
}

class _InteractiveMessageRowState extends ConsumerState<_InteractiveMessageRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMe = widget.isMe;
    final showReceipt = widget.showReceipt;
    final thread = widget.thread;
    final groupPosition = widget.groupPosition;

    final isLastInGroup = groupPosition == BubbleGroupPosition.end || groupPosition == BubbleGroupPosition.single;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: EdgeInsets.only(
          top: (groupPosition == BubbleGroupPosition.start || groupPosition == BubbleGroupPosition.single) ? 6 : 2,
          bottom: (groupPosition == BubbleGroupPosition.end || groupPosition == BubbleGroupPosition.single) ? 6 : 2,
          left: 16,
          right: 16,
        ),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Left Side: Recipient Avatar (only shown at the end of a group block)
            if (!isMe) ...[
              if (isLastInGroup)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF3A3B3C),
                  backgroundImage: thread.avatarUrl != null && thread.avatarUrl!.isNotEmpty
                      ? NetworkImage(thread.avatarUrl!)
                      : null,
                  child: thread.avatarUrl == null || thread.avatarUrl!.isEmpty
                      ? Text(
                          thread.avatarInitials,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        )
                      : null,
                )
              else
                const SizedBox(width: 28), // Spacer matches CircleAvatar width
              const SizedBox(width: 8),
            ],

            // Center / Hover actions (placed left of bubble if isMe)
            if (isMe && _isHovered) ...[
              _buildHoverActions(context),
            ],

            // Bubble block
            Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Reply header: curved arrow icon and text "Đạt đã trả lời 7 Sụa"
                if (message.replyTo != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.reply_rounded,
                          color: Colors.white38,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${message.senderId == 'me' ? 'Bạn' : message.senderName} đã trả lời ${message.replyTo!.senderId == 'me' ? 'bạn' : message.replyTo!.senderName}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Replying quote preview inside list
                if (message.replyTo != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: message.replyTo!.senderId == 'me'
                          ? const Color(0xFF003D80)
                          : const Color(0xFF1F1F21),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                    ),
                    child: Text(
                      message.replyTo!.text,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Main bubble widget
                _MessageBubble(
                  message: message,
                  isMe: isMe,
                  groupPosition: groupPosition,
                  hasReply: message.replyTo != null,
                ),

                // Reactions display below bubble
                if (message.reactions.isNotEmpty)
                  _buildReactionsBadge(message),

                // Seen receipts (only shown for isMe)
                if (isMe && (showReceipt || message.status == MessageStatus.seen || message.seenByUserIds.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.status == MessageStatus.sending)
                          const Icon(Icons.access_time_rounded, color: Colors.white30, size: 12)
                        else if (message.status == MessageStatus.sent)
                          const Icon(Icons.check_circle_outline_rounded, color: Colors.white30, size: 12)
                        else if (message.status == MessageStatus.delivered)
                          const Icon(Icons.check_circle_rounded, color: Colors.white30, size: 12)
                        else if (message.status == MessageStatus.seen || message.seenByUserIds.isNotEmpty)
                          CircleAvatar(
                            radius: 7,
                            backgroundColor: const Color(0xFF3A3B3C),
                            backgroundImage: thread.avatarUrl != null && thread.avatarUrl!.isNotEmpty
                                ? NetworkImage(thread.avatarUrl!)
                                : null,
                            child: thread.avatarUrl == null || thread.avatarUrl!.isEmpty
                                ? Text(
                                    thread.avatarInitials,
                                    style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                      ],
                    ),
                  ),
              ],
            ),

            // Center / Hover actions (placed right of bubble if !isMe)
            if (!isMe && _isHovered) ...[
              _buildHoverActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHoverActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHoverActionIconButton(
            icon: Icons.sentiment_satisfied_alt_rounded,
            tooltip: 'Bày tỏ cảm xúc',
            onTap: (btnContext) {
              final renderBox = btnContext.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              widget.onShowReactionPicker(btnContext, widget.message, position);
            },
          ),
          const SizedBox(width: 4),
          _buildHoverActionIconButton(
            icon: Icons.reply_rounded,
            tooltip: 'Trả lời',
            onTap: (btnContext) {
              widget.onReply(widget.message);
            },
          ),
          const SizedBox(width: 4),
          _buildHoverActionIconButton(
            icon: Icons.more_vert_rounded,
            tooltip: 'Xem thêm',
            onTap: (btnContext) {
              final renderBox = btnContext.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              _showMoreMenu(btnContext, position);
            },
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + 32, // Show right below/near the 3-dot button
        position.dx + 120,
        position.dy + 150,
      ),
      color: const Color(0xFF252525),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: [
        PopupMenuItem(
          height: 38,
          onTap: () {
            ref.read(chatThreadsProvider.notifier).deleteMessage(widget.thread.id, widget.message.id);
          },
          child: const Text(
            'Gỡ',
            style: TextStyle(color: Colors.white, fontSize: 13.5),
          ),
        ),
        PopupMenuItem(
          height: 38,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đang chuyển tiếp tin nhắn...')),
            );
          },
          child: const Text(
            'Chuyển tiếp',
            style: TextStyle(color: Colors.white, fontSize: 13.5),
          ),
        ),
        PopupMenuItem(
          height: 38,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã ghim tin nhắn')),
            );
          },
          child: const Text(
            'Ghim',
            style: TextStyle(color: Colors.white, fontSize: 13.5),
          ),
        ),
        PopupMenuItem(
          height: 38,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã gửi báo cáo đoạn chat')),
            );
          },
          child: const Text(
            'Báo cáo',
            style: TextStyle(color: Colors.white, fontSize: 13.5),
          ),
        ),
      ],
    );
  }

  Widget _buildHoverActionIconButton({
    required IconData icon,
    required String tooltip,
    required void Function(BuildContext) onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Builder(
        builder: (btnContext) {
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onTap(btnContext),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white70, size: 16),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildReactionsBadge(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
      child: Wrap(
        spacing: 2,
        children: message.reactions.keys.map((emoji) {
          final count = message.reactions[emoji]!.length;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF242526),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: .04)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 11)),
                if (count > 1) ...[
                  const SizedBox(width: 2),
                  Text('$count', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
