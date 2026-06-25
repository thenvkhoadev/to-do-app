import 'package:to_do_app/features/social/presentation/widgets/premium_toast.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/social/presentation/widgets/post_menu_overlay.dart';
import 'package:to_do_app/features/social/presentation/widgets/share_dialog.dart';
import 'package:to_do_app/theme/design_tokens.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/social/data/models/activity_post_model.dart';
import 'package:to_do_app/features/social/data/models/friendship_model.dart';
import 'package:to_do_app/features/social/presentation/providers/feed_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:dio/dio.dart';
import 'package:to_do_app/features/social/presentation/widgets/post_backgrounds.dart';

class ActivityPostCard extends ConsumerStatefulWidget {
  const ActivityPostCard({super.key, required this.post});

  final ActivityPostModel post;

  @override
  ConsumerState<ActivityPostCard> createState() => _ActivityPostCardState();
}

class _ActivityPostCardState extends ConsumerState<ActivityPostCard> {
  final LayerLink _likeButtonLink = LayerLink();
  final LayerLink _postMenuLink = LayerLink();
  final LayerLink _reactionAnchorLink = LayerLink();
  final LayerLink _emojiLink = LayerLink();
  final LayerLink _gifLink = LayerLink();
  final LayerLink _stickerLink = LayerLink();
  String? _activePickerTab;
  Timer? _reactionHoverTimer;
  Timer? _reactionAutoHideTimer;
  bool _showComments = false;
  bool _commentsLoading = false;
  bool _showReactionPicker = false;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  Map<String, dynamic>? _selectedAttachment;
  bool _uploadingAttachment = false;

  Map<String, String>? _localReactions;
  Map<String, String>? _localReactorNames;
  Map<String, Map<String, String>>? _localCommentReactions;

  String? _justClickedPostId;
  String? _justClickedCommentId;
  String? _replyingToCommentId;
  String? _replyingToAuthorName;

  int _pendingPostOperations = 0;
  final Map<String, int> _pendingCommentOperations = {};
  Future<void> _postLock = Future.value();
  final Map<String, Future<void>> _commentLocks = {};
  bool _hasUnsyncedPostUpdate = false;
  final Set<String> _unsyncedCommentIds = {};

  @override
  void initState() {
    super.initState();
    _localReactions = widget.post.reactions;
    _localReactorNames = widget.post.reactorNames;
    _localCommentReactions = {};
    for (final comment in widget.post.comments) {
      _localCommentReactions![comment.id] = Map<String, String>.from(comment.reactions);
      for (final reply in comment.replies) {
        _localCommentReactions![reply.id] = Map<String, String>.from(reply.reactions);
      }
    }
  }


