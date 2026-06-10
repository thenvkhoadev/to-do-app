import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/data/models/task_subtask_model.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_data_helpers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterSubtasksSection extends ConsumerStatefulWidget {
  const FilterSubtasksSection({
    required this.selected,
    required this.onChanged,
    this.searchQuery = '',
    this.onSearchChanged,
    super.key,
  });

  final Set<SubtaskFilter> selected;
  final ValueChanged<Set<SubtaskFilter>> onChanged;
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;

  @override
  ConsumerState<FilterSubtasksSection> createState() =>
      _FilterSubtasksSectionState();
}

class _FilterSubtasksSectionState
    extends ConsumerState<FilterSubtasksSection> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(FilterSubtasksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        _controller.text != widget.searchQuery) {
      _controller.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _search => _controller.text;

  @override
  Widget build(BuildContext context) {
    final subtasksByTask =
        ref.watch(userSubtasksByTaskProvider).valueOrNull ??
            const <String, List<TaskSubtaskModel>>{};
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? const [];

    final counts = <SubtaskFilter, int>{
      SubtaskFilter.hasSubtasks: tasks
          .where((t) => subtasksByTask[t.id]?.isNotEmpty ?? false)
          .length,
      SubtaskFilter.noSubtasks: tasks
          .where((t) => subtasksByTask[t.id]?.isEmpty ?? true)
          .length,
      SubtaskFilter.completedSubtasks: tasks.where((t) {
        final list = subtasksByTask[t.id];
        return list != null &&
            list.isNotEmpty &&
            list.every((s) => s.isDone);
      }).length,
      SubtaskFilter.incompleteSubtasks: tasks.where((t) {
        final list = subtasksByTask[t.id];
        return list != null && list.any((s) => !s.isDone);
      }).length,
    };

    // collect subtask titles that match search
    final matchingTaskIds = _search.trim().isEmpty
        ? null
        : subtasksByTask.entries
            .where((e) => e.value.any((s) =>
                s.title.toLowerCase().contains(_search.toLowerCase())))
            .map((e) => e.key)
            .toSet();

    final searchResultCount = matchingTaskIds?.length;

    final visibleFilters = SubtaskFilter.values
        .where((f) =>
            _search.trim().isEmpty ||
            subtaskFilterLabel(f)
                .toLowerCase()
                .contains(_search.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: DashboardColors.surfaceLow,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.search_rounded,
                  color: DashboardColors.onSurfaceVariant,
                  size: 16,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (v) {
                    setState(() {});
                    widget.onSearchChanged?.call(v);
                  },
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search subtasks...',
                    hintStyle: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_search.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() {});
                    widget.onSearchChanged?.call('');
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.close_rounded,
                      color: DashboardColors.onSurfaceVariant,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (searchResultCount != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$searchResultCount task${searchResultCount == 1 ? '' : 's'} with matching subtasks',
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (visibleFilters.isEmpty)
          const Text(
            'No filters match',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleFilters.map((filter) {
              final active = widget.selected.contains(filter);
              return GestureDetector(
                onTap: () {
                  final next = Set<SubtaskFilter>.from(widget.selected);
                  active ? next.remove(filter) : next.add(filter);
                  widget.onChanged(next);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: active
                        ? DashboardColors.secondaryContainer
                            .withValues(alpha: .14)
                        : DashboardColors.surfaceLow,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? DashboardColors.secondary
                              .withValues(alpha: .40)
                          : Colors.white.withValues(alpha: .08),
                    ),
                  ),
                  child: Text(
                    '${subtaskFilterLabel(filter)} (${counts[filter] ?? 0})',
                    style: TextStyle(
                      color: active
                          ? DashboardColors.onSurface
                          : DashboardColors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
