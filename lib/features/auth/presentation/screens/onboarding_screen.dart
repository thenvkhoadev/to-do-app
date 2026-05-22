import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/shared/widgets/nexus_background.dart';
import 'package:to_do_app/shared/widgets/nexus_glass_panel.dart';
import 'package:to_do_app/shared/widgets/nexus_gradient_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 820;

    return Scaffold(
      body: NexusBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Hero(
                      tag: 'nexus-logo',
                      child: Icon(Icons.bubble_chart_rounded, color: NexusColors.primary, size: 48),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Build momentum with AI precision.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, height: 1.05),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Plan deep work, automate task breakdowns, and understand where your focus goes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 17, height: 1.5),
                    ),
                    const SizedBox(height: 34),
                    Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      children: const [
                        Expanded(child: _OnboardingCard(icon: Icons.auto_awesome_rounded, title: 'AI planning', body: 'Turn vague goals into clean action plans.')),
                        SizedBox(width: 16, height: 16),
                        Expanded(child: _OnboardingCard(icon: Icons.track_changes_rounded, title: 'Focus analytics', body: 'See streaks, deep work, admin load, and learning trends.')),
                        SizedBox(width: 16, height: 16),
                        Expanded(child: _OnboardingCard(icon: Icons.calendar_month_rounded, title: 'Calendar flow', body: 'Align events and tasks into a calm daily command center.')),
                      ],
                    ),
                    const SizedBox(height: 34),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: NexusGradientButton(
                        label: 'Enter NexusAI',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => context.go('/login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return NexusGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: NexusColors.secondary, size: 30),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: NexusColors.onSurfaceVariant, height: 1.45)),
        ],
      ),
    );
  }
}
