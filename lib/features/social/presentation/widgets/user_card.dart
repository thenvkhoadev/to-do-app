import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/social/data/models/friendship_model.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class UserCard extends ConsumerWidget {
  const UserCard({super.key, required this.user, this.onTap});

  final UserProfileModel user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(friendshipStatusProvider(user.id));
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final loadingMap = ref.watch(socialActionLoadingProvider);
    final isLoading = loadingMap[user.id] ?? false;

    Widget buildButton() {
      if (currentUser == null) return const SizedBox.shrink();
      if (isLoading) {
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DashboardColors.primary,
          ),
        );
      }

      switch (status) {
        case FriendshipStatus.none:
          return GradientButton(
            label: 'Thêm bạn bè',
            icon: Icons.person_add_rounded,
            onPressed:
                () => _handleAction(ref, currentUser.id, user.id, 'add'),
          );
        case FriendshipStatus.pendingSent:
          return OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: .08)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed:
                () => _handleAction(ref, currentUser.id, user.id, 'cancel'),
            child: const Text(
              '⏳ Huỷ',
              style: TextStyle(color: DashboardColors.outline, fontSize: 12),
            ),
          );
        case FriendshipStatus.pendingReceived:
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GradientButton(
                label: 'Xác nhận',
                icon: Icons.check_rounded,
                onPressed:
                    () => _handleAction(
                      ref,
                      currentUser.id,
                      user.id,
                      'accept',
                    ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: DashboardColors.error,
                  size: 18,
                ),
                onPressed:
                    () => _handleAction(
                      ref,
                      currentUser.id,
                      user.id,
                      'reject',
                    ),
              ),
            ],
          );
        case FriendshipStatus.friends:
          return OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: DashboardColors.success.withValues(alpha: .2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () {},
            child: const Text(
              '✓ Bạn bè',
              style: TextStyle(color: DashboardColors.success, fontSize: 12),
            ),
          );
        case FriendshipStatus.blocked:
          return const Text(
            'Đã chặn',
            style: TextStyle(color: DashboardColors.outline, fontSize: 12),
          );
      }
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: DashboardColors.surfaceHigh,
                backgroundImage:
                    user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                child:
                    user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? Text(
                          user.fullName?.isNotEmpty == true
                              ? user.fullName!.characters.first.toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                        : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.fullName ?? 'User',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: DashboardColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lv.${user.level} · ${user.rankTitle}',
                style: TextStyle(
                  color: DashboardColors.primary.withValues(alpha: .85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '🔥 Streak: ${user.streakDays}d',
                style: const TextStyle(
                  color: DashboardColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              buildButton(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    WidgetRef ref,
    String currentUserId,
    String otherUserId,
    String action,
  ) async {
    ref.read(socialActionLoadingProvider.notifier).update((state) =>
        {...state, otherUserId: true});
    try {
      final ds = ref.read(socialRemoteDataSourceProvider);
      switch (action) {
        case 'add':
          await ds.sendFriendRequest(currentUserId, otherUserId);
          break;
        case 'cancel':
        case 'reject':
          await ds.deleteFriendship(currentUserId, otherUserId);
          break;
        case 'accept':
          await ds.acceptFriendRequest(currentUserId, otherUserId);
          break;
      }
      ref.invalidate(friendshipsStreamProvider);
    } catch (_) {} finally {
      ref.read(socialActionLoadingProvider.notifier).update((state) =>
          {...state, otherUserId: false});
    }
  }
}
