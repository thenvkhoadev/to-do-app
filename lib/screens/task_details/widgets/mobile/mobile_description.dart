import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/shared/widgets/quill_description_editor.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileDescription extends StatelessWidget {
  const MobileDescription({required this.item, super.key});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _GlassCard(
          child: QuillDescriptionEditor(
            taskId: item.id,
            initialText: item.description,
            minHeight: 80,
            maxHeight: 220,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(24),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: .12)),
                left: BorderSide(color: Colors.white.withValues(alpha: .05)),
                right: BorderSide(color: Colors.white.withValues(alpha: .05)),
                bottom: BorderSide(color: Colors.white.withValues(alpha: .05)),
              ),
            ),
            child: child,
          ),
        ),
      );
}
