import 'package:flutter/material.dart';
import 'package:to_do_app/constants/colors.dart';
import 'package:to_do_app/screens/sign_in_page.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: NexusLandingPage());
  }
}

class NexusLandingPage extends StatelessWidget {
  const NexusLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFF0D1322))),
        const Positioned(
          top: -160,
          left: -120,
          child: _GlowOrb(size: 420, color: Color(0x267C4DFF)),
        ),
        const Positioned(
          top: 260,
          right: -160,
          child: _GlowOrb(size: 520, color: Color(0x204DDCC6)),
        ),
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child:
                  isDesktop ? const _DesktopLanding() : const _MobileLanding(),
            ),
          ],
        ),
        const Positioned(top: 0, left: 0, right: 0, child: _LandingTopNav()),
      ],
    );
  }
}

class _DesktopLanding extends StatelessWidget {
  const _DesktopLanding();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _DesktopHero(),
        _SocialProofSection(),
        _DesktopFeaturesSection(),
        _DesktopTestimonialSection(),
        _FinalCtaSection(),
        _LandingFooter(),
      ],
    );
  }
}

class _MobileLanding extends StatelessWidget {
  const _MobileLanding();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _MobileHero(),
        _MobileValueProps(),
        _MobileTestimonial(),
        _MobileIntegrations(),
        _LandingFooter(),
      ],
    );
  }
}

