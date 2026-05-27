import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.username,
    this.avatarUrl,
    this.radius = 28,
    this.online = false,
    this.roundedRectangle = false,
    super.key,
  });

  final String? avatarUrl;
  final String username;
  final double radius;
  final bool online;
  final bool roundedRectangle;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final initial = username.trim().isNotEmpty ? username.trim().characters.first.toUpperCase() : '?';
    final imageUrl = avatarUrl?.trim();
    final borderRadius = BorderRadius.circular(roundedRectangle ? radius * 0.44 : 999);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [NexusColors.primary, NexusColors.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: NexusColors.primaryContainer.withValues(alpha: 0.34),
                blurRadius: radius * 0.75,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(roundedRectangle ? radius * 0.36 : 999),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: imageUrl == null || imageUrl.isEmpty
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF8083FF), Color(0xFF6F00BE)],
                      )
                    : null,
                color: NexusColors.surfaceContainerHigh,
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: radius * 0.78,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        if (online)
          Positioned(
            right: roundedRectangle ? 5 : 1,
            bottom: roundedRectangle ? 5 : 1,
            child: Container(
              width: radius * 0.44,
              height: radius * 0.44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NexusColors.success,
                border: Border.all(color: const Color(0xFF0D1322), width: 3),
                boxShadow: [BoxShadow(color: NexusColors.success.withValues(alpha: 0.65), blurRadius: 12)],
              ),
            ),
          ),
      ],
    );
  }
}
