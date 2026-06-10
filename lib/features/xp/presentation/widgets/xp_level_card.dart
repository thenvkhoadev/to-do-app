import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/xp/domain/xp_leveling.dart' as leveling;

// ── Level title ladder ────────────────────────────────────────────────────────

String xpLevelTitle(int level) {
  const titles = {
    1: 'Beginner',
    2: 'Apprentice',
    3: 'Explorer',
    4: 'Pathfinder',
    5: 'Strategist',
    6: 'Specialist',
    7: 'Expert',
    8: 'Master',
    9: 'Grandmaster',
    10: 'Legend',
  };
  if (level <= 0) return 'Beginner';
  if (level >= 10) return 'Legend';
  return titles[level] ?? 'Legend';
}

int xpLevelFromTotalXp(int totalXp) => leveling.xpLevelFromTotalXp(totalXp);

double xpProgress(int totalXp, int level) {
  final start = leveling.xpRequiredForLevel(level);
  final end = leveling.xpRequiredForLevel(level + 1);
  if (end <= start) return 1.0;
  return ((totalXp - start) / (end - start)).clamp(0.0, 1.0);
}

int xpIntoLevel(int totalXp, int level) {
  return (totalXp - leveling.xpRequiredForLevel(level)).clamp(0, 1 << 30);
}

// ── Colour constants ──────────────────────────────────────────────────────────

const _kBg = Color(0xFF060B18);
const _kSurface = Color(0xFF0E1626);
const _kBorder = Color(0xFF2A3650);
const _kPrimary = Color(0xFFB794F6);
const _kSecondary = Color(0xFF7B6CF6);
const _kCyan = Color(0xFF67E8F9);
const _kOnSurface = Color(0xFFF5F7FF);
const _kMuted = Color(0xFFA8B2D1);

// ── XpLevelCard ───────────────────────────────────────────────────────────────

class XpLevelCard extends ConsumerStatefulWidget {
  const XpLevelCard({super.key});

  @override
  ConsumerState<XpLevelCard> createState() => _XpLevelCardState();
}

class _XpLevelCardState extends ConsumerState<XpLevelCard>
    with TickerProviderStateMixin {
  late AnimationController _barCtrl;
  late AnimationController _xpCtrl;
  late Animation<double> _barAnim;
  late Animation<int> _xpAnim;
  double _lastProgress = 0;
  int _lastTotalXp = 0;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _xpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
    _xpAnim = IntTween(begin: 0, end: 0).animate(_xpCtrl);
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  void _animateTo(double target, int totalXp) {
    final progressChanged = (target - _lastProgress).abs() >= 0.001;
    final xpChanged = totalXp != _lastTotalXp;
    if (!progressChanged && !xpChanged) return;

    if (progressChanged) {
      _barAnim = Tween<double>(
        begin: _lastProgress,
        end: target,
      ).animate(CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic));
      _barCtrl
        ..reset()
        ..forward();
    }
    if (xpChanged) {
      _xpAnim = IntTween(
        begin: _lastTotalXp,
        end: totalXp,
      ).animate(CurvedAnimation(parent: _xpCtrl, curve: Curves.easeOutCubic));
      _xpCtrl
        ..reset()
        ..forward();
    }
    _lastProgress = target;
    _lastTotalXp = totalXp;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    return profileAsync.when(
      loading: () => const _CardShell(child: _LoadingBody()),
      error: (_, __) => const _CardShell(child: _ErrorBody()),
      data: (profile) {
        final totalXp = profile?.totalXp ?? 0;
        final levelState = leveling.xpProgressFromTotalXp(totalXp);
        final level = levelState.level;
        final rank = leveling.xpRankForLevel(level);
        final completedTasks = profile?.completedTasks ?? 0;
        final progress = levelState.progress;
        final xpInto = levelState.xpIntoLevel;
        final xpForNext = levelState.xpForNextLevel;

        _animateTo(progress, totalXp);

        return _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LevelHeader(level: level, rankTitle: rank.title),
              const SizedBox(height: 24),
              _XpProgressSection(
                barAnim: _barAnim,
                xpCountAnim: _xpAnim,
                xpInto: xpInto,
                xpForNext: xpForNext,
                totalXp: totalXp,
              ),
              const SizedBox(height: 28),
              _StatsRow(
                completedTasks: completedTasks,
                totalXp: totalXp,
                level: level,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Card shell (glassmorphism) ────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: _kSurface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder, width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _kSurface.withValues(alpha: 0.9),
                _kBg.withValues(alpha: 0.7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }
}

// ── Loading / error bodies ────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 160,
    child: Center(
      child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
    ),
  );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 80,
    child: Center(
      child: Text(
        'Could not load XP data',
        style: TextStyle(color: _kMuted, fontSize: 13),
      ),
    ),
  );
}

// ── XP progress section ───────────────────────────────────────────────────────

class _XpProgressSection extends StatelessWidget {
  const _XpProgressSection({
    required this.barAnim,
    required this.xpCountAnim,
    required this.xpInto,
    required this.xpForNext,
    required this.totalXp,
  });

  final Animation<double> barAnim;
  final Animation<int> xpCountAnim;
  final int xpInto;
  final int xpForNext;
  final int totalXp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedBuilder(
              animation: xpCountAnim,
              builder:
                  (_, __) => Text(
                    '${xpCountAnim.value} XP',
                    style: const TextStyle(
                      color: _kOnSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            ),
            Text(
              '$xpInto / $xpForNext XP',
              style: const TextStyle(color: _kMuted, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: barAnim,
          builder: (_, __) => _GradientProgressBar(progress: barAnim.value),
        ),
      ],
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final total = constraints.maxWidth;
        final filled = total * progress;
        return Stack(
          children: [
            // Track
            Container(
              height: 8,
              width: total,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Filled portion
            Container(
              height: 8,
              width: filled.clamp(0, total),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kSecondary, _kCyan],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.completedTasks,
    required this.totalXp,
    required this.level,
  });

  final int completedTasks;
  final int totalXp;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell(label: 'Completed Tasks', value: '$completedTasks'),
        _Divider(),
        _StatCell(label: 'Total XP Earned', value: _fmt(totalXp)),
        _Divider(),
        _StatCell(label: 'Current Level', value: '$level'),
        _Divider(),
        _StatCell(label: 'Next Level', value: '${level + 1}'),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return '$n';
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _kOnSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: _kBorder,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

// ── Level header ─────────────────────────────────────────────────────────────

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({required this.level, required this.rankTitle});
  final int level;
  final String rankTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Large level number
        ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [_kPrimary, _kSecondary, _kCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
          child: Text(
            '$level',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEVEL $level',
                style: const TextStyle(
                  color: _kMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                rankTitle,
                style: const TextStyle(
                  color: _kPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
