import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/features/achievements/providers/achievements_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AchievementTabs extends ConsumerWidget {
  const AchievementTabs({super.key});

  static const List<String> _categories = [
    'All',
    'Tasks',
    'Focus',
    'Streak',
    'XP',
    'Projects',
    'AI',
    'Social',
    'Special',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(achievementsFilterProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isActive = filterState.selectedCategory == category;

          return GestureDetector(
            onTap: () {
              ref.read(achievementsFilterProvider.notifier).update(
                    (state) => state.copyWith(selectedCategory: category),
                  );
            },
            child: AnimatedContainer(
              duration: DashboardDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DashboardRadii.full),
                gradient: isActive
                    ? const LinearGradient(
                        colors: [DashboardColors.primary, DashboardColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: isActive
                      ? DashboardColors.primary.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: DashboardColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isActive ? Colors.black : DashboardColors.onSurface,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
