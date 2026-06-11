import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskGeneralInfoCard extends StatelessWidget {
  const TaskGeneralInfoCard({
    required this.titleController,
    required this.descController,
    required this.estimateController,
    required this.actualController,
    required this.categories,
    required this.tags,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.dueDate,
    required this.onDueDateChanged,
    required this.selectedTagIds,
    required this.onAddTag,
    required this.onRemoveTag,
    super.key,
  });

  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController estimateController;
  final TextEditingController actualController;
  final List<CategoryModel> categories;
  final List<TagModel> tags;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final DateTime? dueDate;
  final ValueChanged<DateTime?> onDueDateChanged;
  final List<String> selectedTagIds;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return DashboardColors.primary;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

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
          Row(
            children: const [
              Icon(Icons.edit_note_rounded, color: DashboardColors.primary, size: 24),
              SizedBox(width: 12),
              Text(
                'General Information',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          // Title Input
          const Text(
            'TASK TITLE',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: titleController,
            style: const TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.015),
              hintText: 'Enter task title...',
              hintStyle: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.3)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: DashboardColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Description Input
          const Text(
            'DESCRIPTION',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descController,
            maxLines: 4,
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.015),
              hintText: 'Enter task description...',
              hintStyle: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.3)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: DashboardColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Grid for dropdowns / dates
          LayoutBuilder(
            builder: (context, gridConstraints) {
              final isWide = gridConstraints.maxWidth > 500;
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category selection
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CATEGORY',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: DashboardColors.surfaceLow,
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedCategoryId?.isEmpty == true ? null : selectedCategoryId,
                                dropdownColor: DashboardColors.surfaceLow,
                                style: const TextStyle(color: DashboardColors.onSurface, fontSize: 14),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.015),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: DashboardColors.primary),
                                  ),
                                ),
                                icon: const Icon(Icons.expand_more_rounded, color: DashboardColors.onSurfaceVariant),
                                hint: const Text('Select Category', style: TextStyle(color: Colors.white24)),
                                items: categories.map((cat) {
                                  final catColor = _parseHexColor(cat.color);
                                  return DropdownMenuItem<String>(
                                    value: cat.id,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: catColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(cat.name, style: const TextStyle(color: DashboardColors.onSurface, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: onCategoryChanged,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isWide ? 20 : 12),
                      // Due Date Selection
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DUE DATE',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: dueDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: DashboardColors.primary,
                                          onPrimary: DashboardColors.onPrimary,
                                          surface: DashboardColors.surfaceLow,
                                          onSurface: DashboardColors.onSurface,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                onDueDateChanged(picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.015),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dueDate == null
                                          ? 'Chưa chọn'
                                          : DateFormat('yyyy-MM-dd').format(dueDate!),
                                      style: const TextStyle(
                                        color: DashboardColors.onSurface,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today_rounded, color: DashboardColors.onSurfaceVariant, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Selection
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STATUS',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: DashboardColors.surfaceLow,
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedStatus,
                                dropdownColor: DashboardColors.surfaceLow,
                                style: const TextStyle(color: DashboardColors.onSurface, fontSize: 14),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.015),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: DashboardColors.primary),
                                  ),
                                ),
                                icon: const Icon(Icons.expand_more_rounded, color: DashboardColors.onSurfaceVariant),
                                items: [
                                  DropdownMenuItem(
                                    value: 'draft',
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFA855F7),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text('Draft'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'todo',
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF5B8CFF),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text('To Do'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'in_progress',
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFFB020),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text('In Progress'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'done',
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF34C759),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text('Completed'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) onStatusChanged(val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isWide ? 20 : 12),
                      // Empty column spacer to align with grid in test.html
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TAGS',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.01),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.04)),
                              ),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ...selectedTagIds.map((tid) {
                                    final tag = tags.firstWhere((t) => t.id == tid, orElse: () => TagModel(id: tid, name: tid, userId: ''));
                                    final tagColor = _parseHexColor(tag.color);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: tagColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: tagColor.withValues(alpha: 0.25)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('#${tag.name}', style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () => onRemoveTag(tid),
                                            child: Icon(Icons.close_rounded, size: 12, color: tagColor),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  // Add Tag Dialog Button
                                  _AddTagButton(
                                    tags: tags,
                                    selectedTagIds: selectedTagIds,
                                    onAddTag: onAddTag,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estimated Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ESTIMATED TIME',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: estimateController,
                              style: const TextStyle(color: DashboardColors.onSurface, fontSize: 14),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.timer_outlined, color: DashboardColors.onSurfaceVariant, size: 16),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.015),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: DashboardColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isWide ? 20 : 12),
                      // Actual Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ACTUAL TIME',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: actualController,
                              style: const TextStyle(color: DashboardColors.onSurface, fontSize: 14),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.history_rounded, color: DashboardColors.onSurfaceVariant, size: 16),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.015),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: DashboardColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddTagButton extends StatelessWidget {
  const _AddTagButton({
    required this.tags,
    required this.selectedTagIds,
    required this.onAddTag,
  });

  final List<TagModel> tags;
  final List<String> selectedTagIds;
  final ValueChanged<String> onAddTag;

  @override
  Widget build(BuildContext context) {
    final available = tags.where((t) => !selectedTagIds.contains(t.id)).toList();

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08), style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_rounded, size: 12, color: DashboardColors.onSurfaceVariant),
            SizedBox(width: 4),
            Text('Add', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      color: DashboardColors.surfaceLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white12),
      ),
      itemBuilder: (context) {
        if (available.isEmpty) {
          return [
            const PopupMenuItem<String>(
              enabled: false,
              child: Text('No tags available', style: TextStyle(color: Colors.white30, fontSize: 13)),
            ),
          ];
        }
        return available.map((t) {
          return PopupMenuItem<String>(
            value: t.id,
            child: Text('#${t.name}', style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13)),
          );
        }).toList();
      },
      onSelected: onAddTag,
    );
  }
}
