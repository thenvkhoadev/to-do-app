import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/shared/widgets/metric_card.dart';
import 'package:to_do_app/shared/widgets/nexus_glass_panel.dart';
import 'package:to_do_app/shared/widgets/responsive_page.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 780;

    return ResponsivePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Good evening, Khoa', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 8),
          const Text('Nexus has organized your focus blocks and task queue.', style: TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 16)),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: wide ? 4 : 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: wide ? 1.35 : 1.1,
            children: const [
              MetricCard(title: 'Focus score', value: '82%', icon: Icons.track_changes_rounded),
              MetricCard(title: 'Streak', value: '7d', icon: Icons.local_fire_department_rounded, color: NexusColors.tertiary),
              MetricCard(title: 'Tasks done', value: '18', icon: Icons.task_alt_rounded, color: NexusColors.secondary),
              MetricCard(title: 'Focus hours', value: '24.5', icon: Icons.timer_rounded, color: NexusColors.warning),
            ],
          ),
          const SizedBox(height: 18),
          const NexusGlassPanel(
            glowColor: Color(0x337C4DFF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI briefing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text('Your calendar is clean from 9:30 to 11:00. Best slot for deep work: ship the auth refactor, then batch admin tasks after lunch.', style: TextStyle(color: NexusColors.onSurfaceVariant, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
