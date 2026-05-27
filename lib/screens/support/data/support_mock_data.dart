import 'package:flutter/material.dart';
import 'package:to_do_app/screens/support/models/support_models.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class SupportMockData {
  const SupportMockData._();

  static const categories = [
    SupportCategory(
      title: 'Getting Started',
      label: 'Guide',
      description: 'Master the fundamentals of TaskFlow AI in under 5 minutes.',
      icon: Icons.rocket_launch_rounded,
      color: DashboardColors.primary,
      links: ['Installation Guide', 'Creating your first workspace'],
    ),
    SupportCategory(
      title: 'AI Intelligence',
      label: 'Focus',
      description: 'Learn how to leverage AI integrations for peak efficiency.',
      icon: Icons.psychology_rounded,
      color: DashboardColors.secondary,
      links: ['Prompt Engineering 101', 'AI Task Prioritization'],
    ),
    SupportCategory(
      title: 'Deep Work Mode',
      label: 'System',
      description: 'Customize focus timers and notification suppression.',
      icon: Icons.bolt_rounded,
      color: DashboardColors.tertiary,
      links: ['Flow Trigger Settings', 'Focus Analytics'],
    ),
    SupportCategory(
      title: 'Billing & Account',
      label: 'Account',
      description: 'Manage subscriptions and invoices.',
      icon: Icons.payments_rounded,
      color: DashboardColors.onSurfaceVariant,
    ),
    SupportCategory(
      title: 'Integrations',
      label: 'Connect',
      description: 'Slack, Jira, GitHub, and Calendar sync.',
      icon: Icons.extension_rounded,
      color: DashboardColors.primary,
    ),
    SupportCategory(
      title: 'Privacy & Security',
      label: 'Secure',
      description: 'Data encryption policies and permissions.',
      icon: Icons.shield_rounded,
      color: DashboardColors.tertiary,
    ),
  ];

  static const faqs = [
    SupportFAQ(
      question: 'How do I reset my AI focus model?',
      answer: 'Go to Settings > Intelligence > Model Data, then choose Retrain AI. TaskFlow will rebuild your focus model after 2-3 days of active use.',
    ),
    SupportFAQ(
      question: 'Why are Slack notifications not blocked in Focus Mode?',
      answer: 'Check that TaskFlow AI has system-level Focus Control permission and confirm Slack is not whitelisted in your Focus exceptions.',
    ),
    SupportFAQ(
      question: 'Can I export Intelligence reports to PDF?',
      answer: 'Yes. Open the Intelligence tab, choose Export, then select PDF, CSV, or Markdown format.',
    ),
    SupportFAQ(
      question: 'Can I sync tasks across multiple workspaces?',
      answer: 'Workspace sync is available on Pro plans. Connect each workspace from Integrations, then enable cross-workspace task mirroring.',
    ),
    SupportFAQ(
      question: 'What happens to data when I am offline?',
      answer: 'TaskFlow keeps recent tasks and schedules locally, then syncs changes when your connection returns.',
    ),
  ];

  static const ticketCategories = [
    'Technical Problem',
    'Billing Inquiry',
    'Feature Request',
    'Security Concern',
  ];
}
