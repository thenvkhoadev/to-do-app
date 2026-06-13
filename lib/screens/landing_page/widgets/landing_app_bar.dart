import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'design_system.dart';

class LandingAppBar extends StatelessWidget {
  final double width;

  const LandingAppBar({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final isMobile = width < 768;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 64.0,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1322).withValues(alpha: 0.60),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Text(
                    'Nexus AI',
                    style: getLandingGeistStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.w700,
                      color: LandingColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  // Menu links (Desktop only)
                  if (!isMobile)
                    Row(
                      children: [
                        _buildNavLink('Features', isActive: true),
                        const SizedBox(width: 32.0),
                        _buildNavLink('Pricing', isActive: false),
                        const SizedBox(width: 32.0),
                        _buildNavLink('Intelligence', isActive: false),
                      ],
                    ),

                  // Buttons
                  if (isMobile)
                    PressableScale(
                      onTap: () => _goSignUp(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: LandingColors.primary,
                          borderRadius: BorderRadius.circular(9999.0),
                        ),
                        child: Text(
                          'Get Started',
                          style: getLandingGeistStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF131449),
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        PressableScale(
                          onTap: () => _goSignIn(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              'Login',
                              style: getLandingGeistStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w400,
                                color: LandingColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        PressableScale(
                          onTap: () => _goSignUp(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 8.0,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE1DFFF),
                                  Color(0xFFC0C1FF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC0C1FF).withValues(alpha: 0.15),
                                  blurRadius: 20.0,
                                ),
                              ],
                            ),
                            child: Text(
                              'Get Started',
                              style: getLandingGeistStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF131449),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavLink(String text, {required bool isActive}) {
    return HoverBuilder(
      builder: (context, isHovered) {
        return PressableScale(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.only(bottom: 4.0),
            decoration: BoxDecoration(
              border: isActive
                  ? const Border(
                      bottom: BorderSide(
                        color: LandingColors.primary,
                        width: 2.0,
                      ),
                    )
                  : null,
            ),
            child: Text(
              text,
              style: getLandingGeistStyle(
                fontSize: 16.0,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? LandingColors.primary
                    : (isHovered ? LandingColors.textPrimary : LandingColors.textSecondary),
              ),
            ),
          ),
        );
      },
    );
  }

  void _goSignIn(BuildContext context) {
    context.go('/login');
  }

  void _goSignUp(BuildContext context) {
    context.go('/signup');
  }
}
