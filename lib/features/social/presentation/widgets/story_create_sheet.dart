import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:to_do_app/theme/design_tokens.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';

class StoryCreateSheet extends ConsumerWidget {
  const StoryCreateSheet({
    super.key,
    required this.onCreatePhotoStory,
    required this.onCreateTaskStory,
    required this.onCreateStreakStory,
    required this.onCreateAchievementStory,
  });

  final Future<void> Function(XFile file) onCreatePhotoStory;
  final Future<void> Function(int taskCount, int xp) onCreateTaskStory;
  final Future<void> Function(int streakCount) onCreateStreakStory;
  final Future<void> Function(String title, String desc) onCreateAchievementStory;

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        // Show loading dialog
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        await onCreatePhotoStory(image);
        if (context.mounted) {
          Navigator.pop(context); // Pop loading dialog
          Navigator.pop(context); // Pop bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đăng tin hình ảnh thành công!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusCard)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tạo tin mới',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Option List
          _buildOptionItem(
            context,
            icon: Icons.photo_camera_back_rounded,
            title: 'Đăng ảnh từ thiết bị',
            subtitle: 'Chọn một bức ảnh đẹp từ thư viện của bạn',
            color: const Color(0xFF8B5CF6),
            onTap: () => _pickImage(context),
          ),
          const SizedBox(height: 12),
          profileAsync.when(
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOptionItem(
                    context,
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Tin hoàn thành công việc hôm nay',
                    subtitle: 'Chia sẻ tiến độ: ${profile.completedTasks} công việc (+${profile.completedTasks * 10} XP)',
                    color: const Color(0xFF3B82F6),
                    onTap: () async {
                      Navigator.pop(context);
                      await onCreateTaskStory(profile.completedTasks, profile.completedTasks * 10);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildOptionItem(
                    context,
                    icon: Icons.local_fire_department_rounded,
                    title: 'Tin chuỗi năng suất (Streak)',
                    subtitle: 'Chia sẻ cột mốc duy trì tập trung: ${profile.streakDays} ngày',
                    color: const Color(0xFFEF4444),
                    onTap: () async {
                      Navigator.pop(context);
                      await onCreateStreakStory(profile.streakDays);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildOptionItem(
                    context,
                    icon: Icons.military_tech_rounded,
                    title: 'Tin thành tích nổi bật',
                    subtitle: 'Chia sẻ danh hiệu hiện tại: ${profile.rankTitle}',
                    color: const Color(0xFF10B981),
                    onTap: () async {
                      Navigator.pop(context);
                      await onCreateAchievementStory(
                        'Danh hiệu ${profile.rankTitle}',
                        'Hoạt động tích cực đạt cấp độ ${profile.level}',
                      );
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .04),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: .4),
            ),
          ],
        ),
      ),
    );
  }
}
