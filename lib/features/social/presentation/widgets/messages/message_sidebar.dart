import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_state.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_draft_state.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_dialogs.dart';

class MessageSidebar extends ConsumerStatefulWidget {
  const MessageSidebar({super.key});

  @override
  ConsumerState<MessageSidebar> createState() => _MessageSidebarState();
}

class _MessageSidebarState extends ConsumerState<MessageSidebar> {
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      ref.read(isSearchFocusedProvider.notifier).state = _searchFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final threads = ref.watch(chatThreadsProvider);
    final activeId = ref.watch(activeThreadIdProvider);
    final selectedTab = ref.watch(chatTabFilterProvider);
    final searchQuery = ref.watch(messageSearchQueryProvider);
    final isFocused = ref.watch(isSearchFocusedProvider);

    // Apply Tab filtering
    var filteredThreads = threads.where((t) {
      if (selectedTab == 'unread') return t.unread;
      if (selectedTab == 'groups') return t.id.contains('group');
      if (selectedTab == 'archive') return t.id.contains('archive');
      return true; // all
    }).toList();

    // Apply Search query filtering
    if (searchQuery.isNotEmpty) {
      final drafts = ref.watch(messageDraftsProvider);
      filteredThreads = filteredThreads.where((t) {
        final matchesName = t.name.toLowerCase().contains(searchQuery.toLowerCase());
        final draft = drafts[t.id];
        final matchesDraft = draft != null && draft.draftText.toLowerCase().contains(searchQuery.toLowerCase());
        return matchesName || matchesDraft;
      }).toList();
    }

