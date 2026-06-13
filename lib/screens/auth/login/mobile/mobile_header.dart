import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/login/theme/login_theme.dart';

class MobileHeader extends StatelessWidget {
  const MobileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Rocket Icon Box
        Container(
          width: 64.0,
          height: 64.0,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LoginColors.primary, LoginColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: LoginColors.secondary.withValues(alpha: 0.15),
                blurRadius: 40.0,
                spreadRadius: 5.0,
              ),
            ],
          ),
          child: const Icon(
            Icons.rocket_launch_rounded,
            color: LoginColors.surface,
            size: 32.0,
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          'Nexus AI',
          style: getLoginGeistStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.02,
          ),
        ),
        const SizedBox(height: 8.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            'Access the future of bounded focus and boundless intelligence.',
            textAlign: TextAlign.center,
            style: getLoginGeistStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
              color: LoginColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
