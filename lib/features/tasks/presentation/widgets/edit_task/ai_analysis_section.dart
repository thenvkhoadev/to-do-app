import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskAIAnalysisSection extends StatelessWidget {
  const TaskAIAnalysisSection({
    required this.item,
    required this.isMobile,
    super.key,
  });

  final TaskBoardItem item;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.psychology_rounded, color: DashboardColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'AI Analysis',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mobile Health Card
          const _MobileHealthCard(),
          const SizedBox(height: 16),
          // Mobile Grid: Risk Meter + Smart Schedule
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(child: _MobileRiskMeterCard()),
              SizedBox(width: 12),
              Expanded(child: _MobileSmartScheduleCard()),
            ],
          ),
        ],
      );
    }

    // On Desktop, layouts.dart handles rendering TaskHealthCard, AIAnalysisPanelCard,
    // and TaskSmartScheduleCard as separate sibling widgets in the right column list.
    // So we return the AIAnalysisPanelCard here as the primary "aiAnalysis" widget.
    return const AIAnalysisPanelCard();
  }
}

// ── DESKTOP WIDGETS ──────────────────────────────────────────────────────────

class TaskHealthCard extends StatelessWidget {
  const TaskHealthCard({
    required this.item,
    required this.isMobile,
    super.key,
  });

  final TaskBoardItem item;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TASK HEALTH INDICATOR',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 0.85,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    valueColor: const AlwaysStoppedAnimation<Color>(DashboardColors.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '85%',
                      style: TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'OPTIMAL',
                      style: TextStyle(
                        color: DashboardColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Health is driven by activity consistency and subtask velocity.',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class AIAnalysisPanelCard extends StatelessWidget {
  const AIAnalysisPanelCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            DashboardColors.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.psychology_rounded, color: DashboardColors.primary, size: 22),
              SizedBox(width: 12),
              Text(
                'AI Analysis',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'COMPLETION CHANCE',
                    style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '87%',
                    style: TextStyle(color: DashboardColors.success, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'COMPLEXITY',
                    style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      text: '9',
                      style: TextStyle(color: DashboardColors.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '/10',
                          style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // AI Insight Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DashboardColors.primary.withValues(alpha: 0.05),
              border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome_rounded, color: DashboardColors.primary, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'AI INSIGHT',
                      style: TextStyle(color: DashboardColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '"This task exhibits high cognitive load patterns. Recommend splitting \'Kafka consumer implementation\' into two subtasks to improve flow velocity."',
                  style: TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 13,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Deadline Risk Meter
          const Text(
            'DEADLINE RISK',
            style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: Colors.white.withValues(alpha: 0.04),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: DashboardColors.success,
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(99)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Container(
                        color: DashboardColors.warning,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: DashboardColors.error,
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(99)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Indicator dot placed exactly in the middle of medium risk
              Positioned(
                top: -4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1B1C1D), width: 3), // matching low-surface color
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('LOW', style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold)),
              Text('MEDIUM RISK', style: TextStyle(color: DashboardColors.warning, fontSize: 10, fontWeight: FontWeight.bold)),
              Text('CRITICAL', style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class TaskSmartScheduleCard extends StatelessWidget {
  const TaskSmartScheduleCard({
    required this.isMobile,
    super.key,
  });

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    const tertiaryColor = DashboardColors.tertiary; // #b4ebff
    const onTertiaryText = Color(0xFF003642); // dark slate/teal

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tertiaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.schedule_rounded, color: tertiaryColor, size: 20),
              SizedBox(width: 12),
              Text(
                'Smart Schedule',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tertiaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tertiaryColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUGGESTED FOCUS WINDOW',
                  style: TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '08:00 — 10:00',
                      style: TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tertiaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PEAK ENERGY',
                        style: TextStyle(
                          color: onTertiaryText,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── MOBILE WIDGETS ───────────────────────────────────────────────────────────

class _MobileHealthCard extends StatelessWidget {
  const _MobileHealthCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Task Health',
                    style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Excellent',
                        style: TextStyle(color: DashboardColors.success, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.verified_rounded, color: DashboardColors.success, size: 18),
                    ],
                  ),
                ],
              ),
              // Compact circular progress ring
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: 0.9,
                      strokeWidth: 3,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(DashboardColors.success),
                    ),
                  ),
                  Text(
                    '90%',
                    style: TextStyle(
                      color: DashboardColors.onSurface.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Velocity is 12% above team average. No immediate blockers detected for the current sprint cycle.',
            style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _MobileRiskMeterCard extends StatelessWidget {
  const _MobileRiskMeterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Meter',
            style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.25,
              child: Container(
                decoration: BoxDecoration(
                  color: DashboardColors.warning,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'LOW',
                style: TextStyle(color: DashboardColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                '25% Prob.',
                style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileSmartScheduleCard extends StatelessWidget {
  const _MobileSmartScheduleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Smart Schedule',
            style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: DashboardColors.tertiary, size: 16),
              SizedBox(width: 6),
              Text(
                'Oct 26',
                style: TextStyle(color: DashboardColors.onSurface, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Recommended finish',
            style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
