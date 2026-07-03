import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_state.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_dialogs.dart';

class MessageInfoPanel extends ConsumerWidget {
  const MessageInfoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeThreadIdProvider);
    final threads = ref.watch(chatThreadsProvider);

    if (activeId == null) {
      return const SizedBox.shrink();
    }

    final threadIndex = threads.indexWhere((t) => t.id == activeId);
    if (threadIndex == -1) {
      return const SizedBox.shrink();
    }
    final thread = threads[threadIndex];

    ref.listen<String?>(activeThreadIdProvider, (prev, next) {
      if (prev != next) {
        ref.read(infoPanelTabProvider.notifier).state = InfoPanelTab.main;
      }
    });

    final activeTab = ref.watch(infoPanelTabProvider);

    Widget content;
    switch (activeTab) {
      case InfoPanelTab.media:
        content = MediaFilesView(thread: thread);
        break;
      case InfoPanelTab.permissions:
        content = MessagingPermissionsView(thread: thread);
        break;
      case InfoPanelTab.readReceipts:
        content = ReadReceiptsView(thread: thread);
        break;
      case InfoPanelTab.main:
      default:
        content = _buildMainPanel(context, ref, thread);
        break;
    }

    return Container(
      color: const Color(0xFF1C1B1B), // Match the sidebar background
      height: double.infinity,
      child: content,
    );
  }

  Widget _buildMainPanel(BuildContext context, WidgetRef ref, ChatThread thread) {
    final friendId = thread.recipientId ?? 'friend';
    final nicknamesMap = ref.watch(threadNicknamesProvider)[thread.id] ?? {};
    final activeName = nicknamesMap[friendId] ?? thread.name;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          // Circular Avatar (sunset view fallback to match user screenshot)
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: const Color(0xFF3A3B3C),
              backgroundImage: thread.avatarUrl != null && thread.avatarUrl!.trim().isNotEmpty
                  ? NetworkImage(thread.avatarUrl!)
                  : null,
              child: thread.avatarUrl == null || thread.avatarUrl!.trim().isEmpty
                  ? Text(
                      thread.avatarInitials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          // User Name (uses activeNickname if set)
          Center(
            child: Text(
              activeName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Quick Actions Buttons Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickActionButton(
                  Icons.account_circle_outlined,
                  'Trang cá n...',
                  () {},
                ),
                _buildQuickActionButton(
                  thread.muted ? Icons.notifications_off_rounded : Icons.notifications_none_rounded,
                  'Tắt thông báo',
                  () async {
                    final res = await MuteNotificationsDialog.show(context, thread);
                    if (res != null) {
                      ref.read(threadMuteDurationProvider.notifier).setMuteDuration(thread.id, res);
                      if (!thread.muted) {
                        ref.read(chatThreadsProvider.notifier).toggleMuteThread(thread.id);
                      }
                    }
                  },
                ),
                _buildQuickActionButton(
                  Icons.search_rounded,
                  'Tìm kiếm',
                  () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF242526), height: 1),
          // Accordion Sections (ExpansionTiles without borders)
          _buildAccordionTile(
            context,
            title: 'Thông tin về đoạn chat',
            children: [
              _buildSubItem(
                leading: Transform.rotate(
                  angle: -0.785, // Rotated ~45 degrees pointing down-left
                  child: const Icon(Icons.push_pin_rounded, color: Colors.white70, size: 20),
                ),
                title: 'Xem tin nhắn đã ghim',
                onTap: () {
                  PinnedMessagesDialog.show(context, thread);
                },
              ),
            ],
          ),
          _buildAccordionTile(
            context,
            title: 'Tùy chỉnh đoạn chat',
            children: [
              _buildSubItem(
                leading: const Icon(Icons.circle, color: Color(0xFF0084FF), size: 20),
                title: 'Đổi chủ đề',
                onTap: () => ThemeSelectorDialog.show(context, thread),
              ),
              _buildSubItem(
                leading: Text(
                  ref.watch(threadQuickReactionProvider)[thread.id] ?? '👍',
                  style: const TextStyle(fontSize: 20),
                ),
                title: 'Thay đổi biểu tượng cảm xúc',
                onTap: () => QuickReactionSelectorDialog.show(context, thread),
              ),
              _buildSubItem(
                leading: const SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: 'Chỉnh sửa biệt danh',
                onTap: () => NicknamesDialog.show(context, thread),
              ),
            ],
          ),
          _buildAccordionTile(
            context,
            title: 'File phương tiện và file',
            children: [
              _buildSubItem(
                leading: const Icon(Icons.image_rounded, color: Colors.white70, size: 20),
                title: 'File phương tiện',
                onTap: () => ref.read(infoPanelTabProvider.notifier).state = InfoPanelTab.media,
              ),
              _buildSubItem(
                leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.white70, size: 20),
                title: 'File',
                onTap: () => ref.read(infoPanelTabProvider.notifier).state = InfoPanelTab.media,
              ),
            ],
          ),
          _buildAccordionTile(
            context,
            title: 'Quyền riêng tư và hỗ trợ',
            children: [
              Builder(
                builder: (context) {
                  final isMuted = thread.muted;
                  final muteDuration = ref.watch(threadMuteDurationProvider)[thread.id];
                  String? muteSubtitle;
                  if (isMuted) {
                    if (muteDuration == '15m') {
                      muteSubtitle = 'Trong 15 phút';
                    } else if (muteDuration == '1h') {
                      muteSubtitle = 'Trong 1 giờ';
                    } else if (muteDuration == '8h') {
                      muteSubtitle = 'Trong 8 giờ';
                    } else if (muteDuration == '24h') {
                      muteSubtitle = 'Trong 24 giờ';
                    } else {
                      muteSubtitle = 'Đến khi tôi bật lại';
                    }
                  }
                  return _buildSubItem(
                    leading: const Icon(Icons.notifications_rounded, color: Colors.white70, size: 20),
                    title: 'Tắt thông báo',
                    subtitle: muteSubtitle,
                    onTap: () async {
                      final res = await MuteNotificationsDialog.show(context, thread);
                      if (res != null) {
                        ref.read(threadMuteDurationProvider.notifier).setMuteDuration(thread.id, res);
                        if (!thread.muted) {
                          ref.read(chatThreadsProvider.notifier).toggleMuteThread(thread.id);
                        }
                      }
                    },
                  );
                }
              ),
              _buildSubItem(
                leading: const Icon(Icons.shield_outlined, color: Colors.white70, size: 20),
                title: 'Quyền nhắn tin',
                onTap: () => ref.read(infoPanelTabProvider.notifier).state = InfoPanelTab.permissions,
              ),
              Builder(
                builder: (context) {
                  final disappearingVal = ref.watch(threadDisappearingMessagesProvider)[thread.id] ?? 'off';
                  final disappearingSubtitle = disappearingVal == '24h' ? '24 giờ' : 'Tắt';
                  return _buildSubItem(
                    leading: const Icon(Icons.history_rounded, color: Colors.white70, size: 20),
                    title: 'Tin nhắn tự hủy',
                    subtitle: disappearingSubtitle,
                    onTap: () => DisappearingMessagesDialog.show(context, thread),
                  );
                }
              ),
              Builder(
                builder: (context) {
                  final showReadReceipts = ref.watch(threadReadReceiptsProvider)[thread.id] ?? true;
                  final readReceiptsSubtitle = showReadReceipts ? 'Bật' : 'Tắt';
                  return _buildSubItem(
                    leading: const Icon(Icons.visibility_rounded, color: Colors.white70, size: 20),
                    title: 'Thông báo đã đọc',
                    subtitle: readReceiptsSubtitle,
                    onTap: () => ref.read(infoPanelTabProvider.notifier).state = InfoPanelTab.readReceipts,
                  );
                }
              ),
              _buildSubItem(
                leading: const Icon(Icons.lock_rounded, color: Colors.white70, size: 20),
                title: 'Xác minh mã hóa đầu cuối',
                onTap: () {},
              ),
              _buildSubItem(
                leading: const Icon(Icons.person_off_rounded, color: Colors.white70, size: 20),
                title: 'Hạn chế',
                onTap: () => RestrictDialog.show(context, thread),
              ),
              _buildSubItem(
                leading: const Icon(Icons.remove_circle_rounded, color: Colors.white70, size: 20),
                title: 'Chặn',
                onTap: () => BlockDialog.show(context, thread),
              ),
              _buildSubItem(
                leading: const Icon(Icons.error_rounded, color: Colors.white70, size: 20),
                title: 'Báo cáo',
                subtitle: 'Đóng góp ý kiến và báo cáo cuộc trò chuyện',
                onTap: () => ReportDialog.show(context, thread),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: const Color(0xFF2C2C2E), // Lighter circle background
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            hoverColor: const Color(0xFF3A3B3C),
            child: Container(
              width: 40, // Slightly more compact circle
              height: 40,
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAccordionTile(BuildContext context, {required String title, required List<Widget> children}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white70,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.zero,
        children: children,
      ),
    );
  }

  Widget _buildSubItem({
    required Widget leading,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: const Color(0xFF2E2F30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDanger ? Colors.redAccent : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

class MediaFilesView extends ConsumerStatefulWidget {
  final ChatThread thread;
  const MediaFilesView({super.key, required this.thread});

  @override
  ConsumerState<MediaFilesView> createState() => _MediaFilesViewState();
}

class _MediaFilesViewState extends ConsumerState<MediaFilesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title Bar with Back Button
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 12, right: 16, bottom: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => ref.read(infoPanelTabProvider.notifier).state = InfoPanelTab.main,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'File phương tiện và file',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Custom TabBar
        TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0084FF),
          labelColor: const Color(0xFF0084FF),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'File phương tiện'),
            Tab(text: 'File'),
          ],
        ),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMediaTab(),
              _buildFilesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaTab() {
    final List<ChatMessage> mediaMsgs = widget.thread.messages.where((m) =>
      !m.isRecalled &&
      (m.type == MessageType.image || m.type == MessageType.video || m.type == MessageType.gif) &&
      m.mediaUrl != null && m.mediaUrl!.trim().isNotEmpty
    ).toList();

    mediaMsgs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mediaMsgs.isEmpty) {
      // Fallback to mockup data (Photo 1) if no images sent in thread yet
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildMonthHeader('Tháng 5'),
          _buildMediaGrid([
            'https://picsum.photos/id/1011/300/300',
          ]),
          const SizedBox(height: 20),

          _buildMonthHeader('Tháng 4'),
          _buildMediaGrid([
            'https://picsum.photos/id/1015/300/300',
          ]),
          const SizedBox(height: 20),

          _buildMonthHeader('Tháng 3'),
          _buildMediaGrid([
            'https://picsum.photos/id/1020/300/300',
            'https://picsum.photos/id/1021/300/300',
            'https://picsum.photos/id/1022/300/300',
            'https://picsum.photos/id/1023/300/300',
            'https://picsum.photos/id/1024/300/300',
            'https://picsum.photos/id/1025/300/300',
          ], columnsCount: 3),
        ],
      );
    }

    // Group real media messages by Month
    final Map<String, List<String>> groupedMedia = {};
    for (final msg in mediaMsgs) {
      final key = 'Tháng ${msg.timestamp.month}';
      groupedMedia.putIfAbsent(key, () => []).add(msg.mediaUrl!);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: groupedMedia.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMonthHeader(entry.key),
            _buildMediaGrid(entry.value, columnsCount: entry.value.length >= 3 ? 3 : 2),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMonthHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMediaGrid(List<String> urls, {int columnsCount = 2}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnsCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: urls.length,
      itemBuilder: (context, index) {
        final url = urls[index];
        final isVideo = url.toLowerCase().endsWith('.mp4') ||
                        url.toLowerCase().endsWith('.mov') ||
                        url.toLowerCase().endsWith('.avi') ||
                        url.toLowerCase().endsWith('.mkv');

        ImageProvider? imgProvider;
        if (!isVideo) {
          if (url.startsWith('http://') || url.startsWith('https://')) {
            imgProvider = NetworkImage(url);
          } else {
            imgProvider = FileImage(File(url));
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(8),
            image: imgProvider != null
                ? DecorationImage(
                    image: imgProvider,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: isVideo
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 36),
                      SizedBox(height: 4),
                      Text(
                        'Video',
                        style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFilesTab() {
    final List<ChatMessage> fileMsgs = widget.thread.messages.where((m) =>
      !m.isRecalled &&
      m.type == MessageType.file &&
      m.fileName != null && m.fileName!.trim().isNotEmpty
    ).toList();

    fileMsgs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final String Function(int?) formatSize = (bytes) {
      if (bytes == null) return 'Không rõ dung lượng';
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    };

    final String Function(DateTime) formatDate = (dt) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    };

    if (fileMsgs.isEmpty) {
      // Mock files fallback
      final List<Map<String, String>> mockFiles = [
        {'name': 'Báo cáo chi tiết.pdf', 'size': '2.4 MB', 'date': '24/05/2026'},
        {'name': 'Đại cương thiết kế.docx', 'size': '4.1 MB', 'date': '12/05/2026'},
        {'name': 'Hình ảnh mockup app.zip', 'size': '45.8 MB', 'date': '08/04/2026'},
        {'name': 'Dự trù ngân sách.xlsx', 'size': '890 KB', 'date': '15/03/2026'},
      ];

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: mockFiles.length,
        itemBuilder: (context, index) {
          final file = mockFiles[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.insert_drive_file_rounded, color: Colors.white70),
              ),
              title: Text(
                file['name']!,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${file['size']} • ${file['date']}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              onTap: () {},
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: fileMsgs.length,
      itemBuilder: (context, index) {
        final msg = fileMsgs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.insert_drive_file_rounded, color: Colors.white70),
            ),
            title: Text(
              msg.fileName!,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${formatSize(msg.fileSize)} • ${formatDate(msg.timestamp)}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
}

class MessagingPermissionsView extends ConsumerWidget {
  final ChatThread thread;
  const MessagingPermissionsView({super.key, required this.thread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowSharing = ref.watch(threadPermissionsProvider)[thread.id] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 12, right: 16, bottom: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => ref.read(infoPanelTabProvider.notifier).state = InfoPanelTab.main,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'Quyền nhắn tin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Permission list item
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Cho phép chia sẻ tin nhắn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: allowSharing,
                    activeColor: const Color(0xFF0084FF),
                    onChanged: (val) {
                      ref.read(threadPermissionsProvider.notifier).toggleAllowSharing(thread.id, val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
                  children: [
                    TextSpan(text: 'Everyone in this chat can share messages with Meta AI or auto-save photos. These features are not available on some versions of Messenger. '),
                    TextSpan(
                      text: 'Tìm hiểu thêm',
                      style: TextStyle(color: Color(0xFF0084FF), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ReadReceiptsView extends ConsumerWidget {
  final ChatThread thread;
  const ReadReceiptsView({super.key, required this.thread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showReadReceipts = ref.watch(threadReadReceiptsProvider)[thread.id] ?? true;

    final friendId = thread.recipientId ?? 'friend';
    final nicknamesMap = ref.watch(threadNicknamesProvider)[thread.id] ?? {};
    final friendName = nicknamesMap[friendId] ?? thread.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 12, right: 16, bottom: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => ref.read(infoPanelTabProvider.notifier).state = InfoPanelTab.main,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Thông báo đã đọc',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Read receipts option
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Hiển thị thông báo đã đọc',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: showReadReceipts,
                    activeColor: const Color(0xFF0084FF),
                    onChanged: (val) {
                      ref.read(threadReadReceiptsProvider.notifier).toggleReadReceipts(thread.id, val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$friendName sẽ không biết khi bạn đọc tin nhắn của họ và bạn cũng không biết khi họ đọc tin nhắn của bạn.',
                style: const TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
