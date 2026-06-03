import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class DangerZoneCard extends StatelessWidget {
  const DangerZoneCard({
    required this.onDeleteAccount,
    required this.onWipeData,
    super.key,
  });

  final VoidCallback onDeleteAccount;
  final VoidCallback onWipeData;

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EditProfileColors.cardBg,
        title: Text(title, style: const TextStyle(color: EditProfileColors.error, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: EditProfileColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: EditProfileColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Confirm', style: TextStyle(color: EditProfileColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EditProfileGlassCard(
      borderColor: EditProfileColors.error.withValues(alpha: 0.2),
      backgroundColor: EditProfileColors.error.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Danger Zone',
            style: TextStyle(
              color: EditProfileColors.error,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Irreversible actions on your node.',
            style: TextStyle(
              color: EditProfileColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildDangerRow(
                context,
                label: 'Delete Account Profile',
                onTap: () => _showConfirmDialog(
                  context,
                  title: 'Delete Account',
                  content: 'Are you sure you want to permanently delete your account? This action cannot be undone.',
                  onConfirm: onDeleteAccount,
                ),
              ),
              const Divider(color: EditProfileColors.borderSides, height: 1),
              _buildDangerRow(
                context,
                label: 'Wipe All Productivity Data',
                onTap: () => _showConfirmDialog(
                  context,
                  title: 'Wipe Data',
                  content: 'Are you sure you want to erase all focus sessions, task history, and analytics? This action cannot be undone.',
                  onConfirm: onWipeData,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDangerRow(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: EditProfileColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: EditProfileColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
