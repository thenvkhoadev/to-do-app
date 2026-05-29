import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_models.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/ai_action_chips.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/ai_summary_block.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/collaboration_presence.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/smart_progress_timeline.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskPreviewOverlay extends StatelessWidget {
  const TaskPreviewOverlay({required this.item, required this.visible, required this.onClose, this.onViewDetails, super.key});

  final TasksProjectItem item;
  final bool visible;
  final VoidCallback onClose;
  final ValueChanged<TasksProjectItem>? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(420.0, 500.0).toDouble();
        final previewGap = visible ? width + 48 : 0.0;
        return Stack(
          children: [
            Positioned.fill(child: GestureDetector(onTap: onClose, child: Container(color: Colors.black.withValues(alpha: .14)))),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: visible ? 32 : 0,
              right: visible ? previewGap : 0,
              bottom: 24,
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: visible ? Alignment.bottomLeft : Alignment.bottomCenter,
                child: const FloatingAiSuggestionBar(),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              top: 24,
              right: visible ? 24 : -width - 40,
              bottom: 24,
              width: width,
              child: _PreviewPanel(item: item, onClose: onClose, onViewDetails: onViewDetails),
            ),
          ],
        );
      },
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.item, required this.onClose, this.onViewDetails});

  final TasksProjectItem item;
  final VoidCallback onClose;
  final ValueChanged<TasksProjectItem>? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
            boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .12), blurRadius: 54)],
          ),
          child: Stack(
            children: [
              Positioned(right: -90, bottom: -90, child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .10), blurRadius: 100, spreadRadius: 40)]))),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 12, 32),
                child: ScrollbarTheme(
                  data: ScrollbarTheme.of(context).copyWith(
                    thumbVisibility: WidgetStateProperty.all(false),
                    trackVisibility: WidgetStateProperty.all(false),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TaskPreviewHeader(item: item, onClose: onClose),
                      const SizedBox(height: 18),
                      const CollaborationPresence(),
                      const SizedBox(height: 24),
                      Text(item.title, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 32, height: 1.2, fontWeight: FontWeight.w600, letterSpacing: -.32)),
                      const SizedBox(height: 16),
                      const AiSummaryBlock(),
                      const SizedBox(height: 32),
                      const SuggestedSubtasksSection(),
                      const SizedBox(height: 32),
                      const SmartProgressTimeline(),
                      const SizedBox(height: 32),
                      const AiActionChips(),
                      const SizedBox(height: 32),
                      const AttachmentGrid(),
                      const SizedBox(height: 32),
                      _ViewDetailsButton(onTap: () => onViewDetails?.call(item)),
                      const SizedBox(height: 16),
                      const CommentInput(),
                    ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskPreviewHeader extends StatelessWidget {
  const TaskPreviewHeader({required this.item, required this.onClose, super.key});

  final TasksProjectItem item;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: Wrap(spacing: 8, runSpacing: 8, children: [PriorityBadge(), StatusBadge()])),
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onClose,
            child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.close_rounded, color: DashboardColors.onSurfaceVariant)),
          ),
        ),
      ],
    );
  }
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key});

  @override
  Widget build(BuildContext context) => _PillBadge(label: 'HIGH PRIORITY', color: DashboardColors.error, background: const Color(0xFF93000A));
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key});

  @override
  Widget build(BuildContext context) => _PillBadge(label: 'IN PROGRESS', color: DashboardColors.primary, background: DashboardColors.primaryContainer);
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: background.withValues(alpha: .10), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: .30))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
    );
  }
}

class SuggestedSubtasksSection extends StatefulWidget {
  const SuggestedSubtasksSection({super.key});

  @override
  State<SuggestedSubtasksSection> createState() => _SuggestedSubtasksSectionState();
}

