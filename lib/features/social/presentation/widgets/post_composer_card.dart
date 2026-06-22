import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/theme/design_tokens.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/social/presentation/widgets/post_composer_modal.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class PostComposerCard extends ConsumerWidget {
  const PostComposerCard({super.key});

  void _openComposer(BuildContext context, {int initialTab = 0}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PostComposerModal',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return PostComposerModal(initialTab: initialTab);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: curve,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              profileAsync.when(
                data: (profile) => CircleAvatar(
                  radius: 20,
                  backgroundImage: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  backgroundColor: Colors.grey.shade900,
                  child: profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                loading: () => const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
                error: (_, __) => const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openComposer(context, initialTab: 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .04),
                      border: Border.all(color: Colors.white.withValues(alpha: .06)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'Bạn đang nghĩ gì? Chia sẻ tiến độ...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: DesignTokens.borderSubtle, height: 1),
          const SizedBox(height: 10),
          // Composer Action tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildComposerTab(
                icon: Icons.photo_rounded,
                label: 'Ảnh',
                color: const Color(0xFF8B5CF6),
                onTap: () => _openComposer(context, initialTab: 0), // Image upload in tab 0 or custom flow
              ),
              _buildComposerTab(
                icon: Icons.check_circle_outline_rounded,
                label: 'Task',
                color: const Color(0xFF3B82F6),
                onTap: () => _openComposer(context, initialTab: 1),
              ),
              _buildComposerTab(
                icon: Icons.military_tech_rounded,
                label: 'Thành tích',
                color: const Color(0xFF10B981),
                onTap: () => _openComposer(context, initialTab: 2),
              ),
              _buildComposerTab(
                icon: Icons.bar_chart_rounded,
                label: 'Khảo sát',
                color: const Color(0xFFEF4444),
                onTap: () => _openComposer(context, initialTab: 3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComposerTab({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
