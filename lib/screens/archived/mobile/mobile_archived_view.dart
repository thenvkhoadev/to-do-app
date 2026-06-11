import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/screens/archived/models/archived_task_model.dart';
import 'package:to_do_app/screens/archived/providers/archived_tasks_provider.dart';
import 'package:to_do_app/screens/archived/widgets/archive_shared_widgets.dart';
import 'package:to_do_app/screens/archived/widgets/archived_task_card.dart';
import 'package:to_do_app/screens/archived/widgets/archive_detail_drawer.dart';
import 'package:to_do_app/screens/archived/widgets/archive_export_service.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/features/streak/presentation/providers/streak_providers.dart';

class MobileArchivedView extends ConsumerStatefulWidget {
  const MobileArchivedView({super.key});

  @override
  ConsumerState<MobileArchivedView> createState() => _MobileArchivedViewState();
}

class _MobileArchivedViewState extends ConsumerState<MobileArchivedView> {
  String _search = '';
  String _filter = 'all';
  ArchivedTask? _selected;

  List<ArchivedTask> _filtered(List<ArchivedTask> tasks) {
    return tasks.where((t) {
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          (t.description ?? '').toLowerCase().contains(q);
      final matchFilter = _filter == 'all' ||
          (_filter == 'done' && t.status == 'done') ||
          (_filter == 'high' && t.priority == 'high') ||
          (_filter == 'ai' && t.aiGenerated) ||
          (_filter == 'month' &&
              t.archivedAt != null &&
              t.archivedAt!
                  .isAfter(DateTime.now().subtract(const Duration(days: 30))));
      return matchSearch && matchFilter;
    }).toList();
  }

  Future<void> _restore(ArchivedTask task) async {
    try {
      await ref.read(archivedTasksRepositoryProvider).restore(task);
      await ref.read(streakRemoteDataSourceProvider).updateUserStreak('Task Restored');
      if (mounted) {
        setState(() => _selected = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Task restored'),
              backgroundColor: DashboardColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: DashboardColors.error),
        );
      }
    }
  }

  Future<void> _delete(ArchivedTask task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardColors.surfaceLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text('Delete Permanently',
            style: TextStyle(
                color: DashboardColors.onSurface,
                fontWeight: FontWeight.bold)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: DashboardColors.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style:
                      TextStyle(color: DashboardColors.onSurfaceVariant))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref
          .read(archivedTasksRepositoryProvider)
          .deletePermanently(task.id);
      setState(() => _selected = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(archivedTasksProvider);
    final tasks = async.valueOrNull ?? [];
    final filtered = _filtered(tasks);
    final categories = ref.watch(userCategoriesProvider).valueOrNull ?? [];
    final users = ref.watch(allUsersProvider).valueOrNull ?? [];

    if (_selected != null) {
      return Scaffold(
        backgroundColor: DashboardColors.background,
        body: SafeArea(
          child: ArchiveDetailDrawer(
            task: _selected!,
            onClose: () => setState(() => _selected = null),
            onRestore: () => _restore(_selected!),
            onDelete: () => _delete(_selected!),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DashboardColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _MobileHeader(
              total: tasks.length,
              tasks: tasks,
              categories: categories,
              users: users,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _MobileKpiCarousel(tasks: tasks),
                    const SizedBox(height: 16),
                    _MobileSearchBar(
                      value: _search,
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    const SizedBox(height: 12),
                    _MobileFilterChips(
                      selected: _filter,
                      onSelected: (v) => setState(() => _filter = v),
                    ),
                    const SizedBox(height: 20),
                    async.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                          child: Text('Error: $e',
                              style: const TextStyle(
                                  color: DashboardColors.error))),
                      data: (_) => filtered.isEmpty
                          ? _MobileEmptyState(
                              hasFilter: _search.isNotEmpty ||
                                  _filter != 'all')
                          : Column(
                              children: filtered
                                  .map((t) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: ArchivedTaskCard(
                                          task: t,
                                          onView: () => setState(
                                              () => _selected = t),
                                          onRestore: () => _restore(t),
                                          onDelete: () => _delete(t),
                                        ),
                                      ))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile header ─────────────────────────────────────────────────────────────

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.total,
    required this.tasks,
    required this.categories,
    required this.users,
  });
  final int total;
  final List<ArchivedTask> tasks;
  final List<CategoryModel> categories;
  final List<UserProfileModel> users;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: DashboardColors.surface.withValues(alpha: .5),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Archived Tasks',
                style: TextStyle(
                  color: DashboardColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '$total Items',
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          ArchiveExportButton(
            tasks: tasks,
            categories: categories,
            users: users,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.archive_rounded,
              color: DashboardColors.primary, size: 28),
        ],
      ),
    );
  }
}

// ── KPI carousel ──────────────────────────────────────────────────────────────

class _MobileKpiCarousel extends StatelessWidget {
  const _MobileKpiCarousel({required this.tasks});
  final List<ArchivedTask> tasks;

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.status == 'done').length;
    final kpis = [
      _KpiData('Archived', '${tasks.length}', Icons.archive_rounded),
      _KpiData('Completed', '$done', Icons.check_circle_outline_rounded),
      _KpiData('Storage', '12.4 MB', Icons.storage_rounded),
      _KpiData('Rate', '92%', Icons.verified_rounded),
    ];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kpis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _MobileKpiTile(data: kpis[i]),
      ),
    );
  }
}

class _KpiData {
  const _KpiData(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _MobileKpiTile extends StatelessWidget {
  const _MobileKpiTile({required this.data});
  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return ArchiveGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      radius: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: DashboardColors.primary, size: 18),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: const TextStyle(
              color: DashboardColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
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

// ── Search bar ────────────────────────────────────────────────────────────────

class _MobileSearchBar extends StatelessWidget {
  const _MobileSearchBar(
      {required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
            color: DashboardColors.onSurface, fontSize: 14),
        cursorColor: DashboardColors.primary,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search_rounded,
              color: DashboardColors.onSurfaceVariant, size: 18),
          hintText: 'Search archived tasks...',
          hintStyle: TextStyle(
              color: DashboardColors.onSurfaceVariant, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _MobileFilterChips extends StatelessWidget {
  const _MobileFilterChips(
      {required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const opts = {
      'all': 'All',
      'done': 'Done',
      'high': 'High',
      'ai': 'AI Generated',
      'month': 'This Month',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: opts.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onSelected(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected == e.key
                            ? DashboardColors.primary.withValues(alpha: .12)
                            : Colors.white.withValues(alpha: .04),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected == e.key
                              ? DashboardColors.primary.withValues(alpha: .35)
                              : Colors.white.withValues(alpha: .08),
                        ),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: selected == e.key
                              ? DashboardColors.primary
                              : DashboardColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _MobileEmptyState extends StatelessWidget {
  const _MobileEmptyState({required this.hasFilter});
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: DashboardColors.primary.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.archive_outlined,
                color: DashboardColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No results found' : 'Archive Empty',
            style: const TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Archived tasks will appear here.',
            style: TextStyle(
                color: DashboardColors.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
