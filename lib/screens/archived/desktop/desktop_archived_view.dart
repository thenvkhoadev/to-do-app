import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart'
    hide GlassCard, GlowOrb, GradientButton, SectionTitle;
import 'package:to_do_app/widgets/dashboard/dashboard_enhancement_widgets.dart'
    show XPLevelCard;
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/presentation/providers/task_timeline_provider.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/screens/archived/providers/restore_activity_provider.dart';
import 'package:to_do_app/screens/archived/widgets/restore_success_dialog.dart';
import 'package:to_do_app/screens/archived/models/archived_task_model.dart';
import 'package:to_do_app/screens/archived/providers/archived_tasks_provider.dart';
import 'package:to_do_app/screens/archived/widgets/archive_shared_widgets.dart';
import 'package:to_do_app/screens/archived/widgets/archive_detail_drawer.dart';
import 'package:to_do_app/screens/archived/widgets/modern_filter_dropdown.dart';
import 'package:to_do_app/screens/archived/widgets/archive_export_service.dart';
import 'package:to_do_app/screens/archived/widgets/assignee_avatar_group.dart';
import 'package:to_do_app/screens/archived/widgets/archive_command_center.dart';
import 'package:to_do_app/features/streak/presentation/providers/streak_providers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DesktopArchivedView extends ConsumerStatefulWidget {
  const DesktopArchivedView({super.key});

  @override
  ConsumerState<DesktopArchivedView> createState() =>
      _DesktopArchivedViewState();
}

class _DesktopArchivedViewState extends ConsumerState<DesktopArchivedView> {
  String _search = '';
  String _filterStatus = 'all';
  String _filterPriority = 'all';
  String _filterCategory = 'all';
  String _filterArchivedDate = 'all';
  ArchivedTask? _selected;
  final Set<String> _checkedIds = {};
  // Optimistic UI: tasks being restored are immediately hidden from UI
  // even before the database stream catches up.
  final Set<String> _pendingRestoreIds = {};

  List<ArchivedTask> _filtered(List<ArchivedTask> tasks) {
    return tasks.where((t) {
      // Optimistic UI: hide tasks that have been restored locally
      // even if the stream hasn't caught up yet.
      if (_pendingRestoreIds.contains(t.id)) return false;
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          (t.description ?? '').toLowerCase().contains(q) ||
          t.tagIds.any((tag) => tag.toLowerCase().contains(q));
      final matchStatus =
          _filterStatus == 'all' || t.status == _filterStatus;
      final matchPriority =
          _filterPriority == 'all' || t.priority == _filterPriority;
      final matchCategory =
          _filterCategory == 'all' || t.categoryId == _filterCategory;

      bool matchArchivedDate = true;
      if (_filterArchivedDate != 'all' && t.archivedAt != null) {
        final now = DateTime.now();
        final archived = t.archivedAt!;
        final diff = now.difference(archived).inDays;

        switch (_filterArchivedDate) {
          case 'today':
            matchArchivedDate = diff == 0 && now.day == archived.day;
            break;
          case 'yesterday':
            matchArchivedDate = diff == 1 || (diff == 0 && now.day != archived.day);
            break;
          case '7d':
            matchArchivedDate = diff <= 7;
            break;
          case '30d':
            matchArchivedDate = diff <= 30;
            break;
          case 'this_month':
            matchArchivedDate = now.month == archived.month && now.year == archived.year;
            break;
          case 'last_month':
            final lastMonth = now.month == 1 ? 12 : now.month - 1;
            final lastYear = now.month == 1 ? now.year - 1 : now.year;
            matchArchivedDate = archived.month == lastMonth && archived.year == lastYear;
            break;
          case 'this_year':
            matchArchivedDate = now.year == archived.year;
            break;
        }
      } else if (_filterArchivedDate != 'all') {
        matchArchivedDate = false;
      }

      return matchSearch && matchStatus && matchPriority && matchCategory && matchArchivedDate;
    }).toList();
  }

  Future<void> _restore(ArchivedTask task) async {
    final messenger = ScaffoldMessenger.of(context);
    // Step 1: Close the detail panel immediately
    setState(() {
      _selected = null;
      _checkedIds.remove(task.id);
    });
    try {
      await ref.read(archivedTasksRepositoryProvider).restore(task);
      await ref.read(streakRemoteDataSourceProvider).updateUserStreak('Task Restored');

      // Step 2: Show success dialog BEFORE hiding task from list
      if (!mounted) return;
      RestoreSuccessDialog.show(context);

      // Step 3: Hide task from list AFTER dialog appears (short delay for visual effect)
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() => _pendingRestoreIds.add(task.id));
      }

