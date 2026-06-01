import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TasksSidebar extends StatelessWidget {
  const TasksSidebar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 256,
          padding: const EdgeInsets.fromLTRB(24, 32, 16, 20),
          decoration: BoxDecoration(
            color: DashboardColors.surfaceLowest.withValues(alpha: .82),
            border: Border(
              right: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .3),
                blurRadius: 28,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShaderMask(
                shaderCallback:
                    (rect) => const LinearGradient(
                      colors: [
                        DashboardColors.primary,
                        DashboardColors.secondary,
                      ],
                    ).createShader(rect),
                child: const Text(
                  'NEXUS AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Deep Work Mode',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 38),
              _Item(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                active: false,
                onTap: () => context.go('/home'),
              ),
              _Item(
                icon: Icons.account_tree_rounded,
                label: 'Projects',
                active: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
              _Item(
                icon: Icons.psychology_rounded,
                label: 'Intelligence',
                active: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
              _Item(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                active: selectedIndex == 3,
                onTap: () => onSelected(3),
              ),
              _Item(
                icon: Icons.query_stats_rounded,
                label: 'Analytics',
                active: selectedIndex == 4,
                onTap: () => onSelected(4),
              ),
              const Spacer(),
              Container(
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [
                      DashboardColors.primary,
                      DashboardColors.secondary,
                    ],
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: DashboardColors.onPrimary),
                    SizedBox(width: 8),
                    Text(
                      'New Task',
                      style: TextStyle(
                        color: DashboardColors.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _Item(
                icon: Icons.settings_rounded,
                label: 'Settings',
                active: selectedIndex == 5,
                onTap: () => onSelected(5),
              ),
              _Item(
                icon: Icons.help_outline_rounded,
                label: 'Support',
                active: selectedIndex == 6,
                onTap: () => onSelected(6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color:
            active
                ? DashboardColors.primary.withValues(alpha: .1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border(
                right: BorderSide(
                  color: active ? DashboardColors.primary : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      active
                          ? DashboardColors.primary
                          : DashboardColors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        active
                            ? DashboardColors.primary
                            : DashboardColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
