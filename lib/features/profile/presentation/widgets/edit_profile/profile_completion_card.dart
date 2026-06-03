import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({
    required this.avatarUrlController,
    required this.usernameController,
    required this.fullNameController,
    required this.bioController,
    super.key,
  });

  final TextEditingController avatarUrlController;
  final TextEditingController usernameController;
  final TextEditingController fullNameController;
  final TextEditingController bioController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        avatarUrlController,
        usernameController,
        fullNameController,
        bioController,
      ]),
      builder: (context, _) {
        final hasAvatar = avatarUrlController.text.trim().isNotEmpty;
        final hasUsername = usernameController.text.trim().isNotEmpty;
        final hasFullName = fullNameController.text.trim().isNotEmpty;
        final hasBio = bioController.text.trim().isNotEmpty;

        final items = [
          _CompletionItem('Avatar & Identity', hasAvatar),
          _CompletionItem('Professional Bio', hasBio),
          _CompletionItem('Legal Full Name', hasFullName),
          _CompletionItem('Public Username', hasUsername),
        ];

        final completedCount = items.where((item) => item.isCompleted).length;
        final percent = items.isEmpty ? 0.0 : (completedCount / items.length);

        return EditProfileGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile Completion',
                style: TextStyle(
                  color: EditProfileColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: percent,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: const AlwaysStoppedAnimation(EditProfileColors.primary),
                        ),
                      ),
                      Text(
                        '${(percent * 100).round()}%',
                        style: const TextStyle(
                          color: EditProfileColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: item.isCompleted ? EditProfileColors.success : EditProfileColors.textOutline.withValues(alpha: 0.6),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: item.isCompleted ? EditProfileColors.success : EditProfileColors.textSecondary,
                            fontSize: 14,
                            fontWeight: item.isCompleted ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompletionItem {
  _CompletionItem(this.label, this.isCompleted);
  final String label;
  final bool isCompleted;
}
