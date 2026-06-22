import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class FeedRightSidebar extends ConsumerStatefulWidget {
  const FeedRightSidebar({super.key});

  @override
  ConsumerState<FeedRightSidebar> createState() => _FeedRightSidebarState();
}

class _FeedRightSidebarState extends ConsumerState<FeedRightSidebar> {
  bool _mockAccepted = false;
  bool _mockDeleted = false;

  Future<void> _sendRequest(BuildContext context, String currentUserId, String otherUserId) async {
    final socialDs = ref.read(socialRemoteDataSourceProvider);
    try {
      await socialDs.sendFriendRequest(currentUserId, otherUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi yêu cầu kết bạn!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gửi yêu cầu thất bại: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest(BuildContext context, String currentUserId, String otherUserId) async {
    final socialDs = ref.read(socialRemoteDataSourceProvider);
    try {
      await socialDs.acceptFriendRequest(currentUserId, otherUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chấp nhận lời mời kết bạn!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _deleteRequest(BuildContext context, String currentUserId, String otherUserId) async {
    final socialDs = ref.read(socialRemoteDataSourceProvider);
    try {
      await socialDs.deleteFriendship(currentUserId, otherUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã từ chối lời mời kết bạn!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final suggested = ref.watch(suggestedFriendsProvider);
    final allUsersAsync = ref.watch(allUsersProvider);
    final pendingRequests = ref.watch(pendingRequestsProvider);
    final friends = ref.watch(friendsListProvider);

    final receivedRequests = pendingRequests.received;

    return Container(
      width: 360,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Friend Requests Section
            if (receivedRequests.isNotEmpty || (!_mockAccepted && !_mockDeleted)) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lời mời kết bạn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Xem tất cả',
                            style: TextStyle(
                              color: Color(0xFF0866FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (receivedRequests.isNotEmpty)
                      ...receivedRequests.map((request) {
                        final sender = request.otherUser;
                        return _buildRequestRow(
                          name: sender.fullName ?? sender.username ?? 'Người dùng',
                          avatarUrl: sender.avatarUrl,
                          subtitle: sender.coreTech.isNotEmpty
                              ? sender.coreTech.join(', ')
                              : 'Muốn kết nối với bạn',
                          onAccept: () {
                            if (currentUser != null) {
                              _acceptRequest(context, currentUser.id, sender.id);
                            }
                          },
                          onDelete: () {
                            if (currentUser != null) {
                              _deleteRequest(context, currentUser.id, sender.id);
                            }
                          },
                        );
                      })
                    else if (!_mockAccepted && !_mockDeleted)
                      _buildRequestRow(
                        name: 'Hùng Cityzens',
                        avatarUrl: null,
                        subtitle: '8 bạn chung',
                        onAccept: () {
                          setState(() {
                            _mockAccepted = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã chấp nhận lời mời kết bạn từ Hùng Cityzens!')),
                          );
                        },
                        onDelete: () {
                          setState(() {
                            _mockDeleted = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xóa lời mời kết bạn từ Hùng Cityzens!')),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2. Birthdays Section
            _buildBirthdaySection(),
            const SizedBox(height: 16),

            // 3. Contacts Section (Người liên hệ)
            _buildContactsSection(friends),
            const SizedBox(height: 16),

            // 4. Suggestions Card (Gợi ý kết bạn)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gợi ý kết bạn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (suggested.isEmpty)
                    const Text(
                      'Không có gợi ý mới',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    )
                  else
                    ...suggested.take(3).map((user) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              backgroundColor: Colors.grey.shade900,
                              child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                  ? const Icon(Icons.person, size: 24, color: Colors.white54)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName ?? user.username ?? 'Người dùng',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (user.coreTech.isNotEmpty)
                                    Text(
                                      user.coreTech.join(', '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: .4),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (currentUser != null)
                              ElevatedButton(
                                onPressed: () => _sendRequest(context, currentUser.id, user.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C5CFF),
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'Kết bạn',
                                  style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Top Contributors Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Contributors',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  allUsersAsync.when(
                    data: (users) {
                      final sortedUsers = List<UserProfileModel>.from(users);
                      sortedUsers.sort((a, b) => b.level.compareTo(a.level));

                      final topContributors = sortedUsers.take(3).toList();
                      if (topContributors.isEmpty) {
                        return const Text('Chưa có đóng góp', style: TextStyle(color: Colors.white38));
                      }

                      return Column(
                        children: List.generate(topContributors.length, (index) {
                          final user = topContributors[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == 0
                                        ? const Color(0xFFF59E0B)
                                        : index == 1
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFFB45309),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                      ? NetworkImage(user.avatarUrl!)
                                      : null,
                                  backgroundColor: Colors.grey.shade900,
                                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                      ? const Icon(Icons.person, size: 22, color: Colors.white54)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    user.fullName ?? user.username ?? 'Người dùng',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Lv.${user.level}',
                                  style: const TextStyle(
                                    color: Color(0xFFA78BFA),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.white24)),
                    error: (_, __) => const Text('Lỗi tải bảng xếp hạng', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestRow({
    required String name,
    required String? avatarUrl,
    required String subtitle,
    required VoidCallback onAccept,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            backgroundColor: Colors.grey.shade900,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white54, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(
                      '1 tuần',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0866FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size.zero,
                          elevation: 0,
                        ),
                        child: const Text(
                          'Xác nhận',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .08),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size.zero,
                          elevation: 0,
                        ),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
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
    );
  }

  Widget _buildBirthdaySection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sinh nhật',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: .15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cake_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15.5,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: 'Hôm nay là sinh nhật của '),
                        TextSpan(
                          text: 'Thế Vy',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' và '),
                        TextSpan(
                          text: '4 người khác',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactsSection(List<UserProfileModel> friends) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Người liên hệ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, size: 15, color: Colors.white54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                    splashRadius: 16,
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, size: 15, color: Colors.white54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                    splashRadius: 16,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Meta AI item
          _buildContactRow(
            name: 'Meta AI',
            avatarUrl: null,
            isOnline: true,
            isMetaAI: true,
          ),
          if (friends.isNotEmpty)
            ...friends.map((friend) => _buildContactRow(
                  name: friend.fullName ?? friend.username ?? 'Người dùng',
                  avatarUrl: friend.avatarUrl,
                  isOnline: true,
                ))
          else ...[
            _buildContactRow(name: 'Võ Hằng', avatarUrl: null, isOnline: true),
            _buildContactRow(name: 'Trọng Ninh', avatarUrl: null, isOnline: true),
            _buildContactRow(name: 'Oanh Pham', avatarUrl: null, isOnline: true),
            _buildContactRow(name: 'Yến Nhi', avatarUrl: null, isOnline: true, statusText: '14 phút'),
            _buildContactRow(name: 'Đức Giang', avatarUrl: null, isOnline: true),
            _buildContactRow(name: 'Chau Cosme', avatarUrl: null, isOnline: true),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required String name,
    required String? avatarUrl,
    required bool isOnline,
    bool isMetaAI = false,
    String? statusText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                backgroundColor: isMetaAI ? const Color(0xFF7C5CFF).withValues(alpha: .2) : Colors.grey.shade900,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Icon(
                        isMetaAI ? Icons.auto_awesome_rounded : Icons.person,
                        size: 20,
                        color: isMetaAI ? const Color(0xFFA78BFA) : Colors.white54,
                      )
                    : null,
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF13131C),
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isMetaAI) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0866FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (statusText != null)
            Text(
              statusText,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
