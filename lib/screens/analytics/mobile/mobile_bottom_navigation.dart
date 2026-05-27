import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AnalyticsMobileBottomNavigation extends StatelessWidget {
  const AnalyticsMobileBottomNavigation({required this.bottomInset, super.key});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
          decoration: BoxDecoration(color: DashboardColors.surface.withValues(alpha: .52), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .10))), boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .14), blurRadius: 32, offset: const Offset(0, -8))]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(icon: Icons.home_rounded, label: 'Home', onTap: () => context.go('/home')),
              _BottomNavItem(icon: Icons.calendar_month_rounded, label: 'Calendar', onTap: () => context.go('/calendar')),
              _BottomNavItem(icon: Icons.assignment_rounded, label: 'Tasks', onTap: () => context.go('/tasks')),
              _BottomNavItem(icon: Icons.bar_chart_rounded, label: 'Stats', active: true, onTap: () => context.go('/analytics')),
              _BottomNavItem(icon: Icons.person_rounded, label: 'Profile', onTap: () => context.go('/profile')),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({required this.icon, required this.label, this.active = false, this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? DashboardColors.primary.withValues(alpha: .12) : Colors.transparent,
      borderRadius: BorderRadius.circular(DashboardRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(DashboardRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: active ? 13 : 7, vertical: 7),
          child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: active ? DashboardColors.primary : DashboardColors.onSurfaceVariant, size: 23), Text(label, style: TextStyle(color: active ? DashboardColors.primary : DashboardColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w800))]),
        ),
      ),
    );
  }
}
