import 'package:to_do_app/features/social/presentation/widgets/premium_toast.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/theme/design_tokens.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/data/datasource/attachment_datasource.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/feed_provider.dart';
import 'package:to_do_app/features/social/presentation/widgets/post_backgrounds.dart';
import 'package:to_do_app/features/social/presentation/widgets/emoji_popover.dart';

enum AttachmentType { none, media, task, achievement, poll }
enum ComposerScreen { main, backgroundPicker, addOptions, settings }

class PostComposerModal extends ConsumerStatefulWidget {
  const PostComposerModal({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<PostComposerModal> createState() => _PostComposerModalState();
}

class _PostComposerModalState extends ConsumerState<PostComposerModal> {
  final TextEditingController _contentController = TextEditingController();
  final LayerLink _emojiLayerLink = LayerLink();
  final GlobalKey _emojiTriggerKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  
  // Active screen and attachment states
  ComposerScreen _currentScreen = ComposerScreen.main;
  AttachmentType _activeAttachment = AttachmentType.none;

  // Tab 0: Image/File Attachment
  XFile? _selectedImage;
  PlatformFileInfo? _selectedFile;

  // Tab 1: Task Attachment
  NexusTask? _selectedTask;

  // Tab 2: Achievement Attachment
  String? _selectedAchievement;

  // Tab 3: Survey/Poll Creator
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(text: ''),
    TextEditingController(text: ''),
  ];

  bool _isPosting = false;

  // Background and Emoji States
  bool _showAaBar = false;
  String? _selectedBackgroundId;
  bool _showEmojiPicker = false;
  bool _shouldShowPopoverBelow = false;

  // Post Settings Screen States
  bool _boostPost = false;
  String _audience = 'Công khai';
  DateTime? _scheduledDateTime;
  final List<String> _selectedGroups = [];
  bool _monetizationEnabled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkPopoverDirection);
    _contentController.addListener(_onContentChanged);
    // Map initialTab to initial attachment type
    if (widget.initialTab == 0) {
      _activeAttachment = AttachmentType.media;
      // Trigger image picker immediately after layout build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImage();
      });
    } else if (widget.initialTab == 1) {
      _activeAttachment = AttachmentType.task;
    } else if (widget.initialTab == 2) {
      _activeAttachment = AttachmentType.achievement;
    } else if (widget.initialTab == 3) {
      _activeAttachment = AttachmentType.poll;
    } else {
      _activeAttachment = AttachmentType.none;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkPopoverDirection);
    _scrollController.dispose();
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    for (var controller in _pollOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onContentChanged() {
    setState(() {});
  }

  void _checkPopoverDirection() {
    if (!_showEmojiPicker) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = _emojiTriggerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        
        // Popover height is 348. We need at least 360px above the trigger button.
        // If Y is less than 360, show below.
        final showBelow = position.dy < 360.0;
        
        if (showBelow != _shouldShowPopoverBelow) {
          if (mounted) {
            setState(() {
              _shouldShowPopoverBelow = showBelow;
            });
          }
        }
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _selectedFile = null;
          _activeAttachment = AttachmentType.media;
          _showEmojiPicker = false;
        });
      } else {
        if (_selectedImage == null && _selectedFile == null) {
          setState(() {
            _activeAttachment = AttachmentType.none;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Lỗi chọn ảnh: $e', isError: true);
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'zip', 'doc', 'docx', 'txt', 'csv', 'xlsx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFile = PlatformFileInfo(
            name: file.name,
            sizeBytes: file.size,
            extension: file.extension ?? '',
            bytes: file.bytes,
            filePath: kIsWeb ? null : file.path,
          );
          _selectedImage = null;
          _activeAttachment = AttachmentType.media;
          _showEmojiPicker = false;
        });
      } else {
        if (_selectedImage == null && _selectedFile == null) {
          setState(() {
            _activeAttachment = AttachmentType.none;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Lỗi chọn file: $e', isError: true);
      }
    }
  }

  void _addPollOption() {
    if (_pollOptionControllers.length < 4) {
      setState(() {
        _pollOptionControllers.add(TextEditingController());
      });
    }
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length > 2) {
      setState(() {
        final controller = _pollOptionControllers.removeAt(index);
        controller.dispose();
      });
    }
  }

  Future<void> _submitPost() async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;

    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImage == null && _selectedFile == null && _selectedTask == null && _selectedAchievement == null) {
      PremiumToast.show(context, 'Vui lòng nhập nội dung bài viết');
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      String type = 'text';
      String? mediaUrl;
      String? referenceId;
      Map<String, dynamic>? metaData;

      // Handle media attachment
      if (_activeAttachment == AttachmentType.media) {
        // Handle Image Upload
        if (_selectedImage != null) {
          type = 'photo';
          final fileBytes = await _selectedImage!.readAsBytes();
          final name = 'post_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final path = '${currentUser.id}/$name';
          
          await Supabase.instance.client.storage.from('post-attachments').uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );
          mediaUrl = Supabase.instance.client.storage.from('post-attachments').getPublicUrl(path);
        }

        // Handle File Upload
        if (_selectedFile != null) {
          type = 'file';
          final name = 'post_file_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.${_selectedFile!.extension}';
          final path = '${currentUser.id}/$name';

          final fileBytes = _selectedFile!.bytes ?? 
              (kIsWeb ? null : await File(_selectedFile!.filePath!).readAsBytes());

          if (fileBytes != null) {
            await Supabase.instance.client.storage.from('post-attachments').uploadBinary(
              path,
              fileBytes,
              fileOptions: const FileOptions(upsert: true),
            );
            mediaUrl = Supabase.instance.client.storage.from('post-attachments').getPublicUrl(path);
            metaData = {
              'fileName': _selectedFile!.name,
              'fileSize': _selectedFile!.sizeBytes,
              'fileExtension': _selectedFile!.extension,
            };
          } else {
            throw Exception('Không thể đọc dữ liệu từ file đã chọn');
          }
        }
      }

      // Handle Task attachment
      if (_activeAttachment == AttachmentType.task && _selectedTask != null) {
        type = 'task';
        referenceId = _selectedTask!.id;
        metaData = {
          'taskTitle': _selectedTask!.title,
          'taskStatus': _selectedTask!.status,
          'taskPriority': _selectedTask!.priority,
        };
      }

      // Handle Achievement attachment
      if (_activeAttachment == AttachmentType.achievement && _selectedAchievement != null) {
        type = 'achievement';
        metaData = {
          'achievementTitle': _selectedAchievement,
          'achievementDesc': 'Hoàn thành các cột mốc trong NEXUS AI',
        };
      }

      // Handle Poll attachment
      if (_activeAttachment == AttachmentType.poll) {
        final options = _pollOptionControllers
            .map((c) => c.text.trim())
            .where((opt) => opt.isNotEmpty)
            .toList();

        if (options.length >= 2) {
          type = 'poll';
          metaData = {
            'pollOptions': options,
            'votes': <String, String>{}, // userId: option
          };
        }
      }

      // Save background ID if active and no attachments are present
      if (_selectedBackgroundId != null && _activeAttachment == AttachmentType.none) {
        metaData ??= {};
        metaData['background_id'] = _selectedBackgroundId;
      }

      // Save additional post settings in metaData
      metaData ??= {};
      metaData['audience'] = _audience;
      if (_scheduledDateTime != null) {
        metaData['scheduled_at'] = _scheduledDateTime!.toIso8601String();
      }
      if (_selectedGroups.isNotEmpty) {
        metaData['shared_groups'] = _selectedGroups;
      }
      if (_monetizationEnabled) {
        metaData['monetization_enabled'] = true;
      }
      if (_boostPost) {
        metaData['boosted'] = true;
      }

      final feedService = ref.read(feedServiceProvider);
      await feedService.createPost(
        userId: currentUser.id,
        type: type,
        content: content,
        mediaUrl: mediaUrl,
        referenceId: referenceId,
        metaData: metaData,
      );

      if (mounted) {
        Navigator.pop(context);
        PremiumToast.show(context, 'Đăng bài viết thành công!');
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Lỗi đăng bài: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userTasksProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;

    // Extract first name for the hint text
    final fullName = profile?.fullName ?? profile?.username ?? 'Bạn';
    final firstName = fullName.split(' ').first;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.6),
      body: Center(
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 640),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Dialog Main Content (Switch screens depending on state)
              _buildActiveScreen(firstName, tasksAsync, profileAsync),

              // Floating Emoji Popover (aligned dynamically relative to target smiley icon)
              if (_showEmojiPicker && _currentScreen == ComposerScreen.main)
                CompositedTransformFollower(
                  link: _emojiLayerLink,
                  showWhenUnlinked: false,
                  targetAnchor: _shouldShowPopoverBelow ? Alignment.bottomRight : Alignment.topRight,
                  followerAnchor: _shouldShowPopoverBelow ? Alignment.topRight : Alignment.bottomRight,
                  offset: Offset(0, _shouldShowPopoverBelow ? 4 : -4), // Dynamic gap based on direction
                  child: TapRegion(
                    groupId: 'post_composer_emoji',
                    onTapOutside: (_) {
                      setState(() {
                        _showEmojiPicker = false;
                      });
                    },
                    child: EmojiPopover(
                      arrowOffset: 12.0,
                      isArrowTop: _shouldShowPopoverBelow,
                      onEmojiSelected: (emoji) {
                        final text = _contentController.text;
                        final selection = _contentController.selection;
                        final start = selection.start >= 0 ? selection.start : text.length;
                        final end = selection.end >= 0 ? selection.end : text.length;
                        final newText = text.replaceRange(start, end, emoji);
                        _contentController.value = TextEditingValue(
                          text: newText,
                          selection: TextSelection.collapsed(offset: start + emoji.length),
                        );
                      },
                      onClose: () {
                        setState(() {
                          _showEmojiPicker = false;
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveScreen(String firstName, AsyncValue<List<NexusTask>> tasksAsync, AsyncValue<UserProfileModel?> profileAsync) {
    switch (_currentScreen) {
      case ComposerScreen.backgroundPicker:
        return _buildBackgroundPickerScreen();
      case ComposerScreen.addOptions:
        return _buildAddOptionsScreen();
      case ComposerScreen.settings:
        return _buildSettingsScreen();
      case ComposerScreen.main:
        return _buildMainComposerScreen(firstName, tasksAsync, profileAsync);
    }
  }

  Widget _buildMainComposerScreen(String firstName, AsyncValue<List<NexusTask>> tasksAsync, AsyncValue<UserProfileModel?> profileAsync) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Spacer(),
              const Text(
                'Tạo bài viết',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Close button in circle (Image 1 style)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: DesignTokens.borderSubtle, height: 1),

        // Scrollable Area (User Info, Input, Attachments)
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Info (Image 1 style)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: profileAsync.valueOrNull?.avatarUrl != null && profileAsync.valueOrNull!.avatarUrl!.isNotEmpty
                            ? NetworkImage(profileAsync.valueOrNull!.avatarUrl!)
                            : null,
                        backgroundColor: Colors.grey.shade800,
                        child: profileAsync.valueOrNull?.avatarUrl == null || profileAsync.valueOrNull!.avatarUrl!.isEmpty
                            ? const Icon(Icons.person, color: Colors.white54)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileAsync.valueOrNull?.fullName ?? profileAsync.valueOrNull?.username ?? 'Bạn',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Public Dropdown (Image 1 style)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.public, color: Colors.white.withOpacity(0.6), size: 12),
                                const SizedBox(width: 6),
                                Text(
                                  'Công khai',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.6), size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Text Input Area with background or standard
                _buildInputArea(firstName),

                // Aa Toggle Row (Aa button or background circles)
                if (_activeAttachment == AttachmentType.none)
                  _buildAaRow(),

                // If media attachment is active, render photo/file preview/upload box
                if (_activeAttachment == AttachmentType.media)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: _buildImageTab(),
                  ),

                // Dynamic attachment preview widget (for task, achievement, poll)
                _buildAttachmentPreview(tasksAsync, profileAsync),
              ],
            ),
          ),
        ),

        // "Thêm vào bài viết của bạn" Card
        _buildAddToPostCard(),

        // Footer Post Button (triggers Settings view)
        const Divider(color: DesignTokens.borderSubtle, height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              gradient: DesignTokens.gradientPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: (_contentController.text.trim().isEmpty &&
                      _selectedImage == null &&
                      _selectedFile == null &&
                      _selectedTask == null &&
                      _selectedAchievement == null)
                  ? null
                  : () {
                      setState(() {
                        _currentScreen = ComposerScreen.settings;
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Tiếp',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea(String firstName) {
    if (_selectedBackgroundId != null && _activeAttachment == AttachmentType.none) {
      final bg = getPostBackgroundById(_selectedBackgroundId!);
      if (bg != null) {
        return Container(
          height: 280,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          decoration: bg.getDecoration(),
          child: TextField(
            controller: _contentController,
            maxLines: null,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: bg.textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: '$firstName ơi, bạn đang nghĩ gì thế?',
              hintStyle: TextStyle(
                color: bg.textColor.withOpacity(0.6),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        );
      }
    }

    final showEmojiInTextInput = _activeAttachment != AttachmentType.none;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: '$firstName ơi, bạn đang nghĩ gì thế?',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 18),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (showEmojiInTextInput)
            TapRegion(
              groupId: 'post_composer_emoji',
              child: CompositedTransformTarget(
                key: _emojiTriggerKey,
                link: _emojiLayerLink,
                child: IconButton(
                  icon: Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    color: _showEmojiPicker ? const Color(0xFF1877F2) : Colors.white60,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _showEmojiPicker = !_showEmojiPicker;
                    });
                    _checkPopoverDirection();
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAaRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!_showAaBar) ...[
            // Closed Aa button (Image 1 gradient square)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAaBar = true;
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF56040)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Aa',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Expanded Aa bar row (Image 2 style)
            Expanded(
              child: Row(
                children: [
                  // Back/Chevron left button
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _showAaBar = false;
                      });
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  // Horizontal scrollable preview circles
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          // Slash circle (None background)
                          _buildPreviewCircle(
                            isSelected: _selectedBackgroundId == null,
                            onTap: () {
                              setState(() {
                                _selectedBackgroundId = null;
                              });
                            },
                            child: Container(
                              color: Colors.black38,
                              child: CustomPaint(
                                painter: _SlashPainter(),
                              ),
                            ),
                          ),
                          // Previews of popular styles
                          ...[
                            'grad_purple_pink',
                            'grad_blue_purple',
                            'grad_orange_yellow',
                            'grad_dark_grey',
                            'solid_red',
                            'solid_magenta',
                            'solid_dark',
                          ].map((id) {
                            final bg = getPostBackgroundById(id);
                            if (bg == null) return const SizedBox.shrink();
                            return _buildPreviewCircle(
                              isSelected: _selectedBackgroundId == id,
                              onTap: () {
                                setState(() {
                                  _selectedBackgroundId = id;
                                  // Mutual exclusivity with attachments
                                  _activeAttachment = AttachmentType.none;
                                  _selectedImage = null;
                                  _selectedFile = null;
                                  _selectedTask = null;
                                  _selectedAchievement = null;
                                });
                              },
                              decoration: bg.getDecoration(),
                            );
                          }),
                          // Grid button (four squares icon) to see all
                          _buildPreviewCircle(
                            isSelected: _currentScreen == ComposerScreen.backgroundPicker,
                            onTap: () {
                              setState(() {
                                _currentScreen = ComposerScreen.backgroundPicker;
                              });
                            },
                            child: Container(
                              color: Colors.white.withOpacity(0.08),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Emojis Smiley Button on the right
          TapRegion(
            groupId: 'post_composer_emoji',
            child: CompositedTransformTarget(
              key: _emojiTriggerKey,
              link: _emojiLayerLink,
              child: IconButton(
                icon: Icon(
                  Icons.sentiment_satisfied_alt_rounded,
                  color: _showEmojiPicker ? const Color(0xFF1877F2) : Colors.white60,
                  size: 24,
                ),
                onPressed: () {
                  setState(() {
                    _showEmojiPicker = !_showEmojiPicker;
                  });
                  _checkPopoverDirection();
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCircle({
    required VoidCallback onTap,
    Widget? child,
    Decoration? decoration,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF1877F2) : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipOval(
          child: child ?? Container(decoration: decoration),
        ),
      ),
    );
  }

  Widget _buildAddToPostCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Thêm vào bài viết của bạn',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Row(
            children: [
              _buildAddIconButton(
                icon: Icons.photo_library_rounded,
                color: const Color(0xFF45BD62),
                tooltip: 'Ảnh/Video/Tệp',
                onTap: () async {
                  setState(() {
                    _selectedBackgroundId = null; // Clear background
                    _showEmojiPicker = false;
                  });
                  await _pickImage();
                },
              ),
              _buildAddIconButton(
                icon: Icons.assignment_turned_in_rounded,
                color: const Color(0xFF1877F2),
                tooltip: 'Đính kèm Công việc',
                onTap: () {
                  setState(() {
                    _activeAttachment = AttachmentType.task;
                    _selectedBackgroundId = null; // Clear background
                    _showEmojiPicker = false;
                  });
                },
              ),
              _buildAddIconButton(
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFF7B125),
                tooltip: 'Khoe thành tích',
                onTap: () {
                  setState(() {
                    _activeAttachment = AttachmentType.achievement;
                    _selectedBackgroundId = null; // Clear background
                    _showEmojiPicker = false;
                  });
                },
              ),
              _buildAddIconButton(
                icon: Icons.location_on_rounded,
                color: const Color(0xFFF14636),
                tooltip: 'Check-in',
                onTap: () {
                  PremiumToast.show(context, 'Chức năng Check-in đang phát triển');
                },
              ),
              _buildAddIconButton(
                icon: Icons.chat_bubble_rounded,
                color: const Color(0xFF25D366),
                tooltip: 'Gửi tin nhắn',
                onTap: () {
                  PremiumToast.show(context, 'Chức năng gửi tin nhắn đang phát triển');
                },
              ),
              _buildAddIconButton(
                icon: Icons.more_horiz_rounded,
                color: Colors.white54,
                tooltip: 'Xem thêm',
                onTap: () {
                  setState(() {
                    _currentScreen = ComposerScreen.addOptions;
                    _showEmojiPicker = false;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(AsyncValue<List<NexusTask>> tasksAsync, AsyncValue<UserProfileModel?> profileAsync) {
    // Exclude media because it is rendered directly under the text field without the wrapper card
    if (_activeAttachment == AttachmentType.none || _activeAttachment == AttachmentType.media) {
      return const SizedBox.shrink();
    }

    Widget child;
    String title = '';
    
    switch (_activeAttachment) {
      case AttachmentType.task:
        title = 'Công việc đính kèm';
        child = _buildTaskTab(tasksAsync);
        break;
      case AttachmentType.achievement:
        title = 'Thành tích đính kèm';
        child = _buildAchievementTab(profileAsync);
        break;
      case AttachmentType.poll:
        title = 'Khảo sát bình chọn';
        child = _buildPollTab();
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white54),
                onPressed: () {
                  setState(() {
                    _activeAttachment = AttachmentType.none;
                    _selectedTask = null;
                    _selectedAchievement = null;
                  });
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildBackgroundPickerScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentScreen = ComposerScreen.main;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Chọn phông nền',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32), // Spacer to balance back arrow
            ],
          ),
        ),
        const Divider(color: DesignTokens.borderSubtle, height: 1),
        
        // Body Scrollable categories
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPickerCategorySection('Trang trí', decorationBgs),
              const SizedBox(height: 20),
              _buildPickerCategorySection('Màu chuyển sắc', gradientBgs),
              const SizedBox(height: 20),
              _buildPickerCategorySection('Một màu trơn', solidBgs),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickerCategorySection(String title, List<PostBackground> backgrounds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: backgrounds.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final bg = backgrounds[index];
            final isSelected = _selectedBackgroundId == bg.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBackgroundId = bg.id;
                  // Clear attachments
                  _activeAttachment = AttachmentType.none;
                  _selectedImage = null;
                  _selectedFile = null;
                  _selectedTask = null;
                  _selectedAchievement = null;
                  _currentScreen = ComposerScreen.main;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1877F2) : Colors.white12,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    decoration: bg.getDecoration(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddOptionsScreen() {
    final List<Map<String, dynamic>> items = [
      {
        'label': 'Ảnh/video',
        'icon': Icons.photo_library_rounded,
        'color': const Color(0xFF45BD62),
        'onTap': () async {
          setState(() {
            _selectedBackgroundId = null;
            _showEmojiPicker = false;
          });
          await _pickImage();
          setState(() {
            _currentScreen = ComposerScreen.main;
          });
        },
      },
      {
        'label': 'Tải lên tệp tin',
        'icon': Icons.insert_drive_file_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () async {
          setState(() {
            _selectedBackgroundId = null;
            _showEmojiPicker = false;
          });
          await _pickFile();
          setState(() {
            _currentScreen = ComposerScreen.main;
          });
        },
      },
      {
        'label': 'Gắn thẻ người khác',
        'icon': Icons.person_add_alt_1_rounded,
        'color': const Color(0xFF1877F2),
        'onTap': () {
          setState(() {
            _currentScreen = ComposerScreen.main;
            _showEmojiPicker = false;
          });
          PremiumToast.show(context, 'Chức năng gắn thẻ đang phát triển');
        },
      },
      {
        'label': 'Cảm xúc/hoạt động',
        'icon': Icons.sentiment_satisfied_rounded,
        'color': const Color(0xFFF7B125),
        'onTap': () {
          setState(() {
            _currentScreen = ComposerScreen.main;
            _showEmojiPicker = false;
          });
          PremiumToast.show(context, 'Chức năng cảm xúc đang phát triển');
        },
      },
      {
        'label': 'Check in',
        'icon': Icons.location_on_rounded,
        'color': const Color(0xFFF14636),
        'onTap': () {
          setState(() {
            _currentScreen = ComposerScreen.main;
            _showEmojiPicker = false;
          });
          PremiumToast.show(context, 'Chức năng Check-in đang phát triển');
        },
      },
      {
        'label': 'Nhận tin nhắn WhatsApp',
        'icon': Icons.chat_bubble_rounded,
        'color': const Color(0xFF25D366),
        'onTap': () {
          setState(() {
            _currentScreen = ComposerScreen.main;
            _showEmojiPicker = false;
          });
          PremiumToast.show(context, 'Chức năng WhatsApp đang phát triển');
        },
      },
      {
        'label': 'Nhận cuộc gọi',
        'icon': Icons.phone_rounded,
        'color': const Color(0xFF1877F2),
        'onTap': () {
          setState(() {
            _currentScreen = ComposerScreen.main;
            _showEmojiPicker = false;
          });
          PremiumToast.show(context, 'Chức năng nhận cuộc gọi đang phát triển');
        },
      },
      {
        'label': 'Mới cộng tác viên',
        'icon': Icons.group_add_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () {
          setState(() {
            _currentScreen = ComposerScreen.main;
            _showEmojiPicker = false;
          });
          PremiumToast.show(context, 'Chức năng mời cộng tác viên đang phát triển');
        },
      },
      {
        'label': 'Ảnh GIF',
        'icon': Icons.gif_box_rounded,
        'color': const Color(0xFF00ADB5),
        'onTap': () {
          setState(() {
            _currentScreen = ComposerScreen.main;
            _showEmojiPicker = false;
          });
          PremiumToast.show(context, 'Chức năng ảnh GIF đang phát triển');
        },
      },
      {
        'label': 'Video trực tiếp',
        'icon': Icons.videocam_rounded,
        'color': const Color(0xFFEF4444),
        'onTap': () {
          setState(() {
            _currentScreen = ComposerScreen.main;
            _showEmojiPicker = false;
          });
          PremiumToast.show(context, 'Chức năng video trực tiếp đang phát triển');
        },
      },
      {
        'label': 'Cột mốc (Thành tích)',
        'icon': Icons.flag_rounded,
        'color': const Color(0xFF1877F2),
        'onTap': () {
          setState(() {
            _activeAttachment = AttachmentType.achievement;
            _selectedBackgroundId = null;
            _currentScreen = ComposerScreen.main;
            _showEmojiPicker = false;
          });
        },
      },
      {
        'label': 'Đính kèm công việc (Task)',
        'icon': Icons.checklist_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () {
          setState(() {
            _activeAttachment = AttachmentType.task;
            _selectedBackgroundId = null;
            _currentScreen = ComposerScreen.main;
            _showEmojiPicker = false;
          });
        },
      },
      {
        'label': 'Khảo sát bình chọn (Poll)',
        'icon': Icons.bar_chart_rounded,
        'color': const Color(0xFFA78BFA),
        'onTap': () {
          setState(() {
            _activeAttachment = AttachmentType.poll;
            _selectedBackgroundId = null;
            _currentScreen = ComposerScreen.main;
            _showEmojiPicker = false;
          });
        },
      },
      {
        'label': 'Gắn thẻ đối tác kinh doanh',
        'icon': Icons.handshake_rounded,
        'color': const Color(0xFFF59E0B),
        'onTap': () {
          setState(() => _currentScreen = ComposerScreen.main);
          PremiumToast.show(context, 'Chức năng đối tác kinh doanh đang phát triển');
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header (Image 1 style)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentScreen = ComposerScreen.main;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Thêm vào bài viết của bạn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
        ),
        const Divider(color: DesignTokens.borderSubtle, height: 1),

        // Items List Grid (Image 1 style)
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
              childAspectRatio: 3.8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: item['onTap'] as VoidCallback,
                borderRadius: BorderRadius.circular(8),
                hoverColor: Colors.white.withOpacity(0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['label'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentScreen = ComposerScreen.main;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const Text(
                'Cài đặt bài viết',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        
        // Settings Content
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Xem trước bài viết
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xem trước bài viết',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _contentController.text.trim().isNotEmpty
                          ? _contentController.text.trim()
                          : 'Chưa có nội dung...',
                      style: TextStyle(
                        color: _contentController.text.trim().isNotEmpty
                            ? Colors.white
                            : Colors.white.withOpacity(0.45),
                        fontSize: 13,
                        fontStyle: _contentController.text.trim().isNotEmpty
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              
              // Settings Items List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    // 1. Đối tượng của bài viết
                    _buildSettingRow(
                      icon: Icons.public_rounded,
                      title: 'Đối tượng của bài viết',
                      subtitle: _audience,
                      onTap: _showAudiencePicker,
                    ),
                    
                    // 2. Lựa chọn lịch đăng
                    _buildSettingRow(
                      icon: Icons.access_time_rounded,
                      title: 'Lựa chọn lịch đăng',
                      subtitle: _scheduledDateTime == null
                          ? 'Đăng ngay'
                          : 'Đăng vào ${_scheduledDateTime!.day}/${_scheduledDateTime!.month}/${_scheduledDateTime!.year} lúc ${_scheduledDateTime!.hour.toString().padLeft(2, '0')}:${_scheduledDateTime!.minute.toString().padLeft(2, '0')}',
                      onTap: _showSchedulePicker,
                    ),
                    
                    // 3. Chia sẻ lên nhóm
                    _buildSettingRow(
                      icon: Icons.group_rounded,
                      title: 'Chia sẻ lên nhóm',
                      subtitle: _selectedGroups.isEmpty
                          ? 'Tiếp cận nhiều người hơn khi bạn chia sẻ bài viết trong các nhóm phù hợp.'
                          : 'Chia sẻ lên ${_selectedGroups.join(', ')}',
                      onTap: _showGroupPicker,
                    ),
                    
                    // 4. Kiếm tiền
                    _buildSettingRow(
                      icon: Icons.monetization_on_rounded,
                      title: 'Kiếm tiền',
                      subtitle: _monetizationEnabled
                          ? 'Đã bật kiếm tiền từ nội dung'
                          : 'Kiếm tiền từ nội dung của bạn',
                      onTap: _showMonetizationPicker,
                    ),
                    
                    // 5. Quảng bá bài viết
                    _buildSettingRow(
                      icon: Icons.campaign_rounded,
                      title: 'Quảng bá bài viết',
                      subtitle: 'Bạn sẽ chọn phần cài đặt sau khi nhấp vào nút Đăng. Bạn chỉ có thể quảng cáo bài viết công khai.',
                      onTap: () {
                        setState(() {
                          _boostPost = !_boostPost;
                        });
                      },
                      trailing: PremiumToggle(
                        value: _boostPost,
                        onChanged: (val) {
                          setState(() {
                            _boostPost = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
        
        // Footer actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              // Lưu Button
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      PremiumToast.show(context, 'Đã lưu bản nháp bài viết');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.08),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Lưu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Đăng Button
              Expanded(
                flex: 6,
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _isPosting ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Đăng',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: Colors.white.withOpacity(0.05),
      splashColor: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (trailing != null)
              trailing
            else
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.4),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      height: 0.5,
      color: Colors.white.withOpacity(0.06),
    );
  }

  void _showAudiencePicker() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF1C1830),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Đối tượng của bài viết',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...[
                      {'title': 'Công khai', 'subtitle': 'Bất kỳ ai trên hoặc ngoài NEXUS AI', 'icon': Icons.public_rounded},
                      {'title': 'Bạn bè', 'subtitle': 'Chỉ bạn bè của bạn trên NEXUS AI', 'icon': Icons.people_rounded},
                      {'title': 'Chỉ mình tôi', 'subtitle': 'Chỉ mình bạn xem được bài viết này', 'icon': Icons.lock_rounded},
                    ].map((item) {
                      final isSel = _audience == item['title'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _audience = item['title'] as String;
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF7C5CFF).withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(item['icon'] as IconData, color: isSel ? const Color(0xFFA78BFA) : Colors.white60, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      item['subtitle'] as String,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSel)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF7C5CFF), size: 18),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSchedulePicker() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1C1830),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Lựa chọn lịch đăng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    setState(() {
                      _scheduledDateTime = null;
                    });
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _scheduledDateTime == null ? const Color(0xFF7C5CFF).withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Color(0xFF7C5CFF), size: 20),
                        const SizedBox(width: 12),
                        const Text('Đăng ngay', style: TextStyle(color: Colors.white, fontSize: 14)),
                        const Spacer(),
                        if (_scheduledDateTime == null)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF7C5CFF), size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    final now = DateTime.now();
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _scheduledDateTime ?? now.add(const Duration(hours: 1)),
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 30)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF7C5CFF),
                              onPrimary: Colors.white,
                              surface: Color(0xFF1C1830),
                              onSurface: Colors.white,
                            ),
                            dialogBackgroundColor: const Color(0xFF1C1830),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null && mounted) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_scheduledDateTime ?? now.add(const Duration(hours: 1))),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF7C5CFF),
                                onPrimary: Colors.white,
                                surface: Color(0xFF1C1830),
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: const Color(0xFF1C1830),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _scheduledDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _scheduledDateTime != null ? const Color(0xFF7C5CFF).withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Color(0xFFA78BFA), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Lên lịch đăng', style: TextStyle(color: Colors.white, fontSize: 14)),
                              if (_scheduledDateTime != null)
                                Text(
                                  '${_scheduledDateTime!.day}/${_scheduledDateTime!.month} lúc ${_scheduledDateTime!.hour.toString().padLeft(2, '0')}:${_scheduledDateTime!.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                        if (_scheduledDateTime != null)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF7C5CFF), size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGroupPicker() {
    final availableGroups = [
      'NEXUS AI Community',
      'Học tập & Năng suất',
      'Thử thách 21 ngày',
      'Góc chia sẻ & Thảo luận'
    ];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF1C1830),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Chia sẻ lên nhóm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chọn nhóm bạn muốn tự động chia sẻ bài viết này sau khi đăng.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...availableGroups.map((group) {
                      final isChecked = _selectedGroups.contains(group);
                      return Theme(
                        data: Theme.of(context).copyWith(
                          unselectedWidgetColor: Colors.white30,
                        ),
                        child: CheckboxListTile(
                          value: isChecked,
                          title: Text(group, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          activeColor: const Color(0xFF7C5CFF),
                          checkColor: Colors.white,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                _selectedGroups.add(group);
                              } else {
                                _selectedGroups.remove(group);
                              }
                            });
                            setState(() {});
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C5CFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Xong', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMonetizationPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF1C1830),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Cài đặt kiếm tiền',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nhận tiền bản quyền nội dung hoặc phần thưởng từ độc giả cho bài viết này.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Theme(
                      data: Theme.of(context).copyWith(
                        useMaterial3: true,
                      ),
                      child: SwitchListTile(
                        value: _monetizationEnabled,
                        title: const Text('Bật kiếm tiền', style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text('Độc giả có thể gửi xu/tặng quà cho bạn', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                        activeColor: const Color(0xFF7C5CFF),
                        activeTrackColor: const Color(0xFF7C5CFF).withOpacity(0.5),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.12),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setDialogState(() {
                            _monetizationEnabled = val;
                          });
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C5CFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Xong', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageTab() {
    if (_selectedImage != null) {
      return Center(
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_selectedImage!.path),
                fit: BoxFit.fitWidth,
                width: double.infinity,
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.black87, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Chỉnh sửa',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImage = null;
                    _activeAttachment = AttachmentType.none;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.6),
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedFile != null) {
      final ext = _selectedFile!.name.split('.').last.toLowerCase();
      final icon = switch (ext) {
        'pdf' => Icons.picture_as_pdf_rounded,
        'png' || 'jpg' || 'jpeg' => Icons.image_rounded,
        'zip' || 'rar' => Icons.folder_zip_rounded,
        'doc' || 'docx' => Icons.description_rounded,
        'xls' || 'xlsx' || 'csv' => Icons.table_chart_rounded,
        _ => Icons.insert_drive_file_rounded,
      };
      
      final sizeKb = _selectedFile!.sizeBytes / 1024;
      final sizeStr = sizeKb < 1024 
          ? '${sizeKb.toStringAsFixed(1)} KB' 
          : '${(sizeKb / 1024).toStringAsFixed(1)} MB';

      return Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C5CFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF7C5CFF), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedFile!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sizeStr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedFile = null;
                    _activeAttachment = AttachmentType.none;
                  });
                },
                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white30),
                hoverColor: Colors.white12,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTaskTab(AsyncValue<List<NexusTask>> tasksAsync) {
    return tasksAsync.when(
      data: (tasks) {
        final incompleteTasks = tasks.where((t) => t.status != 'completed' && t.status != 'done').toList();
        if (incompleteTasks.isEmpty) {
          return const Center(child: Text('Không có công việc nào để chia sẻ', style: TextStyle(color: Colors.white60)));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Đính kèm công việc:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<NexusTask>(
              value: _selectedTask,
              dropdownColor: DesignTokens.bgCard,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              hint: const Text('Chọn một công việc', style: TextStyle(color: Colors.white38)),
              items: incompleteTasks.map((t) {
                return DropdownMenuItem<NexusTask>(
                  value: t,
                  child: Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedTask = val;
                });
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (_, __) => const Center(child: Text('Lỗi tải công việc', style: TextStyle(color: Colors.red))),
    );
  }

  Widget _buildAchievementTab(AsyncValue<UserProfileModel?> profileAsync) {
    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        final list = ['Rank: ${profile.rankTitle}', 'Level ${profile.level} reached!', 'Focus Score: ${profile.focusScore}%'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Khoe thành tích:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAchievement,
              dropdownColor: DesignTokens.bgCard,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              hint: const Text('Chọn thành tích để chia sẻ', style: TextStyle(color: Colors.white38)),
              items: list.map((a) {
                return DropdownMenuItem<String>(
                  value: a,
                  child: Text(a, style: const TextStyle(color: Colors.white, fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedAchievement = val;
                });
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (_, __) => const Center(child: Text('Lỗi tải thành tích', style: TextStyle(color: Colors.red))),
    );
  }

  Widget _buildPollTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tùy chọn bình chọn:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            if (_pollOptionControllers.length < 4)
              TextButton.icon(
                icon: const Icon(Icons.add, size: 14, color: Color(0xFFA78BFA)),
                label: const Text('Thêm tùy chọn', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12)),
                onPressed: _addPollOption,
              ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pollOptionControllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pollOptionControllers[index],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Lựa chọn ${index + 1}',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.04),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  if (_pollOptionControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _removePollOption(index),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(4, size.height - 4),
      Offset(size.width - 4, 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PremiumToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PremiumToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value ? const Color(0xFF1877F2) : Colors.white.withOpacity(0.12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

