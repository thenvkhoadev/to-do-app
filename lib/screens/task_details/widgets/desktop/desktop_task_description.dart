import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/ai_suggestion_banner.dart';
import 'package:to_do_app/shared/widgets/quill_description_editor.dart';
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
          const SizedBox(height: 20),
          QuillDescriptionEditor(
            taskId: item.id,
            initialText: item.plainTextDescription,
            minHeight: 100,
            maxHeight: 260,
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
          ],
        ],
      ),
    );
  }
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
