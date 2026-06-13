import 'dart:ui';
import 'package:flutter/material.dart';
import 'design_system.dart';

class MobileBottomNavigation extends StatelessWidget {
  const MobileBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: LandingColors.surface.withValues(alpha: 0.80),
            border: const Border(
              top: BorderSide(
                color: LandingColors.glassBorder,
                width: 1.0,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'HOME',
                isActive: true,
              ),
              _buildNavItem(
                icon: Icons.explore,
                label: 'EXPLORE',
                isActive: false,
              ),
              _buildNavItem(
                icon: Icons.analytics,
                label: 'DATA',
                isActive: false,
              ),
              _buildNavItem(
                icon: Icons.account_circle,
                label: 'PROFILE',
                isActive: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final color = isActive ? LandingColors.primary : LandingColors.textSecondary.withValues(alpha: 0.60);

    return PressableScale(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 24.0,
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: getLandingGeistStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
