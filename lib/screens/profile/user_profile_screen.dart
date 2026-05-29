import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
// NexusColors (inline – no external dependency)
// ─────────────────────────────────────────────
abstract class NexusColors {
  static const Color primary = Color(0xFFC0C1FF);
  static const Color secondary = Color(0xFFDDB7FF);
  static const Color tertiary = Color(0xFFADC6FF);
  static const Color background = Color(0xFF0D1322);
  static const Color surface = Color(0xFF0D1322);
  static const Color surfaceContainer = Color(0xFF191F2F);
  static const Color surfaceContainerLow = Color(0xFF151B2B);
  static const Color surfaceContainerHigh = Color(0xFF242A3A);
  static const Color surfaceContainerHighest = Color(0xFF2F3445);
  static const Color surfaceVariant = Color(0xFF2F3445);
  static const Color primaryContainer = Color(0xFF8083FF);
  static const Color secondaryContainer = Color(0xFF6F00BE);
  static const Color onSurface = Color(0xFFDDE2F8);
  static const Color onSurfaceVariant = Color(0xFFC7C4D7);
  static const Color onPrimary = Color(0xFF1000A9);
  static const Color onPrimaryFixed = Color(0xFF07006C);
  static const Color error = Color(0xFFFFB4AB);
  static const Color outlineVariant = Color(0xFF464554);
  static const Color warning = Color(0xFFFFB951);
}

// ─────────────────────────────────────────────
// Main Entry
// ─────────────────────────────────────────────
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        return isDesktop
            ? const _DesktopProfileScreen()
            : const _MobileProfileScreen();
      },
    );
  }
}

class _SupabaseProfile {
  const _SupabaseProfile({
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  final String name;
  final String email;
  final String avatarUrl;

  String get initial =>
      name.trim().isEmpty ? '?' : name.characters.first.toUpperCase();

  static _SupabaseProfile current() {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final email = (user?.email ?? '').trim();
    final name =
        (metadata['full_name'] ??
                metadata['username'] ??
                email.split('@').first)
            .toString()
            .trim();
    final avatarUrl =
        (metadata['avatar_url'] ?? metadata['avatarUrl'] ?? '')
            .toString()
            .trim();

    return _SupabaseProfile(
      name: name.isEmpty ? 'User' : name,
      email: email.isEmpty ? 'No email' : email,
      avatarUrl: avatarUrl,
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({
    required this.avatarUrl,
    required this.initial,
    required this.fontSize,
  });

  final String avatarUrl;
  final String initial;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) =>
                _ProfileInitial(initial: initial, fontSize: fontSize),
      );
    }

    return _ProfileInitial(initial: initial, fontSize: fontSize);
  }
}

class _ProfileInitial extends StatelessWidget {
  const _ProfileInitial({required this.initial, required this.fontSize});

  final String initial;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: NexusColors.surfaceContainerHigh,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: NexusColors.onSurface,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

Future<void> _signOut(BuildContext context) async {
  await Supabase.instance.client.auth.signOut();
  if (context.mounted) context.go('/');
}

// ══════════════════════════════════════════════
// DESKTOP SCREEN  (test.html)
// ══════════════════════════════════════════════
class _DesktopProfileScreen extends StatelessWidget {
  const _DesktopProfileScreen();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: const _DesktopContent(),
        ),
      ),
    );
  }
}

// ── Desktop Main Content ─────────────────────
class _DesktopContent extends StatelessWidget {
  const _DesktopContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _DesktopHeroSection(),
        SizedBox(height: 24),
        _DesktopStatsRow(),
        SizedBox(height: 24),
        _DesktopMilestonesSection(),
        SizedBox(height: 24),
        _DesktopBottomRow(),
      ],
    );
  }
}

// ── Desktop Hero Section ─────────────────────
class _DesktopHeroSection extends StatelessWidget {
  const _DesktopHeroSection();

