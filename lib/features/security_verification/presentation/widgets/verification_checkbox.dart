import 'dart:math' as math;

import 'package:flutter/material.dart';

enum VerificationCheckboxState { idle, loading, success, failed }

class VerificationCheckbox extends StatefulWidget {
  const VerificationCheckbox({
    required this.state,
    required this.onPressed,
    super.key,
  });

  final VerificationCheckboxState state;
  final VoidCallback onPressed;

  @override
  State<VerificationCheckbox> createState() => _VerificationCheckboxState();
}

class _VerificationCheckboxState extends State<VerificationCheckbox>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pressController;
  late final AnimationController _successController;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.95,
      upperBound: 1,
      value: 1,
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    if (widget.state == VerificationCheckboxState.loading) {
      _rotationController.repeat();
    }
    if (widget.state == VerificationCheckboxState.success) {
      _successController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant VerificationCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == VerificationCheckboxState.loading) {
      _successController.reset();
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    if (oldWidget.state == VerificationCheckboxState.loading &&
        widget.state == VerificationCheckboxState.success) {
      _rotationController.reset();
      _successController.forward(from: 0);
    } else if (widget.state != VerificationCheckboxState.success &&
        widget.state != VerificationCheckboxState.loading) {
      _successController.reset();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pressController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.state == VerificationCheckboxState.loading) return;
    widget.onPressed();
    await _pressController.reverse();
    await _pressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final success = widget.state == VerificationCheckboxState.success;
    final failed = widget.state == VerificationCheckboxState.failed;
    final borderColor = success
        ? const Color(0xFF34C759)
        : failed
            ? const Color(0xFFEF4444)
            : const Color(0xFFBFC8D8);

    return Semantics(
      button: true,
      checked: success,
      label: 'I am not a robot verification checkbox',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.state == VerificationCheckboxState.loading ? null : _handleTap,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pressController, _successController]),
            builder: (context, child) {
              final hoverScale = _hovered && widget.state == VerificationCheckboxState.idle ? 1.05 : 1.0;
              final successScale = widget.state == VerificationCheckboxState.success
                  ? TweenSequence<double>([
                      TweenSequenceItem(
                        tween: Tween(begin: 0.8, end: 1.15).chain(CurveTween(curve: Curves.easeOutBack)),
                        weight: 65,
                      ),
                      TweenSequenceItem(
                        tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
                        weight: 35,
                      ),
                    ]).transform(_successController.value)
                  : 1.0;

              final loading = widget.state == VerificationCheckboxState.loading;

              return SizedBox.square(
                dimension: 56,
                child: Center(
                  child: Transform.scale(
                    scale: _pressController.value * hoverScale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: loading ? 32 : 38,
                      height: loading ? 32 : 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: loading ? null : Border.all(color: borderColor, width: 2),
                        boxShadow: [
                          if (success)
                            BoxShadow(
                              color: const Color(0xFF34C759).withValues(alpha: 0.22),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(opacity: animation, child: child),
                          );
                        },
                        child: switch (widget.state) {
                          VerificationCheckboxState.idle => const SizedBox.shrink(key: ValueKey('idle')),
                          VerificationCheckboxState.loading => AnimatedBuilder(
                              key: const ValueKey('loading'),
                              animation: _rotationController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotationController.value * math.pi * 2,
                                  child: CustomPaint(
                                    size: const Size.square(30),
                                    painter: _RecaptchaSpinnerPainter(
                                      phase: _rotationController.value,
                                    ),
                                  ),
                                );
                              },
                            ),
                          VerificationCheckboxState.success => Transform.scale(
                              key: const ValueKey('success'),
                              scale: successScale,
                              child: const Icon(
                                Icons.check,
                                color: Color(0xFF34C759),
                                size: 34,
                                weight: 900,
                              ),
                            ),
                          VerificationCheckboxState.failed => const Icon(
                              Icons.close_rounded,
                              key: ValueKey('failed'),
                              color: Color(0xFFEF4444),
                              size: 30,
                            ),
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecaptchaSpinnerPainter extends CustomPainter {
  const _RecaptchaSpinnerPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF4A90E2).withValues(alpha: 0.18);
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF4A90E2);

    final arcRect = rect.deflate(2);
    canvas.drawArc(arcRect, 0, math.pi * 2, false, basePaint);

    final sweep = math.pi * (1.08 + math.sin(phase * math.pi * 2).abs() * 0.28);
    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _RecaptchaSpinnerPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}
