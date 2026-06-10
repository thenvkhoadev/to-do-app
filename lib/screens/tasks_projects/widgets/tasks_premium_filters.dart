import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TasksFilterState {
  const TasksFilterState({
    this.statuses = const {},
    this.priorities = const {},
    this.duePreset,
    this.categoryIds = const {},
    this.assigneeIds = const {},
    this.aiMode = 'all',
    this.archivedMode = 'active',
    this.quickPreset = 'all',
  });

  final Set<TaskBoardStatus> statuses;
  final Set<TaskBoardPriority> priorities;
  final String? duePreset;
  final Set<String> categoryIds;
  final Set<String> assigneeIds;
  final String aiMode;
  final String archivedMode;
  final String quickPreset;

  int get count => statuses.length + priorities.length + categoryIds.length + assigneeIds.length +
      (duePreset == null ? 0 : 1) + (aiMode == 'all' ? 0 : 1) +
      (archivedMode == 'active' ? 0 : 1) + (quickPreset == 'all' ? 0 : 1);

  TasksFilterState copyWith({
    Set<TaskBoardStatus>? statuses,
    Set<TaskBoardPriority>? priorities,
    String? duePreset,
    bool clearDuePreset = false,
    Set<String>? categoryIds,
    Set<String>? assigneeIds,
    String? aiMode,
    String? archivedMode,
    String? quickPreset,
  }) {
    return TasksFilterState(
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      duePreset: clearDuePreset ? null : (duePreset ?? this.duePreset),
      categoryIds: categoryIds ?? this.categoryIds,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      aiMode: aiMode ?? this.aiMode,
      archivedMode: archivedMode ?? this.archivedMode,
      quickPreset: quickPreset ?? this.quickPreset,
    );
  }

  static const empty = TasksFilterState();
}

class TasksPremiumFilterToolbar extends StatelessWidget {
  const TasksPremiumFilterToolbar({
    required this.state,
    required this.onChanged,
    super.key,
  });

