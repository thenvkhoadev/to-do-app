import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class ProductivityStatsCard extends StatelessWidget {
  const ProductivityStatsCard({
    required this.focusScore,
    required this.streakDays,
    required this.focusHours,
    required this.completedTasks,
    required this.totalTasks,
    super.key,
  });

  final int focusScore;
  final int streakDays;
  final int focusHours;
  final int completedTasks;
  final int totalTasks;

  @override
  Widget build(BuildContext context) {
    final rate = totalTasks == 0 ? 0 : ((completedTasks / totalTasks) * 100).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 550;

        final items = [
          _KpiItem(
            label: 'FOCUS SCORE',
            value: focusScore.toString(),
            valueColor: EditProfileColors.primary,
            trendLabel: '+4%',
            trendColor: EditProfileColors.success,
            trendIcon: Icons.trending_up,
          ),
          _KpiItem(
            label: 'STREAK',
            value: '${streakDays}d',
            valueColor: EditProfileColors.secondary,
            trendLabel: 'RECORD',
            trendColor: EditProfileColors.warning,
          ),
          _KpiItem(
            label: 'FOCUS HOURS',
            value: '${focusHours}h',
            valueColor: EditProfileColors.textPrimary,
            trendLabel: 'MTD',
            trendColor: EditProfileColors.textSecondary,
          ),
          _KpiItem(
            label: 'RATE',
            value: '$rate%',
            valueColor: EditProfileColors.secondary, // tertiary equivalent
            trendLabel: 'Target: 80%',
            trendColor: EditProfileColors.textSecondary,
          ),
        ];

        if (isMobile) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: items.map((item) => _buildKpiCard(item)).toList(),
          );
        }

        return Row(
          children: items.map((item) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildKpiCard(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiItem item) {
    return EditProfileGlassCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              color: EditProfileColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  color: item.valueColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.trendIcon != null) ...[
                    Icon(item.trendIcon, color: item.trendColor, size: 12),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    item.trendLabel,
                    style: TextStyle(
                      color: item.trendColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiItem {
  _KpiItem({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.trendLabel,
    required this.trendColor,
    this.trendIcon,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String trendLabel;
  final Color trendColor;
  final IconData? trendIcon;
}