    return Material(
      color: const Color(0xFF1C1B1B), // Dark charcoal matching Messenger Desktop
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Text(
                  'Đoạn chat',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                // More button
                _buildCircularHeaderButton(
                  icon: Icons.more_horiz_rounded,
                  onTap: (btnContext) {
                    _showMoreMenu(btnContext);
                  },
                ),
                const SizedBox(width: 8),
                // Compose button
                _buildCircularHeaderButton(
                  icon: Icons.edit_note_rounded,
                  onTap: (btnContext) {
                    showDialog(
                      context: context,
                      builder: (_) => const CreateChatDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Focus(
              onFocusChange: (hasFocus) {
                ref.read(isSearchFocusedProvider.notifier).state = hasFocus;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 36, // Slimmer search bar
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E), // Lighter grey input background
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isFocused ? const Color(0xFF0084FF) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: (val) {
                    ref.read(messageSearchQueryProvider.notifier).state = val;
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm trên Messenger',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isFocused ? const Color(0xFF0084FF) : Colors.white38,
                      size: 20,
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(messageSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Tab Chips Row
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildTabChip('all', 'Hộp thư'),
                _buildTabChip('unread', 'Chưa đọc'),
                _buildTabChip('groups', 'Nhóm'),
                _buildTabChip('archive', 'Kho lưu trữ'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Divider
          const Divider(height: 1, color: Color(0xFF303031)),
          // Conversation tiles list
          Expanded(
            child: filteredThreads.isEmpty
                ? const Center(
                    child: Text(
                      'Không có đoạn chat nào',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredThreads.length,
                    itemBuilder: (context, index) {
                      final thread = filteredThreads[index];
                      final isSelected = thread.id == activeId;
                      return _buildConversationTile(thread, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularHeaderButton({required IconData icon, required void Function(BuildContext) onTap}) {
    return Builder(
      builder: (btnContext) {
        return Material(
          color: const Color(0xFF242526),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTap(btnContext),
            splashFactory: NoSplash.splashFactory, // Disable ripple
            hoverColor: const Color(0xFF3A3B3C),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        );
      }
    );
  }

  void _showMoreMenu(BuildContext btnContext) {
    final renderBox = btnContext.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Background dim/dismiss layer
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => overlayEntry.remove(),
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Menu Container positioned right below the button
            Positioned(
              top: position.dy + 46, // Pushed down slightly (from 42 to 46)
              left: position.dx - 4, // Pushed to the right slightly (from -16 to -4)
              child: Material(
                color: Colors.transparent,
                child: _MoreMenuPopover(
                  onDismiss: () => overlayEntry.remove(),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(btnContext).insert(overlayEntry);
  }

  Widget _buildTabChip(String value, String label) {
    final selectedTab = ref.watch(chatTabFilterProvider);
    final isSelected = selectedTab == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            ref.read(chatTabFilterProvider.notifier).state = value;
          }
        },
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF0084FF) : Colors.white60,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        backgroundColor: Colors.transparent,
        selectedColor: const Color(0xFF2C2C2E),
        side: const BorderSide(
          color: Colors.transparent,
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildConversationTile(ChatThread thread, bool isSelected) {
    return _ConversationTile(
      thread: thread,
      isSelected: isSelected,
      showContextMenu: _showContextMenu,
      showThreadMoreMenu: _showThreadMoreMenu,
    );
  }

  void _showThreadMoreMenu(BuildContext btnContext, String threadId, VoidCallback onMenuDismiss) {
    final renderBox = btnContext.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Dismiss layer
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                overlayEntry.remove();
                onMenuDismiss();
              },
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Menu Popover
            Positioned(
              top: position.dy + 40, // Positioned right under the button with clean gap
              left: position.dx - 14, // Shifted right, arrow is at left: 24 of toggle
              child: Material(
                color: Colors.transparent,
                child: _ThreadMoreMenuPopover(
                  threadId: threadId,
                  onDismiss: () {
                    overlayEntry.remove();
                    onMenuDismiss();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(btnContext).insert(overlayEntry);
  }

  void _showContextMenu(Offset position, String threadId) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      color: const Color(0xFF242526),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          onTap: () => ref.read(chatThreadsProvider.notifier).togglePinThread(threadId),
          child: const Row(
            children: [
              Icon(Icons.push_pin_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 10),
              Text('Ghim đoạn chat', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => ref.read(chatThreadsProvider.notifier).toggleMuteThread(threadId),
          child: const Row(
            children: [
              Icon(Icons.notifications_off_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 10),
              Text('Tắt thông báo', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => ref.read(chatThreadsProvider.notifier).deleteThread(threadId),
          child: const Row(
            children: [
              Icon(Icons.delete_rounded, color: Colors.redAccent, size: 18),
              SizedBox(width: 10),
              Text('Xóa cuộc trò chuyện', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreMenuPopover extends StatefulWidget {
  final VoidCallback onDismiss;

  const _MoreMenuPopover({required this.onDismiss});

  @override
  State<_MoreMenuPopover> createState() => _MoreMenuPopoverState();
}

class _MoreMenuPopoverState extends State<_MoreMenuPopover> {
  String _activeScreen = 'main'; // main, privacy, encryption, read_receipts, verify_keys
  bool _readReceiptsEnabled = false;
  bool _verifyKeysEnabled = false;
  bool _isForwardTransition = true;

  int _getDepth(String screen) {
    switch (screen) {
      case 'privacy':
        return 1;
      case 'encryption':
      case 'read_receipts':
      case 'verify_keys':
        return 2;
      case 'main':
      default:
        return 0;
    }
  }

  void _changeScreen(String target) {
    final oldDepth = _getDepth(_activeScreen);
    final newDepth = _getDepth(target);
    setState(() {
      _isForwardTransition = newDepth >= oldDepth;
      _activeScreen = target;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget activeChild;
    switch (_activeScreen) {
      case 'privacy':
        activeChild = _buildPrivacyMenu();
        break;
      case 'encryption':
        activeChild = _buildEncryptionMenu();
        break;
      case 'read_receipts':
        activeChild = _buildReadReceiptsMenu();
        break;
      case 'verify_keys':
        activeChild = _buildVerifyKeysMenu();
        break;
      case 'main':
      default:
        activeChild = _buildMainMenu();
        break;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Arrow pointer (rotated square)
        Positioned(
          top: -6,
          left: 14,
          child: Transform.rotate(
            angle: 0.785398, // pi / 4
            child: Container(
              width: 12,
              height: 12,
              color: const Color(0xFF242526),
            ),
          ),
        ),
        // Menu Box
        Container(
          width: 320,
          clipBehavior: Clip.hardEdge, // Clip sliding transitions cleanly
          decoration: BoxDecoration(
            color: const Color(0xFF242526),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250), // Standard smooth transition speed
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              final isEntering = child.key == ValueKey(_activeScreen);
              
              Offset beginOffset;
              if (isEntering) {
                beginOffset = _isForwardTransition ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
              } else {
                beginOffset = _isForwardTransition ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
              }
              
              return SlideTransition(
                position: animation.drive(
                  Tween<Offset>(
                    begin: beginOffset,
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeInOutCubic)),
                ),
                child: child,
              );
            },
            child: activeChild,
          ),
        ),
      ],
    );
  }

  Widget _buildMainMenu() {
    return Column(
      key: const ValueKey('main'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMenuItem(Icons.settings_rounded, 'Tùy chọn', () {
          widget.onDismiss();
        }),
        const Divider(color: Color(0xFF303031), height: 12),
        _buildMenuItem(Icons.mark_chat_unread_rounded, 'Tin nhắn đang chờ', () {
          widget.onDismiss();
        }),
        _buildMenuItem(Icons.archive_rounded, 'Đoạn chat đã lưu trữ', () {
          widget.onDismiss();
        }),
        _buildMenuItem(Icons.block_rounded, 'Tài khoản đã hạn chế', () {
          widget.onDismiss();
        }),
        const Divider(color: Color(0xFF303031), height: 12),
        _buildMenuItem(
          Icons.security_rounded,
          'Quyền riêng tư và an toàn',
          () {
            _changeScreen('privacy');
          },
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
        ),
        const Divider(color: Color(0xFF303031), height: 12),
        _buildMenuItem(Icons.help_rounded, 'Trợ giúp', () {
          widget.onDismiss();
        }),
      ],
    );
  }

  Widget _buildPrivacyMenu() {
    return Column(
      key: const ValueKey('privacy'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Bar with Back Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                onPressed: () {
                  _changeScreen('main');
                },
              ),
              const SizedBox(width: 12),
              const Text(
                'Quyền riêng tư và an toàn',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF303031), height: 8),
        _buildSubMenuItem(
          'Đoạn chat được mã hóa đầu cuối',
          'Quản lý cài đặt đoạn chat được mã hóa đầu cuối',
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
          onTap: () {
            _changeScreen('encryption');
          },
        ),
        _buildSubMenuItem(
          'Thông báo đã đọc',
          _readReceiptsEnabled ? 'Bật' : 'Tắt',
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
          onTap: () {
            _changeScreen('read_receipts');
          },
        ),
        _buildSubMenuItem(
          'Đoạn chat đã báo cáo',
          'Xem thông tin mới về báo cáo của bạn',
          onTap: () {},
        ),
        const Divider(color: Color(0xFF303031), height: 12),
        _buildSubMenuItem(
          'Xác minh khóa trong đoạn chat',
          _verifyKeysEnabled ? 'Bật' : 'Tắt',
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
          onTap: () {
            _changeScreen('verify_keys');
          },
        ),
      ],
    );
  }

  Widget _buildEncryptionMenu() {
    return Column(
      key: const ValueKey('encryption'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                onPressed: () {
                  _changeScreen('privacy');
                },
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Đoạn chat được mã hóa đầu cuối',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF303031), height: 8),
        _buildSubMenuItem(
          'Lưu trữ tin nhắn',
          'Quản lý cách bạn lưu trữ và truy cập vào lịch sử chat.',
          onTap: () {},
        ),
        _buildSubMenuItem(
          'Cảnh báo bảo mật',
          'Xem, quản lý cảnh báo về lần đăng nhập và thay đổi khóa',
          onTap: () {},
        ),
        const Divider(color: Color(0xFF303031), height: 12),
        _buildSubMenuItem(
          'Bản xem trước',
          'Xem trước nội dung được chia sẻ từ các ứng dụng của Meta',
          trailing: const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Text('Bật', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildReadReceiptsMenu() {
    return Column(
      key: const ValueKey('read_receipts'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                onPressed: () {
                  _changeScreen('privacy');
                },
              ),
              const SizedBox(width: 12),
              const Text(
                'Thông báo đã đọc',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF303031), height: 8),
        _buildSubMenuItem(
          'Hiển thị thông báo đã đọc',
          'Mọi người sẽ không biết khi bạn đọc tin nhắn của họ và ngược lại.',
          trailing: Switch(
            value: _readReceiptsEnabled,
            onChanged: (val) {
              setState(() {
                _readReceiptsEnabled = val;
              });
            },
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF0084FF),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF4E4F50),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyKeysMenu() {
    return Column(
      key: const ValueKey('verify_keys'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                onPressed: () {
                  _changeScreen('privacy');
                },
              ),
              const SizedBox(width: 12),
              const Text(
                'Xác minh khóa',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF303031), height: 8),
        _buildSubMenuItem(
          'Xác minh khóa trong đoạn chat',
          'Nhấp vào một tin nhắn để xem khóa của bạn hoặc khóa của người khác.',
          trailing: Switch(
            value: _verifyKeysEnabled,
            onChanged: (val) {
              setState(() {
                _verifyKeysEnabled = val;
              });
            },
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF0084FF),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF4E4F50),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Widget? trailing}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFF3A3B3C),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.normal),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(String title, String subtitle, {Widget? trailing, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFF3A3B3C),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  final double size;
  const _BouncingDots({this.size = 4});

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            double delay = index * 0.2;
            double progress = (_controller.value - delay).clamp(0.0, 1.0);
            if (progress > 0.5) progress = 1.0 - progress;
            double offset = progress * 8.0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              transform: Matrix4.translationValues(0, -offset, 0),
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                color: Color(0xFF0084FF),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _ConversationTile extends ConsumerStatefulWidget {
  final ChatThread thread;
  final bool isSelected;
  final void Function(Offset position, String threadId) showContextMenu;
  final void Function(BuildContext btnContext, String threadId, VoidCallback onMenuDismiss) showThreadMoreMenu;

  const _ConversationTile({
    required this.thread,
    required this.isSelected,
    required this.showContextMenu,
    required this.showThreadMoreMenu,
  });

  @override
  ConsumerState<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends ConsumerState<_ConversationTile> {
  bool _isHovered = false;
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final isSelected = widget.isSelected;

    final lastMsg = thread.messages.isNotEmpty ? thread.messages.last : null;
    String previewText = '';
    String timeText = '';

    if (lastMsg != null) {
      final isMe = lastMsg.senderId == 'me';
      final prefix = isMe ? 'Bạn: ' : '';
      if (lastMsg.type == MessageType.text) {
        previewText = '$prefix${lastMsg.text}';
      } else if (lastMsg.type == MessageType.task) {
        previewText = '$prefixĐã gửi một Task: ${lastMsg.metaTitle}';
      } else if (lastMsg.type == MessageType.image) {
        previewText = '$prefixĐã gửi một hình ảnh';
      } else if (lastMsg.type == MessageType.sticker) {
        previewText = '$prefixĐã gửi một nhãn dán';
      } else {
        previewText = '$prefixĐã gửi một tin nhắn';
      }

      // Quick time formatting
      final diff = DateTime.now().difference(lastMsg.timestamp);
      if (diff.inMinutes < 60) {
        timeText = '${diff.inMinutes}p';
      } else if (diff.inHours < 24) {
        timeText = '${diff.inHours}g';
      } else {
        timeText = '${diff.inDays}ngày';
      }
    }

    final draft = ref.watch(messageDraftsProvider)[thread.id];
    final hasDraft = draft != null && draft.draftText.isNotEmpty;
    if (hasDraft) {
      previewText = 'Nháp: ${draft.draftText}';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Material(
          color: isSelected
              ? const Color(0xFF2C2C2E) // Native selection grey background
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              ref.read(activeThreadIdProvider.notifier).state = thread.id;
              ref.read(chatThreadsProvider.notifier).selectThread(thread.id);
            },
            onSecondaryTapDown: (details) {
              widget.showContextMenu(details.globalPosition, thread.id);
            },
            splashFactory: NoSplash.splashFactory,
            hoverColor: isSelected
                ? const Color(0xFF2C2C2E)
                : const Color(0xFF242526),
            child: Container(
              height: 72, // Slimmer tile height
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Avatar with online dot
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF3A3B3C),
                        child: Text(
                          thread.avatarInitials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (thread.online)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF31A24C),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2C2C2E)
                                    : (_isHovered ? const Color(0xFF242526) : const Color(0xFF1C1B1B)),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Text details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          thread.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: thread.unread ? FontWeight.bold : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: thread.isTyping
                                  ? const Row(
                                      children: [
                                        Text(
                                          'Đang nhập',
                                          style: TextStyle(
                                            color: Color(0xFF0084FF),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        _BouncingDots(size: 3),
                                      ],
                                    )
                                  : Text(
                                      previewText,
                                      style: TextStyle(
                                        color: hasDraft
                                            ? const Color(0xFF0084FF)
                                            : (thread.unread ? Colors.white : Colors.white38),
                                        fontSize: 13,
                                        fontWeight: hasDraft
                                            ? FontWeight.w500
                                            : (thread.unread ? FontWeight.bold : FontWeight.normal),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                            const SizedBox(width: 8),
                            if (!_isHovered && !_isMenuOpen)
                              Text(
                                timeText,
                                style: TextStyle(
                                  color: thread.unread ? const Color(0xFF0084FF) : Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Hover 3-dot or badge
                  if (_isHovered || _isMenuOpen)
                    Builder(
                      builder: (btnContext) {
                        return Material(
                          color: const Color(0xFF3A3B3C),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isMenuOpen = true;
                              });
                              widget.showThreadMoreMenu(btnContext, thread.id, () {
                                if (mounted) {
                                  setState(() {
                                    _isMenuOpen = false;
                                  });
                                }
                              });
                            },
                            hoverColor: const Color(0xFF4E4F50),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(Icons.more_horiz_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        );
                      }
                    )
                  else ...[
                    // Badge indicators
                    if (thread.unread)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0084FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (thread.muted && !thread.unread)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.notifications_off_rounded, color: Colors.white24, size: 16),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreadMoreMenuPopover extends ConsumerWidget {
  final String threadId;
  final VoidCallback onDismiss;

  const _ThreadMoreMenuPopover({
    required this.threadId,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Arrow pointer (rotated square)
        Positioned(
          top: -6,
          left: 24, // Positioned on the left side of the toggle
          child: Transform.rotate(
            angle: 0.785398, // pi / 4
            child: Container(
              width: 12,
              height: 12,
              color: const Color(0xFF242526),
            ),
          ),
        ),
        // Menu Box
        Container(
          width: 300, // Enlarged slightly to 300px
          constraints: const BoxConstraints(maxHeight: 400), // Scrollable context menu
          decoration: BoxDecoration(
            color: const Color(0xFF242526),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildItem(Icons.mark_chat_unread_outlined, 'Đánh dấu là chưa đọc', () {
                    ref.read(chatThreadsProvider.notifier).toggleUnreadThread(threadId);
                    onDismiss();
                  }),
                  _buildItem(Icons.notifications_none_rounded, 'Tắt thông báo', () {
                    ref.read(chatThreadsProvider.notifier).toggleMuteThread(threadId);
                    onDismiss();
                  }),
                  _buildItem(Icons.account_circle_outlined, 'Xem trang cá nhân', () {
                    onDismiss();
                  }),
                  const Divider(color: Color(0xFF303031), height: 12),
                  _buildItem(Icons.lock_outline_rounded, 'Bắt đầu đoạn chat được mã hóa đầu cuối', () {
                    onDismiss();
                  }),
                  const Divider(color: Color(0xFF303031), height: 12),
                  _buildItem(Icons.phone_outlined, 'Gọi thoại', () {
                    onDismiss();
                  }),
                  _buildItem(Icons.videocam_outlined, 'Chat video', () {
                    onDismiss();
                  }),
                  _buildItem(Icons.block_outlined, 'Chặn', () {
                    onDismiss();
                  }),
                  _buildItem(Icons.inventory_2_outlined, 'Lưu trữ đoạn chat', () {
                    onDismiss();
                  }),
                  _buildItem(Icons.delete_outline_rounded, 'Xóa đoạn chat', () {
                    ref.read(chatThreadsProvider.notifier).deleteThread(threadId);
                    onDismiss();
                  }),
                  _buildItem(Icons.warning_amber_rounded, 'Báo cáo', () {
                    onDismiss();
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFF3A3B3C),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.normal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
