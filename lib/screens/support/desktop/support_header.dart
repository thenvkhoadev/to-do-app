import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class SupportHeader extends StatelessWidget {
  const SupportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(color: DashboardColors.surface.withValues(alpha: .5), border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08)))),
          child: const Row(
            children: [
              Icon(Icons.support_agent_rounded, color: DashboardColors.primary),
              SizedBox(width: 12),
              Text('Support', style: TextStyle(color: DashboardColors.primary, fontSize: 24, fontWeight: FontWeight.w900)),
              Spacer(),
              _HeaderIcon(icon: Icons.notifications_none_rounded),
              SizedBox(width: 12),
              _HeaderIcon(icon: Icons.history_edu_rounded),
              SizedBox(width: 12),
              ProfileAvatar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: () {}, tooltip: 'Support action', icon: Icon(icon, color: DashboardColors.onSurfaceVariant));
  }
}
