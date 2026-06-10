import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/xp/presentation/providers/xp_providers.dart';
import 'package:to_do_app/features/xp/presentation/widgets/xp_level_card.dart'
    show xpLevelTitle;

// ── Colors ────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFFB794F6);
const _kSecondary = Color(0xFF7B6CF6);
const _kCyan = Color(0xFF67E8F9);
const _kMuted = Color(0xFFA8B2D1);

// XP required to start a given level (matches DB formula).
int _xpForLevel(int level) {
  if (level <= 1) return 0;
  final l = level - 1;
  return l * l * 100;
}

// ── Level Up Modal ────────────────────────────────────────────────────────
class LevelUpModal extends ConsumerStatefulWidget {
  const LevelUpModal({super.key, required this.newLevel});
  final int newLevel;

  @override
  ConsumerState<LevelUpModal> createState() => _LevelUpModalState();
}

class _LevelUpModalState extends ConsumerState<LevelUpModal>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _floatAnim;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _opacityAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _floatAnim = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    _entryCtrl.duration = const Duration(milliseconds: 300);
    await _entryCtrl.reverse();
    if (mounted) ref.read(levelUpProvider.notifier).dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;
    final cardWidth = isMobile ? width - 32 : 720.0;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: _dismiss,
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
            const Positioned(
              left: -200,
              top: -200,
              child: _AmbientGlow(
                size: 800,
                opacity: 0.30,
                color: _kPrimary,
                blur: 120,
              ),
            ),
            const Positioned(
              right: -150,
              bottom: -150,
              child: _AmbientGlow(
                size: 600,
                opacity: 0.10,
                color: _kCyan,
                blur: 100,
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: () {},
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: FadeTransition(
                    opacity: _opacityAnim,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: cardWidth,
                        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                      ),
                      child: _AchievementCard(
                        newLevel: widget.newLevel,
                        isMobile: isMobile,
                        floatAnim: _floatAnim,
                        onContinue: _dismiss,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ambient glow ──────────────────────────────────────────────────────────
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.opacity,
    required this.color,
    required this.blur,
  });

  final double size;
  final double opacity;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity),
              blurRadius: blur,
              spreadRadius: blur / 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Achievement card ──────────────────────────────────────────────────────
class _AchievementCard extends ConsumerWidget {
  const _AchievementCard({
    required this.newLevel,
    required this.isMobile,
    required this.floatAnim,
    required this.onContinue,
  });

  final int newLevel;
  final bool isMobile;
  final Animation<double> floatAnim;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final totalXp = profile?.totalXp ?? 0;
    final nextLevelStart = _xpForLevel(newLevel + 1);
    final remainingToNext = (nextLevelStart - totalXp).clamp(0, 1 << 30);

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 48,
            vertical: isMobile ? 32 : 48,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -8,
                right: -8,
                child: Icon(
                  Icons.auto_awesome,
                  size: isMobile ? 32 : 40,
                  color: _kPrimary.withValues(alpha: 0.7),
                ),
              ),
              Positioned(
                bottom: -8,
                left: -8,
                child: Icon(
                  Icons.star,
                  size: isMobile ? 18 : 22,
                  color: _kCyan.withValues(alpha: 0.6),
                ),
              ),
              SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LevelBadge(
                    newLevel: newLevel,
                    isMobile: isMobile,
                    floatAnim: floatAnim,
                  ),
                  SizedBox(height: isMobile ? 24 : 32),
                  _TitleSection(newLevel: newLevel, isMobile: isMobile),
                  SizedBox(height: isMobile ? 16 : 20),
                  _DescriptionText(newLevel: newLevel, isMobile: isMobile),
                  SizedBox(height: isMobile ? 20 : 24),
                  const _UnlockChips(),
                  SizedBox(height: isMobile ? 24 : 32),
                  _ActionButtons(isMobile: isMobile, onContinue: onContinue),
                  SizedBox(height: isMobile ? 16 : 20),
                  _ProgressSection(
                    newLevel: newLevel,
                    totalXp: totalXp,
                    remaining: remainingToNext,
                  ),
                ],
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stubs (replaced by subsequent Edit operations) ────────────────────────
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({
    required this.newLevel,
    required this.isMobile,
    required this.floatAnim,
  });
  final int newLevel;
  final bool isMobile;
  final Animation<double> floatAnim;

  @override
  Widget build(BuildContext context) {
    final size = isMobile ? 160.0 : 192.0;
    return AnimatedBuilder(
      animation: floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, floatAnim.value),
        child: child,
      ),
      child: SizedBox(
        width: size + 80,
        height: size + 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 1.5,
              height: size * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPrimary.withValues(alpha: 0.20),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.20),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
            Transform.rotate(
              angle: 12 * 3.1415926 / 180,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kPrimary, _kSecondary, _kCyan],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kSecondary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'LEVEL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$newLevel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 64 : 80,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.newLevel, required this.isMobile});
  final int newLevel;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.4)),
          ),
          child: const Text(
            'LEVEL UP',
            style: TextStyle(
              color: _kPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [_kPrimary, _kSecondary, _kCyan],
          ).createShader(b),
          child: Text(
            'Level $newLevel Reached',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 32 : 44,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          xpLevelTitle(newLevel),
          style: TextStyle(
            color: _kCyan,
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _DescriptionText extends StatelessWidget {
  const _DescriptionText({required this.newLevel, required this.isMobile});
  final int newLevel;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 24),
      child: Text(
        'Amazing progress.\nYou have reached Level $newLevel and unlocked new productivity milestones.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _kMuted,
          fontSize: isMobile ? 14 : 16,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _UnlockChips extends StatelessWidget {
  const _UnlockChips();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: const [
        _UnlockChip(icon: Icons.psychology_rounded, label: 'Neural Task Sorting'),
        _UnlockChip(icon: Icons.bolt_rounded, label: 'Turbo Workflows'),
      ],
    );
  }
}

class _UnlockChip extends StatelessWidget {
  const _UnlockChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kPrimary, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.isMobile, required this.onContinue});
  final bool isMobile;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _PrimaryButton(label: 'Continue', onTap: onContinue),
      const SizedBox(width: 12, height: 12),
      _GlassButton(
        label: 'Share Achievement',
        icon: Icons.share_rounded,
        onTap: () {},
      ),
    ];
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          )
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: children);
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kPrimary, _kSecondary],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _kSecondary.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.newLevel,
    required this.totalXp,
    required this.remaining,
  });
  final int newLevel;
  final int totalXp;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final levelStart = _xpForLevel(newLevel);
    final levelEnd = _xpForLevel(newLevel + 1);
    final span = (levelEnd - levelStart).clamp(1, 1 << 30);
    final progressInto = (totalXp - levelStart).clamp(0, span);
    final progress = (progressInto / span).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Level ${newLevel + 1} in $remaining XP',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation(_kPrimary),
          ),
        ),
      ],
    );
  }
}
