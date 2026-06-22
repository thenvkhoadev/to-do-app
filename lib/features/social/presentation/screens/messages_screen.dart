import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DesktopTopbar(),
        Expanded(
          child: Row(
            children: [
              // Sidebar conversations list (Column 1)
              Container(
                width: 320,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.white.withValues(alpha: .06),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Đoạn chat',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: DashboardColors.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: DashboardColors.primary.withValues(
                                alpha: .12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '✏ Mới',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: DashboardColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: DashboardColors.surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: DashboardColors.outline,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tìm kiếm trên Messenger',
                              style: TextStyle(
                                color: DashboardColors.outline,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: [
                          _ConversationTile(
                            avatarInitials: 'L',
                            name: 'Lan',
                            lastMessage: 'Đã gửi một Task: Fix Dashboard...',
                            time: '2 phút',
                            unread: true,
                            online: true,
                          ),
                          _ConversationTile(
                            avatarInitials: 'M',
                            name: 'Minh',
                            lastMessage: 'Bạn: Ok để mai làm 👍',
                            time: '1 giờ',
                            pinned: true,
                            online: true,
                          ),
                          _ConversationTile(
                            avatarInitials: 'H',
                            name: 'Hùng',
                            lastMessage: 'Đã xem',
                            time: 'Hôm qua',
                            online: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Message content detail placeholder (Column 2)
              Expanded(
                child: Container(
                  color: DashboardColors.surfaceLowest.withValues(alpha: .2),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DashboardColors.primary.withValues(
                              alpha: .08,
                            ),
                          ),
                          child: Icon(
                            Icons.forum_rounded,
                            color: DashboardColors.primary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No Conversation Selected',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: DashboardColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Chọn một hội thoại hoặc bắt đầu trò chuyện mới.',
                          style: TextStyle(
                            color: DashboardColors.outline,
                            fontSize: 13,
                          ),
                        ),
                      ],
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
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.avatarInitials,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unread = false,
    this.pinned = false,
    this.online = false,
  });

  final String avatarInitials;
  final String name;
  final String lastMessage;
  final String time;
  final bool unread;
  final bool pinned;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unread ? Colors.white.withValues(alpha: .03) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: DashboardColors.surfaceHigh,
                  child: Text(
                    avatarInitials,
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
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: DashboardColors.surface,
                          width: 2,
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
                  Row(
                    children: [
                      if (pinned)
                        const Padding(
                          padding: EdgeInsets.only(right: 4.0),
                          child: Icon(
                            Icons.push_pin_rounded,
                            size: 12,
                            color: DashboardColors.outline,
                          ),
                        ),
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight:
                              unread ? FontWeight.bold : FontWeight.w600,
                          color: unread
                              ? DashboardColors.onSurface
                              : DashboardColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                      color: unread
                          ? DashboardColors.onSurface
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
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        unread ? DashboardColors.primary : DashboardColors.outline,
                  ),
                ),
                if (unread) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 7,
                    height: 7,
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
      ),
    );
  }
}
