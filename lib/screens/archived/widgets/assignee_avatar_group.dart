import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AssigneeAvatarGroup extends StatelessWidget {
  const AssigneeAvatarGroup({
    required this.assignees,
    this.avatarSize = 28,
    this.maxVisible = 4,
    super.key,
  });

  final List<UserProfileModel> assignees;
  final double avatarSize;
  final int maxVisible;

  static String _initials(UserProfileModel u) {
    final name = (u.fullName ?? u.username ?? u.email).trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  static Color _color(String id) {
    const palette = [
      Color(0xFF7C5CFF),
      Color(0xFF5B8CFF),
      Color(0xFF22C55E),
      Color(0xFFFFB020),
      Color(0xFFFF6B6B),
      Color(0xFF06B6D4),
      Color(0xFFA855F7),
    ];
    final hash = id.codeUnits.fold(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    if (assignees.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.person_outline_rounded,
              size: 14, color: DashboardColors.onSurfaceVariant),
          SizedBox(width: 5),
          Text(
            'Unassigned',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final shown = assignees.take(maxVisible).toList();
    final extra = assignees.length - shown.length;
    final stackWidth = shown.length * (avatarSize - 6) + 6 + (extra > 0 ? 28.0 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SizedBox(
            width: stackWidth,
            height: avatarSize,
            child: Stack(
              children: [
                for (int i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * (avatarSize - 6),
                    child: _AvatarBubble(
                      user: shown[i],
                      size: avatarSize,
                      color: _color(shown[i].id),
                      initials: _initials(shown[i]),
                    ),
                  ),
                if (extra > 0)
                  Positioned(
                    left: shown.length * (avatarSize - 6),
                    child: _OverflowBubble(
                      extra: extra,
                      size: avatarSize,
                      remaining: assignees.skip(maxVisible).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Single avatar bubble ──────────────────────────────────────────────────────

class _AvatarBubble extends StatefulWidget {
  const _AvatarBubble({
    required this.user,
    required this.size,
    required this.color,
    required this.initials,
  });

  final UserProfileModel user;
  final double size;
  final Color color;
  final String initials;

  @override
  State<_AvatarBubble> createState() => _AvatarBubbleState();
}

class _AvatarBubbleState extends State<_AvatarBubble> {
  bool _hover = false;

  String get _tooltipText {
    final name = (widget.user.fullName ?? widget.user.username ?? '').trim();
    final email = widget.user.email.trim();
    if (name.isNotEmpty && email.isNotEmpty) return '$name\n$email';
    if (name.isNotEmpty) return name;
    return email;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: _tooltipText,
        preferBelow: false,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .1)),
        ),
        child: AnimatedScale(
          scale: _hover ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DashboardColors.surface, width: 2),
            ),
            child: ClipOval(child: _avatarContent()),
          ),
        ),
      ),
    );
  }

  Widget _avatarContent() {
    final url = widget.user.avatarUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _initialsWidget(),
        placeholder: (_, __) => _initialsWidget(),
      );
    }
    return _initialsWidget();
  }

  Widget _initialsWidget() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.color,
            widget.color.withValues(alpha: .7),
          ],
        ),
      ),
      child: Text(
        widget.initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.size * 0.33,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Overflow bubble (+N) ──────────────────────────────────────────────────────

class _OverflowBubble extends StatefulWidget {
  const _OverflowBubble({
    required this.extra,
    required this.size,
    required this.remaining,
  });

  final int extra;
  final double size;
  final List<UserProfileModel> remaining;

  @override
  State<_OverflowBubble> createState() => _OverflowBubbleState();
}

class _OverflowBubbleState extends State<_OverflowBubble> {
  bool _hover = false;

  String get _tooltipText => widget.remaining
      .map((u) => (u.fullName ?? u.username ?? u.email).trim())
      .where((s) => s.isNotEmpty)
      .join('\n');

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: _tooltipText,
        preferBelow: false,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .1)),
        ),
        child: AnimatedScale(
          scale: _hover ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DashboardColors.surfaceHigh,
              border: Border.all(color: DashboardColors.surface, width: 2),
            ),
            child: Text(
              '+${widget.extra}',
              style: TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: widget.size * 0.28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
