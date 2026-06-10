import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/streak/presentation/providers/streak_providers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class StreakTopbarButton extends ConsumerWidget {
  const StreakTopbarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final showStreak = ref.watch(showStreakOverlayProvider);
    final count = profile == null
        ? 0
        : displayStreakCount(profile.streakCount, profile.lastActivityDate);

    final active = count > 0;

    return TapRegion(
      groupId: 'streak_popup',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            ref.read(showStreakOverlayProvider.notifier).state = !showStreak;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: showStreak
                  ? const Color(0xFFFF8A00).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: showStreak
                    ? const Color(0xFFFF8A00).withValues(alpha: 0.45)
                    : (active
                        ? const Color(0xFFFF8A00).withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.08)),
              ),
              boxShadow: showStreak
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF8A00).withValues(alpha: 0.2),
                        blurRadius: 10,
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: active || showStreak
                      ? const Color(0xFFFF8A00)
                      : DashboardColors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    color: active || showStreak
                        ? Colors.white
                        : DashboardColors.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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
