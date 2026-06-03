import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class AccountSettingsCard extends StatelessWidget {
  const AccountSettingsCard({
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.notificationsEnabled,
    required this.onNotificationsEnabledChanged,
    required this.privacyMode,
    required this.onPrivacyModeChanged,
    required this.aiCopilotEnabled,
    required this.onAiCopilotEnabledChanged,
    super.key,
  });

  final String themeMode;
  final ValueChanged<String> onThemeModeChanged;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsEnabledChanged;
  final bool privacyMode;
  final ValueChanged<bool> onPrivacyModeChanged;
  final bool aiCopilotEnabled;
  final ValueChanged<bool> onAiCopilotEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode.toLowerCase() == 'dark';

    return EditProfileGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_applications_outlined, color: EditProfileColors.primary),
              SizedBox(width: 12),
              Text(
                'System Preferences',
                style: TextStyle(
                  color: EditProfileColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Theme Mode Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interface Theme',
                    style: TextStyle(
                      color: EditProfileColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Select your visual work environment',
                    style: TextStyle(
                      color: EditProfileColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: EditProfileColors.borderSides),
                ),
                child: Row(
                  children: [
                    _buildThemeButton(
                      icon: Icons.dark_mode,
                      isActive: isDark,
                      onTap: () => onThemeModeChanged('dark'),
                    ),
                    _buildThemeButton(
                      icon: Icons.light_mode,
                      isActive: !isDark,
                      onTap: () => onThemeModeChanged('light'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: EditProfileColors.borderSides, height: 1),
          const SizedBox(height: 20),

          // Notifications Switch Row
          _buildSwitchRow(
            title: 'Deep Focus Mode',
            subtitle: 'Suppress all notifications during flow state',
            value: notificationsEnabled,
            onChanged: onNotificationsEnabledChanged,
          ),
          const SizedBox(height: 20),
          const Divider(color: EditProfileColors.borderSides, height: 1),
          const SizedBox(height: 20),

          // AI Task Co-Pilot Switch Row
          _buildSwitchRow(
            title: 'AI Task Co-Pilot',
            subtitle: 'Enable autonomous task prioritization',
            value: aiCopilotEnabled,
            onChanged: onAiCopilotEnabledChanged,
          ),
          const SizedBox(height: 20),
          const Divider(color: EditProfileColors.borderSides, height: 1),
          const SizedBox(height: 20),

          // Privacy Mode Switch Row
          _buildSwitchRow(
            title: 'Privacy Mode',
            subtitle: 'Hide focus statistics from the network feed',
            value: privacyMode,
            onChanged: onPrivacyModeChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? EditProfileColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.white : EditProfileColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: EditProfileColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: EditProfileColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: EditProfileColors.primary,
          activeTrackColor: EditProfileColors.primary.withValues(alpha: 0.3),
          inactiveThumbColor: EditProfileColors.textSecondary,
          inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
        ),
      ],
    );
  }
}
