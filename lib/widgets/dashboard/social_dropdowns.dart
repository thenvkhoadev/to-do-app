import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class FriendRequestsDropdown extends ConsumerStatefulWidget {
  const FriendRequestsDropdown({
    required this.onClose,
    required this.onViewAll,
    required this.width,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onViewAll;
  final double width;

  @override
  ConsumerState<FriendRequestsDropdown> createState() => _FriendRequestsDropdownState();
}

class _FriendRequestsDropdownState extends ConsumerState<FriendRequestsDropdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  final Map<String, bool> _localLoading = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _animateClose() async {
    await _animationController.reverse();
    widget.onClose();
  }

  Future<void> _handleAction(
    String currentUserId,
    String otherUserId,
    String action,
  ) async {
    setState(() => _localLoading[otherUserId] = true);
    try {
      final ds = ref.read(socialRemoteDataSourceProvider);
      switch (action) {
        case 'accept':
          await ds.acceptFriendRequest(currentUserId, otherUserId);
          break;
        case 'reject':
          await ds.deleteFriendship(currentUserId, otherUserId);
          break;
      }
      ref.invalidate(friendshipsStreamProvider);
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _localLoading[otherUserId] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingRequestsProvider);
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final items = pending.received.take(3).toList();

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: widget.width,
                decoration: BoxDecoration(
                  color: const Color(0xff0F172A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lời mời kết bạn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          if (pending.received.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: DashboardColors.primary.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${pending.received.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: DashboardColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'Không có lời mời kết bạn nào.',
                            style: TextStyle(
                              color: DashboardColors.outline,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: Colors.white10,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final req = items[index];
                            final u = req.otherUser;
                            final isLoading = _localLoading[u.id] ?? false;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: DashboardColors.surfaceHigh,
                                    backgroundImage: u.avatarUrl != null &&
                                            u.avatarUrl!.isNotEmpty
                                        ? NetworkImage(u.avatarUrl!)
                                        : null,
                                    child: u.avatarUrl == null ||
                                            u.avatarUrl!.isEmpty
                                        ? Text(
                                            u.fullName?.isNotEmpty == true
                                                ? u.fullName!.characters.first
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u.fullName ?? 'User',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Lv.${u.level} · ${u.rankTitle}',
                                          style: TextStyle(
                                            color: DashboardColors.primary
                                                .withValues(alpha: .85),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isLoading)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: DashboardColors.primary,
                                      ),
                                    )
                                  else if (currentUser != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GradientButton(
                                          label: 'Đồng ý',
                                          onPressed: () => _handleAction(
                                            currentUser.id,
                                            u.id,
                                            'accept',
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.white12,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                          ),
                                          onPressed: () => _handleAction(
                                            currentUser.id,
                                            u.id,
                                            'reject',
                                          ),
                                          child: const Text(
                                            'Xoá',
                                            style: TextStyle(
                                              color: DashboardColors.outline,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const Divider(color: Colors.white10, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextButton(
                        onPressed: () {
                          _animateClose();
                          widget.onViewAll();
                        },
                        child: const Text(
                          'Xem tất cả',
                          style: TextStyle(
                            color: DashboardColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
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

class MessagesDropdown extends StatefulWidget {
  const MessagesDropdown({
    required this.onClose,
    required this.onViewAll,
    required this.width,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onViewAll;
  final double width;

  @override
  State<MessagesDropdown> createState() => _MessagesDropdownState();
}

class _MessagesDropdownState extends State<MessagesDropdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _animateClose() async {
    await _animationController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    // Mock conversations from messages_screen.dart
    final mockChats = [
      {
        'initials': 'L',
        'name': 'Lan',
        'message': 'Đã gửi một Task: Fix Dashboard...',
        'time': '2 phút',
        'unread': true,
        'online': true,
      },
      {
        'initials': 'M',
        'name': 'Minh',
        'message': 'Bạn: Ok để mai làm 👍',
        'time': '1 giờ',
        'unread': false,
        'online': true,
      },
      {
        'initials': 'H',
        'name': 'Hùng',
        'message': 'Đã xem',
        'time': 'Hôm qua',
        'unread': false,
        'online': false,
      },
    ];

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: widget.width,
                decoration: BoxDecoration(
                  color: const Color(0xff0F172A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text(
                        'Đoạn chat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: mockChats.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: Colors.white10,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final chat = mockChats[index];
                        final unread = chat['unread'] as bool;
                        final online = chat['online'] as bool;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: DashboardColors.surfaceHigh,
                                    child: Text(
                                      chat['initials'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (online)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22C55E),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xff0F172A),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chat['name'] as String,
                                      style: TextStyle(
                                        fontWeight: unread
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: unread
                                            ? Colors.white
                                            : DashboardColors.onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      chat['message'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: unread
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: unread
                                            ? Colors.white
                                            : DashboardColors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    chat['time'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: unread
                                          ? DashboardColors.primary
                                          : DashboardColors.outline,
                                    ),
                                  ),
                                  if (unread) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: DashboardColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextButton(
                        onPressed: () {
                          _animateClose();
                          widget.onViewAll();
                        },
                        child: const Text(
                          'Mở Messages',
                          style: TextStyle(
                            color: DashboardColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
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
