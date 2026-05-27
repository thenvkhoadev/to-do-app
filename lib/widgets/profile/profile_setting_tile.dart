import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';

class ProfileSettingTile extends StatelessWidget {
  const ProfileSettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.color = NexusColors.primary,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NexusColors.onSurface, fontSize: 15, fontWeight: FontWeight.w900)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ?? const Icon(Icons.chevron_right_rounded, color: NexusColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileSwitchPill extends StatelessWidget {
  const ProfileSwitchPill({required this.enabled, super.key});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 46,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: enabled ? NexusColors.primaryContainer : NexusColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Align(
        alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        ),
      ),
    );
  }
}
