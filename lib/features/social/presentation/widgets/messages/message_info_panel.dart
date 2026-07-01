import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_state.dart';

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

    return Container(
      color: const Color(0xFF1C1B1B), // Match the sidebar background
      height: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            // Circular Avatar (sunset view fallback to match user screenshot)
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: thread.avatarUrl != null && thread.avatarUrl!.isNotEmpty
                        ? NetworkImage(thread.avatarUrl!)
                        : const NetworkImage('https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=200') as ImageProvider,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // User Name
            Center(
              child: Text(
                thread.name,
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
                    thread.muted ? Icons.notifications_off_outlined : Icons.notifications_none_rounded,
                    'Tắt thông báo',
                    () => ref.read(chatThreadsProvider.notifier).toggleMuteThread(thread.id),
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
                  onTap: () {},
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
                  onTap: () {},
                ),
                _buildSubItem(
                  leading: const Icon(Icons.thumb_up_rounded, color: Color(0xFF0084FF), size: 20),
                  title: 'Thay đổi biểu tượng cảm xúc',
                  onTap: () {},
                ),
                _buildSubItem(
                  leading: const SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: Text(
                        'Aa',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: 'Chỉnh sửa biệt danh',
                  onTap: () {},
                ),
              ],
            ),
            _buildAccordionTile(
              context,
              title: 'File phương tiện, file và liên kết',
              children: [
                _buildSubItem(
                  leading: const Icon(Icons.image_outlined, color: Colors.white70, size: 20),
                  title: 'File phương tiện',
                  onTap: () {},
                ),
                _buildSubItem(
                  leading: const Icon(Icons.insert_drive_file_outlined, color: Colors.white70, size: 20),
                  title: 'File',
                  onTap: () {},
                ),
                _buildSubItem(
                  leading: const Icon(Icons.link_rounded, color: Colors.white70, size: 20),
                  title: 'Liên kết',
                  onTap: () {},
                ),
              ],
            ),
            _buildAccordionTile(
              context,
              title: 'Quyền riêng tư và hỗ trợ',
              children: [
                _buildSubItem(
                  leading: Icon(
                    thread.muted ? Icons.notifications_off_outlined : Icons.notifications_none_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  title: 'Tắt thông báo',
                  onTap: () => ref.read(chatThreadsProvider.notifier).toggleMuteThread(thread.id),
                ),
                _buildSubItem(
                  leading: const Icon(Icons.shield_outlined, color: Colors.white70, size: 20),
                  title: 'Quyền nhắn tin',
                  onTap: () {},
                ),
                _buildSubItem(
                  leading: const Icon(Icons.visibility_outlined, color: Colors.white70, size: 20),
                  title: 'Thông báo đã đọc',
                  subtitle: 'Tắt',
                  onTap: () {},
                ),
                _buildSubItem(
                  leading: const Icon(Icons.person_off_outlined, color: Colors.white70, size: 20),
                  title: 'Hạn chế',
                  onTap: () {},
                ),
                _buildSubItem(
                  leading: const Icon(Icons.block_outlined, color: Colors.white70, size: 20),
                  title: 'Chặn',
                  onTap: () {},
                ),
                _buildSubItem(
                  leading: const Icon(Icons.report_problem_outlined, color: Colors.white70, size: 20),
                  title: 'Báo cáo',
                  subtitle: 'Đóng góp ý kiến và báo cáo cuộc trò chuyện',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
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
