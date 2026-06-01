import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

enum TasksProjectCardKind { priority, ai, review, urgent, research, add }

class TasksProjectItem {
  const TasksProjectItem({
    required this.kind,
    required this.badge,
    required this.title,
    required this.description,
    required this.accent,
    this.metaLeft,
    this.metaRight,
    this.progress,
  });

  final TasksProjectCardKind kind;
  final String badge;
  final String title;
  final String description;
  final Color accent;
  final String? metaLeft;
  final String? metaRight;
  final double? progress;
}

class TasksProjectInsight {
  const TasksProjectInsight({
    required this.label,
    required this.title,
    required this.message,
    required this.confidence,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String title;
  final String message;
  final String confidence;
  final IconData icon;
  final Color accent;
}

class TasksProjectStat {
  const TasksProjectStat({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color accent;
}

class TasksProjectActivity {
  const TasksProjectActivity({
    required this.title,
    required this.detail,
    required this.time,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String detail;
  final String time;
  final IconData icon;
  final Color accent;
}

class TasksProjectQuickAction {
  const TasksProjectQuickAction({
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final Color accent;
}

class TasksProjectCommand {
  const TasksProjectCommand({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.shortcut,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String shortcut;
}

const tasksProjectItems = [
  TasksProjectItem(
    kind: TasksProjectCardKind.priority,
    badge: 'PRIORITY HIGH',
    title: 'Finalize Neural Engine Specs',
    description:
        'Review technical documentation for the inference layer of the AI Core 2.0. Ensure latency benchmarks meet the Q3 targets.',
    accent: DashboardColors.primary,
    metaRight: 'Today, 5:00 PM',
  ),
  TasksProjectItem(
    kind: TasksProjectCardKind.ai,
    badge: 'AI SUGGESTED',
    title: 'Batch Process Image Assets',
    description:
        'AI has identified 42 unsorted assets in the Quantum project. Automation script is ready to run.',
    accent: DashboardColors.tertiary,
    metaLeft: '82% Confidence',
    metaRight: '42 files',
  ),
  TasksProjectItem(
    kind: TasksProjectCardKind.review,
    badge: 'PENDING REVIEW',
    title: 'Quarterly Security Audit',
    description:
        'Validate access logs for the internal cloud cluster and rotate SSH keys for the production environment.',
    accent: DashboardColors.outline,
    progress: .66,
  ),
  TasksProjectItem(
    kind: TasksProjectCardKind.urgent,
    badge: 'URGENT',
    title: 'Executive Briefing Prep',
    description:
        'Drafting the key talking points for the upcoming Board of Directors meeting regarding the AI roadmap.',
    accent: DashboardColors.secondary,
    metaRight: 'In 2 hours',
  ),
  TasksProjectItem(
    kind: TasksProjectCardKind.research,
    badge: 'RESEARCH',
    title: 'Latency Analysis',
    description:
        'Deep dive into the edge computing latency reports from last month\'s beta launch in North America.',
    accent: DashboardColors.tertiary,
    metaLeft: 'No deadline set',
  ),
  TasksProjectItem(
    kind: TasksProjectCardKind.add,
    badge: '',
    title: 'Create New Sub-Project',
    description: '',
    accent: DashboardColors.primary,
  ),
];

const tasksProjectInsight = TasksProjectInsight(
  label: 'AI PRIORITY SIGNAL',
  title: 'You completed 82% more deep work this week',
  message:
      'AI found a dependency cluster around Neural Engine Specs. Clear documentation review first to unblock 3 downstream tasks.',
  confidence: '92% confidence',
  icon: Icons.auto_awesome_rounded,
  accent: DashboardColors.primary,
);

const tasksProjectStats = [
  TasksProjectStat(
    label: 'Tasks Completed',
    value: '128',
    delta: '+18%',
    icon: Icons.task_alt_rounded,
    accent: DashboardColors.primary,
  ),
  TasksProjectStat(
    label: 'Deep Work Hours',
    value: '42.5h',
    delta: '+6.4h',
    icon: Icons.bolt_rounded,
    accent: DashboardColors.secondary,
  ),
  TasksProjectStat(
    label: 'AI Assisted Tasks',
    value: '36',
    delta: '+24%',
    icon: Icons.psychology_rounded,
    accent: DashboardColors.tertiary,
  ),
  TasksProjectStat(
    label: 'Active Projects',
    value: '12',
    delta: '4 critical',
    icon: Icons.account_tree_rounded,
    accent: DashboardColors.tertiaryContainer,
  ),
];

const tasksProjectActivities = [
  TasksProjectActivity(
    title: 'AI reprioritized Neural Engine Specs',
    detail: 'Moved to top because it unlocks three dependent tasks.',
    time: '4 min ago',
    icon: Icons.auto_fix_high_rounded,
    accent: DashboardColors.primary,
  ),
  TasksProjectActivity(
    title: 'Security Audit moved to review',
    detail: '66% progress reached after key rotation checklist completed.',
    time: '28 min ago',
    icon: Icons.verified_rounded,
    accent: DashboardColors.secondary,
  ),
  TasksProjectActivity(
    title: '42 assets queued for automation',
    detail: 'AI batch process is ready for Quantum image assets.',
    time: '1h ago',
    icon: Icons.inventory_2_rounded,
    accent: DashboardColors.tertiary,
  ),
];

const tasksProjectQuickActions = [
  TasksProjectQuickAction(
    label: 'New Task',
    icon: Icons.add_rounded,
    accent: DashboardColors.primary,
  ),
  TasksProjectQuickAction(
    label: 'AI Generate',
    icon: Icons.auto_awesome_rounded,
    accent: DashboardColors.secondary,
  ),
  TasksProjectQuickAction(
    label: 'Focus Mode',
    icon: Icons.center_focus_strong_rounded,
    accent: DashboardColors.tertiary,
  ),
  TasksProjectQuickAction(
    label: 'Upload',
    icon: Icons.cloud_upload_rounded,
    accent: DashboardColors.outline,
  ),
  TasksProjectQuickAction(
    label: 'Analytics',
    icon: Icons.query_stats_rounded,
    accent: DashboardColors.tertiaryContainer,
  ),
];

const tasksProjectCommands = [
  TasksProjectCommand(
    title: 'Create task',
    subtitle: 'Add a project task with AI context',
    icon: Icons.add_task_rounded,
    shortcut: 'N',
  ),
  TasksProjectCommand(
    title: 'Ask AI to summarize blockers',
    subtitle: 'Generate a concise dependency report',
    icon: Icons.psychology_rounded,
    shortcut: 'A',
  ),
  TasksProjectCommand(
    title: 'Show at-risk projects',
    subtitle: 'Filter urgent and delayed project work',
    icon: Icons.warning_amber_rounded,
    shortcut: 'R',
  ),
  TasksProjectCommand(
    title: 'Open productivity heatmap',
    subtitle: 'Review focus intensity across the week',
    icon: Icons.grid_view_rounded,
    shortcut: 'H',
  ),
  TasksProjectCommand(
    title: 'Filter high priority',
    subtitle: 'Show critical and urgent tasks only',
    icon: Icons.filter_alt_rounded,
    shortcut: 'F',
  ),
];

const tasksProjectHeatmapValues = [
  .18,
  .42,
  .22,
  .78,
  .35,
  .62,
  .20,
  .28,
  .12,
  .48,
  .52,
  .31,
  .74,
  .44,
  .82,
  .68,
  .92,
  .56,
  .47,
  .88,
  .71,
  .34,
  .25,
  .58,
  .81,
  .63,
  .95,
  .52,
];
