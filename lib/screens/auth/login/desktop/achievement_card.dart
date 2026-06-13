import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/login/theme/login_theme.dart';
import 'package:to_do_app/screens/auth/login/widgets/glass_card.dart';

class AchievementCard extends StatelessWidget {
  const AchievementCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 12.0,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: getLoginGeistStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                subtitle,
                style: getLoginGeistMonoStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
