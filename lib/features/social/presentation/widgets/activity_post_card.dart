import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/theme/design_tokens.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/social/data/models/activity_post_model.dart';
import 'package:to_do_app/features/social/data/models/friendship_model.dart';
import 'package:to_do_app/features/social/presentation/providers/feed_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class ActivityPostCard extends ConsumerStatefulWidget {
  const ActivityPostCard({super.key, required this.post});

  final ActivityPostModel post;

  @override
  ConsumerState<ActivityPostCard> createState() => _ActivityPostCardState();
}

class _ActivityPostCardState extends ConsumerState<ActivityPostCard> {
  bool _showComments = false;
  bool _showReactionPicker = false;
  final TextEditingController _commentController = TextEditingController();

  Map<String, String>? _localReactions;
  Map<String, String>? _localReactorNames;
  Map<String, Map<String, String>>? _localCommentReactions;

  String? _justClickedPostId;
  String? _justClickedCommentId;

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
    _localCommentReactions = {
      for (final comment in widget.post.comments)
        comment.id: Map<String, String>.from(comment.reactions)
    };
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
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;

    try {
      final feedService = ref.read(feedServiceProvider);
      await feedService.addComment(widget.post.id, currentUser.id, text);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi bình luận: $e')),
        );
      }
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
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
              );
            }).toList(),
          ),
        ),
      ],
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã gửi yêu cầu kết bạn!')),
          );
        }
      } else if (status == FriendshipStatus.pendingReceived) {
        await socialDs.acceptFriendRequest(currentUser.id, widget.post.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đồng ý kết bạn!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết bạn: $e')),
        );
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
        child: Column(
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
              if (!isMe) _buildFriendshipButton(friendshipStatus),
            ],
          ),
          const SizedBox(height: 14),

          // Post Text Content
          if (widget.post.content.isNotEmpty) ...[
            Text(
              widget.post.content,
              style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.5),
            ),
            const SizedBox(height: 12),
          ],

          // Post Attachments (Photo, Task, Achievement, Poll)
          _buildPostAttachment(currentUser?.id),

          const SizedBox(height: 12),
          const Divider(color: DesignTokens.borderSubtle, height: 1),
          const SizedBox(height: 8),

          // Likes / Comments Count Info, Divider, and Actions Row in a Stack to support floating reactions overlay
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Main child defining stack bounds
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
                          final sharesCount = widget.post.metaData?['sharesCount'] as int? ?? 0;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.post.comments.isNotEmpty)
                                Text(
                                  '${widget.post.comments.length} bình luận',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12.5,
                                    fontFamily: 'Segoe UI',
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
                  const SizedBox(height: 6),

                  // Like / Comment / Share Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Like Button with custom reaction layout
                      MouseRegion(
                        onEnter: (event) {
                          if (event.kind == PointerDeviceKind.touch) return;
                          // if (currentUser != null && _justClickedPostId != widget.post.id) {
                          //   setState(() {
                          //     _showReactionPicker = true;
                          //   });
                          // }
                          if (currentUser != null) {
                            setState(() {
                              _showReactionPicker = true;
                            });
                          }
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
                                }
                              },
                            );
                          }
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.mode_comment_outlined,
                        label: 'Bình luận',
                        color: const Color(0xFFE4E6EB),
                        onTap: _toggleComments,
                      ),
                      _buildActionButton(
                        icon: Icons.send_outlined,
                        label: 'Gửi',
                        color: const Color(0xFFE4E6EB),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã sao chép liên kết bài viết!')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // Absolute overlay of Reaction Picker (floats above, does not shift layout)
              if (_showReactionPicker && currentUser != null)
                Positioned(
                  left: 12,
                  bottom: 46, // Sits above the action buttons row, overlaying the likes count and divider
                  child: TapRegion(
                    onTapOutside: (event) {
                      setState(() {
                        _showReactionPicker = false;
                      });
                    },
                    child: _buildReactionPicker(currentUser.id),
                  ),
                ),
            ],
          ),
          // Expandable Comments Section
          if (_showComments) _buildCommentsSection(currentUser?.id),
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

  Widget _buildPostAttachment(String? currentUserId) {
    if (widget.post.type == 'photo' && widget.post.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.post.mediaUrl!,
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

    if (widget.post.type == 'task') {
      final taskTitle = widget.post.metaData?['taskTitle'] as String? ?? 'Công việc';
      final taskStatus = widget.post.metaData?['taskStatus'] as String? ?? 'todo';
      final taskPriority = widget.post.metaData?['taskPriority'] as String? ?? 'medium';

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

    if (widget.post.type == 'achievement') {
      final title = widget.post.metaData?['achievementTitle'] as String? ?? 'Danh hiệu';
      final desc = widget.post.metaData?['achievementDesc'] as String? ?? '';

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

    if (widget.post.type == 'poll') {
      final options = List<String>.from(widget.post.metaData?['pollOptions'] ?? []);
      final votes = Map<String, String>.from(widget.post.metaData?['votes'] ?? {});
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
                    await ref.read(feedServiceProvider).voteOnPoll(widget.post.id, currentUserId, opt);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Divider(color: DesignTokens.borderSubtle, height: 1),
        const SizedBox(height: 12),
        // Comment List
        if (widget.post.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Chưa có bình luận nào. Hãy bắt đầu cuộc trò chuyện!',
              style: TextStyle(color: Colors.white38, fontSize: 12.5),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: widget.post.comments.length,
            itemBuilder: (context, index) {
              final comment = widget.post.comments[index];
              final reactions = _localCommentReactions?[comment.id] ?? comment.reactions;
              final hasReactions = reactions.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: MouseRegion(
                  onExit: (_) {
                    if (_activeCommentReactionPickerId == comment.id) {
                      setState(() {
                        _activeCommentReactionPickerId = null;
                      });
                    }
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Main layout Column defining Stack bounds
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: comment.authorAvatarUrl.isNotEmpty
                                    ? NetworkImage(comment.authorAvatarUrl)
                                    : null,
                                backgroundColor: Colors.grey.shade900,
                                child: comment.authorAvatarUrl.isEmpty
                                    ? const Icon(Icons.person, size: 14, color: Colors.white54)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: .03),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comment.authorName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment.content,
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (hasReactions)
                                      Positioned(
                                        bottom: -6,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E1E2E),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: reactions.values.toSet().take(3).map((rType) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(right: 1.0),
                                                    child: Text(
                                                      _getReactionEmoji(rType),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: _getReactionColor(rType),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${reactions.length}',
                                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const SizedBox(width: 38), // Align with comment card
                              Text(
                                _timeAgo(comment.createdAt),
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                              const SizedBox(width: 14),
                              MouseRegion(
                                onEnter: (event) {
                                  if (event.kind == PointerDeviceKind.touch) return;
                                  // if (currentUserId != null && _justClickedCommentId != comment.id) {
                                  //   setState(() {
                                  //     _activeCommentReactionPickerId = comment.id;
                                  //   });
                                  // }
                                  if (currentUserId != null) {
                                    setState(() {
                                      _activeCommentReactionPickerId = comment.id;
                                    });
                                  }
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    if (currentUserId != null) {
                                      setState(() {
                                        _activeCommentReactionPickerId = null;
                                      });
                                      final myReaction = reactions[currentUserId];
                                      if (myReaction != null) {
                                        _submitCommentReaction(comment.id, currentUserId, myReaction);
                                      } else {
                                        _submitCommentReaction(comment.id, currentUserId, 'like');
                                      }
                                    }
                                  },
                                  onLongPress: () {
                                    if (currentUserId != null) {
                                      setState(() {
                                        _activeCommentReactionPickerId =
                                            _activeCommentReactionPickerId == comment.id ? null : comment.id;
                                      });
                                    }
                                  },
                                  child: Builder(
                                    builder: (context) {
                                      final myReaction = currentUserId != null ? reactions[currentUserId] : null;
                                      final hasReacted = myReaction != null;
                                      final text = hasReacted ? _getReactionLabel(myReaction) : 'Thích';
                                      final textColor = hasReacted ? _getReactionColor(myReaction) : Colors.white54;
                                      return Text(
                                        text,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              MouseRegion(
                                onEnter: (event) {
                                  if (event.kind == PointerDeviceKind.touch) return;
                                  if (currentUserId != null && _justClickedCommentId != comment.id) {
                                    setState(() {
                                      _activeCommentReactionPickerId = comment.id;
                                    });
                                  }
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    if (currentUserId != null) {
                                      setState(() {
                                        _activeCommentReactionPickerId =
                                            _activeCommentReactionPickerId == comment.id ? null : comment.id;
                                      });
                                    }
                                  },
                                  child: const Icon(
                                    Icons.emoji_emotions_outlined,
                                    size: 14,
                                    color: Colors.white38,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Floating Reaction Picker Overlay (floats above, does not shift layout)
                      if (_activeCommentReactionPickerId == comment.id && currentUserId != null)
                        Positioned(
                          left: 48,
                          bottom: 20, // Positions it directly above the action row, overlaying the comment bubble
                          child: TapRegion(
                            onTapOutside: (event) {
                              setState(() {
                                _activeCommentReactionPickerId = null;
                              });
                            },
                            child: _buildCommentReactionPicker(comment.id, currentUserId),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        // Comment Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Viết bình luận...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: .4)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .04),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFFA78BFA)),
              onPressed: _submitComment,
            ),
          ],
        ),
      ],
    );
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
}

class ReactionPickerItem extends StatefulWidget {
  final String type;
  final String emoji;
  final VoidCallback onTap;

  const ReactionPickerItem({
    super.key,
    required this.type,
    required this.emoji,
    required this.onTap,
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
          width: 48,
          height: 82,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                transform: Matrix4.translationValues(0.0, _isHovered ? -12.0 : 0.0, 0.0)
                  ..multiply(Matrix4.diagonal3Values(_isHovered ? 1.5 : 1.0, _isHovered ? 1.5 : 1.0, 1.0)),
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
                top: -14,
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
        fontSize: 34,
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