  final TasksFilterState state;
  final ValueChanged<TasksFilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _FilterButton(
              label: 'Status',
              active: state.statuses.isNotEmpty,
              count: state.statuses.length,
              onTap: (offset) => _showStatus(context, offset),
            ),
            _FilterButton(
              label: 'Priority',
              active: state.priorities.isNotEmpty,
              count: state.priorities.length,
              onTap: (offset) => _showPriority(context, offset),
            ),
            _FilterButton(
              label: 'Assignee',
              onTap: (offset) => _showPlaceholder(context, offset, 'Filter Assignee'),
            ),
            _FilterButton(
              label: 'Labels',
              onTap: (offset) => _showPlaceholder(context, offset, 'Filter Labels'),
            ),
            _FilterButton(
              label: 'Due Date',
              active: state.duePreset != null,
              count: state.duePreset == null ? 0 : 1,
              onTap: (offset) => _showDueDate(context, offset),
            ),
            _FilterButton(
              label: 'Advanced Filters',
              icon: Icons.tune_rounded,
              active: state.count > 0,
              count: state.count,
              onTap: (offset) => _showAdvanced(context, offset),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _QuickPresets(
          active: state.quickPreset,
          onSelected: (preset) => onChanged(state.copyWith(quickPreset: preset)),
        ),
        if (state.count > 0) ...[
          const SizedBox(height: 12),
          _ActiveChips(state: state, onChanged: onChanged),
        ],
      ],
    );
  }

  Future<void> _showStatus(BuildContext context, Offset offset) async {
    final result = await _showTaskFilterDropdown<TaskBoardStatus>(
      context: context,
      offset: offset,
      title: 'Filter Status',
      selected: state.statuses,
      options: const [
        _FilterOption(TaskBoardStatus.draft, 'Draft', Icons.lightbulb_outline_rounded, Color(0xFFA855F7)),
        _FilterOption(TaskBoardStatus.todo, 'To-do', Icons.radio_button_unchecked_rounded, Color(0xFF5B8CFF)),
        _FilterOption(TaskBoardStatus.inProgress, 'In Progress', Icons.bolt_rounded, Color(0xFFFFB020)),
        _FilterOption(TaskBoardStatus.completed, 'Completed', Icons.verified_rounded, Color(0xFF34C759)),
      ],
    );
    if (result != null) onChanged(state.copyWith(statuses: result));
  }

  Future<void> _showPriority(BuildContext context, Offset offset) async {
    final result = await _showTaskFilterDropdown<TaskBoardPriority>(
      context: context,
      offset: offset,
      title: 'Filter Priority',
      selected: state.priorities,
      options: const [
        _FilterOption(TaskBoardPriority.urgent, 'Critical', Icons.flag_rounded, DashboardColors.error),
        _FilterOption(TaskBoardPriority.high, 'High', Icons.keyboard_double_arrow_up_rounded, DashboardColors.error),
        _FilterOption(TaskBoardPriority.medium, 'Medium', Icons.drag_handle_rounded, DashboardColors.secondary),
        _FilterOption(TaskBoardPriority.low, 'Low', Icons.keyboard_arrow_down_rounded, DashboardColors.tertiary),
      ],
    );
    if (result != null) onChanged(state.copyWith(priorities: result));
  }

  Future<void> _showDueDate(BuildContext context, Offset offset) async {
    final result = await _showTaskFilterDropdown<String>(
      context: context,
      offset: offset,
      title: 'Filter Due Date',
      selected: state.duePreset == null ? const {} : {state.duePreset!},
      singleSelect: true,
      options: const [
        _FilterOption('today', 'Today', Icons.today_rounded, DashboardColors.primary),
        _FilterOption('tomorrow', 'Tomorrow', Icons.event_rounded, DashboardColors.secondary),
        _FilterOption('week', 'This Week', Icons.date_range_rounded, DashboardColors.tertiary),
        _FilterOption('overdue', 'Overdue', Icons.warning_rounded, DashboardColors.error),
        _FilterOption('none', 'No Due Date', Icons.event_busy_rounded, DashboardColors.onSurfaceVariant),
      ],
    );
    if (result != null) {
      onChanged(result.isEmpty ? state.copyWith(clearDuePreset: true) : state.copyWith(duePreset: result.first));
    }
  }

  Future<void> _showAdvanced(BuildContext context, Offset offset) async {
    await _showGlassPopup(
      context: context,
      offset: offset,
      width: 560,
      child: _AdvancedPanel(
        state: state,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _showPlaceholder(BuildContext context, Offset offset, String title) async {
    await _showGlassPopup(
      context: context,
      offset: offset,
      child: _FilterShell(
        title: title,
        subtitle: 'Coming soon',
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Text('This filter will use the same premium dropdown system.', style: TextStyle(color: DashboardColors.onSurfaceVariant)),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.onTap, this.icon, this.active = false, this.count = 0});
  final String label;
  final IconData? icon;
  final bool active;
  final int count;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) => onTap(d.globalPosition),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? DashboardColors.primary.withValues(alpha: .16) : Colors.white.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? DashboardColors.primary.withValues(alpha: .35) : Colors.white.withValues(alpha: .09)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.keyboard_arrow_down_rounded, size: 16, color: active ? DashboardColors.primary : DashboardColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: active ? DashboardColors.primary : DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w800)),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: DashboardColors.primary, shape: BoxShape.circle),
                child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterOption<T> {
  const _FilterOption(this.value, this.label, this.icon, this.color);
  final T value;
  final String label;
  final IconData icon;
  final Color color;
}

Future<Set<T>?> _showTaskFilterDropdown<T>({
  required BuildContext context,
  required Offset offset,
  required String title,
  required Set<T> selected,
  required List<_FilterOption<T>> options,
  bool singleSelect = false,
}) async {
  return _showGlassPopup<Set<T>>(
    context: context,
    offset: offset,
    child: _FilterDropdown<T>(
      title: title,
      selected: selected,
      options: options,
      singleSelect: singleSelect,
    ),
  );
}

Future<T?> _showGlassPopup<T>({required BuildContext context, required Offset offset, required Widget child, double width = 320}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'filter',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final screen = MediaQuery.sizeOf(ctx);
      var left = offset.dx;
      var top = offset.dy + 8;
      if (left + width > screen.width) left = screen.width - width - 16;
      if (top + 520 > screen.height) top = screen.height - 536;
      return Stack(children: [
        Positioned(
          left: left,
          top: top,
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: .98, end: 1).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, -.04), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: Material(type: MaterialType.transparency, child: SizedBox(width: width, child: child)),
              ),
            ),
          ),
        ),
      ]);
    },
  );
}

class _FilterShell extends StatelessWidget {
  const _FilterShell({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B0F1E).withValues(alpha: .92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .45), blurRadius: 60, offset: const Offset(0, 20))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 15, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .8), fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: .07)),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatefulWidget {
  const _FilterDropdown({required this.title, required this.selected, required this.options, required this.singleSelect});
  final String title;
  final Set<T> selected;
  final List<_FilterOption<T>> options;
  final bool singleSelect;

  @override
  State<_FilterDropdown<T>> createState() => _FilterDropdownState<T>();
}

