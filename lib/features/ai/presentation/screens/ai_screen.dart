import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/shared/widgets/nexus_glass_panel.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final horizontalPadding = constraints.maxWidth >= 760 ? 48.0 : 16.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                40,
                horizontalPadding,
                150,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child:
                      isWide
                          ? const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 4, child: _NexusSideRail()),
                              SizedBox(width: 32),
                              Expanded(flex: 8, child: _NexusMainPanel()),
                            ],
                          )
                          : const Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _NexusSideRail(),
                              SizedBox(height: 24),
                              _NexusMainPanel(),
                            ],
                          ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NexusSideRail extends StatelessWidget {
  const _NexusSideRail();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductivityInsightsCard(),
        SizedBox(height: 24),
        _RoutineCard(),
      ],
    );
  }
}

class _ProductivityInsightsCard extends StatelessWidget {
  const _ProductivityInsightsCard();

  @override
  Widget build(BuildContext context) {
    return const NexusGlassPanel(
      padding: EdgeInsets.all(30),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.insights_rounded,
            label: 'Productivity Insights',
            color: NexusColors.secondary,
          ),
          SizedBox(height: 18),
          _InsightItem(
            icon: Icons.warning_rounded,
            iconColor: NexusColors.error,
            title: 'Burnout risk detected',
            subtitle: 'Schedule a 15-min break soon.',
          ),
          SizedBox(height: 12),
          _InsightItem(
            icon: Icons.bolt_rounded,
            iconColor: NexusColors.secondary,
            title: 'Peak focus hours: 9AM - 11AM',
            subtitle: 'Optimal time for deep work tasks.',
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightItem extends StatelessWidget {
  const _InsightItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: NexusColors.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard();

  @override
  Widget build(BuildContext context) {
    return NexusGlassPanel(
      padding: const EdgeInsets.all(32),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionLabel(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI Routine',
                  color: NexusColors.primary,
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('Edit')),
            ],
          ),
          const SizedBox(height: 24),
          const _RoutineTimeline(),
        ],
      ),
    );
  }
}

class _RoutineTimeline extends StatelessWidget {
  const _RoutineTimeline();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 15,
          top: 10,
          bottom: 10,
          child: Container(
            width: 2,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        const Column(
          children: [
            _RoutineItem(time: '09:00 AM', title: 'Deep Work Session'),
            SizedBox(height: 14),
            _RoutineItem(
              time: '11:15 AM - Current',
              title: 'Review Q3 Architecture',
              active: true,
            ),
            SizedBox(height: 14),
            _RoutineItem(
              time: '01:00 PM',
              title: 'Lunch & Reconnect',
              muted: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _RoutineItem extends StatelessWidget {
  const _RoutineItem({
    required this.time,
    required this.title,
    this.active = false,
    this.muted = false,
  });

  final String time;
  final String title;
  final bool active;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final accent = active ? NexusColors.primary : NexusColors.onSurfaceVariant;

    return Opacity(
      opacity: muted ? 0.62 : 1,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  active
                      ? NexusColors.primaryContainer.withValues(alpha: 0.22)
                      : NexusColors.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: NexusColors.surface, width: 2),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:
                    active
                        ? NexusColors.primaryContainer.withValues(alpha: 0.10)
                        : NexusColors.surfaceContainer.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      active
                          ? NexusColors.primary.withValues(alpha: 0.24)
                          : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color: accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          active ? NexusColors.primary : NexusColors.onSurface,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NexusMainPanel extends StatelessWidget {
  const _NexusMainPanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NexusHeroCard(),
        SizedBox(height: 32),
        _QuickActionsGrid(),
        SizedBox(height: 32),
        _NexusChatCard(),
      ],
    );
  }
}

class _NexusHeroCard extends StatelessWidget {
  const _NexusHeroCard();

  @override
  Widget build(BuildContext context) {
    return NexusGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 56),
      radius: 18,
      borderColor: NexusColors.primary.withValues(alpha: 0.28),
      glowColor: NexusColors.primaryContainer.withValues(alpha: 0.18),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    NexusColors.primaryContainer.withValues(alpha: 0.12),
                    Colors.transparent,
                    NexusColors.tertiary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Column(
            children: [
              const _NexusOrb(),
              const SizedBox(height: 20),
              const _GradientTitle(text: 'Nexus is Ready'),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 520),
                child: Text(
                  'Your contextual AI assistant is actively monitoring your workflow. How can we optimize your afternoon?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: NexusColors.onSurfaceVariant,
                    fontSize: 20,
                    height: 1.6,
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

class _NexusOrb extends StatelessWidget {
  const _NexusOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: NexusColors.surface,
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: NexusColors.primaryContainer.withValues(alpha: 0.30),
            blurRadius: 36,
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback:
            (bounds) => const LinearGradient(
              colors: [NexusColors.primary, NexusColors.tertiary],
            ).createShader(bounds),
        child: const Icon(
          Icons.graphic_eq_rounded,
          color: Colors.white,
          size: 66,
        ),
      ),
    );
  }
}

class _GradientTitle extends StatelessWidget {
  const _GradientTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback:
          (bounds) => const LinearGradient(
            colors: [NexusColors.primary, NexusColors.tertiary],
          ).createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 56,
          fontWeight: FontWeight.w900,
          height: 1.08,
          letterSpacing: -1.6,
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 1;
        const spacing = 16.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              const [
                _QuickActionCard(
                  icon: Icons.call_split_rounded,
                  title: 'Break Down Task',
                  subtitle: 'Split complex goals into actionable sub-tasks.',
                  accent: NexusColors.primary,
                ),
                _QuickActionCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Optimize Schedule',
                  subtitle: 'Rearrange events for maximum focus time.',
                  accent: NexusColors.secondary,
                ),
                _QuickActionCard(
                  icon: Icons.school_rounded,
                  title: 'Build Study Plan',
                  subtitle: 'Generate a spaced-repetition curriculum.',
                  accent: NexusColors.tertiary,
                ),
              ].map((child) => SizedBox(width: width, child: child)).toList(),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return NexusGlassPanel(
      padding: EdgeInsets.zero,
      radius: 16,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: NexusColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: NexusColors.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NexusChatCard extends StatelessWidget {
  const _NexusChatCard();

  @override
  Widget build(BuildContext context) {
    return NexusGlassPanel(
      padding: EdgeInsets.zero,
      radius: 18,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: NexusColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Nexus Context Active',
                    style: TextStyle(
                      color: NexusColors.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.open_in_full_rounded, size: 18),
                  tooltip: 'Expand',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ask Nexus to execute a workflow...',
                      filled: true,
                      fillColor: NexusColors.surface.withValues(alpha: 0.82),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 22,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: NexusColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [NexusColors.primaryContainer, Color(0xFF6833EA)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: NexusColors.primaryContainer.withValues(
                          alpha: 0.34,
                        ),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    tooltip: 'Send',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
