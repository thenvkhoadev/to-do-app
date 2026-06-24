import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/social/data/models/activity_post_model.dart';
import 'package:to_do_app/features/social/presentation/providers/feed_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/theme/design_tokens.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';

class ShareDialog extends ConsumerStatefulWidget {
  const ShareDialog({super.key, required this.post});

  final ActivityPostModel post;

  @override
  ConsumerState<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends ConsumerState<ShareDialog> {
  final TextEditingController _commentaryController = TextEditingController();
  bool _isSharing = false;
  final Set<String> _sentFriends = {}; // Keep track of friends we mock-sent the message to

  @override
  void dispose() {
    _commentaryController.dispose();
    super.dispose();
  }

  Future<void> _shareNow() async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;

    setState(() => _isSharing = true);

    try {
      final feedService = ref.read(feedServiceProvider);
      await feedService.sharePost(
        userId: currentUser.id,
        originalPostId: widget.post.id,
        content: _commentaryController.text.trim(),
      );

      // Invalidate feed provider to update UI instantly
      ref.invalidate(feedPostsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chia sẻ bài viết lên bảng feed thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chia sẻ bài viết: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _copyPostLink() {
    // Generate a mock post link or just use a standard one
    final mockLink = 'https://todoapp.social/posts/${widget.post.id}';
    Clipboard.setData(ClipboardData(text: mockLink));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép liên kết bài viết!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 65,
              height: 32,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final currentUserProfile = ref.watch(userProfileProvider).valueOrNull;
    final displayName = currentUserProfile?.fullName ?? currentUserProfile?.username ?? currentUser?.fullName ?? currentUser?.username ?? 'Người dùng';
    final avatarUrl = currentUserProfile?.avatarUrl ?? currentUser?.avatarUrl;
    final friends = ref.watch(friendsListProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1E212E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: .08)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    const Text(
                      'Chia sẻ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .08),
                        padding: const EdgeInsets.all(6),
                        minimumSize: Size.zero,
                      ),
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: DesignTokens.borderSubtle, height: 1),

              // Profile Row
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      backgroundColor: Colors.grey.shade900,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? const Icon(Icons.person, color: Colors.white54)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Bảng feed',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.public, color: Colors.white70, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Công khai',
                                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down, color: Colors.white70, size: 14),
                                  ],
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

              // Commentary Input Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _commentaryController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Hãy nói gì đó về nội dung này...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
              ),

              // Emoji and Share Button Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.sentiment_satisfied_alt_outlined, color: Colors.white54, size: 24),
                      onPressed: () {
                        // Smiley face helper
                        _commentaryController.text += '😊';
                      },
                    ),
                    ElevatedButton(
                      onPressed: _isSharing ? null : _shareNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2), // Facebook Blue
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isSharing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Chia sẻ ngay',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ],
                ),
              ),
              const Divider(color: DesignTokens.borderSubtle, height: 1),

              // Horizontal list: Gửi bằng Messenger
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Gửi bằng Messenger',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Icon(Icons.messenger_outline, color: Colors.white.withValues(alpha: .3), size: 16),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (friends.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Không tìm thấy bạn bè trực tuyến',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                      )
                    else
                      SizedBox(
                        height: 95,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friend = friends[index];
                            final isSent = _sentFriends.contains(friend.id);

                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (isSent) return;
                                      setState(() {
                                        _sentFriends.add(friend.id);
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đã gửi bài viết cho ${friend.fullName}!'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundImage: (friend.avatarUrl?.isNotEmpty == true)
                                              ? NetworkImage(friend.avatarUrl!)
                                              : null,
                                          backgroundColor: Colors.grey.shade900,
                                          child: (friend.avatarUrl?.isEmpty != false)
                                              ? const Icon(Icons.person, color: Colors.white54)
                                              : null,
                                        ),
                                        // Active status dot
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: const Color(0xFF1E212E), width: 2),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      isSent ? 'Đã gửi' : (friend.fullName ?? ''),
                                      style: TextStyle(
                                        color: isSent ? Colors.green : Colors.white70,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
              const Divider(color: DesignTokens.borderSubtle, height: 1),

              // Section: Chia sẻ lên
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Chia sẻ lên',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShareOption(
                            icon: Icons.chat_bubble_outline,
                            label: 'Messenger',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đang mở Messenger...')),
                              );
                            },
                          ),
                          _buildShareOption(
                            icon: Icons.call,
                            label: 'WhatsApp',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đang mở WhatsApp...')),
                              );
                            },
                          ),
                          _buildShareOption(
                            icon: Icons.chrome_reader_mode_outlined,
                            label: 'Tin của bạn',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã chia sẻ lên Tin của bạn!')),
                              );
                            },
                          ),
                          _buildShareOption(
                            icon: Icons.link,
                            label: 'Sao chép liên kết',
                            onTap: _copyPostLink,
                          ),
                          _buildShareOption(
                            icon: Icons.group_outlined,
                            label: 'Nhóm',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đang hiển thị danh sách nhóm...')),
                              );
                            },
                          ),
                          _buildShareOption(
                            icon: Icons.people_outline,
                            label: 'Trang cá nhân',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đang hiển thị danh sách bạn bè...')),
                              );
                            },
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
    );
  }
}
