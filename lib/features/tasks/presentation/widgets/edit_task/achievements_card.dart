import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskAchievementsCard extends StatefulWidget {
  const TaskAchievementsCard({super.key});

  @override
  State<TaskAchievementsCard> createState() => _TaskAchievementsCardState();
}

class _TaskAchievementsCardState extends State<TaskAchievementsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _isHovered 
              ? const Color.fromRGBO(255, 255, 255, 0.04)
              : const Color.fromRGBO(255, 255, 255, 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered 
                ? DashboardColors.tertiary.withValues(alpha: 0.15)
                : const Color.fromRGBO(255, 255, 255, 0.08),
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: DashboardColors.tertiary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TASK MILESTONES',
                  style: TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Icon(
                  Icons.emoji_events_outlined,
                  size: 14,
                  color: DashboardColors.tertiary.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Achievement 1: Atomic Win (Unlocked)
            _buildAchievementRow(
              icon: Icons.widgets_rounded,
              color: const Color(0xFF22C55E),
              title: 'Atomic Win',
              description: 'Break down work with 3+ subtasks.',
              progressText: '3/3 Subtasks added',
              progress: 1.0,
              isUnlocked: true,
            ),
            const SizedBox(height: 18),
            
            // Achievement 2: Deep Work Prodigy (Locked)
            _buildAchievementRow(
              icon: Icons.psychology_rounded,
              color: DashboardColors.primary,
              title: 'Deep Work Prodigy',
              description: 'Complete within estimated duration.',
              progressText: '80% Est. Ratio',
              progress: 0.8,
              isUnlocked: false,
            ),
            const SizedBox(height: 18),
            
            // Achievement 3: Consistency Streak (Locked)
            _buildAchievementRow(
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Streak Master',
              description: 'Complete tasks 7 days in a row.',
              progressText: '5 / 7 Days active',
              progress: 5 / 7,
              isUnlocked: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementRow({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String progressText,
    required double progress,
    required bool isUnlocked,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rounded Hexagon / Square badge
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: isUnlocked ? 0.35 : 0.15),
            ),
            boxShadow: [
              if (isUnlocked)
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
            ],
          ),
          child: Icon(
            icon,
            color: color.withValues(alpha: isUnlocked ? 1.0 : 0.6),
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.white : DashboardColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    isUnlocked ? 'UNLOCKED' : progressText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isUnlocked ? const Color(0xFF22C55E) : DashboardColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.7),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUnlocked ? const Color(0xFF22C55E) : color.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
