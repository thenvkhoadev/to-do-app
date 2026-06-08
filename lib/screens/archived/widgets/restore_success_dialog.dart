import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class RestoreSuccessDialog extends StatefulWidget {
  const RestoreSuccessDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const RestoreSuccessDialog(),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }

  @override
  State<RestoreSuccessDialog> createState() => _RestoreSuccessDialogState();
}

class _RestoreSuccessDialogState extends State<RestoreSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismiss,
      child: Stack(
        children: [
          // Blur backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          // Dialog content (block taps so card itself doesn't dismiss accidentally)
          Center(
            child: Material(
              color: Colors.transparent,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _scaleAnimation.value > 0 ? 1.0 : 0.0,
                      child: child,
                    ),
                  );
                },
                child: _DialogCard(fadeAnimation: _fadeAnimation, ctrl: _ctrl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _DialogCard extends StatelessWidget {
  const _DialogCard({required this.fadeAnimation, required this.ctrl});
  final Animation<double> fadeAnimation;
  final AnimationController ctrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Block taps from propagating to the background
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 320,
          padding: const EdgeInsets.fromLTRB(32, 48, 32, 40),
          decoration: BoxDecoration(
            color: DashboardColors.surface.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: .1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.primary.withValues(alpha: .2),
                blurRadius: 80,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon stack
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow rings
                    AnimatedBuilder(
                      animation: ctrl,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + math.sin(ctrl.value * math.pi) * 0.2,
                          child: Opacity(
                            opacity: (1.0 - ctrl.value).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: DashboardColors.primary.withValues(alpha: .4),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Inner circle
                    AnimatedBuilder(
                      animation: ctrl,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: Curves.easeOutBack.transform((ctrl.value * 2).clamp(0.0, 1.0)),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  DashboardColors.primary,
                                  Color(0xFF6366F1),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DashboardColors.primary.withValues(alpha: .4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.unarchive_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Texts
              AnimatedBuilder(
                animation: fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - fadeAnimation.value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    const Text(
                      'Task Restored',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The task has been successfully restored to your active workspace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
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
