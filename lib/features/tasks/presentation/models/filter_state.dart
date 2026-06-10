enum TaskStatus { all, todo, inProgress, review, completed }

enum TaskPriority { urgent, high, medium, low }

enum DateRangePreset { today, thisWeek, month, custom }

class FilterState {
  final Set<TaskStatus> selectedStatuses;
  final Set<TaskPriority> selectedPriorities;
  final Set<String> selectedCategoryIds;
  final DateRangePreset datePreset;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? assignedUserId;
  final bool unassignedOnly;
  final bool hasSubtasks;
  final bool missingSubtasks;
  final bool overdue;
  final bool blocked;

  const FilterState({
    this.selectedStatuses = const {TaskStatus.all},
    this.selectedPriorities = const {},
    this.selectedCategoryIds = const {},
    this.datePreset = DateRangePreset.thisWeek,
    this.startDate,
    this.endDate,
    this.assignedUserId,
    this.unassignedOnly = false,
    this.hasSubtasks = false,
    this.missingSubtasks = false,
    this.overdue = false,
    this.blocked = false,
  });

  FilterState copyWith({
    Set<TaskStatus>? selectedStatuses,
    Set<TaskPriority>? selectedPriorities,
    Set<String>? selectedCategoryIds,
    DateRangePreset? datePreset,
    DateTime? startDate,
    DateTime? endDate,
    String? assignedUserId,
    bool clearAssignedUserId = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool? unassignedOnly,
    bool? hasSubtasks,
    bool? missingSubtasks,
    bool? overdue,
    bool? blocked,
  }) {
    return FilterState(
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedPriorities: selectedPriorities ?? this.selectedPriorities,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      datePreset: datePreset ?? this.datePreset,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      assignedUserId:
          clearAssignedUserId ? null : (assignedUserId ?? this.assignedUserId),
      unassignedOnly: unassignedOnly ?? this.unassignedOnly,
      hasSubtasks: hasSubtasks ?? this.hasSubtasks,
      missingSubtasks: missingSubtasks ?? this.missingSubtasks,
      overdue: overdue ?? this.overdue,
      blocked: blocked ?? this.blocked,
    );
  }

  FilterState reset() => const FilterState();
}
