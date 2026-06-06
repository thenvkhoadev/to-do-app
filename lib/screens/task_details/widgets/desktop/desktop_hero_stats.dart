import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DesktopHeroStats extends ConsumerWidget {
  const DesktopHeroStats({required this.item, super.key});
  final TaskBoardItem item;

  (IconData, Color) _getResourceFileInfo(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) {
      return (Icons.insert_drive_file_rounded, DashboardColors.tertiary);
    }
    final ext = parts.last.toLowerCase();
    return switch (ext) {
      'pdf' => (Icons.picture_as_pdf_rounded, const Color(0xFF00CFE8)),
      'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' => (Icons.image_rounded, const Color(0xFFF24E1E)),
      'dart' || 'js' || 'ts' || 'html' || 'css' || 'py' || 'json' || 'cpp' || 'c' => (Icons.code_rounded, DashboardColors.primary),
      'fig' || 'xd' || 'sketch' => (Icons.grid_view_rounded, const Color(0xFFF24E1E)),
      'doc' || 'docx' => (Icons.description_rounded, const Color(0xFF00CFE8)),
      _ => (Icons.insert_drive_file_rounded, DashboardColors.tertiary),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = ref.watch(taskAttachmentsProvider(item.id));
    final attachments = attachmentsAsync.valueOrNull ?? [];

    final subtasksAsync = ref.watch(taskSubtasksProvider(item.id));
    double? progressValue;
    subtasksAsync.when(
      data: (subtasks) {
        if (subtasks.isNotEmpty) {
          final doneCount = subtasks.where((s) => s.isDone).length;
          progressValue = doneCount / subtasks.length;
        } else {
          progressValue = null;
        }
      },
      loading: () => progressValue = null,
      error: (_, __) => progressValue = null,
    );

    return ClipRRect(
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
          child: Stack(
            children: [
              Positioned(
                right: -80,
                top: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DashboardColors.primary.withValues(alpha: .07),
                  ),
                ),
              ),
              Row(
                children: [
                  // Estimated Completion
                  Expanded(
                    child: _StatItem(
                      label: 'Estimated Completion',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.estimate.isNotEmpty ? item.estimate : '—',
                            style: const TextStyle(
                              color: DashboardColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.01,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progressValue ?? 0.0,
                              minHeight: 4,
                              backgroundColor: DashboardColors.surfaceHighest,
                              valueColor: const AlwaysStoppedAnimation(
                                DashboardColors.primary,
                              ),
                            ),
                          ),
                          if (progressValue == null) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'No subtasks available',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Focus Rating
                  Expanded(
                    child: _StatItem(
                      label: 'Focus Rating',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                'A+',
                                style: TextStyle(
                                  color: DashboardColors.secondary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.verified_rounded,
                                  color: DashboardColors.secondary, size: 20),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Recommended for your morning flow',
                            style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Linked Resources
                  Expanded(
                    child: _StatItem(
                      label: 'Linked Resources',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (attachments.isEmpty) ...[
                            Row(
                              children: [
                                _ResourceIcon(
                                  icon: Icons.attachment_rounded,
                                  color: DashboardColors.onSurfaceVariant.withValues(alpha: .4),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'No assets linked',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                for (int i = 0; i < attachments.length.clamp(0, 3); i++) ...[
                                  if (i > 0) const SizedBox(width: 4),
                                  Builder(builder: (context) {
                                    final info = _getResourceFileInfo(attachments[i].fileName);
                                    return _ResourceIcon(
                                      icon: info.$1,
                                      color: info.$2,
                                    );
                                  }),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              attachments.length > 3
                                  ? '+${attachments.length - 3} more assets'
                                  : attachments.length == 1
                                      ? '1 asset'
                                      : '${attachments.length} assets',
                              style: const TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      );
}

class _ResourceIcon extends StatelessWidget {
  const _ResourceIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: DashboardColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Icon(icon, color: color, size: 16),
      );
}