    void _showReactionPickerDelayed() {
    _reactionHoverTimer?.cancel();
    _reactionHoverTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showReactionPicker = true);
        _startReactionAutoHide();
      }
    });
  }

  void _startReactionAutoHide() {
    _reactionAutoHideTimer?.cancel();
    _reactionAutoHideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _showReactionPicker = false);
    });
  }

  @override
  void didUpdateWidget(ActivityPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    final currentUserId = currentUser?.id;

    if (_pendingPostOperations == 0) {
      if (!_hasUnsyncedPostUpdate) {
        _localReactions = widget.post.reactions;
        _localReactorNames = widget.post.reactorNames;
      } else if (currentUserId != null) {
        final serverReaction = widget.post.reactions[currentUserId];
        final localReaction = _localReactions?[currentUserId];
        if (serverReaction == localReaction) {
          _localReactions = widget.post.reactions;
          _localReactorNames = widget.post.reactorNames;
          _hasUnsyncedPostUpdate = false;
        }
      }
    }
    
    _localCommentReactions ??= {};
    for (final comment in widget.post.comments) {
      // Sync parent comment
      final pendingCount = _pendingCommentOperations[comment.id] ?? 0;
      if (pendingCount == 0) {
        if (!_unsyncedCommentIds.contains(comment.id)) {
          _localCommentReactions![comment.id] = Map<String, String>.from(comment.reactions);
        } else if (currentUserId != null) {
          final serverReaction = comment.reactions[currentUserId];
          final localReaction = _localCommentReactions?[comment.id]?[currentUserId];
          if (serverReaction == localReaction) {
            _localCommentReactions![comment.id] = Map<String, String>.from(comment.reactions);
            _unsyncedCommentIds.remove(comment.id);
          }
        }
      }
      // Sync replies
      for (final reply in comment.replies) {
        final pendingReplyCount = _pendingCommentOperations[reply.id] ?? 0;
        if (pendingReplyCount == 0) {
          if (!_unsyncedCommentIds.contains(reply.id)) {
            _localCommentReactions![reply.id] = Map<String, String>.from(reply.reactions);
          } else if (currentUserId != null) {
            final serverReaction = reply.reactions[currentUserId];
            final localReaction = _localCommentReactions?[reply.id]?[currentUserId];
            if (serverReaction == localReaction) {
              _localCommentReactions![reply.id] = Map<String, String>.from(reply.reactions);
              _unsyncedCommentIds.remove(reply.id);
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _reactionHoverTimer?.cancel();
    _reactionAutoHideTimer?.cancel();
    super.dispose();
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
      if (_showComments) {
        _commentsLoading = true;
      }
    });
    if (_showComments) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _commentsLoading = false;
          });
        }
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _selectedAttachment == null) return;

    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;

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

      if (_replyingToCommentId != null) {
        await feedService.addReply(widget.post.id, currentUser.id, _replyingToCommentId!, finalContent);
      } else {
        await feedService.addComment(widget.post.id, currentUser.id, finalContent);
      }
      ref.invalidate(feedPostsProvider);
      
      _commentController.clear();
      setState(() {
        _selectedAttachment = null;
        _replyingToCommentId = null;
        _replyingToAuthorName = null;
      });
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

  Future<void> _toggleLike() async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;
    
    _justClickedPostId = widget.post.id;
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _justClickedPostId = null;
        });
      }
    });

    final currentReactions = _localReactions ?? widget.post.reactions;
    final currentReaction = currentReactions[currentUser.id];
    
    if (currentReaction != null) {
      await _submitReaction(currentUser.id, currentReaction);
    } else {
      await _submitReaction(currentUser.id, 'like');
    }
  }

  Future<void> _submitReaction(String currentUserId, String type) async {
    final oldReactions = _localReactions ?? widget.post.reactions;
    final oldReactorNames = _localReactorNames ?? widget.post.reactorNames;

    _justClickedPostId = widget.post.id;
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _justClickedPostId = null;
        });
      }
    });

    setState(() {
      _pendingPostOperations++;
      _hasUnsyncedPostUpdate = true;
      final reactions = Map<String, String>.from(oldReactions);
      final reactorNames = Map<String, String>.from(oldReactorNames);

      if (reactions[currentUserId] == type) {
        reactions.remove(currentUserId);
        reactorNames.remove(currentUserId);
      } else {
        reactions[currentUserId] = type;
        final currentUser = ref.read(authControllerProvider).valueOrNull;
        final currentUserName = currentUser?.fullName ?? currentUser?.username ?? 'Bạn';
        reactorNames[currentUserId] = currentUserName;
      }

      _localReactions = reactions;
      _localReactorNames = reactorNames;
    });

    final feedService = ref.read(feedServiceProvider);
    _postLock = _postLock.then((_) async {
      try {
        await feedService.toggleReaction(widget.post.id, currentUserId, type);
      } catch (e) {
        if (mounted) {
          setState(() {
            _localReactions = oldReactions;
            _localReactorNames = oldReactorNames;
            _hasUnsyncedPostUpdate = false;
          });
          PremiumToast.show(context, 'Lỗi: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() {
            _pendingPostOperations--;
            // if (_pendingPostOperations == 0) {
            //   _localReactions = null;
            //   _localReactorNames = null;
            // }
          });
        }
      }
    });
  }

  List<String> _getReactorNamesList(
    Map<String, String> reactions,
    Map<String, String> reactorNames,
    String? currentUserId,
  ) {
    final List<String> names = [];
    if (currentUserId != null && reactions.containsKey(currentUserId)) {
      names.add('Bạn');
    }
    for (final entry in reactions.entries) {
      final rUserId = entry.key;
      if (rUserId == currentUserId) continue;
      final name = reactorNames[rUserId] ?? 'Người dùng';
      names.add(name);
    }
    return names;
  }

  String _formatReactorNamesText(List<String> names) {
    if (names.isEmpty) return '';
    if (names.length == 1) {
      return names[0];
    }
    if (names.length == 2) {
      return '${names[0]} và ${names[1]}';
    }
    final othersCount = names.length - 2;
    return '${names[0]}, ${names[1]} và $othersCount người khác';
  }

  void _showReactorsBottomSheet(
    BuildContext context,
    Map<String, String> reactions,
    Map<String, String> reactorNames,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mọi người',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reactions.length,
                  itemBuilder: (context, index) {
                    final userId = reactions.keys.elementAt(index);
                    final reactType = reactions[userId]!;
                    final userName = reactorNames[userId] ?? 'Người dùng';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.white54, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            _getReactionEmoji(reactType),
                            style: TextStyle(
                              fontSize: 18,
                              color: _getReactionColor(reactType),
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
        );
      },
    );
  }

  Widget _buildReactionsSummaryLine(
    BuildContext context,
    Map<String, String> reactions,
    Map<String, String> reactorNames,
    String? currentUserId,
  ) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Count reactions to sort by frequency
    final reactionCounts = <String, int>{};
    for (final react in reactions.values) {
      reactionCounts[react] = (reactionCounts[react] ?? 0) + 1;
    }

    // Sort reactions ascending by count (so higher frequency reactions render last / on top)
    final uniqueReactions = reactionCounts.keys.toList()
      ..sort((a, b) => reactionCounts[a]!.compareTo(reactionCounts[b]!));

    final topUniqueReactions = uniqueReactions.take(3).toList();

    final names = _getReactorNamesList(reactions, reactorNames, currentUserId);
    final namesText = _formatReactorNamesText(names);

    return GestureDetector(
      onTap: () => _showReactorsBottomSheet(context, reactions, reactorNames),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(topUniqueReactions.length, (index) {
              final reactType = topUniqueReactions[index];
              return Align(
                widthFactor: 0.65, // Overlap 35%
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1E1E2E), // Match Feed card dark background
                      width: 1.0,
                    ),
                  ),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: Center(
                      child: Text(
                        _getReactionEmoji(reactType),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.0,
                          color: _getReactionColor(reactType),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              namesText,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12.5,
                fontFamily: 'Segoe UI',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionPicker(String currentUserId) {
    final reactions = ['like', 'love', 'care', 'haha', 'wow', 'sad', 'angry', 'rocket', 'fire', 'clap', 'party'];
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    
    final itemWidth = isMobile ? 30.0 : 48.0;
    final itemHeight = isMobile ? 54.0 : 82.0;
    final itemFontSize = isMobile ? 22.0 : 34.0;
    final containerHeight = isMobile ? 36.0 : 52.0;

    return MouseRegion(
      onEnter: (_) => _reactionAutoHideTimer?.cancel(),
      onExit: (_) => _startReactionAutoHide(),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomLeft,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: containerHeight,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(containerHeight / 2),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: reactions.map((type) {
                return ReactionPickerItem(
                  type: type,
                  emoji: _getReactionEmoji(type),
                  onTap: () {
                    _reactionAutoHideTimer?.cancel();
                    setState(() {
                      _showReactionPicker = false;
                    });
                    _justClickedPostId = widget.post.id;
                    Future.delayed(const Duration(milliseconds: 2000), () {
                      if (mounted) {
                        setState(() {
                          _justClickedPostId = null;
                        });
                      }
                    });
                    _submitReaction(currentUserId, type);
                  },
                  width: itemWidth,
                  height: itemHeight,
                  fontSize: itemFontSize,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String? _activeCommentReactionPickerId;

  Widget _buildCommentReactionPicker(String commentId, String currentUserId) {
    final reactions = ['like', 'love', 'care', 'haha', 'wow', 'sad', 'angry', 'rocket', 'fire', 'clap', 'party'];
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 52,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: reactions.map((type) {
              return ReactionPickerItem(
                type: type,
                emoji: _getReactionEmoji(type),
                onTap: () {
                  setState(() {
                    _activeCommentReactionPickerId = null;
                  });
                  _justClickedCommentId = commentId;
                  Future.delayed(const Duration(milliseconds: 2000), () {
                    if (mounted) {
                      setState(() {
                        _justClickedCommentId = null;
                      });
                    }
                  });
                  _submitCommentReaction(commentId, currentUserId, type);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _submitCommentReaction(String commentId, String currentUserId, String type) async {
    final oldCommentReactions = _localCommentReactions?[commentId] ?? {};
    
    _justClickedCommentId = commentId;
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _justClickedCommentId = null;
        });
      }
    });

    setState(() {
      _pendingCommentOperations[commentId] = (_pendingCommentOperations[commentId] ?? 0) + 1;
      _unsyncedCommentIds.add(commentId);
      final commentReactions = Map<String, String>.from(oldCommentReactions);
      if (commentReactions[currentUserId] == type) {
        commentReactions.remove(currentUserId);
      } else {
        commentReactions[currentUserId] = type;
      }
      _localCommentReactions ??= {};
      _localCommentReactions![commentId] = commentReactions;
    });

    final feedService = ref.read(feedServiceProvider);
    final commentLock = _commentLocks[commentId] ?? Future.value();
    
    _commentLocks[commentId] = commentLock.then((_) async {
      try {
        await feedService.toggleCommentReaction(commentId, currentUserId, type);
      } catch (e) {
        if (mounted) {
          setState(() {
            _localCommentReactions?[commentId] = oldCommentReactions;
          });
          PremiumToast.show(context, 'Lỗi: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() {
            final val = (_pendingCommentOperations[commentId] ?? 1) - 1;
            if (val <= 0) {
              _pendingCommentOperations.remove(commentId);
              // _localCommentReactions?.remove(commentId);
            } else {
              _pendingCommentOperations[commentId] = val;
            }
          });
        }
      }
    });
  }

  Future<void> _handleFriendAction(FriendshipStatus status) async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;

    final socialDs = ref.read(socialRemoteDataSourceProvider);
    try {
      if (status == FriendshipStatus.none) {
        await socialDs.sendFriendRequest(currentUser.id, widget.post.userId);
        if (mounted) {
          PremiumToast.show(context, 'Đã gửi yêu cầu kết bạn!');
        }
      } else if (status == FriendshipStatus.pendingReceived) {
        await socialDs.acceptFriendRequest(currentUser.id, widget.post.userId);
        if (mounted) {
          PremiumToast.show(context, 'Đã đồng ý kết bạn!');
        }
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Lỗi kết bạn: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final friendshipStatus = ref.watch(friendshipStatusProvider(widget.post.userId));
    final isMe = currentUser != null && currentUser.id == widget.post.userId;

    final displayReactions = _localReactions ?? widget.post.reactions;
    final displayReactorNames = _localReactorNames ?? widget.post.reactorNames;
    final displayLikedByUserIds = _localReactions != null 
        ? _localReactions!.keys.toList() 
        : widget.post.likedByUserIds;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          // Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.post.authorAvatarUrl.isNotEmpty
                    ? NetworkImage(widget.post.authorAvatarUrl)
                    : null,
                backgroundColor: Colors.grey.shade900,
                child: widget.post.authorAvatarUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white54)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.post.authorName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Lv.${widget.post.authorLevel}',
                            style: const TextStyle(
                              color: Color(0xFFA78BFA),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _timeAgo(widget.post.createdAt),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .4),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.circle, size: 3, color: Colors.white.withValues(alpha: .4)),
                        const SizedBox(width: 6),
                        Icon(Icons.public, size: 12, color: Colors.white.withValues(alpha: .4)),
                      ],
                    ),
                  ],
                ),
              ),
              // Friendship Action Button
              if (!isMe) ...[
                _buildFriendshipButton(friendshipStatus),
                const SizedBox(width: 8),
              ],
              // 3-dot menu button
              CompositedTransformTarget(
                link: _postMenuLink,
                child: Builder(
                  builder: (menuContext) {
                    return IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white70),
                      onPressed: () => _showPostMenu(menuContext),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Post Text Content & Background
          Builder(
            builder: (context) {
              final backgroundId = widget.post.metaData?['background_id'] as String?;
              if (backgroundId != null && widget.post.content.isNotEmpty) {
                final bg = getPostBackgroundById(backgroundId);
                if (bg != null) {
                  return Container(
                    width: double.infinity,
                    height: 260,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: bg.getDecoration(),
                    child: SingleChildScrollView(
                      child: Text(
                        widget.post.content,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: bg.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                }
              }

              if (widget.post.content.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    widget.post.content,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.5),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Post Attachments (Photo, Task, Achievement, Poll)
          _buildPostAttachment(currentUser?.id),

          const SizedBox(height: 12),
          const Divider(color: DesignTokens.borderSubtle, height: 1),
          const SizedBox(height: 8),

          // Likes / Comments Count Info, Divider, and Actions Row
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  // Likes / Comments Count Info
                  Row(
                    children: [
                      if (displayReactions.isNotEmpty) ...[
                        Expanded(
                          child: _buildReactionsSummaryLine(
                            context,
                            displayReactions,
                            displayReactorNames,
                            currentUser?.id,
                          ),
                        ),
                      ] else if (displayLikedByUserIds.isNotEmpty) ...[
                        const Text(
                          '👍',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${displayLikedByUserIds.length}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12.5,
                              fontFamily: 'Segoe UI',
                            ),
                          ),
                        ),
                      ] else ...[
                        const Spacer(),
                      ],
                      Builder(
                        builder: (context) {
                          int countCommentAndReplies(ActivityCommentModel comment) {
                            int count = 1;
                            for (final r in comment.replies) {
                              count += countCommentAndReplies(r);
                            }
                            return count;
                          }

                          int totalComments = 0;
                          for (final c in widget.post.comments) {
                            totalComments += countCommentAndReplies(c);
                          }

                          final sharesCount = widget.post.metaData?['sharesCount'] as int? ?? 0;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (totalComments > 0)
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _toggleComments,
                                    child: Text(
                                      '$totalComments bình luận',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12.5,
                                        fontFamily: 'Segoe UI',
                                      ),
                                    ),
                                  ),
                                ),
                              if (sharesCount > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '$sharesCount lượt chia sẻ',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12.5,
                                    fontFamily: 'Segoe UI',
                                  ),
                                ),
                              ],
                            ],
                          );
                        }
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: DesignTokens.borderSubtle, height: 1),
                  CompositedTransformTarget(
                    link: _reactionAnchorLink,
                    child: const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 6),

                  // Like / Comment / Share Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Like Button with custom reaction layout
                      CompositedTransformTarget(
                        link: _likeButtonLink,
                        child: MouseRegion(
                          onEnter: (event) {
                            if (event.kind == PointerDeviceKind.touch) return;
                            if (currentUser != null) _showReactionPickerDelayed();
                          },
                          onExit: (_) {
                            _reactionHoverTimer?.cancel();
                          },
                          child: Builder(
                            builder: (context) {
                              final postReactions = displayReactions;
                              final myReaction = currentUser != null ? postReactions[currentUser.id] : null;
                              final hasReacted = myReaction != null;

                              String label = 'Thích';
                              Color btnColor = const Color(0xFFE4E6EB);
                              Widget iconWidget = const Icon(Icons.thumb_up_outlined, size: 22, color: Color(0xFFE4E6EB));

                              if (hasReacted) {
                                label = _getReactionLabel(myReaction);
                                btnColor = _getReactionColor(myReaction);
                                iconWidget = Text(
                                  _getReactionEmoji(myReaction),
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: _getReactionColor(myReaction),
                                  ),
                                );
                              }

                              return _buildActionButton(
                                iconWidget: iconWidget,
                                label: label,
                                color: btnColor,
                                onTap: _toggleLike,
                                onLongPress: () {
                                  if (currentUser != null) {
                                    setState(() {
                                      _showReactionPicker = !_showReactionPicker;
                                    });
                                    if (_showReactionPicker) {
                                      _startReactionAutoHide();
                                    } else {
                                      _reactionAutoHideTimer?.cancel();
                                    }
                                  }
                                },
                              );
                            }
                          ),
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.mode_comment_outlined,
                        label: 'Bình luận',
                        color: const Color(0xFFE4E6EB),
                        onTap: _toggleComments,
                      ),
                      _buildActionButton(
                        icon: Icons.share_outlined,
                        label: 'Chia sẻ',
                        color: const Color(0xFFE4E6EB),
                        onTap: () {
                          if (currentUser != null) {
                            showDialog(
                              context: context,
                              builder: (context) => ShareDialog(post: widget.post),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
          // Expandable Comments Section
          if (_showComments) _buildCommentsSection(currentUser?.id),
        ],
      ),
      if (_showReactionPicker && currentUser != null)
        CompositedTransformFollower(
          link: _reactionAnchorLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          // Đặt sát lề trái thẻ bài viết (dx = -16.0) và nằm phía trên thanh action (dy = -8.0).
          offset: const Offset(-16.0, -8.0),
          child: TapRegion(
            onTapOutside: (_) {
              _reactionAutoHideTimer?.cancel();
              setState(() => _showReactionPicker = false);
            },
            child: _buildReactionPicker(currentUser.id),
          ),
        ),
    ],
  ),
    ),
  );
}

  Widget _buildFriendshipButton(FriendshipStatus status) {
    if (status == FriendshipStatus.friends) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: Colors.white70, size: 14),
            SizedBox(width: 4),
            Text('Bạn bè', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    String label = '';
    IconData? icon;
    bool isActionable = true;

    if (status == FriendshipStatus.none) {
      label = 'Kết bạn';
      icon = Icons.person_add_rounded;
    } else if (status == FriendshipStatus.pendingSent) {
      label = 'Đã gửi';
      icon = Icons.hourglass_empty_rounded;
      isActionable = false;
    } else if (status == FriendshipStatus.pendingReceived) {
      label = 'Chấp nhận';
      icon = Icons.check_circle_outline_rounded;
    } else if (status == FriendshipStatus.blocked) {
      label = 'Đã chặn';
      isActionable = false;
    }

    return ElevatedButton.icon(
      onPressed: isActionable ? () => _handleFriendAction(status) : null,
      icon: icon != null ? Icon(icon, size: 12, color: Colors.white) : const SizedBox.shrink(),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: status == FriendshipStatus.pendingReceived
            ? const Color(0xFF7C5CFF)
            : Colors.white.withValues(alpha: .1),
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showPostMenu(BuildContext menuContext) {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    final isMe = currentUser != null && currentUser.id == widget.post.userId;

    final currentPrivacy = widget.post.metaData?['privacy'] as String? ?? 'public';
    final isPinned = widget.post.metaData?['is_pinned'] == true;
    final isArchived = widget.post.metaData?['is_archived'] == true;
    final isNotificationsDisabled = widget.post.metaData?['is_notifications_disabled'] == true;
    final isSaved = widget.post.metaData?['is_saved'] == true;
    final isHidden = widget.post.metaData?['is_hidden'] == true;

    PostMenuOverlay.show(
      context: context,
      triggerContext: menuContext,
      layerLink: _postMenuLink,
      postId: widget.post.id,
      isMe: isMe,
      currentPrivacy: currentPrivacy,
      isPinned: isPinned,
      isArchived: isArchived,
      isCommentsDisabled: widget.post.commentsDisabled,
      isNotificationsDisabled: isNotificationsDisabled,
      isSaved: isSaved,
      isHidden: isHidden,
      authorName: widget.post.authorName,
      authorAvatarUrl: widget.post.authorAvatarUrl,
      onAction: _handlePostAction,
      onPrivacyChanged: _handlePostPrivacyChanged,
    );
  }

  Future<void> _handlePostAction(String action) async {
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
          await client.from('activity_feed').delete().eq('id', widget.post.id);
          if (mounted) {
            PremiumToast.show(context, 'Đã xóa bài viết');
          }
        } catch (e) {
          if (mounted) {
            PremiumToast.show(context, 'Lỗi xóa bài viết: $e', isError: true);
          }
        }
      }
    } else if (action == 'toggle_comment') {
      try {
        final newCommentsDisabled = !widget.post.commentsDisabled;
        final currentMeta = Map<String, dynamic>.from(widget.post.metaData ?? {});
        currentMeta['comments_disabled'] = newCommentsDisabled;
        await client.from('activity_feed').update({'meta_data': currentMeta}).eq('id', widget.post.id);
        if (mounted) {
          PremiumToast.show(context, newCommentsDisabled ? 'Đã tắt bình luận bài viết' : 'Đã bật bình luận bài viết');
        }
      } catch (e) {
        if (mounted) {
          PremiumToast.show(context, 'Lỗi thay đổi trạng thái bình luận: $e', isError: true);
        }
      }
    } else if (action == 'edit') {
      if (mounted) {
        PremiumToast.show(context, 'Chức năng chỉnh sửa bài viết đang được phát triển');
      }
    } else if (action == 'archive') {
      try {
        final currentMeta = Map<String, dynamic>.from(widget.post.metaData ?? {});
        currentMeta['is_archived'] = true;
        await client.from('activity_feed').update({'meta_data': currentMeta}).eq('id', widget.post.id);
        if (mounted) {
          PremiumToast.show(context, 'Đã lưu trữ bài viết');
        }
      } catch (e) {
        if (mounted) {
          PremiumToast.show(context, 'Lỗi lưu trữ bài viết: $e', isError: true);
        }
      }
    } else if (action == 'turn_off_notification') {
      try {
        final currentMeta = Map<String, dynamic>.from(widget.post.metaData ?? {});
        final currentVal = currentMeta['is_notifications_disabled'] == true;
        currentMeta['is_notifications_disabled'] = !currentVal;
        await client.from('activity_feed').update({'meta_data': currentMeta}).eq('id', widget.post.id);
        if (mounted) {
          PremiumToast.show(context, !currentVal ? 'Đã tắt thông báo bài viết này' : 'Đã bật thông báo bài viết này');
        }
      } catch (e) {
        if (mounted) {
          PremiumToast.show(context, 'Lỗi thay đổi thông báo: $e', isError: true);
        }
      }
    } else if (action == 'save') {
      try {
        final currentMeta = Map<String, dynamic>.from(widget.post.metaData ?? {});
        final currentVal = currentMeta['is_saved'] == true;
        currentMeta['is_saved'] = !currentVal;
        await client.from('activity_feed').update({'meta_data': currentMeta}).eq('id', widget.post.id);
        if (mounted) {
          PremiumToast.show(context, !currentVal ? 'Đã lưu bài viết' : 'Đã bỏ lưu bài viết');
        }
      } catch (e) {
        if (mounted) {
          PremiumToast.show(context, 'Lỗi lưu bài viết: $e', isError: true);
        }
      }
    } else if (action == 'hide') {
      try {
        final currentMeta = Map<String, dynamic>.from(widget.post.metaData ?? {});
        currentMeta['is_hidden'] = true;
        await client.from('activity_feed').update({'meta_data': currentMeta}).eq('id', widget.post.id);
        if (mounted) {
          PremiumToast.show(context, 'Đã ẩn bài viết này');
        }
      } catch (e) {
        if (mounted) {
          PremiumToast.show(context, 'Lỗi ẩn bài viết: $e', isError: true);
        }
      }
    }
  }

  Future<void> _handlePostPrivacyChanged(String privacy) async {
    final client = ref.read(supabaseClientProvider);
    try {
      final currentMeta = Map<String, dynamic>.from(widget.post.metaData ?? {});
      currentMeta['privacy'] = privacy;
      await client.from('activity_feed').update({'meta_data': currentMeta}).eq('id', widget.post.id);
      if (mounted) {
        PremiumToast.show(context, 'Đã đổi quyền riêng tư thành: $privacy');
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Lỗi đổi quyền riêng tư: $e', isError: true);
      }
    }
  }

  Widget _buildAttachmentFor(ActivityPostModel post, String? currentUserId) {
    if (post.type == 'photo' && post.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          post.mediaUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.white.withValues(alpha: .04),
              child: const Center(child: CircularProgressIndicator(color: Colors.white24)),
            );
          },
        ),
      );
    }

    if (post.type == 'task') {
      final taskTitle = post.metaData?['taskTitle'] as String? ?? 'Công việc';
      final taskStatus = post.metaData?['taskStatus'] as String? ?? 'todo';
      final taskPriority = post.metaData?['taskPriority'] as String? ?? 'medium';

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .03),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: .15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF3B82F6), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskTitle,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildBadge(
                        label: taskStatus.toUpperCase(),
                        color: taskStatus == 'completed' || taskStatus == 'done' ? Colors.green : Colors.amber,
                      ),
                      const SizedBox(width: 6),
                      _buildBadge(
                        label: taskPriority.toUpperCase(),
                        color: taskPriority == 'high' || taskPriority == 'urgent' ? Colors.redAccent : Colors.blueGrey,
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

    if (post.type == 'achievement') {
      final title = post.metaData?['achievementTitle'] as String? ?? 'Danh hiệu';
      final desc = post.metaData?['achievementDesc'] as String? ?? '';

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.military_tech_rounded, size: 40, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (post.type == 'poll') {
      final options = List<String>.from(post.metaData?['pollOptions'] ?? []);
      final votes = Map<String, String>.from(post.metaData?['votes'] ?? {});
      final totalVotes = votes.length;

      // Group votes
      final votesCounts = <String, int>{};
      for (var opt in options) {
        votesCounts[opt] = 0;
      }
      for (var v in votes.values) {
        if (votesCounts.containsKey(v)) {
          votesCounts[v] = votesCounts[v]! + 1;
        }
      }

      final hasVoted = currentUserId != null && votes.containsKey(currentUserId);
      final userVote = votes[currentUserId];

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .03),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...options.map((opt) {
              final count = votesCounts[opt] ?? 0;
              final percent = totalVotes == 0 ? 0.0 : (count / totalVotes);
              final isUserSelection = userVote == opt;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: () async {
                    if (currentUserId == null || hasVoted) return;
                    await ref.read(feedServiceProvider).voteOnPoll(post.id, currentUserId, opt);
                  },
                  child: Stack(
                    children: [
                      // Progress background
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percent,
                            child: Container(
                              color: isUserSelection
                                  ? const Color(0xFF7C5CFF).withValues(alpha: .24)
                                  : Colors.white.withValues(alpha: .08),
                            ),
                          ),
                        ),
                      ),
                      // Text overlay
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isUserSelection
                                ? const Color(0xFF7C5CFF)
                                : Colors.white.withValues(alpha: .08),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              opt,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isUserSelection ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13.5,
                              ),
                            ),
                            if (hasVoted)
                              Text(
                                '${(percent * 100).round()}% ($count)',
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
            Text(
              'Tổng số bình chọn: $totalVotes',
              style: TextStyle(color: Colors.white.withValues(alpha: .4), fontSize: 11),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPostAttachment(String? currentUserId) {
    if (widget.post.type == 'share') {
      final sharedPost = widget.post.sharedPost;
      if (sharedPost == null) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .03),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white54, size: 20),
              SizedBox(width: 10),
              Text(
                'Bài viết này hiện không khả dụng.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .15),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Inner Author Header
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: sharedPost.authorAvatarUrl.isNotEmpty
                      ? NetworkImage(sharedPost.authorAvatarUrl)
                      : null,
                  backgroundColor: Colors.grey.shade900,
                  child: sharedPost.authorAvatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 14, color: Colors.white54)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              sharedPost.authorName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .06),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'Lv.${sharedPost.authorLevel}',
                              style: const TextStyle(
                                color: Color(0xFFA78BFA),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _timeAgo(sharedPost.createdAt),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .3),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.circle, size: 2.5, color: Colors.white.withValues(alpha: .3)),
                          const SizedBox(width: 4),
                          Icon(Icons.public, size: 10.5, color: Colors.white.withValues(alpha: .3)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Inner Post content
            if (sharedPost.content.isNotEmpty) ...[
              Text(
                sharedPost.content,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
            ],
            // Inner Post attachment
            _buildAttachmentFor(sharedPost, currentUserId),
          ],
        ),
      );
    }

    return _buildAttachmentFor(widget.post, currentUserId);
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconWidget != null)
                iconWidget
              else if (icon != null)
                Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  height: 1.2,
                  fontFamily: 'Inter',
                  fontFamilyFallback: const ['SF Pro Display', 'Segoe UI', 'Roboto'],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection(String? currentUserId) {
    if (_commentsLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Divider(color: DesignTokens.borderSubtle, height: 1),
          const SizedBox(height: 12),
          const CommentSkeleton(),
          const CommentSkeleton(),
          const CommentSkeleton(),
        ],
      );
    }

    final sortOption = ref.watch(commentSortOptionProvider(widget.post.id));
    final sortedComments = _getSortedComments(sortOption);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Divider(color: DesignTokens.borderSubtle, height: 1),
        const SizedBox(height: 12),
        
        // Comment Header with Sort Options
        _buildCommentHeader(sortOption),
        
        const SizedBox(height: 12),
        
        if (sortedComments.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: sortedComments.length,
            itemBuilder: (context, index) {
              final comment = sortedComments[index];
              return CommentCard(
                key: ValueKey(comment.id),
                comment: comment,
                currentUserId: currentUserId,
                postOwnerId: widget.post.userId,
                isCommentsDisabled: widget.post.commentsDisabled,
                onReplyPressed: (authorName, authorId) => _replyToComment(comment.id, authorName, authorId),
                onEditComment: _handleEditComment,
                onDeleteComment: _handleDeleteComment,
                onPinComment: _handlePinComment,
                onHideComment: _handleHideComment,
                onBlockUser: _handleBlockUser,
                onReactionSelected: (commentId, type) => _submitCommentReaction(commentId, currentUserId ?? '', type),
                localCommentReactions: _localCommentReactions,
              );
            },
          ),
        
        const SizedBox(height: 12),
        
        // Replying indicator
        if (_replyingToCommentId != null)
          _buildReplyingIndicator(),
          
        // Comment Input
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildCommentHeader(String sortOption) {
    final sortLabels = {
      'newest': 'Mới nhất',
      'popular': 'Phổ biến',
      'interactions': 'Tương tác',
      'has_replies': 'Có trả lời',
    };
    final currentLabel = sortLabels[sortOption] ?? 'Mới nhất';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Bình luận',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Sắp xếp bình luận',
          onSelected: (value) {
            ref.read(commentSortOptionProvider(widget.post.id).notifier).state = value;
          },
          offset: const Offset(0, 35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: const Color(0xFF7C5CFF).withValues(alpha: 0.25), width: 0.5),
          ),
          color: const Color(0xFF1A1730),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C5CFF).withValues(alpha: 0.08),
              border: Border.all(color: const Color(0xFF7C5CFF).withValues(alpha: 0.3), width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currentLabel ',
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFFA78BFA),
                  size: 16,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            _buildSortMenuItem('newest', 'Mới nhất', Icons.access_time_rounded, sortOption == 'newest'),
            _buildSortMenuItem('popular', 'Phổ biến', Icons.local_fire_department_rounded, sortOption == 'popular'),
            const PopupMenuItem<String>(
              enabled: false,
              height: 1,
              padding: EdgeInsets.zero,
              child: Divider(
                color: Color(0x1F7C5CFF), // rgba(124, 92, 255, 0.12)
                height: 1,
                thickness: 0.5,
              ),
            ),
            _buildSortMenuItem('interactions', 'Tương tác', Icons.bolt_rounded, sortOption == 'interactions'),
            _buildSortMenuItem('has_replies', 'Có trả lời', Icons.reply_rounded, sortOption == 'has_replies'),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(
    String value,
    String label,
    IconData icon,
    bool isSelected,
  ) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      height: 38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isSelected ? const Color(0x1F7C5CFF) : Colors.transparent, // rgba(124, 92, 255, 0.12)
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFA78BFA) : Colors.white30,
              size: 15,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFA78BFA) : Colors.white70,
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Check badge
            Opacity(
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0x337C5CFF), // rgba(124, 92, 255, 0.2)
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(Icons.check_rounded, color: Color(0xFFA78BFA), size: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: Colors.white24,
          ),
          const SizedBox(height: 12),
          Text(
            '💬 Chưa có bình luận nào. Hãy là người đầu tiên bình luận',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.38),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    if (currentUser == null) return const SizedBox.shrink();

    final currentUserProfile = ref.watch(userProfileProvider).valueOrNull;
    final avatarUrl = currentUserProfile?.avatarUrl ?? currentUser.avatarUrl;
    final fullName = currentUserProfile?.fullName ?? currentUser.fullName;
    final username = currentUserProfile?.username ?? currentUser.username;
    final displayName = fullName != null && fullName.isNotEmpty
        ? (username != null && username.isNotEmpty ? '$fullName (@$username)' : fullName)
        : (username != null && username.isNotEmpty ? '@$username' : 'bạn');

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current User Avatar with chevron dropdown overlay
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                backgroundColor: Colors.grey.shade900,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? const Icon(Icons.person, size: 16, color: Colors.white54)
                    : null,
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E2130),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(1),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70,
                  size: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          
          // Unified comment input capsule box
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
                  // Text input field
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
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submitComment(),
                  ),
                  
                  // Uploading attachment state indicator
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
                        onTap: _pickFile,
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
                      
                      // Send arrow button
                      GestureDetector(
                        onTap: _submitComment,
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

  Widget _buildReplyingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFA78BFA).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.2)),
        ),
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
    );
  }

  List<ActivityCommentModel> _getSortedComments(String sortOption) {
    final List<ActivityCommentModel> parentComments = widget.post.comments
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

  Future<void> _handleEditComment(String commentId, String content) async {
    try {
      final feedService = ref.read(feedServiceProvider);
      await feedService.editComment(commentId, content);
      ref.invalidate(feedPostsProvider);
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Lỗi sửa bình luận: $e', isError: true);
      }
    }
  }

  Future<void> _handleDeleteComment(String commentId) async {
    try {
      final feedService = ref.read(feedServiceProvider);
      await feedService.deleteComment(commentId);
      ref.invalidate(feedPostsProvider);
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Lỗi xóa bình luận: $e', isError: true);
      }
    }
  }

  Future<void> _handlePinComment(String commentId, bool pin) async {
    try {
      final feedService = ref.read(feedServiceProvider);
      await feedService.togglePinComment(commentId, pin);
      ref.invalidate(feedPostsProvider);
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Lỗi ghim bình luận: $e', isError: true);
      }
    }
  }

  void _handleHideComment(String commentId) {
    ref.read(hiddenCommentIdsProvider.notifier).update((state) => {...state, commentId});
    if (mounted) {
      PremiumToast.show(context, 'Đã ẩn bình luận này');
    }
  }

  void _handleBlockUser(String userId) {
    ref.read(blockedUserIdsProvider.notifier).blockUser(userId);
    if (mounted) {
      PremiumToast.show(context, 'Đã chặn người dùng này');
    }
  }

  void _replyToComment(String commentId, String authorName, String authorId) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToAuthorName = authorName;
      
      final currentUser = ref.read(authControllerProvider).valueOrNull;
      final currentUserId = currentUser?.id;
      
      if (currentUserId != authorId) {
        final mentionString = '@$authorName ';
        if (!_commentController.text.startsWith(mentionString)) {
          _commentController.text = '$mentionString${_commentController.text}';
        }
      }
      
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    _commentFocusNode.requestFocus();
  }
}