class _LandingTopNav extends StatelessWidget {
  const _LandingTopNav();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1322).withValues(alpha: 0.84),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: NexusColors.primary.withValues(alpha: 0.12),
            blurRadius: 30,
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Row(
            children: [
              const Text(
                'TaskFlow AI',
                style: TextStyle(
                  color: Color(0xFFDDE2F8),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const Spacer(),
              if (isDesktop) ...const [
                _LandingNavLink(label: 'Features', active: true),
                SizedBox(width: 32),
                _LandingNavLink(label: 'Pricing'),
                SizedBox(width: 32),
                _LandingNavLink(label: 'Intelligence'),
                SizedBox(width: 24),
              ],
              if (isDesktop) ...[
                const _GlassButton(
                  label: 'Watch Demo',
                  icon: Icons.play_circle_outline_rounded,
                ),
                const SizedBox(width: 12),
                _GradientButton(
                  label: 'Get Started',
                  compact: true,
                  onTap: () => _goSignIn(context),
                ),
              ] else
                IconButton(
                  onPressed: () => _goSignIn(context),
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Color(0xFFDDE2F8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopHero extends StatelessWidget {
  const _DesktopHero();

  @override
  Widget build(BuildContext context) {
    return _LandingSection(
      top: 128,
      bottom: 128,
      child: Column(
        children: [
          const _StatusPill(label: 'AI-POWERED FLOW STATE'),
          const SizedBox(height: 28),
          const Text.rich(
            TextSpan(
              text: 'Master your focus with\n',
              children: [
                TextSpan(
                  text: 'machine intelligence.',
                  style: TextStyle(color: Color(0xFFC0C1FF)),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFDDE2F8),
              fontSize: 72,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.2,
            ),
          ),
          const SizedBox(height: 28),
          const SizedBox(
            width: 720,
            child: Text(
              'The premium productivity command center for high-performing professionals. Eliminate friction, automate scheduling, and enter deep work faster with TaskFlow AI.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFC7C4D7),
                fontSize: 18,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: [
              _GradientButton(
                label: 'Get Started Free',
                onTap: () => _goSignIn(context),
              ),
              const _GlassButton(
                label: 'Watch Demo',
                icon: Icons.play_circle_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 80),
          const SizedBox(width: double.infinity, child: _DesktopPreviewCard()),
        ],
      ),
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 96, 24, 64),
      child: Column(
        children: [
          const Text.rich(
            TextSpan(
              text: 'Focus at the\n',
              children: [
                TextSpan(
                  text: 'speed of thought.',
                  style: TextStyle(
                    color: Color(0xFFC0C1FF),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFDDE2F8),
              fontSize: 32,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 330,
            child: Text(
              'TaskFlow AI streamlines your mental cycles by automating deep work logistics.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFC7C4D7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 36),
          _GradientButton(
            label: 'Get Started',
            onTap: () => _goSignIn(context),
          ),
          const SizedBox(height: 56),
          const _MobilePreviewCard(),
        ],
      ),
    );
  }
}

class _DesktopPreviewCard extends StatelessWidget {
  const _DesktopPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: NexusColors.primary.withValues(alpha: 0.20),
                blurRadius: 44,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuB6jL30XEV5SBz8WHOPFvHgBzOjDSOJ6gzSdpz0oSUX3dyK0eorDpDbF1M76gRH3s8nWQKbZVW2d8J1hFf2giRU7xmp9Fw4jkdfVIYHCCq8dUoxWYxdormHPjeEn7Y1CQYPDRDp9v1WiH2GHn9z46Y_QYqqWzO7hDEBTJxn_u9mcGAz46DnCbTO6MYKnf7d7snLZEwYUVFbhvXvyGTog3KJ-Cm1wcSNs4oIn3-2G3Qpxprl-tTqFD2ff4J0R9Wepo5Ci6DApjj57UZv',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: 48,
          right: 48,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: NexusColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              children: [
                _PulseDot(),
                SizedBox(width: 10),
                Text(
                  'AI FOCUS MODE ACTIVE',
                  style: TextStyle(
                    color: Color(0xFFDDE2F8),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobilePreviewCard extends StatelessWidget {
  const _MobilePreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SizedBox(
          height: 430,
          child: Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuC9EMQo5LCiU19k6tqO5cjc7YWbi_fHFsOVZ4UnQUM1psvLqmFWWc4C0lkmEwPaJrOojjSdIneHHTMX8uIGaYK-Z98DNF0jUV09HrpdrdiE-ZEPvYEjc947SJtrTIE6SZ3G5AJRmaIt5YCBioG4Ci27NVu20Hrkha6ALswMqChKTnCIhkl5oOhoUtqsX-Z-UStMi53hepd0K7AEv4h6EqV318F_G3ItcDg7jnVXs_vStberX5IyH8My_Yd8l7PfvFp9NcydIWtbfGoX',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
      ),
    );
  }
}

class _SocialProofSection extends StatelessWidget {
  const _SocialProofSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: const Color(0xFF080E1D).withValues(alpha: 0.5),
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: const Column(
        children: [
          Text(
            'TRUSTED BY ENGINEERS AT',
            style: TextStyle(
              color: Color(0xFF908FA0),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.4,
            ),
          ),
          SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 72,
            runSpacing: 22,
            children: [
              _LogoText('GOOGLE'),
              _LogoText('GITHUB'),
              _LogoText('STRIPE'),
              _LogoText('VERCEL'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopFeaturesSection extends StatelessWidget {
  const _DesktopFeaturesSection();

  @override
  Widget build(BuildContext context) {
    return _LandingSection(
      top: 128,
      bottom: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Engineered for deep work.',
            style: TextStyle(
              color: Color(0xFFDDE2F8),
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14),
          SizedBox(
            width: 560,
            child: Text(
              'Every feature is designed to reduce your cognitive load and maximize your creative output.',
              style: TextStyle(
                color: Color(0xFFC7C4D7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 64),
          Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  icon: Icons.psychology_rounded,
                  title: 'Deep Work Detection',
                  body:
                      'TaskFlow monitors digital patterns to silence notifications during peak focus periods.',
                  color: Color(0xFFC0C1FF),
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: _FeatureCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Intelligent Scheduling',
                  body:
                      'Reorganizes your calendar based on priority, energy levels, and upcoming deadlines.',
                  color: Color(0xFFDDB7FF),
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: _FeatureCard(
                  icon: Icons.sync_rounded,
                  title: 'Ecosystem Sync',
                  body:
                      'Native integrations unify Slack, Jira, GitHub, and Figma under one intelligent engine.',
                  color: Color(0xFFADC6FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileValueProps extends StatelessWidget {
  const _MobileValueProps();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 80),
      child: Column(
        children: [
          _FeatureCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Predictive Focus',
            body:
                'AI suggests the optimal time for deep work based on your rhythms and past performance.',
            color: Color(0xFFC0C1FF),
          ),
          SizedBox(height: 24),
          _FeatureCard(
            icon: Icons.layers_rounded,
            title: 'Contextual Ghosting',
            body:
                'Hide non-essential notifications by understanding your current task context.',
            color: Color(0xFFDDB7FF),
          ),
          SizedBox(height: 24),
          _FeatureCard(
            icon: Icons.bolt_rounded,
            title: 'Atomic Execution',
            body:
                'Break complex goals into AI-generated sub-tasks aligned with your time blocks.',
            color: Color(0xFFADC6FF),
          ),
        ],
      ),
    );
  }
}

class _DesktopTestimonialSection extends StatelessWidget {
  const _DesktopTestimonialSection();

  @override
  Widget build(BuildContext context) {
    return _LandingSection(
      top: 48,
      bottom: 96,
      child: const _TestimonialCard(desktop: true),
    );
  }
}

class _MobileTestimonial extends StatelessWidget {
  const _MobileTestimonial();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 80),
      child: _TestimonialCard(desktop: false),
    );
  }
}

class _MobileIntegrations extends StatelessWidget {
  const _MobileIntegrations();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 80),
      child: Column(
        children: [
          Text(
            'UNIFIED WITH YOUR ECOSYSTEM',
            style: TextStyle(
              color: Color(0xFF908FA0),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LogoText('SLACK'),
              _LogoText('GOOGLE'),
              _LogoText('NOTION'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinalCtaSection extends StatelessWidget {
  const _FinalCtaSection();

  @override
  Widget build(BuildContext context) {
    return _LandingSection(
      top: 64,
      bottom: 96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 72),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF151B2B), Color(0xFF0D1322)],
          ),
          borderRadius: BorderRadius.circular(48),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            const Text(
              'Ready to reclaim your time?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFDDE2F8),
                fontSize: 56,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.6,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 620,
              child: Text(
                'Join 50,000+ high-performers who have optimized their lives with TaskFlow AI. Start your free trial today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFC7C4D7),
                  fontSize: 18,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 40),
            _GradientButton(
              label: 'Get Started Free',
              icon: Icons.arrow_forward_rounded,
              onTap: () => _goSignIn(context),
            ),
            const SizedBox(height: 20),
            const Text(
              'No credit card required. Cancel anytime.',
              style: TextStyle(color: Color(0xFF908FA0), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingFooter extends StatelessWidget {
  const _LandingFooter();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: isDesktop ? 80 : 0),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 24,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF080E1D),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child:
              isDesktop
                  ? const _DesktopFooterContent()
                  : const _MobileFooterContent(),
        ),
      ),
    );
  }
}

class _DesktopFooterContent extends StatelessWidget {
  const _DesktopFooterContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _FooterBrand()),
            Expanded(
              child: _FooterLinks(
                title: 'Product',
                items: ['Features', 'Pricing', 'Intelligence'],
                desktopTitleColor: NexusColors.primary,
              ),
            ),
            Expanded(
              child: _FooterLinks(
                title: 'Company',
                items: ['About', 'Security', 'Privacy'],
                desktopTitleColor: NexusColors.primary,
              ),
            ),
            Expanded(child: _FooterSubscribe()),
          ],
        ),
        SizedBox(height: 64),
        _FooterCopyright(center: true),
      ],
    );
  }
}

class _MobileFooterContent extends StatelessWidget {
  const _MobileFooterContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TaskFlow AI',
          style: TextStyle(
            color: Color(0xFFDDE2F8),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FooterLinks(
                title: 'Product',
                items: ['Features', 'Intelligence', 'Pricing'],
              ),
            ),
            Expanded(
              child: _FooterLinks(
                title: 'Company',
                items: ['About', 'Security', 'Privacy'],
              ),
            ),
          ],
        ),
        SizedBox(height: 32),
        _FooterCopyright(center: false),
      ],
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TaskFlow AI',
          style: TextStyle(
            color: Color(0xFFDDE2F8),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: 300,
          child: Text(
            'Engineered for deep work. The ultimate productivity platform for the modern professional.',
            style: TextStyle(
              color: Color(0xFFC7C4D7),
              height: 1.5,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterSubscribe extends StatelessWidget {
  const _FooterSubscribe();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUBSCRIBE',
            style: TextStyle(
              color: NexusColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(
                    color: Color(0xFFDDE2F8),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    hintStyle: const TextStyle(
                      color: Color(0xFF908FA0),
                      fontSize: 14,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFF0D1322).withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      borderSide: BorderSide(
                        color: NexusColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: NexusColors.primary,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Join',
                  style: TextStyle(
                    color: Color(0xFF1000A9),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterCopyright extends StatelessWidget {
  const _FooterCopyright({required this.center});

  final bool center;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 32),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Text(
        center
            ? '© 2024 TaskFlow AI. Engineered for deep work.'
            : '© 2024 TaskFlow AI.\nEngineered for deep work.',
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          color: Color(0xFFC7C4D7),
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}

class _LandingSection extends StatelessWidget {
  const _LandingSection({required this.child, this.top = 0, this.bottom = 0});

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(32, top, 32, bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: child,
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(28),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFDDE2F8),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFFC7C4D7),
              fontSize: 16,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.desktop});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 360;

    return _GlassPanel(
      padding: EdgeInsets.all(desktop ? 48 : (isNarrow ? 24 : 32)),
      radius: desktop ? 48 : 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: NexusColors.primary.withValues(alpha: 0.55),
            size: desktop ? 64 : 42,
          ),
          const SizedBox(height: 20),
          Text(
            desktop
                ? '“TaskFlow AI changed how our engineering team operates. We have seen a 40% increase in sprint completion rates since AI started managing our focus blocks.”'
                : '“TaskFlow AI is the first tool that actually respects my mental state. It manages my attention.”',
            style: TextStyle(
              color: const Color(0xFFDDE2F8),
              fontSize: desktop ? 28 : 22,
              height: 1.35,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _AvatarMark(desktop: desktop),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marcus Thorne',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFDDE2F8),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'CTO at TechFlow Systems',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFC7C4D7),
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: NexusColors.primary.withValues(alpha: 0.08),
            blurRadius: 28,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    this.icon,
    this.compact = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC0C1FF), Color(0xFFDDB7FF)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: NexusColors.primary.withValues(alpha: 0.22),
              blurRadius: 24,
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 24 : 36,
              vertical: compact ? 12 : 18,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF1000A9),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 10),
                  Icon(icon, color: const Color(0xFF1000A9), size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: const Color(0xFFDDE2F8)),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFDDE2F8),
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

class _LandingNavLink extends StatelessWidget {
  const _LandingNavLink({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: active ? NexusColors.primary : const Color(0xFFC7C4D7),
        fontWeight: active ? FontWeight.w900 : FontWeight.w600,
        fontSize: 16,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NexusColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: NexusColors.primary, size: 15),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: NexusColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoText extends StatelessWidget {
  const _LogoText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0x99DDE2F8),
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks({
    required this.title,
    required this.items,
    this.desktopTitleColor,
  });

  final String title;
  final List<String> items;
  final Color? desktopTitleColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: desktopTitleColor ?? const Color(0x80908FA0),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                item,
                style: const TextStyle(color: Color(0xFFC7C4D7), fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarMark extends StatelessWidget {
  const _AvatarMark({required this.desktop});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: desktop ? 64 : 48,
      height: desktop ? 64 : 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: NexusColors.primary.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Image.network(
          desktop
              ? 'https://lh3.googleusercontent.com/aida-public/AB6AXuBNIw_BxAnbCE3OcxvBkfXgUPGWSmBgP3f0u1bV_P5bORchnWWXerbRYx0LRBOig2XfsjWsAZ39-w9jQauE_27AL-DK70hKzZnkh4M7prdoXKLegf3pV10T5AideKqpLRQIhsHBtjRmG7mb1Rf2zr9lTuGAony8gBb_4zJ3VhBTbzGYrSNA_ABGgpKDW3orNirD1TW795D03qW7Xc_sxtIRhqNO26I7v9ca54CLOB4WvWokkkJHbTX7YJu2kDOJAUUqkuUJQWoHFXQZ'
              : 'https://lh3.googleusercontent.com/aida-public/AB6AXuDhptjq-2ecb7hH2q_O3gHw9SUY5j9UtcACqRQcWoDrX_5mcvbPHQMh5YQWd5OW_APd9vXnMweIgn7FI1xJU5oEyjsJUMhl-dWT_0kBstMbYtlT-xZqspwsMDBn8anZlogx1gDph62UEYWZ-9tcACa5NX1pQJ2WTUg7oklrPhTsSOkCrxL2mjtythCnW2a-DMOoYBmfPOLLqL0ZdJPAZjDOxFGqdF2IdKsc7iSPpdifdRf-uI-Eo-XXV4vluhf6t1Hf1xE5ou8DvTq7',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: NexusColors.primary,
        boxShadow: [
          BoxShadow(
            color: NexusColors.primary.withValues(alpha: 0.65),
            blurRadius: 14,
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 80)],
      ),
    );
  }
}

void _goSignIn(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const SignInPage()));
}
