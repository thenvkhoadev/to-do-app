import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DesktopAiPanel extends StatelessWidget {
  const DesktopAiPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x0DC0C1FF),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.psychology_rounded,
                      color: DashboardColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AI INTELLIGENCE INSIGHT',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('92%',
                          style: TextStyle(
                              color: DashboardColors.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.w700)),
                      Text('TASK HEALTH SCORE',
                          style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('87%',
                          style: TextStyle(
                              color: DashboardColors.secondary,
                              fontSize: 32,
                              fontWeight: FontWeight.w700)),
                      Text('COMPLETION PROB.',
                          style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InsightCard(
                color: DashboardColors.primary,
                label: 'RECOMMENDED NEXT',
                icon: Icons.tips_and_updates_rounded,
                text: 'Build analytics cards first to validate the grid layout performance.',
              ),
              const SizedBox(height: 12),
              _InsightCard(
                color: DashboardColors.error,
                label: 'POTENTIAL RISK',
                icon: Icons.warning_rounded,
                text: 'WebSocket latency might impact UI smoothness.',
                textColor: DashboardColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.color,
    required this.label,
    required this.icon,
    required this.text,
    this.textColor,
  });
  final Color color;
  final String label, text;
  final IconData icon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: .20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: TextStyle(
                color: textColor ?? DashboardColors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}