class ReactionPickerItem extends StatefulWidget {
  final String type;
  final String emoji;
  final VoidCallback onTap;
  final double width;
  final double height;
  final double fontSize;

  const ReactionPickerItem({
    super.key,
    required this.type,
    required this.emoji,
    required this.onTap,
    this.width = 48,
    this.height = 82,
    this.fontSize = 34,
  });

  @override
  State<ReactionPickerItem> createState() => _ReactionPickerItemState();
}

class _ReactionPickerItemState extends State<ReactionPickerItem> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _animationController.repeat();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _animationController.stop();
        _animationController.reset();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                transform: Matrix4.translationValues(0.0, _isHovered ? -(widget.height * 0.15) : 0.0, 0.0)
                  ..multiply(Matrix4.diagonal3Values(_isHovered ? 1.4 : 1.0, _isHovered ? 1.4 : 1.0, 1.0)),
                transformAlignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return _buildAnimatedEmoji(widget.type, _animationController.value);
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: widget.height > 60 ? -14 : -10,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _isHovered ? 1.0 : 0.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    transform: Matrix4.translationValues(0.0, _isHovered ? 0.0 : 5.0, 0.0),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getTooltipLabel(widget.type),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedEmoji(String type, double val) {
    final emojiWidget = Text(
      widget.emoji,
      style: TextStyle(
        fontSize: widget.fontSize,
        height: 1.0,
        color: _getReactionColor(type),
      ),
    );

    if (!_isHovered) return emojiWidget;

    final String t = type.toLowerCase();
    Matrix4 transform = Matrix4.identity();
    Widget currentWidget = emojiWidget;

    if (t == 'like') {
      final double dy = -6.0 * math.sin(val * math.pi * 2).abs();
      transform = Matrix4.translationValues(0.0, dy, 0.0);
    } else if (t == 'love' || t == 'heart') {
      double scale = 1.0;
      if (val < 0.3) {
        scale += 0.20 * math.sin((val / 0.3) * math.pi);
      } else if (val < 0.6) {
        scale += 0.15 * math.sin(((val - 0.3) / 0.3) * math.pi);
      }
      transform = Matrix4.diagonal3Values(scale, scale, 1.0);
    } else if (t == 'care') {
      final double angle = 0.12 * math.sin(val * math.pi * 2);
      final double dx = 3.0 * math.sin(val * math.pi * 2);
      transform = Matrix4.translationValues(dx, 0.0, 0.0)..rotateZ(angle);
    } else if (t == 'haha') {
      final double dy = -5.0 * math.sin(val * math.pi * 4).abs();
      final double angle = 0.1 * math.sin(val * math.pi * 6);
      transform = Matrix4.translationValues(0.0, dy, 0.0)..rotateZ(angle);
    } else if (t == 'wow') {
      final double sy = 1.0 + 0.2 * math.sin(val * math.pi * 2);
      final double sx = 1.0 - 0.1 * math.sin(val * math.pi * 2);
      transform = Matrix4.diagonal3Values(sx, sy, 1.0);
    } else if (t == 'sad') {
      final double angle = 0.06 * math.sin(val * math.pi * 2);
      transform = Matrix4.rotationZ(angle);
      currentWidget = CustomPaint(
        foregroundPainter: _TearPainter(val),
        child: emojiWidget,
      );
    } else if (t == 'angry') {
      final double dx = 1.5 * math.sin(val * math.pi * 28);
      final double dy = 1.0 * math.cos(val * math.pi * 36);
      transform = Matrix4.translationValues(dx, dy, 0.0);
    } else if (t == 'rocket') {
      final double dx = 1.0 * math.sin(val * math.pi * 18);
      final double dy = -6.0 * math.sin(val * math.pi * 2);
      final double angle = 0.04 * math.sin(val * math.pi * 18);
      transform = Matrix4.translationValues(dx, dy, 0.0)..rotateZ(angle);
    } else if (t == 'fire') {
      final double sy = 1.0 + 0.12 * math.sin(val * math.pi * 10);
      final double sx = 1.0 - 0.06 * math.sin(val * math.pi * 10);
      final double dy = -1.5 * math.sin(val * math.pi * 5);
      transform = Matrix4.translationValues(0.0, dy, 0.0)..multiply(Matrix4.diagonal3Values(sx, sy, 1.0));
    } else if (t == 'clap') {
      final double angle = 0.12 * math.cos(val * math.pi * 8);
      final double scale = 1.0 + 0.08 * math.sin(val * math.pi * 8).abs();
      transform = Matrix4.diagonal3Values(scale, scale, 1.0)..rotateZ(angle);
    } else if (t == 'party') {
      final double angle = 0.08 * math.sin(val * math.pi * 4);
      final double scale = 1.0 + 0.12 * math.sin(val * math.pi * 2).abs();
      transform = Matrix4.diagonal3Values(scale, scale, 1.0)..rotateZ(angle);
      currentWidget = CustomPaint(
        foregroundPainter: _ConfettiPainter(val),
        child: emojiWidget,
      );
    }

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: currentWidget,
    );
  }
}

