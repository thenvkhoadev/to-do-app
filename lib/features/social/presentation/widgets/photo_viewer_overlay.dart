import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/social/data/models/activity_post_model.dart';
import 'package:to_do_app/features/social/presentation/providers/feed_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/theme/design_tokens.dart';
import 'package:to_do_app/features/social/presentation/widgets/premium_toast.dart';
import 'package:to_do_app/features/social/presentation/widgets/activity_post_card.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/social/presentation/widgets/post_details_dialog.dart';


class PhotoViewerOverlay extends ConsumerStatefulWidget {
  const PhotoViewerOverlay({
    super.key,
    required this.postId,
    required this.initialIndex,
  });

  final String postId;
  final int initialIndex;

  @override
  ConsumerState<PhotoViewerOverlay> createState() => _PhotoViewerOverlayState();
}

class _PhotoViewerOverlayState extends ConsumerState<PhotoViewerOverlay>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late TransformationController _transformationController;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  double _opacity = 0.0;
  bool _isZoomed = false;
  bool _isFullscreen = false;
  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  int? _hoveredThumbnailIndex;

  // Hover states for buttons
  bool _isPrevHovered = false;
  bool _isNextHovered = false;
  bool _isCloseHovered = false;
  final Map<int, bool> _toolbarHoverStates = {};

  String? _activePickerTab;
  Map<String, dynamic>? _selectedAttachment;
  bool _uploadingAttachment = false;
  final LayerLink _emojiLink = LayerLink();
  final LayerLink _gifLink = LayerLink();
  final LayerLink _stickerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
    _transformationController.addListener(_zoomListener);

    // Fade-in animation on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
      });
      _focusNode.requestFocus();
    });
  }

  void _zoomListener() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.0;
    if (zoomed != _isZoomed) {
      setState(() {
        _isZoomed = zoomed;
      });
    }
  }

  @override
  void dispose() {
    CommentMediaPickerOverlay.close();
    _pageController.dispose();
    _transformationController.removeListener(_zoomListener);
    _transformationController.dispose();
    _focusNode.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale + 0.35).clamp(1.0, 5.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
    setState(() {});
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale - 0.35).clamp(1.0, 5.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
    setState(() {});
  }

  void _navigatePage(int offset, int totalCount) {
    final nextIndex = _currentIndex + offset;
    if (nextIndex >= 0 && nextIndex < totalCount) {
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _closeOverlay() {
    CommentMediaPickerOverlay.close();
    setState(() {
      _opacity = 0.0;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        ref.read(photoViewerStateProvider.notifier).state = null;
      }
    });
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays >= 1) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  List<ActivityCommentModel> _getSortedComments(ActivityPostModel post, String sortOption) {
    final List<ActivityCommentModel> parentComments = post.comments
        .where((c) => c.parentCommentId == null)
        .toList();

    parentComments.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      switch (sortOption) {
        case 'popular':
          final aCount = a.reactions.length;
          final bCount = b.reactions.length;
          if (aCount != bCount) return bCount.compareTo(aCount);
          return b.createdAt.compareTo(a.createdAt);
        case 'interactions':
          final aInt = a.reactions.length + a.replies.length;
          final bInt = b.reactions.length + b.replies.length;
          if (aInt != bInt) return bInt.compareTo(aInt);
          return b.createdAt.compareTo(a.createdAt);
        case 'has_replies':
          final aHas = a.replies.isNotEmpty ? 1 : 0;
          final bHas = b.replies.isNotEmpty ? 1 : 0;
          if (aHas != bHas) return bHas.compareTo(aHas);
          return b.createdAt.compareTo(a.createdAt);
        case 'newest':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return parentComments;
  }

  Future<void> _submitComment(ActivityPostModel post, String currentUserId) async {
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
        await feedService.addReply(post.id, currentUserId, replyingId, finalContent);
      } else {
        await feedService.addComment(post.id, currentUserId, finalContent);
      }
      ref.invalidate(feedPostsProvider);
    } catch (e) {
      if (context.mounted) {
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
      if (context.mounted) {
        PremiumToast.show(context, 'Lỗi tải tệp lên: $e', isError: true);
      }
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return;

      setState(() {
        _uploadingAttachment = true;
      });

      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final mimeType = 'image/$ext';

      final publicUrl = await _uploadFileToSupabase(bytes, image.name, mimeType);

      if (publicUrl != null) {
        setState(() {
          _selectedAttachment = {
            'url': publicUrl,
            'type': 'image',
            'name': image.name,
          };
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _uploadingAttachment = false;
        });
      }
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

  void _showFileSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Thêm Đính Kèm',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              ListTile(
                leading: const Icon(Icons.image_rounded, color: Color(0xFFA78BFA)),
                title: const Text('Chọn ảnh từ thư viện', style: TextStyle(color: Colors.white, fontSize: 14.5)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.blueAccent),
                title: const Text('Chọn tài liệu / tệp tin', style: TextStyle(color: Colors.white, fontSize: 14.5)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        constraints: const BoxConstraints(maxWidth: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_rounded, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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

    return InkWell(
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
    );
  }

  Future<void> _handlePostAction(ActivityPostModel post, String action) async {
    final client = ref.read(supabaseClientProvider);
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF151827),
          title: const Text('Xóa bài viết', style: TextStyle(color: Colors.white)),
          content: const Text('Bạn có chắc chắn muốn xóa bài viết này?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        try {
          await client.from('activity_feed').delete().eq('id', post.id);
          _closeOverlay();
          if (context.mounted) {
            PremiumToast.show(context, 'Đã xóa bài viết');
          }
        } catch (e) {
          if (context.mounted) {
            PremiumToast.show(context, 'Lỗi xóa bài viết: $e', isError: true);
          }
        }
      }
    } else if (action == 'toggle_comment') {
      try {
        final newCommentsDisabled = !post.commentsDisabled;
        final currentMeta = Map<String, dynamic>.from(post.metaData ?? {});
        currentMeta['comments_disabled'] = newCommentsDisabled;
        await client.from('activity_feed').update({'meta_data': currentMeta}).eq('id', post.id);
        ref.invalidate(feedPostsProvider);
        if (context.mounted) {
          PremiumToast.show(context, newCommentsDisabled ? 'Đã tắt bình luận bài viết' : 'Đã bật bình luận bài viết');
        }
      } catch (e) {
        if (context.mounted) {
          PremiumToast.show(context, 'Lỗi thay đổi trạng thái bình luận: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(feedPostsProvider);
    final post = postsAsync.whenOrNull(
      data: (posts) => posts.firstWhere(
        (p) => p.id == widget.postId,
        orElse: () => null as dynamic,
      ),
    );

    // Auto-close if post is deleted or invalid
    if (post == null) {
      return const SizedBox.shrink();
    }

    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final currentUserId = currentUser?.id ?? '';
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    // Parse image list
    final List<String> mediaUrls = [];
    final metaUrls = post.metaData?['media_urls'] as List<dynamic>?;
    if (metaUrls != null && metaUrls.isNotEmpty) {
      mediaUrls.addAll(metaUrls.cast<String>());
    } else if (post.mediaUrl != null) {
      mediaUrls.add(post.mediaUrl!);
    }

    if (mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // Keyboard listener focus wrapper
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              _closeOverlay();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _navigatePage(-1, mediaUrls.length);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _navigatePage(1, mediaUrls.length);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          color: const Color(0xFF0D0B1A),
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(child: _buildImageViewer(mediaUrls)),
                    _buildRightPanel(post, currentUserId, isDesktop),
                  ],
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 120),
                        child: _buildImageViewer(mediaUrls),
                      ),
                    ),
                    _buildMobileCommentsSheet(post, currentUserId),
                  ],
                ),
        ),
      ),
    );
  }

  // IMAGE VIEWER (LEFT SIDE)
  Widget _buildImageViewer(List<String> urls) {
    final showPrev = _currentIndex > 0;
    final showNext = _currentIndex < urls.length - 1;

    return Stack(
      children: [
        // Dark background clickable container to close on click outside photo
        Positioned.fill(
          child: GestureDetector(
            onTap: _closeOverlay,
            child: Container(color: Colors.black),
          ),
        ),

        // Interactive Page View
        Positioned.fill(
          child: PageView.builder(
            controller: _pageController,
            itemCount: urls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _transformationController.value = Matrix4.identity();
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: MouseRegion(
                    cursor: _isZoomed ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
                    child: CachedNetworkImage(
                      imageUrl: urls[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.white24, size: 64),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // CLOSE BUTTON [X]
        Positioned(
          top: 16,
          left: 16,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isCloseHovered = true),
            onExit: (_) => setState(() => _isCloseHovered = false),
            child: GestureDetector(
              onTap: _closeOverlay,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _isCloseHovered
                      ? const Color(0xFF7C5CFF).withOpacity(0.25)
                      : Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),

        // ZOOM / FULLSCREEN TOOLBAR
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolbarButton(0, Icons.zoom_in_rounded, _zoomIn, 'Phóng to'),
                const SizedBox(width: 8),
                _buildToolbarButton(1, Icons.zoom_out_rounded, _zoomOut, 'Thu nhỏ'),
                const SizedBox(width: 8),
                _buildToolbarButton(2, Icons.local_offer_outlined, () {
                  PremiumToast.show(context, 'Tính năng tag đang được phát triển');
                }, 'Tag ảnh'),
                const SizedBox(width: 8),
                _buildToolbarButton(3, _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, () {
                  setState(() {
                    _isFullscreen = !_isFullscreen;
                  });
                }, _isFullscreen ? 'Thoát toàn màn hình' : 'Toàn màn hình'),
              ],
            ),
          ),
        ),

        // PREVIOUS BUTTON
        Positioned(
          left: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isPrevHovered = true),
              onExit: (_) => setState(() => _isPrevHovered = false),
              child: GestureDetector(
                onTap: showPrev ? () => _navigatePage(-1, urls.length) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: !showPrev
                        ? Colors.black.withOpacity(0.15)
                        : _isPrevHovered
                            ? const Color(0xFF7C5CFF).withOpacity(0.3)
                            : Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                          color: Colors.white.withOpacity(showPrev ? 1.0 : 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // NEXT BUTTON
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isNextHovered = true),
              onExit: (_) => setState(() => _isNextHovered = false),
              child: GestureDetector(
                onTap: showNext ? () => _navigatePage(1, urls.length) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: !showNext
                        ? Colors.black.withOpacity(0.15)
                        : _isNextHovered
                            ? const Color(0xFF7C5CFF).withOpacity(0.3)
                            : Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: Colors.white.withOpacity(showNext ? 1.0 : 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // THUMBNAIL STRIP (At Bottom)
        if (urls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(urls.length, (index) {
                      final isActive = index == _currentIndex;
                      final isHovered = _hoveredThumbnailIndex == index;

                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoveredThumbnailIndex = index),
                        onExit: (_) => setState(() => _hoveredThumbnailIndex = null),
                        child: GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFF7C5CFF)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Opacity(
                              opacity: isActive
                                  ? 1.0
                                  : isHovered
                                      ? 1.0
                                      : 0.55,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: urls[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.white10),
                                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // TOOLBAR BUTTON BUILDER
  Widget _buildToolbarButton(int id, IconData icon, VoidCallback onTap, String tooltip) {
    final isHovered = _toolbarHoverStates[id] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _toolbarHoverStates[id] = true),
      onExit: (_) => setState(() => _toolbarHoverStates[id] = false),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isHovered
                  ? const Color(0xFF7C5CFF).withOpacity(0.25)
                  : Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Center(
                  child: Icon(icon, size: 18, color: Colors.white.withOpacity(0.8)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // COMMENTS & INFO PANEL (RIGHT COLUMN - DESKTOP)
  Widget _buildRightPanel(ActivityPostModel post, String currentUserId, bool isDesktop) {
    final width = _isFullscreen ? 0.0 : 340.0;

    final List<String> mediaUrls = [];
    final metaUrls = post.metaData?['media_urls'] as List<dynamic>?;
    if (metaUrls != null && metaUrls.isNotEmpty) {
      mediaUrls.addAll(metaUrls.cast<String>());
    } else if (post.mediaUrl != null) {
      mediaUrls.add(post.mediaUrl!);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      height: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF12101F),
        border: Border(
          left: BorderSide(color: Colors.white.withOpacity(0.07), width: 0.5),
        ),
      ),
      child: _isFullscreen
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Scrollable Panel Content
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // Banner "Xem bài viết"
                      if (mediaUrls.length > 1)
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C5CFF).withOpacity(0.08),
                              border: Border(
                                bottom: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.description_outlined, color: Colors.white54, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text(
                                        'Ảnh này nằm trong một bài viết. ',
                                        style: TextStyle(fontSize: 13, color: Colors.white54),
                                      ),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            _closeOverlay();
                                            PostDetailsDialog.show(context, post);
                                          },
                                          child: const Text(
                                            'Xem bài viết →',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFFA78BFA),
                                              fontWeight: FontWeight.w500,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Author details row
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: post.authorAvatarUrl.isNotEmpty
                                    ? NetworkImage(post.authorAvatarUrl)
                                    : null,
                                backgroundColor: Colors.grey.shade900,
                                child: post.authorAvatarUrl.isEmpty
                                    ? const Icon(Icons.person, color: Colors.white54)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.authorName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          _timeAgo(post.createdAt),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.4),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('·', style: TextStyle(color: Colors.white.withOpacity(0.4))),
                                        const SizedBox(width: 4),
                                        Icon(Icons.lock_rounded, size: 12, color: Colors.white.withOpacity(0.35)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Three dot menu button
                              _buildPostMenuButton(post),
                            ],
                          ),
                        ),
                      ),

                      // Edit button (shown if post belongs to user)
                      if (post.userId == currentUserId)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  PremiumToast.show(context, 'Chức năng chỉnh sửa bài viết đang được phát triển');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Chỉnh sửa',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Reaction bar
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.5),
                              bottom: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildReactionAction(
                                  icon: Icons.thumb_up_alt_outlined,
                                  label: 'Thích',
                                  isActive: post.likedByUserIds.contains(currentUserId),
                                  activeColor: const Color(0xFF7C5CFF),
                                  onTap: () async {
                                    try {
                                      await ref.read(feedServiceProvider).toggleLike(post.id, currentUserId);
                                      ref.invalidate(feedPostsProvider);
                                    } catch (e) {
                                      if (mounted) {
                                        PremiumToast.show(context, 'Lỗi thích bài viết: $e', isError: true);
                                      }
                                    }
                                  },
                                ),
                              ),
                              Expanded(
                                child: _buildReactionAction(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  label: 'Bình luận',
                                  isActive: false,
                                  onTap: () {
                                    _commentFocusNode.requestFocus();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Comment sort options (only if comments exist)
                      if (post.comments.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Bình luận',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _buildCommentSortMenu(post),
                              ],
                            ),
                          ),
                        ),

                      // Empty state or Comment list
                      if (post.comments.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final sortOption = ref.watch(commentSortOptionProvider(post.id));
                                final sortedComments = _getSortedComments(post, sortOption);
                                final comment = sortedComments[index];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: CommentCard(
                                    key: ValueKey(comment.id),
                                    comment: comment,
                                    currentUserId: currentUserId,
                                    postOwnerId: post.userId,
                                    isCommentsDisabled: post.commentsDisabled,
                                    onReplyPressed: (authorName, authorId) {
                                      setState(() {
                                        _replyingToCommentId = comment.id;
                                        _replyingToAuthorName = authorName;
                                        if (currentUserId != authorId) {
                                          final mention = '@$authorName ';
                                          if (!_commentController.text.startsWith(mention)) {
                                            _commentController.text = '$mention${_commentController.text}';
                                          }
                                        }
                                        _commentFocusNode.requestFocus();
                                      });
                                    },
                                    onEditComment: (commentId, content) async {
                                      await ref.read(feedServiceProvider).editComment(commentId, content);
                                      ref.invalidate(feedPostsProvider);
                                    },
                                    onDeleteComment: (commentId) async {
                                      await ref.read(feedServiceProvider).deleteComment(commentId);
                                      ref.invalidate(feedPostsProvider);
                                    },
                                    onPinComment: (commentId, pin) async {
                                      await ref.read(feedServiceProvider).togglePinComment(commentId, pin);
                                      ref.invalidate(feedPostsProvider);
                                    },
                                    onHideComment: (commentId) {
                                      ref.read(hiddenCommentIdsProvider.notifier).update((state) => {...state, commentId});
                                    },
                                    onBlockUser: (userId) {
                                      ref.read(blockedUserIdsProvider.notifier).blockUser(userId);
                                    },
                                    onReactionSelected: (commentId, type) async {
                                      await ref.read(feedServiceProvider).toggleCommentReaction(commentId, currentUserId, type);
                                      ref.invalidate(feedPostsProvider);
                                    },
                                  ),
                                );
                              },
                              childCount: _getSortedComments(post, ref.watch(commentSortOptionProvider(post.id))).length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Replying Indicator
                if (_replyingToCommentId != null)
                  Container(
                    color: const Color(0xFF151224),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'Đang trả lời $_replyingToAuthorName',
                          style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyingToCommentId = null;
                              _replyingToAuthorName = null;
                            });
                          },
                          child: const Icon(Icons.close_rounded, color: Color(0xFFA78BFA), size: 14),
                        ),
                      ],
                    ),
                  ),

                // Stick comment input
                _buildCommentInputSection(post, currentUserId),
              ],
            ),
    );
  }

  // EMPTY STATE WIDGET
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có bình luận nào',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hãy là người đầu tiên bình luận.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // REACTION ACTION BUILDER
  Widget _buildReactionAction({
    required IconData icon,
    required String label,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? activeColor : Colors.white.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // COMMENT SORT MENU
  Widget _buildCommentSortMenu(ActivityPostModel post) {
    final sortOption = ref.watch(commentSortOptionProvider(post.id));
    final sortLabels = {
      'newest': 'Mới nhất',
      'popular': 'Phổ biến',
      'interactions': 'Tương tác',
      'has_replies': 'Có trả lời',
    };
    final currentLabel = sortLabels[sortOption] ?? 'Mới nhất';

    return PopupMenuButton<String>(
      tooltip: 'Sắp xếp bình luận',
      onSelected: (value) {
        ref.read(commentSortOptionProvider(post.id).notifier).state = value;
      },
      color: const Color(0xFF151827),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentLabel,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 16),
        ],
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'newest', child: Text('Mới nhất', style: TextStyle(color: Colors.white70))),
        const PopupMenuItem(value: 'popular', child: Text('Phổ biến', style: TextStyle(color: Colors.white70))),
        const PopupMenuItem(value: 'interactions', child: Text('Tương tác', style: TextStyle(color: Colors.white70))),
        const PopupMenuItem(value: 'has_replies', child: Text('Có trả lời', style: TextStyle(color: Colors.white70))),
      ],
    );
  }

  // COMMENT INPUT CONTAINER
  Widget _buildCommentInputSection(ActivityPostModel post, String currentUserId) {
    final currentUserProfile = ref.watch(userProfileProvider).valueOrNull;
    final avatarUrl = currentUserProfile?.avatarUrl ?? '';
    final fullName = currentUserProfile?.fullName ?? '';
    final username = currentUserProfile?.username ?? 'user';
    final displayName = fullName.isNotEmpty
        ? (username.isNotEmpty ? '$fullName (@$username)' : fullName)
        : (username.isNotEmpty ? '@$username' : 'bạn');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF12101F),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.07), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            backgroundColor: Colors.grey.shade900,
            child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 16, color: Colors.white54) : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1F2B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    maxLines: null,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: _replyingToCommentId != null
                          ? 'Trả lời dưới tên $displayName...'
                          : 'Bình luận dưới tên $displayName...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submitComment(post, currentUserId),
                  ),
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
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
                      _buildCommentActionIcon(
                        icon: Icons.camera_alt_outlined,
                        onTap: _showFileSelector,
                        tooltip: 'Ảnh / Tài liệu',
                      ),
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
                      GestureDetector(
                        onTap: () => _submitComment(post, currentUserId),
                        child: Container(
                          decoration: BoxDecoration(
                            color: (_commentController.text.trim().isNotEmpty || _selectedAttachment != null)
                                ? const Color(0xFFA78BFA)
                                : Colors.white.withValues(alpha: 0.08),
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
          ),
        ],
      ),
    );
  }

  // THREE DOT BUTTON MENU FOR POSTS
  Widget _buildPostMenuButton(ActivityPostModel post) {
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final isOwner = post.userId == currentUser?.id;

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: Colors.white.withOpacity(0.6), size: 18),
      tooltip: 'Tùy chọn bài viết',
      onSelected: (value) => _handlePostAction(post, value),
      color: const Color(0xFF151827),
      itemBuilder: (context) => [
        if (isOwner) ...[
          const PopupMenuItem(
            value: 'delete',
            child: Text('Xóa bài viết', style: TextStyle(color: Colors.redAccent)),
          ),
          PopupMenuItem(
            value: 'toggle_comment',
            child: Text(
              post.commentsDisabled ? 'Bật bình luận' : 'Tắt bình luận',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ],
    );
  }

  // DRAGGABLE COMMENTS SHEET FOR MOBILE
  Widget _buildMobileCommentsSheet(ActivityPostModel post, String currentUserId) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF12101F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Pull Bar Indicator
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Sticky Banner at top of sheet
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF7C5CFF).withOpacity(0.08),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, color: Colors.white54, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ảnh trong bài viết của ${post.authorName}',
                        style: const TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ),
                    GestureDetector(
                      onTap: _closeOverlay,
                      child: const Text(
                        'Đóng',
                        style: TextStyle(fontSize: 12, color: Color(0xFFA78BFA), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Main list of comments
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Author details row inside sheet
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: post.authorAvatarUrl.isNotEmpty
                                ? NetworkImage(post.authorAvatarUrl)
                                : null,
                            backgroundColor: Colors.grey.shade900,
                            child: post.authorAvatarUrl.isEmpty
                                ? const Icon(Icons.person, size: 16, color: Colors.white54)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 1),
                                Row(
                                  children: [
                                    Text(
                                      _timeAgo(post.createdAt),
                                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.lock_rounded, size: 10, color: Colors.white.withOpacity(0.35)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildPostMenuButton(post),
                        ],
                      ),
                    ),

                    // Reaction row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildReactionAction(
                              icon: Icons.thumb_up_alt_outlined,
                              label: 'Thích',
                              isActive: post.likedByUserIds.contains(currentUserId),
                              activeColor: const Color(0xFF7C5CFF),
                              onTap: () async {
                                try {
                                  await ref.read(feedServiceProvider).toggleLike(post.id, currentUserId);
                                  ref.invalidate(feedPostsProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    PremiumToast.show(context, 'Lỗi thích bài viết: $e', isError: true);
                                  }
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildReactionAction(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'Bình luận',
                              isActive: false,
                              onTap: () {
                                _commentFocusNode.requestFocus();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Colors.white10),

                    // Comment sorting
                    if (post.comments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Bình luận',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            _buildCommentSortMenu(post),
                          ],
                        ),
                      ),

                    // Comments List
                    if (post.comments.isEmpty)
                      _buildEmptyState()
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _getSortedComments(post, ref.watch(commentSortOptionProvider(post.id))).length,
                          itemBuilder: (context, index) {
                            final sortOption = ref.watch(commentSortOptionProvider(post.id));
                            final sortedComments = _getSortedComments(post, sortOption);
                            final comment = sortedComments[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: CommentCard(
                                key: ValueKey(comment.id),
                                comment: comment,
                                currentUserId: currentUserId,
                                postOwnerId: post.userId,
                                isCommentsDisabled: post.commentsDisabled,
                                onReplyPressed: (authorName, authorId) {
                                  setState(() {
                                    _replyingToCommentId = comment.id;
                                    _replyingToAuthorName = authorName;
                                    if (currentUserId != authorId) {
                                      final mention = '@$authorName ';
                                      if (!_commentController.text.startsWith(mention)) {
                                        _commentController.text = '$mention${_commentController.text}';
                                      }
                                    }
                                    _commentFocusNode.requestFocus();
                                  });
                                },
                                onEditComment: (commentId, content) async {
                                  await ref.read(feedServiceProvider).editComment(commentId, content);
                                  ref.invalidate(feedPostsProvider);
                                },
                                onDeleteComment: (commentId) async {
                                  await ref.read(feedServiceProvider).deleteComment(commentId);
                                  ref.invalidate(feedPostsProvider);
                                },
                                onPinComment: (commentId, pin) async {
                                  await ref.read(feedServiceProvider).togglePinComment(commentId, pin);
                                  ref.invalidate(feedPostsProvider);
                                },
                                onHideComment: (commentId) {
                                  ref.read(hiddenCommentIdsProvider.notifier).update((state) => {...state, commentId});
                                },
                                onBlockUser: (userId) {
                                  ref.read(blockedUserIdsProvider.notifier).blockUser(userId);
                                },
                                onReactionSelected: (commentId, type) async {
                                  await ref.read(feedServiceProvider).toggleCommentReaction(commentId, currentUserId, type);
                                  ref.invalidate(feedPostsProvider);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // Replying indicator
              if (_replyingToCommentId != null)
                Container(
                  color: const Color(0xFF151224),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Đang trả lời $_replyingToAuthorName',
                        style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _replyingToCommentId = null;
                            _replyingToAuthorName = null;
                          });
                        },
                        child: const Icon(Icons.close_rounded, color: Color(0xFFA78BFA), size: 14),
                      ),
                    ],
                  ),
                ),

              // Comment Input
              _buildCommentInputSection(post, currentUserId),
            ],
          ),
        );
      },
    );
  }
}
