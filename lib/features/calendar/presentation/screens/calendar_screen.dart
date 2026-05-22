import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/shared/widgets/nexus_glass_panel.dart';
import 'package:to_do_app/shared/widgets/responsive_page.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsivePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Events', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Your focus calendar and task schedule.', style: TextStyle(color: NexusColors.onSurfaceVariant)),
          SizedBox(height: 24),
          NexusGlassPanel(
            child: Column(
              children: [
                _CalendarRow(day: 'Mon', title: 'Deep work sprint', time: '09:30'),
                Divider(),
                _CalendarRow(day: 'Tue', title: 'AI planning review', time: '14:00'),
                Divider(),
                _CalendarRow(day: 'Fri', title: 'Weekly shutdown', time: '16:30'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarRow extends StatelessWidget {
  const _CalendarRow({required this.day, required this.title, required this.time});

  final String day;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: NexusColors.primaryContainer, child: Text(day)),
      title: Text(title),
      subtitle: Text(time),
    );
  }
}