  @override
  Widget build(BuildContext context) {
    final profile = _SupabaseProfile.current();

    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: NexusColors.primary.withValues(alpha:0.2),
                      width: 4,
                    ),
                    color: NexusColors.surfaceContainer,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _ProfileImage(
                      avatarUrl: profile.avatarUrl,
                      initial: profile.initial,
                      fontSize: 48,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [NexusColors.primary, NexusColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: NexusColors.primary.withValues(alpha:0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        color: NexusColors.onPrimaryFixed,
                        fontSize: 10,
                        letterSpacing: 1,
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      color: NexusColors.onSurface,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _InfoChip(icon: Icons.mail_rounded, label: profile.email),
                      _InfoChip(
                        icon: Icons.location_on_rounded,
                        label: 'San Francisco, CA',
                      ),
                      _InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: 'Joined Sept 2023',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _GradientButton(label: 'EDIT PROFILE', onTap: () {}),
                const SizedBox(width: 16),
                _GlassButton(label: 'LOGOUT', onTap: () => _signOut(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: NexusColors.primary, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: NexusColors.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

// ── Desktop Stats Row (heatmap + pro intel) ──
class _DesktopStatsRow extends StatelessWidget {
  const _DesktopStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Efficiency Landscape (heatmap) – 2/3
        Expanded(
          flex: 2,
          child: _GlassPanel(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Efficiency Landscape',
                        style: TextStyle(
                          color: NexusColors.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Geist',
                        ),
                      ),
                      Row(
                        children: [
                          _LegendDot(
                            color: NexusColors.surfaceContainerHighest,
                          ),
                          const SizedBox(width: 8),
                          _LegendDot(
                            color: NexusColors.primary.withValues(alpha:0.2),
                          ),
                          const SizedBox(width: 8),
                          _LegendDot(
                            color: NexusColors.primary.withValues(alpha:0.4),
                          ),
                          const SizedBox(width: 8),
                          _LegendDot(
                            color: NexusColors.primary.withValues(alpha:0.7),
                          ),
                          const SizedBox(width: 8),
                          _LegendDot(color: NexusColors.primary),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _DesktopHeatmap(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Lacking Focus',
                        style: TextStyle(
                          color: NexusColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Deep Flow State Reached',
                        style: TextStyle(
                          color: NexusColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Pro Intelligence card – 1/3
        Expanded(
          child: _GlassPanel(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Pro Intelligence',
                        style: TextStyle(
                          color: NexusColors.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Geist',
                        ),
                      ),
                      Icon(Icons.bolt_rounded, color: NexusColors.primary),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'AI Token Usage',
                        style: TextStyle(color: NexusColors.onSurfaceVariant),
                      ),
                      Text(
                        '8.2k / 10k',
                        style: TextStyle(
                          color: NexusColors.primary,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: 0.82,
                      minHeight: 8,
                      backgroundColor: NexusColors.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation(
                        NexusColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha:0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'NEXT BILLING CYCLE',
                          style: TextStyle(
                            color: NexusColors.onSurfaceVariant,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Oct 24, 2023',
                          style: TextStyle(
                            color: NexusColors.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NexusColors.primary,
                        foregroundColor: NexusColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'MANAGE SUBSCRIPTION',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopHeatmap extends StatelessWidget {
  const _DesktopHeatmap();

  @override
  Widget build(BuildContext context) {
    final rng = Random(42);
    final cols = List.generate(
      30,
      (_) => List.generate(7, (_) => rng.nextDouble()),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            cols.map((col) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Column(
                  children:
                      col.map((v) {
                        Color c;
                        if (v > 0.7) {
                          c = NexusColors.primary;
                        } else if (v > 0.4) {
                          c = NexusColors.primary.withValues(alpha:0.5);
                        } else {
                          c = NexusColors.surfaceContainerHighest;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              );
            }).toList(),
      ),
    );
  }
}

// ── Desktop Milestones ───────────────────────
class _DesktopMilestonesSection extends StatelessWidget {
  const _DesktopMilestonesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Milestones',
          style: TextStyle(
            color: NexusColors.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w500,
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: const [
            Expanded(
              child: _MilestoneCard(
                icon: Icons.eco_rounded,
                iconColor: NexusColors.primary,
                title: 'Deep Work Pioneer',
                description:
                    'Logged 500+ hours of uninterrupted focused flow sessions.',
                badge: 'UNLOCKED',
                badgeTextColor: NexusColors.primary,
                unlocked: true,
              ),
            ),
            SizedBox(width: 24),
            Expanded(
              child: _MilestoneCard(
                icon: Icons.psychology_rounded,
                iconColor: NexusColors.secondary,
                iconBg: Color(0x1ADDB7FF),
                title: 'AI Whisperer',
                description:
                    'Successfully automated 20+ workflows using TaskFlow AI logic.',
                badge: 'UNLOCKED',
                badgeTextColor: NexusColors.secondary,
                unlocked: true,
              ),
            ),
            SizedBox(width: 24),
            Expanded(
              child: _MilestoneCard(
                icon: Icons.emoji_events_rounded,
                iconColor: NexusColors.tertiary,
                iconBg: Color(0x1AADC6FF),
                title: 'Project Master',
                description:
                    'Complete 5 simultaneous team projects ahead of schedule.',
                badge: '75% PROGRESS',
                badgeTextColor: NexusColors.onSurfaceVariant,
                unlocked: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.icon,
    required this.iconColor,
    this.iconBg,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeTextColor,
    required this.unlocked,
  });

  final IconData icon;
  final Color iconColor;
  final Color? iconBg;
  final String title;
  final String description;
  final String badge;
  final Color badgeTextColor;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.7,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBg ?? iconColor.withValues(alpha:0.1),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: NexusColors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NexusColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: NexusColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontFamily: 'JetBrains Mono',
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

// ── Desktop Bottom Row (focus chart + settings) ──
class _DesktopBottomRow extends StatelessWidget {
  const _DesktopBottomRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Focus Distribution Chart
        Expanded(
          child: _GlassPanel(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Focus Distribution',
                    style: TextStyle(
                      color: NexusColors.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 192,
                        height: 192,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(192, 192),
                              painter: _DonutChartPainter(),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  '62%',
                                  style: TextStyle(
                                    color: NexusColors.onSurface,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                                Text(
                                  'DEEP FLOW',
                                  style: TextStyle(
                                    color: NexusColors.onSurfaceVariant,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    fontFamily: 'JetBrains Mono',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _ChartLegendItem(
                            color: NexusColors.primary,
                            label: 'Deep Work',
                            sub: '62% Efficacy',
                            glow: true,
                          ),
                          SizedBox(height: 16),
                          _ChartLegendItem(
                            color: NexusColors.secondary,
                            label: 'Collaboration',
                            sub: '28% Activity',
                          ),
                          SizedBox(height: 16),
                          _ChartLegendItem(
                            color: NexusColors.surfaceVariant,
                            label: 'Admin',
                            sub: '10% Maintenance',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Settings panels
        Expanded(
          child: Column(
            children: const [
              _DesktopPersonalIdentityCard(),
              SizedBox(height: 24),
              _DesktopSecurityCard(),
              SizedBox(height: 24),
              _DesktopAIPersonaCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 24.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    void drawArc(double start, double sweep, Color color) {
      final paint =
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
    }

    // Background
    drawArc(0, 2 * pi, NexusColors.surfaceContainerHighest);
    const toRad = pi / 180;
    // Deep Work 62%
    drawArc(-90 * toRad + 136.8 * toRad, 0.62 * 2 * pi, NexusColors.primary);
    // Collaboration 28%
    drawArc(-90 * toRad + 36 * toRad, 0.28 * 2 * pi, NexusColors.secondary);
    // Admin 10%
    drawArc(-90 * toRad, 0.10 * 2 * pi, NexusColors.surfaceVariant);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.sub,
    this.glow = false,
  });
  final Color color;
  final String label;
  final String sub;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow:
                glow
                    ? [BoxShadow(color: color.withValues(alpha:0.4), blurRadius: 6)]
                    : null,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: NexusColors.onSurface,
                fontSize: 16,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DesktopPersonalIdentityCard extends StatelessWidget {
  const _DesktopPersonalIdentityCard();

  @override
  Widget build(BuildContext context) {
    final profile = _SupabaseProfile.current();

    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.badge_rounded, color: NexusColors.primary),
                SizedBox(width: 12),
                Text(
                  'Personal Identity',
                  style: TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _IdentityField(
                    label: 'FULL NAME',
                    value: profile.name,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _IdentityField(
                    label: 'ROLE',
                    value: 'Senior Product Strategist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _IdentityField(
                    label: 'DEPARTMENT',
                    value: 'Innovation Labs',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _IdentityField(
                    label: 'TIMEZONE',
                    value: 'UTC-8 (PST)',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityField extends StatelessWidget {
  const _IdentityField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: NexusColors.onSurfaceVariant,
            fontSize: 10,
            letterSpacing: 1.5,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: NexusColors.onSurface, fontSize: 16),
        ),
      ],
    );
  }
}

class _DesktopSecurityCard extends StatelessWidget {
  const _DesktopSecurityCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.security_rounded, color: NexusColors.primary),
                SizedBox(width: 12),
                Text(
                  'Security & Access',
                  style: TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SecurityRow(
              icon: Icons.lock_rounded,
              title: 'Two-Factor Auth',
              subtitle: 'Enabled via Authenticator App',
              trailing: const Icon(
                Icons.check_circle_rounded,
                color: NexusColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            _SecurityRow(
              icon: Icons.key_rounded,
              title: 'API Keys',
              subtitle: '3 Active Keys',
              trailing: Text(
                'VIEW',
                style: TextStyle(
                  color: NexusColors.primary,
                  fontSize: 10,
                  letterSpacing: 1,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: NexusColors.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: NexusColors.onSurface),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: NexusColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _DesktopAIPersonaCard extends StatelessWidget {
  const _DesktopAIPersonaCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.psychology_rounded, color: NexusColors.secondary),
                SizedBox(width: 12),
                Text(
                  'AI Persona',
                  style: TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assistant Tone',
                  style: TextStyle(color: NexusColors.onSurfaceVariant),
                ),
                Row(
                  children: [
                    _ToneChip(label: 'Casual', active: false),
                    const SizedBox(width: 8),
                    _ToneChip(label: 'Executive', active: true),
                    const SizedBox(width: 8),
                    _ToneChip(label: 'Direct', active: false),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Automation Threshold',
                  style: TextStyle(color: NexusColors.onSurfaceVariant),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: NexusColors.secondary,
                          inactiveTrackColor:
                              NexusColors.surfaceContainerHighest,
                          thumbColor: NexusColors.secondary,
                          overlayColor: NexusColors.secondary.withValues(alpha:0.2),
                          trackHeight: 6,
                        ),
                        child: Slider(value: 0.75, onChanged: null),
                      ),
                    ),
                    const Text(
                      '75%',
                      style: TextStyle(
                        color: NexusColors.secondary,
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToneChip extends StatelessWidget {
  const _ToneChip({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color:
            active
                ? NexusColors.secondary.withValues(alpha:0.2)
                : NexusColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border:
            active
                ? Border.all(color: NexusColors.secondary.withValues(alpha:0.3))
                : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? NexusColors.secondary : NexusColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// MOBILE SCREEN  (test1.html)
// ══════════════════════════════════════════════
class _MobileProfileScreen extends StatelessWidget {
  const _MobileProfileScreen();

  // Heatmap data from test1.html (9 columns × 7 rows opacity values)
  static const List<List<double>> _heatData = [
    [0.2, 0.4, 0.1, 0.6, 0.2, 0.8, 0.2],
    [0.3, 0.1, 0.4, 0.2, 0.1, 0.3, 0.1],
    [0.8, 0.9, 0.6, 1.0, 0.8, 0.9, 0.7],
    [0.2, 0.1, 0.3, 0.2, 0.1, 0.2, 0.1],
    [0.4, 0.3, 0.5, 0.4, 0.2, 0.5, 0.3],
    [0.1, 0.2, 0.1, 0.3, 0.1, 0.2, 0.1],
    [0.8, 0.7, 0.9, 0.8, 0.6, 1.0, 0.8],
    [0.2, 0.4, 0.1, 0.6, 0.2, 0.8, 0.2],
    [0.3, 0.1, 0.4, 0.2, 0.1, 0.3, 0.1],
  ];

  @override
  Widget build(BuildContext context) {
    final profile = _SupabaseProfile.current();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header
          Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [NexusColors.primary, NexusColors.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NexusColors.primary.withValues(alpha:0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: _ProfileImage(
                        avatarUrl: profile.avatarUrl,
                        initial: profile.initial,
                        fontSize: 38,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: NexusColors.primary,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: NexusColors.primary.withValues(alpha:0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          'Pro Plan',
                          style: TextStyle(
                            color: NexusColors.onPrimary,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                profile.name,
                style: const TextStyle(
                  color: NexusColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.email,
                style: const TextStyle(
                  color: NexusColors.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Bento
          Column(
            children: [
              _MobileGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deep Work Streak',
                        style: TextStyle(
                          color: NexusColors.primary,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Text(
                            '12 Days',
                            style: TextStyle(
                              color: NexusColors.onSurface,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Geist',
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.local_fire_department,
                            color: NexusColors.secondary,
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MobileGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'TASKS DONE',
                              style: TextStyle(
                                color: NexusColors.onSurfaceVariant,
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '1,284',
                              style: TextStyle(
                                color: NexusColors.onSurface,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MobileGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'FOCUS HOURS',
                              style: TextStyle(
                                color: NexusColors.onSurfaceVariant,
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '452h',
                              style: TextStyle(
                                color: NexusColors.onSurface,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Productivity Heatmap
          _MobileGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Productivity Heatmap',
                        style: TextStyle(
                          color: NexusColors.onSurface,
                          fontSize: 14,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Last 90 Days',
                        style: TextStyle(
                          color: NexusColors.onSurfaceVariant,
                          fontSize: 10,
                          letterSpacing: 1,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                          _heatData.map((col) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Column(
                                children:
                                    col.map((v) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 3,
                                        ),
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: NexusColors.primary
                                                .withValues(alpha:v),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Personal Identity
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'PERSONAL IDENTITY',
                  style: TextStyle(
                    color: NexusColors.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
              _MobileGlassCard(
                child: Column(
                  children: [
                    _MobileIdentityField(
                      label: 'FULL NAME',
                      value: profile.name,
                    ),
                    Divider(color: Colors.white.withValues(alpha:0.05), height: 1),
                    _MobileIdentityField(
                      label: 'EMAIL ADDRESS',
                      value: profile.email,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preferences
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'PREFERENCES',
                  style: TextStyle(
                    color: NexusColors.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
              _MobileGlassCard(
                child: Column(
                  children: [
                    _MobileToggleRow(
                      icon: Icons.notifications_rounded,
                      label: 'Notifications',
                      value: true,
                    ),
                    Divider(color: Colors.white.withValues(alpha:0.05), height: 1),
                    _MobileToggleRow(
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark Mode',
                      value: true,
                    ),
                    Divider(color: Colors.white.withValues(alpha:0.05), height: 1),
                    _MobileToggleRow(
                      icon: Icons.psychology_rounded,
                      label: 'AI Insights',
                      value: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Go Premium Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NexusColors.primaryContainer.withValues(alpha:0.8),
                  NexusColors.secondaryContainer.withValues(alpha:0.8),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha:0.1)),
              boxShadow: [
                BoxShadow(
                  color: NexusColors.primary.withValues(alpha:0.15),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Go Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Geist',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Unlock advanced AI deep work analysis.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0DBFF),
                    foregroundColor: const Color(0xFF2C0051),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Upgrade Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
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

class _MobileGlassCard extends StatelessWidget {
  const _MobileGlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:0.08)),
      ),
      child: child,
    );
  }
}

class _MobileIdentityField extends StatelessWidget {
  const _MobileIdentityField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: NexusColors.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.5,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: NexusColors.onSurface, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _MobileToggleRow extends StatefulWidget {
  const _MobileToggleRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final bool value;

  @override
  State<_MobileToggleRow> createState() => _MobileToggleRowState();
}

class _MobileToggleRowState extends State<_MobileToggleRow> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: NexusColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  color: NexusColors.onSurface,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Switch(
            value: _value,
            activeThumbColor: NexusColors.primary,
            activeTrackColor: NexusColors.primary.withValues(alpha:0.3),
            inactiveTrackColor: NexusColors.surfaceContainer,
            onChanged: (v) => setState(() => _value = v),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha:0.08)),
        boxShadow: [
          BoxShadow(
            color: NexusColors.primary.withValues(alpha:0.05),
            blurRadius: 30,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              NexusColors.primaryContainer,
              NexusColors.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: NexusColors.primary.withValues(alpha:0.15),
              blurRadius: 12,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            letterSpacing: 2,
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: NexusColors.error.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: NexusColors.error.withValues(alpha: 0.28)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: NexusColors.error,
            fontSize: 10,
            letterSpacing: 2,
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
