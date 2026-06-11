import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/premium_dropdown.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class ColumnBatchToolbar extends StatelessWidget {
  const ColumnBatchToolbar({
    required this.selectedTasks,
    required this.onCopy,
    required this.onExport,
    required this.onDelete,
    super.key,
  });

  final List<TaskBoardItem> selectedTasks;
  final ValueChanged<String> onCopy;
  final ValueChanged<String> onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          _DropdownButton(
            label: 'Copy',
            icon: Icons.copy_rounded,
            onTap: (renderBox) {
              final position = renderBox.localToGlobal(Offset.zero);
              showTaskColumnCopyMenu(
                context: context,
                offset: Offset(position.dx, position.dy + renderBox.size.height + 6),
                anchorSize: renderBox.size,
                onSelect: onCopy,
              );
            },
          ),
          const SizedBox(width: 8),
          _DropdownButton(
            label: 'Export',
            icon: Icons.download_rounded,
            onTap: (renderBox) {
              final position = renderBox.localToGlobal(Offset.zero);
              showTaskColumnExportMenu(
                context: context,
                offset: Offset(position.dx, position.dy + renderBox.size.height + 6),
                anchorSize: renderBox.size,
                onSelect: onExport,
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: DashboardColors.error,
              size: 20,
            ),
            tooltip: 'Xóa các công việc đã chọn',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _DropdownButton extends StatelessWidget {
  _DropdownButton({
    required this.label,
    required this.icon,
    required this.onTap,
  }) : _key = GlobalKey();

  final String label;
  final IconData icon;
  final void Function(RenderBox renderBox) onTap;
  final GlobalKey _key;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: () {
        final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) onTap(renderBox);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: DashboardColors.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: DashboardColors.onSurfaceVariant,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
