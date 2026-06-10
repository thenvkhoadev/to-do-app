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

  const FilterState({
    this.selectedStatuses = const {TaskStatus.all},
    this.selectedPriorities = const {},
    this.selectedCategoryIds = const {},
    this.datePreset = DateRangePreset.thisWeek,
    this.startDate,
    this.endDate,
  });

  FilterState copyWith({
    Set<TaskStatus>? selectedStatuses,
    Set<TaskPriority>? selectedPriorities,
    Set<String>? selectedCategoryIds,
    DateRangePreset? datePreset,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return FilterState(
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedPriorities: selectedPriorities ?? this.selectedPriorities,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      datePreset: datePreset ?? this.datePreset,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  FilterState reset() => const FilterState();
}
