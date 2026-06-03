import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    required this.email,
    required this.tier,
    required this.role,
    required this.fullNameController,
    required this.usernameController,
    required this.avatarUrlController,
    required this.onDiscard,
    required this.onSave,
    this.isSaving = false,
    super.key,
  });

  final String email;
  final String tier;
  final String role;
  final TextEditingController fullNameController;
  final TextEditingController usernameController;
  final TextEditingController avatarUrlController;
  final VoidCallback onDiscard;
  final VoidCallback onSave;
  final bool isSaving;

  void _triggerAvatarChange(BuildContext context) {
    final controller = TextEditingController(text: avatarUrlController.text);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EditProfileColors.cardBg,
        title: const Text(
          'Change Avatar URL',
          style: TextStyle(color: EditProfileColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: EditProfileColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter direct image URL...',
            hintStyle: TextStyle(color: EditProfileColors.textOutline),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: EditProfileColors.borderSides),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: EditProfileColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: EditProfileColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              avatarUrlController.text = controller.text.trim();
              Navigator.pop(ctx);
            },
            child: const Text('Update', style: TextStyle(color: EditProfileColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([fullNameController, usernameController, avatarUrlController]),
      builder: (context, _) {
        final currentName = fullNameController.text.isNotEmpty ? fullNameController.text : 'User';
        final currentUsername = usernameController.text.isNotEmpty ? usernameController.text : 'username';
        final currentAvatar = avatarUrlController.text.trim();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            final avatarWidget = Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: EditProfileColors.primary.withValues(alpha: 0.25),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _triggerAvatarChange(context),
                    child: Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [EditProfileColors.primary, EditProfileColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: EditProfileColors.cardBg,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: currentAvatar.isNotEmpty
                            ? Image.network(
                                currentAvatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(currentName),
                              )
                            : _buildPlaceholderAvatar(currentName),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _triggerAvatarChange(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: EditProfileColors.primary,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            final infoWidget = Column(
              crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      currentName,
                      style: const TextStyle(
                        color: EditProfileColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EditProfileColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: EditProfileColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        tier.toUpperCase(),
                        style: const TextStyle(
                          color: EditProfileColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EditProfileColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: EditProfileColors.secondary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          color: EditProfileColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '@$currentUsername • $email',
                  textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                  style: const TextStyle(
                    color: EditProfileColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: EditProfileColors.success, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(color: EditProfileColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Text(
                        'Level 42',
                        style: TextStyle(color: EditProfileColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    TextButton(
                      onPressed: () => _triggerAvatarChange(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Change Photo', style: TextStyle(color: EditProfileColors.primary, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () {
                        avatarUrlController.clear();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Remove Photo', style: TextStyle(color: EditProfileColors.error, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Supports JPG, PNG, WEBP. Max size: 5MB',
                  style: TextStyle(color: EditProfileColors.textOutline, fontSize: 10),
                ),
              ],
            );

            final actionsWidget = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: onDiscard,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EditProfileColors.textPrimary,
                        side: const BorderSide(color: EditProfileColors.borderSides),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Discard'),
                    ),
                    const SizedBox(width: 12),
                    EditProfileGradientButton(
                      label: 'Save Changes',
                      isLoading: isSaving,
                      onTap: onSave,
                    ),
                  ],
                ),
              ],
            );

            if (isDesktop) {
              return EditProfileGlassCard(
                child: Row(
                  children: [
                    avatarWidget,
                    const SizedBox(width: 32),
                    Expanded(child: infoWidget),
                    const SizedBox(width: 24),
                    actionsWidget,
                  ],
                ),
              );
            } else {
              return EditProfileGlassCard(
                child: Column(
                  children: [
                    avatarWidget,
                    const SizedBox(height: 24),
                    infoWidget,
                    const SizedBox(height: 24),
                    actionsWidget,
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildPlaceholderAvatar(String name) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.05),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: EditProfileColors.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