class _SuggestedSubtasksSectionState extends State<SuggestedSubtasksSection> {
  final checked = <bool>[true, false, false];
  final subtasks = const ['Audit elevation blur tokens', 'Normalize rounded corner scale', 'Verify contrast on glass cards'];

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'AI SUGGESTED SUBTASKS',
      trailing: 'Calculated by TaskFlow AI',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: DashboardColors.surfaceLow.withValues(alpha: .40), borderRadius: BorderRadius.circular(16), border: Border.all(color: DashboardColors.outlineVariant.withValues(alpha: .10))),
        child: Column(
          children: List.generate(subtasks.length, (index) => _SubtaskRow(label: subtasks[index], checked: checked[index], onTap: () => setState(() => checked[index] = !checked[index]))),
        ),
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({required this.label, required this.checked, required this.onTap});

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: checked ? DashboardColors.primary.withValues(alpha: .20) : Colors.transparent, borderRadius: BorderRadius.circular(checked ? 8 : 4), border: Border.all(color: checked ? DashboardColors.primary : DashboardColors.outlineVariant, width: 2)),
              child: checked ? const Icon(Icons.check_rounded, color: DashboardColors.primary, size: 18) : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: checked ? DashboardColors.onSurface.withValues(alpha: .60) : DashboardColors.onSurfaceVariant, fontSize: 16, decoration: checked ? TextDecoration.lineThrough : null, decorationColor: DashboardColors.onSurface))),
          ],
        ),
      ),
    );
  }
}

class AttachmentGrid extends StatelessWidget {
  const AttachmentGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'ATTACHMENTS',
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.35,
        children: const [
          _AttachmentCard(icon: Icons.image_rounded, color: DashboardColors.primary, name: 'ui-kit-v4.png', size: '2.4 MB'),
          _AttachmentCard(icon: Icons.picture_as_pdf_rounded, color: DashboardColors.secondary, name: 'design-spec.pdf', size: '840 KB'),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.icon, required this.color, required this.name, required this.size});

  final IconData icon;
  final Color color;
  final String name;
  final String size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: DashboardColors.surfaceLow.withValues(alpha: .40), borderRadius: BorderRadius.circular(16), border: Border.all(color: DashboardColors.outlineVariant.withValues(alpha: .10))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color)), const Spacer(), Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(size, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 10))]),
    );
  }
}

class CommentInput extends StatelessWidget {
  const CommentInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        TextField(
          style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Write a comment...',
            hintStyle: const TextStyle(color: DashboardColors.outline, fontSize: 12),
            filled: true,
            fillColor: DashboardColors.surfaceLow.withValues(alpha: .60),
            contentPadding: const EdgeInsets.fromLTRB(56, 13, 48, 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide(color: DashboardColors.outlineVariant.withValues(alpha: .20))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide(color: DashboardColors.outlineVariant.withValues(alpha: .20))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: DashboardColors.primary)),
          ),
        ),
        Positioned(left: 12, child: Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: DashboardColors.surfaceHighest, border: Border.all(color: DashboardColors.outlineVariant.withValues(alpha: .30))), child: const Text('A', style: TextStyle(color: DashboardColors.onSurface, fontSize: 10, fontWeight: FontWeight.w800)))) ,
        Positioned(right: 10, child: IconButton(onPressed: () {}, icon: const Icon(Icons.send_rounded, color: DashboardColors.primary, size: 20))),
      ],
    );
  }
}

class FloatingAiSuggestionBar extends StatelessWidget {
  const FloatingAiSuggestionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .03), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: .08)), boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .16), blurRadius: 34)]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: DashboardColors.onSurfaceVariant),
                Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 14), color: DashboardColors.outlineVariant.withValues(alpha: .20)),
                const Text('AI Suggestion: ', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
                const Text('Optimize elevation tokens in the Style Guide', style: TextStyle(color: DashboardColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(width: 16),
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: DashboardColors.primary.withValues(alpha: .20), borderRadius: BorderRadius.circular(999), border: Border.all(color: DashboardColors.primary.withValues(alpha: .20))), child: const Text('APPLY', style: TextStyle(color: DashboardColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewDetailsButton extends StatelessWidget {
  const _ViewDetailsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .02), borderRadius: BorderRadius.circular(16), border: Border.all(color: DashboardColors.outlineVariant.withValues(alpha: .30))),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('View Full Details', style: TextStyle(color: DashboardColors.onSurface, fontWeight: FontWeight.w800)), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, color: DashboardColors.onSurface, size: 20)]),
        ),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Text(title, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)), const Spacer(), if (trailing != null) Text(trailing!, style: const TextStyle(color: DashboardColors.primaryContainer, fontSize: 10, fontStyle: FontStyle.italic))]), const SizedBox(height: 16), child]);
  }
}
