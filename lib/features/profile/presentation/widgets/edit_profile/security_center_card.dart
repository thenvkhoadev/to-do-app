import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class SecurityCenterCard extends StatelessWidget {
  const SecurityCenterCard({
    required this.onResetPassword,
    required this.onTwoFactorToggled,
    required this.twoFactorEnabled,
    super.key,
  });

  final VoidCallback onResetPassword;
  final ValueChanged<bool> onTwoFactorToggled;
  final bool twoFactorEnabled;

  @override
  Widget build(BuildContext context) {
    return EditProfileGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Security Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.security, color: EditProfileColors.success),
                  SizedBox(width: 12),
                  Text(
                    'Security Center',
                    style: TextStyle(
                      color: EditProfileColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'SECURITY SCORE: ',
                    style: TextStyle(
                      color: EditProfileColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: 0.98,
                            strokeWidth: 3,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: const AlwaysStoppedAnimation(EditProfileColors.success),
                          ),
                        ),
                        const Text(
                          '98',
                          style: TextStyle(
                            color: EditProfileColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2FA Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EditProfileColors.borderSides),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: EditProfileColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phonelink_setup, color: EditProfileColors.success, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Two-Factor Authentication',
                          style: TextStyle(
                            color: EditProfileColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          twoFactorEnabled ? 'Secured via Authenticator App' : 'Add verification layer',
                          style: const TextStyle(
                            color: EditProfileColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: twoFactorEnabled,
                  onChanged: onTwoFactorToggled,
                  activeThumbColor: EditProfileColors.success,
                  activeTrackColor: EditProfileColors.success.withValues(alpha: 0.3),
                  inactiveThumbColor: EditProfileColors.textSecondary,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Password Change Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EditProfileColors.borderSides),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: EditProfileColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.key, color: EditProfileColors.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Password',
                          style: TextStyle(
                            color: EditProfileColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Last updated 14 days ago',
                          style: TextStyle(
                            color: EditProfileColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onResetPassword,
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      color: EditProfileColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
