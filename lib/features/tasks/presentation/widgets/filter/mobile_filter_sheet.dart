import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_ai_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_assigned_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_attachments_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_categories_grid.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_date_range_mobile.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_priority_tabs.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_smart_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_status_chips.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_subtasks_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_tags_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_time_section.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileFilterSheet extends StatefulWidget {
  const MobileFilterSheet({
    required this.initialState,
    required this.onApply,
    super.key,
  });

  final FilterState initialState;
  final ValueChanged<FilterState> onApply;

  static Future<FilterState?> show(
    BuildContext context, {
    required FilterState initialState,
  }) {
    return showModalBottomSheet<FilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder:
          (sheetContext) => MobileFilterSheet(
            initialState: initialState,
            onApply: (state) => Navigator.pop(sheetContext, state),
          ),
    );
  }

  @override
  State<MobileFilterSheet> createState() => _MobileFilterSheetState();
}

class _MobileFilterSheetState extends State<MobileFilterSheet> {
  late FilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return DraggableScrollableSheet(
      initialChildSize: .92,
      maxChildSize: .95,
      minChildSize: .50,
      builder:
          (_, scrollController) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xBF121315),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(
                    top: BorderSide(color: Color(0x26FFFFFF)),
                    left: BorderSide(color: Color(0x14FFFFFF)),
                    right: BorderSide(color: Color(0x14FFFFFF)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 40,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF46464F),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Row(
                        children: [
                          const Text(
                            'Filter Tasks',
                            style: TextStyle(
                              color: Color(0xFFE1DFFF),
                              fontSize: 24,
                              height: 1.3,
                              letterSpacing: -.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Material(
                            color: Colors.white.withValues(alpha: .03),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .08),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFFC7C5D0),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: .08),
                      height: 24,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FilterSmartSection(
                              selected: _state.selectedSmartFilters,
                              onChanged: (v) => setState(
                                () => _state = _state.copyWith(selectedSmartFilters: v),
                              ),
                            ),
                            const SizedBox(height: 32),
                            FilterStatusChips(
                              selected: _state.selectedStatuses,
                              onChanged:
                                  (v) => setState(
                                    () =>
                                        _state = _state.copyWith(
                                          selectedStatuses: v,
                                        ),
                                  ),
                            ),
                            const SizedBox(height: 32),
                            FilterPriorityTabs(
                              selected: _state.selectedPriorities,
                              onChanged:
                                  (v) => setState(
                                    () =>
                                        _state = _state.copyWith(
                                          selectedPriorities: v,
                                        ),
                                  ),
                            ),
                            const SizedBox(height: 32),
                            FilterCategoriesGrid(
                              selected: _state.selectedCategoryIds,
                              onChanged:
                                  (v) => setState(
                                    () =>
                                        _state = _state.copyWith(
                                          selectedCategoryIds: v,
                                        ),
                                  ),
                            ),
                            const SizedBox(height: 32),
                            _MobileSectionHeader(icon: Icons.label_outline_rounded, label: 'TAGS'),
                            const SizedBox(height: 12),
                            FilterTagsSection(
                              selected: _state.selectedTagIds,
                              onChanged: (v) => setState(
                                () => _state = _state.copyWith(selectedTagIds: v),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _MobileSectionHeader(icon: Icons.person_outline_rounded, label: 'ASSIGNEES'),
                            const SizedBox(height: 12),
                            FilterAssignedSection(
                              selectedUserId: _state.assignedUserId,
                              unassignedOnly: _state.unassignedOnly,
                              selectedAssigneeIds: _state.selectedAssigneeIds,
                              specialFilters: _state.assigneeSpecialFilters,
                              onUserChanged: (v) => setState(
                                () => _state = _state.copyWith(assignedUserId: v),
                              ),
                              onUnassignedChanged: (v) => setState(
                                () => _state = _state.copyWith(unassignedOnly: v),
                              ),
                              onAssigneeIdsChanged: (v) => setState(
                                () => _state = _state.copyWith(selectedAssigneeIds: v),
                              ),
                              onSpecialFiltersChanged: (v) => setState(
                                () => _state = _state.copyWith(assigneeSpecialFilters: v),
                              ),
                            ),
                            const SizedBox(height: 32),
                            FilterDateRangeMobile(
                              preset: _state.datePreset,
                              startDate: _state.startDate,
                              endDate: _state.endDate,
                              onPresetChanged:
                                  (preset) => setState(
                                    () =>
                                        _state = _state.copyWith(
                                          datePreset: preset,
                                        ),
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
                            const SizedBox(height: 32),
                            _MobileSectionHeader(icon: Icons.schedule_rounded, label: 'TIME FILTERS'),
                            const SizedBox(height: 12),
                            FilterTimeSection(
                              selected: _state.selectedTimeFilters,
                              onChanged: (v) => setState(
                                () => _state = _state.copyWith(selectedTimeFilters: v),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _MobileSectionHeader(icon: Icons.auto_awesome_outlined, label: 'AI TASKS'),
                            const SizedBox(height: 12),
                            FilterAiSection(
                              value: _state.aiTaskFilter,
                              onChanged: (v) => setState(
                                () => _state = _state.copyWith(aiTaskFilter: v),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _MobileSectionHeader(icon: Icons.attach_file_rounded, label: 'ATTACHMENTS'),
                            const SizedBox(height: 12),
                            FilterAttachmentsSection(
                              value: _state.attachmentFilter,
                              onChanged: (v) => setState(
                                () => _state = _state.copyWith(attachmentFilter: v),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _MobileSectionHeader(icon: Icons.list_alt_rounded, label: 'SUBTASKS'),
                            const SizedBox(height: 12),
                            FilterSubtasksSection(
                              selected: _state.selectedSubtaskFilters,
                              searchQuery: _state.subtaskSearch,
                              onSearchChanged: (v) => setState(
                                () => _state = _state.copyWith(subtaskSearch: v),
                              ),
                              onChanged: (v) => setState(
                                () => _state = _state.copyWith(selectedSubtaskFilters: v),
                              ),
                            ),
                            SizedBox(height: mq.viewInsets.bottom + 16),
                          ],
                        ),
                      ),
                    ),
                    _Footer(
                      onApply: () => widget.onApply(_state),
                      onReset: () => setState(() => _state = _state.reset()),
                      activeCount: _state.activeCount,
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onApply, required this.onReset, this.activeCount = 0});
  final VoidCallback onApply;
  final VoidCallback onReset;
  final int activeCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      24,
      16,
      24,
      MediaQuery.of(context).padding.bottom + 16,
    ),
    decoration: const BoxDecoration(
      color: Color(0x800D0E0F),
      border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFE1DFFF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x4DC0C1FF), blurRadius: 20),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onApply,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                    'Apply Filters${activeCount > 0 ? ' ($activeCount)' : ''}',
                      style: TextStyle(
                        color: Color(0xFF131449),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onReset,
          child: Text(
            activeCount > 0 ? 'Reset All ($activeCount)' : 'Reset All',
            style: const TextStyle(
              color: Color(0xFFC7C5D0),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MobileSectionHeader extends StatelessWidget {
  const _MobileSectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: DashboardColors.onSurfaceVariant, size: 14),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: DashboardColors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: .96,
        ),
      ),
    ],
  );
}