class _FilterDropdownState<T> extends State<_FilterDropdown<T>> {
  late Set<T> _selected = {...widget.selected};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visible = widget.options.where((o) => o.label.toLowerCase().contains(_query.toLowerCase())).toList();
    return _FilterShell(
      title: widget.title,
      subtitle: 'Select one or more options',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(color: DashboardColors.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search_rounded, color: DashboardColors.onSurfaceVariant, size: 18),
                filled: true,
                fillColor: Colors.white.withValues(alpha: .04),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              itemCount: visible.length,
              itemBuilder: (_, i) {
                final option = visible[i];
                final active = _selected.contains(option.value);
                return _OptionRow(
                  label: option.label,
                  icon: option.icon,
                  color: option.color,
                  active: active,
                  onTap: () => setState(() {
                    if (widget.singleSelect) {
                      _selected = active ? <T>{} : {option.value};
                    } else if (active) {
                      _selected.remove(option.value);
                    } else {
                      _selected.add(option.value);
                    }
                  }),
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: .07)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              TextButton(onPressed: () => setState(() => _selected.clear()), child: const Text('Clear Filters')),
              const Spacer(),
              FilledButton(onPressed: () => Navigator.of(context).pop(_selected), child: const Text('Apply')),
            ]),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatefulWidget {
  const _OptionRow({required this.label, required this.icon, required this.color, required this.active, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.active ? DashboardColors.primary.withValues(alpha: .15) : (_hovered ? Colors.white.withValues(alpha: .05) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.active ? DashboardColors.primary.withValues(alpha: .35) : Colors.transparent),
          ),
          child: Row(children: [
            Icon(widget.icon, size: 16, color: widget.color),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.label, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700))),
            Icon(widget.active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: widget.active ? DashboardColors.primary : DashboardColors.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }
}

class _QuickPresets extends StatelessWidget {
  const _QuickPresets({required this.active, required this.onSelected});
  final String active;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const presets = [
      ('all', 'All Tasks'),
      ('mine', 'My Tasks'),
      ('today', 'Due Today'),
      ('overdue', 'Overdue'),
      ('completed', 'Completed'),
      ('high', 'High Priority'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((p) {
        final selected = active == p.$1;
        return GestureDetector(
          onTap: () => onSelected(p.$1),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected ? const LinearGradient(colors: [Color(0xFF7C5CFF), Color(0xFF9A7BFF)]) : null,
              color: selected ? null : Colors.white.withValues(alpha: .035),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? Colors.transparent : Colors.white.withValues(alpha: .08)),
            ),
            child: Text(p.$2, style: TextStyle(color: selected ? Colors.white : DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        );
      }).toList(),
    );
  }
}

class _ActiveChips extends StatelessWidget {
  const _ActiveChips({required this.state, required this.onChanged});
  final TasksFilterState state;
  final ValueChanged<TasksFilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (final s in state.statuses) {
      chips.add(_Chip(label: 'Status: ${s.displayLabel}', onRemove: () => onChanged(state.copyWith(statuses: {...state.statuses}..remove(s)))));
    }
    for (final p in state.priorities) {
      chips.add(_Chip(label: 'Priority: ${p.name}', onRemove: () => onChanged(state.copyWith(priorities: {...state.priorities}..remove(p)))));
    }
    if (state.duePreset != null) {
      chips.add(_Chip(label: 'Due: ${state.duePreset}', onRemove: () => onChanged(state.copyWith(clearDuePreset: true))));
    }
    if (state.quickPreset != 'all') {
      chips.add(_Chip(label: 'Preset: ${state.quickPreset}', onRemove: () => onChanged(state.copyWith(quickPreset: 'all'))));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: DashboardColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DashboardColors.primary.withValues(alpha: .22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(color: DashboardColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(width: 6),
        GestureDetector(onTap: onRemove, child: const Icon(Icons.close_rounded, color: DashboardColors.primary, size: 16)),
      ]),
    );
  }
}

void showTasksFilterMenu({
  required BuildContext context,
  required Offset offset,
  required TasksFilterState state,
  required ValueChanged<TasksFilterState> onChanged,
}) {
  _showGlassPopup<void>(
    context: context,
    offset: offset,
    width: 560,
    child: _MainFilterMenu(state: state, onChanged: onChanged),
  );
}

