import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/agenda_panel.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/calendar_month_view.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/day_view.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/desktop_layout.dart';
import 'package:to_do_app/features/calendar/presentation/widgets/mobile_layout.dart'
    as mobile;
import 'package:to_do_app/features/calendar/presentation/widgets/week_view.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_detail_panel.dart';
import 'package:to_do_app/widgets/dashboard/mobile_dashboard_widgets.dart';
import 'package:to_do_app/core/utils/description_utils.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';

enum CalendarView { month, week, day }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({this.onViewDetails, this.onCreateTask, super.key});
  final ValueChanged<TaskBoardItem>? onViewDetails;
  final VoidCallback? onCreateTask;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarView _view = CalendarView.month;
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate = DateTime.now();
  bool _agendaVisible = false;
  TaskBoardItem? _selectedTask;

  void _selectTask(TaskBoardItem? task) {
    setState(() {
      _selectedTask = task;
    });
  }

  TaskBoardItem _toTaskBoardItem(NexusTask t) {
    TaskBoardStatus status;
    switch ((t.status).toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        status = TaskBoardStatus.inProgress;
        break;
      case 'completed':
      case 'done':
        status = TaskBoardStatus.completed;
        break;
      case 'draft':
        status = TaskBoardStatus.draft;
        break;
      default:
        status = TaskBoardStatus.todo;
    }

    TaskBoardPriority priority;
    switch ((t.priority).toLowerCase()) {
      case 'urgent':
        priority = TaskBoardPriority.urgent;
        break;
      case 'high':
        priority = TaskBoardPriority.high;
        break;
      case 'low':
        priority = TaskBoardPriority.low;
        break;
      default:
        priority = TaskBoardPriority.medium;
    }

    final estMin = t.estimatedMinutes;
    final estimate = estMin != null
        ? estMin >= 60
            ? '${estMin ~/ 60}h${estMin % 60 > 0 ? ' ${estMin % 60}m' : ''}'
            : '${estMin}m'
        : '–';

    final allUsers = ref.read(allUsersProvider).valueOrNull ?? [];
    String resolvedAssigneeName = 'Unassigned';
    if (t.assigneeIds.isNotEmpty) {
      final assigneeId = t.assigneeIds.first;
      final user = allUsers.firstWhere(
        (u) => u.id == assigneeId,
        orElse: () => UserProfileModel(id: '', email: ''),
      );
      if (user.fullName != null && user.fullName!.trim().isNotEmpty) {
        resolvedAssigneeName = user.fullName!;
      } else if (user.username != null && user.username!.isNotEmpty) {
        resolvedAssigneeName = user.username!;
      } else if (user.email.isNotEmpty) {
        resolvedAssigneeName = user.email;
      }
    }
    
    String? resolvedCreatorName;
    final creatorUser = allUsers.firstWhere(
      (u) => u.id == t.userId,
      orElse: () => UserProfileModel(id: '', email: ''),
    );
    if (creatorUser.fullName != null && creatorUser.fullName!.trim().isNotEmpty) {
      resolvedCreatorName = creatorUser.fullName;
    } else if (creatorUser.username != null && creatorUser.username!.isNotEmpty) {
      resolvedCreatorName = creatorUser.username;
    } else if (creatorUser.email.isNotEmpty) {
      resolvedCreatorName = creatorUser.email;
    }

    return TaskBoardItem(
      id: t.id,
      title: t.title,
      description: t.description ?? '',
      status: status,
      priority: priority,
      estimate: estimate,
      assignee: resolvedAssigneeName,
      progress: t.status == 'done' ? 1.0 : (t.status == 'in_progress' ? 0.5 : 0.0),
      tags: const [],
      dueDate: t.dueDate,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
      userId: t.userId,
      creatorName: resolvedCreatorName,
      xpAwarded: t.xpAwarded,
    );
  }

  void _onTaskTapped(String taskId, List<NexusTask> allTasks, bool isDesktop) {
    if (taskId.isEmpty) return;
    final matching = allTasks.where((t) => t.id == taskId);
    if (matching.isEmpty) return;
    
    final nexusTask = matching.first;
    if (isDesktop) {
      _selectTask(_toTaskBoardItem(nexusTask));
    } else {
      context.push('/task-detail/$taskId');
    }
  }

  void _setView(CalendarView view) {
    setState(() {
      _view = view;
      if (view == CalendarView.day) {
        _agendaVisible = false;
        _selectedDate ??= _focusedDate;
      }
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _focusedDate = date;
      if (_view != CalendarView.day) {
        _agendaVisible = true;
      }
    });
  }

  void _goToToday() {
    _selectDate(DateTime.now());
  }

  void _handleCreateTask() {
    if (widget.onCreateTask != null) {
      widget.onCreateTask!();
    } else {
      context.go('/tasks?newTask=1');
    }
  }

  void _goToPrevious() {
    _moveDate(-1);
  }

  void _goToNext() {
    _moveDate(1);
  }

  void _moveDate(int direction) {
    final nextDate = _shiftDate(_focusedDate, direction);
    setState(() {
      _focusedDate = nextDate;
      if (_view == CalendarView.day) {
        _selectedDate = nextDate;
      } else {
        _selectedDate = null;
      }
    });
  }

  DateTime _shiftDate(DateTime date, int direction) {
    return switch (_view) {
      CalendarView.month => DateTime(
        date.year,
        date.month + direction,
        date.day,
      ),
      CalendarView.week => date.add(Duration(days: 7 * direction)),
      CalendarView.day => date.add(Duration(days: direction)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userTasksProvider);
    final allTasks = tasksAsync.valueOrNull ?? const <NexusTask>[];
    final effectiveDate = _selectedDate ?? _focusedDate;
    final selectedTasks = _selectedTasksFor(allTasks, effectiveDate);
    final selectedDayEvents = _dayEventsFor(selectedTasks);
    final selectedAgendaEvents = _agendaEventsFor(selectedTasks);
    final monthTaskEvents = _monthTaskEvents(allTasks);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          final isPanelOpen = _selectedTask != null;
          final panelWidth = constraints.maxWidth >= 1600
              ? 520.0
              : (constraints.maxWidth >= 1200 ? 480.0 : 420.0);
          return Stack(
            children: [
              Positioned.fill(
                child: CalendarDesktopLayout(
                  title: _title,
                  selectedView: _desktopView,
                  onViewChanged: (view) => _setView(CalendarView.values[view.index]),
                  onToday: _goToToday,
                  onPrevious: _goToPrevious,
                  onNext: _goToNext,
                  calendar: _calendarContent(
                    selectedDayEvents,
                    selectedAgendaEvents,
                    tasksAsync,
                    monthTaskEvents,
                    allTasks,
                    true,
                  ),
                  agendaVisible: _view == CalendarView.day ? false : _agendaVisible,
                  onToggleAgenda: _view == CalendarView.day
                      ? null
                      : () => setState(() => _agendaVisible = !_agendaVisible),
                  agenda: AgendaPanel(
                    date: effectiveDate,
                    events: selectedAgendaEvents,
                    isLoading: tasksAsync.isLoading,
                    errorMessage:
                        tasksAsync.hasError
                            ? 'Unable to load tasks for this day.'
                            : null,
                    onHideAgenda:
                        () => setState(() => _agendaVisible = false),
                    onCreateTask: _handleCreateTask,
                    onEventTap: (event) => _onTaskTapped(event.taskId ?? '', allTasks, true),
                  ),
                ),
              ),
              if (isPanelOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => _selectTask(null),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, value, child) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 5.0 * value,
                            sigmaY: 5.0 * value,
                          ),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.35 * value),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                top: 0,
                bottom: 0,
                right: isPanelOpen ? 0 : -panelWidth,
                width: panelWidth,
                child: _selectedTask != null
                    ? TaskDetailPanel(
                        task: _selectedTask!,
                        onClose: () => _selectTask(null),
                        onViewDetails: () {
                          final task = _selectedTask!;
                          _selectTask(null);
                          if (widget.onViewDetails != null) {
                            widget.onViewDetails!(task);
                          } else {
                            context.push('/task-detail/${task.id}');
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }

        return mobile.CalendarMobileLayout(
          title: _title,
          weekSelector: WeekView(
            selectedDate: _selectedDate,
            focusedDate: _focusedDate,
            onDateSelected: _selectDate,
            onPreviousWeek: _goToPrevious,
            onNextWeek: _goToNext,
            taskEvents: monthTaskEvents,
            dayEvents: _dayEventsFor(allTasks),
            onEventTap: (event) => _onTaskTapped(event.taskId ?? '', allTasks, false),
          ),
          timelineAgenda: AgendaPanel(
            date: effectiveDate,
            events: selectedAgendaEvents,
            isLoading: tasksAsync.isLoading,
            errorMessage:
                tasksAsync.hasError
                    ? 'Unable to load tasks for this day.'
                    : null,
            onCreateTask: _handleCreateTask,
            onEventTap: (event) => _onTaskTapped(event.taskId ?? '', allTasks, false),
            physics: const NeverScrollableScrollPhysics(),
          ),
          bottomNavigation: MobileBottomNavBar(
            bottomInset: MediaQuery.paddingOf(context).bottom,
          ),
          actions: [
            IconButton(
              onPressed: () =>
                  _openMobileAgenda(selectedAgendaEvents, tasksAsync, allTasks),
              icon: const Icon(Icons.view_agenda_rounded),
            ),
          ],
          onAdd: () {},
        );
      },
    );
  }

  void _openMobileAgenda(
    List<AgendaPanelEvent> events,
    AsyncValue<List<NexusTask>> tasksAsync,
    List<NexusTask> allTasks,
  ) {
    final date = _selectedDate ?? _focusedDate;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: .78,
          minChildSize: .42,
          maxChildSize: .92,
          builder: (context, controller) {
            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: .10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .32),
                    blurRadius: 36,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: AgendaPanel(
                date: date,
                events: events,
                isLoading: tasksAsync.isLoading,
                errorMessage:
                    tasksAsync.hasError
                        ? 'Unable to load tasks for this day.'
                        : null,
                onCreateTask: _handleCreateTask,
                onEventTap: (event) => _onTaskTapped(event.taskId ?? '', allTasks, false),
              ),
            );
          },
        );
      },
    );
  }

  Widget _calendarContent(
    List<DayCalendarEvent> selectedDayEvents,
    List<AgendaPanelEvent> selectedAgendaEvents,
    AsyncValue<List<NexusTask>> tasksAsync,
    Map<String, List<CalendarMonthEvent>> taskEvents,
    List<NexusTask> allTasks,
    bool isDesktop,
  ) {
    final effectiveDate = _selectedDate ?? _focusedDate;
    return switch (_view) {
      CalendarView.month => CalendarMonthView(
        focusedDate: _focusedDate,
        selectedDate: _selectedDate,
        onDateSelected: _selectDate,
        taskEvents: taskEvents,
      ),
      CalendarView.week => WeekView(
        selectedDate: _selectedDate,
        focusedDate: _focusedDate,
        onDateSelected: _selectDate,
        onPreviousWeek: _goToPrevious,
        onNextWeek: _goToNext,
        taskEvents: taskEvents,
        dayEvents: _dayEventsFor(allTasks),
        onEventTap: (event) => _onTaskTapped(event.taskId ?? '', allTasks, isDesktop),
      ),
      CalendarView.day => DayView(
          date: effectiveDate,
          events: selectedDayEvents,
          onEventTap: (event) => _onTaskTapped(event.taskId ?? '', allTasks, isDesktop),
        ),
    };
  }

  List<NexusTask> _selectedTasksFor(List<NexusTask> tasks, DateTime targetDate) {
    return tasks
        .where(
          (task) =>
              task.dueDate != null && _sameDay(task.dueDate!, targetDate),
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  List<DayCalendarEvent> _dayEventsFor(List<NexusTask> tasks) {
    return tasks.where((t) => t.dueDate != null).map((task) {
      final due = task.dueDate!;
      final idx = tasks.indexOf(task);
      final start = (due.hour == 0 && due.minute == 0)
          ? DateTime(due.year, due.month, due.day, 8 + idx % 10, 0)
          : due;
      final durationMinutes = (task.estimatedMinutes != null && task.estimatedMinutes! > 0)
          ? task.estimatedMinutes!
          : 60;
      final end = start.add(Duration(minutes: durationMinutes));
      final parsedDesc = parseDescriptionToPlainText(task.description);
      return DayCalendarEvent(
        start: start,
        end: end,
        title: task.title,
        taskId: task.id,
        subtitle: parsedDesc.isEmpty ? task.categoryId : parsedDesc,
        color: _taskColor(task),
        category: task.categoryId,
        participants: const [],
      );
    }).toList();
  }

  List<AgendaPanelEvent> _agendaEventsFor(List<NexusTask> tasks) {
    return tasks.map((task) {
      final parsedDesc = parseDescriptionToPlainText(task.description);
      return AgendaPanelEvent(
        start: task.dueDate!,
        title: task.title,
        taskId: task.id,
        subtitle: parsedDesc.isEmpty ? task.categoryId : parsedDesc,
        color: _taskColor(task),
        durationMinutes: 45,
        status: task.status,
        priority: task.priority,
        type: _agendaType(task),
      );
    }).toList();
  }

  Map<String, List<CalendarMonthEvent>> _monthTaskEvents(List<NexusTask> tasks) {
    final map = <String, List<CalendarMonthEvent>>{};
    for (final task in tasks) {
      if (task.dueDate == null) continue;
      final d = task.dueDate!;
      final key = '${d.year}-${d.month}-${d.day}';
      map.putIfAbsent(key, () => []).add(
        CalendarMonthEvent(
          color: _taskColor(task),
          title: task.title,
          taskId: task.id,
        ),
      );
    }
    return map;
  }

  Color _taskColor(NexusTask task) {
    const palette = [
      Color(0xFF7C3AED), // violet
      Color(0xFFF97316), // orange
      Color(0xFF06B6D4), // cyan
      Color(0xFF22C55E), // green
      Color(0xFFEC4899), // pink
      Color(0xFF8B5CF6), // purple
      Color(0xFFEAB308), // yellow
      Color(0xFFEF4444), // red
      Color(0xFF14B8A6), // teal
      Color(0xFF3B82F6), // blue
      Color(0xFFF59E0B), // amber
      Color(0xFF84CC16), // lime
    ];
    final index = task.id.hashCode.abs() % palette.length;
    return palette[index];
  }

  String _agendaType(NexusTask task) {
    final category = (task.categoryId ?? '').toLowerCase();
    if (category.contains('meeting')) return 'Meeting';
    if (category.contains('reminder')) return 'Reminder';
    return 'Task';
  }

  CalendarDesktopView get _desktopView {
    return CalendarDesktopView.values[_view.index];
  }

  String get _title {
    final date =
        '${_focusedDate.day}/${_focusedDate.month}/${_focusedDate.year}';
    return switch (_view) {
      CalendarView.month => '${_focusedDate.month}/${_focusedDate.year}',
      CalendarView.week => 'Week of $date',
      CalendarView.day => date,
    };
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
