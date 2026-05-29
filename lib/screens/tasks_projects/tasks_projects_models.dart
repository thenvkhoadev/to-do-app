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