class _TearPainter extends CustomPainter {
  final double progress;
  _TearPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF29B6F6).withValues(alpha: 1.0 - progress)
      ..style = PaintingStyle.fill;

    double cx = size.width / 2;
    double cy = size.height / 2 + 2;

    double ly = cy + (size.height - cy) * progress;
    double lx = cx - 7;
    _drawTear(canvas, lx, ly, paint);

    double rp = (progress + 0.5) % 1.0;
    double ry = cy + (size.height - cy) * rp;
    double rx = cx + 7;
    final rightPaint = Paint()
      ..color = const Color(0xFF29B6F6).withValues(alpha: 1.0 - rp)
      ..style = PaintingStyle.fill;
    _drawTear(canvas, rx, ry, rightPaint);
  }

  void _drawTear(Canvas canvas, double x, double y, Paint paint) {
    final path = Path();
    path.moveTo(x, y - 4);
    path.quadraticBezierTo(x + 2, y - 2, x + 3, y);
    path.arcToPoint(Offset(x - 3, y), radius: const Radius.circular(3), clockwise: true);
    path.quadraticBezierTo(x - 2, y - 2, x, y - 4);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TearPainter oldDelegate) => oldDelegate.progress != progress;
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.yellowAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
    ];

    const numParticles = 14;
    for (int i = 0; i < numParticles; i++) {
      final double angle = (i * (360 / numParticles)) * math.pi / 180;
      final double speed = 12.0 + (i % 3) * 6.0;
      double dist = progress * speed;
      double dy = 0.5 * 9.8 * progress * progress * 8;

      double px = cx + math.cos(angle) * dist;
      double py = cy + math.sin(angle) * dist + dy;

      final color = colors[i % colors.length].withValues(alpha: 1.0 - progress);
      final paint = Paint()..color = color;

      if (i % 3 == 0) {
        canvas.drawCircle(Offset(px, py), 2.0 + (i % 2), paint);
      } else if (i % 3 == 1) {
        final rect = Rect.fromCenter(center: Offset(px, py), width: 3.5, height: 3.5);
        canvas.drawRect(rect, paint);
      } else {
        final linePaint = Paint()
          ..color = color
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(px, py),
          Offset(px - math.cos(angle) * 3, py - math.sin(angle) * 3),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

String _getTooltipLabel(String type) {
  switch (type.toLowerCase()) {
    case 'heart':
    case 'love':
      return 'Yêu thích';
    case 'care':
      return 'Thương thương';
    case 'haha':
      return 'Haha';
    case 'wow':
      return 'Wow';
    case 'sad':
      return 'Buồn';
    case 'angry':
      return 'Phẫn nộ';
    case 'rocket':
      return 'Bứt phá';
    case 'fire':
      return 'Cố lên';
    case 'clap':
      return 'Vỗ tay';
    case 'party':
      return 'Tiệc tùng';
    default:
      return 'Thích';
  }
}

String _getReactionEmoji(String type) {
  switch (type.toLowerCase()) {
    case 'like':
      return '👍';
    case 'heart':
    case 'love':
      return '❤️';
    case 'care':
      return '🥰';
    case 'haha':
      return '😆';
    case 'wow':
      return '😮';
    case 'sad':
      return '😢';
    case 'angry':
      return '😡';
    case 'rocket':
      return '🚀';
    case 'fire':
      return '🔥';
    case 'clap':
      return '👏';
    case 'party':
      return '🎉';
    default:
      return '👍';
  }
}

String _getReactionLabel(String type) {
  switch (type.toLowerCase()) {
    case 'heart':
    case 'love':
      return 'Yêu thích';
    case 'care':
      return 'Thương thương';
    case 'haha':
      return 'Haha';
    case 'wow':
      return 'Wow';
    case 'sad':
      return 'Buồn';
    case 'angry':
      return 'Phẫn nộ';
    case 'rocket':
      return 'Bứt phá';
    case 'fire':
      return 'Cố lên';
    case 'clap':
      return 'Vỗ tay';
    case 'party':
      return 'Tiệc tùng';
    default:
      return 'Thích';
  }
}

Color _getReactionColor(String type) {
  switch (type.toLowerCase()) {
    case 'heart':
    case 'love':
      return Colors.red;
    case 'care':
    case 'haha':
    case 'wow':
    case 'sad':
      return const Color(0xFFF7B125);
    case 'angry':
      return const Color(0xFFF15A36);
    case 'rocket':
      return Colors.cyanAccent;
    case 'fire':
      return Colors.orangeAccent;
    case 'clap':
      return Colors.yellowAccent;
    case 'party':
      return Colors.pinkAccent;
    default:
      return const Color(0xFF0866FF);
  }
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

class _ReplyConnectionPainter extends CustomPainter {
  final bool isLast;
  final Color lineColor;
  final double startX;

  _ReplyConnectionPainter({
    required this.isLast,
    required this.lineColor,
    required this.startX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const double targetY = 12.0;
    const double endX = -8.0;

    if (isLast) {
      path.moveTo(startX, 0);
      path.lineTo(startX, targetY - 10);
      path.quadraticBezierTo(startX, targetY, startX + 10, targetY);
      path.lineTo(endX, targetY);
    } else {
      path.moveTo(startX, 0);
      path.lineTo(startX, size.height);
      
      path.moveTo(startX, targetY - 10);
      path.quadraticBezierTo(startX, targetY, startX + 10, targetY);
      path.lineTo(endX, targetY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ReplyConnectionPainter oldDelegate) {
    return oldDelegate.isLast != isLast ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.startX != startX;
  }
}

class CommentCard extends StatefulWidget {
  final ActivityCommentModel comment;
  final String? currentUserId;
  final String postOwnerId;
  final bool isCommentsDisabled;
  final void Function(String authorName, String authorId) onReplyPressed;
  final void Function(String commentId, String text) onEditComment;
  final void Function(String commentId) onDeleteComment;
  final void Function(String commentId, bool pin) onPinComment;
  final void Function(String commentId) onHideComment;
  final void Function(String userId) onBlockUser;
  final void Function(String commentId, String type) onReactionSelected;
  final Map<String, Map<String, String>>? localCommentReactions;

  const CommentCard({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.postOwnerId,
    required this.isCommentsDisabled,
    required this.onReplyPressed,
    required this.onEditComment,
    required this.onDeleteComment,
    required this.onPinComment,
    required this.onHideComment,
    required this.onBlockUser,
    required this.onReactionSelected,
    this.localCommentReactions,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> with SingleTickerProviderStateMixin {
  final LayerLink _menuLink = LayerLink();
  final LayerLink _likeLink = LayerLink();
  Timer? _hoverTimer;
  Timer? _autoHideTimer;
  bool _isHovered = false;
  bool _isMenuOpen = false;
  bool _showReactionPicker = false;
  Timer? _reactionCloseTimer;
  bool _showReplies = false;
  bool _repliesLoading = false;

  bool _isEditing = false;
  late TextEditingController _editController;
  String? _localContent;

  late AnimationController _repliesController;
  late Animation<double> _repliesAnimation;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: _getCommentText(widget.comment.content));
    _repliesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _repliesAnimation = CurvedAnimation(
      parent: _repliesController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(CommentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comment.content != oldWidget.comment.content) {
      setState(() {
        _localContent = null;
      });
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _reactionCloseTimer?.cancel();
    _repliesController.dispose();
    _hoverTimer?.cancel();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editController.text = _getCommentText(widget.comment.content);
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  void _submitEdit() {
    final text = _editController.text.trim();
    if (text.isNotEmpty) {
      String finalContent = text;
      try {
        final raw = widget.comment.content;
        if (raw.startsWith('{') && raw.endsWith('}')) {
          final data = jsonDecode(raw);
          if (data is Map && data.containsKey('attachment')) {
            finalContent = jsonEncode({
              'text': text,
              'attachment': data['attachment'],
            });
          }
        }
      } catch (_) {}
      
      if (finalContent != widget.comment.content) {
        setState(() {
          _localContent = finalContent;
        });
        widget.onEditComment(widget.comment.id, finalContent);
      }
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _showPicker() {
    _reactionCloseTimer?.cancel();
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showReactionPicker = true);
        _startAutoHide();
      }
    });
  }

  void _startAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _showReactionPicker = false);
    });
  }

  void _hidePickerDelayed() {
     _hoverTimer?.cancel();
  }

  void _showMenu(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      _showMobileBottomSheet(context);
    } else {
      CommentMenuOverlay.show(
        context: context,
        triggerContext: context,
        layerLink: _menuLink,
        isMe: widget.comment.userId == widget.currentUserId,
        isPostOwner: widget.currentUserId == widget.postOwnerId,
        isPinned: widget.comment.isPinned,
        onEdit: _startEditing,
        onTogglePin: () => widget.onPinComment(widget.comment.id, !widget.comment.isPinned),
        onDelete: () => widget.onDeleteComment(widget.comment.id),
        onHide: () => widget.onHideComment(widget.comment.id),
        onBlock: () => widget.onBlockUser(widget.comment.userId),
        onReport: _reportComment,
        onCopyLink: _copyCommentLink,
        buttonSize: 30.0,
        onClose: () {
          if (mounted) {
            setState(() {
              _isMenuOpen = false;
            });
          }
        },
      );
      setState(() {
        _isMenuOpen = true;
      });
    }
  }

  void _showMobileBottomSheet(BuildContext context) {
    final isMe = widget.comment.userId == widget.currentUserId;
    final isPostOwner = widget.currentUserId == widget.postOwnerId;
    final isPinned = widget.comment.isPinned;

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
              const SizedBox(height: 16),
              if (isMe) ...[
                _buildBottomSheetItem(context, Icons.edit_outlined, 'Chỉnh sửa bình luận', _startEditing),
                if (isPostOwner)
                  _buildBottomSheetItem(
                    context,
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    isPinned ? 'Bỏ ghim bình luận' : 'Ghim bình luận',
                    () => widget.onPinComment(widget.comment.id, !isPinned),
                  ),
                _buildBottomSheetItem(context, Icons.copy_rounded, 'Sao chép liên kết', _copyCommentLink),
                const Divider(color: Colors.white10),
                _buildBottomSheetItem(context, Icons.delete_outline, 'Xóa bình luận', () => widget.onDeleteComment(widget.comment.id), isDestructive: true),
              ] else ...[
                _buildBottomSheetItem(context, Icons.visibility_off_outlined, 'Ẩn bình luận', () => widget.onHideComment(widget.comment.id)),
                _buildBottomSheetItem(context, Icons.block_outlined, 'Chặn người dùng', () => widget.onBlockUser(widget.comment.userId)),
                _buildBottomSheetItem(context, Icons.report_problem_outlined, 'Báo cáo bình luận', _reportComment),
                _buildBottomSheetItem(context, Icons.copy_rounded, 'Sao chép liên kết', _copyCommentLink),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFF15A36) : Colors.white;
    return ListTile(
      leading: Icon(icon, color: color.withValues(alpha: 0.8)),
      title: Text(
        label,
        style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _reportComment() {
    PremiumToast.show(context, 'Cảm ơn bạn đã báo cáo bình luận này');
  }

  void _copyCommentLink() {
    Clipboard.setData(ClipboardData(text: 'https://todo.app/comment/${widget.comment.id}'));
    PremiumToast.show(context, 'Đã sao chép liên kết bình luận!');
  }

  @override
  Widget build(BuildContext context) {
    final reactions = widget.localCommentReactions?[widget.comment.id] ?? widget.comment.reactions;
    final hasReactions = reactions.isNotEmpty;
    final myReaction = widget.currentUserId != null ? reactions[widget.currentUserId] : null;
    final hasReacted = myReaction != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 22.0),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: widget.comment.authorAvatarUrl.isNotEmpty
                            ? NetworkImage(widget.comment.authorAvatarUrl)
                            : null,
                        backgroundColor: Colors.grey.shade900,
                        child: widget.comment.authorAvatarUrl.isEmpty
                            ? const Icon(Icons.person, size: 16, color: Colors.white54)
                            : null,
                      ),
                    ),
                    if (widget.comment.replies.isNotEmpty)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          margin: const EdgeInsets.only(top: 4),
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1C1F2B),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                widget.comment.authorName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF7C5CFF).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Cấp ${widget.comment.authorLevel}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF7C5CFF),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (widget.comment.userId == widget.postOwnerId) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'Tác giả',
                                                    style: TextStyle(
                                                      color: Color(0xFF00E5FF),
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (widget.comment.isPinned) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF7B125).withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    '📌 Đã ghim',
                                                    style: TextStyle(
                                                      color: Color(0xFFF7B125),
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          if (_isEditing)
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _editController,
                                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                                    autofocus: true,
                                                    decoration: const InputDecoration(
                                                      isDense: true,
                                                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                                                      border: InputBorder.none,
                                                    ),
                                                    onSubmitted: (_) => _submitEdit(),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 18),
                                                  onPressed: _submitEdit,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                                                  onPressed: _cancelEditing,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            )
                                          else
                                            _buildCommentContent(_localContent ?? widget.comment.content, 15),
                                        ],
                                      ),
                                    ),
                                    if (hasReactions)
                                      Positioned(
                                        bottom: -8,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E1E2E),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ...reactions.values.toSet().take(3).map((rType) => Padding(
                                                padding: const EdgeInsets.only(right: 2.0),
                                                child: Text(
                                                  _getReactionEmoji(rType),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _getReactionColor(rType),
                                                  ),
                                                ),
                                              )),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${reactions.length}',
                                                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              CompositedTransformTarget(
                                link: _menuLink,
                                child: Opacity(
                                  opacity: (_isHovered || _isMenuOpen) ? 1.0 : 0.0,
                                  child: _CommentThreeDotButton(
                                    isOpen: _isMenuOpen,
                                    onPressed: () => _showMenu(context),
                                    size: 30.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                _timeAgo(widget.comment.createdAt),
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                              const SizedBox(width: 14),
                              MouseRegion(
                                onEnter: (_) => _showPicker(),
                                onExit: (_) => _hidePickerDelayed(),
                                child: CompositedTransformTarget(
                                  link: _likeLink,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (widget.currentUserId != null) {
                                        if (hasReacted) {
                                          widget.onReactionSelected(widget.comment.id, myReaction);
                                        } else {
                                          widget.onReactionSelected(widget.comment.id, 'like');
                                        }
                                      }
                                    },
                                    child: Text(
                                      hasReacted ? _getReactionLabel(myReaction) : 'Thích',
                                      style: TextStyle(
                                        color: hasReacted ? _getReactionColor(myReaction) : Colors.white54,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (!widget.isCommentsDisabled) ...[
                                const SizedBox(width: 14),
                                GestureDetector(
                                  onTap: () => widget.onReplyPressed(widget.comment.authorName, widget.comment.userId),
                                  child: const Text(
                                    'Trả lời',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                              if (widget.comment.isEdited || _localContent != null) ...[
                                const SizedBox(width: 14),
                                const Text(
                                  'Đã chỉnh sửa',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                      if (_showReactionPicker && widget.currentUserId != null)
                        Positioned(
                          left: 0,
                          bottom: 22,
                          child: MouseRegion(
                            onEnter: (_) => _autoHideTimer?.cancel(),
                            onExit: (_) {
                              _hidePickerDelayed();
                              _startAutoHide();
                            },
                            child: CompositedTransformFollower(
                              link: _likeLink,
                              showWhenUnlinked: false,
                              targetAnchor: Alignment.topCenter,
                              followerAnchor: Alignment.bottomLeft,
                              offset: Offset(MediaQuery.sizeOf(context).width < 600 ? -40.0 : -100.0, -6),
                              child: CommentReactionPicker(
                                onReactionSelected: (type) {
                                  _autoHideTimer?.cancel();
                                  setState(() {
                                    _showReactionPicker = false;
                                  });
                                  widget.onReactionSelected(widget.comment.id, type);
                                },
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
          if (widget.comment.replies.isNotEmpty) ...[
            CustomPaint(
              painter: _TogglerConnectionPainter(
                showReplies: _showReplies,
                lineColor: Colors.white.withValues(alpha: 0.12),
                startX: 16.0,
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 42.0, top: 10.0, bottom: 10.0),
                child: GestureDetector(
                  onTap: _repliesLoading
                      ? null
                      : () async {
                          if (_showReplies) {
                            _repliesController.reverse().then((_) {
                              if (mounted) {
                                setState(() {
                                  _showReplies = false;
                                });
                              }
                            });
                          } else {
                            setState(() {
                              _repliesLoading = true;
                            });
                            await Future.delayed(const Duration(milliseconds: 600));
                            if (mounted) {
                              setState(() {
                                _repliesLoading = false;
                                _showReplies = true;
                              });
                              _repliesController.forward(from: 0.0);
                            }
                          }
                        },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showReplies
                            ? 'Ẩn trả lời'
                            : 'Xem ${widget.comment.replies.length} trả lời',
                        style: TextStyle(
                          color: const Color(0xFF7C5CFF).withValues(alpha: 0.85),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (_repliesLoading) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C5CFF)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (!_showReplies && !_repliesController.isAnimating) const SizedBox(height: 8),
            SizeTransition(
              sizeFactor: _repliesAnimation,
              axis: Axis.vertical,
              axisAlignment: -1.0,
              child: FadeTransition(
                opacity: _repliesAnimation,
                child: (_showReplies || _repliesController.isAnimating)
                    ? Container(
                        margin: const EdgeInsets.only(left: 16, bottom: 12),
                        padding: const EdgeInsets.only(left: 26),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          clipBehavior: Clip.none,
                          itemCount: widget.comment.replies.length,
                          itemBuilder: (context, rIdx) {
                            return ReplyCard(
                              key: ValueKey(widget.comment.replies[rIdx].id),
                              reply: widget.comment.replies[rIdx],
                              currentUserId: widget.currentUserId,
                              postOwnerId: widget.postOwnerId,
                              isCommentsDisabled: widget.isCommentsDisabled,
                              startX: -26.0,
                              isLast: rIdx == widget.comment.replies.length - 1,
                              onReplyPressed: widget.onReplyPressed,
                              onEditComment: widget.onEditComment,
                              onDeleteComment: widget.onDeleteComment,
                              onHideComment: widget.onHideComment,
                              onBlockUser: widget.onBlockUser,
                              onReactionSelected: widget.onReactionSelected,
                              localCommentReactions: widget.localCommentReactions,
                            );
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ReplyCard extends StatefulWidget {
  final ActivityCommentModel reply;
  final String? currentUserId;
  final String postOwnerId;
  final bool isCommentsDisabled;
  final double startX;
  final bool isLast;
  final void Function(String authorName, String authorId) onReplyPressed;
  final void Function(String commentId, String text) onEditComment;
  final void Function(String commentId) onDeleteComment;
  final void Function(String commentId) onHideComment;
  final void Function(String userId) onBlockUser;
  final void Function(String commentId, String type) onReactionSelected;
  final Map<String, Map<String, String>>? localCommentReactions;

  const ReplyCard({
    super.key,
    required this.reply,
    required this.currentUserId,
    required this.postOwnerId,
    required this.isCommentsDisabled,
    required this.startX,
    required this.isLast,
    required this.onReplyPressed,
    required this.onEditComment,
    required this.onDeleteComment,
    required this.onHideComment,
    required this.onBlockUser,
    required this.onReactionSelected,
    this.localCommentReactions,
  });

  @override
  State<ReplyCard> createState() => _ReplyCardState();
}

class _ReplyCardState extends State<ReplyCard> {
  final LayerLink _menuLink = LayerLink();
  final LayerLink _likeLink = LayerLink();
  Timer? _hoverTimer;
  Timer? _autoHideTimer;
  bool _isHovered = false;
  bool _isMenuOpen = false;
  bool _showReactionPicker = false;
  Timer? _reactionCloseTimer;

  bool _isEditing = false;
  late TextEditingController _editController;
  String? _localContent;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: _getCommentText(widget.reply.content));
  }

  @override
  void didUpdateWidget(ReplyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reply.content != oldWidget.reply.content) {
      setState(() {
        _localContent = null;
      });
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _reactionCloseTimer?.cancel();
    _hoverTimer?.cancel();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editController.text = _getCommentText(widget.reply.content);
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  void _submitEdit() {
    final text = _editController.text.trim();
    if (text.isNotEmpty) {
      String finalContent = text;
      try {
        final raw = widget.reply.content;
        if (raw.startsWith('{') && raw.endsWith('}')) {
          final data = jsonDecode(raw);
          if (data is Map && data.containsKey('attachment')) {
            finalContent = jsonEncode({
              'text': text,
              'attachment': data['attachment'],
            });
          }
        }
      } catch (_) {}
      
      if (finalContent != widget.reply.content) {
        setState(() {
          _localContent = finalContent;
        });
        widget.onEditComment(widget.reply.id, finalContent);
      }
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _showPicker() {
    _reactionCloseTimer?.cancel();
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showReactionPicker = true);
        _startAutoHide();
      }
    });
  }

  void _startAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _showReactionPicker = false);
    });
  }

  void _hidePickerDelayed() {
    _hoverTimer?.cancel();
  }

  void _showMenu(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      _showMobileBottomSheet(context);
    } else {
      CommentMenuOverlay.show(
        context: context,
        triggerContext: context,
        layerLink: _menuLink,
        isMe: widget.reply.userId == widget.currentUserId,
        isPostOwner: false,
        isPinned: false,
        onEdit: _startEditing,
        onTogglePin: () {},
        onDelete: () => widget.onDeleteComment(widget.reply.id),
        onHide: () => widget.onHideComment(widget.reply.id),
        onBlock: () => widget.onBlockUser(widget.reply.userId),
        onReport: _reportComment,
        onCopyLink: _copyCommentLink,
        buttonSize: 26.0,
        onClose: () {
          if (mounted) {
            setState(() {
              _isMenuOpen = false;
            });
          }
        },
      );
      setState(() {
        _isMenuOpen = true;
      });
    }
  }

  void _showMobileBottomSheet(BuildContext context) {
    final isMe = widget.reply.userId == widget.currentUserId;

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
              const SizedBox(height: 16),
              if (isMe) ...[
                _buildBottomSheetItem(context, Icons.edit_outlined, 'Chỉnh sửa trả lời', _startEditing),
                _buildBottomSheetItem(context, Icons.copy_rounded, 'Sao chép liên kết', _copyCommentLink),
                const Divider(color: Colors.white10),
                _buildBottomSheetItem(context, Icons.delete_outline, 'Xóa trả lời', () => widget.onDeleteComment(widget.reply.id), isDestructive: true),
              ] else ...[
                _buildBottomSheetItem(context, Icons.visibility_off_outlined, 'Ẩn trả lời', () => widget.onHideComment(widget.reply.id)),
                _buildBottomSheetItem(context, Icons.block_outlined, 'Chặn người dùng', () => widget.onBlockUser(widget.reply.userId)),
                _buildBottomSheetItem(context, Icons.report_problem_outlined, 'Báo cáo trả lời', _reportComment),
                _buildBottomSheetItem(context, Icons.copy_rounded, 'Sao chép liên kết', _copyCommentLink),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFF15A36) : Colors.white;
    return ListTile(
      leading: Icon(icon, color: color.withValues(alpha: 0.8)),
      title: Text(
        label,
        style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _reportComment() {
    PremiumToast.show(context, 'Cảm ơn bạn đã báo cáo trả lời này');
  }

  void _copyCommentLink() {
    Clipboard.setData(ClipboardData(text: 'https://todo.app/comment/${widget.reply.id}'));
    PremiumToast.show(context, 'Đã sao chép liên kết trả lời!');
  }

  @override
  Widget build(BuildContext context) {
    final reactions = widget.localCommentReactions?[widget.reply.id] ?? widget.reply.reactions;
    final hasReactions = reactions.isNotEmpty;
    final myReaction = widget.currentUserId != null ? reactions[widget.currentUserId] : null;
    final hasReacted = myReaction != null;

    return CustomPaint(
      painter: _ReplyConnectionPainter(
        isLast: widget.isLast,
        lineColor: Colors.white.withValues(alpha: 0.12),
        startX: widget.startX,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: CircleAvatar(
                  radius: 12,
                  backgroundImage: widget.reply.authorAvatarUrl.isNotEmpty
                      ? NetworkImage(widget.reply.authorAvatarUrl)
                      : null,
                  backgroundColor: Colors.grey.shade900,
                  child: widget.reply.authorAvatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 12, color: Colors.white54)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C1F2B),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              widget.reply.authorName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF7C5CFF).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Cấp ${widget.reply.authorLevel}',
                                                style: const TextStyle(
                                                  color: Color(0xFF7C5CFF),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (widget.reply.userId == widget.postOwnerId) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Tác giả',
                                                  style: TextStyle(
                                                    color: Color(0xFF00E5FF),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (_isEditing)
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: _editController,
                                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                                  autofocus: true,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                                                    border: InputBorder.none,
                                                  ),
                                                  onSubmitted: (_) => _submitEdit(),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 16),
                                                onPressed: _submitEdit,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
                                                onPressed: _cancelEditing,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          )
                                        else
                                          _buildCommentContent(_localContent ?? widget.reply.content, 13),
                                      ],
                                    ),
                                  ),
                                  if (hasReactions)
                                    Positioned(
                                      bottom: -8,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E1E2E),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ...reactions.values.toSet().take(3).map((rType) => Padding(
                                              padding: const EdgeInsets.only(right: 1.5),
                                              child: Text(
                                                _getReactionEmoji(rType),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: _getReactionColor(rType),
                                                ),
                                              ),
                                            )),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${reactions.length}',
                                              style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            CompositedTransformTarget(
                              link: _menuLink,
                              child: Opacity(
                                opacity: (_isHovered || _isMenuOpen) ? 1.0 : 0.0,
                                child: _CommentThreeDotButton(
                                  isOpen: _isMenuOpen,
                                  onPressed: () => _showMenu(context),
                                  size: 26.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _timeAgo(widget.reply.createdAt),
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                            const SizedBox(width: 12),
                            MouseRegion(
                              onEnter: (_) => _showPicker(),
                              onExit: (_) => _hidePickerDelayed(),
                              child: CompositedTransformTarget(
                                link: _likeLink,
                                child: GestureDetector(
                                  onTap: () {
                                    if (widget.currentUserId != null) {
                                      if (hasReacted) {
                                        widget.onReactionSelected(widget.reply.id, myReaction);
                                      } else {
                                        widget.onReactionSelected(widget.reply.id, 'like');
                                      }
                                    }
                                  },
                                  child: Text(
                                    hasReacted ? _getReactionLabel(myReaction) : 'Thích',
                                    style: TextStyle(
                                      color: hasReacted ? _getReactionColor(myReaction) : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (!widget.isCommentsDisabled) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => widget.onReplyPressed(widget.reply.authorName, widget.reply.userId),
                                child: const Text(
                                  'Trả lời',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            ],
                            if (widget.reply.isEdited || _localContent != null) ...[
                              const SizedBox(width: 12),
                              const Text(
                                'Đã chỉnh sửa',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (_showReactionPicker && widget.currentUserId != null)
                      Positioned(
                        left: 0,
                        bottom: 20,
                        child: MouseRegion(
                          onEnter: (_) => _autoHideTimer?.cancel(),
                          onExit: (_) {
                            _hidePickerDelayed();
                            _startAutoHide();
                          },
                          child: CompositedTransformFollower(
                            link: _likeLink,
                            showWhenUnlinked: false,
                            targetAnchor: Alignment.topCenter,
                            followerAnchor: Alignment.bottomLeft,
                            offset: Offset(MediaQuery.sizeOf(context).width < 600 ? -40.0 : -100.0, -6),
                            child: CommentReactionPicker(
                              onReactionSelected: (type) {
                                _autoHideTimer?.cancel();
                                setState(() {
                                  _showReactionPicker = false;
                                });
                                widget.onReactionSelected(widget.reply.id, type);
                              },
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
    );
  }
}

class CommentSkeleton extends StatefulWidget {
  const CommentSkeleton({super.key});

  @override
  State<CommentSkeleton> createState() => _CommentSkeletonState();
}

class _CommentSkeletonState extends State<CommentSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF1C1F2B),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1F2B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1F2B),
                      borderRadius: BorderRadius.circular(12),
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
}

class CommentReactionPicker extends StatefulWidget {
  final void Function(String type) onReactionSelected;

  const CommentReactionPicker({
    super.key,
    required this.onReactionSelected,
  });

  @override
  State<CommentReactionPicker> createState() => _CommentReactionPickerState();
}

class _CommentReactionPickerState extends State<CommentReactionPicker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactionTypes = ['like', 'love', 'care', 'haha', 'wow', 'sad', 'angry', 'rocket', 'fire', 'clap', 'party'];
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    final itemWidth = isMobile ? 26.0 : 32.0;
    final itemHeight = isMobile ? 48.0 : 56.0;
    final itemFontSize = isMobile ? 18.0 : 22.0;

    final containerHeight = isMobile ? 32.0 : 40.0;
    return ScaleTransition(
      scale: _scaleAnimation,
      alignment: Alignment.bottomCenter,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: containerHeight,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(containerHeight / 2),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: reactionTypes.map((type) {
                return ReactionPickerItem(
                  type: type,
                  emoji: _getReactionEmoji(type),
                  onTap: () => widget.onReactionSelected(type),
                  width: itemWidth,
                  height: itemHeight,
                  fontSize: itemFontSize,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class CommentMenuOverlay extends StatefulWidget {
  final BuildContext triggerContext;
  final LayerLink layerLink;
  final bool isMe;
  final bool isPostOwner;
  final bool isPinned;
  final VoidCallback onEdit;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  final VoidCallback onHide;
  final VoidCallback onBlock;
  final VoidCallback onReport;
  final VoidCallback onCopyLink;
  final VoidCallback onClose;
  final double buttonSize;

  const CommentMenuOverlay({
    super.key,
    required this.triggerContext,
    required this.layerLink,
    required this.isMe,
    required this.isPostOwner,
    required this.isPinned,
    required this.onEdit,
    required this.onTogglePin,
    required this.onDelete,
    required this.onHide,
    required this.onBlock,
    required this.onReport,
    required this.onCopyLink,
    required this.onClose,
    this.buttonSize = 30.0,
  });

  static OverlayEntry? _currentOverlayEntry;
  static VoidCallback? _onCloseCallback;

  static void close() {
    if (_currentOverlayEntry != null) {
      _currentOverlayEntry!.remove();
      _currentOverlayEntry = null;
    }
    if (_onCloseCallback != null) {
      _onCloseCallback!();
      _onCloseCallback = null;
    }
  }

  static void show({
    required BuildContext context,
    required BuildContext triggerContext,
    required LayerLink layerLink,
    required bool isMe,
    required bool isPostOwner,
    required bool isPinned,
    required VoidCallback onEdit,
    required VoidCallback onTogglePin,
    required VoidCallback onDelete,
    required VoidCallback onHide,
    required VoidCallback onBlock,
    required VoidCallback onReport,
    required VoidCallback onCopyLink,
    double buttonSize = 30.0,
    VoidCallback? onClose,
  }) {
    close();

    _onCloseCallback = onClose;

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return CommentMenuOverlay(
          triggerContext: triggerContext,
          layerLink: layerLink,
          isMe: isMe,
          isPostOwner: isPostOwner,
          isPinned: isPinned,
          onEdit: () { close(); onEdit(); },
          onTogglePin: () { close(); onTogglePin(); },
          onDelete: () { close(); onDelete(); },
          onHide: () { close(); onHide(); },
          onBlock: () { close(); onBlock(); },
          onReport: () { close(); onReport(); },
          onCopyLink: () { close(); onCopyLink(); },
          onClose: close,
          buttonSize: buttonSize,
        );
      },
    );

    _currentOverlayEntry = overlayEntry;
    overlayState.insert(overlayEntry);
  }

  @override
  State<CommentMenuOverlay> createState() => _CommentMenuOverlayState();
}

class _CommentMenuOverlayState extends State<CommentMenuOverlay> with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onClose,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.transparent)),
          CompositedTransformFollower(
            link: widget.layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 6),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.topRight,
                child: Material(
                  color: Colors.transparent,
                  child: CustomPaint(
                    painter: _CommentMenuPointer(
                      color: const Color(0xFF1E1B2E),
                      buttonSize: widget.buttonSize,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        width: 210,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF7C5CFF).withValues(alpha: 0.2), width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (widget.isMe) ...[
                                  _buildMenuItem(Icons.edit_outlined, 'Chỉnh sửa', widget.onEdit),
                                  if (widget.isPostOwner)
                                    _buildMenuItem(
                                      widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                      widget.isPinned ? 'Bỏ ghim' : 'Ghim bình luận',
                                      widget.onTogglePin,
                                    ),
                                  _buildMenuItem(Icons.copy_rounded, 'Sao chép liên kết', widget.onCopyLink),
                                  const Divider(
                                    color: Color(0x12FFFFFF), // rgba(255, 255, 255, 0.07)
                                    height: 9,
                                    thickness: 0.5,
                                  ),
                                  _buildMenuItem(Icons.delete_outline, 'Xóa bình luận', widget.onDelete, isDestructive: true),
                                ] else ...[
                                  _buildMenuItem(Icons.visibility_off_outlined, 'Ẩn bình luận', widget.onHide),
                                  _buildMenuItem(Icons.block_outlined, 'Chặn người dùng', widget.onBlock),
                                  _buildMenuItem(Icons.report_problem_outlined, 'Báo cáo', widget.onReport),
                                  _buildMenuItem(Icons.copy_rounded, 'Sao chép liên kết', widget.onCopyLink),
                                ],
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return _CommentMenuItem(
      icon: icon,
      label: label,
      onTap: onTap,
      isDestructive: isDestructive,
    );
  }
}

class _CommentMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _CommentMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_CommentMenuItem> createState() => _CommentMenuItemState();
}

class _CommentMenuItemState extends State<_CommentMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Normal colors
    final Color normalTextColor = widget.isDestructive 
        ? const Color(0xD9EF4444) // rgba(239, 68, 68, 0.85)
        : const Color(0xBFFFFFFF); // rgba(255, 255, 255, 0.75)
    final Color normalIconColor = widget.isDestructive 
        ? const Color(0x99EF4444) // rgba(239, 68, 68, 0.6)
        : const Color(0x66FFFFFF); // rgba(255, 255, 255, 0.4)

    // Hover colors
    final Color hoverTextColor = widget.isDestructive 
        ? const Color(0xFFF87171) 
        : Colors.white;
    final Color hoverIconColor = widget.isDestructive 
        ? const Color(0xFFF87171) 
        : const Color(0xFFA78BFA);
    final Color hoverBgColor = widget.isDestructive 
        ? const Color(0x1AEF4444) // rgba(239, 68, 68, 0.1)
        : const Color(0x1F7C5CFF); // rgba(124, 92, 255, 0.12)

    final Color textColor = _isHovered ? hoverTextColor : normalTextColor;
    final Color iconColor = _isHovered ? hoverIconColor : normalIconColor;
    final Color bgColor = _isHovered ? hoverBgColor : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        splashColor: hoverBgColor.withValues(alpha: 0.2),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Center(
                  child: TweenAnimationBuilder<Color?>(
                    duration: const Duration(milliseconds: 120),
                    tween: ColorTween(begin: normalIconColor, end: iconColor),
                    builder: (context, color, child) {
                      return Icon(
                        widget.icon,
                        size: 16,
                        color: color,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 120),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  child: Text(widget.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentThreeDotButton extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onPressed;
  final double size;

  const _CommentThreeDotButton({
    required this.isOpen,
    required this.onPressed,
    this.size = 30.0,
  });

  @override
  State<_CommentThreeDotButton> createState() => _CommentThreeDotButtonState();
}

class _CommentThreeDotButtonState extends State<_CommentThreeDotButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isOpen
        ? const Color(0x337C5CFF) // rgba(124, 92, 255, 0.2)
        : (_isHovered ? const Color(0x267C5CFF) : Colors.transparent); // rgba(124, 92, 255, 0.15)
        
    final Color iconColor = (widget.isOpen || _isHovered)
        ? const Color(0xFFA78BFA) // #a78bfa
        : const Color(0x59FFFFFF); // rgba(255, 255, 255, 0.35)

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onPressed,
        hoverColor: Colors.transparent,
        splashColor: const Color(0x337C5CFF),
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.more_vert_rounded, // Vertical dots matching test1.html
              color: iconColor,
              size: widget.size * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentMenuPointer extends CustomPainter {
  final Color color;
  final double buttonSize;

  _CommentMenuPointer({
    required this.color,
    this.buttonSize = 30.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const double arrowWidth = 12.0;
    const double arrowHeight = 8.0;

    // Peak of the arrow should align with the center of the button.
    // The right edge of the menu is aligned with the right edge of the button.
    // Button center is at buttonSize / 2 from the right edge.
    // Peak is at startX + arrowWidth / 2.
    // So: size.width - buttonSize / 2 = startX + arrowWidth / 2
    // => startX = size.width - buttonSize / 2 - arrowWidth / 2
    final double startX = size.width - (buttonSize / 2) - (arrowWidth / 2);
    
    path.moveTo(startX, arrowHeight);
    path.lineTo(startX + arrowWidth / 2, 0);
    path.lineTo(startX + arrowWidth, arrowHeight);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CommentMenuPointer oldDelegate) {
    return oldDelegate.color != color || oldDelegate.buttonSize != buttonSize;
  }
}

class _TogglerConnectionPainter extends CustomPainter {
  final bool showReplies;
  final Color lineColor;
  final double startX;

  _TogglerConnectionPainter({
    required this.showReplies,
    required this.lineColor,
    required this.startX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double targetY = size.height / 2;
    final double endX = startX + 18.0;

    if (showReplies) {
      path.moveTo(startX, 0);
      path.lineTo(startX, size.height);
      
      path.moveTo(startX, targetY - 6);
      path.quadraticBezierTo(startX, targetY, startX + 6, targetY);
      path.lineTo(endX, targetY);
    } else {
      path.moveTo(startX, 0);
      path.lineTo(startX, targetY - 6);
      path.quadraticBezierTo(startX, targetY, startX + 6, targetY);
      path.lineTo(endX, targetY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TogglerConnectionPainter oldDelegate) {
    return oldDelegate.showReplies != showReplies ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.startX != startX;
  }
}

String _getCommentText(String rawContent) {
  try {
    if (rawContent.startsWith('{') && rawContent.endsWith('}')) {
      final data = jsonDecode(rawContent);
      if (data is Map && data.containsKey('text')) {
        return data['text'] as String;
      }
    }
  } catch (_) {}
  return rawContent;
}

Widget _buildCommentContent(String rawContent, double fontSize) {
  try {
    if (rawContent.startsWith('{') && rawContent.endsWith('}')) {
      final data = jsonDecode(rawContent);
      if (data is Map && data.containsKey('text')) {
        final text = data['text'] as String;
        final attachment = data['attachment'] as Map?;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text.isNotEmpty)
              Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: fontSize,
                ),
              ),
            if (attachment != null) ...[
              if (text.isNotEmpty) const SizedBox(height: 8),
              _buildAttachmentPreviewWidget(attachment),
            ],
          ],
        );
      }
    }
  } catch (_) {
    // Fallback to plain text
  }
  
  return Text(
    rawContent,
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.9),
      fontSize: fontSize,
    ),
  );
}

Widget _buildAttachmentPreviewWidget(Map attachment) {
  final url = attachment['url'] as String? ?? '';
  final type = attachment['type'] as String? ?? 'file';
  final name = attachment['name'] as String? ?? 'Tập tin';

  if (url.isEmpty) return const SizedBox.shrink();

  if (type == 'image' || type == 'gif' || type == 'sticker') {
    double width = 160;
    double height = 120;
    BoxFit fit = BoxFit.cover;

    if (type == 'sticker') {
      width = 80;
      height = 80;
      fit = BoxFit.contain;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.black.withValues(alpha: 0.2),
        child: CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: Colors.white12,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA78BFA)),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: width,
            height: height,
            color: Colors.white12,
            child: const Icon(Icons.broken_image_rounded, color: Colors.white30),
          ),
        ),
      ),
    );
  } else {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_rounded, color: Colors.blueAccent, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Nhấn để tải về / mở tệp',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Custom Media Picker Overlay & Helpers
// ==========================================

class CommentMediaPickerOverlay {
  static OverlayEntry? _entry;

  static void show({
    required BuildContext context,
    required BuildContext triggerContext,
    required LayerLink emojiLink,
    required LayerLink gifLink,
    required LayerLink stickerLink,
    required String initialTab,
    required ValueChanged<String> onTabChanged,
    required ValueChanged<String> onEmojiSelected,
    required Function(String url, String name) onGifSelected,
    required Function(String url, String name) onStickerSelected,
    required VoidCallback onClose,
  }) {
    close();

    final overlayState = Overlay.of(context);
    
    _entry = OverlayEntry(
      builder: (context) {
        return _CommentMediaPickerOverlayWidget(
          emojiLink: emojiLink,
          gifLink: gifLink,
          stickerLink: stickerLink,
          initialTab: initialTab,
          onTabChanged: onTabChanged,
          onEmojiSelected: (emoji) {
            onEmojiSelected(emoji);
            close();
            onClose();
          },
          onGifSelected: (gifUrl, gifName) {
            onGifSelected(gifUrl, gifName);
            close();
            onClose();
          },
          onStickerSelected: (stickerUrl, stickerName) {
            onStickerSelected(stickerUrl, stickerName);
            close();
            onClose();
          },
          onClose: () {
            close();
            onClose();
          },
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

class _CommentMediaPickerOverlayWidget extends StatefulWidget {
  final LayerLink emojiLink;
  final LayerLink gifLink;
  final LayerLink stickerLink;
  final String initialTab;
  final ValueChanged<String> onTabChanged;
  final ValueChanged<String> onEmojiSelected;
  final Function(String url, String name) onGifSelected;
  final Function(String url, String name) onStickerSelected;
  final VoidCallback onClose;

  const _CommentMediaPickerOverlayWidget({
    required this.emojiLink,
    required this.gifLink,
    required this.stickerLink,
    required this.initialTab,
    required this.onTabChanged,
    required this.onEmojiSelected,
    required this.onGifSelected,
    required this.onStickerSelected,
    required this.onClose,
  });

  @override
  State<_CommentMediaPickerOverlayWidget> createState() => _CommentMediaPickerOverlayWidgetState();
}

class _CommentMediaPickerOverlayWidgetState extends State<_CommentMediaPickerOverlayWidget> {
  late String _activeTab;
  final TextEditingController _searchController = TextEditingController();
  String _selectedEmojiCategory = 'smileys';
  
  bool _isLoading = false;
  List<dynamic> _mediaItems = [];
  String _error = '';
  final Dio _dio = Dio();
  CancelToken? _cancelToken;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cancelToken?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_activeTab == 'emoji') {
      setState(() {});
      return;
    }
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchGiphyData();
    });
  }

  void _performSearch() {
    _searchController.clear();
    if (_activeTab == 'emoji') {
      setState(() {
        _mediaItems = [];
        _isLoading = false;
        _error = '';
      });
    } else {
      _fetchGiphyData();
    }
  }

  Future<void> _fetchGiphyData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    final query = _searchController.text.trim();
    final isSearch = query.isNotEmpty;
    
    String url = '';
    const apiKey = 'sXpGFDGZs0Dv1mmNFvYaGUvYwKX0PWIh';
    
    if (_activeTab == 'gif') {
      url = isSearch
          ? 'https://api.giphy.com/v1/gifs/search?api_key=$apiKey&q=${Uri.encodeComponent(query)}&limit=24&rating=g'
          : 'https://api.giphy.com/v1/gifs/trending?api_key=$apiKey&limit=24&rating=g';
    } else if (_activeTab == 'sticker') {
      url = isSearch
          ? 'https://api.giphy.com/v1/stickers/search?api_key=$apiKey&q=${Uri.encodeComponent(query)}&limit=24&rating=g'
          : 'https://api.giphy.com/v1/stickers/trending?api_key=$apiKey&limit=24&rating=g';
    }

    try {
      final response = await _dio.get(url, cancelToken: _cancelToken);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        if (mounted) {
          setState(() {
            _mediaItems = data;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải dữ liệu';
          _isLoading = false;
        });
      }
    }
  }

  Alignment getTargetAnchor(String tab) {
    if (tab == 'emoji') return Alignment.topLeft;
    if (tab == 'sticker') return Alignment.topRight;
    return Alignment.topCenter;
  }

  Alignment getFollowerAnchor(String tab) {
    if (tab == 'emoji') return Alignment.bottomLeft;
    if (tab == 'sticker') return Alignment.bottomRight;
    return Alignment.bottomCenter;
  }

  Offset getOffset(String tab) {
    if (tab == 'emoji') return const Offset(-12, -8);
    if (tab == 'sticker') return const Offset(12, -8);
    return const Offset(0, -8);
  }

  double getArrowX(String tab) {
    if (tab == 'emoji') return 28.0;
    if (tab == 'sticker') return 292.0;
    return 160.0;
  }

  List<String> _getFilteredEmojis() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return emojiCategories[_selectedEmojiCategory] ?? [];
    }

    final List<String> results = [];
    emojiNames.forEach((emoji, keywords) {
      if (keywords.contains(query)) {
        results.add(emoji);
      }
    });
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final targetAnchor = getTargetAnchor(_activeTab);
    final followerAnchor = getFollowerAnchor(_activeTab);
    final offset = getOffset(_activeTab);
    final arrowX = getArrowX(_activeTab);
    
    final currentLink = _activeTab == 'emoji'
        ? widget.emojiLink
        : (_activeTab == 'gif' ? widget.gifLink : widget.stickerLink);

    return Positioned(
      width: 320,
      height: 400,
      child: CompositedTransformFollower(
        link: currentLink,
        showWhenUnlinked: false,
        targetAnchor: targetAnchor,
        followerAnchor: followerAnchor,
        offset: offset,
        child: TapRegion(
          groupId: 'comment_media_picker',
          onTapOutside: (event) {
            widget.onClose();
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CommentPickerCardPainter(
                    backgroundColor: const Color(0xFF151827),
                    borderColor: const Color(0xFF7C5CFF).withOpacity(0.25),
                    arrowX: arrowX,
                  ),
                ),
              ),
              Positioned(
                left: 1,
                right: 1,
                top: 1,
                bottom: 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        _buildTabBar(),
                        Expanded(
                          child: _activeTab == 'emoji' ? _buildEmojiContent() : _buildMediaContent(),
                        ),
                        if (_activeTab == 'emoji' && _searchController.text.isEmpty)
                          _buildEmojiCategoriesBar(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: _activeTab == 'emoji'
              ? 'Tìm kiếm biểu tượng...'
              : (_activeTab == 'gif' ? 'Tìm kiếm ảnh động GIPHY...' : 'Tìm kiếm nhãn dán GIPHY...'),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.4), size: 16),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.4), size: 16),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTabItem('emoji', 'Biểu cảm', Icons.sentiment_satisfied_alt_rounded),
          _buildTabItem('gif', 'GIF', Icons.gif_box_outlined),
          _buildTabItem('sticker', 'Sticker', Icons.sticky_note_2_outlined),
        ],
      ),
    );
  }

  Widget _buildTabItem(String tab, String label, IconData icon) {
    final isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = tab;
          });
          widget.onTabChanged(tab);
          _performSearch();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF7C5CFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? Colors.white : Colors.white60, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white60,
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiContent() {
    final emojis = _getFilteredEmojis();
    if (emojis.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy biểu tượng phù hợp',
          style: TextStyle(color: Colors.white30, fontSize: 13),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        return _HoverableEmojiItem(
          emoji: emojis[index],
          onTap: widget.onEmojiSelected,
        );
      },
    );
  }

  Widget _buildMediaContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7C5CFF),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Text(
          _error,
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    if (_mediaItems.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy kết quả nào',
          style: TextStyle(color: Colors.white30, fontSize: 13),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      itemCount: _mediaItems.length,
      itemBuilder: (context, index) {
        final item = _mediaItems[index];
        return _HoverableMediaItem(
          item: item,
          onTap: () {
            final images = item['images'] as Map<String, dynamic>?;
            final fixedHeight = images?['fixed_height'] as Map<String, dynamic>?;
            final url = fixedHeight?['url'] as String? ?? '';
            final title = item['title'] as String? ?? 'Giphy';
            if (url.isNotEmpty) {
              if (_activeTab == 'gif') {
                widget.onGifSelected(url, title);
              } else {
                widget.onStickerSelected(url, title);
              }
            }
          },
        );
      },
    );
  }

  Widget _buildEmojiCategoriesBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.04),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEmojiCategoryItem('smileys', Icons.sentiment_satisfied_alt_rounded),
          _buildEmojiCategoryItem('gestures', Icons.front_hand_rounded),
          _buildEmojiCategoryItem('animals', Icons.pets_rounded),
          _buildEmojiCategoryItem('food', Icons.fastfood_rounded),
          _buildEmojiCategoryItem('activities', Icons.sports_soccer_rounded),
          _buildEmojiCategoryItem('travel', Icons.directions_car_rounded),
        ],
      ),
    );
  }

  Widget _buildEmojiCategoryItem(String category, IconData icon) {
    final isActive = _selectedEmojiCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmojiCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF7C5CFF) : Colors.white38,
          size: 18,
        ),
      ),
    );
  }
}

class _HoverableEmojiItem extends StatefulWidget {
  final String emoji;
  final ValueChanged<String> onTap;

  const _HoverableEmojiItem({required this.emoji, required this.onTap});

  @override
  State<_HoverableEmojiItem> createState() => _HoverableEmojiItemState();
}

class _HoverableEmojiItemState extends State<_HoverableEmojiItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.emoji),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}

