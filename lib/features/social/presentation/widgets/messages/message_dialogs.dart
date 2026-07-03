import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_state.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class CreateChatDialog extends ConsumerStatefulWidget {
  const CreateChatDialog({super.key});

  @override
  ConsumerState<CreateChatDialog> createState() => _CreateChatDialogState();
}

class _CreateChatDialogState extends ConsumerState<CreateChatDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allUsers = ref.watch(allUsersProvider).valueOrNull ?? [];
    
    final filteredUsers = allUsers.where((user) {
      final query = _searchQuery.toLowerCase();
      final name = (user.fullName ?? '').toLowerCase();
      final username = (user.username ?? '').toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 440,
          height: 520,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tin nhắn mới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search input
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm người dùng...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF18191A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0084FF), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gợi ý',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'Không tìm thấy người dùng nào',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () async {
                                final convId = await ref.read(chatThreadsProvider.notifier).createOrGetConversation(user.id);
                                ref.read(activeThreadIdProvider.notifier).state = convId;
                                Navigator.of(context).pop();
                              },
                              leading: CircleAvatar(
                                backgroundColor: DashboardColors.surfaceHigh,
                                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                                child: user.avatarUrl == null
                                    ? Text(
                                        (user.fullName ?? 'U')[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              title: Text(
                                user.fullName ?? user.username ?? 'Người dùng',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '@${user.username ?? 'user'}',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreSettingsDialog extends StatelessWidget {
  const MoreSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tùy chọn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSettingItem(Icons.settings_rounded, 'Cài đặt tài khoản'),
              _buildSettingItem(Icons.archive_rounded, 'Đoạn chat đã lưu trữ'),
              _buildSettingItem(Icons.mark_chat_unread_rounded, 'Tin nhắn đang chờ'),
              _buildSettingItem(Icons.block_rounded, 'Tài khoản đã hạn chế'),
              _buildSettingItem(Icons.lock_rounded, 'Quyền riêng tư & An toàn'),
              const Divider(color: Color(0xFF303031), height: 24),
              _buildSettingItem(Icons.help_rounded, 'Trợ giúp & Hỗ trợ'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: Colors.white70, size: 20),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
        onTap: () {},
      ),
    );
  }
}

class RecallMessageDialog extends StatefulWidget {
  const RecallMessageDialog({super.key});

  static Future<int?> show(BuildContext context) {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const RecallMessageDialog(),
    );
  }

  @override
  State<RecallMessageDialog> createState() => _RecallMessageDialogState();
}

class _RecallMessageDialogState extends State<RecallMessageDialog> {
  int _selectedValue = 1; // 1 = Thu hồi với mọi người, 2 = Thu hồi với bạn

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Bạn muốn thu hồi tin nhắn này ở phía ai?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3A3B3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Option 1
              _buildOption(
                value: 1,
                title: 'Thu hồi với mọi người',
                subtitle: 'Tin nhắn này sẽ bị thu hồi với mọi người trong đoạn chat. Những người khác có thể đã xem hoặc chuyển tiếp tin nhắn đó. Tin nhắn đã thu hồi vẫn có thể bị báo cáo.',
              ),
              const SizedBox(height: 16),

