import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/achievements/providers/achievements_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AchievementFilter extends ConsumerWidget {
  const AchievementFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(achievementsFilterProvider);

    return Row(
      children: [
        // Search field
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: TextField(
              onChanged: (value) {
                ref.read(achievementsFilterProvider.notifier).update(
                      (state) => state.copyWith(searchQuery: value),
                    );
              },
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search achievements...',
                hintStyle: TextStyle(
                  color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.6),
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Filter dropdown
        Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            color: const Color(0xFF131A2B),
            elevation: 16,
            shadowColor: Colors.black.withValues(alpha: 0.5),
            onSelected: (value) {
              ref.read(achievementsFilterProvider.notifier).update(
                    (state) => state.copyWith(selectedStatus: value),
                  );
            },
            itemBuilder: (context) {
              return ['All', 'Unlocked', 'Locked', 'Rare'].map((status) {
                final isSelected = filterState.selectedStatus == status;
                IconData statusIcon;
                Color statusColor;
                switch (status) {
                  case 'All':
                    statusIcon = Icons.grid_view_rounded;
                    statusColor = DashboardColors.primary;
                    break;
                  case 'Unlocked':
                    statusIcon = Icons.lock_open_rounded;
                    statusColor = DashboardColors.success;
                    break;
                  case 'Locked':
                    statusIcon = Icons.lock_rounded;
                    statusColor = DashboardColors.error;
                    break;
                  case 'Rare':
                    statusIcon = Icons.workspace_premium_rounded;
                    statusColor = DashboardColors.secondary;
                    break;
                  default:
                    statusIcon = Icons.filter_list_rounded;
                    statusColor = Colors.white;
                }

                return PopupMenuItem<String>(
                  value: status,
                  height: 44,
                  child: Row(
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: isSelected ? statusColor : DashboardColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        status == 'All' ? 'All Badges' : status,
                        style: TextStyle(
                          color: isSelected ? Colors.white : DashboardColors.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: statusColor,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList();
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.02),
                    Colors.white.withValues(alpha: 0.005),
                  ],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filterState.selectedStatus == 'All'
                        ? Icons.grid_view_rounded
                        : filterState.selectedStatus == 'Unlocked'
                            ? Icons.lock_open_rounded
                            : filterState.selectedStatus == 'Locked'
                                ? Icons.lock_rounded
                                : Icons.workspace_premium_rounded,
                    color: filterState.selectedStatus == 'All'
                        ? DashboardColors.primary
                        : filterState.selectedStatus == 'Unlocked'
                            ? DashboardColors.success
                            : filterState.selectedStatus == 'Locked'
                                ? DashboardColors.error
                                : DashboardColors.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    filterState.selectedStatus == 'All'
                        ? 'All Badges'
                        : filterState.selectedStatus,
                    style: const TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: DashboardColors.onSurfaceVariant,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