class _HoverableMediaItem extends StatefulWidget {
  final dynamic item;
  final VoidCallback onTap;

  const _HoverableMediaItem({required this.item, required this.onTap});

  @override
  State<_HoverableMediaItem> createState() => _HoverableMediaItemState();
}

class _HoverableMediaItemState extends State<_HoverableMediaItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final images = widget.item['images'] as Map<String, dynamic>?;
    final fixedHeight = images?['fixed_height'] as Map<String, dynamic>?;
    final url = fixedHeight?['url'] as String? ?? '';
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered ? const Color(0xFF7C5CFF) : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: url.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.white10,
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF7C5CFF),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white24),
                    )
                  : Container(color: Colors.white10),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentPickerCardPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double arrowX;

  _CommentPickerCardPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.arrowX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rectWidth = size.width;
    final rectHeight = size.height - 8;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, rectWidth, rectHeight),
      const Radius.circular(16),
    );

    final path = Path()..addRRect(rrect);

    const arrowWidth = 16.0;
    const arrowHeight = 8.0;

    path.moveTo(arrowX - arrowWidth / 2, rectHeight);
    path.lineTo(arrowX, rectHeight + arrowHeight);
    path.lineTo(arrowX + arrowWidth / 2, rectHeight);
    path.close();

    canvas.drawShadow(path.shift(const Offset(0, 4)), Colors.black.withOpacity(0.3), 12.0, true);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CommentPickerCardPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.arrowX != arrowX;
  }
}

