import 'package:flutter/material.dart';

class SettingsIntegration {
  const SettingsIntegration({
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
    required this.color,
    required this.buttonText,
    required this.connected,
  });

  final String title;
  final String description;
  final String status;
  final IconData icon;
  final Color color;
  final String buttonText;
  final bool connected;
}

class SettingsToggleOption {
  const SettingsToggleOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
}

class SettingsActionOption {
  const SettingsActionOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class SettingsSupportLink {
  const SettingsSupportLink({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;
}
