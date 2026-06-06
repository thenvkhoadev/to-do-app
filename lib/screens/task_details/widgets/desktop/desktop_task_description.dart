import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/ai_suggestion_banner.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DesktopTaskDescription extends StatelessWidget {
  const DesktopTaskDescription({required this.item, super.key});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Task Description',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.01,
                  height: 1.3,
                ),
              ),
              const Spacer(),
              _ToolbarButton(icon: Icons.format_bold_rounded),
              _ToolbarButton(icon: Icons.format_italic_rounded),
              _ToolbarButton(icon: Icons.checklist_rounded),
              Container(
                width: 1,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: Colors.white.withValues(alpha: .08),
              ),
              _ToolbarButton(icon: Icons.code_rounded),
              _ToolbarButton(icon: Icons.link_rounded),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            item.description.isNotEmpty
                ? item.description
                : 'Develop a pixel-perfect Flutter implementation of the AI Analytics Dashboard based on the Figma specifications. The dashboard should maintain 60FPS performance and include glassmorphic effects as defined in the brand system.',
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          if (item.aiSuggestion != null) ...[
            const SizedBox(height: 24),
            const Text(
              'AI Suggestion:',
              style: TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            AiSuggestionBanner(text: item.aiSuggestion!),
          ] else ...[
            const SizedBox(height: 20),
            const Text(
              'Technical Requirements:',
              style: TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _RequirementItem(
              text: 'Implementation of ',
              highlight: 'CustomPainter',
              suffix: ' for the glassmorphism blurs.',
            ),
            _RequirementItem(
              text: 'Responsive grid layout using ',
              highlight: 'LayoutBuilder',
              suffix: '.',
            ),
            const _BulletItem(text: 'Integration of real-time data streaming via WebSockets.'),
            const _BulletItem(text: 'Lottie animations for task success states.'),
          ],
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: Icon(icon, color: DashboardColors.onSurfaceVariant, size: 16),
          ),
        ),
      );
}

class _RequirementItem extends StatelessWidget {
  const _RequirementItem({
    required this.text,
    required this.highlight,
    required this.suffix,
  });
  final String text, highlight, suffix;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 16)),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: text),
                    WidgetSpan(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: DashboardColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          highlight,
                          style: const TextStyle(
                            color: DashboardColors.primary,
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    TextSpan(text: suffix),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 16)),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: child,
          ),
        ),
      );
}