final Map<String, List<String>> emojiCategories = {
  'smileys': [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
    '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
    '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🥸',
    '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️',
    '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡',
    '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓',
  ],
  'gestures': [
    '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏', '✌️', '🤞',
    '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '👍',
    '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝',
    '🙏', '✍️', '💅', '🤳', '💪', '🦾', '👂', '🦻', '👃', '🧠',
  ],
  'animals': [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
    '🦁', '🐮', '🐷', '🐽', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒',
    '🐔', '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇',
    '🐺', '🐗', '🐴', '🦄', '🐝', '🪱', '🐛', '🦋', '🐌', '🐞',
  ],
  'food': [
    '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐',
    '🍈', '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🍆', '🥑',
    '🥦', '🥬', '🥒', '🌶️', '🫑', '🌽', '🥕', '🫒', '🧄', '🧅',
    '🍄', '🥔', '🍠', '🥐', '🥯', '🍞', '🥖', '🥨', '🥞', '🧇',
  ],
  'activities': [
    '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱',
    '🪀', '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🪃', '🥅', '⛳',
    '🪁', '🏹', '🎣', '🤿', '🥊', '🥋', '🎽', '🛹', '🛼', '🛷',
  ],
  'travel': [
    '🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐',
    '🛻', '🚚', '🚛', '🚜', '🛵', '🚲', '🛴', '🛺', '🚂', '🚆',
    '✈️', '🚁', '🚀', '🛸', '⛵', '🛟', '⚓', '🗺️', '🧭', '⛰️',
  ],
};

