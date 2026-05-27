import 'package:flutter/material.dart';
import 'package:to_do_app/screens/settings/models/settings_models.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class SettingsMockData {
  const SettingsMockData._();

  static const integrations = [
    SettingsIntegration(
      title: 'Slack',
      description: 'Sync team notifications',
      status: 'Connected',
      icon: Icons.forum_rounded,
      color: Color(0xFFDDB7FF),
      buttonText: 'Manage',
      connected: true,
    ),
    SettingsIntegration(
      title: 'Google Calendar',
      description: 'Manage AI schedule',
      status: 'Connected',
      icon: Icons.calendar_today_rounded,
      color: Color(0xFFADC6FF),
      buttonText: 'Configure',
      connected: true,
    ),
    SettingsIntegration(
      title: 'Notion',
      description: 'Knowledge base sync',
      status: 'Not Connected',
      icon: Icons.article_rounded,
      color: Color(0xFFDDE2F8),
      buttonText: 'Connect',
      connected: false,
    ),
  ];

  static const notifications = [
    SettingsToggleOption(
      title: 'AI Suggestion Alerts',
      subtitle: 'Notify when AI finds a slot for deep work.',
      icon: Icons.auto_awesome_rounded,
      enabled: true,
    ),
    SettingsToggleOption(
      title: 'Push Notifications',
      subtitle: 'Receive alerts on your mobile device.',
      icon: Icons.notifications_active_rounded,
      enabled: false,
    ),
    SettingsToggleOption(
      title: 'Smart Reminders',
      subtitle: 'Surface reminders when context is strongest.',
      icon: Icons.schedule_rounded,
      enabled: true,
    ),
    SettingsToggleOption(
      title: 'Productivity Alerts',
      subtitle: 'Warn when focus quality drops below target.',
      icon: Icons.trending_up_rounded,
      enabled: true,
    ),
  ];

  static const security = [
    SettingsActionOption(
      title: 'Change Password',
      subtitle: 'Last changed 3 months ago',
      icon: Icons.password_rounded,
      color: DashboardColors.onSurfaceVariant,
    ),
    SettingsActionOption(
      title: 'Two-Factor Authentication',
      subtitle: 'Enabled',
      icon: Icons.phonelink_lock_rounded,
      color: DashboardColors.primary,
    ),
    SettingsActionOption(
      title: 'Device Management',
      subtitle: '3 trusted devices',
      icon: Icons.devices_rounded,
      color: DashboardColors.secondary,
    ),
  ];

  static const support = [
    SettingsSupportLink(title: 'Documentation', icon: Icons.help_rounded),
    SettingsSupportLink(title: 'Community', icon: Icons.forum_rounded),
    SettingsSupportLink(title: 'Report Bug', icon: Icons.bug_report_rounded),
  ];
}
