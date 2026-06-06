import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description.isNotEmpty
                    ? item.description
                    : 'Create dashboard page using Flutter. Implement consistent spacing and follow the glassmorphism design system for all cards and interactive elements.',
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              // Toolbar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: DashboardColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToolBtn(icon: Icons.format_bold_rounded),
                    _ToolBtn(icon: Icons.format_italic_rounded),
                    _ToolBtn(icon: Icons.checklist_rounded),
                    _ToolBtn(icon: Icons.code_rounded),
                    _ToolBtn(icon: Icons.link_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.transparent,
        ),
        child: Icon(icon, color: DashboardColors.onSurfaceVariant, size: 18),
      );
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
