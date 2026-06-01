import 'package:flutter/material.dart';
import 'package:to_do_app/screens/analytics/models/analytics_models.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AnalyticsMockData {
  const AnalyticsMockData._();

  static const metrics = [
    AnalyticsMetric(
      label: 'Focus Sessions',
      value: '12',
      delta: '+20% vs last week',
      icon: Icons.timer_rounded,
      color: DashboardColors.primary,
    ),
    AnalyticsMetric(
      label: 'Deep Work Hours',
      value: '34.5h',
      delta: '+4.2h growth',
      icon: Icons.bolt_rounded,
      color: DashboardColors.secondary,
    ),
    AnalyticsMetric(
      label: 'Efficiency Score',
      value: '92%',
      delta: 'Top 5%',
      icon: Icons.insights_rounded,
      color: DashboardColors.tertiary,
    ),
    AnalyticsMetric(
      label: 'AI Pulse',
      value: 'Peak',
      delta: 'Expected @ 2PM',
      icon: Icons.auto_awesome_rounded,
      color: DashboardColors.primaryContainer,
    ),
  ];

  static const focusTrend = [
    AnalyticsPoint('Mon', .44),
    AnalyticsPoint('Tue', .62),
    AnalyticsPoint('Wed', .78),
    AnalyticsPoint('Thu', .58),
    AnalyticsPoint('Fri', .91),
    AnalyticsPoint('Sat', .74),
    AnalyticsPoint('Sun', .52),
  ];

  static const energyCycle = [
    AnalyticsPoint('08:00', .40),
    AnalyticsPoint('09:00', .65),
    AnalyticsPoint('10:00', .86),
    AnalyticsPoint('11:00', .72),
    AnalyticsPoint('12:00', .48),
    AnalyticsPoint('14:00', .60),
    AnalyticsPoint('15:00', .95),
    AnalyticsPoint('16:00', .80),
    AnalyticsPoint('17:00', .55),
    AnalyticsPoint('18:00', .32),
  ];

  static const categories = [
    AnalyticsCategory(
      label: 'Deep Work',
      value: .65,
      color: DashboardColors.primary,
      detail: '4h 12m peak',
    ),
    AnalyticsCategory(
      label: 'Collaboration',
      value: .25,
      color: DashboardColors.secondary,
      detail: '7 sync blocks',
    ),
    AnalyticsCategory(
      label: 'Admin',
      value: .10,
      color: DashboardColors.onSurfaceVariant,
      detail: 'Low friction',
    ),
  ];

  static const velocity = [
    AnalyticsCategory(
      label: 'Design Systems',
      value: .85,
      color: DashboardColors.primary,
      detail: '24 Units/hr',
    ),
    AnalyticsCategory(
      label: 'Core Engineering',
      value: .65,
      color: DashboardColors.secondary,
      detail: '18 Units/hr',
    ),
    AnalyticsCategory(
      label: 'Content Strategy',
      value: .45,
      color: DashboardColors.tertiary,
      detail: '12 Units/hr',
    ),
    AnalyticsCategory(
      label: 'Client Reviews',
      value: .30,
      color: DashboardColors.outlineVariant,
      detail: '9 Units/hr',
    ),
  ];

  static const insights = [
    AnalyticsInsight(
      title: 'Optimize Morning Sprint',
      description:
          'Peak cognitive load appears between 9 AM and 11 AM. Move architecture review into this window.',
      icon: Icons.auto_awesome_rounded,
      color: DashboardColors.primary,
      actionLabel: 'Apply',
    ),
    AnalyticsInsight(
      title: 'Scheduled Recovery',
      description:
          'Mental fatigue likely around 3 PM. A 15-minute reset improves afternoon endurance by 22%.',
      icon: Icons.energy_savings_leaf_rounded,
      color: DashboardColors.secondary,
      actionLabel: 'Plan',
    ),
    AnalyticsInsight(
      title: 'Project Switch',
      description:
          'Velocity is dropping on Design Docs. Switch to Code Audit tasks for one focus block.',
      icon: Icons.batch_prediction_rounded,
      color: DashboardColors.tertiary,
      actionLabel: 'Review',
    ),
  ];

  static const activities = [
    AnalyticsActivity(
      title: 'Completed deep work block',
      time: '10:42 AM',
      icon: Icons.check_rounded,
      color: DashboardColors.primary,
    ),
    AnalyticsActivity(
      title: 'AI detected peak focus state',
      time: '10:05 AM',
      icon: Icons.psychology_rounded,
      color: DashboardColors.secondary,
    ),
    AnalyticsActivity(
      title: 'Category balance updated',
      time: 'Yesterday',
      icon: Icons.category_rounded,
      color: DashboardColors.tertiary,
    ),
  ];
}
