import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_ai_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_assigned_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_attachments_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_categories_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_date_range_desktop.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_other_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_priority_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_smart_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_status_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_subtasks_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_tags_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_time_section.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DesktopFilterPanel extends ConsumerStatefulWidget {
  const DesktopFilterPanel({
    required this.initialState,
    required this.onApply,
    required this.onClose,
    super.key,
  });

  final FilterState initialState;
  final ValueChanged<FilterState> onApply;
  final VoidCallback onClose;

  @override
  ConsumerState<DesktopFilterPanel> createState() => _DesktopFilterPanelState();
}

class _DesktopFilterPanelState extends ConsumerState<DesktopFilterPanel>
    with SingleTickerProviderStateMixin {
  late FilterState _state;
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, .02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: .98,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onClose();
  }

  int get _activeCount => _state.activeCount;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          alignment: Alignment.topCenter,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xF0131420),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .06),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0FFFFFFF), spreadRadius: 1),
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 60,
                      offset: Offset(0, 20),
                    ),
                    BoxShadow(color: Color(0x147C5CFF), blurRadius: 40),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _divider(),
                    Flexible(child: _buildBody()),
                    _divider(),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? const [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x1AE1DFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: .15)),
            ),
            child: const Icon(
              Icons.filter_list_rounded,
              color: DashboardColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Tasks',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Showing ${tasks.length} tasks',
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _state = _state.reset()),
            child: Row(
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  color: DashboardColors.onSurfaceVariant,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _activeCount > 0 ? 'Clear all ($_activeCount)' : 'Clear all',
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: _dismiss,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: DashboardColors.surfaceHigh,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: DashboardColors.onSurfaceVariant,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            icon: Icons.auto_awesome_rounded,
            label: 'QUICK SMART FILTERS',
            child: FilterSmartSection(
              selected: _state.selectedSmartFilters,
              onChanged: (value) =>
                  setState(() => _state = _state.copyWith(selectedSmartFilters: value)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SectionCard(
                  icon: Icons.calendar_view_day_rounded,
                  label: 'STATUS',
                  child: FilterStatusSection(
                    selected: _state.selectedStatuses,
                    onChanged:
                        (value) => setState(
                          () =>
                              _state = _state.copyWith(selectedStatuses: value),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SectionCard(
                  icon: Icons.flag_rounded,
                  label: 'PRIORITY',
                  child: FilterPrioritySection(
                    selected: _state.selectedPriorities,
                    onChanged:
                        (value) => setState(
                          () =>
                              _state = _state.copyWith(
                                selectedPriorities: value,
                              ),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SectionCard(
                  icon: Icons.folder_outlined,
                  label: 'CATEGORIES',
                  trailing: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.add,
                      size: 14,
                      color: DashboardColors.onSurfaceVariant,
                    ),
                    label: const Text(
                      'Add',
                      style: TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  child: FilterCategoriesSection(
                    selected: _state.selectedCategoryIds,
                    onChanged:
                        (value) => setState(
                          () =>
                              _state = _state.copyWith(
                                selectedCategoryIds: value,
                              ),
                        ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SectionCard(
                  icon: Icons.calendar_month_outlined,
                  label: 'DATE RANGE',
                  child: FilterDateRangeDesktop(
                    preset: _state.datePreset,
                    startDate: _state.startDate,
                    endDate: _state.endDate,
                    onPresetChanged:
                        (value) => setState(
                          () => _state = _state.copyWith(datePreset: value),
                        ),
                    onRangeChanged:
                        (start, end) => setState(
                          () =>
                              _state = _state.copyWith(
                                startDate: start,
                                endDate: end,
                                datePreset: DateRangePreset.custom,
                              ),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SectionCard(
                  icon: Icons.person_outline_rounded,
                  label: 'ASSIGNED TO',
                  child: FilterAssignedSection(
                    selectedUserId: _state.assignedUserId,
                    unassignedOnly: _state.unassignedOnly,
                    selectedAssigneeIds: _state.selectedAssigneeIds,
                    specialFilters: _state.assigneeSpecialFilters,
                    onUserChanged:
                        (value) => setState(
                          () => _state = _state.copyWith(assignedUserId: value),
                        ),
                    onUnassignedChanged:
                        (value) => setState(
                          () => _state = _state.copyWith(unassignedOnly: value),
                        ),
                    onAssigneeIdsChanged: (value) => setState(
                      () => _state = _state.copyWith(selectedAssigneeIds: value),
                    ),
                    onSpecialFiltersChanged: (value) => setState(
                      () => _state = _state.copyWith(assigneeSpecialFilters: value),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.tune_rounded,
            label: 'OTHER FILTERS',
            child: FilterOtherSection(
              state: _state,
              onChanged: (value) => setState(() => _state = value),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SectionCard(
                  icon: Icons.label_outline_rounded,
                  label: 'TAGS',
                  child: FilterTagsSection(
                    selected: _state.selectedTagIds,
                    onChanged: (value) =>
                        setState(() => _state = _state.copyWith(selectedTagIds: value)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SectionCard(
                  icon: Icons.schedule_rounded,
                  label: 'TIME FILTERS',
                  child: FilterTimeSection(
                    selected: _state.selectedTimeFilters,
                    onChanged: (value) =>
                        setState(() => _state = _state.copyWith(selectedTimeFilters: value)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SectionCard(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI TASKS',
                  child: FilterAiSection(
                    value: _state.aiTaskFilter,
                    onChanged: (value) =>
                        setState(() => _state = _state.copyWith(aiTaskFilter: value)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SectionCard(
                  icon: Icons.attach_file_rounded,
                  label: 'ATTACHMENTS',
                  child: FilterAttachmentsSection(
                    value: _state.attachmentFilter,
                    onChanged: (value) =>
                        setState(() => _state = _state.copyWith(attachmentFilter: value)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.list_alt_rounded,
            label: 'SUBTASKS',
            child: FilterSubtasksSection(
              selected: _state.selectedSubtaskFilters,
              searchQuery: _state.subtaskSearch,
              onSearchChanged: (v) =>
                  setState(() => _state = _state.copyWith(subtaskSearch: v)),
              onChanged: (value) =>
                  setState(() => _state = _state.copyWith(selectedSubtaskFilters: value)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _state = _state.reset()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: DashboardColors.outlineVariant.withValues(alpha: .25),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: DashboardColors.onSurfaceVariant,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Reset All Filters',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (_activeCount > 0) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: DashboardColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_activeCount active filter${_activeCount > 1 ? 's' : ''}',
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 24),
          ],
          GestureDetector(
            onTap: () => widget.onApply(_state),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: DashboardColors.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40321ED2),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: DashboardColors.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _activeCount > 0 ? 'Apply Filters ($_activeCount)' : 'Apply Filters',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    color: Colors.white.withValues(alpha: .08),
    height: 1,
    thickness: 1,
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: DashboardColors.onSurfaceVariant, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .96,
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
