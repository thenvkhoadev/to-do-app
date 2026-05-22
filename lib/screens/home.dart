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
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PageBackground(),
        SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _TopBar()),
              SliverToBoxAdapter(
                child: _ResponsiveSection(
                  child: Column(
                    children: const [
                      _HeroSection(),
                      _FeatureSection(),
                      _TestimonialSection(),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: _Footer()),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResponsiveSection extends StatelessWidget {
  const _ResponsiveSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 1024 ? 48.0 : 16.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 16, vertical: 16),
      decoration: BoxDecoration(
        color: NexusColors.surface.withOpacity(0.82),
        border: Border(
          bottom: BorderSide(
            color: NexusColors.outlineVariant.withOpacity(0.24),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bubble_chart_rounded,
            color: NexusColors.primary,
            size: 30,
          ),
          const SizedBox(width: 8),
          const Text(
            'Nexus AI',
            style: TextStyle(
              color: NexusColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          if (isWide) ...const [
            _NavLink(label: 'Product', active: true),
            SizedBox(width: 24),
            _NavLink(label: 'Solutions'),
            SizedBox(width: 24),
            _NavLink(label: 'Pricing'),
            SizedBox(width: 24),
          ],
          _GradientButton(
            label: 'Get Started',
            compact: true,
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignInPage()),
                ),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: active ? NexusColors.primary : NexusColors.onSurfaceVariant,
        fontSize: 14,
        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
        letterSpacing: 0.7,
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 920;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child:
          isWide
              ? const Row(
                children: [
                  Expanded(child: _HeroCopy()),
                  SizedBox(width: 40),
                  Expanded(child: _HeroVisual()),
                ],
              )
              : const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_HeroCopy(), SizedBox(height: 40), _HeroVisual()],
              ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StatusPill(),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            text: 'Your Premium\n',
            children: [
              WidgetSpan(
                child: _GradientText(
                  'Productivity Companion',
                  style: TextStyle(
                    fontSize: isWide ? 48 : 34,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          style: TextStyle(
            color: NexusColors.onSurface,
            fontSize: isWide ? 48 : 34,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Master your flow with AI-driven task management, deep work optimization, and seamless context switching. Built for visionaries.',
            style: TextStyle(
              color: NexusColors.onSurfaceVariant,
              fontSize: 18,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _GradientButton(
              label: 'Get Started Free',
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                  ),
            ),
            const _GlassButton(
              label: 'Watch Demo',
              icon: Icons.play_circle_outline_rounded,
            ),
          ],
        ),
        const SizedBox(height: 40),
        Container(
          height: 1,
          width: 360,
          color: NexusColors.outlineVariant.withOpacity(0.35),
        ),
        const SizedBox(height: 16),
        const Text(
          'TRUSTED BY INNOVATIVE TEAMS',
          style: TextStyle(
            color: NexusColors.outline,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: const [
            _LogoChip(icon: Icons.api_rounded, label: 'Vertex'),
            _LogoChip(icon: Icons.layers_rounded, label: 'Synapse'),
            _LogoChip(icon: Icons.all_inclusive_rounded, label: 'Infinity'),
          ],
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return const _GlassPanel(
      borderRadius: 999,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: NexusColors.secondary, size: 18),
          SizedBox(width: 8),
          Text(
            'NEXUS ENGINE V2.0 LIVE',
            style: TextStyle(
              color: NexusColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: _GlassPanel(
        padding: EdgeInsets.zero,
        borderRadius: 20,
        glowColor: NexusColors.primaryContainer.withOpacity(0.32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.1, -0.25),
                      radius: 1.0,
                      colors: [
                        NexusColors.primaryContainer.withOpacity(0.72),
                        NexusColors.secondaryContainer.withOpacity(0.34),
                        NexusColors.surfaceLow,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _OrbitalPainter())),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: _GlassPanel(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _IconTile(
                        icon: Icons.auto_awesome_rounded,
                        color: NexusColors.secondary,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Deep Work Achieved',
                              style: TextStyle(
                                color: NexusColors.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Nexus optimized your schedule, saving 2.4 hours today.',
                              style: TextStyle(
                                color: NexusColors.onSurfaceVariant,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 860;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          const Text(
            'Engineered for Focus',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: NexusColors.onSurface,
              fontSize: 32,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'Abandon the clutter. Nexus AI structures your workload with crystalline precision.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 18,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 40),
          if (isWide)
            const _DesktopFeatureGrid()
          else
            const _MobileFeatureList(),
        ],
      ),
    );
  }
}

class _DesktopFeatureGrid extends StatelessWidget {
  const _DesktopFeatureGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _TaskBreakdownCard()),
            SizedBox(width: 24),
            Expanded(
              child: _FeatureCard(
                icon: Icons.bar_chart_rounded,
                color: NexusColors.secondary,
                title: 'Focus Analytics',
                body:
                    'Real-time telemetry on your cognitive flow. Understand when you peak.',
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.hub_rounded,
                color: NexusColors.tertiary,
                title: 'Seamless Integrations',
                body:
                    'Syncs silently with your existing stack. No friction, pure output.',
              ),
            ),
            SizedBox(width: 24),
            Expanded(flex: 2, child: _FlowStateCard()),
          ],
        ),
      ],
    );
  }
}

class _MobileFeatureList extends StatelessWidget {
  const _MobileFeatureList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _TaskBreakdownCard(),
        SizedBox(height: 16),
        _FeatureCard(
          icon: Icons.bar_chart_rounded,
          color: NexusColors.secondary,
          title: 'Focus Analytics',
          body:
              'Real-time telemetry on your cognitive flow. Understand when you peak.',
        ),
        SizedBox(height: 16),
        _FeatureCard(
          icon: Icons.hub_rounded,
          color: NexusColors.tertiary,
          title: 'Seamless Integrations',
          body:
              'Syncs silently with your existing stack. No friction, pure output.',
        ),
        SizedBox(height: 16),
        _FlowStateCard(),
      ],
    );
  }
}

class _TaskBreakdownCard extends StatelessWidget {
  const _TaskBreakdownCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      minHeight: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(
                icon: Icons.account_tree_rounded,
                color: NexusColors.primary,
              ),
              SizedBox(height: 16),
              Text(
                'AI Task Breakdown',
                style: TextStyle(
                  color: NexusColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Input a massive project, and watch Nexus fracture it into actionable, hyper-specific micro-tasks instantly.',
                style: TextStyle(
                  color: NexusColors.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.55,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 96,
            child: CustomPaint(
              painter: _BarPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      minHeight: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: icon, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: NexusColors.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: NexusColors.onSurfaceVariant,
              fontSize: 16,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(
              icon,
              color: NexusColors.onSurfaceVariant.withOpacity(0.18),
              size: 64,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStateCard extends StatelessWidget {
  const _FlowStateCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      minHeight: 300,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.self_improvement_rounded,
              color: NexusColors.primary,
              size: 52,
            ),
            SizedBox(height: 16),
            Text(
              'Enter The Flow State',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: NexusColors.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Nexus silences notifications and orchestrates your environment when it detects deep work patterns.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 16,
                height: 1.55,
              ),
            ),
            SizedBox(height: 24),
            _TextAction(label: 'Explore Focus Mode'),
          ],
        ),
      ),
    );
  }
}

class _TestimonialSection extends StatelessWidget {
  const _TestimonialSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: _GlassPanel(
          padding: const EdgeInsets.all(40),
          borderRadius: 24,
          glowColor: NexusColors.primaryContainer.withOpacity(0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '“Nexus does not just manage my tasks; it manages my cognitive load. The UI is so clean it almost disappears, leaving only the work that matters. It is like having a brilliant, silent partner.”',
                style: TextStyle(
                  color: NexusColors.onSurface,
                  fontSize: 24,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: NexusColors.surfaceContainerHighest,
                    child: Icon(
                      Icons.person_rounded,
                      color: NexusColors.primary,
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Elias Thorne',
                        style: TextStyle(
                          color: NexusColors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Lead Architect, Quantum Dynamics',
                        style: TextStyle(
                          color: NexusColors.onSurfaceVariant,
                          fontSize: 12,
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
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 16, vertical: 56),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E17),
        border: Border(
          top: BorderSide(color: NexusColors.outlineVariant.withOpacity(0.18)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 24,
            children: const [
              _FooterBrand(),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _NavLink(label: 'Features'),
                  _NavLink(label: 'Pricing'),
                  _NavLink(label: 'Security'),
                  _NavLink(label: 'Privacy'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bubble_chart_rounded,
              color: NexusColors.primary,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Nexus AI',
              style: TextStyle(
                color: NexusColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          '© 2024 Nexus AI. Precision in every prompt.',
          style: TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 14),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, this.compact = false, this.onTap});

  final String label;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              NexusColors.primaryContainer,
              NexusColors.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: NexusColors.primaryContainer.withOpacity(0.28),
              blurRadius: 28,
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 24,
              vertical: compact ? 10 : 16,
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      borderRadius: 12,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: NexusColors.onSurface, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 14,
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

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {},
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: NexusColors.secondary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LogoChip extends StatelessWidget {
  const _LogoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.62,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: NexusColors.onSurface, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: NexusColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NexusColors.outlineVariant.withOpacity(0.35)),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.minHeight,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? minHeight;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding,
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainer.withOpacity(0.72),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(color: glowColor!, blurRadius: 42, spreadRadius: 2),
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback:
          (bounds) => const LinearGradient(
            colors: [NexusColors.primary, NexusColors.secondary],
          ).createShader(bounds),
      child: Text(text, style: style),
    );
  }
}

class _PageBackground extends StatelessWidget {
  const _PageBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: NexusColors.background)),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned(
            top: 120,
            left: MediaQuery.sizeOf(context).width * 0.24,
            child: _BlurOrb(
              size: 520,
              color: NexusColors.primaryContainer.withOpacity(0.22),
            ),
          ),
          Positioned(
            top: 220,
            right: 80,
            child: _BlurOrb(
              size: 360,
              color: NexusColors.secondaryContainer.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 60)],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.03)
          ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrbitalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.52, size.height * 0.42);
    final linePaint =
        Paint()
          ..color = NexusColors.primary.withOpacity(0.32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
    final dotPaint = Paint()..color = NexusColors.secondary.withOpacity(0.9);

    for (var i = 0; i < 9; i++) {
      final radius = 42.0 + i * 24;
      canvas.drawCircle(center, radius, linePaint);
      canvas.drawCircle(
        Offset(center.dx + radius * 0.72, center.dy - radius * 0.36),
        3.5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint =
        Paint()
          ..color = NexusColors.outlineVariant.withOpacity(0.5)
          ..style = PaintingStyle.stroke;
    final fillPaint =
        Paint()..color = NexusColors.surfaceContainerHighest.withOpacity(0.82);
    final activePaint = Paint()..color = NexusColors.primary.withOpacity(0.22);
    final widths = size.width / 4;
    final heights = [0.5, 0.76, 1.0, 0.34];

    for (var i = 0; i < 4; i++) {
      final left = i * widths + 6;
      final top = size.height - (size.height * heights[i]);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, widths - 12, size.height - top),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, i == 1 ? activePaint : fillPaint);
      canvas.drawRRect(rect, borderPaint);
    }

    canvas.drawCircle(
      Offset(widths * 1.5, size.height * 0.18),
      5,
      Paint()..color = NexusColors.primary,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