class _MainFilterMenu extends ConsumerStatefulWidget {
  const _MainFilterMenu({required this.state, required this.onChanged});
  final TasksFilterState state;
  final ValueChanged<TasksFilterState> onChanged;

  @override
  ConsumerState<_MainFilterMenu> createState() => _MainFilterMenuState();
}

class _MainFilterMenuState extends ConsumerState<_MainFilterMenu> {
  late TasksFilterState _state = widget.state;

  void _emit(TasksFilterState state) {
    setState(() => _state = state);
    widget.onChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? const <NexusTask>[];
    final categories = ref.watch(userCategoriesProvider).valueOrNull ?? const <CategoryModel>[];
    final users = ref.watch(allUsersProvider).valueOrNull ?? const [];
    final matching = tasks.where((t) => _matchesTask(t, _state)).toList();

    return _FilterShell(
      title: 'Filters',
      subtitle: 'Refine and explore your tasks intelligently',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: _StatsCounter(showing: matching.length, total: tasks.length),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: .07)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final twoCols = c.maxWidth >= 500;
                    final controls = _FilterControls(
                      state: _state,
                      onChanged: _emit,
                      tasks: tasks,
                      categories: categories,
                      users: users,
                    );
                    final preview = _LivePreview(tasks: matching);
                    return twoCols
                        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: controls),
                            const SizedBox(width: 16),
                            Expanded(child: preview),
                          ])
                        : Column(children: [controls, const SizedBox(height: 16), preview]);
                  },
                ),
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: .07)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Text('${_state.count} Filters Applied', style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(onPressed: () => _emit(TasksFilterState.empty), child: const Text('Reset')),
                const SizedBox(width: 8),
                FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Apply Filters')),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

bool _matchesTask(NexusTask t, TasksFilterState f) {
  if (f.statuses.isNotEmpty) {
    final status = switch (t.status) {
      'draft' => TaskBoardStatus.draft,
      'in_progress' => TaskBoardStatus.inProgress,
      'done' => TaskBoardStatus.completed,
      _ => TaskBoardStatus.todo,
    };
    if (!f.statuses.contains(status)) return false;
  }
  if (f.priorities.isNotEmpty) {
    final p = switch (t.priority) {
      'urgent' => TaskBoardPriority.urgent,
      'high' => TaskBoardPriority.high,
      'low' => TaskBoardPriority.low,
      _ => TaskBoardPriority.medium,
    };
    if (!f.priorities.contains(p)) return false;
  }
  if (f.categoryIds.isNotEmpty && (t.categoryId == null || !f.categoryIds.contains(t.categoryId))) return false;
  if (f.assigneeIds.isNotEmpty && !t.assigneeIds.any(f.assigneeIds.contains)) return false;
  if (f.aiMode == 'ai' && !t.aiGenerated) return false;
  if (f.aiMode == 'manual' && t.aiGenerated) return false;
  return true;
}

class _StatsCounter extends StatelessWidget {
  const _StatsCounter({required this.showing, required this.total});
  final int showing;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Text('Showing', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w800)),
      const SizedBox(width: 10),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Text('$showing Tasks', key: ValueKey(showing), style: const TextStyle(color: DashboardColors.onSurface, fontSize: 22, fontWeight: FontWeight.w900)),
      ),
      const SizedBox(width: 10),
      Text('out of $total Total Tasks', style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _FilterControls extends StatelessWidget {
  const _FilterControls({required this.state, required this.onChanged, required this.tasks, required this.categories, required this.users});
  final TasksFilterState state;
  final ValueChanged<TasksFilterState> onChanged;
  final List<NexusTask> tasks;
  final List<CategoryModel> categories;
  final List<dynamic> users;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _PanelTitle('Quick Filters'),
      _QuickPresets(active: state.quickPreset, onSelected: (p) => onChanged(state.copyWith(quickPreset: p))),
      const SizedBox(height: 16),
      const _PanelTitle('Status'),
      ...TaskBoardStatus.values.map((s) => _StatRow(
            label: s.displayLabel,
            count: tasks.where((t) => _statusOf(t) == s).length,
            icon: s.displayIcon,
            color: s.displayColor,
            active: state.statuses.contains(s),
            onTap: () => onChanged(state.copyWith(statuses: {...state.statuses}..toggle(s))),
          )),
      const SizedBox(height: 14),
      const _PanelTitle('Priority'),
      ...TaskBoardPriority.values.where((p) => p != TaskBoardPriority.done).map((p) => _StatRow(
            label: p.name[0].toUpperCase() + p.name.substring(1),
            count: tasks.where((t) => _priorityOf(t) == p).length,
            icon: Icons.flag_rounded,
            color: _priorityColor(p),
            active: state.priorities.contains(p),
            onTap: () => onChanged(state.copyWith(priorities: {...state.priorities}..toggle(p))),
          )),
      const SizedBox(height: 14),
      const _PanelTitle('Category'),
      ...categories.take(6).map((c) => _StatRow(
            label: c.name,
            count: tasks.where((t) => t.categoryId == c.id).length,
            icon: Icons.folder_rounded,
            color: DashboardColors.primary,
            active: state.categoryIds.contains(c.id),
            onTap: () => onChanged(state.copyWith(categoryIds: {...state.categoryIds}..toggle(c.id))),
          )),
      const SizedBox(height: 14),
      const _PanelTitle('AI Generated'),
      _StatRow(label: 'AI Generated', count: tasks.where((t) => t.aiGenerated).length, icon: Icons.auto_awesome_rounded, color: DashboardColors.secondary, active: state.aiMode == 'ai', onTap: () => onChanged(state.copyWith(aiMode: state.aiMode == 'ai' ? 'all' : 'ai'))),
      _StatRow(label: 'Manual Tasks', count: tasks.where((t) => !t.aiGenerated).length, icon: Icons.person_rounded, color: DashboardColors.tertiary, active: state.aiMode == 'manual', onTap: () => onChanged(state.copyWith(aiMode: state.aiMode == 'manual' ? 'all' : 'manual'))),
    ]);
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({required this.tasks});
  final List<NexusTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .04), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Preview Results', style: TextStyle(color: DashboardColors.onSurface, fontSize: 14, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('${tasks.length} matching tasks', style: const TextStyle(color: DashboardColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No matching tasks found\nTry adjusting filters.', textAlign: TextAlign.center, style: TextStyle(color: DashboardColors.onSurfaceVariant))))
        else
          ...tasks.take(5).map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 8),
                  Text(t.priority, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              )),
      ]),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: .4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
      );
}

