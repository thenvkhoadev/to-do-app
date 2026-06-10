enum TaskStatus { all, todo, inProgress, review, completed }

enum TaskPriority { urgent, high, medium, low }

enum DateRangePreset { today, thisWeek, month, custom }

enum TimeFilter {
  dueToday,
  dueTomorrow,
  dueThisWeek,
  dueNextWeek,
  overdue,
  completedToday,
  completedThisWeek,
  createdToday,
  recentlyUpdated,
}

enum AiTaskFilter { all, generated, manual }

enum AttachmentFilter { all, hasAttachments, noAttachments }

enum AssigneeSpecialFilter { assignedToMe, unassigned, createdByMe }

enum SubtaskFilter { hasSubtasks, noSubtasks, completedSubtasks, incompleteSubtasks }

enum SmartFilter {
  myTasks,
  dueToday,
  overdue,
  highPriority,
  completed,
  recentlyAdded,
  aiGenerated,
  hasAttachments,
  unassigned,
  archived,
}

class FilterState {
  final Set<TaskStatus> selectedStatuses;
  final Set<TaskPriority> selectedPriorities;
  final Set<String> selectedCategoryIds;
  final Set<String> selectedTagIds;
  final DateRangePreset datePreset;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? assignedUserId;
  final Set<String> selectedAssigneeIds;
  final Set<AssigneeSpecialFilter> assigneeSpecialFilters;
  final bool unassignedOnly;
  final bool hasSubtasks;
  final bool missingSubtasks;
  final Set<SubtaskFilter> selectedSubtaskFilters;
  final bool overdue;
  final bool blocked;
  final Set<TimeFilter> selectedTimeFilters;
  final AiTaskFilter aiTaskFilter;
  final AttachmentFilter attachmentFilter;
  final Set<SmartFilter> selectedSmartFilters;
  final String subtaskSearch;

  const FilterState({
    this.selectedStatuses = const {TaskStatus.all},
    this.selectedPriorities = const {},
    this.selectedCategoryIds = const {},
    this.selectedTagIds = const {},
    this.datePreset = DateRangePreset.thisWeek,
    this.startDate,
    this.endDate,
    this.assignedUserId,
    this.selectedAssigneeIds = const {},
    this.assigneeSpecialFilters = const {},
    this.unassignedOnly = false,
    this.hasSubtasks = false,
    this.missingSubtasks = false,
    this.selectedSubtaskFilters = const {},
    this.overdue = false,
    this.blocked = false,
    this.selectedTimeFilters = const {},
    this.aiTaskFilter = AiTaskFilter.all,
    this.attachmentFilter = AttachmentFilter.all,
    this.selectedSmartFilters = const {},
    this.subtaskSearch = '',
  });

  int get activeCount {
    var count = 0;
    if (selectedPriorities.isNotEmpty) count += selectedPriorities.length;
    count += selectedCategoryIds.length;
    count += selectedTagIds.length;
    if (!selectedStatuses.contains(TaskStatus.all) || selectedStatuses.length > 1) {
      count += selectedStatuses.where((status) => status != TaskStatus.all).length;
    }
    if (startDate != null || endDate != null) count++;
    count += selectedAssigneeIds.length;
    count += assigneeSpecialFilters.length;
    if (unassignedOnly) count++;
    if (assignedUserId != null) count++;
    count += selectedSubtaskFilters.length;
    if (hasSubtasks) count++;
    if (missingSubtasks) count++;
    if (overdue) count++;
    if (blocked) count++;
    count += selectedTimeFilters.length;
    if (aiTaskFilter != AiTaskFilter.all) count++;
    if (attachmentFilter != AttachmentFilter.all) count++;
    count += selectedSmartFilters.length;
    return count;
  }

  FilterState copyWith({
    Set<TaskStatus>? selectedStatuses,
    Set<TaskPriority>? selectedPriorities,
    Set<String>? selectedCategoryIds,
    Set<String>? selectedTagIds,
    DateRangePreset? datePreset,
    DateTime? startDate,
    DateTime? endDate,
    String? assignedUserId,
    Set<String>? selectedAssigneeIds,
    Set<AssigneeSpecialFilter>? assigneeSpecialFilters,
    bool clearAssignedUserId = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool? unassignedOnly,
    bool? hasSubtasks,
    bool? missingSubtasks,
    Set<SubtaskFilter>? selectedSubtaskFilters,
    bool? overdue,
    bool? blocked,
    Set<TimeFilter>? selectedTimeFilters,
    AiTaskFilter? aiTaskFilter,
    AttachmentFilter? attachmentFilter,
    Set<SmartFilter>? selectedSmartFilters,
    String? subtaskSearch,
  }) {
    return FilterState(
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedPriorities: selectedPriorities ?? this.selectedPriorities,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      datePreset: datePreset ?? this.datePreset,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      assignedUserId:
          clearAssignedUserId ? null : (assignedUserId ?? this.assignedUserId),
      selectedAssigneeIds: selectedAssigneeIds ?? this.selectedAssigneeIds,
      assigneeSpecialFilters:
          assigneeSpecialFilters ?? this.assigneeSpecialFilters,
      unassignedOnly: unassignedOnly ?? this.unassignedOnly,
      hasSubtasks: hasSubtasks ?? this.hasSubtasks,
      missingSubtasks: missingSubtasks ?? this.missingSubtasks,
      selectedSubtaskFilters:
          selectedSubtaskFilters ?? this.selectedSubtaskFilters,
      overdue: overdue ?? this.overdue,
      blocked: blocked ?? this.blocked,
      selectedTimeFilters: selectedTimeFilters ?? this.selectedTimeFilters,
      aiTaskFilter: aiTaskFilter ?? this.aiTaskFilter,
      attachmentFilter: attachmentFilter ?? this.attachmentFilter,
      selectedSmartFilters: selectedSmartFilters ?? this.selectedSmartFilters,
      subtaskSearch: subtaskSearch ?? this.subtaskSearch,
    );
  }

  FilterState reset() => const FilterState();
}
