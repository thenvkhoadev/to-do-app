import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/shared/widgets/metric_card.dart';
import 'package:to_do_app/shared/widgets/nexus_glass_panel.dart';
import 'package:to_do_app/shared/widgets/responsive_page.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final wide = MediaQuery.sizeOf(context).width >= 820;

    return ResponsivePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NexusGlassPanel(
            glowColor: NexusColors.primaryContainer.withValues(alpha: 0.26),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: NexusColors.primaryContainer,
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? 'Nexus Operator', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? 'precision@nexus.ai', style: const TextStyle(color: NexusColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Log out',
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: wide ? 4 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: wide ? 1.35 : 1.05,
            children: const [
              MetricCard(title: 'Focus score', value: '82%', icon: Icons.track_changes_rounded),
              MetricCard(title: 'Streak', value: '7d', icon: Icons.local_fire_department_rounded, color: NexusColors.tertiary),
              MetricCard(title: 'Total tasks', value: '32', icon: Icons.task_alt_rounded, color: NexusColors.secondary),
              MetricCard(title: 'Focus hours', value: '24', icon: Icons.timer_rounded, color: NexusColors.warning),
            ],
          ),
          const SizedBox(height: 18),
          const NexusGlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cognitive load analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 18),
                _AnalyticsBar(label: 'Deep work', value: 0.62, color: NexusColors.primary),
                SizedBox(height: 14),
                _AnalyticsBar(label: 'Admin', value: 0.18, color: NexusColors.tertiary),
                SizedBox(height: 14),
                _AnalyticsBar(label: 'Learning', value: 0.20, color: NexusColors.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsBar extends StatelessWidget {
  const _AnalyticsBar({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(value * 100).round()}%', style: const TextStyle(color: NexusColors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 9,
            backgroundColor: NexusColors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
