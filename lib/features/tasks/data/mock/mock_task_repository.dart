import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';

class MockTaskRepository {
  const MockTaskRepository();

  List<TaskColumnData> board() {
    final tasks = allTasks();
    return [
      TaskColumnData(title: 'To Do', status: TaskBoardStatus.todo, tasks: tasks.where((task) => task.status == TaskBoardStatus.todo).toList()),
      TaskColumnData(title: 'In Progress', status: TaskBoardStatus.inProgress, tasks: tasks.where((task) => task.status == TaskBoardStatus.inProgress).toList()),
      TaskColumnData(title: 'Completed', status: TaskBoardStatus.completed, tasks: tasks.where((task) => task.status == TaskBoardStatus.completed).toList()),
    ];
  }

  List<TaskBoardItem> today() => allTasks().where((task) => task.status != TaskBoardStatus.completed).toList();

  List<TaskBoardItem> upcoming() => const [
    TaskBoardItem(
      id: 'upcoming-finance',
      title: 'Monthly financial sync',
      description: 'Align budget deltas and forecast updates with finance leadership.',
      status: TaskBoardStatus.todo,
      priority: TaskBoardPriority.low,
      estimate: 'Thu 11:00 AM',
      assignee: 'KV',
      progress: .15,
      tags: ['finance', 'ops'],
      dueLabel: 'OCT 24',
    ),
    TaskBoardItem(
      id: 'upcoming-prototype',
      title: 'Prototype sign-off with stakeholders',
      description: 'Resolve final mobile prototype notes before engineering handoff.',
      status: TaskBoardStatus.todo,
      priority: TaskBoardPriority.medium,
      estimate: 'Fri 15:30 PM',
      assignee: 'AR',
      progress: .48,
      tags: ['design', 'handoff'],
      dueLabel: 'OCT 25',
    ),
  ];

  List<TaskBoardItem> allTasks() => const [
    TaskBoardItem(
      id: 'architecture-review',
      title: 'Cloud Architecture Review',
      description: 'Review scalability of the new vector database integration with AWS Lambda.',
      status: TaskBoardStatus.todo,
      priority: TaskBoardPriority.high,
      estimate: '4h',
      assignee: 'AR',
      progress: .25,
      tags: ['architecture', 'aws'],
      aiSuggestion: 'AI recommends reviewing cold-start latency before approving this integration.',
      dueLabel: '09:00 - 11:30',
    ),
    TaskBoardItem(
      id: 'user-interview',
      title: 'User Interview - V3',
      description: 'Synthesize findings from the latest round of power user feedback.',
      status: TaskBoardStatus.todo,
      priority: TaskBoardPriority.medium,
      estimate: '1.5h',
      assignee: 'JD',
      progress: .35,
      tags: ['research', 'product'],
      dueLabel: '14:00',
    ),
    TaskBoardItem(
      id: 'glass-ui',
      title: 'Refine Glassmorphism UI Components',
      description: 'Adjust background blurs and border opacities for better readability across core navigation surfaces.',
      status: TaskBoardStatus.inProgress,
      priority: TaskBoardPriority.high,
      estimate: 'In Focus',
      assignee: 'AI',
      progress: .65,
      tags: ['ui', 'accessibility'],
      aiSuggestion: 'AI suggestion: Check WCAG contrast before shipping translucent cards.',
      dueLabel: 'Deep Work',
    ),
    TaskBoardItem(
      id: 'weekly-sync',
      title: 'Weekly Sync Prep',
      description: 'Gather key metrics for the Friday engineering leadership sync.',
      status: TaskBoardStatus.inProgress,
      priority: TaskBoardPriority.low,
      estimate: '.5h',
      assignee: 'KV',
      progress: .42,
      tags: ['meetings'],
    ),
    TaskBoardItem(
      id: 'roadmap',
      title: 'Q3 Roadmap Presentation',
      description: 'Finalize strategic roadmap narrative and executive summary.',
      status: TaskBoardStatus.completed,
      priority: TaskBoardPriority.done,
      estimate: 'Done',
      assignee: 'KV',
      progress: 1,
      tags: ['planning', 'strategy'],
      completed: true,
    ),
    TaskBoardItem(
      id: 'webhooks',
      title: 'API Documentation - Webhooks',
      description: 'Publish updated webhook lifecycle reference for partners.',
      status: TaskBoardStatus.completed,
      priority: TaskBoardPriority.done,
      estimate: 'Done',
      assignee: 'JD',
      progress: 1,
      tags: ['docs', 'api'],
      completed: true,
    ),
  ];
}
