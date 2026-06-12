import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/premium_due_date_picker.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/time_picker_card.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/premium_select_field.dart';
import 'package:to_do_app/shared/widgets/quill_description_editor.dart';
import 'package:string_to_icon/string_to_icon.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskGeneralInfoCard extends StatelessWidget {
  const TaskGeneralInfoCard({
    required this.titleController,
    required this.taskId,
    required this.initialDescription,
    required this.onDescriptionChanged,
    required this.onCreateCategory,
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
    required this.onCreateTag,
    required this.estimateHour,
    required this.estimateMinute,
    required this.onEstimateChanged,
    required this.actualHour,
    required this.actualMinute,
    required this.onActualChanged,
    required this.selectedPriority,
    required this.onPriorityChanged,
    super.key,
  });

  final TextEditingController titleController;
  final String taskId;
  final String initialDescription;
  final ValueChanged<String?> onDescriptionChanged;
  final Future<CategoryModel> Function(
    String name,
    String colorHex,
    String iconName,
  )
  onCreateCategory;
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
  final Future<TagModel> Function(String name, String colorHex) onCreateTag;
  final int estimateHour;
  final int estimateMinute;
  final void Function(int hour, int minute) onEstimateChanged;
  final int actualHour;
  final int actualMinute;
  final void Function(int hour, int minute) onActualChanged;
  final String selectedPriority;
  final ValueChanged<String> onPriorityChanged;

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return DashboardColors.primary;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _categoryIcon(String name, String? icon) {
    final cleanName = name.trim().toLowerCase();

    // 1. Try mapping the category icon field directly if it exists (explicit user selection)
    if (icon != null && icon.trim().isNotEmpty) {
      final codeIcon = IconMapper.getIconData(icon.trim().toLowerCase());
      if (codeIcon != Icons.circle &&
          codeIcon != Icons.help_outline &&
          codeIcon != Icons.error) {
        return codeIcon;
      }
    }

    // Vietnamese category names to English Material Icons mapping
    const viTranslation = {
      'bóng đá': 'sports_soccer',
      'đá bóng': 'sports_soccer',
      'thể thao': 'sports_soccer',
      'gym': 'fitness_center',
      'thể hình': 'fitness_center',
      'công việc': 'work',
      'dự án': 'business',
      'học tập': 'school',
      'học': 'school',
      'cá nhân': 'person',
      'sức khỏe': 'favorite',
      'tài chính': 'account_balance',
      'tiền': 'attach_money',
      'mua sắm': 'shopping_bag',
      'du lịch': 'flight',
      'lập trình': 'code',
      'code': 'code',
      'thiết kế': 'palette',
      'giải trí': 'movie',
      'gia đình': 'home',
      'nhà': 'home',
      'ăn uống': 'restaurant',
      'nấu ăn': 'restaurant',
      'quan trọng': 'flag',
      'ngôi sao': 'star',
    };

    String lookupKey = cleanName;
    for (final entry in viTranslation.entries) {
      if (cleanName.contains(entry.key)) {
        lookupKey = entry.value;
        break;
      }
    }

    // 2. Try mapping the translated/lookup key
    final nameIcon = IconMapper.getIconData(lookupKey);
    if (nameIcon != Icons.circle &&
        nameIcon != Icons.help_outline &&
        nameIcon != Icons.error) {
      return nameIcon;
    }

    // 3. Fallback to folder icon
    return Icons.folder_rounded;
  }

  void _showCreateCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final iconSearchController = TextEditingController();
    String selectedColor = '#8083FF';
    String selectedIconName = 'work';

    final presetColors = [
      '#8083FF', // Indigo
      '#7CFFB2', // Mint
      '#FFD166', // Yellow
      '#FF6B9D', // Pink
      '#06D6A0', // Teal
      '#FF5B5B', // Coral Red
      '#FF9F43', // Orange
      '#54A0FF', // Blue
    ];

    final presetIcons = [
      'work',
      'person',
      'school',
      'favorite',
      'account_balance',
      'home',
      'shopping_bag',
      'fitness_center',
      'flight',
      'code',
      'palette',
      'calendar_month',
      'flag',
      'star',
      'sports_soccer',
      'music_note',
      'movie',
      'restaurant',
      'directions_car',
      'pets',
      'book',
      'lightbulb',
      'camera_alt',
      'phone',
      'email',
      'chat',
      'lock',
      'key',
      'sunny',
      'cloud',
    ];

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: DashboardColors.surfaceLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: DashboardColors.outlineVariant.withValues(
                        alpha: .3,
                      ),
                    ),
                  ),
                  title: Text(
                    'Create New Category',
                    style: GoogleFonts.interTight(
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.onSurface,
                    ),
                  ),
                  content: SizedBox(
                    width: 420,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: nameController,
                            autofocus: true,
                            style: const TextStyle(
                              color: DashboardColors.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Category Name',
                              labelStyle: TextStyle(
                                color: DashboardColors.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                              hintText: 'e.g. Bóng Đá, Gym, ...',
                              hintStyle: TextStyle(
                                color: DashboardColors.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: DashboardColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'THEME COLOR',
                            style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                presetColors.map((hex) {
                                  final color = _parseHexColor(hex);
                                  final isSelected = selectedColor == hex;
                                  return GestureDetector(
                                    onTap:
                                        () => setDialogState(
                                          () => selectedColor = hex,
                                        ),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border:
                                            isSelected
                                                ? Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                )
                                                : null,
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: color.withValues(
                                                      alpha: 0.4,
                                                    ),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                                : null,
                                      ),
                                      child:
                                          isSelected
                                              ? const Icon(
                                                Icons.check_rounded,
                                                color: Colors.black,
                                                size: 16,
                                              )
                                              : null,
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'SELECT ICON',
                            style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: iconSearchController,
                            style: const TextStyle(
                              color: DashboardColors.onSurface,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Search icons (e.g. work, sports, code...)',
                              hintStyle: TextStyle(
                                color: DashboardColors.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: DashboardColors.onSurfaceVariant,
                                size: 18,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: DashboardColors.primary,
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              setDialogState(() {});
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 130,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Builder(
                                builder: (context) {
                                  final query =
                                      iconSearchController.text
                                          .trim()
                                          .toLowerCase();
                                  final filteredPresets =
                                      presetIcons
                                          .where((name) => name.contains(query))
                                          .toList();
                                  final List<String> displayIcons = [
                                    ...filteredPresets,
                                  ];
                                  if (query.isNotEmpty &&
                                      !displayIcons.contains(query)) {
                                    final customIcon = IconMapper.getIconData(
                                      query,
                                    );
                                    if (customIcon != Icons.circle &&
                                        customIcon != Icons.help_outline &&
                                        customIcon != Icons.error) {
                                      displayIcons.insert(0, query);
                                    }
                                  }

                                  if (displayIcons.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No icons found',
                                        style: TextStyle(
                                          color: DashboardColors
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }

                                  return GridView.builder(
                                    padding: const EdgeInsets.all(8),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 6,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                        ),
                                    itemCount: displayIcons.length,
                                    itemBuilder: (context, index) {
                                      final iconName = displayIcons[index];
                                      final iconData = IconMapper.getIconData(
                                        iconName,
                                      );
                                      final isSelected =
                                          selectedIconName == iconName;
                                      final color = _parseHexColor(
                                        selectedColor,
                                      );

                                      return GestureDetector(
                                        onTap:
                                            () => setDialogState(
                                              () => selectedIconName = iconName,
                                            ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? color.withValues(
                                                      alpha: 0.15,
                                                    )
                                                    : Colors.white.withValues(
                                                      alpha: 0.02,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? color
                                                      : Colors.white.withValues(
                                                        alpha: 0.05,
                                                      ),
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Icon(
                                            iconData,
                                            color:
                                                isSelected
                                                    ? color
                                                    : DashboardColors
                                                        .onSurfaceVariant,
                                            size: 20,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: DashboardColors.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          try {
                            final newCat = await onCreateCategory(
                              name,
                              selectedColor,
                              selectedIconName,
                            );
                            onCategoryChanged(newCat.id);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to create category: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Create',
                        style: TextStyle(
                          color: DashboardColors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    ).then((_) {
      nameController.dispose();
      iconSearchController.dispose();
    });
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
              Icon(
                Icons.edit_note_rounded,
                color: DashboardColors.primary,
                size: 24,
              ),
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
              hintStyle: TextStyle(
                color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color.fromRGBO(255, 255, 255, 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: DashboardColors.primary,
                  width: 1.5,
                ),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.015),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.08),
              ),
            ),
            child: QuillDescriptionEditor(
              taskId: taskId,
              initialText: initialDescription,
              minHeight: 100,
              maxHeight: 250,
              onChanged: onDescriptionChanged,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                GestureDetector(
                                  onTap: () {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (context.mounted) {
                                            _showCreateCategoryDialog(context);
                                          }
                                        });
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 2.0,
                                    ),
                                    child: Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: DashboardColors.primary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            PremiumSelectField(
                              value:
                                  selectedCategoryId?.isEmpty == true
                                      ? null
                                      : selectedCategoryId,
                              hint: 'Select Category',
                              sectionHeader: 'Categories',
                              searchable: true,
                              items:
                                  categories.map((cat) {
                                    final catColor = _parseHexColor(cat.color);
                                    return PremiumSelectItem(
                                      value: cat.id,
                                      label: cat.name,
                                      color: catColor,
                                      icon: _categoryIcon(cat.name, cat.icon),
                                    );
                                  }).toList(),
                              onChanged: onCategoryChanged,
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
                            PremiumDueDatePicker(
                              value: dueDate,
                              onChanged: onDueDateChanged,
                              durationMinutes:
                                  estimateHour * 60 + estimateMinute,
                              onDurationChanged: (mins) {
                                onEstimateChanged(mins ~/ 60, mins % 60);
                              },
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
                            PremiumSelectField(
                              value: selectedStatus,
                              sectionHeader: 'Status',
                              items: const [
                                PremiumSelectItem(
                                  value: 'draft',
                                  label: 'Draft',
                                  color: Color(0xFFA855F7),
                                  icon: Icons.edit_note_rounded,
                                ),
                                PremiumSelectItem(
                                  value: 'todo',
                                  label: 'To Do',
                                  color: Color(0xFF5B8CFF),
                                  icon: Icons.radio_button_unchecked_rounded,
                                ),
                                PremiumSelectItem(
                                  value: 'in_progress',
                                  label: 'In Progress',
                                  color: Color(0xFFFFB020),
                                  icon: Icons.hourglass_top_rounded,
                                ),
                                PremiumSelectItem(
                                  value: 'done',
                                  label: 'Completed',
                                  color: Color(0xFF34C759),
                                  icon: Icons.check_circle_outline_rounded,
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) onStatusChanged(val);
                              },
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.01),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color.fromRGBO(
                                    255,
                                    255,
                                    255,
                                    0.04,
                                  ),
                                ),
                              ),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ...selectedTagIds.map((tid) {
                                    final tag = tags.firstWhere(
                                      (t) => t.id == tid,
                                      orElse:
                                          () => TagModel(
                                            id: tid,
                                            name: tid,
                                            userId: '',
                                          ),
                                    );
                                    final tagColor = _parseHexColor(tag.color);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tagColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: tagColor.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '#${tag.name}',
                                            style: TextStyle(
                                              color: tagColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () => onRemoveTag(tid),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 12,
                                              color: tagColor,
                                            ),
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
                                    onCreateTag: onCreateTag,
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
                        child: TaskTimePickerCard(
                          label: 'ESTIMATED TIME',
                          icon: Icons.timer_outlined,
                          initialHour: estimateHour,
                          initialMinute: estimateMinute,
                          onChanged: onEstimateChanged,
                        ),
                      ),
                      SizedBox(width: isWide ? 20 : 12),
                      // Actual Time
                      Expanded(
                        child: TaskTimePickerCard(
                          label: 'ACTUAL TIME',
                          icon: Icons.history_rounded,
                          initialHour: actualHour,
                          initialMinute: actualMinute,
                          onChanged: onActualChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Priority Selection
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PRIORITY',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            PremiumSelectField(
                              value: selectedPriority,
                              sectionHeader: 'Priority',
                              items: const [
                                PremiumSelectItem(
                                  value: 'urgent',
                                  label: 'Urgent',
                                  color: DashboardColors.error,
                                  icon: Icons.priority_high_rounded,
                                ),
                                PremiumSelectItem(
                                  value: 'high',
                                  label: 'High',
                                  color: DashboardColors.error,
                                  icon: Icons.error_outline_rounded,
                                ),
                                PremiumSelectItem(
                                  value: 'medium',
                                  label: 'Medium',
                                  color: DashboardColors.warning,
                                  icon: Icons.warning_amber_rounded,
                                ),
                                PremiumSelectItem(
                                  value: 'low',
                                  label: 'Low',
                                  color: Color(0xFF3B82F6),
                                  icon: Icons.info_outline_rounded,
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) onPriorityChanged(val);
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isWide ? 20 : 12),
                      const Expanded(child: SizedBox.shrink()),
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
    required this.onCreateTag,
  });

  final List<TagModel> tags;
  final List<String> selectedTagIds;
  final ValueChanged<String> onAddTag;
  final Future<TagModel> Function(String name, String colorHex) onCreateTag;

  Future<void> _openTagPicker(BuildContext context) async {
    HapticFeedback.selectionClick();
    final selected = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close tag selector',
      barrierColor: Colors.black.withValues(alpha: 0.58),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder:
          (context, animation, secondaryAnimation) => _TagPickerDialog(
            tags: tags,
            selectedTagIds: selectedTagIds,
            onCreateTag: onCreateTag,
          ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (selected != null) onAddTag(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add tag',
      child: InkWell(
        onTap: () => _openTagPicker(context),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: DashboardColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: DashboardColors.primary.withValues(alpha: 0.28),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: DashboardColors.primary),
              SizedBox(width: 5),
              Text(
                'Add',
                style: TextStyle(
                  color: DashboardColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagPickerDialog extends StatefulWidget {
  const _TagPickerDialog({
    required this.tags,
    required this.selectedTagIds,
    required this.onCreateTag,
  });

  final List<TagModel> tags;
  final List<String> selectedTagIds;
  final Future<TagModel> Function(String name, String colorHex) onCreateTag;

  @override
  State<_TagPickerDialog> createState() => _TagPickerDialogState();
}

class _TagPickerDialogState extends State<_TagPickerDialog> {
  static const _tagColors = [
    '#8083FF',
    '#7CFFB2',
    '#FF6B9D',
    '#FFD166',
    '#06D6A0',
    '#38BDF8',
  ];

  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  String _query = '';
  String _selectedColorHex = _tagColors.first;
  bool _creating = false;
  String? _createError;

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return DashboardColors.primary;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  List<TagModel> get _filteredTags {
    final normalized = _query.trim().toLowerCase();
    final available = widget.tags.where(
      (tag) => !widget.selectedTagIds.contains(tag.id),
    );
    if (normalized.isEmpty) return available.toList();
    return available
        .where((tag) => tag.name.toLowerCase().contains(normalized))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createTag() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _creating) return;

    final exists = widget.tags.any(
      (tag) => tag.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      setState(() => _createError = 'Tag already exists');
      return;
    }

    setState(() {
      _creating = true;
      _createError = null;
    });

    try {
      final tag = await widget.onCreateTag(name, _selectedColorHex);
      if (!mounted) return;
      HapticFeedback.selectionClick();
      Navigator.of(context).pop(tag.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _createError = 'Could not create tag. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTags = _filteredTags;
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width < 520 ? width - 32 : 460.0;

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              width: dialogWidth,
              constraints: const BoxConstraints(maxHeight: 560),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF182033), Color(0xFF0E1423)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 50,
                    offset: const Offset(0, 24),
                  ),
                  BoxShadow(
                    color: DashboardColors.primary.withValues(alpha: 0.10),
                    blurRadius: 70,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 14, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: DashboardColors.primary.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: DashboardColors.primary.withValues(
                                alpha: 0.24,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.sell_rounded,
                            color: DashboardColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select tag',
                                style: TextStyle(
                                  color: DashboardColors.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Choose a label to organize this task',
                                style: TextStyle(
                                  color: DashboardColors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: DashboardColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (value) => setState(() => _query = value),
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search tags...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.32),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.38),
                          size: 20,
                        ),
                        suffixIcon:
                            _query.isEmpty
                                ? null
                                : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: DashboardColors.onSurfaceVariant,
                                    size: 18,
                                  ),
                                ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.055),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: DashboardColors.primary.withValues(
                              alpha: 0.75,
                            ),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.035),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: DashboardColors.primary.withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                color: DashboardColors.primary,
                                size: 17,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Create new tag',
                                style: TextStyle(
                                  color: DashboardColors.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  enabled: !_creating,
                                  onSubmitted: (_) => _createTag(),
                                  onChanged: (_) {
                                    if (_createError != null)
                                      setState(() => _createError = null);
                                  },
                                  style: const TextStyle(
                                    color: DashboardColors.onSurface,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Tag name...',
                                    errorText: _createError,
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.30,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.black.withValues(
                                      alpha: 0.12,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 12,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: DashboardColors.primary
                                            .withValues(alpha: 0.65),
                                        width: 1.3,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: DashboardColors.error.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: DashboardColors.error,
                                        width: 1.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 44,
                                child: FilledButton.icon(
                                  onPressed: _creating ? null : _createTag,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: DashboardColors.primary,
                                    disabledBackgroundColor: Colors.white
                                        .withValues(alpha: 0.08),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon:
                                      _creating
                                          ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: DashboardColors.onPrimary,
                                            ),
                                          )
                                          : const Icon(
                                            Icons.add_rounded,
                                            size: 18,
                                          ),
                                  label: Text(
                                    _creating ? 'Creating' : 'Create',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _tagColors.map((hex) {
                                  final color = _parseHexColor(hex);
                                  final selected = hex == _selectedColorHex;
                                  return InkWell(
                                    onTap:
                                        _creating
                                            ? null
                                            : () => setState(
                                              () => _selectedColorHex = hex,
                                            ),
                                    borderRadius: BorderRadius.circular(999),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              selected
                                                  ? Colors.white
                                                  : Colors.white.withValues(
                                                    alpha: 0.18,
                                                  ),
                                          width: selected ? 2.2 : 1,
                                        ),
                                        boxShadow:
                                            selected
                                                ? [
                                                  BoxShadow(
                                                    color: color.withValues(
                                                      alpha: 0.45,
                                                    ),
                                                    blurRadius: 12,
                                                  ),
                                                ]
                                                : null,
                                      ),
                                      child:
                                          selected
                                              ? const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                              : null,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child:
                        filteredTags.isEmpty
                            ? Padding(
                              padding: const EdgeInsets.fromLTRB(
                                28,
                                28,
                                28,
                                34,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_offer_outlined,
                                    color: Colors.white.withValues(alpha: 0.28),
                                    size: 34,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No tags found',
                                    style: TextStyle(
                                      color: DashboardColors.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Try another keyword or create more tags first.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.38,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                              itemCount: filteredTags.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final tag = filteredTags[index];
                                final color = _parseHexColor(tag.color);
                                return _TagPickerTile(
                                  tag: tag,
                                  color: color,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.of(context).pop(tag.id);
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagPickerTile extends StatefulWidget {
  const _TagPickerTile({
    required this.tag,
    required this.color,
    required this.onTap,
  });

  final TagModel tag;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_TagPickerTile> createState() => _TagPickerTileState();
}

class _TagPickerTileState extends State<_TagPickerTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          Future.microtask(() {
            if (mounted) setState(() => _hovered = true);
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          Future.microtask(() {
            if (mounted) setState(() => _hovered = false);
          });
        }
      },
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                _hovered
                    ? Colors.white.withValues(alpha: 0.075)
                    : Colors.white.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  _hovered
                      ? widget.color.withValues(alpha: 0.36)
                      : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.36),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#',
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.tag.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color:
                      _hovered
                          ? widget.color.withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color:
                      _hovered
                          ? widget.color
                          : DashboardColors.onSurfaceVariant,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
