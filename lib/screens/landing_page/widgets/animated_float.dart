import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedFloat extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;
  final Duration delay;

  const AnimatedFloat({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 6),
    this.offset = 15.0,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedFloat> createState() => _AnimatedFloatState();
}

class _AnimatedFloatState extends State<AnimatedFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0.0, end: widget.offset).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _SineCurve(),
      ),
    );

    if (widget.delay == Duration.zero) {
      _controller.repeat();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SineCurve extends Curve {
  const _SineCurve();

  @override
  double transformInternal(double t) {
    // Standard sine wave from 0 to 1 back to 0
    return math.sin(t * 2.0 * math.pi) * 0.5 + 0.5;
  }
}