const Map<String, String> emojiNames = {
  '😀': 'smile cuoi cuoi_tuoi vui',
  '😃': 'smile cuoi cuoi_tuoi vui',
  '😄': 'smile cuoi cuoi_tuoi vui',
  '😁': 'smile cuoi cuoi_tuoi vui',
  '😆': 'smile cuoi cuoi_tuoi vui',
  '😅': 'smile cuoi cuoi_tuoi vui ra_mo_hoi',
  '😂': 'smile cuoi cuoi_ra_nuoc_mat vui',
  '🤣': 'smile cuoi lan_lon vui',
  '😊': 'smile cuoi vui hanh_phuc',
  '😇': 'smile thien_than ngoan ngo_nghinh',
  '🙂': 'smile cuoi_nhe nhin vui',
  '🙃': 'smile cuoi_nguoc nguoc ngu_ngoc',
  '😉': 'smile nhay_mat tinh_nghich',
  '😌': 'smile nhe_nhom thoai_mai',
  '😍': 'love thich yeu tim mat_tim',
  '🥰': 'love thich yeu hanh_phuc om',
  '😘': 'love thich yeu hon thom',
  '😗': 'love hon thom',
  '😙': 'love hon thom',
  '😚': 'love hon thom nham_mat',
  '😋': ' ngon ngon_mieng them le_luoi',
  '😛': ' le_luoi tre_con vui',
  '😝': ' le_luoi nham_mat tre_con vui',
  '😜': ' le_luoi nhay_mat tre_con vui',
  '🤪': ' le_luoi dien khung tinh_nghich',
  '🤨': ' nghi_ngo nghi_ngai hoai_nghi',
  '🧐': ' nghi_ngo kinh_mot_mat kham_pha',
  '🤓': ' nerd mot_sach thong_minh',
  '😎': ' cool ngau dep_trai kinh_ram',
  '🥸': ' cai_trang mat_na gia_mao',
  '🤩': ' star ngoi_sao ngac_nhien vui',
  '🥳': ' party tiec_tung sinh_nhat vui',
  '😏': ' kieu_ngao cuoi_deu khinh_buon',
  '😒': ' khong_vui buon chan_nan',
  '😞': ' buon that_vong bat_luc',
  '😔': ' buon suy_tu tram_tu',
  '😟': ' lo_lang ban_khoan boi_roi',
  '😕': ' boi_roi hoang_mang nghi_ngo',
  '🙁': ' buon hoi_buon',
  '☹️': ' buon rat_buon',
  '😣': ' dau_kho chiu_dung vat_va',
  '😖': ' dau_kho chiu_dung vat_va',
  '😫': ' met_moi kiet_suc nan_long',
  '😩': ' met_moi kiet_suc nan_long',
  '🥺': ' cau_xin nan_ni de_thuong khoc',
  '😢': ' khoc buon roi_le',
  '😭': ' khoc khoc_loc buon_qua',
  '😤': ' gian_du buc_tuc kieu_ngao',
  '😠': ' gian_du buc_tuc',
  '😡': ' gian_du buc_tuc do_mat',
  '🤬': ' chui_the gian_du buc_tuc',
  '🤯': ' no_tung_dau ngac_nhien shock',
  '😳': ' ngac_nhien nguong do_mat',
  '🥵': ' nong buc do_mat mo_hoi',
  '🥶': ' lanh run_ray lanh_gia',
  '😱': ' shock ngac_nhien so_hai',
  '😨': ' so_hai lo_lang',
  '😰': ' so_hai lo_lang mo_hoi',
  '😥': ' nhe_nhom lo_lang mo_hoi',
  '😓': ' met_moi mo_hoi lo_lang',
  '👋': ' hello chao vay_tay',
  '👍': ' like tot dong_y duoc',
  '👎': ' dislike khong_dong_y bad',
  '👏': ' clap vo_tay khen_ngoi',
  '🙏': ' pray cau_nguyen cam_on chao',
  '❤️': ' love tim do yeu_thich',
  '🔥': ' fire lua hot tuyet_voi',
  '🎉': ' party tiec sinh_nhat chuc_mung',
  '🚀': ' rocket ten_lua bay nhanh',
};
