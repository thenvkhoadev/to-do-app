import 'package:flutter/material.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_glass.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TasksProjectsAiAssistantPanel extends StatelessWidget {
  const TasksProjectsAiAssistantPanel({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TasksProjectsGlass(
      padding: EdgeInsets.all(compact ? 16 : 18),
      glowColor: DashboardColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: .85, end: 1.08),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                builder:
                    (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        DashboardColors.primaryContainer,
                        DashboardColors.secondaryContainer,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DashboardColors.primary.withValues(alpha: .28),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI Copilot Online',
                  style: TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Start with Neural Engine Specs',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Highest impact task. It blocks 3 dependent tasks and has a same-day deadline.',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _PromptChip(label: 'Summarize blockers'),
              _PromptChip(label: 'Plan my day'),
              _PromptChip(label: 'Draft update'),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 16),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .04),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ask about this project...',
                      style: TextStyle(
                        color: DashboardColors.outline,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_upward_rounded,
                    color: DashboardColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TasksProjectsFloatingAiButton extends StatelessWidget {
  const TasksProjectsFloatingAiButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open AI Copilot',
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              DashboardColors.primaryContainer,
              DashboardColors.secondaryContainer,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: DashboardColors.primary.withValues(alpha: .32),
              blurRadius: 32,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: DashboardColors.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: DashboardColors.primary.withValues(alpha: .18),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: DashboardColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