              // Option 2
              _buildOption(
                value: 2,
                title: 'Thu hồi với bạn',
                subtitle: 'Chúng tôi sẽ gỡ tin nhắn này ở phía bạn. Những người khác trong đoạn chat vẫn có thể xem được.',
              ),
              const SizedBox(height: 24),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0084FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () => Navigator.of(context).pop(_selectedValue),
                    child: const Text(
                      'Gỡ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required int value,
    required String title,
    required String subtitle,
  }) {
    final bool isSelected = _selectedValue == value;
    return InkWell(
      onTap: () => setState(() => _selectedValue = value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF0084FF) : Colors.white30,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RemoveMessageDialog extends StatelessWidget {
  const RemoveMessageDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const RemoveMessageDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Gỡ đối với bạn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3A3B3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Content
              const Text(
                'Chúng tôi sẽ gỡ tin nhắn này cho bạn. Những thành viên khác trong đoạn chat vẫn có thể xem được.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0084FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Gỡ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PinnedMessagesDialog extends ConsumerWidget {
  final ChatThread thread;

  const PinnedMessagesDialog({super.key, required this.thread});

  static Future<void> show(BuildContext context, ChatThread thread) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PinnedMessagesDialog(thread: thread),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedMessages = thread.messages.where((m) => m.isPinned).toList();
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;

    final String myAvatarUrl = (profile?.avatarUrl?.trim().isNotEmpty == true
            ? profile!.avatarUrl
            : metadata?['avatar_url'] ?? metadata?['avatarUrl'] ?? '')
        .toString()
        .trim();

    final String myName = (profile?.fullName?.trim().isNotEmpty == true
            ? profile!.fullName
            : profile?.username?.trim().isNotEmpty == true
                ? profile!.username
                : metadata?['full_name'] ?? metadata?['username'] ?? 'Bạn')
        .toString()
        .trim();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 520,
          height: 600,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tin nhắn đã ghim',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3A3B3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // List of Pinned Messages
              Expanded(
                child: pinnedMessages.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có tin nhắn nào được ghim',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        itemCount: pinnedMessages.length,
                        itemBuilder: (context, index) {
                          final message = pinnedMessages[index];
                          final bool isMe = message.senderId == 'me';
                          final String timeStr = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF3A3B3C),
                                  backgroundImage: isMe
                                      ? (myAvatarUrl.isNotEmpty ? NetworkImage(myAvatarUrl) : null)
                                      : (thread.avatarUrl != null && thread.avatarUrl!.isNotEmpty
                                          ? NetworkImage(thread.avatarUrl!)
                                          : null),
                                  child: isMe
                                      ? (myAvatarUrl.isEmpty
                                          ? Text(myName.isNotEmpty ? myName[0].toUpperCase() : 'B',
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                                          : null)
                                      : ((thread.avatarUrl == null || thread.avatarUrl!.isEmpty)
                                          ? Text(message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                                          : null),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            isMe ? 'Bạn' : message.senderName,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            timeStr,
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF303031),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              message.text,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (message.reactions.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 4),
                                              child: Wrap(
                                                spacing: 4,
                                                children: message.reactions.keys.map((emoji) {
                                                  return Text(
                                                    emoji,
                                                    style: const TextStyle(fontSize: 13),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
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
      ),
    );
  }
}

class ThemeSelectorDialog extends ConsumerStatefulWidget {
  final ChatThread thread;

  const ThemeSelectorDialog({super.key, required this.thread});

  static Future<void> show(BuildContext context, ChatThread thread) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ThemeSelectorDialog(thread: thread),
    );
  }

  @override
  ConsumerState<ThemeSelectorDialog> createState() => _ThemeSelectorDialogState();
}

class _ThemeSelectorDialogState extends ConsumerState<ThemeSelectorDialog> {
  String? _tempSelectedThemeId;

  Widget _buildThemeIcon(String id) {
    switch (id) {
      case 'default':
        return Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF0084FF), Color(0xFFA78BFA)],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF242526),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case 'supergirl':
        return Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFDC2626),
          ),
          child: const Center(
            child: Text(
              '⚡',
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      case 'avatar':
        return Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0D5C4B),
          ),
          child: const Center(
            child: Text(
              '💨',
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      case 'olivia':
        return Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE0B0FF),
          ),
          child: const Center(
            child: Text(
              '🦋',
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      case 'football':
        return Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1E3A8A),
          ),
          child: const Center(
            child: Icon(
              Icons.sports_soccer_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        );
      case 'backstage':
        return Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFAA7C11)],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.theater_comedy_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        );
      case 'deliboys':
        return Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF97316),
          ),
          child: const Center(
            child: Text(
              '🍔',
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      default:
        return const Icon(Icons.palette_rounded, color: Colors.white70);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeThemeId = ref.watch(threadThemeProvider)[widget.thread.id] ?? 'default';
    final selectedId = _tempSelectedThemeId ?? activeThemeId;
    final selectedTheme = availableChatThemes.firstWhere((t) => t.id == selectedId, orElse: () => availableChatThemes.first);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 800,
          height: 600,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Xem trước và chọn chủ đề',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3A3B3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Two-pane Layout
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Pane: Scrollable List of themes
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(right: 16),
                          itemCount: availableChatThemes.length,
                          itemBuilder: (context, index) {
                            final theme = availableChatThemes[index];
                            final isCurrent = theme.id == selectedId;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _tempSelectedThemeId = theme.id;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    _buildThemeIcon(theme.id),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            theme.displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (theme.subtitle != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              theme.subtitle!,
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (isCurrent)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF0084FF),
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // Right Pane: Preview area simulating a chat screen
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedTheme.accentColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          gradient: LinearGradient(
                            colors: selectedTheme.chatBackgroundGradient,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(),
                            
                            // Message 1 (sent by me)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 220),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: selectedTheme.senderGradient,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'Có rất nhiều chủ đề để bạn lựa chọn và những chủ đề này đều khác nhau đôi chút.',
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            
                            // Message 2 (sent by me)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 220),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: selectedTheme.senderGradient,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(4),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Tin nhắn mà bạn gửi cho người khác sẽ có màu này.',
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Message 3 (sent by recipient)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 220),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedTheme.recipientColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Tin nhắn của bạn bè sẽ tương tự như thế này.',
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            
                            // Timestamp below bubble
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Text(
                                  '13:47',
                                  style: TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ),
                            ),
                            const Spacer(),
                            
                            // Bottom helper text
                            const Text(
                              'Nhấp vào Chọn để chọn chủ đề này.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Hủy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(threadThemeProvider.notifier).setTheme(widget.thread.id, selectedId);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedTheme.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Chọn', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickReactionSelectorDialog extends ConsumerStatefulWidget {
  final ChatThread thread;

  const QuickReactionSelectorDialog({super.key, required this.thread});

  static Future<void> show(BuildContext context, ChatThread thread) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => QuickReactionSelectorDialog(thread: thread),
    );
  }

  @override
  ConsumerState<QuickReactionSelectorDialog> createState() => _QuickReactionSelectorDialogState();
}

class _QuickReactionSelectorDialogState extends ConsumerState<QuickReactionSelectorDialog> {
  String _searchQuery = '';
  String _activeCategory = 'smileys';

  final Map<String, List<String>> _emojiCategories = {
    'smileys': [
      '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣',
      '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰',
      '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜',
      '🤪', '🤨', '🧐', '🤓', '😎', '🥸', '🤩', '🥳',
      '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️',
      '😂', '😭', '🥺', '🥱', '😴', '😤', '😡', '🤬'
    ],
    'animals': [
      '🐱', '🐶', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
      '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔',
      '🐧', '🐦', '🦆', '🦅', '🦉', '🦇', '🐺', '🐗'
    ],
    'food': [
      '🍕', '🍔', '🍟', '🌭', '🍿', '🧂', '🥓', '🥚',
      '🍳', '🧇', '🥞', '🧈', '🍞', '🥐', '🥨', '🥯',
      '🥗', '🍣', '🍦', '🍩', '🍪', '🍫', '🍬', '🍭'
    ],
    'activities': [
      '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉',
      '🎱', '🪀', '🏓', '🏸', '🏒', '🏑', '🥍', '🏹',
      '⛳', '🪁', '🎣', '🥊', '🥋', '🛹', '🛷', '⛸️'
    ],
    'travel': [
      '🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑',
      '🚒', '🚐', '🛻', '🚚', '🚛', '🚜', '🛵', '🚲',
      '🛴', '🛹', '✈️', '⛵', '🚁', '🚀', '🛸', '🗺️'
    ],
    'objects': [
      '💡', '🔦', '🕯️', '🪔', '🗑️', '🛢️', '💸', '💵',
      '🪙', '💰', '💳', '💎', '⚖️', '🔑', '🔒', '🔓',
      '🎁', '🎈', '🎉', '🎊', '🧸', '✉️', '📦', '✏️'
    ],
    'symbols': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
      '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉️', '☸️'
    ],
    'flags': [
      '🏁', '🚩', '🎌', '🏴', '🏳️', '🏳️‍🌈', '🏳️‍⚧️', '🏴‍☠️',
      '🇻🇳', '🇺🇸', '🇬🇧', '🇯🇵', '🇰🇷', '🇨🇳', '🇫🇷', '🇩🇪',
      '🇮🇹', '🇪🇸', '🇨🇦', '🇦🇺', '🇷🇺', '🇧🇷', '🇮🇳', '🇲🇽'
    ],
  };

  String _getCategoryTitle(String cat) {
    switch (cat) {
      case 'smileys':
        return 'Mặt cười và hình người';
      case 'animals':
        return 'Động vật và thiên nhiên';
      case 'food':
        return 'Ẩm thực';
      case 'activities':
        return 'Hoạt động';
      case 'travel':
        return 'Du lịch và địa điểm';
      case 'objects':
        return 'Đồ vật';
      case 'symbols':
        return 'Biểu tượng';
      case 'flags':
        return 'Cờ';
      default:
        return 'Biểu tượng cảm xúc';
    }
  }

  Widget _buildCategoryTabIcon(String cat, bool isActive) {
    final activeColor = const Color(0xFF0084FF);
    final inactiveColor = Colors.white38;
    final color = isActive ? activeColor : inactiveColor;

    switch (cat) {
      case 'smileys':
        return Icon(Icons.emoji_emotions_outlined, color: color, size: 20);
      case 'animals':
        return Icon(Icons.pets_rounded, color: color, size: 20);
      case 'food':
        return Icon(Icons.restaurant_rounded, color: color, size: 20);
      case 'activities':
        return Icon(Icons.sports_soccer_rounded, color: color, size: 20);
      case 'travel':
        return Icon(Icons.directions_car_rounded, color: color, size: 20);
      case 'objects':
        return Icon(Icons.lightbulb_outline_rounded, color: color, size: 20);
      case 'symbols':
        return Icon(Icons.favorite_border_rounded, color: color, size: 20);
      case 'flags':
        return Icon(Icons.flag_outlined, color: color, size: 20);
      default:
        return Icon(Icons.category_outlined, color: color, size: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> displayedEmojis = [];
    if (_searchQuery.trim().isEmpty) {
      displayedEmojis = _emojiCategories[_activeCategory] ?? [];
    } else {
      final query = _searchQuery.toLowerCase();
      // Simple lookup across all categories
      for (final catList in _emojiCategories.values) {
        for (final emoji in catList) {
          if (emoji.contains(query) || query == '') {
            displayedEmojis.add(emoji);
          }
        }
      }
      // If we didn't find matches by characters, just show those matching query string
      if (displayedEmojis.isEmpty) {
        displayedEmojis = _emojiCategories.values.expand((x) => x).take(40).toList();
      }
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 440,
          height: 480,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      'Biểu tượng cảm xúc',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3A3B3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Bar
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3B3C),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm biểu tượng cảm xúc',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category Header
              Text(
                _searchQuery.trim().isNotEmpty
                    ? 'Kết quả tìm kiếm'
                    : _getCategoryTitle(_activeCategory),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // Grid list of emojis
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: displayedEmojis.length,
                  itemBuilder: (context, index) {
                    final emoji = displayedEmojis[index];
                    return GestureDetector(
                      onTap: () {
                        ref.read(threadQuickReactionProvider.notifier).setQuickReaction(widget.thread.id, emoji);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Bottom Category Tabs Bar
              if (_searchQuery.trim().isEmpty) ...[
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _emojiCategories.keys.map((cat) {
                    final isActive = cat == _activeCategory;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _activeCategory = cat;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: _buildCategoryTabIcon(cat, isActive),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NicknamesDialog extends ConsumerStatefulWidget {
  final ChatThread thread;

  const NicknamesDialog({super.key, required this.thread});

  static Future<void> show(BuildContext context, ChatThread thread) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => NicknamesDialog(thread: thread),
    );
  }

  @override
  ConsumerState<NicknamesDialog> createState() => _NicknamesDialogState();
}

class _NicknamesDialogState extends ConsumerState<NicknamesDialog> {
  String? _editingUserId;
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;

    final String myName = (profile?.fullName?.trim().isNotEmpty == true
            ? profile!.fullName
            : profile?.username?.trim().isNotEmpty == true
                ? profile!.username
                : metadata?['full_name'] ?? metadata?['username'] ?? 'Bạn')
        .toString()
        .trim();

    final String myAvatarUrl = (profile?.avatarUrl?.trim().isNotEmpty == true
            ? profile!.avatarUrl
            : metadata?['avatar_url'] ?? metadata?['avatarUrl'] ?? '')
        .toString()
        .trim();

    final String friendId = widget.thread.recipientId ?? 'friend';
    final nicknamesMap = ref.watch(threadNicknamesProvider)[widget.thread.id] ?? {};
    
    final myNickname = nicknamesMap['me'] ?? '';
    final friendNickname = nicknamesMap[friendId] ?? '';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      'Biệt danh',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3A3B3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // User Row (Bạn)
              _buildParticipantRow(
                userId: 'me',
                originalName: myName,
                avatarUrl: myAvatarUrl,
                avatarInitials: 'ME',
                currentNickname: myNickname,
              ),
              const SizedBox(height: 16),

              // Friend Row
              _buildParticipantRow(
                userId: friendId,
                originalName: widget.thread.name,
                avatarUrl: widget.thread.avatarUrl,
                avatarInitials: widget.thread.avatarInitials,
                currentNickname: friendNickname,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantRow({
    required String userId,
    required String originalName,
    required String? avatarUrl,
    required String avatarInitials,
    required String currentNickname,
  }) {
    final isEditing = _editingUserId == userId;

    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF3A3B3C),
          backgroundImage: avatarUrl != null && avatarUrl.trim().isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl == null || avatarUrl.trim().isEmpty
              ? Text(
                  avatarInitials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                )
              : null,
        ),
        const SizedBox(width: 14),

        // Text & Input Pane
        Expanded(
          child: isEditing
              ? Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3B3C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0084FF), width: 1.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _nicknameController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action Buttons (Save/Cancel)
                    IconButton(
                      onPressed: () {
                        ref.read(threadNicknamesProvider.notifier).setNickname(
                              widget.thread.id,
                              userId,
                              _nicknameController.text,
                            );
                        setState(() {
                          _editingUserId = null;
                        });
                      },
                      icon: const Icon(Icons.check_rounded, color: Colors.green, size: 20),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _editingUserId = null;
                        });
                      },
                      icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentNickname.isNotEmpty ? currentNickname : originalName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentNickname.isNotEmpty ? originalName : 'Đặt biệt danh',
                      style: TextStyle(
                        color: currentNickname.isNotEmpty ? Colors.white38 : const Color(0xFF0084FF),
                        fontSize: 12,
                        fontWeight: currentNickname.isNotEmpty ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),

        // Pencil Edit Icon
        if (!isEditing)
          IconButton(
            onPressed: () {
              setState(() {
                _editingUserId = userId;
                _nicknameController.text = currentNickname;
              });
            },
            icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
          ),
      ],
    );
  }
}

class MuteNotificationsDialog extends StatefulWidget {
  final ChatThread thread;

  const MuteNotificationsDialog({super.key, required this.thread});

  static Future<String?> show(BuildContext context, ChatThread thread) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => MuteNotificationsDialog(thread: thread),
    );
  }

  @override
  State<MuteNotificationsDialog> createState() => _MuteNotificationsDialogState();
}

class _MuteNotificationsDialogState extends State<MuteNotificationsDialog> {
  String _selectedOption = '15m';

  Widget _buildRadioRow(String option, String text) {
    final isSelected = _selectedOption == option;
    return InkWell(
      onTap: () => setState(() => _selectedOption = option),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0084FF) : Colors.white38,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: isSelected
                  ? Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0084FF),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      'Tắt thông báo về cuộc trò chuyện',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Options
              _buildRadioRow('15m', 'Trong 15 phút'),
              _buildRadioRow('1h', 'Trong 1 giờ'),
              _buildRadioRow('8h', 'Trong 8 giờ'),
              _buildRadioRow('24h', 'Trong 24 giờ'),
              _buildRadioRow('until_on', 'Đến khi tôi bật lại'),
              
              const SizedBox(height: 16),
              const Text(
                'Cửa sổ chat vẫn đóng và bạn sẽ không nhận được thông báo đẩy trên thiết bị.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Hủy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_selectedOption),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0084FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Tắt thông báo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DisappearingMessagesDialog extends ConsumerStatefulWidget {
  final ChatThread thread;

  const DisappearingMessagesDialog({super.key, required this.thread});

  static Future<void> show(BuildContext context, ChatThread thread) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DisappearingMessagesDialog(thread: thread),
    );
  }

  @override
  ConsumerState<DisappearingMessagesDialog> createState() => _DisappearingMessagesDialogState();
}

class _DisappearingMessagesDialogState extends ConsumerState<DisappearingMessagesDialog> {
  String _selectedVal = 'off';

  @override
  void initState() {
    super.initState();
    final currentVal = ref.read(threadDisappearingMessagesProvider)[widget.thread.id] ?? 'off';
    _selectedVal = currentVal;
  }

  Widget _buildRadioRow(String val, String text) {
    final isSelected = _selectedVal == val;
    return InkWell(
      onTap: () => setState(() => _selectedVal = val),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0084FF) : Colors.white38,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: isSelected
                  ? Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0084FF),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      'Tin nhắn tự hủy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3A3B3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description with blue link
              RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
                  children: [
                    TextSpan(text: 'Khi tính năng tin nhắn tự hủy đang bật, tin nhắn mới sẽ biến mất đối với mọi người trong đoạn chat sau 24 giờ kể từ thời điểm gửi. '),
                    TextSpan(
                      text: 'Tìm hiểu thêm',
                      style: TextStyle(color: Color(0xFF0084FF), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Options
              _buildRadioRow('off', 'Tắt'),
              _buildRadioRow('24h', '24 giờ'),
              const SizedBox(height: 24),

              // Bottom Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Hủy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(threadDisappearingMessagesProvider.notifier).setDisappearingMessages(widget.thread.id, _selectedVal);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedVal != 'off'
                            ? const Color(0xFF0084FF)
                            : Colors.white.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Xong', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RestrictDialog extends ConsumerWidget {
  final ChatThread thread;

  const RestrictDialog({super.key, required this.thread});

  static Future<void> show(BuildContext context, ChatThread thread) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => RestrictDialog(thread: thread),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendId = thread.recipientId ?? 'friend';
    final nicknamesMap = ref.watch(threadNicknamesProvider)[thread.id] ?? {};
    final friendName = nicknamesMap[friendId] ?? thread.name;

    final shortName = friendName.split(' ').first;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3A3B3C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),

              // Centered Avatar
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF3A3B3C),
                  backgroundImage: thread.avatarUrl != null && thread.avatarUrl!.isNotEmpty
                      ? NetworkImage(thread.avatarUrl!)
                      : null,
                  child: thread.avatarUrl == null || thread.avatarUrl!.isEmpty
                      ? Text(
                          thread.avatarInitials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Ẩn bớt nội dung về $shortName mà không chặn họ',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Bullet Rows
              _buildDetailRow(
                Icons.visibility_off_outlined,
                'Ẩn đoạn chat',
                'Gỡ cuộc trò chuyện khỏi hộp thư để không nhận thông báo về tin nhắn nữa.',
              ),
              _buildDetailRow(
                Icons.chat_bubble_outline_rounded,
                'Ẩn hoạt động của bạn',
                'Họ sẽ không biết khi nào bạn đọc tin nhắn hay Trạng thái hoạt động của bạn.',
              ),
              _buildDetailRow(
                Icons.undo_rounded,
                'Bỏ hạn chế bất cứ lúc nào',
                'Họ sẽ không nhận được thông báo rằng bạn đã hạn chế họ. Bạn có thể bỏ hạn chế trong phần cài đặt quyền riêng tư.',
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0084FF),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0084FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      'Hạn chế $shortName',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlockDialog extends ConsumerWidget {
  final ChatThread thread;

  const BlockDialog({super.key, required this.thread});

  static Future<void> show(BuildContext context, ChatThread thread) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => BlockDialog(thread: thread),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 5, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockOptionRow({
    required BuildContext context,
    required Widget leadingIcon,
    required String title,
    required List<String> bullets,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leadingIcon,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...bullets.map((b) => _buildBulletPoint(b)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Align(
              alignment: Alignment.center,
              child: Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendId = thread.recipientId ?? 'friend';
    final nicknamesMap = ref.watch(threadNicknamesProvider)[thread.id] ?? {};
    final friendName = nicknamesMap[friendId] ?? thread.name;

    final shortName = friendName.split(' ').first;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 540,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Chặn $friendName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 16),

              // Option 1: Block messenger
              _buildBlockOptionRow(
                context: context,
                leadingIcon: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3A3B3C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                ),
                title: 'Chặn tin nhắn và cuộc gọi',
                bullets: [
                  'Tài khoản Facebook của bạn sẽ không nhận được tin nhắn hoặc cuộc gọi từ tài khoản Facebook của $shortName.',
                  'Tài khoản này sẽ không bị chặn trên Facebook. Bạn vẫn có thể xem bài viết, bình luận và cảm xúc của $shortName trên Facebook.',
                  'Nếu tham gia cùng nhóm hoặc phòng họp mặt, bạn và tài khoản này vẫn có thể nhìn thấy cũng như trò chuyện với nhau. Bạn có thể rời khỏi nhóm hoặc phòng họp mặt bất cứ lúc nào.',
                ],
                onTap: () async {
                  final didConfirm = await BlockConfirmationDialog.show(context, thread);
                  if (didConfirm == true) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Block Facebook
              _buildBlockOptionRow(
                context: context,
                leadingIcon: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3A3B3C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.facebook_rounded, color: Colors.white, size: 24),
                ),
                title: 'Chặn trên Facebook',
                bullets: [
                  'Nếu các bạn là bạn bè, việc chặn $shortName cũng sẽ hủy kết bạn với họ.',
                  'Tin nhắn và cuộc gọi của $shortName cũng sẽ bị chặn.',
                  'Facebook sẽ không cho họ biết là bạn đã chặn họ.',
                ],
                onTap: () async {
                  final didConfirm = await BlockFacebookConfirmationDialog.show(context, thread);
                  if (didConfirm == true) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 20),

              // Bottom Button
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text(
                  'Tìm hiểu thêm về tính năng chặn',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlockConfirmationDialog extends ConsumerWidget {
  final ChatThread thread;

  const BlockConfirmationDialog({super.key, required this.thread});

  static Future<bool?> show(BuildContext context, ChatThread thread) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => BlockConfirmationDialog(thread: thread),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendId = thread.recipientId ?? 'friend';
    final nicknamesMap = ref.watch(threadNicknamesProvider)[thread.id] ?? {};
    final friendName = nicknamesMap[friendId] ?? thread.name;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Block $friendName?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn sẽ không nhận được tin nhắn hay cuộc gọi của họ trên Messenger.',
                style: TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0084FF),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Hủy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0084FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text('Chặn', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlockFacebookConfirmationDialog extends ConsumerWidget {
  final ChatThread thread;

  const BlockFacebookConfirmationDialog({super.key, required this.thread});

  static Future<bool?> show(BuildContext context, ChatThread thread) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => BlockFacebookConfirmationDialog(thread: thread),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendId = thread.recipientId ?? 'friend';
    final nicknamesMap = ref.watch(threadNicknamesProvider)[thread.id] ?? {};
    final friendName = nicknamesMap[friendId] ?? thread.name;

    final shortName = friendName.split(' ').first;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      'Chặn trên Facebook?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Bạn và $shortName sẽ không phải là bạn bè trên Facebook. Tin nhắn và cuộc gọi của $shortName cũng sẽ bị chặn.',
                style: const TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0084FF),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Hủy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0084FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text('Chặn', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportDialog extends ConsumerWidget {
  final ChatThread thread;

  const ReportDialog({super.key, required this.thread});

  static Future<void> show(BuildContext context, ChatThread thread) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ReportDialog(thread: thread),
    );
  }

  Widget _buildCategoryRow(BuildContext context, String title) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nicknamesMap = ref.watch(threadNicknamesProvider)[thread.id] ?? {};
    final myNickname = nicknamesMap['me'] ?? '';
    final nameToUse = myNickname.isNotEmpty ? myNickname.split(' ').first : 'Bạn';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: const Color(0xFF242526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      'Chọn vấn đề bạn muốn báo cáo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3A3B3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'We won\'t let the person know who reported them.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Localized Warning Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white70, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$nameToUse ơi, nếu bạn nhận thấy ai đó đang gặp nguy hiểm, đừng chần chừ mà hãy báo ngay cho dịch vụ khẩn cấp tại địa phương.',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Categories List
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCategoryRow(context, 'Quấy rối'),
                      _buildCategoryRow(context, 'Tự tử hoặc tự gây thương tích'),
                      _buildCategoryRow(context, 'Giả mạo người khác'),
                      _buildCategoryRow(context, 'Hành vi bạo lực hoặc tổ chức nguy hiểm'),
                      _buildCategoryRow(context, 'Ảnh khỏa thân hoặc hoạt động tình dục'),
                      _buildCategoryRow(context, 'Bán hoặc quảng bá mặt hàng bị hạn chế'),
                      _buildCategoryRow(context, 'Lừa đảo hoặc gian lận'),
                      _buildCategoryRow(context, 'Khác'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
