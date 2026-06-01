import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class SupportMobileBottomNavigation extends StatelessWidget {
  const SupportMobileBottomNavigation({required this.bottomInset, super.key});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
          decoration: BoxDecoration(
            color: DashboardColors.surfaceHighest.withValues(alpha: .84),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: .10)),
            ),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.primary.withValues(alpha: .14),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: () => context.go('/home'),
              ),
              _BottomNavItem(
                icon: Icons.task_alt_rounded,
                label: 'Tasks',
                onTap: () => context.go('/tasks'),
              ),
              _BottomNavItem(
                icon: Icons.auto_awesome_rounded,
                label: 'AI',
                onTap: () => context.go('/ai'),
              ),
              _BottomNavItem(
                icon: Icons.support_agent_rounded,
                label: 'Support',
                active: true,
                onTap: () => context.go('/support'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? DashboardColors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(DashboardRadii.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(DashboardRadii.full),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: active ? 14 : 8,
            vertical: 7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    active
                        ? DashboardColors.onPrimary
                        : DashboardColors.onSurfaceVariant,
                size: 22,
              ),
              Text(
                label,
                style: TextStyle(
                  color:
                      active
                          ? DashboardColors.onPrimary
                          : DashboardColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
