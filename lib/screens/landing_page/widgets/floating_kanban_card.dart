import 'package:flutter/material.dart';
import 'design_system.dart';
import 'animated_float.dart';

class FloatingKanbanCard extends StatelessWidget {
  const FloatingKanbanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedFloat(
      delay: const Duration(milliseconds: 3000),
      child: GlassCard(
        padding: const EdgeInsets.all(16.0),
        borderRadius: 12.0,
        borderColor: Colors.white.withValues(alpha: 0.05),
        child: SizedBox(
          width: 240.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kanban • In Progress',
                style: getLandingGeistStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: LandingColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12.0),
              _buildTaskItem('Neural Engine R&D'),
              const SizedBox(height: 8.0),
              _buildTaskItem('Market Analysis UI'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: getLandingGeistMonoStyle(
          fontSize: 10.0,
          fontWeight: FontWeight.w500,
          color: LandingColors.textPrimary,
        ),
      ),
    );
  }
}
