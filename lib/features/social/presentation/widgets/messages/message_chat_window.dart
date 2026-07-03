import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_state.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_draft_state.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_dialogs.dart';
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
  final Map<String, GlobalKey<_InteractiveMessageRowState>> _messageKeys = {};

  GlobalKey<_InteractiveMessageRowState> _getKeyForMessage(String messageId) {
    return _messageKeys.putIfAbsent(messageId, () => GlobalKey<_InteractiveMessageRowState>());
  }

  ChatMessage? _editingMessage;
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

  // Reaction overlay state
  OverlayEntry? _reactionOverlayEntry;
  Timer? _reactionShowTimer;
  Timer? _reactionHideTimer;
  final _MessengerReactionPopupController _reactionPopupController = _MessengerReactionPopupController();
  bool _isTransitioningToFullPicker = false;
  String? _hoveredMessageId;
  Timer? _draftDebounceTimer;
  bool _isDisposed = false;

  // Composer emoji picker overlay state
  OverlayEntry? _emojiPickerOverlay;
  final _MessengerEmojiPickerPopupController _emojiPickerPopupController = _MessengerEmojiPickerPopupController();

  // Full emoji picker (triggered by + button on Reaction Capsule) overlay state
  OverlayEntry? _fullEmojiPickerOverlay;
  final _MessengerEmojiPickerPopupController _fullEmojiPickerPopupController = _MessengerEmojiPickerPopupController();

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
    _textController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final activeId = ref.read(activeThreadIdProvider);
        if (activeId != null) {
          _loadDraftForThread(activeId);
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _draftDebounceTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    _dismissReactionPopupImmediate();
    _closeEmojiPickerImmediate();
    _closeFullEmojiPickerImmediate();
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
    _closeEmojiPickerImmediate();
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

  void _togglePlusMenu(ChatThread thread, BuildContext anchorContext) {
    if (_isPlusMenuOpen) {
      PlusMenuOverlay.close();
      setState(() => _isPlusMenuOpen = false);
    } else {
      setState(() => _isPlusMenuOpen = true);

      PlusMenuOverlay.show(
        context: context,
        anchorContext: anchorContext,
        link: _plusLink,
        onSendAudio: () {
          PlusMenuOverlay.close();
          setState(() => _isPlusMenuOpen = false);
          ref.read(voiceRecordingProvider.notifier).startRecording();
        },
        onAttachFile: () {
          PlusMenuOverlay.close();
          setState(() => _isPlusMenuOpen = false);
          _pickAttachmentFile(thread);
        },
        onSticker: () {
          PlusMenuOverlay.close();
          setState(() => _isPlusMenuOpen = false);
          _toggleMediaPicker('sticker', thread);
        },
        onGif: () {
          PlusMenuOverlay.close();
          setState(() => _isPlusMenuOpen = false);
          _toggleMediaPicker('gif', thread);
        },
        onCapture: () {
          PlusMenuOverlay.close();
          setState(() => _isPlusMenuOpen = false);
          _capturePhoto(thread);
        },
        onShareTask: () {
          PlusMenuOverlay.close();
          setState(() => _isPlusMenuOpen = false);
          _toggleTaskPicker(thread);
        },
        onClose: () => setState(() => _isPlusMenuOpen = false),
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

  void _onTextChanged() {
    final activeId = ref.read(activeThreadIdProvider);
    if (activeId == null) return;

    _draftDebounceTimer?.cancel();

    final text = _textController.text;
    final replyTo = ref.read(replyingToProvider(activeId));

    if (text.trim().isEmpty && replyTo == null) {
      ref.read(messageDraftsProvider.notifier).deleteDraft(activeId);
      return;
    }

    _draftDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      final text = _textController.text;
      final replyTo = ref.read(replyingToProvider(activeId));
      if (text.trim().isNotEmpty || replyTo != null) {
        int cursor = _textController.selection.baseOffset;
        int start = _textController.selection.start;
        int end = _textController.selection.end;
        if (cursor < 0) cursor = text.length;
        if (start < 0) start = text.length;
        if (end < 0) end = text.length;

        ref.read(messageDraftsProvider.notifier).saveDraft(
          conversationId: activeId,
          text: text,
          cursorPosition: cursor,
          selectionStart: start,
          selectionEnd: end,
          replyToId: replyTo?.id,
          replyToSenderId: replyTo?.senderId,
          replyToSenderName: replyTo?.senderName,
          replyToText: replyTo?.text,
          replyToType: replyTo?.type.name,
          replyToMediaUrl: replyTo?.mediaUrl,
        );
      }
    });
  }

  void _saveDraftImmediately(String conversationId) {
    _draftDebounceTimer?.cancel();
    final text = _textController.text;
    final replyTo = ref.read(replyingToProvider(conversationId));

    if (text.trim().isEmpty && replyTo == null) {
      ref.read(messageDraftsProvider.notifier).deleteDraft(conversationId);
    } else {
      int cursor = _textController.selection.baseOffset;
      int start = _textController.selection.start;
      int end = _textController.selection.end;
      if (cursor < 0) cursor = text.length;
      if (start < 0) start = text.length;
      if (end < 0) end = text.length;

      ref.read(messageDraftsProvider.notifier).saveDraft(
        conversationId: conversationId,
        text: text,
        cursorPosition: cursor,
        selectionStart: start,
        selectionEnd: end,
        replyToId: replyTo?.id,
        replyToSenderId: replyTo?.senderId,
        replyToSenderName: replyTo?.senderName,
        replyToText: replyTo?.text,
        replyToType: replyTo?.type.name,
        replyToMediaUrl: replyTo?.mediaUrl,
      );
    }
  }

  void _loadDraftForThread(String conversationId) {
    _draftDebounceTimer?.cancel();

    _textController.removeListener(_onTextChanged);

    final drafts = ref.read(messageDraftsProvider);
    final draft = drafts[conversationId];

    if (draft != null) {
      _textController.text = draft.draftText;

      final textLength = draft.draftText.length;
      int start = draft.selectionStart;
      int end = draft.selectionEnd;

      if (start < 0 || start > textLength) start = textLength;
      if (end < 0 || end > textLength) end = textLength;

      _textController.selection = TextSelection(
        baseOffset: start,
        extentOffset: end,
      );

      // Restore replyingTo state!
      if (draft.replyToId != null &&
        draft.replyToSenderId != null &&
        draft.replyToSenderName != null &&
        draft.replyToText != null) {
      final reconstructed = ChatMessage(
        id: draft.replyToId!,
        threadId: conversationId,
        senderId: draft.replyToSenderId!,
        senderName: draft.replyToSenderName!,
        text: draft.replyToText!,
        timestamp: draft.updatedAt,
        type: draft.replyToType != null
            ? MessageType.values.firstWhere((e) => e.name == draft.replyToType, orElse: () => MessageType.text)
            : MessageType.text,
        mediaUrl: draft.replyToMediaUrl,
      );
      ref.read(replyingToProvider(conversationId).notifier).state = reconstructed;
    } else {
      ref.read(replyingToProvider(conversationId).notifier).state = null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inputFocus.requestFocus();
      }
    });
  } else {
    _textController.clear();
    ref.read(replyingToProvider(conversationId).notifier).state = null;
  }

    _textController.addListener(_onTextChanged);
  }

  void _handleSend() {
  final activeId = ref.read(activeThreadIdProvider);
  if (activeId == null) return;

  // ✅ Đọc từ provider thay vì local state
  final replyingTo = ref.read(replyingToProvider(activeId));

  final text = _textController.text.trim();
  if (text.isEmpty && _attachedImagePath == null) return;

  if (_editingMessage != null) {
    ref.read(chatThreadsProvider.notifier).editMessage(
      activeId, _editingMessage!.id, text,
    );
    setState(() => _editingMessage = null);
  } else if (_attachedImagePath != null) {
    setState(() => _uploadProgress = 0.0);
    ref.read(chatThreadsProvider.notifier).sendMessage(
      activeId,
      'Gửi một hình ảnh',
      type: MessageType.image,
      mediaUrl: _attachedImagePath,
      replyTo: replyingTo,          // ✅
      onUploadProgress: (progress) {
        setState(() => _uploadProgress = progress >= 1.0 ? null : progress);
      },
    );
    _attachedImagePath = null;
  } else {
    ref.read(chatThreadsProvider.notifier).sendMessage(
      activeId, text,
      replyTo: replyingTo,          // ✅
    );
  }

  ref.read(messageDraftsProvider.notifier).deleteDraft(activeId);
  _textController.clear();

  // ✅ Clear qua provider
  ref.read(replyingToProvider(activeId).notifier).state = null;

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
    ref.listen<String?>(activeThreadIdProvider, (previous, next) {
      if (previous != next) {
        _dismissReactionPopupImmediate();
        _editingMessage = null;
        if (previous != null && next != null && previous != next) {
          ref.read(replyingToProvider(previous).notifier).state = null;
          _saveDraftImmediately(previous);
        } else if (previous != null && next == null) {
          // vẫn lưu draft nếu cần, nhưng không xóa reply
          _saveDraftImmediately(previous);
        }

        if (next != null) {
          _loadDraftForThread(next);
        }
      }
    });

    final activeId = ref.watch(activeThreadIdProvider);
    if (activeId != null) {
      ref.listen<ChatMessage?>(replyingToProvider(activeId), (previous, next) {
        if (previous != next) {
          _saveDraftImmediately(activeId);
        }
      });
    }

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
    final activeThemeId = ref.watch(threadThemeProvider)[thread.id] ?? 'default';
    final activeTheme = availableChatThemes.firstWhere((t) => t.id == activeThemeId, orElse: () => availableChatThemes.first);

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
              
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: activeTheme.chatBackgroundGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ListView.builder(
                        shrinkWrap: true,
                        controller: _scrollController,
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
                        itemCount: thread.messages.length + (thread.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == thread.messages.length) {
                            return _buildTypingIndicator(thread);
                          }
                          final message = thread.messages[index];
                          if (message.type == MessageType.event) {
                            return _buildSystemNoticeRow(message, thread);
                          }
                          final isMe = message.senderId == 'me';
                          final showReceipt = index == thread.messages.length - 1 && isMe;
                          final groupPosition = _getGroupPosition(thread.messages, index);

                          return _InteractiveMessageRow(
                            key: _getKeyForMessage(message.id),
                            message: message,
                            isMe: isMe,
                            showReceipt: showReceipt,
                            thread: thread,
                            groupPosition: groupPosition,
                            onCallAgain: () => _startCall(thread, isVideo: false),
                            onReply: (msg) {
                              setState(() {
                                ref.read(replyingToProvider(activeId).notifier).state = msg;
                              });
                            },
                            onEdit: (msg) {
                              setState(() {
                                _editingMessage = msg;
                                _textController.text = msg.text;
                                _inputFocus.requestFocus();
                              });
                            },
                            onReact: (msg, emoji) {
                              ref.read(chatThreadsProvider.notifier).addReaction(thread.id, msg.id, emoji);
                            },
                            onShowReactionPicker: (btnContext, msg, pos, link) =>
                                _showReactionPicker(btnContext, pos, msg, link),
                            onBubbleHoverShow: (btnContext, link, msg, pos) =>
                                _showReactionPopup(context: btnContext, link: link, message: msg, isMe: msg.senderId == 'me', position: pos),
                            onBubbleHoverExit: _startReactionHideTimer,
                            onBubbleHoverEnterCancelHide: _cancelReactionHideTimer,
                            isMenuOpen: _hoveredMessageId == message.id && (_reactionOverlayEntry != null || _fullEmojiPickerOverlay != null),
                            onScrollToMessage: (targetId) async {
                              final index = thread.messages.indexWhere((m) => m.id == targetId);
                              if (index == -1) return;

                              final targetKey = _messageKeys[targetId];
                              if (targetKey != null) {
                                if (targetKey.currentContext != null) {
                                  Scrollable.ensureVisible(
                                    targetKey.currentContext!,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                  targetKey.currentState?.highlight(); // ✅ Sáng và phóng to tin nhắn lên
                                } else {
                                  final double estimatedOffset = index * 90.0;
                                  final double maxScroll = _scrollController.position.maxScrollExtent;
                                  final double targetOffset = estimatedOffset.clamp(0.0, maxScroll);
                                  
                                  await _scrollController.animateTo(
                                    targetOffset,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );

                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (targetKey.currentContext != null) {
                                      Scrollable.ensureVisible(
                                        targetKey.currentContext!,
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                      );
                                      targetKey.currentState?.highlight(); // ✅ Sáng và phóng to tin nhắn lên
                                    }
                                  });
                                }
                              }
                            },
                          );
                        },
                      ),
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
            ),
            // Composer attachment & reply preview overlays
            if (ref.watch(replyingToProvider(activeId)) != null) _buildReplyPreviewOverlay(),
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
            backgroundImage: thread.avatarUrl != null && thread.avatarUrl!.trim().isNotEmpty
                ? NetworkImage(thread.avatarUrl!)
                : null,
            child: thread.avatarUrl == null || thread.avatarUrl!.trim().isEmpty
                ? Text(
                    thread.avatarInitials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ref.watch(threadNicknamesProvider)[thread.id]?[thread.recipientId ?? 'friend'] ?? thread.name,
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

  Widget _buildSystemNoticeRow(ChatMessage message, ChatThread thread) {
    final String baseText = message.text;
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: baseText.endsWith(' ') ? baseText : '$baseText ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    PinnedMessagesDialog.show(context, thread);
                  },
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: Color(0xFF0084FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
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
  final activeId = ref.read(activeThreadIdProvider);
  if (activeId == null) return const SizedBox.shrink();
  final replyingTo = ref.watch(replyingToProvider(activeId));
  if (replyingTo == null) return const SizedBox.shrink();

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
                replyingTo.senderId == 'me'
                    ? 'Đang trả lời chính mình'
                    : 'Đang trả lời ${replyingTo.senderName}',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                replyingTo.text.isNotEmpty
                    ? replyingTo.text
                    : (replyingTo.type == MessageType.video
                        ? '[Video]'
                        : (replyingTo.type == MessageType.image
                            ? '[Hình ảnh]'
                            : (replyingTo.type == MessageType.gif
                                ? '[Ảnh động]'
                                : (replyingTo.type == MessageType.file
                                    ? '[Tệp tin]'
                                    : '[Tin nhắn]')))),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
          onPressed: () {
            // ✅ Clear qua provider
            ref.read(replyingToProvider(activeId).notifier).state = null;
          },
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_editingMessage != null) _buildEditingPreviewBar(),
        AnimatedSwitcher(
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
        ),
      ],
    );
  }

  Widget _buildEditingPreviewBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1F20),
        border: Border(
          top: BorderSide(color: Color(0xFF242526), width: 1),
          bottom: BorderSide(color: Color(0xFF242526), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_rounded, color: Color(0xFF0084FF), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chỉnh sửa tin nhắn',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _editingMessage!.text,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
            onPressed: () {
              setState(() {
                _editingMessage = null;
                _textController.clear();
              });
            },
          ),
        ],
      ),
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
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          if (isTyping) ...[
            // Collapsed state: just show + or x toggle button
            CompositedTransformTarget(
              link: _plusLink,
              child: Builder(
                builder: (btnContext) => IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _isPlusMenuOpen ? Icons.cancel_rounded : Icons.add_circle_rounded,
                    color: const Color(0xFF0084FF),
                    size: 32,
                  ),
                  onPressed: () => _togglePlusMenu(thread, btnContext),
                ),
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
                      onPressed: () => _toggleEmojiPicker(thread),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSendOrLikeButton(
            thread: thread,
            isSending: _textController.text.trim().isNotEmpty || _attachedImagePath != null,
            onTap: () {
              if (_textController.text.trim().isEmpty && _attachedImagePath == null) {
                final quickReaction = ref.read(threadQuickReactionProvider)[thread.id] ?? '👍';
                _textController.text = quickReaction;
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

  Widget _buildSendOrLikeButton({required ChatThread thread, required bool isSending, required VoidCallback onTap}) {
    final threadQuickReaction = ref.watch(threadQuickReactionProvider)[thread.id] ?? '👍';

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
          child: isSending
              ? const Icon(
                  Icons.send_rounded,
                  color: Color(0xFF0084FF),
                  size: 22,
                )
              : Text(
                  threadQuickReaction,
                  style: const TextStyle(fontSize: 24),
                ),
        ),
      ),
    );
  }

  void _toggleEmojiPicker(ChatThread thread) {
    if (_emojiPickerOverlay != null) {
      _closeEmojiPicker();
    } else {
      _closeEmojiPickerImmediate();
      CommentMediaPickerOverlay.close();
      PlusMenuOverlay.close();
      TaskPickerOverlay.close();

      final overlay = Overlay.of(context);
      _emojiPickerOverlay = OverlayEntry(
        builder: (overlayContext) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closeEmojiPicker,
                  child: Container(color: Colors.transparent),
                ),
              ),
              CompositedTransformFollower(
                link: _emojiLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topCenter,
                followerAnchor: Alignment.bottomCenter,
                offset: const Offset(-168, -8),
                child: Material(
                  color: Colors.transparent,
                  child: _MessengerEmojiPickerPopup(
                    controller: _emojiPickerPopupController,
                    onDismissed: () {
                      _emojiPickerOverlay?.remove();
                      _emojiPickerOverlay = null;
                      if (mounted) {
                        setState(() {
                          _showEmojiPicker = false;
                        });
                      }
                    },
                    onEmojiSelected: (emoji) {
                      _textController.text += emoji;
                      setState(() {});
                      _closeEmojiPicker();
                    },
                  ),
                ),
              ),
            ],
          );
        },
      );
      overlay.insert(_emojiPickerOverlay!);
      setState(() {
        _showEmojiPicker = true;
      });
    }
  }

  void _closeEmojiPicker() {
    _emojiPickerPopupController.close?.call();
  }

  void _closeEmojiPickerImmediate() {
    _emojiPickerOverlay?.remove();
    _emojiPickerOverlay = null;
    if (mounted && !_isDisposed) {
      setState(() {
        _showEmojiPicker = false;
      });
    }
  }

  Future<void> _showReactionPicker(BuildContext context, Offset position, ChatMessage message, LayerLink link) async {
    _showReactionPopup(
      context: context,
      link: link,
      message: message,
      isMe: message.senderId == 'me',
      position: position,
    );
  }

  void _dismissReactionPopupImmediate() {
    _reactionShowTimer?.cancel();
    _reactionShowTimer = null;
    _reactionHideTimer?.cancel();
    _reactionHideTimer = null;
    final changed = _reactionOverlayEntry != null || _hoveredMessageId != null;
    _reactionOverlayEntry?.remove();
    _reactionOverlayEntry = null;
    if (!_isTransitioningToFullPicker) {
      _hoveredMessageId = null;
    }
    if (changed && mounted && !_isDisposed) setState(() {});
  }

  void _closeReactionPopup() {
    _reactionPopupController.close?.call();
  }

  void _startReactionHideTimer() {
    if (_isTransitioningToFullPicker) return;
    _reactionHideTimer?.cancel();
    _reactionHideTimer = Timer(const Duration(milliseconds: 250), () {
      _closeReactionPopup();
    });
  }

  void _cancelReactionHideTimer() {
    _reactionHideTimer?.cancel();
    _reactionHideTimer = null;
  }

  void _showReactionPopup({
    required BuildContext context,
    required LayerLink link,
    required ChatMessage message,
    required bool isMe,
    required Offset position,
  }) {
    _reactionShowTimer?.cancel();
    _reactionShowTimer = null;
    _reactionHideTimer?.cancel();
    _reactionHideTimer = null;

    if (_hoveredMessageId == message.id && _reactionOverlayEntry != null) {
      return;
    }

    _dismissReactionPopupImmediate();

    _hoveredMessageId = message.id;

    final overlay = Overlay.of(context);
    final bool openDownward = position.dy < 80;

    _reactionOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: openDownward ? Alignment.bottomCenter : Alignment.topCenter,
          followerAnchor: openDownward ? Alignment.topCenter : Alignment.bottomCenter,
          offset: Offset(0, openDownward ? 8 : -8),
          child: Align(
            alignment: openDownward ? Alignment.topCenter : Alignment.bottomCenter,
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: Material(
              color: Colors.transparent,
              child: _MessengerReactionPopup(
                controller: _reactionPopupController,
                message: message,
                activeId: ref.read(activeThreadIdProvider)!,
                ref: ref,
                isMe: isMe,
                openDownward: openDownward,
                onDismissed: () {
                  _reactionOverlayEntry?.remove();
                  _reactionOverlayEntry = null;
                  _hoveredMessageId = null;   // trước đây thiếu dòng này
                  if (mounted) setState(() {});
                },
                onOpenFullPicker: () {
                  _isTransitioningToFullPicker = true;
                  _dismissReactionPopupImmediate();
                  _showFullEmojiPicker(context, message, link);
                  _isTransitioningToFullPicker = false;
                },
                onEnter: _cancelReactionHideTimer,
                onExit: _startReactionHideTimer,
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_reactionOverlayEntry!);
    if (mounted) setState(() {});
  }

  void _showFullEmojiPicker(BuildContext context, ChatMessage message, LayerLink link) {
    if (_fullEmojiPickerOverlay != null) {
      _closeFullEmojiPicker();
    } else {
      _closeFullEmojiPickerImmediate();
      _dismissReactionPopupImmediate();

      final overlay = Overlay.of(context);
      
      final RenderBox? targetBox = context.findRenderObject() as RenderBox?;
      if (targetBox == null) return;
      final targetPosition = targetBox.localToGlobal(Offset.zero);
      
      final bool openDownward = targetPosition.dy < 360;
      const double pickerWidth = 280.0;
      
      _fullEmojiPickerOverlay = OverlayEntry(
        builder: (overlayContext) {
          final screenWidth = MediaQuery.of(overlayContext).size.width;
          final targetWidth = targetBox.size.width;
          final targetCenterX = targetPosition.dx + targetWidth / 2;
          
          double popupLeft = targetCenterX - pickerWidth / 2;
          double adjustedLeft = popupLeft;
          if (adjustedLeft < 12) {
            adjustedLeft = 12;
          } else if (adjustedLeft + pickerWidth > screenWidth - 12) {
            adjustedLeft = screenWidth - 12 - pickerWidth;
          }
          
          double offsetX = adjustedLeft - targetPosition.dx;
          double arrowX = targetCenterX - adjustedLeft;
          
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closeFullEmojiPicker,
                  child: Container(color: Colors.transparent),
                ),
              ),
              CompositedTransformFollower(
                link: link,
                showWhenUnlinked: false,
                targetAnchor: openDownward ? Alignment.bottomLeft : Alignment.topLeft,
                followerAnchor: openDownward ? Alignment.topLeft : Alignment.bottomLeft,
                offset: Offset(offsetX, openDownward ? 8 : -8),
                child: Material(
                  color: Colors.transparent,
                  child: _FullEmojiPickerPopup(
                    controller: _fullEmojiPickerPopupController,
                    arrowAtBottom: !openDownward,
                    arrowX: arrowX,
                    message: message,
                    activeId: ref.read(activeThreadIdProvider)!,
                    ref: ref,
                    onDismissed: () {
                      _fullEmojiPickerOverlay?.remove();
                      _fullEmojiPickerOverlay = null;
                      _hoveredMessageId = null;
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ),
            ],
          );
        },
      );
      overlay.insert(_fullEmojiPickerOverlay!);
      if (mounted) setState(() {});
    }
  }

  void _closeFullEmojiPicker() {
    _fullEmojiPickerPopupController.close?.call();
  }

  void _closeFullEmojiPickerImmediate() {
    final changed = _fullEmojiPickerOverlay != null;
    _fullEmojiPickerOverlay?.remove();
    _fullEmojiPickerOverlay = null;
    _hoveredMessageId = null;
    if (changed && mounted && !_isDisposed) setState(() {});
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

class _MessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isMe;
  final BubbleGroupPosition groupPosition;
  final bool hasReply;
  final VoidCallback? onCallAgain;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.groupPosition,
    this.hasReply = false,
    this.onCallAgain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeThemeId = ref.watch(threadThemeProvider)[message.threadId] ?? 'default';
    final activeTheme = availableChatThemes.firstWhere((t) => t.id == activeThemeId, orElse: () => availableChatThemes.first);

    if (message.isRecalled) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: _getBubbleBorderRadius(isMe, groupPosition, hasReply: hasReply),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Text(
          isMe ? 'Bạn đã xóa một tin nhắn' : '${message.senderName} đã thu hồi một tin nhắn',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 14.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

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
          color: isMe ? null : activeTheme.recipientColor,
          gradient: isMe ? LinearGradient(colors: activeTheme.senderGradient) : null,
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

    if (message.type == MessageType.audio) {
      final isMissed = message.text.contains('nhỡ') || message.text.toLowerCase().contains('missed') || message.text == 'Đã nhỡ cuộc gọi thoại';
      final callTitle = isMissed ? 'Đã nhỡ cuộc gọi thoại' : 'Cuộc gọi thoại';
      
      String callSubtitle;
      if (isMissed) {
        final hour = message.timestamp.hour.toString().padLeft(2, '0');
        final minute = message.timestamp.minute.toString().padLeft(2, '0');
        callSubtitle = '$hour:$minute';
      } else {
        callSubtitle = message.text;
      }

      return Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF242526),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3A3B3C),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMissed ? Icons.phone_missed_rounded : Icons.phone_forwarded_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        callTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        callSubtitle,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ElevatedButton(
                onPressed: onCallAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A3B3C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Gọi lại',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isMe ? null : activeTheme.recipientColor,
        gradient: isMe ? LinearGradient(colors: activeTheme.senderGradient) : null,
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
    required BuildContext anchorContext, // 👈 context của chính nút "+" để đo vị trí
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

    final RenderBox? targetBox = anchorContext.findRenderObject() as RenderBox?;
    if (targetBox == null) return;
    final targetPosition = targetBox.localToGlobal(Offset.zero);
    final targetSize = targetBox.size;

    const double menuWidth = 320;
    const double menuHeight = 290;

    _entry = OverlayEntry(
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;

        // Đủ chỗ phía trên nút "+" không? Nếu không thì mở xuống dưới.
        final bool openUpward = targetPosition.dy - menuHeight - 12 > 0;

        double dx = targetPosition.dx - 8;
        // Không để popup tràn ra khỏi mép phải màn hình
        if (dx + menuWidth > screenSize.width - 12) {
          dx = screenSize.width - 12 - menuWidth;
        }
        if (dx < 12) dx = 12;

        final double offsetX = dx - targetPosition.dx;
        final double offsetY = openUpward
            ? -(menuHeight + 12)
            : (targetSize.height + 12);

        return Stack(
          children: [
            // Lớp chắn để tap ra ngoài thì đóng popup
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  close();
                  onClose();
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topLeft,
              followerAnchor: Alignment.topLeft,
              offset: Offset(offsetX, offsetY),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: menuWidth,
                  height: menuHeight,
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
              ),
            ),
          ],
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
        width: 480,
        height: 560,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chuyển tiếp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3A3B3C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search Input
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người và nhóm',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                fillColor: const Color(0xFF3A3B3C),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF0084FF), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                                      backgroundColor: alreadySent ? Colors.white10 : const Color(0xFF2E3E50),
                                      disabledBackgroundColor: Colors.white10,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      minimumSize: const Size(60, 32),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      alreadySent ? 'Đã gửi' : 'Gửi',
                                      style: TextStyle(
                                        color: alreadySent ? Colors.white38 : const Color(0xFF0084FF),
                                        fontSize: 13,
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
  final void Function(ChatMessage) onEdit;
  final void Function(ChatMessage, String) onReact;
  final Future<void> Function(BuildContext, ChatMessage, Offset, LayerLink) onShowReactionPicker;
  final void Function(BuildContext context, LayerLink link, ChatMessage message, Offset position) onBubbleHoverShow;
  final void Function() onBubbleHoverExit;
  final void Function() onBubbleHoverEnterCancelHide;
  final bool isMenuOpen;
  final VoidCallback? onCallAgain;
  final void Function(String) onScrollToMessage;

  const _InteractiveMessageRow({
    super.key,
    required this.message,
    required this.isMe,
    required this.showReceipt,
    required this.thread,
    required this.groupPosition,
    required this.onReply,
    required this.onEdit,
    required this.onReact,
    required this.onShowReactionPicker,
    required this.onBubbleHoverShow,
    required this.onBubbleHoverExit,
    required this.onBubbleHoverEnterCancelHide,
    required this.isMenuOpen,
    required this.onScrollToMessage,
    this.onCallAgain,
  });

  @override
  ConsumerState<_InteractiveMessageRow> createState() => _InteractiveMessageRowState();
}

class _InteractiveMessageRowState extends ConsumerState<_InteractiveMessageRow> with TickerProviderStateMixin {
  bool _isHovered = false;
  bool _isMenuOpen = false;

  final LayerLink _layerLink = LayerLink();
  Timer? _showDelayTimer;
  bool _isSmileHovered = false;

  late AnimationController _highlightController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 65,
      ),
    ]).animate(_highlightController);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.35).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.35, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 75,
      ),
    ]).animate(_highlightController);
  }

  @override
  void dispose() {
    _showDelayTimer?.cancel();
    _highlightController.dispose();
    super.dispose();
  }

  void highlight() {
    if (mounted) {
      _highlightController.forward(from: 0.0);
    }
  }

  Widget _buildInteractiveQuoteWidget(ChatMessage replyTo, bool isMe) {
    final isQuoteMedia = replyTo.type == MessageType.image || 
                         replyTo.type == MessageType.video || 
                         replyTo.type == MessageType.gif;

    Widget childWidget;
    if (isQuoteMedia) {
      childWidget = Container(
        width: 120,
        height: 85,
        margin: const EdgeInsets.only(bottom: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: _QuoteMediaPreview(message: replyTo),
              ),
              if (replyTo.type == MessageType.video)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      childWidget = Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04),
            width: 0.5,
          ),
        ),
        child: Text(
          replyTo.text.isNotEmpty
              ? replyTo.text
              : (replyTo.type == MessageType.file
                  ? (replyTo.fileName ?? '[Tệp tin]')
                  : '[Tin nhắn]'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return GestureDetector(
      onTap: () => widget.onScrollToMessage(replyTo.id),
      behavior: HitTestBehavior.opaque,
      child: childWidget,
    );
  }

  Widget _buildQuoteMediaPreview(ChatMessage replyTo) {
    if (replyTo.type == MessageType.video) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A3B3C), Color(0xFF1E1F20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.video_collection_rounded,
          color: Colors.white24,
          size: 28,
        ),
      );
    }

    final url = replyTo.mediaUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: const Color(0xFF1F1F21),
        child: const Icon(Icons.image_not_supported_rounded, color: Colors.white24, size: 24),
      );
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1F1F21),
          child: const Icon(Icons.image_not_supported_rounded, color: Colors.white24, size: 24),
        ),
      );
    } else {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1F1F21),
          child: const Icon(Icons.image_not_supported_rounded, color: Colors.white24, size: 24),
        ),
      );
    }
  }

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

            // Bubble block
            Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Reply header: curved arrow icon and text "Đạt đã trả lời 7 Sụa"
                if (message.replyTo != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.reply_rounded,
                          color: Colors.white.withValues(alpha: 0.55),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          message.senderId == message.replyTo!.senderId
                              ? (message.senderId == 'me' ? 'Bạn đã trả lời chính mình' : '${message.senderName} đã trả lời chính mình')
                              : '${message.senderId == 'me' ? 'Bạn' : message.senderName} đã trả lời ${message.replyTo!.senderId == 'me' ? 'bạn' : message.replyTo!.senderName}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (message.replyTo != null)
                  Padding(
                    padding: EdgeInsets.only(
                      right: isMe ? 4 : 0,
                      left: !isMe ? 4 : 0,
                    ),
                    child: _buildInteractiveQuoteWidget(message.replyTo!, isMe),
                  ),

                if (message.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                    child: Text(
                      'Đã ghim',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Row containing Main Bubble and Vertically Centered Hover Actions!
                // Row containing Main Bubble and Vertically Centered Hover Actions!
                Transform.translate(
                  offset: Offset(0, message.replyTo != null ? -12 : 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isMe && (_isHovered || widget.isMenuOpen || _isMenuOpen)) ...[
                        _buildHoverActions(context),
                      ],
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, childWidget) {
                            return Stack(
                              children: [
                                childWidget!,
                                if (_glowAnimation.value > 0.0)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: ClipRRect(
                                        borderRadius: _getBubbleBorderRadius(isMe, groupPosition, hasReply: false),
                                        child: Container(
                                          color: Colors.white.withOpacity(_glowAnimation.value),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _MessageBubble(
                                message: message,
                                isMe: isMe,
                                groupPosition: groupPosition,
                                hasReply: false,
                                onCallAgain: widget.onCallAgain,
                              ),
                              if (message.reactions.isNotEmpty && !message.isRecalled)
                                Positioned(
                                  bottom: -6,
                                  right: isMe ? 4 : null,
                                  left: !isMe ? 4 : null,
                                  child: _buildReactionsBadge(message),
                                ),
                              if (message.isPinned)
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF242526),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Transform.rotate(
                                      angle: 0.785,
                                      child: const Icon(
                                        Icons.push_pin_rounded,
                                        color: Colors.red,
                                        size: 13,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!isMe && (_isHovered || widget.isMenuOpen || _isMenuOpen)) ...[
                        _buildHoverActions(context),
                      ],
                    ],
                  ),
                ),

                // Wrap status and receipts in a translated Container to maintain alignment relative to shifted bubble
                Transform.translate(
                  offset: Offset(0, message.replyTo != null ? -12 : 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Spacer below bubble row if reactions are present to avoid overlapping next items/seen status
                      if (message.reactions.isNotEmpty && !message.isRecalled)
                        const SizedBox(height: 6),

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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoverActions(BuildContext context) {
    if (widget.message.isRecalled) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: _buildHoverActionIconButton(
          icon: Icons.more_vert_rounded,
          tooltip: 'Xem thêm',
          onTap: (btnContext) {
            final renderBox = btnContext.findRenderObject() as RenderBox;
            final position = renderBox.localToGlobal(Offset.zero);
            _showMoreMenu(btnContext, position);
          },
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CompositedTransformTarget(
            link: _layerLink,
            child: MouseRegion(
              onEnter: (_) {
                _isSmileHovered = true;
                widget.onBubbleHoverEnterCancelHide();
                _showDelayTimer?.cancel();
                _showDelayTimer = Timer(const Duration(milliseconds: 120), () {
                  if (_isSmileHovered && mounted) {
                    final renderBox = context.findRenderObject() as RenderBox;
                    final position = renderBox.localToGlobal(Offset.zero);
                    widget.onBubbleHoverShow(context, _layerLink, widget.message, position);
                  }
                });
              },
              onExit: (_) {
                _isSmileHovered = false;
                _showDelayTimer?.cancel();
                widget.onBubbleHoverExit();
              },
              child: _buildHoverActionIconButton(
                icon: Icons.sentiment_satisfied_alt_rounded,
                tooltip: 'Bày tỏ cảm xúc',
                onTap: (btnContext) async {
                  setState(() {
                    _isMenuOpen = true;
                  });
                  final renderBox = btnContext.findRenderObject() as RenderBox;
                  final position = renderBox.localToGlobal(Offset.zero);
                  widget.onShowReactionPicker(btnContext, widget.message, position, _layerLink);
                  if (mounted) {
                    setState(() {
                      _isMenuOpen = false;
                    });
                  }
                },
              ),
            ),
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

  void _showMoreMenu(BuildContext context, Offset position) async {
    setState(() {
      _isMenuOpen = true;
    });

    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    
    final bool canEditOrRecall = widget.message.senderId == 'me';
    final bool isTextMsg = widget.message.type == MessageType.text;
    final int itemCount = widget.message.isRecalled
        ? 2
        : (canEditOrRecall ? (isTextMsg ? 5 : 4) : 3);
    final double menuHeight = itemCount * 38.0 + 16.0;
    const double menuWidth = 160.0;

    final bool openUpward = position.dy > overlay.size.height - (menuHeight + 50);

    const double buttonWidth = 28.0;
    const double buttonHeight = 28.0;

    final double topCoord = openUpward 
        ? position.dy - menuHeight 
        : position.dy + buttonHeight;

    final double leftCoord = widget.isMe
        ? (position.dx + buttonWidth) - menuWidth
        : position.dx;

    final RelativeRect positionRect = RelativeRect.fromRect(
      Rect.fromLTWH(
        leftCoord,
        topCoord,
        menuWidth,
        menuHeight,
      ),
      Offset.zero & overlay.size,
    );

    final List<PopupMenuEntry<String>> menuItems = [];

    if (widget.message.isRecalled) {
      menuItems.addAll([
        const PopupMenuItem<String>(
          height: 38,
          value: 'remove_only',
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Gỡ',
              style: TextStyle(
                color: Color(0xFFE4E6EB),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const PopupMenuItem<String>(
          height: 38,
          value: 'report',
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Báo cáo',
              style: TextStyle(
                color: Color(0xFFE4E6EB),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ]);
    } else {
      if (canEditOrRecall && isTextMsg) {
        menuItems.add(
          const PopupMenuItem<String>(
            height: 38,
            value: 'edit',
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Chỉnh sửa',
                style: TextStyle(
                  color: Color(0xFFE4E6EB),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }

      if (canEditOrRecall) {
        menuItems.add(
          const PopupMenuItem<String>(
            height: 38,
            value: 'recall',
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Thu hồi',
                style: TextStyle(
                  color: Color(0xFFE4E6EB),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }

      menuItems.addAll([
        const PopupMenuItem<String>(
          height: 38,
          value: 'forward',
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Chuyển tiếp',
              style: TextStyle(
                color: Color(0xFFE4E6EB),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        PopupMenuItem<String>(
          height: 38,
          value: 'pin',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              widget.message.isPinned ? 'Bỏ ghim' : 'Ghim',
              style: const TextStyle(
                color: Color(0xFFE4E6EB),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const PopupMenuItem<String>(
          height: 38,
          value: 'report',
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Báo cáo',
              style: TextStyle(
                color: Color(0xFFE4E6EB),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ]);
    }

    final String? selected = await showMenu<String>(
      context: context,
      position: positionRect,
      color: const Color(0xFF242526),
      elevation: 8,
      shape: TooltipShapeBorder(
        arrowWidth: 12,
        arrowHeight: 8,
        arrowXFromLeft: widget.isMe ? null : buttonWidth / 2,
        arrowXFromRight: widget.isMe ? buttonWidth / 2 : null,
        radius: 12,
        arrowAtBottom: openUpward,
      ),
      items: menuItems,
    );

    if (selected != null) {
      switch (selected) {
        case 'edit':
          widget.onEdit(widget.message);
          break;
        case 'recall':
          final result = await RecallMessageDialog.show(context);
          if (result == 1) {
            ref.read(chatThreadsProvider.notifier).recallMessage(widget.thread.id, widget.message.id);
          } else if (result == 2) {
            ref.read(chatThreadsProvider.notifier).deleteMessage(widget.thread.id, widget.message.id);
          }
          break;
        case 'remove_only':
          final confirmed = await RemoveMessageDialog.show(context);
          if (confirmed == true) {
            ref.read(chatThreadsProvider.notifier).deleteMessage(widget.thread.id, widget.message.id);
          }
          break;
        case 'forward':
          showDialog(
            context: context,
            builder: (context) => _ForwardMessageDialog(
              mediaUrl: widget.message.mediaUrl ?? '',
              messageType: widget.message.type,
              text: widget.message.text,
            ),
          );
          break;
        case 'pin':
          ref.read(chatThreadsProvider.notifier).togglePinMessage(widget.thread.id, widget.message.id);
          break;
        case 'report':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã gửi báo cáo đoạn chat')),
          );
          break;
      }
    }

    if (mounted) {
      setState(() {
        _isMenuOpen = false;
      });
    }
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
    final reactionImages = {
      '❤️': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/2764.png',
      '😆': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f606.png',
      '😮': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f62e.png',
      '😢': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f622.png',
      '😡': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f621.png',
      '👍': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f44d.png',
    };

    final children = message.reactions.keys.map((emoji) {
      final count = message.reactions[emoji]!.length;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          reactionImages.containsKey(emoji)
              ? Image.network(
                  reactionImages[emoji]!,
                  width: 14,
                  height: 14,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(emoji, style: const TextStyle(fontSize: 11));
                  },
                )
              : Text(emoji, style: const TextStyle(fontSize: 11)),
          if (count > 1) ...[
            const SizedBox(width: 2),
            Text(
              '$count',
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF18191A),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class TooltipShapeBorder extends ShapeBorder {
  final double arrowWidth;
  final double arrowHeight;
  final double? arrowXFromRight;
  final double? arrowXFromLeft;
  final double radius;
  final bool arrowAtBottom;

  const TooltipShapeBorder({
    this.arrowWidth = 12.0,
    this.arrowHeight = 8.0,
    this.arrowXFromRight,
    this.arrowXFromLeft,
    this.radius = 12.0,
    this.arrowAtBottom = false,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(
        top: arrowAtBottom ? 0 : arrowHeight,
        bottom: arrowAtBottom ? arrowHeight : 0,
      );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double xArrow = arrowXFromLeft != null 
        ? rect.left + arrowXFromLeft! 
        : rect.right - (arrowXFromRight ?? 20.0);
    final double r = radius;
    final Path path = Path();

    if (arrowAtBottom) {
      final double bodyBottom = rect.bottom - arrowHeight;
      path.moveTo(rect.left + r, rect.top);
      path.lineTo(rect.right - r, rect.top);
      path.arcToPoint(Offset(rect.right, rect.top + r), radius: Radius.circular(r), clockwise: true);
      path.lineTo(rect.right, bodyBottom - r);
      path.arcToPoint(Offset(rect.right - r, bodyBottom), radius: Radius.circular(r), clockwise: true);
      
      path.lineTo(xArrow + arrowWidth / 2, bodyBottom);
      path.lineTo(xArrow, rect.bottom);
      path.lineTo(xArrow - arrowWidth / 2, bodyBottom);
      
      path.lineTo(rect.left + r, bodyBottom);
      path.arcToPoint(Offset(rect.left, bodyBottom - r), radius: Radius.circular(r), clockwise: true);
      path.lineTo(rect.left, rect.top + r);
      path.arcToPoint(Offset(rect.left + r, rect.top), radius: Radius.circular(r), clockwise: true);
    } else {
      final double bodyTop = rect.top + arrowHeight;
      path.moveTo(rect.left + r, bodyTop);
      path.lineTo(xArrow - arrowWidth / 2, bodyTop);
      path.lineTo(xArrow, rect.top);
      path.lineTo(xArrow + arrowWidth / 2, bodyTop);
      path.lineTo(rect.right - r, bodyTop);

      path.arcToPoint(Offset(rect.right, bodyTop + r), radius: Radius.circular(r), clockwise: true);
      path.lineTo(rect.right, rect.bottom - r);
      path.arcToPoint(Offset(rect.right - r, rect.bottom), radius: Radius.circular(r), clockwise: true);
      path.lineTo(rect.left + r, rect.bottom);
      path.arcToPoint(Offset(rect.left, rect.bottom - r), radius: Radius.circular(r), clockwise: true);
      path.lineTo(rect.left, bodyTop + r);
      path.arcToPoint(Offset(rect.left + r, bodyTop), radius: Radius.circular(r), clockwise: true);
    }
    
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class _FullEmojiPickerWidget extends StatefulWidget {
  final ChatMessage message;
  final String activeId;
  final WidgetRef ref;
  final VoidCallback? onClose;

  const _FullEmojiPickerWidget({
    required this.message,
    required this.activeId,
    required this.ref,
    this.onClose,
  });

  @override
  State<_FullEmojiPickerWidget> createState() => _FullEmojiPickerWidgetState();
}

class _FullEmojiPickerWidgetState extends State<_FullEmojiPickerWidget> {
  String _searchQuery = '';
  String _activeCategory = 'smileys';

  final Map<String, String> _categoryTitles = {
    'smileys': 'Mặt cười và hình người',
    'animals': 'Động vật và tự nhiên',
    'food': 'Đồ ăn và thức uống',
    'activities': 'Hoạt động',
    'travel': 'Du lịch và địa điểm',
    'objects': 'Đồ vật',
    'symbols': 'Biểu tượng',
    'flags': 'Lá cờ',
  };

  final Map<String, IconData> _categoryIcons = {
    'smileys': Icons.sentiment_satisfied_alt_rounded,
    'animals': Icons.pets_rounded,
    'food': Icons.restaurant_rounded,
    'activities': Icons.sports_soccer_rounded,
    'travel': Icons.directions_car_rounded,
    'objects': Icons.lightbulb_outline_rounded,
    'symbols': Icons.favorite_border_rounded,
    'flags': Icons.flag_outlined,
  };

  final Map<String, List<String>> _emojiData = {
    'smileys': ['😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🥸', '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗', '🤔', '🫣', '🤭', '🫢', '🫡', '🤫', '🫠', '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️', '🤟', '🤘', '👌', '👋', '💪'],
    'animals': ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', '🐤', '🦆', '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜', '🕷️', '🕸️', '🦂', '🐢', '🐍', '🦎', '🐙', '🦑', '🦞', '🦀', '🐠', '🐟', '🐬', '🐳', '🐋', '🦈', '🐊', '🐅', '🐆', '🦓', '🦍', '🦧', '🐘', '🐪', '🦒', '🦘', '🐏', '🐐', '🦌', '🐕', '🐈', '🐇', '🕊️'],
    'food': ['🍎', '🍏', '🍐', '🍑', '🍒', '🍓', '🍇', '🍉', '🍌', '🍋', '🍊', '🍍', '🥭', '🥥', '🥝', '🍅', '🍆', '🥑', '🥦', '🥬', '🥒', '🌽', '🥕', '🧄', '🧅', '🥔', '🍠', '🥐', '🥖', '🥨', '🥯', '🥞', '🧇', '🧀', '🍖', '🍗', '🥩', '🥓', '🍔', '🍟', '🍕', '🌭', '🥪', '🌮', '🌯', '🥚', '🍳', '🥘', '🍲', '🥣', '🥗', '🍿', '🧈', '🧂', '🍣', '🍤', '🍱', '🥟', '🍦', '🍧', '🍨', '🍩', '🍪', '🎂', '🍰', '🍫', '🍬', '🍭', '🍮', '🍯', '☕', '🍵', '🍶', '🍷', '🍸', '🍹', '🍺', '🍻', '🥤'],
    'activities': ['⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🪀', '', '🏓', '💡', '🏸', '🏒', '🏑', '🥍', '🏏', '⛳', '🎣', '🤿', '🥊', '🥋', '🛹', '🛼', '🏋️', '🤼', '🤸', '⛹️', '        ', '🤺', '🤾', '🏌️', '🏇', '🧘', '🏄', '🏊', '🤽', '🚣', '🧗', '🚴', '🏆', '🥇', '🥈', '🥉', '🏅', '🎖️', '🎗️', '🎟️', '🎪', '🎭', '🎨', '🎬', '🎤', '🎧', '🎼', '🎹', '🎸', '🎲', '♟️', '🎯', '🎳', '🎮', '🎰', '🧩'],
    'travel': ['🚗', '🚕', '🚙', '🚌', '🏎️', '🚓', '🚑', '🚒', '🚐', '🚚', '🚜', '🛵', '🏍️', '🛺', '🚲', '🚨', '🚥', '🚦', '🚧', '⚓', '⛵', '🚤', '🚢', '✈️', '🛫', '🛬', '🚁', '🚟', '🚀', '🛸', '🪐', '🌙', '☀️', '🌤️', '⛅', '🌥️', '☁️', '🌧️', '⛈️', '🌩️', '❄️', '⛄', '🔥', '💧', '🌊', '🎄', '✨', '🌈', '☂️', '⚡', '❄️', '⛄', '☄️', '🔥', '💧', '🌊'],
    'objects': ['⌚', '📱', '📲', '💻', '⌨️', '🖱️', '🕹️', '💿', '📼', '📷', '📸', '📹', '🎥', '📞', '📟', '📠', '📺', '📻', '🎙️', '🎛️', 'Compass', '🧭', '⏰', '⌛', '⏳', '📡', '🔋', '🔌', '💡', '🔦', '💵', '💴', '💶', '💷', '🪙', '💳', '✉️', '📧', '📨', '📩', '📤', '📥', '📦', '🏷️', '📁', '📂', '📅', '📆', '📊', '📋', '📌', '📍', '📎', '🔒', '🔓', '🔑', '🔨', '🔧', '🔩', '🔫', '💣', '🧨', '🛡️', '🔑', '🗝️', '🪓', '🔪', '🗡️'],
    'symbols': ['💘', '💝', '💖', '💗', '💓', '💞', '💕', '💟', '❣️', '💔', '❤️', '🧡', '💛', '💚', '💙', '💜', '🤎', '🖤', '🤍', '💯', '💢', '💥', '💫', '💦', '💨', '💬', '🗨️', '💭', '💤', '♠️', '♥️', '♦️', '♣️', '🃏', '🔇', '🔈', '🔉', '🔊', '📢', '📣', '🔔', '🔕', '🎼', '🎵', '🎶', '➕', '➖', '✖️', '➗', '♾️', '💲', '💱', '™️', '©️', '®️'],
    'flags': ['🏁', '🚩', '🎌', '🏴', '🏳️', '🏳️‍🌈', '🏳️‍⚧️', '🏴‍☠️', '🇻🇳', '🇺🇸', '🇯🇵', '🇰🇷', '🇨🇳', '🇫🇷', '🇩🇪', '🇬🇧', '🇷🇺', '🇮🇹', '🇪🇸', '🇨🇦', '🇦🇺', '🇧🇷', '🇮🇳', '🇸🇬', '🇹🇭', '🇲🇾', '🇵🇭', '🇮🇩'],
  };

  List<String> _getFilteredEmojis() {
    if (_searchQuery.isEmpty) {
      return _emojiData[_activeCategory] ?? [];
    }
    
    final List<String> results = [];
    for (var list in _emojiData.values) {
      for (var emoji in list) {
        if (!results.contains(emoji)) {
          results.add(emoji);
        }
      }
    }
    return results.where((e) => e.contains(_searchQuery) || _searchQuery.length < 3).take(48).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmojis = _getFilteredEmojis();
    final defaultEmojis = ['❤️', '😆', '😮', '😢', '😡', '👍'];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1F),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 8),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.4), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Tìm kiếm biểu tượng cảm xúc',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.05)),

          // 2. Main content scroll area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Your Reactions Section
                  if (_searchQuery.isEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cảm xúc của bạn',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Tùy chỉnh',
                          style: TextStyle(color: const Color(0xFF0084FF).withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: defaultEmojis.map((emoji) {
                        final reactionImages = {
                          '❤️': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/2764.png',
                          '😆': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f606.png',
                          '😮': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f62e.png',
                          '😢': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f622.png',
                          '😡': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f621.png',
                          '👍': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f44d.png',
                        };
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            widget.ref.read(chatThreadsProvider.notifier).addReaction(widget.activeId, widget.message.id, emoji);
                            if (widget.onClose != null) {
                              widget.onClose!();
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: reactionImages.containsKey(emoji)
                                ? Image.network(
                                    reactionImages[emoji]!,
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (context, error, stackTrace) => Text(emoji, style: const TextStyle(fontSize: 24)),
                                  )
                                : Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Category Grid Section
                  Text(
                    _searchQuery.isEmpty ? (_categoryTitles[_activeCategory] ?? '') : 'Kết quả tìm kiếm',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: filteredEmojis.map((emoji) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () {
                          widget.ref.read(chatThreadsProvider.notifier).addReaction(widget.activeId, widget.message.id, emoji);
                          if (widget.onClose != null) {
                            widget.onClose!();
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.05)),

          // 3. Category bar at the bottom
          Container(
            height: 38,
            color: const Color(0xFF161617),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _categoryIcons.keys.map((catKey) {
                final isSelected = catKey == _activeCategory && _searchQuery.isEmpty;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      _activeCategory = catKey;
                      _searchQuery = '';
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      _categoryIcons[catKey],
                      size: 16,
                      color: isSelected ? const Color(0xFF0084FF) : Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessengerReactionPopupController {
  Future<void> Function()? close;
}

class _MessengerReactionPopup extends StatefulWidget {
  final _MessengerReactionPopupController controller;
  final ChatMessage message;
  final String activeId;
  final WidgetRef ref;
  final bool isMe;
  final bool openDownward;
  final VoidCallback onDismissed;
  final VoidCallback onOpenFullPicker;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  const _MessengerReactionPopup({
    Key? key,
    required this.controller,
    required this.message,
    required this.activeId,
    required this.ref,
    required this.isMe,
    required this.openDownward,
    required this.onDismissed,
    required this.onOpenFullPicker,
    required this.onEnter,
    required this.onExit,
  }) : super(key: key);

  @override
  State<_MessengerReactionPopup> createState() => _MessengerReactionPopupState();
}

class _MessengerReactionPopupState extends State<_MessengerReactionPopup> with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _slideAnimation;

  int? _hoveredEmojiIndex;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(
      begin: widget.openDownward ? -6.0 : 6.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();

    widget.controller.close = () async {
      if (!mounted) return;
      try {
        await _entranceController.animateTo(0.0, duration: const Duration(milliseconds: 140), curve: Curves.easeInCubic);
      } catch (_) {
        // Safe to ignore if controller or state is disposed during animation
      }
      if (!mounted) return;
      widget.onDismissed();
    };
  }

  @override
  void dispose() {
    widget.controller.close = null;
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactionImages = {
      '❤️': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/2764.png',
      '😆': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f606.png',
      '😮': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f62e.png',
      '😢': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f622.png',
      '😡': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f621.png',
      '👍': 'https://cdnjs.cloudflare.com/ajax/libs/emojione/2.2.7/assets/png/1f44d.png',
    };

    final emojis = reactionImages.keys.toList();

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              alignment: widget.openDownward ? Alignment.topCenter : Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => widget.onEnter(),
        onExit: (_) => widget.onExit(),
        child: SizedBox(
          width: 276,
          height: 62, // 52 Capsule height + 10 arrow height
          child: CustomPaint(
            painter: _TooltipBackgroundPainter(
              arrowAtBottom: !widget.openDownward,
              arrowX: 138,
              color: const Color(0xFF242526),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: widget.openDownward ? 10 : 0,
                bottom: widget.openDownward ? 0 : 10,
              ),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: Colors.transparent, // Background and border are painted by CustomPaint
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ...List.generate(emojis.length, (index) {
                      final emoji = emojis[index];
                      final imageUrl = reactionImages[emoji]!;
                      
                      // Hover calculation
                      double scale = 1.0;
                      double translateY = 0.0;
                      double translateX = 0.0;

                      if (_hoveredEmojiIndex == index) {
                        scale = 1.32;
                        translateY = -10.0;
                      } else if (_hoveredEmojiIndex != null) {
                        if (index == _hoveredEmojiIndex! - 1) {
                          translateX = -3.0;
                        } else if (index == _hoveredEmojiIndex! + 1) {
                          translateX = 3.0;
                        }
                      }

                      return SizedBox(
                        width: 36,
                        height: 40,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: MouseRegion(
                                onEnter: (_) => setState(() => _hoveredEmojiIndex = index),
                                onExit: (_) => setState(() => _hoveredEmojiIndex = null),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    widget.ref.read(chatThreadsProvider.notifier).addReaction(widget.activeId, widget.message.id, emoji);
                                    widget.controller.close?.call();
                                  },
                                ),
                              ),
                            ),
                            IgnorePointer(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOutBack,
                                transform: Matrix4.identity()
                                  ..translate(translateX, translateY)
                                  ..scale(scale),
                                transformAlignment: Alignment.bottomCenter,
                                alignment: Alignment.center,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: _hoveredEmojiIndex == index
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    _ReactionPlusButton(
                      onTap: widget.onOpenFullPicker,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReactionPlusButton extends StatefulWidget {
  final VoidCallback onTap;

  const _ReactionPlusButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_ReactionPlusButton> createState() => _ReactionPlusButtonState();
}

class _ReactionPlusButtonState extends State<_ReactionPlusButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFF4E4F50) : const Color(0xFF3A3B3C),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessengerEmojiPickerPopupController {
  Future<void> Function()? close;
}

class _MessengerEmojiPickerPopup extends StatefulWidget {
  final _MessengerEmojiPickerPopupController controller;
  final VoidCallback onDismissed;
  final void Function(String) onEmojiSelected;

  const _MessengerEmojiPickerPopup({
    Key? key,
    required this.controller,
    required this.onDismissed,
    required this.onEmojiSelected,
  }) : super(key: key);

  @override
  State<_MessengerEmojiPickerPopup> createState() => _MessengerEmojiPickerPopupState();
}

class _MessengerEmojiPickerPopupState extends State<_MessengerEmojiPickerPopup> with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _keyboardFocusNode;

  String _searchQuery = '';
  int _activeCategoryIndex = 0;
  bool _isScrollingFromCategoryClick = false;

  final List<String> _categories = ['😀', '🐱', '🍔', '⚽', '🚗', '💡', '❤️', '🏳️'];
  final List<String> _categoryNames = [
    'Biểu tượng cảm xúc',
    'Động vật & Tự nhiên',
    'Đồ ăn & Thức uống',
    'Hoạt động',
    'Du lịch & Địa điểm',
    'Đồ vật',
    'Biểu tượng',
    'Cờ'
  ];

  static const Map<String, List<String>> _categoryEmojis = {
    '😀': ['😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓'],
    '🐱': ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸'],
    '🍔': ['🍎', '🍌', '🍇', '🍓', '🍉', '🍕', '🍔', '🍟', '🌭', '🍿', '🍩', '🍪', '🍫', '☕'],
    '⚽': ['⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🎱', '🏓', '🏸', '🥅', '🥇', '🏆'],
    '🚗': ['🚗', '🚕', '🚙', '🚌', '🏎️', '🏎️', '🏍️', '🚲', '✈️', '🚀', '🛸', '🚢', '⚓', '⛺'],
    '💡': ['💡', '🔦', '🕯️', '🔑', '🔨', '🛠️', '📦', '✏️', '✒️', '📅', '🗑️', '🔒', '🔔', '📢'],
    '❤️': ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓'],
    '🏳️': ['🏁', '🚩', '🎌', '🏴', '🏳️', '🏳️‍🌈', '🏳️‍⚧️', '🇺🇸', '🇻🇳', '🇬🇧', '🇫🇷', '🇯🇵', '🇰🇷', '🇨🇳'],
  };

  static const Map<String, String> _emojiKeywords = {
    '👍': 'like, thumbs up, ok, dong y, tot',
    '❤️': 'love, heart, tim, yeu',
    '😂': 'laugh, haha, lol, cuoi',
    '😮': 'wow, o, ngac nhien',
    '😢': 'sad, cry, khoc, buon',
    '😡': 'angry, hate, gian, phan no',
    '👌': 'ok, tot, duoc',
    '🎉': 'party, celebration, chuc mung, tiec',
    '🔥': 'fire, hot, lua',
    '✨': 'star, sparkle, lap lanh',
    '👀': 'eyes, look, nhin',
    '💯': '100, perfect, tram diem',
    '😀': 'smile, happy, cuoi, vui',
    '😃': 'smile, happy, cuoi, vui',
    '😄': 'smile, happy, cuoi, vui',
    '😁': 'smile, happy, grin, cuoi',
    '😆': 'smile, happy, laugh, cuoi',
    '😅': 'sweat, laugh, cuoi',
    '🤣': 'laugh, lol, cuoi',
    '😊': 'smile, happy, cuoi',
    '😇': 'angel, cuoi, thien than',
    '🙂': 'smile, cuoi',
    '🙃': 'upside down, cuoi',
    '😉': 'wink, nhay mat',
    '😌': 'relieved, nhe long',
    '😍': 'love, heart eyes, yeu',
    '🥰': 'love, hearts, yeu',
    '😘': 'kiss, yeu, hon',
    '🐶': 'dog, puppy, cho',
    '🐱': 'cat, meow, meo',
    '🍕': 'pizza, cake',
    '🍔': 'hamburger, burger, banh mi',
    '⚽': 'soccer, football, bong da',
    '🚗': 'car, oto',
    '💡': 'light bulb, sang kien, den',
    '🏁': 'flag, start, co',
    '🇻🇳': 'vietnam, co, quoc ky',
  };

  // Pre-calculated vertical section heights for scrolling alignment
  // Category 0 (😀) has 28 emojis = 4 rows. Height = 36 (Header) + 4 * 48 (rows) = 228
  // Categories 1 to 7 have 14 emojis = 2 rows. Height = 36 (Header) + 2 * 48 (rows) = 132
  final List<double> _sectionOffsets = [
    0.0,
    228.0,
    360.0,
    492.0,
    624.0,
    756.0,
    888.0,
    1020.0,
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();
    _keyboardFocusNode = FocusNode();

    widget.controller.close = () async {
      if (!mounted) return;
      try {
        await _entranceController.animateTo(0.0, duration: const Duration(milliseconds: 140), curve: Curves.easeInCubic);
      } catch (_) {
        // Safe to ignore if controller or state is disposed during animation
      }
      if (!mounted) return;
      widget.onDismissed();
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.close = null;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isScrollingFromCategoryClick || _searchQuery.isNotEmpty) return;
    final double offset = _scrollController.offset;
    
    // Find current category index based on scroll offset
    int activeIndex = 0;
    for (int i = 0; i < _sectionOffsets.length; i++) {
      if (offset >= _sectionOffsets[i] - 20) {
        activeIndex = i;
      }
    }

    if (activeIndex != _activeCategoryIndex) {
      setState(() {
        _activeCategoryIndex = activeIndex;
      });
    }
  }

  void _scrollToCategory(int index) {
    _isScrollingFromCategoryClick = true;
    setState(() {
      _activeCategoryIndex = index;
    });

    _scrollController.animateTo(
      _sectionOffsets[index],
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    ).then((_) => _isScrollingFromCategoryClick = false);
  }

  List<String> _getFilteredEmojis() {
    final cleanQuery = _searchQuery.toLowerCase().trim();
    if (cleanQuery.isEmpty) return [];

    final results = <String>[];
    for (final list in _categoryEmojis.values) {
      for (final emoji in list) {
        final keywords = _emojiKeywords[emoji] ?? '';
        if (keywords.contains(cleanQuery) || emoji.contains(cleanQuery)) {
          results.add(emoji);
        }
      }
    }
    return results.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final recentEmojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];
    final filteredResults = _getFilteredEmojis();

    return FocusScope(
      autofocus: true,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            widget.controller.close?.call();
          }
        },
        child: SizedBox(
          width: 360,
          height: 430, // 420px height + 10px arrow height
          child: CustomPaint(
            painter: _EmojiPickerBackgroundPainter(arrowAtBottom: true),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10), // Offset content upward for bottom arrow
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    // 1. Search Bar Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3B3C),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm biểu tượng cảm xúc',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(color: Color(0xFF0084FF), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2. Main Scrollable Emoji Grid or Search Results
                    Expanded(
                      child: _searchQuery.isNotEmpty
                          ? _buildSearchResults(filteredResults)
                          : _buildStandardCategoriesList(recentEmojis),
                    ),

                    // 3. Bottom Category Selector Bar (Hidden when searching)
                    if (_searchQuery.isEmpty) ...[
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF242526),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.05),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(_categories.length, (index) {
                            final bool isActive = _activeCategoryIndex == index;
                            return _CategoryBarIcon(
                              emoji: _categories[index],
                              isActive: isActive,
                              onTap: () => _scrollToCategory(index),
                            );
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<String> results) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy biểu tượng cảm xúc',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _EmojiGridItem(
          emoji: results[index],
          onTap: () => widget.onEmojiSelected(results[index]),
        );
      },
    );
  }

  Widget _buildStandardCategoriesList(List<String> recentEmojis) {
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      children: [
        // Recent Reactions Section ("Cảm xúc của bạn")
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cảm xúc của bạn',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Tùy chỉnh',
                      style: TextStyle(color: Color(0xFF0084FF), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: recentEmojis.map((emoji) {
                  return _RecentEmojiItem(
                    emoji: emoji,
                    onTap: () => widget.onEmojiSelected(emoji),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Categories & Grids
        ...List.generate(_categories.length, (catIdx) {
          final catIcon = _categories[catIdx];
          final catName = _categoryNames[catIdx];
          final list = _categoryEmojis[catIcon]!;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  catName,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, idx) {
                    return _EmojiGridItem(
                      emoji: list[idx],
                      onTap: () => widget.onEmojiSelected(list[idx]),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _EmojiGridItem extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiGridItem({
    Key? key,
    required this.emoji,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_EmojiGridItem> createState() => _EmojiGridItemState();
}

class _EmojiGridItemState extends State<_EmojiGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.25 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: _isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              widget.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentEmojiItem extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _RecentEmojiItem({
    Key? key,
    required this.emoji,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_RecentEmojiItem> createState() => _RecentEmojiItemState();
}

class _RecentEmojiItemState extends State<_RecentEmojiItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double translateY = _isHovered ? -6.0 : 0.0;
    final double scale = _isHovered ? 1.2 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, translateY)
            ..scale(scale),
          transformAlignment: Alignment.bottomCenter,
          child: Text(
            widget.emoji,
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}

class _CategoryBarIcon extends StatefulWidget {
  final String emoji;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryBarIcon({
    Key? key,
    required this.emoji,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_CategoryBarIcon> createState() => _CategoryBarIconState();
}

class _CategoryBarIconState extends State<_CategoryBarIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFF0084FF).withValues(alpha: 0.15)
                : (_isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isActive ? const Color(0xFF0084FF).withValues(alpha: 0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Opacity(
            opacity: widget.isActive ? 1.0 : (_isHovered ? 0.9 : 0.6),
            child: Text(
              widget.emoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiPickerBackgroundPainter extends CustomPainter {
  final bool arrowAtBottom;

  _EmojiPickerBackgroundPainter({required this.arrowAtBottom});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF242526)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    const double radius = 18.0;
    const double arrowW = 18.0;
    const double arrowH = 10.0;

    if (arrowAtBottom) {
      final rect = Rect.fromLTWH(0, 0, size.width, size.height - arrowH);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));
      path.addRRect(rrect);

      final double centerX = size.width / 2;
      path.moveTo(centerX - arrowW / 2, size.height - arrowH);
      path.lineTo(centerX, size.height);
      path.lineTo(centerX + arrowW / 2, size.height - arrowH);
      path.close();
    } else {
      final rect = Rect.fromLTWH(0, arrowH, size.width, size.height - arrowH);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));
      path.addRRect(rrect);

      final double centerX = size.width / 2;
      path.moveTo(centerX - arrowW / 2, arrowH);
      path.lineTo(centerX, 0);
      path.lineTo(centerX + arrowW / 2, arrowH);
      path.close();
    }

    canvas.drawShadow(
      path.shift(const Offset(0, 4)),
      Colors.black.withValues(alpha: 0.24),
      30.0,
      true,
    );

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _EmojiPickerBackgroundPainter oldDelegate) {
    return oldDelegate.arrowAtBottom != arrowAtBottom;
  }
}

class _FullEmojiPickerPopup extends StatefulWidget {
  final _MessengerEmojiPickerPopupController controller;
  final bool arrowAtBottom;
  final double arrowX;
  final ChatMessage message;
  final String activeId;
  final WidgetRef ref;
  final VoidCallback onDismissed;

  const _FullEmojiPickerPopup({
    Key? key,
    required this.controller,
    required this.arrowAtBottom,
    required this.arrowX,
    required this.message,
    required this.activeId,
    required this.ref,
    required this.onDismissed,
  }) : super(key: key);

  @override
  State<_FullEmojiPickerPopup> createState() => _FullEmojiPickerPopupState();
}

class _FullEmojiPickerPopupState extends State<_FullEmojiPickerPopup> with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _slideAnimation;
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(
      begin: widget.arrowAtBottom ? 8.0 : -8.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();
    _keyboardFocusNode = FocusNode();

    widget.controller.close = () async {
      if (!mounted) return;
      try {
        await _entranceController.animateTo(0.0, duration: const Duration(milliseconds: 140), curve: Curves.easeInCubic);
      } catch (_) {
        // Safe to ignore if controller or state is disposed during animation
      }
      if (!mounted) return;
      widget.onDismissed();
    };
  }

  @override
  void dispose() {
    widget.controller.close = null;
    _keyboardFocusNode.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              alignment: widget.arrowAtBottom ? Alignment.bottomCenter : Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: FocusScope(
        autofocus: true,
        child: KeyboardListener(
          focusNode: _keyboardFocusNode,
          onKeyEvent: (event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              widget.controller.close?.call();
            }
          },
          child: SizedBox(
            width: 280,
            height: 330, // 320px height + 10px arrow height
            child: CustomPaint(
              painter: _TooltipBackgroundPainter(
                arrowAtBottom: widget.arrowAtBottom,
                arrowX: widget.arrowX,
                color: const Color(0xFF1E1E1F),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: widget.arrowAtBottom ? 0 : 10,
                  bottom: widget.arrowAtBottom ? 10 : 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _FullEmojiPickerWidget(
                    message: widget.message,
                    activeId: widget.activeId,
                    ref: widget.ref,
                    onClose: () {
                      widget.controller.close?.call();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TooltipBackgroundPainter extends CustomPainter {
  final bool arrowAtBottom;
  final double arrowX;
  final Color color;

  _TooltipBackgroundPainter({
    required this.arrowAtBottom,
    required this.arrowX,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    const double radius = 16.0;
    const double arrowW = 18.0;
    const double arrowH = 10.0;

    if (arrowAtBottom) {
      final rect = Rect.fromLTWH(0, 0, size.width, size.height - arrowH);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));
      path.addRRect(rrect);

      path.moveTo(arrowX - arrowW / 2, size.height - arrowH);
      path.lineTo(arrowX, size.height);
      path.lineTo(arrowX + arrowW / 2, size.height - arrowH);
      path.close();
    } else {
      final rect = Rect.fromLTWH(0, arrowH, size.width, size.height - arrowH);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));
      path.addRRect(rrect);

      path.moveTo(arrowX - arrowW / 2, arrowH);
      path.lineTo(arrowX, 0);
      path.lineTo(arrowX + arrowW / 2, arrowH);
      path.close();
    }

    canvas.drawShadow(
      path.shift(const Offset(0, 4)),
      Colors.black.withValues(alpha: 0.24),
      24.0,
      true,
    );

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _TooltipBackgroundPainter oldDelegate) {
    return oldDelegate.arrowAtBottom != arrowAtBottom ||
        oldDelegate.arrowX != arrowX ||
        oldDelegate.color != color;
  }
}

class _QuoteMediaPreview extends StatefulWidget {
  final ChatMessage message;

  const _QuoteMediaPreview({required this.message});

  @override
  State<_QuoteMediaPreview> createState() => _QuoteMediaPreviewState();
}

class _QuoteMediaPreviewState extends State<_QuoteMediaPreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.message.type == MessageType.video) {
      _initVideo();
    }
  }

  void _initVideo() {
    final url = widget.message.mediaUrl;
    if (url == null || url.isEmpty) return;
    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        _controller = VideoPlayerController.file(File(url));
      }
      _controller!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((err) {
        debugPrint('Error quote video init: $err');
      });
    } catch (e) {
      debugPrint('Error quote video create: $e');
    }
  }

  @override
  void didUpdateWidget(_QuoteMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.mediaUrl != widget.message.mediaUrl ||
        oldWidget.message.type != widget.message.type) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      if (widget.message.type == MessageType.video) {
        _initVideo();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.message.type;
    final url = widget.message.mediaUrl;

    if (type == MessageType.video) {
      if (_isInitialized && _controller != null) {
        return VideoPlayer(_controller!);
      }
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A3B3C), Color(0xFF1E1F20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.video_collection_rounded,
          color: Colors.white24,
          size: 28,
        ),
      );
    }

    // Otherwise, render image / gif
    if (url == null || url.isEmpty) {
      return Container(
        color: const Color(0xFF1F1F21),
        child: const Icon(Icons.image_not_supported_rounded, color: Colors.white24, size: 24),
      );
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1F1F21),
          child: const Icon(Icons.image_not_supported_rounded, color: Colors.white24, size: 24),
        ),
      );
    } else {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1F1F21),
          child: const Icon(Icons.image_not_supported_rounded, color: Colors.white24, size: 24),
        ),
      );
    }
  }
}

