import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/features/streak/presentation/widgets/streak_topbar_button.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_enhancement_widgets.dart';

class TaskEditMobileNavBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const TaskEditMobileNavBar({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final profile = ref.watch(userProfileProvider).valueOrNull;

    final name =
        (profile?.fullName?.trim().isNotEmpty == true
                ? profile!.fullName
                : profile?.username?.trim().isNotEmpty == true
                ? profile!.username
                : metadata?['full_name'] ??
                    metadata?['username'] ??
                    user?.email ??
                    '?')
            .toString();

    final avatarUrl =
        (profile?.avatarUrl?.trim().isNotEmpty == true
                ? profile!.avatarUrl
                : metadata?['avatar_url'] ?? metadata?['avatarUrl'] ?? '')
            .toString()
            .trim();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: DashboardColors.surface.withValues(alpha: .5),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: DashboardColors.onSurface,
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Edit Task',
                      style: TextStyle(
                        color: DashboardColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const StreakTopbarButton(),
                    const SizedBox(width: 8),
                    const XPLevelCard(compact: true),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Open profile',
                      child: InkWell(
                        onTap: () => context.push('/profile'),
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: DashboardColors.surfaceHigh,
                            backgroundImage:
                                avatarUrl.isEmpty
                                    ? null
                                    : NetworkImage(avatarUrl),
                            child:
                                avatarUrl.isEmpty
                                    ? Text(
                                      name.isEmpty
                                          ? '?'
                                          : name.characters.first.toUpperCase(),
                                      style: const TextStyle(
                                        color: DashboardColors.onSurface,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