      // Step 4: Log timeline activity
      final user = ref.read(authControllerProvider).valueOrNull;
      final userName = user?.fullName ??
          user?.username ??
          user?.email ?? 'Unknown User';

      await ref.read(taskTimelineProvider(task.id).notifier).addActivity(
        actorName: userName,
        action: 'resume',
        detail: 'restored this task from archive',
      );

      // Step 5: Log to restore activity feed
      await ref.read(restoreActivityProvider.notifier).log(
        taskId: task.id,
        taskTitle: task.title,
        userName: userName,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _pendingRestoreIds.remove(task.id));
        messenger.showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: DashboardColors.error,
        ));
      }
    }
  }

  Future<void> _delete(ArchivedTask task) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardColors.surfaceLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text('Delete Permanently',
            style: TextStyle(color: DashboardColors.onSurface, fontWeight: FontWeight.bold)),
        content: Text('Delete "${task.title}"? This cannot be undone.',
            style: const TextStyle(color: DashboardColors.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: DashboardColors.onSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await ref.read(archivedTasksRepositoryProvider).deletePermanently(task.id);
        if (!mounted) return;
        setState(() { _selected = null; _checkedIds.remove(task.id); });
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: DashboardColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(archivedTasksProvider);
    final tasks = async.valueOrNull ?? [];
    // Exclude optimistically restored tasks from all stats/KPIs
    final visibleTasks = tasks.where((t) => !_pendingRestoreIds.contains(t.id)).toList();
    final filtered = _filtered(tasks);
    final categories = ref.watch(userCategoriesProvider).valueOrNull ?? [];
    final users = ref.watch(allUsersProvider).valueOrNull ?? [];
    final tags = ref.watch(userTagsProvider).valueOrNull ?? [];

    const double panelWidth = 460;
    final isPanelOpen = _selected != null;

    return Stack(
      children: [
        Container(
          color: DashboardColors.background,
          child: Column(
            children: [
              _Topbar(
                search: _search,
                onSearch: (v) => setState(() => _search = v),
                checkedCount: _checkedIds.length,
                onRestoreSelected: () async {
                  for (final id in _checkedIds.toList()) {
                    final t = tasks.firstWhere((t) => t.id == id,
                        orElse: () => tasks.first);
                    await _restore(t);
                  }
                },
                onDeleteSelected: () async {
                  for (final id in _checkedIds.toList()) {
                    final t = tasks.firstWhere((t) => t.id == id,
                        orElse: () => tasks.first);
                    await _delete(t);
                  }
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 32, 40, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageHeader(total: visibleTasks.length),
                      const SizedBox(height: 24),
                      _KpiRow(tasks: visibleTasks),
                      const SizedBox(height: 24),
                      _MainGrid(
                        tasks: filtered,
                        allTasks: visibleTasks,
                        categories: categories,
                        users: users,
                        filterStatus: _filterStatus,
                        filterPriority: _filterPriority,
                        filterCategory: _filterCategory,
                        filterArchivedDate: _filterArchivedDate,
                        checkedIds: _checkedIds,
                        onFilterStatus: (v) => setState(() => _filterStatus = v),
                        onFilterPriority: (v) => setState(() => _filterPriority = v),
                        onFilterCategory: (v) => setState(() => _filterCategory = v),
                        onFilterArchivedDate: (v) => setState(() => _filterArchivedDate = v),
                        onCheck: (id, v) => setState(() {
                          if (v) { _checkedIds.add(id); } else { _checkedIds.remove(id); }
                        }),
                        onCheckAll: (v) => setState(() {
                          if (v) { _checkedIds.addAll(filtered.map((t) => t.id)); } else { _checkedIds.clear(); }
                        }),
                        onRowTap: (t) => setState(() => _selected = t),
                        onRestore: _restore,
                        onDelete: _delete,
                        isLoading: async.isLoading,
                      ),
                      const SizedBox(height: 40),
                      ArchiveCommandCenter(
                        tasks: visibleTasks,
                        categories: categories,
                        users: users,
                        tags: tags,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Scrim
        if (isPanelOpen)
          GestureDetector(
            onTap: () => setState(() => _selected = null),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isPanelOpen ? 1.0 : 0.0,
              child: Container(color: Colors.black.withValues(alpha: .35)),
            ),
          ),
        // Slide-in panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          top: 0,
          bottom: 0,
          right: isPanelOpen ? 0 : -panelWidth,
          width: panelWidth,
          child: _selected != null
              ? ArchiveDetailDrawer(
                  task: _selected!,
                  onClose: () => setState(() => _selected = null),
                  onRestore: () => _restore(_selected!),
                  onDelete: () => _delete(_selected!),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Topbar ────────────────────────────────────────────────────────────────────

class _Topbar extends StatelessWidget {
  const _Topbar({
    required this.search,
    required this.onSearch,
    required this.checkedCount,
    required this.onRestoreSelected,
    required this.onDeleteSelected,
  });
  final String search;
  final ValueChanged<String> onSearch;
  final int checkedCount;
  final VoidCallback onRestoreSelected;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: DashboardColors.surface.withValues(alpha: .50),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .16), blurRadius: 18),
            ],
          ),
          child: Row(
            children: [
              // Search field
              Container(
                width: 320, height: 38,
                decoration: BoxDecoration(
                  color: DashboardColors.surfaceLow.withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: .12)),
                ),
                child: TextField(
                  onChanged: onSearch,
                  style: const TextStyle(color: DashboardColors.onSurface, fontSize: 14),
                  cursorColor: DashboardColors.primary,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, color: DashboardColors.onSurfaceVariant, size: 18),
                    hintText: 'Search archived tasks...',
                    hintStyle: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Archive chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: DashboardColors.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DashboardColors.primary.withValues(alpha: .2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.archive_rounded, size: 13, color: DashboardColors.primary),
                    SizedBox(width: 6),
                    Text('Archive', style: TextStyle(color: DashboardColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Spacer(),
              // Notification icon — matches TasksTopbar
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {},
                  child: const SizedBox(
                    width: 42, height: 42,
                    child: Icon(Icons.notifications_none_rounded, color: DashboardColors.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Bolt icon — matches TasksTopbar
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {},
                  child: const SizedBox(
                    width: 42, height: 42,
                    child: Icon(Icons.bolt_rounded, color: DashboardColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Profile avatar — exactly as TasksTopbar
              const XPLevelCard(),
              const SizedBox(width: 14),
              const ProfileAvatar(radius: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page header ───────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Archived Tasks',
          style: TextStyle(
            color: DashboardColors.primary,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage completed and archived work history.',
          style: TextStyle(
            color: DashboardColors.onSurfaceVariant.withValues(alpha: .9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ── KPI row (4 cards) ─────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.tasks});
  final List<ArchivedTask> tasks;

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.status == 'done').length;
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    final completedMonth = tasks
        .where((t) =>
            t.completedAt != null && t.completedAt!.isAfter(monthAgo))
        .length;
    final rate = tasks.isEmpty ? 0 : (done / tasks.length * 100).round();

    return Row(
      children: [
        Expanded(
          child: ArchiveKpiCard(
            label: 'Total Archived',
            value: '${tasks.length}',
            trend: '+12%',
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: ArchiveKpiCard(
            label: 'Completed Month',
            value: '$completedMonth',
            suffix: 'tasks',
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: ArchiveKpiCard(
            label: 'Completion Rate',
            value: '$rate%',
            progress: rate / 100,
          ),
        ),
        const SizedBox(width: 24),
        const Expanded(
          child: ArchiveKpiCard(
            label: 'Archive Storage',
            value: '12',
            suffix: 'MB used',
          ),
        ),
      ],
    );
  }
}

// ── Main 9/3 grid ─────────────────────────────────────────────────────────────

class _MainGrid extends StatelessWidget {
  const _MainGrid({
    required this.tasks,
    required this.allTasks,
    required this.categories,
    required this.users,
    required this.filterStatus,
    required this.filterPriority,
    required this.filterCategory,
    required this.filterArchivedDate,
    required this.checkedIds,
    required this.onFilterStatus,
    required this.onFilterPriority,
    required this.onFilterCategory,
    required this.onFilterArchivedDate,
    required this.onCheck,
    required this.onCheckAll,
    required this.onRowTap,
    required this.onRestore,
    required this.onDelete,
    required this.isLoading,
  });
  final List<ArchivedTask> tasks;
  final List<ArchivedTask> allTasks;
  final List<CategoryModel> categories;
  final List<UserProfileModel> users;
  final String filterStatus;
  final String filterPriority;
  final String filterCategory;
  final String filterArchivedDate;
  final Set<String> checkedIds;
  final ValueChanged<String> onFilterStatus;
  final ValueChanged<String> onFilterPriority;
  final ValueChanged<String> onFilterCategory;
  final ValueChanged<String> onFilterArchivedDate;
  final void Function(String id, bool checked) onCheck;
  final ValueChanged<bool> onCheckAll;
  final ValueChanged<ArchivedTask> onRowTap;
  final Future<void> Function(ArchivedTask) onRestore;
  final Future<void> Function(ArchivedTask) onDelete;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FiltersBar(
          filterStatus: filterStatus,
          filterPriority: filterPriority,
          filterCategory: filterCategory,
          filterArchivedDate: filterArchivedDate,
          allTasks: allTasks,
          categories: categories,
          users: users,
          checkedCount: checkedIds.length,
          onFilterStatus: onFilterStatus,
          onFilterPriority: onFilterPriority,
          onFilterCategory: onFilterCategory,
          onFilterArchivedDate: onFilterArchivedDate,
          onRestoreSelected: () async {
            for (final id in checkedIds.toList()) {
              final t = allTasks.firstWhere((t) => t.id == id,
                  orElse: () => allTasks.first);
              await onRestore(t);
            }
          },
          onDeleteSelected: () async {
            for (final id in checkedIds.toList()) {
              final t = allTasks.firstWhere((t) => t.id == id,
                  orElse: () => allTasks.first);
              await onDelete(t);
            }
          },
        ),
        const SizedBox(height: 16),
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : tasks.isEmpty
                ? _EmptyState()
                : _DataTable(
                    tasks: tasks,
                    checkedIds: checkedIds,
                    categories: categories,
                    users: users,
                    onCheck: onCheck,
                    onCheckAll: (v) {
                      for (final t in tasks) {
                        onCheck(t.id, v);
                      }
                    },
                    onRowTap: onRowTap,
                    onRestore: onRestore,
                    onDelete: onDelete,
                    total: allTasks.length,
                  ),
        const SizedBox(height: 24),
        _RightPanel(tasks: allTasks, categories: categories),
      ],
    );
  }
}

// ── Filters bar ───────────────────────────────────────────────────────────────

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.filterStatus,
    required this.filterPriority,
    required this.filterCategory,
    required this.filterArchivedDate,
    required this.allTasks,
    required this.categories,
    required this.users,
    required this.checkedCount,
    required this.onFilterStatus,
    required this.onFilterPriority,
    required this.onFilterCategory,
    required this.onFilterArchivedDate,
    required this.onRestoreSelected,
    required this.onDeleteSelected,
  });
  final String filterStatus;
  final String filterPriority;
  final String filterCategory;
  final String filterArchivedDate;
  final List<ArchivedTask> allTasks;
  final List<CategoryModel> categories;
  final List<UserProfileModel> users;
  final int checkedCount;
  final ValueChanged<String> onFilterStatus;
  final ValueChanged<String> onFilterPriority;
  final ValueChanged<String> onFilterCategory;
  final ValueChanged<String> onFilterArchivedDate;
  final VoidCallback onRestoreSelected;
  final VoidCallback onDeleteSelected;

  int _countStatus(String val) => val == 'all'
      ? allTasks.length
      : allTasks.where((t) => t.status == val).length;

  int _countPriority(String val) => val == 'all'
      ? allTasks.length
      : allTasks.where((t) => t.priority == val).length;

  int _countArchivedDate(String val) {
    if (val == 'all') return allTasks.length;
    final now = DateTime.now();
    return allTasks.where((t) {
      if (t.archivedAt == null) return false;
      final d = t.archivedAt!;
      final diff = now.difference(d).inDays;
      switch (val) {
        case 'today': return diff == 0 && now.day == d.day;
        case 'yesterday': return diff == 1 || (diff == 0 && now.day != d.day);
        case '7d': return diff <= 7;
        case '30d': return diff <= 30;
        case 'this_month': return now.month == d.month && now.year == d.year;
        case 'last_month':
          final lm = now.month == 1 ? 12 : now.month - 1;
          final ly = now.month == 1 ? now.year - 1 : now.year;
          return d.month == lm && d.year == ly;
        case 'this_year': return now.year == d.year;
        default: return false;
      }
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = [
      FilterOption(value: 'all', label: 'All Tasks', icon: Icons.select_all_rounded, color: Colors.white70, count: _countStatus('all')),
      FilterOption(value: 'todo', label: 'Todo', icon: Icons.radio_button_unchecked_rounded, color: DashboardColors.onSurfaceVariant, count: _countStatus('todo')),
      FilterOption(value: 'in_progress', label: 'Active', icon: Icons.play_circle_outline_rounded, color: DashboardColors.primary, count: _countStatus('in_progress')),
      FilterOption(value: 'done', label: 'Done', icon: Icons.check_circle_outline_rounded, color: DashboardColors.success, count: _countStatus('done')),
    ];

    final priorityOptions = [
      FilterOption(value: 'all', label: 'All', icon: Icons.filter_list_rounded, color: Colors.white70, count: _countPriority('all')),
      FilterOption(value: 'urgent', label: 'Urgent', icon: Icons.bolt_rounded, color: const Color(0xFFFF6B6B), count: _countPriority('urgent')),
      FilterOption(value: 'high', label: 'High', icon: Icons.keyboard_double_arrow_up_rounded, color: const Color(0xFFFFB020), count: _countPriority('high')),
      FilterOption(value: 'medium', label: 'Medium', icon: Icons.remove_rounded, color: const Color(0xFF5B8CFF), count: _countPriority('medium')),
      FilterOption(value: 'low', label: 'Low', icon: Icons.keyboard_double_arrow_down_rounded, color: const Color(0xFF34C759), count: _countPriority('low')),
    ];

    final catOptions = [
      FilterOption(value: 'all', label: 'All Categories', icon: Icons.folder_open_rounded, color: Colors.white70, count: allTasks.length),
      ...categories.map((c) => FilterOption(
        value: c.id,
        label: c.name,
        icon: Icons.folder_rounded,
        color: DashboardColors.primary,
        count: allTasks.where((t) => t.categoryId == c.id).length,
      )),
    ];

    final archivedDateOptions = [
      FilterOption(value: 'all', label: 'All Time', icon: Icons.all_inbox_rounded, color: Colors.white70, count: _countArchivedDate('all')),
      FilterOption(value: 'today', label: 'Today', icon: Icons.today_rounded, color: DashboardColors.primary, count: _countArchivedDate('today')),
      FilterOption(value: 'yesterday', label: 'Yesterday', icon: Icons.calendar_today_rounded, color: DashboardColors.primary, count: _countArchivedDate('yesterday')),
      FilterOption(value: '7d', label: 'Last 7 Days', icon: Icons.date_range_rounded, color: DashboardColors.secondary, count: _countArchivedDate('7d')),
      FilterOption(value: '30d', label: 'Last 30 Days', icon: Icons.calendar_month_rounded, color: DashboardColors.secondary, count: _countArchivedDate('30d')),
      FilterOption(value: 'this_month', label: 'This Month', icon: Icons.folder_special_rounded, color: DashboardColors.success, count: _countArchivedDate('this_month')),
      FilterOption(value: 'last_month', label: 'Last Month', icon: Icons.folder_rounded, color: DashboardColors.success, count: _countArchivedDate('last_month')),
      FilterOption(value: 'this_year', label: 'This Year', icon: Icons.bar_chart_rounded, color: DashboardColors.onSurfaceVariant, count: _countArchivedDate('this_year')),
    ];

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ModernFilterDropdown(
                title: 'Status',
                subtitle: 'Filter by task status',
                options: statusOptions,
                selected: filterStatus,
                onSelected: onFilterStatus,
                footer: '${statusOptions.length - 1} statuses available',
              ),
              ModernFilterDropdown(
                title: 'Priority',
                subtitle: 'Filter by priority level',
                options: priorityOptions,
                selected: filterPriority,
                onSelected: onFilterPriority,
                footer: '${priorityOptions.length - 1} priority levels',
              ),
              ModernFilterDropdown(
                title: 'Category',
                subtitle: 'Filter by category',
                options: catOptions,
                selected: filterCategory,
                onSelected: onFilterCategory,
                footer: '${catOptions.length - 1} categories',
              ),
              ModernFilterDropdown(
                title: 'Archived',
                subtitle: 'Filter by archive date',
                options: archivedDateOptions,
                selected: filterArchivedDate,
                onSelected: onFilterArchivedDate,
                footer: 'Sorted by newest archived first',
              ),
            ],
          ),
        ),
        if (checkedCount > 0) ...[
          const SizedBox(width: 16),
          Text(
            '$checkedCount selected',
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          _BulkBtn(label: 'Restore Selected', color: DashboardColors.primary, onTap: onRestoreSelected),
          const SizedBox(width: 8),
          _BulkBtn(label: 'Delete', color: DashboardColors.error, onTap: onDeleteSelected),
          const SizedBox(width: 8),
        ],
        const SizedBox(width: 8),
        ArchiveExportButton(
          tasks: allTasks,
          categories: categories,
          users: users,
        ),
      ],
    );
  }
}

class _BulkBtn extends StatelessWidget {
  const _BulkBtn({
    required this.label,
    required this.onTap,
    this.color,
  });
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DashboardColors.onSurface;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: c.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      color: c,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data table ────────────────────────────────────────────────────────────────

class _DataTable extends StatelessWidget {
  const _DataTable({
    required this.tasks,
    required this.checkedIds,
    required this.categories,
    required this.users,
    required this.onCheck,
    required this.onCheckAll,
    required this.onRowTap,
    required this.onRestore,
    required this.onDelete,
    required this.total,
  });
  final List<ArchivedTask> tasks;
  final Set<String> checkedIds;
  final List<CategoryModel> categories;
  final List<UserProfileModel> users;
  final void Function(String, bool) onCheck;
  final ValueChanged<bool> onCheckAll;
  final ValueChanged<ArchivedTask> onRowTap;
  final Future<void> Function(ArchivedTask) onRestore;
  final Future<void> Function(ArchivedTask) onDelete;
  final int total;

  bool get _allChecked =>
      tasks.isNotEmpty && tasks.every((t) => checkedIds.contains(t.id));
  bool get _someChecked =>
      tasks.any((t) => checkedIds.contains(t.id)) && !_allChecked;

  @override
  Widget build(BuildContext context) {
    return ArchiveGlassCard(
      padding: EdgeInsets.zero,
      radius: 20,
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: DashboardColors.surfaceLow.withValues(alpha: .3),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Checkbox(
                    value: _someChecked ? null : _allChecked,
                    tristate: true,
                    onChanged: (v) => onCheckAll(v ?? false),
                    side: BorderSide(color: Colors.white.withValues(alpha: .3)),
                    fillColor: WidgetStateProperty.resolveWith((s) =>
                        s.contains(WidgetState.selected)
                            ? DashboardColors.primary
                            : Colors.transparent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: _ThCell('TASK NAME')),
                const SizedBox(width: 90, child: _ThCell('PRIORITY')),
                const SizedBox(width: 120, child: _ThCell('CATEGORY')),
                const SizedBox(width: 120, child: _ThCell('COMPLETED')),
                const SizedBox(width: 120, child: _ThCell('ARCHIVED')),
                const SizedBox(width: 90, child: _ThCell('ASSIGNEES', right: true)),
                const SizedBox(width: 80),
              ],
            ),
          ),
          // Rows
          ...tasks.map((t) => _TableRow(
                task: t,
                checked: checkedIds.contains(t.id),
                categoryName: categories
                    .firstWhere((c) => c.id == t.categoryId,
                        orElse: () => CategoryModel(
                            id: '', userId: '', name: t.categoryId ?? '—'))
                    .name,
                assignees: t.assigneeIds.map((id) {
                  return users.firstWhere((u) => u.id == id,
                      orElse: () => UserProfileModel(id: id, email: ''));
                }).toList(),
                onCheck: (v) => onCheck(t.id, v),
                onTap: () => onRowTap(t),
                onRestore: () => onRestore(t),
                onDelete: () => onDelete(t),
              )),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: .08)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Showing $total archived tasks',
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                _PageBtn(icon: Icons.chevron_left_rounded),
                const SizedBox(width: 4),
                _PageBtn(icon: Icons.chevron_right_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThCell extends StatelessWidget {
  const _ThCell(this.label, {this.right = false});
  final String label;
  final bool right;

  @override
  Widget build(BuildContext context) => Text(
        label,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: DashboardColors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      );
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, color: DashboardColors.onSurfaceVariant, size: 20),
          ),
        ),
      );
}

// ── Table row ─────────────────────────────────────────────────────────────────

class _TableRow extends StatefulWidget {
  const _TableRow({
    required this.task,
    required this.checked,
    required this.categoryName,
    required this.assignees,
    required this.onCheck,
    required this.onTap,
    required this.onRestore,
    required this.onDelete,
  });
  final ArchivedTask task;
  final bool checked;
  final String categoryName;
  final List<UserProfileModel> assignees;
  final ValueChanged<bool> onCheck;
  final VoidCallback onTap;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hover = false;

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month-1]} ${d.day}, ${d.year}';
  }

  String _fmtTime(DateTime? d) {
    if (d == null) return '';
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hover
              ? Colors.white.withValues(alpha: .04)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Checkbox(
                  value: widget.checked,
                  onChanged: (v) => widget.onCheck(v ?? false),
                  side: BorderSide(color: Colors.white.withValues(alpha: .3)),
                  fillColor: WidgetStateProperty.resolveWith((s) =>
                      s.contains(WidgetState.selected)
                          ? DashboardColors.primary
                          : Colors.transparent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 16),
              // Task name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: DashboardColors.surfaceHigh.withValues(alpha: .6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white.withValues(alpha: .12)),
                          ),
                          child: const Text(
                            'ARCHIVED',
                            style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                        if (t.tagIds.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              t.tagIds.take(2).map((tag) => '#$tag').join(' '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: DashboardColors.primary.withValues(alpha: .7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Priority
              SizedBox(
                width: 90,
                child: Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: t.priorityColor),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        t.priorityLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.priorityColor, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              // Category
              SizedBox(
                width: 120,
                child: Text(
                  widget.categoryName.isEmpty ? '—' : widget.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12),
                ),
              ),
              // Completed date
              SizedBox(
                width: 120,
                child: t.completedAt != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_fmtDate(t.completedAt),
                              style: const TextStyle(
                                  color: DashboardColors.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const Text('COMPLETED',
                              style: TextStyle(
                                  color: DashboardColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .5)),
                        ],
                      )
                    : const Text('—',
                        style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13)),
              ),
              // Archived date
              SizedBox(
                width: 120,
                child: t.archivedAt != null
                    ? Row(
                        children: [
                          Icon(Icons.archive_rounded, size: 12,
                              color: DashboardColors.primary.withValues(alpha: .7)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_fmtDate(t.archivedAt),
                                    style: const TextStyle(
                                        color: DashboardColors.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Text(_fmtTime(t.archivedAt),
                                    style: TextStyle(
                                        color: DashboardColors.onSurfaceVariant.withValues(alpha: .7),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const Text('—', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13)),
              ),
              // Assignees
              SizedBox(
                width: 90,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AssigneeAvatarGroup(
                    assignees: widget.assignees,
                    avatarSize: 26,
                    maxVisible: 3,
                  ),
                ),
              ),
              // Actions
              SizedBox(
                width: 80,
                child: _hover
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _RowIconBtn(
                            icon: Icons.restore_rounded,
                            color: DashboardColors.primary,
                            onTap: widget.onRestore,
                          ),
                          const SizedBox(width: 4),
                          _RowIconBtn(
                            icon: Icons.delete_outline_rounded,
                            color: DashboardColors.error,
                            onTap: widget.onDelete,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowIconBtn extends StatelessWidget {
  const _RowIconBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: color, size: 16),
          ),
        ),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatefulWidget {
  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _floatAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - _fadeAnim.value)),
          child: child,
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ArchiveGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
          radius: 20,
          glowColor: DashboardColors.primary,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Floating archive illustration
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: child,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        DashboardColors.primary.withValues(alpha: .25),
                        DashboardColors.primary.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                  Container(
                    width: 88, height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DashboardColors.primary,
                          Color(0xFF6366F1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DashboardColors.primary.withValues(alpha: .4),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 38),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Archive is Empty',
              style: TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Nothing Archived Yet',
              style: TextStyle(
                color: DashboardColors.primary.withValues(alpha: .9),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Your archive is currently empty. Archived tasks and projects\nwill appear here when archived for future recovery.\nAll your current items are active in their workspaces.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DashboardColors.onSurfaceVariant.withValues(alpha: .85),
                fontSize: 13,
                height: 1.65,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            // Feature list
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: const [
                _EmptyChip(icon: Icons.task_alt_rounded, label: 'Archived Tasks'),
                _EmptyChip(icon: Icons.folder_special_rounded, label: 'Archived Projects'),
                _EmptyChip(icon: Icons.history_rounded, label: 'Restore History'),
                _EmptyChip(icon: Icons.timeline_rounded, label: 'Archive Activities'),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _EmptyActionBtn(
                  label: 'Browse Tasks',
                  icon: Icons.view_kanban_rounded,
                  filled: true,
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _EmptyActionBtn(
                  label: 'View Projects',
                  icon: Icons.folder_open_rounded,
                  filled: false,
                  onTap: () {},
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

// ── Right panel ───────────────────────────────────────────────────────────────

class _RightPanel extends StatelessWidget {
  const _RightPanel({required this.tasks, required this.categories});
  final List<ArchivedTask> tasks;
  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeatmapCard(),
        const SizedBox(height: 16),
        _DonutCard(tasks: tasks, categories: categories),
        const SizedBox(height: 16),
        _AiInsightCard(),
        const SizedBox(height: 16),
        _StorageCard(),
      ],
    );
  }
}

// ── Heatmap card ──────────────────────────────────────────────────────────────

class _HeatmapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final levels = [0.0, 0.2, 0.4, 0.6, 1.0];
    final cells = List.generate(35, (i) => levels[i % levels.length]);

    return ArchiveGlassCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Archive Activity',
                    style: TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
              const Icon(Icons.info_outline_rounded,
                  color: DashboardColors.onSurfaceVariant, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              mainAxisExtent: 10,
            ),
            itemCount: cells.length,
            itemBuilder: (_, i) => Container(
              decoration: BoxDecoration(
                color: cells[i] == 0
                    ? Colors.white.withValues(alpha: .05)
                    : DashboardColors.primary.withValues(alpha: cells[i]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Less',
                  style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
              const Spacer(),
              ...levels.map((l) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: l == 0
                            ? Colors.white.withValues(alpha: .05)
                            : DashboardColors.primary.withValues(alpha: l),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
              const Spacer(),
              const Text('More',
                  style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Donut card ────────────────────────────────────────────────────────────────

class _DonutCard extends StatelessWidget {
  const _DonutCard({required this.tasks, required this.categories});
  final List<ArchivedTask> tasks;
  final List<CategoryModel> categories;

  static const _colors = [
    DashboardColors.primary,
    DashboardColors.secondary,
    DashboardColors.success,
    Color(0xFFFFB020),
    Color(0xFFFF6B6B),
  ];

  String _catName(String? id) {
    if (id == null) return 'General';
    final match = categories.where((c) => c.id == id);
    return match.isNotEmpty ? match.first.name : 'General';
  }

  @override
  Widget build(BuildContext context) {
    final cats = <String, int>{};
    for (final t in tasks) {
      final key = t.categoryId ?? '';
      cats[key] = (cats[key] ?? 0) + 1;
    }
    final sorted = cats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final total = tasks.length;

    return ArchiveGlassCard(
      padding: const EdgeInsets.all(20),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Distribution',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(110, 110),
                    painter: _DonutPainter(
                      slices: top.map((e) => e.value).toList(),
                      colors: List.generate(
                          top.length, (i) => _colors[i % _colors.length]),
                      total: total,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          color: DashboardColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (top.isEmpty)
            const Text(
              'No data',
              style: TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 12,
              ),
            )
          else
            ...List.generate(top.length, (i) {
              final e = top[i];
              final pct = total == 0 ? 0 : (e.value / total * 100).round();
              final color = _colors[i % _colors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _catName(e.key.isEmpty ? null : e.key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.slices,
    required this.colors,
    required this.total,
  });

  final List<int> slices;
  final List<Color> colors;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    const strokeWidth = 12.0;
    const gapAngle = 0.04;
    double startAngle = -1.5707963;

    if (total == 0) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: .05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, 0, 6.2831853, false, paint);
      return;
    }

    for (int i = 0; i < slices.length; i++) {
      final sweep =
          (slices[i] / total) * 6.2831853 - gapAngle;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep + gapAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.slices != slices || old.total != total;
}

// ── AI insight card ───────────────────────────────────────────────────────────

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard();

  @override
  Widget build(BuildContext context) {
    return ArchiveGlassCard(
      padding: const EdgeInsets.all(20),
      radius: 16,
      glowColor: DashboardColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.psychology_rounded,
                  color: DashboardColors.primary, size: 18),
              SizedBox(width: 8),
              Text('AI Insights',
                  style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.6),
              children: [
                const TextSpan(text: 'You have '),
                TextSpan(
                  text: '42 tasks',
                  style: const TextStyle(
                      color: DashboardColors.primary,
                      fontWeight: FontWeight.w800),
                ),
                const TextSpan(
                    text:
                        ' archived over 6 months ago that haven\'t been accessed. Consider a permanent cleanup to optimize your workspace.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.white.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: .12)),
                ),
                child: const Center(
                  child: Text(
                    'Review Cleanup Recommendations',
                    style: TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Storage card ──────────────────────────────────────────────────────────────

class _StorageCard extends StatelessWidget {
  const _StorageCard();

  @override
  Widget build(BuildContext context) {
    return ArchiveGlassCard(
      padding: const EdgeInsets.all(20),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Text('Archive Storage',
                    style: TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
              Text('12 / 100 MB',
                  style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.12,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: .06),
              valueColor:
                  const AlwaysStoppedAnimation(DashboardColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          const Text('88 MB remaining',
              style: TextStyle(
                  color: DashboardColors.onSurfaceVariant, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyChip extends StatelessWidget {
  const _EmptyChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: DashboardColors.primary.withValues(alpha: .9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActionBtn extends StatefulWidget {
  const _EmptyActionBtn({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  State<_EmptyActionBtn> createState() => _EmptyActionBtnState();
}

class _EmptyActionBtnState extends State<_EmptyActionBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: widget.filled
                ? LinearGradient(colors: [
                    DashboardColors.primary.withValues(alpha: _hover ? 1 : .9),
                    const Color(0xFF6366F1).withValues(alpha: _hover ? 1 : .9),
                  ])
                : null,
            color: widget.filled
                ? null
                : Colors.white.withValues(alpha: _hover ? .08 : .04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.filled
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: .15),
            ),
            boxShadow: widget.filled
                ? [
                    BoxShadow(
                      color: DashboardColors.primary.withValues(alpha: _hover ? .35 : .2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.filled ? Colors.white : DashboardColors.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.filled ? Colors.white : DashboardColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
