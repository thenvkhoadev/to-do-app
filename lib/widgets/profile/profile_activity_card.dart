import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/widgets/profile/profile_glass_container.dart';

class ProfileActivityCard extends StatelessWidget {
  const ProfileActivityCard({
    required this.title,
    required this.items,
    this.icon = Icons.auto_awesome_rounded,
    this.color = NexusColors.primary,
    super.key,
  });

  final String title;
  final List<ProfileActivityItem> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ProfileGlassContainer(
      glowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionLabel(label: title, icon: icon, color: color),
          const SizedBox(height: 20),
          for (var i = 0; i < items.length; i++) ...[
            _ActivityRow(
              item: items[i],
              color: i == 0 ? color : NexusColors.onSurfaceVariant,
            ),
            if (i != items.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class ProfileActivityItem {
  const ProfileActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? trailing;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.color});

  final ProfileActivityItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: color, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NexusColors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (item.trailing != null) ...[
            const SizedBox(width: 10),
            Text(
              item.trailing!,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
