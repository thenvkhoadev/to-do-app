import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
