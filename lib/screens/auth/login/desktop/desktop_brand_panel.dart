import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/login/theme/login_theme.dart';
import 'package:to_do_app/screens/auth/login/widgets/security_footer.dart';
import 'package:to_do_app/shared/widgets/stitch_shader_background.dart';
import 'package:to_do_app/screens/auth/login/desktop/achievement_card.dart';

class DesktopBrandPanel extends StatefulWidget {
  const DesktopBrandPanel({super.key});

  @override
  State<DesktopBrandPanel> createState() => _DesktopBrandPanelState();
}

class _DesktopBrandPanelState extends State<DesktopBrandPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Shader Background
        const Positioned.fill(child: StitchShaderBackground()),
        // Ambient Glow Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  LoginColors.surface.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: LoginColors.primary,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: LoginColors.secondary.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      color: LoginColors.surface,
                      size: 30.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Text(
                    'Nexus AI',
                    style: getLoginGeistStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48.0),
              // Welcome Back text with Gradient
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [LoginColors.primary, LoginColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'Welcome Back',
                  style: getLoginGeistStyle(
                    fontSize: 48.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Unlock boundless focus with your professional AI productivity ecosystem. Reconnect to your intelligent workflows and high-fidelity insights.',
                textAlign: TextAlign.center,
                style: getLoginGeistStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                  color: LoginColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 80.0),
              // Floating Badges Area
              SizedBox(
                width: double.infinity,
                height: 180.0,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final val = _controller.value * 2.0 * math.pi;

                    // Badge 1 (0 delay)
                    final dy1 = math.sin(val) * 10.0;
                    final rot1 = math.sin(val) * 0.0174;

                    // Badge 2 (1.5s delay -> shift by 1.5/6 * 2pi = 0.5pi)
                    final val2 = val - 0.5 * math.pi;
                    final dy2 = math.sin(val2) * 10.0;
                    final rot2 = math.sin(val2) * 0.0174;

                    // Badge 3 (3.0s delay -> shift by 3.0/6 * 2pi = pi)
                    final val3 = val - math.pi;
                    final dy3 = math.sin(val3) * 10.0;
                    final rot3 = math.sin(val3) * 0.0174;

                    return Stack(
                      children: [
                        Positioned(
                          left: 0.0,
                          top: 0.0,
                          child: Transform.translate(
                            offset: Offset(0, dy1 - 10.0),
                            child: Transform.rotate(
                              angle: rot1,
                              child: const AchievementCard(
                                title: 'POWER USER',
                                subtitle: 'Top 1% Efficiency',
                                icon: Icons.bolt_rounded,
                                iconColor: LoginColors.successGreen,
                                iconBgColor: Color(0x33E4F222),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16.0,
                          top: 48.0,
                          child: Transform.translate(
                            offset: Offset(0, dy2 - 10.0),
                            child: Transform.rotate(
                              angle: rot2,
                              child: const AchievementCard(
                                title: 'PREMIUM',
                                subtitle: 'Nexus Elite Access',
                                icon: Icons.auto_awesome_rounded,
                                iconColor: LoginColors.tertiary,
                                iconBgColor: Color(0x33FEE089),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 80.0,
                          bottom: 0.0,
                          child: Transform.translate(
                            offset: Offset(0, dy3 - 10.0),
                            child: Transform.rotate(
                              angle: rot3,
                              child: const AchievementCard(
                                title: 'CERTIFIED',
                                subtitle: 'Neural Architect',
                                icon: Icons.verified_rounded,
                                iconColor: LoginColors.secondary,
                                iconBgColor: Color(0x33C0C1FF),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 56.0),
              const SecurityFooter(),
            ],
          ),
        ),
      ],
    );
  }
}
