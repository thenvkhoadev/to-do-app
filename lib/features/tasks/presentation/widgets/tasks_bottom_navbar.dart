import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TasksBottomNavBar extends StatelessWidget {
  const TasksBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
          decoration: BoxDecoration(color: DashboardColors.surface.withValues(alpha: .48), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .1))), boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .14), blurRadius: 30)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Nav(icon: Icons.home_rounded, label: 'Home', onTap: () => context.go('/home')),
            _Nav(icon: Icons.calendar_month_rounded, label: 'Calendar', onTap: () => context.go('/calendar')),
            const _Nav(icon: Icons.assignment_rounded, label: 'Tasks', active: true),
            _Nav(icon: Icons.bar_chart_rounded, label: 'Stats', onTap: () => context.go('/analytics')),
            _Nav(icon: Icons.person_rounded, label: 'Profile', onTap: () => context.go('/profile')),
          ]),
        ),
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({required this.icon, required this.label, this.active = false, this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Material(color: active ? DashboardColors.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(999), child: InkWell(borderRadius: BorderRadius.circular(999), onTap: onTap, child: Padding(padding: EdgeInsets.symmetric(horizontal: active ? 14 : 8, vertical: 7), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: active ? Colors.white : DashboardColors.onSurfaceVariant, size: 22), Text(label, style: TextStyle(color: active ? Colors.white : DashboardColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700))]))));
  }
}
