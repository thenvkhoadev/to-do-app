import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/social/presentation/widgets/post_composer_modal.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';

class PostComposerCard extends ConsumerStatefulWidget {
  const PostComposerCard({super.key});

  @override
  ConsumerState<PostComposerCard> createState() => _PostComposerCardState();
}

class _PostComposerCardState extends ConsumerState<PostComposerCard> {
  bool _isPlaceholderHovered = false;

  void _openComposer(BuildContext context, {int initialTab = 0}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PostComposerModal',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return PostComposerModal(initialTab: initialTab);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: curve,
            child: child,
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      final first = parts.first.isNotEmpty ? parts.first[0] : '';
      final last = parts.last.isNotEmpty ? parts.last[0] : '';
      return (first + last).toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : 'U';
  }

  Widget _buildFallbackAvatar(String name) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF7C5CFF), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(UserProfileModel? profile, String fullName) {
    if (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CachedNetworkImage(
          imageUrl: profile.avatarUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 36,
            height: 36,
            color: Colors.grey.shade900,
          ),
          errorWidget: (context, url, error) => _buildFallbackAvatar(fullName),
        ),
      );
    }
    return _buildFallbackAvatar(fullName);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    final fullName = profile?.fullName ?? profile?.username ?? 'Bạn';
    final firstName = fullName.split(' ').first;
    final displayFirstName = firstName.isNotEmpty ? firstName : 'Bạn';
    final postDraft = ref.watch(postDraftProvider);

    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isMobile = screenWidth < 768;

    final EdgeInsetsGeometry padding = isMobile 
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    final double actionBtnSize = isMobile ? 32 : 36;
    final double innerIconSize = isMobile ? 18 : 20;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      padding: padding,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          Colors.white.withOpacity(_isPlaceholderHovered ? 0.03 : 0.0),
          const Color(0xFF12101F),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // 1. Avatar
          SizedBox(
            width: 36,
            height: 36,
            child: _buildAvatar(profile, fullName),
          ),
          const SizedBox(width: 10),
          // 2. Input placeholder (with hover state)
          Expanded(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isPlaceholderHovered = true),
              onExit: (_) => setState(() => _isPlaceholderHovered = false),
              cursor: SystemMouseCursors.text,
              child: GestureDetector(
                onTap: () => _openComposer(context, initialTab: -1),
                child: Container(
                  color: Colors.transparent, // Ensures hover/tap hits the whole area
                  alignment: Alignment.centerLeft,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(
                      color: postDraft.isNotEmpty
                          ? Colors.white.withOpacity(0.9)
                          : (_isPlaceholderHovered 
                              ? Colors.white.withOpacity(0.55) 
                              : Colors.white.withOpacity(0.35)),
                      fontSize: 14,
                    ),
                    child: Text(
                      postDraft.isNotEmpty 
                          ? postDraft 
                          : '$displayFirstName ơi, bạn đang nghĩ gì thế?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 3. Icon Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ComposerActionButton(
                icon: Icons.videocam_rounded,
                color: const Color(0xFFEF4444),
                tooltip: 'Quay video',
                buttonSize: actionBtnSize,
                iconSize: innerIconSize,
                onTap: () => _openComposer(context, initialTab: 4),
              ),
              const SizedBox(width: 4),
              ComposerActionButton(
                icon: Icons.image_rounded,
                color: const Color(0xFF22C55E),
                tooltip: 'Thêm ảnh',
                buttonSize: actionBtnSize,
                iconSize: innerIconSize,
                onTap: () => _openComposer(context, initialTab: 0),
              ),
              const SizedBox(width: 4),
              ComposerActionButton(
                icon: Icons.assignment_rounded,
                color: const Color(0xFFF97316),
                tooltip: 'Tạo task',
                buttonSize: actionBtnSize,
                iconSize: innerIconSize,
                onTap: () => _openComposer(context, initialTab: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ComposerActionButton extends StatefulWidget {
  const ComposerActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    required this.buttonSize,
    required this.iconSize,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final double buttonSize;
  final double iconSize;

  @override
  State<ComposerActionButton> createState() => _ComposerActionButtonState();
}

class _ComposerActionButtonState extends State<ComposerActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed ? 0.92 : 1.0;
    
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.buttonSize,
              height: widget.buttonSize,
              decoration: BoxDecoration(
                color: _isHovered ? Colors.white.withOpacity(0.07) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SizedBox(
                  width: widget.iconSize,
                  height: widget.iconSize,
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: widget.iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
