import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/shared/widgets/stitch_shader_background.dart';
import 'widgets/design_system.dart';
import 'widgets/landing_app_bar.dart';
import 'widgets/hero_section.dart';
import 'widgets/social_proof_section.dart';
import 'widgets/feature_bento_grid.dart';
import 'widgets/rewards_section.dart';
import 'widgets/streak_card.dart';
import 'widgets/xp_economy_card.dart';
import 'widgets/testimonials_section.dart';
import 'widgets/faq_section.dart';
import 'widgets/footer_section.dart';
import 'widgets/mobile_bottom_navigation.dart';
import 'widgets/ai_command_bar.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandingColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 768;

          return Stack(
            children: [
              // 1. Background Shader Effect (Matches WebGL shader from HTML)
              const Positioned.fill(
                child: StitchShaderBackground(),
              ),

              // 2. Main Scrollable Content
              Positioned.fill(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Top spacing under sticky navbar
                      SizedBox(height: isMobile ? 80.0 : 120.0),

                      // Responsive sections
                      if (isMobile)
                        _buildMobileLayout(context, width)
                      else
                        _buildDesktopLayout(context, width),

                      // Footer section
                      FooterSection(width: width),
                    ],
                  ),
                ),
              ),

              // 3. Sticky Top App Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LandingAppBar(width: width),
              ),

              // 4. Mobile Bottom Overlays (Command Bar & Sticky Navigation)
              if (isMobile) ...[
                Positioned(
                  bottom: 96.0,
                  left: 24.0,
                  right: 24.0,
                  child: const AiCommandBar(),
                ),
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: MobileBottomNavigation(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, double width) {
    return Column(
      children: [
        HeroSection(width: width),
        FeatureBentoGrid(width: width),
        RewardsSection(width: width),
        const TestimonialsSection(),
        const FaqSection(),
        _buildFinalCta(context, isMobile: false),
        const SizedBox(height: 64.0),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroSection(width: width),
        const SocialProofSection(),
        
        // Gamification Showcase
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REWARDING WORKFLOW',
                style: getLandingGeistStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: LandingColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Productivity, Gamified.',
                style: getLandingGeistStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  color: LandingColors.textPrimary,
                  letterSpacing: -0.56,
                ),
              ),
              const SizedBox(height: 24.0),
              const StreakCard(isMobile: true),
              const SizedBox(height: 16.0),
              const XpEconomyCard(isMobile: true),
            ],
          ),
        ),

        // Intelligence Features List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Intelligence Features',
                  style: getLandingGeistStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w700,
                    color: LandingColors.textPrimary,
                    letterSpacing: -0.56,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              _buildMobileFeatureItem(
                icon: Icons.psychology,
                title: 'Contextual Memory',
                desc: 'Nexus learns your workflow patterns and anticipates your next move.',
                iconBg: LandingColors.primary.withValues(alpha: 0.15),
                iconColor: LandingColors.primary,
              ),
              const SizedBox(height: 16.0),
              _buildMobileFeatureItem(
                icon: Icons.auto_awesome,
                title: 'Auto-Focus Mode',
                desc: 'Intelligent notification filtering to keep you in the "boundless" state.',
                iconBg: LandingColors.secondary.withValues(alpha: 0.15),
                iconColor: LandingColors.secondary,
              ),
              const SizedBox(height: 16.0),
              _buildMobileFeatureItem(
                icon: Icons.terminal,
                title: 'CLI-First Workflow',
                desc: 'For the power users. Execute AI commands as fast as you can type.',
                iconBg: LandingColors.surfaceVariant,
                iconColor: LandingColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32.0),
      ],
    );
  }

  Widget _buildMobileFeatureItem({
    required IconData icon,
    required String title,
    required String desc,
    required Color iconBg,
    required Color iconColor,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(24.0),
      borderRadius: 16.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: getLandingGeistStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    color: LandingColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  desc,
                  style: getLandingGeistStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: LandingColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalCta(BuildContext context, {required bool isMobile}) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1440.0),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: GlassCard(
          borderRadius: 40.0,
          padding: const EdgeInsets.all(64.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow background
              Positioned(
                child: Container(
                  width: 300.0,
                  height: 300.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFC0C1FF).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Content details
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ready to reach Level 100?',
                    style: getLandingGeistStyle(
                      fontSize: 48.0,
                      fontWeight: FontWeight.w700,
                      color: LandingColors.textPrimary,
                      letterSpacing: -1.92,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600.0),
                    child: Text(
                      'Join thousands of high-performers who have optimized their lives with Nexus AI. Start your 14-day free trial today.',
                      style: getLandingGeistStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: LandingColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PressableScale(
                        onTap: () => _goSignUp(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE1DFFF),
                                Color(0xFFC0C1FF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC0C1FF).withValues(alpha: 0.25),
                                blurRadius: 20.0,
                              ),
                            ],
                          ),
                          child: Text(
                            'Create Your Account',
                            style: getLandingGeistStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF131449),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      PressableScale(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: LandingColors.glassBorder,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Text(
                            'Schedule Enterprise Demo',
                            style: getLandingGeistStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              color: LandingColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goSignUp(BuildContext context) {
    context.go('/signup');
  }
}
