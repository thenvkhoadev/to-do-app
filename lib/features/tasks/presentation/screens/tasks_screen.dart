import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/shared/widgets/nexus_glass_panel.dart';
import 'package:to_do_app/shared/widgets/responsive_page.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = [
      ('Design profile analytics', 'High', 'Deep Work'),
      ('Review AI task plan', 'Medium', 'Planning'),
      ('Sync calendar blocks', 'Low', 'Admin'),
    ];

    return ResponsivePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tasks', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('A calm command queue for today.', style: TextStyle(color: NexusColors.onSurfaceVariant)),
          const SizedBox(height: 22),
          ...tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NexusGlassPanel(
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_unchecked_rounded, color: NexusColors.secondary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(task.$3, style: const TextStyle(color: NexusColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Chip(label: Text(task.$2)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
