import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'design_system.dart';
import 'hero_dashboard_preview.dart';
import 'animated_float.dart';

class HeroSection extends StatelessWidget {
  final double width;

  const HeroSection({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final isMobile = width < 1200;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1440.0),
        padding: EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: isMobile ? 32.0 : 64.0,
        ),
        child: isMobile ? _buildMobileHero(context) : _buildDesktopHero(context),
      ),
    );
  }

  Widget _buildDesktopHero(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column (Text & CTAs)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version Pill
              _buildVersionBadge(isMobile: false),
              const SizedBox(height: 32.0),
              
              // Title
              Text.rich(
                TextSpan(
                  text: 'Turn Tasks Into ',
                  style: getLandingGeistStyle(
                    fontSize: 48.0,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -1.92,
                  ),
                  children: [
                    TextSpan(
                      text: 'Progress.',
                      style: getLandingGeistStyle(
                        fontSize: 48.0,
                        fontWeight: FontWeight.w700,
                        color: LandingColors.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              
              // Description
              Text(
                'Experience the world\'s first AI-driven productivity ecosystem that gamifies your workflow. Earn XP for deep work, maintain streaks with intelligent AI nudges, and conquer your goals with high-fidelity analytics.',
                style: getLandingGeistStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                  color: LandingColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32.0),
              
              // Buttons
              Row(
                children: [
                  PressableScale(
                    onTap: () => _goSignUp(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 16.0,
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
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC0C1FF).withValues(alpha: 0.15),
                            blurRadius: 20.0,
                          ),
                        ],
                      ),
                      child: Text(
                        'Get Started Free',
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
                    child: GlassCard(
                      borderRadius: 12.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.play_circle,
                            color: LandingColors.textPrimary,
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'Watch Demo',
                            style: getLandingGeistStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              color: LandingColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48.0),
              
              // Social Proof Avatars
              Row(
                children: [
                  SizedBox(
                    width: 96.0,
                    height: 40.0,
                    child: Stack(
                      children: [
                        _buildAvatar(0, 'https://lh3.googleusercontent.com/aida-public/AB6AXuDPGPnKHu_Vs92gtHYxKPNbR7fBcukgFVwY4xIJhzwLNyO3ltdK-jVunawiNR5tPAd2RR3evuq2AIt1lB4UoUC9b1uNJstB2zsIoKYrd19IzPucgcH0VM2MhtX4JXj1cYNPJGaCiTZdfxzrrNOiDIw9IL_wSgTwgj9BUA7o9Q2EV_KbZa4cJ4NzbyVO9ODDp3yfybBt8HVAxPSj-4HFJ7JsIFlzH21ryU41EPDKmPf2HJNmDVsriPAYLEeFnorihZ72kFClzXTeCLlz'),
                        _buildAvatar(1, 'https://lh3.googleusercontent.com/aida-public/AB6AXuCCJGUfyXeRz00rWzvUYJXuFY-V1sWjmFc7K-dl6gNrJ-duTpAxJCN-p2WRFBC7kMtplaq-iYPIpEFKSy1jdxSRbGVq3vKBT2XBCiTuL_3XSsUWY3lfZFYyuDXM3FIS0APRH_THsVb-vpnC40ZqfZV68bkZtdtU9YEfdkYAGTGUc4bYlRII0d6qbxicMrsnIeDT92nxbGhgWd5Rd1aMd4e5wpCzMUl8TsqVbMY2BluwQoLU7T_wmW5HMoymEBTLicSfhGmqjGwNsF4_'),
                        _buildAvatar(2, 'https://lh3.googleusercontent.com/aida-public/AB6AXuACO5tyf3LWKfAVbvFYDLqB_xn-kGw2_AOJap3_UaOL2hELh7PeRhSkvDR6CULmQcMdfUW0uo0DNVsXUqJ93HpraohGfi9gZdLYqhYHMLSiELQ8J4vYyZD2Fp27n8kU5DlWrjD0PZ8eh7o_rD-bCTejGMBFk-xWfN7kJaeQd0_dRHa5StKw9OekyxmF8I-px1pTkpKkRcVuU-GpKf6QqcbcPJ67gcYiOLC9zcmJVrsRO4JvAaEPaNcq_avdn_eVIf7DRcOP7FjruXu_'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Text(
                    'Trusted by 50,000+ power users',
                    style: getLandingGeistStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: LandingColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Right Column (Dashboard Preview Container)
        const Expanded(
          child: Center(
            child: HeroDashboardPreview(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHero(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Version Pill
        _buildVersionBadge(isMobile: true),
        const SizedBox(height: 24.0),
        
        // Title
        Text.rich(
          TextSpan(
            text: 'Turn Tasks Into ',
            style: getLandingGeistStyle(
              fontSize: 36.0,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -1.0,
            ),
            children: [
              TextSpan(
                text: 'Progress.',
                style: getLandingGeistStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.w700,
                  color: LandingColors.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        
        // Description
        Text(
          'The ethereal AI workspace designed for boundless focus and high-performance output.',
          style: getLandingGeistStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
            color: LandingColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32.0),
        
        // Button
        PressableScale(
          onTap: () => _goSignUp(context),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: BoxDecoration(
              color: LandingColors.primary,
              borderRadius: BorderRadius.circular(12.0),
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
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF131449),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        
        // Subtext
        Text(
          'NO CREDIT CARD REQUIRED',
          style: getLandingGeistStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: LandingColors.textSecondary.withValues(alpha: 0.60),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 48.0),
        
        // Floating Hero Image (Mobile Mockup)
        AnimatedFloat(
          offset: 10.0,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(4.0),
                borderRadius: 28.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDHhmPGQI3zxpTgy6vARpcUFPdtsyhf3tDWvTfdj1qICt6BAAawYVP-FIl7p-WtE_U5G0PzCXrt8p_8LhvCIE8nWgqbMjet6AnrMbjqPsQtVBbM0g-d0vQmhOwq8PhW4CDBnfpaTT00IaQOGJZWQ-tftvvjHzBaymqrkR8_Q9wRplCZbGL8UArhvfiAOm456Y_gjXAp-iOFPDcnkZ7phJLZaaP8WDwOo8AOTvjNJcf8dD2k2s1noVse1roAUjDAsIu4u8IISgL9CbT2',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: LandingColors.surfaceVariant),
                      errorWidget: (context, url, error) => Container(color: LandingColors.surfaceVariant),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -16.0,
                right: -8.0,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  borderRadius: 12.0,
                  borderColor: LandingColors.tertiary.withValues(alpha: 0.20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified,
                        color: LandingColors.tertiary,
                        size: 16.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        '99.9% ACCURACY',
                        style: getLandingGeistMonoStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w500,
                          color: LandingColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVersionBadge({required bool isMobile}) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: const Color(0x26C0C1FF), // nebula-glow
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(9999.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bolt,
              color: LandingColors.tertiary,
              size: 16.0,
            ),
            const SizedBox(width: 8.0),
            Text(
              'VERSION 2.0 IS LIVE',
              style: getLandingGeistStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: LandingColors.tertiary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
    } else {
      return GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        borderRadius: 9999.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8.0,
              height: 8.0,
              decoration: const BoxDecoration(
                color: LandingColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              'V2.4 NOW LIVE',
              style: getLandingGeistStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: LandingColors.secondary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAvatar(int index, String url) {
    return Positioned(
      left: index * 24.0,
      child: Container(
        width: 40.0,
        height: 40.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: LandingColors.background,
            width: 2.0,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: LandingColors.surfaceVariant),
            errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _goSignUp(BuildContext context) {
    context.go('/signup');
  }
}