class _StatRow extends StatefulWidget {
  const _StatRow({required this.label, required this.count, required this.icon, required this.color, required this.active, required this.onTap});
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  @override
  State<_StatRow> createState() => _StatRowState();
}

class _StatRowState extends State<_StatRow> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.active ? DashboardColors.primary.withValues(alpha: .15) : (_hovered ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .025)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.active ? DashboardColors.primary.withValues(alpha: .35) : Colors.white.withValues(alpha: .06)),
            ),
            child: Row(children: [
              Icon(widget.icon, color: widget.color, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.label, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w800))),
              AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: Text('${widget.count}', key: ValueKey(widget.count), style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w800))),
            ]),
          ),
        ),
      );
}

extension _ToggleSet<T> on Set<T> {
  void toggle(T value) => contains(value) ? remove(value) : add(value);
}

TaskBoardStatus _statusOf(NexusTask t) => switch (t.status) { 'draft' => TaskBoardStatus.draft, 'in_progress' => TaskBoardStatus.inProgress, 'done' => TaskBoardStatus.completed, _ => TaskBoardStatus.todo };
TaskBoardPriority _priorityOf(NexusTask t) => switch (t.priority) { 'urgent' => TaskBoardPriority.urgent, 'high' => TaskBoardPriority.high, 'low' => TaskBoardPriority.low, _ => TaskBoardPriority.medium };
Color _priorityColor(TaskBoardPriority p) => switch (p) { TaskBoardPriority.urgent || TaskBoardPriority.high => DashboardColors.error, TaskBoardPriority.medium => DashboardColors.secondary, TaskBoardPriority.low => DashboardColors.tertiary, TaskBoardPriority.done => DashboardColors.success };

class _AdvancedPanel extends StatelessWidget {
  const _AdvancedPanel({required this.state, required this.onChanged});
  final TasksFilterState state;
  final ValueChanged<TasksFilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FilterShell(
      title: 'Advanced Filters',
      subtitle: 'Build a precise task view',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Status, priority, assignee, labels, project, date and completion filters share this system.', style: TextStyle(color: DashboardColors.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 16),
          Row(children: [
            TextButton(onPressed: () => onChanged(TasksFilterState.empty), child: const Text('Clear Filters')),
            const Spacer(),
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Apply')),
          ]),
        ]),
      ),
    );
  }
}
