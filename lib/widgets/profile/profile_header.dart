import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/widgets/profile/profile_avatar.dart';
import 'package:to_do_app/widgets/profile/profile_glass_container.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.username,
    required this.email,
    this.avatarUrl,
    this.compact = false,
    this.onEdit,
    super.key,
  });

  final String username;
  final String email;
  final String? avatarUrl;
  final bool compact;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return ProfileGlassContainer(
      padding: EdgeInsets.all(compact ? 22 : 32),
      radius: compact ? 28 : 32,
      glowColor: NexusColors.primaryContainer,
      child:
          compact
              ? _CompactHeader(
                username: username,
                email: email,
                avatarUrl: avatarUrl,
                onEdit: onEdit,
              )
              : _WideHeader(
                username: username,
                email: email,
                avatarUrl: avatarUrl,
                onEdit: onEdit,
              ),
    );
  }
}

class _WideHeader extends StatelessWidget {
  const _WideHeader({
    required this.username,
    required this.email,
    this.avatarUrl,
    this.onEdit,
  });

  final String username;
  final String email;
  final String? avatarUrl;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileAvatar(
          username: username,
          avatarUrl: avatarUrl,
          radius: 54,
          roundedRectangle: true,
          online: true,
        ),
        const SizedBox(width: 28),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MembershipBadge(),
              const SizedBox(height: 12),
              Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: NexusColors.onSurface,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _MetaChip(icon: Icons.mail_outline_rounded, label: email),
                  const _MetaChip(
                    icon: Icons.location_on_outlined,
                    label: 'Remote workspace',
                  ),
                  const _MetaChip(
                    icon: Icons.calendar_month_rounded,
                    label: 'Joined 2026',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        _GradientAction(
          label: 'Edit Profile',
          icon: Icons.edit_rounded,
          onTap: onEdit,
        ),
      ],
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.username,
    required this.email,
    this.avatarUrl,
    this.onEdit,
  });

  final String username;
  final String email;
  final String? avatarUrl;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileAvatar(
          username: username,
          avatarUrl: avatarUrl,
          radius: 48,
          online: true,
        ),
        const SizedBox(height: 16),
        const _MembershipBadge(),
        const SizedBox(height: 12),
        Text(
          username,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: NexusColors.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          email,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: NexusColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 18),
        _GradientAction(
          label: 'Edit Profile',
          icon: Icons.edit_rounded,
          onTap: onEdit,
        ),
      ],
    );
  }
}

class _MembershipBadge extends StatelessWidget {
  const _MembershipBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            NexusColors.primary.withValues(alpha: 0.22),
            NexusColors.secondary.withValues(alpha: 0.18),
          ],
        ),
        border: Border.all(color: NexusColors.primary.withValues(alpha: 0.32)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: NexusColors.primary,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            'PRO PLAN',
            style: TextStyle(
              color: NexusColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: NexusColors.onSurfaceVariant, size: 16),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: NexusColors.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GradientAction extends StatelessWidget {
  const _GradientAction({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [
              NexusColors.primaryContainer,
              NexusColors.secondaryContainer,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: NexusColors.primaryContainer.withValues(alpha: 0.26),
              blurRadius: 24,
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
