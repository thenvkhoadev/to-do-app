import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_state.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_sidebar.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_chat_window.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_info_panel.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_dialogs.dart';

// Provider for Messenger left navigation rail selection
final messengerRailTabProvider = StateProvider<String>((ref) => 'chats');

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    final leftWidth = ref.watch(leftSidebarWidthProvider);
    final rightWidth = ref.watch(rightSidebarWidthProvider);
    final rightVisible = ref.watch(isRightSidebarVisibleProvider);
    final activeId = ref.watch(activeThreadIdProvider);
    final isCallActive = ref.watch(isCallActiveProvider);
    final isCallMinimized = ref.watch(isCallMinimizedProvider);
    final showCallFullscreen = isCallActive && !isCallMinimized;
    final videoViewer = ref.watch(activeVideoViewerProvider);
    final selectedRailTab = ref.watch(messengerRailTabProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          ref.read(isSearchFocusedProvider.notifier).state = true;
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          showDialog(
            context: context,
            builder: (_) => const CreateChatDialog(),
          );
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).maybePop();
        },
      },
      child: Focus(
        autofocus: true,
        child: Container(
          color: const Color(0xFF0F0F0F), // Dark base color matching Messenger Desktop
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pane 0: Messenger Leftmost Rail Navigation
                  if (!showCallFullscreen) ...[
                    _buildLeftNavigationRail(context, ref, selectedRailTab),
                    Container(width: 1, color: const Color(0xFF242526)),
                  ],

                  // Pane 1: Conversations Sidebar / Calls List / People List / Stories List
                  if (!showCallFullscreen) ...[
                    SizedBox(
                      width: leftWidth,
                      child: _buildSidebarContent(selectedRailTab),
                    ),
                    
                    // Left Resize Handle
                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        final newWidth = (leftWidth + details.delta.dx).clamp(280.0, 420.0);
                        ref.read(leftSidebarWidthProvider.notifier).state = newWidth;
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeLeftRight,
                        child: Container(
                          width: 4,
                          color: const Color(0xFF242526),
                        ),
                      ),
                    ),
                  ],

                  // Pane 2: Center Chat / Call View / People Details / Story Viewer
                  Expanded(
                    child: _buildCenterContent(selectedRailTab),
                  ),

                  // Pane 3: Right Info Panel (hidden if call fullscreen or not chats)
                  if (!showCallFullscreen && activeId != null && rightVisible && selectedRailTab == 'chats') ...[
                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        final newWidth = (rightWidth - details.delta.dx).clamp(280.0, 360.0);
                        ref.read(rightSidebarWidthProvider.notifier).state = newWidth;
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeLeftRight,
                        child: Container(
                          width: 4,
                          color: const Color(0xFF242526),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: rightWidth,
                      child: const MessageInfoPanel(),
                    ),
                  ],
                ],
              ),
              if (videoViewer != null)
                Positioned.fill(
                  child: ChatVideoViewer(viewerState: videoViewer),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Re-build Leftmost Navigation Rail
  Widget _buildLeftNavigationRail(BuildContext context, WidgetRef ref, String selectedTab) {
    return Container(
      width: 68,
      color: const Color(0xFF121212),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Navigation Icons (Top section)
          _buildRailItem(
            ref: ref,
            tabId: 'chats',
            icon: Icons.chat_bubble_rounded,
            tooltip: 'Đoạn chat',
            isActive: selectedTab == 'chats',
          ),
          const SizedBox(height: 8),
          _buildRailItem(
            ref: ref,
            tabId: 'calls',
            icon: Icons.phone_rounded,
            tooltip: 'Cuộc gọi',
            isActive: selectedTab == 'calls',
          ),
          const SizedBox(height: 8),
          _buildRailItem(
            ref: ref,
            tabId: 'people',
            icon: Icons.people_alt_rounded,
            tooltip: 'Mọi người',
            isActive: selectedTab == 'people',
          ),
          const SizedBox(height: 8),
          _buildRailItem(
            ref: ref,
            tabId: 'stories',
            icon: Icons.donut_large_rounded, // Looks like Facebook Stories ring
            tooltip: 'Tin',
            isActive: selectedTab == 'stories',
          ),
          
          const Spacer(),
          
          // Bottom Navigation Icons
          _buildRailItem(
            ref: ref,
            tabId: 'archive',
            icon: Icons.archive_rounded,
            tooltip: 'Kho lưu trữ',
            isActive: selectedTab == 'archive',
          ),
          const SizedBox(height: 8),
          _buildRailItem(
            ref: ref,
            tabId: 'settings',
            icon: Icons.settings_rounded,
            tooltip: 'Cài đặt',
            isActive: selectedTab == 'settings',
            onTapOverride: () {
              showDialog(
                context: context,
                builder: (_) => const MoreSettingsDialog(),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // User profile Avatar at the very bottom
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const MoreSettingsDialog(),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF31A24C), // Green online indicator
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF121212), width: 1.5),
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

  // Individual Navigation Rail Item
  Widget _buildRailItem({
    required WidgetRef ref,
    required String tabId,
    required IconData icon,
    required String tooltip,
    required bool isActive,
    VoidCallback? onTapOverride,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTapOverride ?? () {
            ref.read(messengerRailTabProvider.notifier).state = tabId;
            if (tabId == 'archive') {
              ref.read(chatTabFilterProvider.notifier).state = 'archive';
            } else if (tabId == 'chats') {
              ref.read(chatTabFilterProvider.notifier).state = 'all';
            }
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Selection Indicator Bar on the far left
                if (isActive)
                  Positioned(
                    left: 0,
                    top: 14,
                    bottom: 14,
                    width: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0084FF),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                
                // Icon
                Icon(
                  icon,
                  size: 24,
                  color: isActive ? const Color(0xFF0084FF) : const Color(0xFF8E8E93),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Render Left Side Panel content based on active rail tab
  Widget _buildSidebarContent(String selectedTab) {
    switch (selectedTab) {
      case 'chats':
      case 'archive':
        return const MessageSidebar();
      case 'calls':
        return const _CallsSidebar();
      case 'people':
        return const _PeopleSidebar();
      case 'stories':
        return const _StoriesSidebar();
      default:
        return const MessageSidebar();
    }
  }

  // Render Center Main content based on active rail tab
  Widget _buildCenterContent(String selectedTab) {
    switch (selectedTab) {
      case 'chats':
      case 'archive':
        return const MessageChatWindow();
      case 'calls':
        return const _CallsMain();
      case 'people':
        return const _PeopleMain();
      case 'stories':
        return const _StoriesMain();
      default:
        return const MessageChatWindow();
    }
  }
}

// ==========================================
// MOCK SUB-VIEWS FOR NON-CHAT TABS
// ==========================================

// CALLS VIEW
class _CallsSidebar extends StatelessWidget {
  const _CallsSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1B1B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'Cuộc gọi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF242526),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 12),
                  Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                  SizedBox(width: 8),
                  Text('Tìm kiếm', style: TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                final names = ['Lê Hoàng Nam', 'Trần Thu Trang', 'Nguyễn Minh Quân', 'Phạm Hải Yến'];
                final times = ['10:45', 'Hôm qua', '29 tháng 6', '28 tháng 6'];
                final isMissed = index == 1;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&index=$index'),
                  ),
                  title: Text(
                    names[index],
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(
                        index.isEven ? Icons.call_made_rounded : Icons.call_received_rounded,
                        size: 14,
                        color: isMissed ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isMissed ? 'Cuộc gọi nhỡ' : 'Cuộc gọi đi • ${times[index]}',
                          style: TextStyle(color: isMissed ? Colors.red : Colors.grey, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.phone_rounded, color: Color(0xFF0084FF), size: 20),
                    onPressed: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CallsMain extends StatelessWidget {
  const _CallsMain();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_rounded, size: 64, color: Colors.white30),
            ),
            const SizedBox(height: 24),
            const Text(
              'Liên hệ gần đây',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bắt đầu cuộc gọi thoại hoặc cuộc gọi video với bạn bè của bạn.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// PEOPLE VIEW
class _PeopleSidebar extends StatelessWidget {
  const _PeopleSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1B1B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'Mọi người',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                final names = ['Đỗ Minh Triết', 'Nguyễn Khánh Linh', 'Bùi Văn Hùng', 'Phan Mỹ Lệ', 'Vũ Anh Tuấn'];
                final statuses = ['Hoạt động 5 phút trước', 'Đang hoạt động', 'Hoạt động 1 giờ trước', 'Đang hoạt động', 'Đang hoạt động'];

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&index=$index'),
                      ),
                      if (statuses[index] == 'Đang hoạt động')
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF31A24C),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF1C1B1B), width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    names[index],
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    statuses[index],
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PeopleMain extends StatelessWidget {
  const _PeopleMain();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_alt_rounded, size: 64, color: Colors.white30),
            ),
            const SizedBox(height: 24),
            const Text(
              'Danh sách liên hệ của bạn',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tìm kiếm và kết nối với bạn bè trên Messenger.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// STORIES VIEW
class _StoriesSidebar extends StatelessWidget {
  const _StoriesSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1B1B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'Tin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                final names = ['Tin của bạn', 'Lâm Thúy Vi', 'Đặng Quốc Bảo'];
                final times = ['Thêm vào tin', '2 giờ trước', '4 giờ trước'];

                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: index == 0 ? Colors.white30 : const Color(0xFF0084FF),
                        width: index == 0 ? 1 : 2.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&index=$index'),
                    ),
                  ),
                  title: Text(
                    names[index],
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    times[index],
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StoriesMain extends StatelessWidget {
  const _StoriesMain();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.donut_large_rounded, size: 64, color: Colors.white30),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chia sẻ khoảnh khắc của bạn',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Xem tin của bạn bè hoặc chia sẻ tin của bạn ngay.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
