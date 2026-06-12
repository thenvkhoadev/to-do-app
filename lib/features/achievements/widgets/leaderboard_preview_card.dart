import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class LeaderboardPreviewCard extends ConsumerWidget {
  const LeaderboardPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allUsersAsync = ref.watch(allUsersProvider);
    final currentUser = ref.watch(userProfileProvider).valueOrNull;

    return Container(
      padding: const EdgeInsets.all(DashboardSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(DashboardRadii.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Leaderboard',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DashboardColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'GLOBAL',
                  style: TextStyle(
                    color: DashboardColors.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          allUsersAsync.when(
            data: (users) {
              // Copy and sort users by XP descending
              final sortedUsers = List<UserProfileModel>.from(users)
                ..sort((a, b) => b.totalXp.compareTo(a.totalXp));

              // Take top 5
              final topUsers = sortedUsers.take(5).toList();

              return Column(
                children: List.generate(topUsers.length, (index) {
                  final user = topUsers[index];
                  final isMe = currentUser != null && user.id == currentUser.id;
                  final displayName = user.fullName ?? user.username ?? 'User';
                  final initial = displayName.trim().isEmpty ? '?' : displayName.characters.first.toUpperCase();

                  // Rank icon or text
                  Widget rankWidget;
                  if (index == 0) {
                    rankWidget = const Text('🥇', style: TextStyle(fontSize: 18));
                  } else if (index == 1) {
                    rankWidget = const Text('🥈', style: TextStyle(fontSize: 18));
                  } else if (index == 2) {
                    rankWidget = const Text('🥉', style: TextStyle(fontSize: 18));
                  } else {
                    rankWidget = SizedBox(
                      width: 24,
                      child: Text(
                        '#${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? DashboardColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isMe
                          ? Border.all(color: DashboardColors.primary.withValues(alpha: 0.25))
                          : null,
                    ),
                    child: Row(
                      children: [
                        rankWidget,
                        const SizedBox(width: 12),
                        // Avatar
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isMe ? DashboardColors.primary : Colors.white24,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? Image.network(
                                    user.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _FallbackAvatar(initial: initial),
                                  )
                                : _FallbackAvatar(initial: initial),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isMe ? DashboardColors.primary : DashboardColors.onSurface,
                              fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Level / XP
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Lvl ${user.level}',
                              style: const TextStyle(
                                color: DashboardColors.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${user.totalXp} XP',
                              style: const TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (err, stack) => const Text(
              'Failed to load leaderboard.',
              style: TextStyle(color: DashboardColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DashboardColors.surfaceLow,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
