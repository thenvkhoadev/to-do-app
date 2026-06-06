import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:to_do_app/features/tasks/data/models/task_subtask_model.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/glass_container.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/screens/task_details/widgets/attachment_preview_dialog.dart';
import 'package:to_do_app/core/utils/description_utils.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';

class TaskDetailPanel extends ConsumerStatefulWidget {
  const TaskDetailPanel({
    required this.task,
    this.onClose,
    this.onViewDetails,
    super.key,
  });

  final TaskBoardItem task;
  final VoidCallback? onClose;
  final VoidCallback? onViewDetails;

  @override
  ConsumerState<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends ConsumerState<TaskDetailPanel> {
  final _commentController = TextEditingController();
  List<Map<String, String>> _comments = [];

  @override
  void initState() {
    super.initState();
    // Prepopulate some comments for mock realism
    _comments = [
      {
        'author': 'A',
        'name': 'Alex',
        'text': 'Great progress on this! Timeline looks perfect.'
      },
      {
        'author': 'K',
        'name': 'Khoa',
        'text': 'Need revision on UI alignment before final push.'
      },
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(taskAttachmentsProvider(widget.task.id));
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _showEditDialog() async {
    try {
      final tasks = ref.read(userTasksProvider).valueOrNull ?? [];
      final nexusTask = tasks.firstWhere(
        (t) => t.id == widget.task.id,
        orElse: () => throw Exception('Không tìm thấy task trong database'),
      );

      final titleController = TextEditingController(text: nexusTask.title);
      final descController = TextEditingController(text: parseDescriptionToPlainText(nexusTask.description));
      final estController = TextEditingController(text: nexusTask.estimatedMinutes?.toString() ?? '');
      String priority = nexusTask.priority.toLowerCase();
      DateTime? dueDate = nexusTask.dueDate;

      if (priority != 'low' && priority != 'medium' && priority != 'high' && priority != 'urgent') {
        priority = 'medium';
      }

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: DashboardColors.surfaceLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Colors.white12),
                ),
                title: const Text('Chỉnh sửa công việc', style: TextStyle(color: DashboardColors.onSurface, fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: DashboardColors.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề',
                          labelStyle: TextStyle(color: DashboardColors.onSurfaceVariant),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: DashboardColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        style: const TextStyle(color: DashboardColors.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                          labelStyle: TextStyle(color: DashboardColors.onSurfaceVariant),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: DashboardColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        dropdownColor: DashboardColors.surfaceLow,
                        initialValue: priority,
                        style: const TextStyle(color: DashboardColors.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Độ ưu tiên',
                          labelStyle: TextStyle(color: DashboardColors.onSurfaceVariant),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              priority = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: estController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: DashboardColors.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Thời gian ước tính (phút)',
                          labelStyle: TextStyle(color: DashboardColors.onSurfaceVariant),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: DashboardColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dueDate == null
                                  ? 'Chưa chọn hạn chót'
                                  : 'Hạn chót: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                              style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dueDate ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  dueDate = picked;
                                });
                              }
                            },
                            child: const Text('Chọn ngày', style: TextStyle(color: DashboardColors.primary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy', style: TextStyle(color: DashboardColors.onSurfaceVariant)),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: DashboardColors.primaryContainer),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      final newDescText = descController.text.trim();
                      final String? finalDescription;
                      if (newDescText == parseDescriptionToPlainText(nexusTask.description)) {
                        finalDescription = nexusTask.description;
                      } else {
                        finalDescription = newDescText.isEmpty ? null : newDescText;
                      }

                      final updated = nexusTask.copyWith(
                        title: title,
                        description: finalDescription,
                        priority: priority,
                        estimatedMinutes: int.tryParse(estController.text),
                        dueDate: dueDate,
                      );

                      await ref.read(taskRepositoryProvider).updateTask(updated);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã cập nhật công việc thành công')),
                        );
                      }
                    },
                    child: const Text('Lưu', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _completeTask() async {
    try {
      final tasks = ref.read(userTasksProvider).valueOrNull ?? [];
      final nexusTask = tasks.firstWhere(
        (t) => t.id == widget.task.id,
        orElse: () => throw Exception('Không tìm thấy task trong database'),
      );
      final updated = nexusTask.copyWith(
        status: 'done',
        completedAt: DateTime.now().toUtc(),
      );
      await ref.read(taskRepositoryProvider).updateTask(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hoàn thành công việc!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _postComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.add({
        'author': 'U',
        'name': 'You',
        'text': text,
      });
      _commentController.clear();
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildBlockProgressBar(double value) {
    final filledBlocks = (value * 10).round().clamp(0, 10);
    return Row(
      children: [
        for (int i = 0; i < 10; i++)
          Container(
            width: 14,
            height: 8,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i < filledBlocks
                  ? const Color(0xff6366F1)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickInfoRow(IconData icon, String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white30, size: 16),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Widget _buildQuickInfoSection(TaskBoardItem task, double progressValue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          _buildQuickInfoRow(
            Icons.calendar_today_rounded,
            'Due Date',
            Text(
              task.dueDate != null ? _formatDate(task.dueDate!) : 'No Due Date',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildQuickInfoRow(
            Icons.timer_outlined,
            'Estimate',
            Text(
              task.estimate.isNotEmpty ? task.estimate : '–',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildQuickInfoRow(
            Icons.person_outline_rounded,
            'Assignee',
            Text(
              task.assignee.isNotEmpty ? task.assignee : 'Unassigned',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildQuickInfoRow(
            Icons.account_circle_outlined,
            'Creator',
            Text(
              task.creatorName != null && task.creatorName!.isNotEmpty ? task.creatorName! : 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildQuickInfoRow(
            Icons.trending_up_rounded,
            'Progress',
            Row(
              children: [
                _buildBlockProgressBar(progressValue),
                const SizedBox(width: 10),
                Text(
                  '${(progressValue * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPriorityBadge(TaskBoardPriority priority) {
    final label = switch (priority) {
      TaskBoardPriority.urgent => 'URGENT',
      TaskBoardPriority.high => 'HIGH PRIORITY',
      TaskBoardPriority.medium => 'MED PRIORITY',
      TaskBoardPriority.low => 'LOW PRIORITY',
      TaskBoardPriority.done => 'DONE',
    };
    final color = switch (priority) {
      TaskBoardPriority.urgent => const Color(0xffEF4444),
      TaskBoardPriority.high => const Color(0xffF97316),
      TaskBoardPriority.medium => const Color(0xff3B82F6),
      TaskBoardPriority.low => const Color(0xff14B8A6),
      TaskBoardPriority.done => const Color(0xff10B981),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAiStatusBadge(TaskBoardStatus status) {
    final label = switch (status) {
      TaskBoardStatus.draft => 'DRAFT',
      TaskBoardStatus.todo => 'TODO',
      TaskBoardStatus.inProgress => 'IN PROGRESS',
      TaskBoardStatus.completed => 'COMPLETED',
    };
    final color = switch (status) {
      TaskBoardStatus.draft => Colors.white30,
      TaskBoardStatus.todo => const Color(0xffA78BFA),
      TaskBoardStatus.inProgress => const Color(0xff3B82F6),
      TaskBoardStatus.completed => const Color(0xff10B981),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAiSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI SUMMARY',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.task.aiSuggestion ??
                'AI Analysis: Recommend completing key design layout drafts and wiring subtask events first to accelerate delivery timeline.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPriorityAnalysis() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRIORITY RATIONALE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Colors.orangeAccent.withValues(alpha: 0.8),
                size: 14,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Blocks 3 critical components.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiTimeEstimation() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SMART ESTIMATE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.cyanAccent.withValues(alpha: 0.8),
                size: 14,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'AI predicts 5h 30m.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiDeadlineRisk() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffEF4444).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xffEF4444).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xffEF4444), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'AI RISK DETECTED',
                  style: TextStyle(
                    color: Color(0xffEF4444),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'High scheduling conflict on due date. 3 other tasks are also due.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiProductivityScore() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xff10B981).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xff10B981).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.military_tech_rounded,
                  color: Color(0xff10B981), size: 18),
              SizedBox(width: 8),
              Text(
                'Productivity Reward',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xff10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '+150 XP',
              style: TextStyle(
                color: Color(0xff10B981),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAutoScheduleBtn() {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('AI has auto-scheduled this task at the optimal free slot!'),
              ],
            ),
            backgroundColor: Color(0xff6366F1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xff8B5CF6).withValues(alpha: 0.2),
              const Color(0xff6366F1).withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xff8B5CF6).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xff8B5CF6), Color(0xff6366F1)],
              ).createShader(bounds),
              child: const Icon(Icons.calendar_today_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'AI Auto Schedule',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNexusAiCenter() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xff8B5CF6).withValues(alpha: 0.05),
            const Color(0xff6366F1).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xff8B5CF6).withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xff8B5CF6), Color(0xff6366F1)],
                ).createShader(bounds),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'NEXUS AI COMMAND CENTER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAiSummary(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildAiPriorityAnalysis()),
              const SizedBox(width: 10),
              Expanded(child: _buildAiTimeEstimation()),
            ],
          ),
          const SizedBox(height: 12),
          _buildAiDeadlineRisk(),
          const SizedBox(height: 12),
          _buildAiProductivityScore(),
          const SizedBox(height: 14),
          _buildAiAutoScheduleBtn(),
        ],
      ),
    );
  }

  Widget _buildSmartCommentChips() {
    final templates = [
      '✨ Looks great!',
      '⚠️ Reviewing blockers',
      '💬 Needs design sync',
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: templates.map((t) {
        return InkWell(
          onTap: () {
            _commentController.text = t;
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xff8B5CF6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xff8B5CF6).withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              t,
              style: const TextStyle(
                color: Color(0xffa78bfa),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COMMENTS',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _comments.length,
          itemBuilder: (context, index) {
            final comment = _comments[index];
            final author = comment['author'] ?? 'U';
            final name = comment['name'] ?? 'User';
            final text = comment['text'] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: author == 'A'
                        ? const Color(0xff8B5CF6)
                        : author == 'K'
                            ? const Color(0xff06B6D4)
                            : const Color(0xff6366F1),
                    child: Text(
                      author,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildSmartCommentChips(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Write comment...',
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (val) => _postComment(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: Color(0xff6366F1), size: 18),
              onPressed: _postComment,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    final tasksAsync = ref.watch(userTasksProvider);
    final allTasks = tasksAsync.valueOrNull ?? const <NexusTask>[];
    final allUsers = ref.watch(allUsersProvider).valueOrNull ?? [];
    final assigneeIdsAsync = ref.watch(taskAssigneeIdsProvider(widget.task.id));
    final assigneeIds = assigneeIdsAsync.valueOrNull ?? const <String>[];
    
    // Find matching task from provider for live update
    final nexusTask = allTasks.where((t) => t.id == widget.task.id).firstOrNull;
    
    final task = (() {
      final boardStatus = nexusTask != null 
          ? (switch (nexusTask.status) {
              'draft' => TaskBoardStatus.draft,
              'todo' => TaskBoardStatus.todo,
              'in_progress' => TaskBoardStatus.inProgress,
              'done' => TaskBoardStatus.completed,
              _ => TaskBoardStatus.todo,
            })
          : widget.task.status;

      final boardPriority = nexusTask != null
          ? (switch (nexusTask.priority.toLowerCase()) {
              'low' => TaskBoardPriority.low,
              'medium' => TaskBoardPriority.medium,
              'high' => TaskBoardPriority.high,
              'urgent' => TaskBoardPriority.urgent,
              _ => TaskBoardPriority.medium,
            })
          : widget.task.priority;

      final estimate = nexusTask != null
          ? (nexusTask.estimatedMinutes != null ? '${nexusTask.estimatedMinutes}m' : '')
          : widget.task.estimate;

      final userId = nexusTask?.userId ?? widget.task.userId;

      // Filter out the owner (userId) from the assignee list to get only other collaborators
      final displayAssigneeIds = assigneeIds.where((id) => id != userId).toList();
      String resolvedAssigneeName = 'Unassigned';

      if (displayAssigneeIds.isNotEmpty) {
        final collaboratorNames = <String>[];
        for (final id in displayAssigneeIds) {
          final user = allUsers.firstWhere(
            (u) => u.id == id,
            orElse: () => UserProfileModel(id: id, email: ''),
          );
          String name;
          if (user.fullName != null && user.fullName!.trim().isNotEmpty) {
            name = user.fullName!;
          } else if (user.username != null && user.username!.isNotEmpty) {
            name = user.username!;
          } else if (user.email.isNotEmpty) {
            name = user.email;
          } else {
            name = (widget.task.assignee.isNotEmpty && widget.task.assignee != 'AI')
                ? widget.task.assignee
                : 'User (${id.substring(0, 4)})';
          }
          collaboratorNames.add(name);
        }

        if (collaboratorNames.length == 1) {
          resolvedAssigneeName = collaboratorNames[0];
        } else if (collaboratorNames.length == 2) {
          resolvedAssigneeName = '${collaboratorNames[0]}, ${collaboratorNames[1]}';
        } else {
          resolvedAssigneeName = '${collaboratorNames[0]}, ${collaboratorNames[1]} +${collaboratorNames.length - 2}';
        }
      } else {
        resolvedAssigneeName = widget.task.assignee.isNotEmpty && widget.task.assignee != 'AI'
            ? widget.task.assignee
            : 'Unassigned';
      }

      String? resolvedCreatorName;
      if (userId != null && userId.isNotEmpty) {
        final creatorUser = allUsers.firstWhere(
          (u) => u.id == userId,
          orElse: () => UserProfileModel(id: '', email: ''),
        );
        if (creatorUser.fullName != null && creatorUser.fullName!.trim().isNotEmpty) {
          resolvedCreatorName = creatorUser.fullName;
        } else if (creatorUser.username != null && creatorUser.username!.isNotEmpty) {
          resolvedCreatorName = creatorUser.username;
        } else if (creatorUser.email.isNotEmpty) {
          resolvedCreatorName = creatorUser.email;
        }
      }
      resolvedCreatorName ??= widget.task.creatorName;

      return TaskBoardItem(
        id: nexusTask?.id ?? widget.task.id,
        title: nexusTask?.title ?? widget.task.title,
        description: nexusTask?.description ?? widget.task.description,
        status: boardStatus,
        priority: boardPriority,
        estimate: estimate,
        assignee: resolvedAssigneeName,
        progress: boardStatus == TaskBoardStatus.completed ? 1.0 : (boardStatus == TaskBoardStatus.inProgress ? 0.5 : 0.0),
        tags: widget.task.tags,
        completed: boardStatus == TaskBoardStatus.completed,
        dueDate: nexusTask != null ? nexusTask.dueDate : widget.task.dueDate,
        dueLabel: nexusTask != null
            ? (nexusTask.dueDate != null ? '${nexusTask.dueDate!.day}/${nexusTask.dueDate!.month}' : null)
            : widget.task.dueLabel,
        createdAt: nexusTask?.createdAt ?? widget.task.createdAt,
        updatedAt: nexusTask?.updatedAt ?? widget.task.updatedAt,
        aiSuggestion: widget.task.aiSuggestion,
        creatorName: resolvedCreatorName,
        userId: userId,
      );
    })();

    final subtasksAsync = ref.watch(taskSubtasksProvider(widget.task.id));
    double progressValue = task.progress;
    subtasksAsync.whenOrNull(
      data: (subtasks) {
        if (subtasks.isNotEmpty) {
          final doneCount = subtasks.where((s) => s.isDone).length;
          progressValue = doneCount / subtasks.length;
        }
      },
    );

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.18),
            blurRadius: 40,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B1020).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: SafeArea(
              left: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildAiPriorityBadge(task.priority),
                            const SizedBox(width: 8),
                            _buildAiStatusBadge(task.status),
                            const Spacer(),
                            IconButton(
                              onPressed: widget.onClose,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          task.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                      color: Colors.white.withValues(alpha: .07), height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildQuickInfoSection(task, progressValue),
                        const SizedBox(height: 24),
                        _PanelSection(
                          title: 'Description',
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: task.description.isNotEmpty
                                ? buildRichTextDescription(
                                    task.description,
                                    const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  )
                                : const Text(
                                    'No description provided.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildNexusAiCenter(),
                        const SizedBox(height: 24),
                        _SubtaskSection(taskId: task.id),
                        const SizedBox(height: 24),
                        _buildAttachmentsSection(context, ref),
                        const SizedBox(height: 24),
                        _buildCommentsSection(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: widget.onViewDetails,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xff6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text(
                            'View Task Detail',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showEditDialog,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.15)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: const Text(
                                  'Sửa',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _completeTask,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.15)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text(
                                  'Complete',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildAttachmentsSection(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = ref.watch(taskAttachmentsProvider(widget.task.id));

    return _PanelSection(
      title: 'Attachments',
      badge: null,
      trailing: IconButton(
        icon: const Icon(Icons.refresh_rounded,
            size: 16, color: DashboardColors.onSurfaceVariant),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Refresh attachments',
        onPressed: () =>
            ref.invalidate(taskAttachmentsProvider(widget.task.id)),
      ),
      child: attachmentsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (err, stack) => Text(
          'Error loading attachments: $err',
          style: const TextStyle(color: DashboardColors.error, fontSize: 12),
        ),
        data: (attachments) {
          if (attachments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No attachments',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Files attached to this task will appear here.',
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: attachments.map((att) {
              final ext = att.fileName.split('.').last.toLowerCase();
              final isImage = att.mimeType.startsWith('image/') ||
                  ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext);
              final isPdf = att.mimeType == 'application/pdf' || ext == 'pdf';
              final isWord = ['doc', 'docx'].contains(ext) || 
                  att.mimeType.contains('word') || 
                  att.mimeType.contains('officedocument.wordprocessingml');
              final isExcel = ['xls', 'xlsx'].contains(ext) || 
                  att.mimeType.contains('excel') || 
                  att.mimeType.contains('officedocument.spreadsheetml');

              return AttachmentSizeWidget(
                url: att.fileUrl,
                builder: (context, sizeStr) {
                  return InkWell(
                    onTap: () => AttachmentPreviewDialog.show(context, att),
                    borderRadius: BorderRadius.circular(12),
                    child: _Attachment(
                      icon: isImage
                          ? Icons.image_rounded
                          : isPdf
                              ? Icons.picture_as_pdf_rounded
                              : isWord
                                  ? Icons.description_rounded
                                  : isExcel
                                      ? Icons.table_view_rounded
                                      : Icons.insert_drive_file_rounded,
                      title: att.fileName,
                      size: '${ext.toUpperCase()} • $sizeStr',
                      color: isImage
                          ? const Color(0xff6366F1)
                          : isPdf
                              ? const Color(0xffEF4444)
                              : isWord
                                  ? const Color(0xff3B82F6)
                                  : isExcel
                                      ? const Color(0xff10B981)
                                      : const Color(0xff14B8A6),
                      imageUrl: isImage ? att.fileUrl : null,
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _PanelSection extends StatelessWidget {
  const _PanelSection({
    required this.title,
    required this.child,
    this.badge,
    this.trailing,
  });

  final String title;
  final Widget child;
  final String? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              if (badge != null || trailing != null) const Spacer(),
              if (badge != null)
                Text(
                  badge!,
                  style: const TextStyle(
                    color: DashboardColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      );
}

class _SubtaskSection extends ConsumerStatefulWidget {
  const _SubtaskSection({required this.taskId});
  final String taskId;

  @override
  ConsumerState<_SubtaskSection> createState() => _SubtaskSectionState();
}

class _SubtaskSectionState extends ConsumerState<_SubtaskSection> {
  final _textController = TextEditingController();
  bool _isAdding = false;
  bool _isGenerating = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _addSubtask(String title) async {
    if (title.trim().isEmpty) return;
    try {
      final subtask = TaskSubtaskModel(
        id: '',
        taskId: widget.taskId,
        title: title.trim(),
        isDone: false,
      );
      await ref.read(subtaskDataSourceProvider).createSubtask(subtask);
      ref.invalidate(taskSubtasksProvider(widget.taskId));
      _textController.clear();
      setState(() {
        _isAdding = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add subtask: $e')),
      );
    }
  }

  Future<void> _toggleSubtask(TaskSubtaskModel subtask, bool value) async {
    try {
      await ref
          .read(subtaskDataSourceProvider)
          .updateSubtask(subtask.id, {'is_done': value});
      ref.invalidate(taskSubtasksProvider(widget.taskId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update subtask: $e')),
      );
    }
  }

  Future<void> _deleteSubtask(String id) async {
    try {
      await ref.read(subtaskDataSourceProvider).deleteSubtask(id);
      ref.invalidate(taskSubtasksProvider(widget.taskId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete subtask: $e')),
      );
    }
  }

  Future<void> _toggleAll(List<TaskSubtaskModel> subtasks, bool checkAll) async {
    try {
      final datasource = ref.read(subtaskDataSourceProvider);
      await Future.wait(subtasks.map((s) => datasource.updateSubtask(s.id, {'is_done': checkAll})));
      ref.invalidate(taskSubtasksProvider(widget.taskId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update subtasks: $e')),
      );
    }
  }

  Future<void> _generateWithAi() async {
    setState(() {
      _isGenerating = true;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    try {
      final suggested = [
        'Review architecture guidelines',
        'Write integration test suite',
        'Verify schema compatibility',
      ];
      final datasource = ref.read(subtaskDataSourceProvider);
      final subtasks = suggested
          .map((t) => TaskSubtaskModel(
                id: '',
                taskId: widget.taskId,
                title: t,
                isDone: false,
              ))
          .toList();
      await datasource.insertMultipleSubtasks(subtasks);
      ref.invalidate(taskSubtasksProvider(widget.taskId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate subtasks: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtasksAsync = ref.watch(taskSubtasksProvider(widget.taskId));

    return _PanelSection(
      title: 'Subtasks',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isGenerating)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          else
            InkWell(
              onTap: _generateWithAi,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff8B5CF6),
                      Color(0xff6366F1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome_rounded,
                        size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'AI Generate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      child: GlassContainer(
        radius: 18,
        padding: const EdgeInsets.all(16),
        child: subtasksAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (err, stack) => Text(
            'Error: $err',
            style: const TextStyle(color: DashboardColors.error, fontSize: 12),
          ),
          data: (subtasks) {
            final allDone = subtasks.isNotEmpty && subtasks.every((s) => s.isDone);
            final anyDone = subtasks.any((s) => s.isDone);
            final isIndeterminate = anyDone && !allDone;

            Widget selectAllBox;
            if (allDone) {
              selectAllBox = Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xff6366F1).withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xff6366F1),
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xff6366F1),
                  size: 14,
                ),
              );
            } else if (isIndeterminate) {
              selectAllBox = Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xff6366F1).withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xff6366F1).withValues(alpha: .6),
                  ),
                ),
                child: const Icon(
                  Icons.remove_rounded,
                  color: Color(0xff6366F1),
                  size: 14,
                ),
              );
            } else {
              selectAllBox = Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: DashboardColors.outline,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (subtasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No subtasks',
                      style: TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleAll(subtasks, !allDone),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: selectAllBox,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _toggleAll(subtasks, !allDone),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Text(
                                allDone ? 'Deselect All' : 'Select All',
                                style: const TextStyle(
                                  color: DashboardColors.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${subtasks.where((s) => s.isDone).length}/${subtasks.length}',
                          style: const TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    color: Colors.white10,
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  ...subtasks.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleSubtask(item, !item.isDone),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: item.isDone
                                      ? const Color(0xff6366F1)
                                          .withValues(alpha: .14)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: item.isDone
                                        ? const Color(0xff6366F1)
                                        : DashboardColors.outline,
                                  ),
                                ),
                                child: item.isDone
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Color(0xff6366F1),
                                        size: 14,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: item.isDone
                                    ? DashboardColors.onSurfaceVariant
                                    : DashboardColors.onSurface,
                                decoration: item.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            color:
                                DashboardColors.outline.withValues(alpha: .5),
                            onPressed: () => _deleteSubtask(item.id),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 4),
                if (_isAdding)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          autofocus: true,
                          style: const TextStyle(
                              fontSize: 14, color: DashboardColors.onSurface),
                          decoration: const InputDecoration(
                            hintText: 'Enter subtask...',
                            border: InputBorder.none,
                            hintStyle:
                                TextStyle(color: DashboardColors.outline),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                          onSubmitted: _addSubtask,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_rounded,
                            color: DashboardColors.primary, size: 18),
                        onPressed: () => _addSubtask(_textController.text),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: DashboardColors.error, size: 18),
                        onPressed: () {
                          setState(() {
                            _isAdding = false;
                            _textController.clear();
                          });
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAdding = true;
                      });
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        children: const [
                          Icon(Icons.add_rounded,
                              color: DashboardColors.outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add another subtask...',
                            style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Attachment extends StatelessWidget {
  const _Attachment({
    required this.icon,
    required this.title,
    required this.size,
    required this.color,
    this.imageUrl,
  });

  final IconData icon;
  final String title;
  final String size;
  final Color color;
  final String? imageUrl;

  Widget _buildDocumentThumbnail(String ext, Color color, IconData icon) {
    final isPdf = ext == 'pdf';
    final isWord = ['doc', 'docx'].contains(ext);
    final isExcel = ['xls', 'xlsx'].contains(ext);
    final isPpt = ['ppt', 'pptx'].contains(ext);
    final isZip = ['zip', 'rar', '7z'].contains(ext);

    final docColor = isPdf
        ? const Color(0xffEF4444)
        : isWord
            ? const Color(0xff3B82F6)
            : isExcel
                ? const Color(0xff10B981)
                : isPpt
                    ? const Color(0xffF59E0B)
                    : isZip
                        ? const Color(0xff8B5CF6)
                        : color;

    final badgeText = ext.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background subtle paper texture / lines
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 4,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 4,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 4,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          // Gradient overlay for depth
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          // Top accent strip
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: docColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          // Document Badge / Type label
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: docColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: docColor.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: docColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          // Large floating central icon representing the file type
          Center(
            child: Icon(
              icon,
              color: docColor.withValues(alpha: 0.75),
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      color: Colors.black87,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => Container(
                          padding: const EdgeInsets.all(24),
                          color: DashboardColors.surfaceLow,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: color, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: DashboardColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .08),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(icon, color: color, size: 28),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.black.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  size,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildDocumentThumbnail(
            title.split('.').last.toLowerCase(),
            color,
            icon,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          size,
          style: const TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
