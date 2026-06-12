import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/streak/presentation/providers/streak_providers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class PremiumProfileCapsuleDropdown extends ConsumerStatefulWidget {
  const PremiumProfileCapsuleDropdown({super.key});

  @override
  ConsumerState<PremiumProfileCapsuleDropdown> createState() =>
      _PremiumProfileCapsuleDropdownState();
}

class _PremiumProfileCapsuleDropdownState
    extends ConsumerState<PremiumProfileCapsuleDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss barrier
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeDropdown,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            width: 300,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 12),
              child: _DropdownContent(
                onClose: _closeDropdown,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final profile = ref.watch(userProfileProvider).valueOrNull;

    final username = (profile?.username?.trim().isNotEmpty == true
            ? profile!.username
            : profile?.fullName?.trim().isNotEmpty == true
                ? profile!.fullName
                : metadata?['username'] ??
                    metadata?['full_name'] ??
                    user?.email ??
                    'NvKhoaaa')
        .toString();

    final avatarUrl = (profile?.avatarUrl?.trim().isNotEmpty == true
            ? profile!.avatarUrl
            : metadata?['avatar_url'] ?? metadata?['avatarUrl'] ?? '')
        .toString()
        .trim();

    final initial = username.trim().isEmpty
        ? '?'
        : username.trim().characters.first.toUpperCase();

    final avatar = CircleAvatar(
      radius: 18,
      backgroundColor: DashboardColors.surfaceHigh,
      backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
      child: avatarUrl.isEmpty
          ? Text(
              initial,
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 18 * 0.78,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: DashboardColors.surfaceHigh.withValues(alpha: .62),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _toggleDropdown,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  avatar,
                  const SizedBox(width: 9),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DashboardColors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: DashboardColors.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownContent extends ConsumerWidget {
  const _DropdownContent({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ProfileNavigationScope.maybeOf(context);
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final profile = ref.watch(userProfileProvider).valueOrNull;

    final username = (profile?.username?.trim().isNotEmpty == true
            ? profile!.username
            : profile?.fullName?.trim().isNotEmpty == true
                ? profile!.fullName
                : metadata?['username'] ??
                    metadata?['full_name'] ??
                    user?.email ??
                    'NvKhoaaa')
        .toString();

    final avatarUrl = (profile?.avatarUrl?.trim().isNotEmpty == true
            ? profile!.avatarUrl
            : metadata?['avatar_url'] ?? metadata?['avatarUrl'] ?? '')
        .toString()
        .trim();

    final initial = username.trim().isEmpty
        ? '?'
        : username.trim().characters.first.toUpperCase();

    final level = profile?.level ?? 1;
    final rank = profile?.rankTitle ?? 'Rookie V';
    final totalXp = profile?.totalXp ?? 0;
    final streak = profile == null
        ? 0
        : displayStreakCount(profile.streakCount, profile.lastActivityDate);

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xCC1B1C1D), // bg-surface-container-low 80% opacity
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Header
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE1DFFF).withValues(alpha: 0.2),
                              width: 2,
                            ),
                            image: avatarUrl.isEmpty
                                ? null
                                : DecorationImage(
                                    image: NetworkImage(avatarUrl),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          child: avatarUrl.isEmpty
                              ? Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF22C55E), // HTML success
                              border: Border.all(
                                color: const Color(0xFF121315),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE3E2E3), // HTML on-surface
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x1AE1DFFF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Lv.$level',
                                  style: const TextStyle(
                                    color: Color(0xFFE1DFFF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '• $rank',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFC7C5D0),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bolt_rounded,
                        iconColor: const Color(0xFFE1DFFF),
                        label: 'XP TOTAL',
                        value: totalXp.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFEF4444),
                        label: 'STREAK',
                        value: '$streak Days',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 12),
                // Action Buttons
                _ActionItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  onTap: () {
                    onClose();
                    if (scope != null) {
                      scope.onProfileSelected();
                    } else {
                      context.go('/profile');
                    }
                  },
                ),
                _ActionItem(
                  icon: Icons.military_tech_rounded,
                  label: 'Achievements',
                  onTap: () {
                    onClose();
                    if (scope?.onAchievementsSelected != null) {
                      scope!.onAchievementsSelected!();
                    }
                  },
                ),
                _ActionItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () {
                    onClose();
                    if (scope?.onSettingsSelected != null) {
                      scope!.onSettingsSelected!();
                    } else {
                      context.go('/settings');
                    }
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 8),
                _ActionItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  isError: true,
                  onTap: () async {
                    onClose();
                    if (scope?.onSignOut != null) {
                      scope!.onSignOut!();
                    } else {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC7C5D0),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatefulWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isError = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isError;

  @override
  State<_ActionItem> createState() => _ActionItemState();
}

class _ActionItemState extends State<_ActionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.isError
        ? const Color(0xFFEF4444).withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.05);

    final normalTextColor = widget.isError
        ? const Color(0xFFEF4444).withValues(alpha: 0.8)
        : const Color(0xFFE3E2E3);

    final hoverTextColor = widget.isError
        ? const Color(0xFFEF4444)
        : const Color(0xFFE1DFFF);

    final normalIconColor = widget.isError
        ? const Color(0xFFEF4444).withValues(alpha: 0.8)
        : const Color(0xFFC7C5D0);

    final hoverIconColor = widget.isError
        ? const Color(0xFFEF4444)
        : const Color(0xFFE1DFFF);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: _isHovered ? hoverIconColor : normalIconColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isHovered ? hoverTextColor : normalTextColor,
                  fontSize: 14,
                  fontWeight: widget.isError ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
