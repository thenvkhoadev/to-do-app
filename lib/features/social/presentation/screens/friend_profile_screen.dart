import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/social/data/models/friendship_model.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';

class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({super.key, required this.profile, this.onBack});

  final UserProfileModel profile;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(friendshipStatusProvider(profile.id));
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final loadingMap = ref.watch(socialActionLoadingProvider);
    final isLoading = loadingMap[profile.id] ?? false;

    Widget buildActionButtons() {
      if (currentUser == null) return const SizedBox.shrink();
      if (isLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: DashboardColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      }

      switch (status) {
        case FriendshipStatus.none:
          return GradientButton(
            label: 'Thêm bạn bè',
            icon: Icons.person_add_rounded,
            onPressed:
                () => _handleAction(ref, currentUser.id, profile.id, 'add'),
          );
        case FriendshipStatus.pendingSent:
          return OutlinedButton.icon(
            icon: const Icon(
              Icons.hourglass_empty_rounded,
              color: DashboardColors.outline,
              size: 16,
            ),
            label: const Text(
              '⏳ Huỷ lời mời',
              style: TextStyle(color: DashboardColors.outline, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: .08)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed:
                () => _handleAction(ref, currentUser.id, profile.id, 'cancel'),
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
                      profile.id,
                      'accept',
                    ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.close_rounded,
                  color: DashboardColors.error,
                  size: 16,
                ),
                label: const Text(
                  'Xoá',
                  style: TextStyle(color: DashboardColors.error, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: DashboardColors.error.withValues(alpha: .24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed:
                    () => _handleAction(
                      ref,
                      currentUser.id,
                      profile.id,
                      'reject',
                    ),
              ),
            ],
          );
        case FriendshipStatus.friends:
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.check_rounded,
                  color: DashboardColors.success,
                  size: 16,
                ),
                label: const Text(
                  '✓ Bạn bè',
                  style:
                      TextStyle(color: DashboardColors.success, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: DashboardColors.success.withValues(alpha: .24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              GradientButton(
                label: 'Nhắn tin',
                icon: Icons.chat_bubble_rounded,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(
                  Icons.person_remove_rounded,
                  color: DashboardColors.error,
                ),
                onPressed:
                    () => _handleAction(
                      ref,
                      currentUser.id,
                      profile.id,
                      'unfriend',
                    ),
              ),
            ],
          );
        case FriendshipStatus.blocked:
          return TextButton(
            child: const Text(
              'Mở chặn',
              style: TextStyle(color: DashboardColors.primary),
            ),
            onPressed:
                () => _handleAction(ref, currentUser.id, profile.id, 'unblock'),
          );
      }
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 180,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7C5CFF), Color(0xFFA78BFA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: onBack != null
                          ? Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withValues(
                                  alpha: .4,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: onBack,
                                ),
                              ),
                            ),
                          )
                          : null,
                    ),
                    Positioned(
                      bottom: -60,
                      left: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DashboardColors.background,
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: DashboardColors.surfaceHigh,
                          backgroundImage:
                              profile.avatarUrl != null &&
                                      profile.avatarUrl!.isNotEmpty
                                  ? NetworkImage(profile.avatarUrl!)
                                  : null,
                          child:
                              profile.avatarUrl == null ||
                                      profile.avatarUrl!.isEmpty
                                  ? Text(
                                    profile.fullName?.isNotEmpty == true
                                        ? profile
                                            .fullName!
                                            .characters
                                            .first
                                            .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 72),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                profile.fullName ?? 'User',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: DashboardColors.onSurface,
                                  letterSpacing: -.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (profile.role == 'admin')
                                const _Badge(
                                  label: 'ADMIN',
                                  color: DashboardColors.secondary,
                                )
                              else if (profile.tier == 'pro')
                                const _Badge(
                                  label: 'PRO',
                                  color: DashboardColors.primary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${profile.username ?? 'user'}',
                            style: const TextStyle(
                              color: DashboardColors.outline,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Level ${profile.level} · ${profile.rankTitle}',
                            style: const TextStyle(
                              color: DashboardColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      buildActionButtons(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _IntroCard(profile: profile),
                            const SizedBox(height: 20),
                            _SkillsCard(coreTech: profile.coreTech),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _StatsGrid(profile: profile),
                            const SizedBox(height: 20),
                            _BioCard(bio: profile.bio),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
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
        case 'unfriend':
          await ds.deleteFriendship(currentUserId, otherUserId);
          break;
        case 'accept':
          await ds.acceptFriendRequest(currentUserId, otherUserId);
          break;
        case 'block':
          await ds.blockUser(currentUserId, otherUserId);
          break;
        case 'unblock':
          await ds.unblockUser(currentUserId, otherUserId);
          break;
      }
      ref.invalidate(friendshipsStreamProvider);
    } catch (_) {} finally {
      ref.read(socialActionLoadingProvider.notifier).update((state) =>
          {...state, otherUserId: false});
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.profile});
  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giới thiệu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _IntroRow(
            icon: Icons.work_outline_rounded,
            text: profile.occupation ?? 'Developer',
          ),
          const SizedBox(height: 12),
          _IntroRow(
            icon: Icons.location_on_outlined,
            text: profile.locationNode ?? 'Việt Nam',
          ),
          const SizedBox(height: 12),
          const _IntroRow(
            icon: Icons.calendar_month_outlined,
            text: 'Tham gia gần đây',
          ),
        ],
      ),
    );
  }
}

class _IntroRow extends StatelessWidget {
  const _IntroRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DashboardColors.outline),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.coreTech});
  final List<String> coreTech;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Kỹ năng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (coreTech.isEmpty)
            const Text(
              'Chưa cập nhật kỹ năng',
              style: TextStyle(color: DashboardColors.outline, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  coreTech
                      .map(
                        (tech) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DashboardColors.surfaceLow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .04),
                            ),
                          ),
                          child: Text(
                            tech.toUpperCase(),
                            style: const TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }
}

class _BioCard extends StatelessWidget {
  const _BioCard({required this.bio});
  final String? bio;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Giới thiệu bản thân',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bio?.isNotEmpty == true ? bio! : 'Chưa có thông tin giới thiệu.',
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.profile});
  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final myTotalXp =
        profile.totalXp > 0
            ? profile.totalXp
            : (profile.completedTasks * 50 +
                profile.focusHours * 10 +
                profile.streakDays * 20);

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _StatChip(value: '$myTotalXp', label: 'XP TOTAL'),
        _StatChip(value: '${profile.streakDays} DAYS', label: 'STREAK'),
        _StatChip(value: '${profile.completedTasks}', label: 'TASKS'),
        _StatChip(value: '${profile.focusHours}h', label: 'FOCUS HOURS'),
        _StatChip(value: '${profile.focusScore}', label: 'FOCUS SCORE'),
        _StatChip(value: '${profile.deepWorkPercent}%', label: 'DEEP WORK'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: DashboardColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: DashboardColors.outline,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }
}
