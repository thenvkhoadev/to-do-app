import 'package:flutter/material.dart';
import 'package:string_to_icon/string_to_icon.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/data/models/task_subtask_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskOverviewCards extends StatelessWidget {
  const TaskOverviewCards({
    required this.priority,
    required this.status,
    required this.categoryId,
    required this.categories,
    required this.dueDate,
    required this.subtasks,
    required this.estimateMinutes,
    required this.actualMinutes,
    required this.attachmentsCount,
    required this.hasDescription,
    required this.tagsCount,
    required this.isMobile,
    super.key,
  });

  final String priority;
  final String status;
  final String? categoryId;
  final List<CategoryModel> categories;
  final DateTime? dueDate;
  final List<TaskSubtaskModel> subtasks;
  final int estimateMinutes;
  final int actualMinutes;
  final int attachmentsCount;
  final bool hasDescription;
  final int tagsCount;
  final bool isMobile;

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return DashboardColors.primary;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _getCategoryIcon(String name, String? icon) {
    final cleanName = name.trim().toLowerCase();
    if (icon != null && icon.trim().isNotEmpty) {
      final codeIcon = IconMapper.getIconData(icon.trim().toLowerCase());
      if (codeIcon != Icons.circle &&
          codeIcon != Icons.help_outline &&
          codeIcon != Icons.error) {
        return codeIcon;
      }
    }
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
    final nameIcon = IconMapper.getIconData(lookupKey);
    if (nameIcon != Icons.circle &&
        nameIcon != Icons.help_outline &&
        nameIcon != Icons.error) {
      return nameIcon;
    }
    return Icons.folder_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Priority details
    final priorityStr = priority.toUpperCase();
    final priorityColor = switch (priority.toLowerCase()) {
      'urgent' || 'high' => DashboardColors.error,
      'medium' => DashboardColors.warning,
      _ => const Color(0xFF3B82F6),
    };
    final priorityIcon = switch (priority.toLowerCase()) {
      'urgent' || 'high' => Icons.priority_high_rounded,
      'medium' => Icons.warning_rounded,
      _ => Icons.info_rounded,
    };

    // 2. Status details
    final statusStr = switch (status.toLowerCase()) {
      'draft' => 'DRAFT',
      'todo' => 'TO DO',
      'in_progress' => 'IN PROGRESS',
      'done' || 'completed' => 'COMPLETED',
      _ => 'TO DO',
    };
    final statusColor = switch (status.toLowerCase()) {
      'draft' => const Color(0xFFA855F7),
      'todo' => const Color(0xFF5B8CFF),
      'in_progress' => const Color(0xFFFFB020),
      'done' || 'completed' => const Color(0xFF34C759),
      _ => const Color(0xFF5B8CFF),
    };
    final statusIcon = switch (status.toLowerCase()) {
      'draft' => Icons.edit_note_rounded,
      'todo' => Icons.radio_button_unchecked_rounded,
      'in_progress' => Icons.hourglass_top_rounded,
      'done' || 'completed' => Icons.check_circle_outline_rounded,
      _ => Icons.radio_button_unchecked_rounded,
    };

    // 3. Category details
    final selectedCategory = categoryId == null || categoryId!.isEmpty
        ? null
        : categories.firstWhere(
            (c) => c.id == categoryId,
            orElse: () => const CategoryModel(id: '', userId: '', name: ''),
          );
    final categoryName = (selectedCategory == null || selectedCategory.name.isEmpty)
        ? 'None'
        : selectedCategory.name;
    final categoryColor = (selectedCategory == null || selectedCategory.color == null)
        ? const Color(0xFF64748B)
        : _parseHexColor(selectedCategory.color);
    final categoryIcon = selectedCategory == null
        ? Icons.folder_open_rounded
        : _getCategoryIcon(selectedCategory.name, selectedCategory.icon);

    // 4. Due Date details
    String dueDateStr = 'No Limit';
    bool isOverdue = false;
    if (dueDate != null) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dueDateStr = '${months[dueDate!.month - 1]} ${dueDate!.day}, ${dueDate!.year}';
      if (status.toLowerCase() != 'done' && status.toLowerCase() != 'completed') {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
        if (due.isBefore(today)) {
          isOverdue = true;
        }
      }
    }
    final dueDateColor = isOverdue ? const Color(0xFFF43F5E) : const Color(0xFF818CF8);

    // 5. XP Reward details
    final baseXp = switch (priority.toLowerCase()) {
      'urgent' => 100,
      'high' => 50,
      'medium' => 20,
      _ => 10,
    };
    final subtaskBonus = subtasks.length * 5;
    final totalXp = baseXp + subtaskBonus;

    // 6. AI Score details
    int aiScore = 40;
    if (hasDescription) aiScore += 15;
    if (dueDate != null) aiScore += 10;
    if (estimateMinutes > 0) aiScore += 15;
    if (categoryId != null && categoryId!.isNotEmpty) aiScore += 10;
    aiScore += (tagsCount * 5).clamp(0, 10);
    if (subtasks.isNotEmpty) aiScore += 10;
    if (hasDescription && dueDate != null && estimateMinutes > 0 && categoryId != null && categoryId!.isNotEmpty && tagsCount > 0 && subtasks.isNotEmpty) {
      aiScore += 5;
    }
    aiScore = aiScore.clamp(0, 100);

    final aiScoreColor = aiScore >= 80
        ? DashboardColors.success
        : aiScore >= 60
            ? DashboardColors.warning
            : const Color(0xFF3B82F6);

    // 7. Progress details
    final totalSubtasks = subtasks.length;
    final completedSubtasks = subtasks.where((s) => s.isDone).length;
    final subtaskPct = totalSubtasks > 0 ? (completedSubtasks / totalSubtasks) : 0.0;
    final progressStr = totalSubtasks > 0 
        ? '$completedSubtasks/$totalSubtasks (${(subtaskPct * 100).round()}%)'
        : '0%';

    // 8. Est. Time details
    final estHours = estimateMinutes ~/ 60;
    final estMins = estimateMinutes % 60;
    final estimateStr = estimateMinutes > 0 
        ? '${estHours}h ${estMins.toString().padLeft(2, '0')}m'
        : 'Not Set';

    // 9. Actual Time details
    final actHours = actualMinutes ~/ 60;
    final actMins = actualMinutes % 60;
    final actualStr = actualMinutes > 0 
        ? '${actHours}h ${actMins.toString().padLeft(2, '0')}m'
        : '0h 00m';

    // 10. Attachments details
    final attachmentsStr = attachmentsCount == 0 
        ? 'None' 
        : '$attachmentsCount File${attachmentsCount > 1 ? 's' : ''}';

    // Responsiveness rules
    final int crossAxisCount;
    final double childAspectRatio;
    if (isMobile) {
      crossAxisCount = 2;
      childAspectRatio = 1.75;
    } else {
      final double width = MediaQuery.of(context).size.width;
      if (width < 1200) {
        crossAxisCount = 3;
        childAspectRatio = 2.2;
      } else {
        crossAxisCount = 5;
        childAspectRatio = 2.8;
      }
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isMobile ? 12 : 16,
      mainAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: childAspectRatio,
      children: [
        // 1. Priority Card (Read-only)
        _OverviewCard(
          icon: priorityIcon,
          label: 'Priority',
          value: priorityStr,
          color: priorityColor,
          isMobile: isMobile,
          bottomWidget: Text(
            'Task urgency level',
            style: TextStyle(
              color: priorityColor.withValues(alpha: 0.6),
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 2. Status Card (Read-only)
        _OverviewCard(
          icon: statusIcon,
          label: 'Status',
          value: statusStr,
          color: statusColor,
          isMobile: isMobile,
          bottomWidget: Text(
            'Workflow state',
            style: TextStyle(
              color: statusColor.withValues(alpha: 0.6),
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 3. Category Card (Read-only)
        _OverviewCard(
          icon: categoryIcon,
          label: 'Category',
          value: categoryName,
          color: categoryColor,
          isMobile: isMobile,
          bottomWidget: Text(
            'Grouping folder',
            style: TextStyle(
              color: categoryColor.withValues(alpha: 0.6),
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 4. Due Date Card (Read-only)
        _OverviewCard(
          icon: Icons.calendar_today_rounded,
          label: 'Due Date',
          value: dueDateStr,
          color: dueDateColor,
          isMobile: isMobile,
          bottomWidget: Text(
            isOverdue ? 'Task is overdue!' : 'Target completion date',
            style: TextStyle(
              color: dueDateColor.withValues(alpha: 0.6),
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 5. XP Reward Card (Read-only)
        _OverviewCard(
          icon: Icons.stars_rounded,
          label: 'XP Reward',
          value: '+$totalXp XP',
          color: const Color(0xFFA855F7),
          isMobile: isMobile,
          shimmer: true,
          bottomWidget: Text(
            '$baseXp Base + $subtaskBonus Bonus',
            style: TextStyle(
              color: const Color(0xFFA855F7).withValues(alpha: 0.6),
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 6. AI Score Card (Read-only)
        _OverviewCard(
          icon: Icons.psychology_rounded,
          label: 'AI Score',
          value: '$aiScore%',
          color: aiScoreColor,
          isMobile: isMobile,
          bottomWidget: Text(
            aiScore >= 80 ? 'Optimal Setup' : 'Metadata incomplete',
            style: TextStyle(
              color: aiScoreColor.withValues(alpha: 0.6),
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 7. Subtask Progress Card (Read-only)
        _OverviewCard(
          icon: Icons.playlist_add_check_rounded,
          label: 'Subtasks',
          value: progressStr,
          color: const Color(0xFF06B6D4),
          isMobile: isMobile,
          bottomWidget: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: totalSubtasks > 0
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: subtaskPct,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF06B6D4)),
                      minHeight: 3,
                    ),
                  )
                : Text(
                    'No subtasks created',
                    style: TextStyle(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.6),
                      fontSize: isMobile ? 8 : 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),

        // 8. Est. Time Card (Read-only)
        _OverviewCard(
          icon: Icons.timer_rounded,
          label: 'Est. Time',
          value: estimateStr,
          color: const Color(0xFFF97316),
          isMobile: isMobile,
          bottomWidget: Text(
            estimateMinutes > 0 ? 'Allocated duration' : 'No time estimate',
            style: TextStyle(
              color: const Color(0xFFF97316).withValues(alpha: 0.6),
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 9. Actual Time Card (Read-only)
        _OverviewCard(
          icon: Icons.history_toggle_off_rounded,
          label: 'Actual Time',
          value: actualStr,
          color: const Color(0xFF10B981),
          isMobile: isMobile,
          bottomWidget: Text(
            actualMinutes > 0 ? 'Time tracked so far' : 'No tracked progress',
            style: TextStyle(
              color: const Color(0xFF10B981).withValues(alpha: 0.6),
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 10. Attachments Card (Read-only)
        _OverviewCard(
          icon: Icons.attach_file_rounded,
          label: 'Attachments',
          value: attachmentsStr,
          color: const Color(0xFF818CF8),
          isMobile: isMobile,
          bottomWidget: Text(
            attachmentsCount > 0 ? 'Uploaded materials' : 'No attachments',
            style: TextStyle(
              color: const Color(0xFF818CF8).withValues(alpha: 0.6),
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatefulWidget {
  const _OverviewCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isMobile,
    this.bottomWidget,
    this.shimmer = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isMobile;
  final Widget? bottomWidget;
  final bool shimmer;

  @override
  State<_OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends State<_OverviewCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController? _shimmerController;

  @override
  void initState() {
    super.initState();
    if (widget.shimmer) {
      _shimmerController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat();
    } else {
      _shimmerController = null;
    }
  }

  @override
  void didUpdateWidget(covariant _OverviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shimmer != oldWidget.shimmer) {
      if (widget.shimmer) {
        _shimmerController ??= AnimationController(
          vsync: this,
          duration: const Duration(seconds: 2),
        );
        _shimmerController!.repeat();
      } else {
        _shimmerController?.stop();
        _shimmerController?.dispose();
        _shimmerController = null;
      }
    }
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.isMobile
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 6);

    final iconSize = widget.isMobile ? 16.0 : 18.0;
    final iconBoxSize = widget.isMobile ? 32.0 : 38.0;
    final valueFontSize = widget.isMobile ? 13.0 : 15.0;
    final labelFontSize = widget.isMobile ? 8.0 : 9.0;
    final bottomSpacer = widget.isMobile ? 1.0 : 2.0;

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isHovered
              ? widget.color.withValues(alpha: 0.3)
              : const Color.fromRGBO(255, 255, 255, 0.08),
          width: 1,
        ),
        boxShadow: [
          if (_isHovered)
            BoxShadow(
              color: widget.color.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 0,
            ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label.toUpperCase(),
                      style: TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.value,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.bottomWidget != null) ...[
                      SizedBox(height: bottomSpacer),
                      widget.bottomWidget!,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: widget.color, size: iconSize),
              ),
            ],
          ),
          if (widget.shimmer && _shimmerController != null)
            AnimatedBuilder(
              animation: _shimmerController!,
              builder: (context, child) {
                return Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: const [
                            Colors.transparent,
                            Color.fromRGBO(255, 255, 255, 0.05),
                            Colors.transparent,
                          ],
                          stops: [
                            _shimmerController!.value - 0.2,
                            _shimmerController!.value,
                            _shimmerController!.value + 0.2,
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );

    return MouseRegion(
      onEnter:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = true);
          }),
      onExit:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = false);
          }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        child: cardContent,
      ),
    );
  }
}
