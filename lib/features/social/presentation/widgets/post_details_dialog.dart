import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/social/data/models/activity_post_model.dart';
import 'package:to_do_app/features/social/presentation/widgets/activity_post_card.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/feed_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/features/social/presentation/widgets/premium_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:typed_data';

class PostDetailsDialog extends ConsumerStatefulWidget {
  const PostDetailsDialog({super.key, required this.post});

  final ActivityPostModel post;

  static void show(BuildContext context, ActivityPostModel post) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PostDetailsDialog',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return PostDetailsDialog(post: post);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: curve,
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<PostDetailsDialog> createState() => _PostDetailsDialogState();
}

class _PostDetailsDialogState extends ConsumerState<PostDetailsDialog> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  String? _activePickerTab;
  Map<String, dynamic>? _selectedAttachment;
  bool _uploadingAttachment = false;

  final LayerLink _emojiLink = LayerLink();
  final LayerLink _gifLink = LayerLink();
  final LayerLink _stickerLink = LayerLink();

  @override
  void dispose() {
    CommentMediaPickerOverlay.close();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment(String currentUserId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _selectedAttachment == null) return;

    try {
      final feedService = ref.read(feedServiceProvider);
      
      String finalContent = text;
      if (_selectedAttachment != null) {
        finalContent = jsonEncode({
          'text': text,
          'attachment': {
            'url': _selectedAttachment!['url'],
            'type': _selectedAttachment!['type'],
            'name': _selectedAttachment!['name'],
          }
        });
      }

      final replyingId = _replyingToCommentId;
      _commentController.clear();
      setState(() {
        _selectedAttachment = null;
        _replyingToCommentId = null;
        _replyingToAuthorName = null;
      });

      if (replyingId != null) {
        await feedService.addReply(widget.post.id, currentUserId, replyingId, finalContent);
      } else {
        await feedService.addComment(widget.post.id, currentUserId, finalContent);
      }
      ref.invalidate(feedPostsProvider);
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Lỗi gửi bình luận: $e', isError: true);
      }
    }
  }

  Future<String?> _uploadFileToSupabase(List<int> bytes, String fileName, String mimeType) async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return null;

    try {
      final supabase = Supabase.instance.client;
      final path = 'social-comments/${currentUser.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await supabase.storage.from('comment-attachments').uploadBinary(
        path,
        Uint8List.fromList(bytes),
        fileOptions: FileOptions(contentType: mimeType, upsert: true),
      );
      
      return supabase.storage.from('comment-attachments').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading social comment file to Supabase: $e');
      if (mounted) {
        PremiumToast.show(context, 'Lỗi tải tệp lên: $e', isError: true);
      }
      return null;
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.any, withData: true);
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() {
        _uploadingAttachment = true;
      });

      final ext = file.name.split('.').last.toLowerCase();
      String mimeType = 'application/octet-stream';
      if (ext == 'pdf') {
        mimeType = 'application/pdf';
      } else if (ext == 'txt') {
        mimeType = 'text/plain';
      } else if (ext == 'png' || ext == 'jpg' || ext == 'jpeg') {
        mimeType = 'image/$ext';
      }

      final publicUrl = await _uploadFileToSupabase(bytes, file.name, mimeType);

      if (publicUrl != null) {
        setState(() {
          _selectedAttachment = {
            'url': publicUrl,
            'type': (ext == 'png' || ext == 'jpg' || ext == 'jpeg') ? 'image' : 'file',
            'name': file.name,
          };
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    } finally {
      if (mounted) {
        setState(() {
          _uploadingAttachment = false;
        });
      }
    }
  }

  void _toggleMediaPicker(String tab) {
    if (_activePickerTab == tab) {
      CommentMediaPickerOverlay.close();
      setState(() {
        _activePickerTab = null;
      });
    } else {
      setState(() {
        _activePickerTab = tab;
      });
      CommentMediaPickerOverlay.show(
        context: context,
        triggerContext: context,
        emojiLink: _emojiLink,
        gifLink: _gifLink,
        stickerLink: _stickerLink,
        initialTab: tab,
        onTabChanged: (newTab) {
          setState(() {
            _activePickerTab = newTab;
          });
        },
        onEmojiSelected: (emoji) {
          _commentController.text += emoji;
          setState(() {});
        },
        onGifSelected: (gifUrl, gifName) {
          setState(() {
            _selectedAttachment = {
              'url': gifUrl,
              'type': 'gif',
              'name': gifName,
            };
          });
        },
        onStickerSelected: (stickerUrl, stickerName) {
          setState(() {
            _selectedAttachment = {
              'url': stickerUrl,
              'type': 'sticker',
              'name': stickerName,
            };
          });
        },
        onClose: () {
          if (mounted) {
            setState(() {
              _activePickerTab = null;
            });
          }
        },
        preferLeft: true,
      );
    }
  }

  Widget _buildAttachmentPreviewPreviewWidget(Map<String, dynamic> attachment) {
    final type = attachment['type'] as String? ?? 'file';
    final url = attachment['url'] as String? ?? '';
    final name = attachment['name'] as String? ?? '';

    if (type == 'image' || type == 'gif' || type == 'sticker') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          height: 80,
          width: 80,
          fit: type == 'sticker' ? BoxFit.contain : BoxFit.cover,
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        constraints: const BoxConstraints(maxWidth: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_outlined, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCommentActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isActive = false,
  }) {
    final Color iconColor = isActive 
        ? const Color(0xFFA78BFA) 
        : Colors.white54;
    final Color bgColor = isActive
        ? const Color(0x267C5CFF)
        : Colors.transparent;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(6.0),
          child: Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= DashboardBreakpoints.desktop;
    final dialogWidth = isDesktop ? 680.0 : screenWidth * 0.92;

    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final currentUserProfile = ref.watch(userProfileProvider).valueOrNull;
    final avatarUrl = currentUserProfile?.avatarUrl ?? currentUser?.avatarUrl;
    final fullName = currentUserProfile?.fullName ?? currentUser?.fullName;
    final username = currentUserProfile?.username ?? currentUser?.username;
    final displayName = fullName != null && fullName.isNotEmpty
        ? fullName
        : (username != null && username.isNotEmpty ? '@$username' : 'Người dùng');

    return Center(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuad,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF151827),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bài viết của ${widget.post.authorName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                
                // Body (Scrollable post card without outer container and comment input box)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: ActivityPostCard(
                      post: widget.post,
                      showCommentsByDefault: true,
                      hideCommentInput: true,
                      hideContainer: true,
                      onReplyPressed: (commentId, authorName) {
                        setState(() {
                          _replyingToCommentId = commentId;
                          _replyingToAuthorName = authorName;
                        });
                        _commentFocusNode.requestFocus();
                      },
                    ),
                  ),
                ),
                
                const Divider(color: Colors.white10, height: 1),
                
                // Pinned Footer (Screenshot-styled comment input box)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        backgroundColor: Colors.grey.shade900,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? const Icon(Icons.person, size: 18, color: Colors.white54)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      
                      // Input capsule
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_replyingToCommentId != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6, left: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      'Đang trả lời $_replyingToAuthorName',
                                      style: const TextStyle(
                                        color: Color(0xFFA78BFA),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _replyingToCommentId = null;
                                          _replyingToAuthorName = null;
                                        });
                                      },
                                      child: const Icon(Icons.close_rounded, color: Colors.white54, size: 14),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2130), // Dark grey capsule
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.04)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Comment field text input
                                  TextField(
                                    controller: _commentController,
                                    focusNode: _commentFocusNode,
                                    maxLines: null,
                                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                    decoration: InputDecoration(
                                      hintText: _replyingToCommentId != null
                                          ? 'Trả lời dưới tên $displayName...'
                                          : 'Bình luận dưới tên $displayName...',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  
                                  // Upload progress/status
                                  if (_uploadingAttachment) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFA78BFA)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Đang tải tệp lên...',
                                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                  
                                  // Selected attachment preview
                                  if (_selectedAttachment != null && !_uploadingAttachment) ...[
                                    const SizedBox(height: 10),
                                    Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        _buildAttachmentPreviewPreviewWidget(_selectedAttachment!),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedAttachment = null;
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            margin: const EdgeInsets.only(top: 4, right: 4),
                                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 10),
                                  
                                  // Actions row
                                  Row(
                                    children: [
                                      // Identity Switch
                                      _buildCommentActionIcon(
                                        icon: Icons.switch_account_outlined,
                                        onTap: () {
                                          PremiumToast.show(context, 'Chức năng đổi danh tính đang được phát triển');
                                        },
                                        tooltip: 'Đổi danh tính',
                                      ),
                                      const SizedBox(width: 4),
                                      
                                      // Smiley Emoji
                                      TapRegion(
                                        groupId: 'comment_media_picker',
                                        child: CompositedTransformTarget(
                                          link: _emojiLink,
                                          child: _buildCommentActionIcon(
                                            icon: Icons.sentiment_satisfied_alt_rounded,
                                            onTap: () => _toggleMediaPicker('emoji'),
                                            tooltip: 'Biểu tượng cảm xúc',
                                            isActive: _activePickerTab == 'emoji',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      
                                      // Camera / Attachment
                                      _buildCommentActionIcon(
                                        icon: Icons.camera_alt_outlined,
                                        onTap: _pickFile,
                                        tooltip: 'Ảnh / Tài liệu',
                                      ),
                                      const SizedBox(width: 4),
                                      
                                      // GIF
                                      TapRegion(
                                        groupId: 'comment_media_picker',
                                        child: CompositedTransformTarget(
                                          link: _gifLink,
                                          child: _buildCommentActionIcon(
                                            icon: Icons.gif_box_outlined,
                                            onTap: () => _toggleMediaPicker('gif'),
                                            tooltip: 'Ảnh động GIF',
                                            isActive: _activePickerTab == 'gif',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      
                                      // Sticker
                                      TapRegion(
                                        groupId: 'comment_media_picker',
                                        child: CompositedTransformTarget(
                                          link: _stickerLink,
                                          child: _buildCommentActionIcon(
                                            icon: Icons.sticky_note_2_outlined,
                                            onTap: () => _toggleMediaPicker('sticker'),
                                            tooltip: 'Nhãn dán',
                                            isActive: _activePickerTab == 'sticker',
                                          ),
                                        ),
                                      ),
                                      
                                      const Spacer(),
                                      
                                      // Send Button
                                      GestureDetector(
                                        onTap: currentUser != null
                                            ? () => _submitComment(currentUser.id)
                                            : null,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: (_commentController.text.trim().isNotEmpty || _selectedAttachment != null)
                                                ? const Color(0xFFA78BFA)
                                                : Colors.white.withOpacity(0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.send_rounded,
                                            color: (_commentController.text.trim().isNotEmpty || _selectedAttachment != null)
                                                ? Colors.black
                                                : Colors.white30,
                                            size: 14,
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
                    ],
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
