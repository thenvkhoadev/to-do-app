import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/social/presentation/providers/story_state_providers.dart';

class StoryPrivacyModal extends ConsumerStatefulWidget {
  const StoryPrivacyModal({super.key});

  @override
  ConsumerState<StoryPrivacyModal> createState() => _StoryPrivacyModalState();
}

class _StoryPrivacyModalState extends ConsumerState<StoryPrivacyModal> {
  late String _selectedPrivacy;

  @override
  void initState() {
    super.initState();
    _selectedPrivacy = ref.read(storyPrivacyProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF242526),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quyền riêng tư của tin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // Body Description
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ai có thể xem tin của bạn?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tin hiển thị trong 24 giờ.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // Option 1: Công khai
            _buildOption(
              value: 'public',
              icon: Icons.public_rounded,
              title: 'Công khai',
              description: 'Bất kỳ ai trên NEXUS AI hoặc Messenger',
            ),
            const Divider(color: Colors.white10, height: 1),

            // Option 2: Bạn bè
            _buildOption(
              value: 'friends',
              icon: Icons.people_alt_rounded,
              title: 'Bạn bè',
              description: 'Chỉ bạn bè của bạn',
            ),
            const Divider(color: Colors.white10, height: 1),

            // Option 3: Tuỳ chỉnh
            _buildOption(
              value: 'custom',
              icon: Icons.person_rounded,
              title: 'Tuỳ chỉnh',
              description: 'Chọn đối tượng cho tin của bạn',
            ),
            const Divider(color: Colors.white12, height: 1),

            // Footer Note
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Text(
                'Chỉ bạn bè và quan hệ kết nối mới có thể trực tiếp trả lời tin bạn đăng.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // Footer Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Huỷ',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(storyPrivacyProvider.notifier).state = _selectedPrivacy;
                      Navigator.pop(context, _selectedPrivacy);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C5CFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: const Text(
                      'Lưu',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String value,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedPrivacy == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPrivacy = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .06),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPrivacy,
              activeColor: const Color(0xFF7C5CFF),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedPrivacy = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
