import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DeleteSuccessDialog extends StatefulWidget {
  const DeleteSuccessDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => const DeleteSuccessDialog(),
    );
  }

  @override
  State<DeleteSuccessDialog> createState() => _DeleteSuccessDialogState();
}

class _DeleteSuccessDialogState extends State<DeleteSuccessDialog>
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 320,
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F131E).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: DashboardColors.error.withValues(alpha: 0.12),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated flying file card into open/close trash bin
                  const _TrashAnimation(),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'Đã Xóa Thành Công',
                          style: TextStyle(
                            color: DashboardColors.onSurface,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Công việc đã được xóa bỏ hoàn toàn khỏi danh sách của bạn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 12),
                        _PulseText(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrashAnimation extends StatefulWidget {
  const _TrashAnimation();

  @override
  State<_TrashAnimation> createState() => _TrashAnimationState();
}

class _TrashAnimationState extends State<_TrashAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  
  // Lid animations
  late final Animation<Offset> _lidOffset;
  late final Animation<double> _lidRotation;

  // Card animations
  late final Animation<Offset> _cardOffset;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardRotation;
  late final Animation<double> _cardOpacity;

  // Bin animations (vibration/impact bounce)
  late final Animation<double> _binScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    // 1. Lid Opens and Closes hinge sequences
    _lidOffset = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(-8, -16),
        ),
        weight: 30, // Lid opens 0.0 -> 0.30
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(const Offset(-8, -16)),
        weight: 35, // stays open 0.30 -> 0.65 while card flies in
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-8, -16),
          end: const Offset(0, 0),
        ),
        weight: 20, // Lid shuts 0.65 -> 0.85
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(const Offset(0, 0)),
        weight: 15, // stays shut
      ),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _lidRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.5), // opens hinge
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(-0.5),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.5, end: 0.0), // closes hinge
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 15,
      ),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // 2. Card flies in: starts at 0.2, lands by 0.65
    _cardOffset = Tween<Offset>(
      begin: const Offset(0, -45),
      end: const Offset(0, 8),
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.65, curve: Curves.easeInQuad),
      ),
    );

    _cardScale = Tween<double>(begin: 1.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.65, curve: Curves.easeInQuad),
      ),
    );

    _cardRotation = Tween<double>(begin: 0.0, end: 2.5 * math.pi).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.65, curve: Curves.easeInOutQuad),
      ),
    );

    _cardOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 35),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 35),
    ]).animate(_ctrl);

    // 3. Bin bounce upon card landing and lid slam: 0.65 -> 0.95
    _binScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 65),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.92),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.15),
        weight: 9,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.98),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.0),
        weight: 10,
      ),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Trash Bin container (Body + Lid)
          Positioned(
            bottom: 6,
            child: ScaleTransition(
              scale: _binScale,
              child: AnimatedBuilder(
                animation: _binScale,
                builder: (context, child) {
                  final glowIntensity = (_binScale.value - 1.0).clamp(0.0, 1.0) * 4.0;
                  return Container(
                    width: 90,
                    height: 90,
                    alignment: Alignment.bottomCenter,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        // Glow background
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: DashboardColors.error.withValues(
                                    alpha: 0.15 + (glowIntensity * 0.15),
                                  ),
                                  blurRadius: 20 + (glowIntensity * 12),
                                  spreadRadius: glowIntensity * 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Trash Bin Body
                        Container(
                          width: 46,
                          height: 48,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(8),
                            ),
                            border: Border.all(
                              color: DashboardColors.error,
                              width: 2.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              3,
                              (index) => Container(
                                width: 2.5,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: DashboardColors.error.withValues(
                                    alpha: 0.4,
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Animated Lid
                        Positioned(
                          bottom: 49,
                          child: AnimatedBuilder(
                            animation: _ctrl,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: _lidOffset.value,
                                child: Transform.rotate(
                                  angle: _lidRotation.value,
                                  origin: const Offset(-20, 0), // hinge on left side
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Handle
                                      Container(
                                        width: 14,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: DashboardColors.error,
                                          borderRadius:
                                              BorderRadius.vertical(
                                            top: Radius.circular(2),
                                          ),
                                        ),
                                      ),
                                      // Lid main bar
                                      Container(
                                        width: 54,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: DashboardColors.error,
                                          borderRadius:
                                              BorderRadius.circular(2.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          // The Flying File Card
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              if (_cardOpacity.value <= 0.0) return const SizedBox.shrink();
              return Transform.translate(
                offset: _cardOffset.value,
                child: Transform.rotate(
                  angle: _cardRotation.value,
                  child: Transform.scale(
                    scale: _cardScale.value,
                    child: Opacity(
                      opacity: _cardOpacity.value,
                      child: Container(
                        width: 44,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 28,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              width: 25,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              width: 16,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: DashboardColors.error.withValues(
                                        alpha: 0.7,
                                      ),
                                      width: 1.2,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PulseText extends StatefulWidget {
  @override
  State<_PulseText> createState() => _PulseTextState();
}

class _PulseTextState extends State<_PulseText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.35, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const Text(
        'Chạm vào bất kỳ để thoát',
        style: TextStyle(
          color: DashboardColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class DeleteAllSuccessDialog extends StatefulWidget {
  final int count;
  const DeleteAllSuccessDialog({required this.count, super.key});

  static Future<void> show(BuildContext context, int count) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => DeleteAllSuccessDialog(count: count),
    );
  }

  @override
  State<DeleteAllSuccessDialog> createState() => _DeleteAllSuccessDialogState();
}

class _DeleteAllSuccessDialogState extends State<DeleteAllSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 320,
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F131E).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: DashboardColors.error.withValues(alpha: 0.12),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _MultipleTrashAnimation(),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'Đã Xóa Tất Cả Thành Công',
                          style: TextStyle(
                            color: DashboardColors.onSurface,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Đã xóa bỏ hoàn toàn ${widget.count} công việc khỏi danh sách của bạn.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 12),
                        _PulseText(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MultipleTrashAnimation extends StatefulWidget {
  const _MultipleTrashAnimation();

  @override
  State<_MultipleTrashAnimation> createState() => _MultipleTrashAnimationState();
}

class _MultipleTrashAnimationState extends State<_MultipleTrashAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  
  // Lid animations
  late final Animation<Offset> _lidOffset;
  late final Animation<double> _lidRotation;

  // Staggered card animations for 3 cards
  // Card 1
  late final Animation<Offset> _cardOffset1;
  late final Animation<double> _cardScale1;
  late final Animation<double> _cardRotation1;
  late final Animation<double> _cardOpacity1;

  // Card 2
  late final Animation<Offset> _cardOffset2;
  late final Animation<double> _cardScale2;
  late final Animation<double> _cardRotation2;
  late final Animation<double> _cardOpacity2;

  // Card 3
  late final Animation<Offset> _cardOffset3;
  late final Animation<double> _cardScale3;
  late final Animation<double> _cardRotation3;
  late final Animation<double> _cardOpacity3;

  // Bin vibrations
  late final Animation<double> _binScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    // Lid sequence:
    // 0.0 -> 0.15: opens
    // 0.15 -> 0.75: stays open for all cards to enter
    // 0.75 -> 0.88: closes
    // 0.88 -> 1.0: remains closed
    _lidOffset = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(-8, -16),
        ),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(const Offset(-8, -16)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-8, -16),
          end: const Offset(0, 0),
        ),
        weight: 13,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(const Offset(0, 0)),
        weight: 12,
      ),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _lidRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.5),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(-0.5),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.5, end: 0.0),
        weight: 13,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 12,
      ),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // Card 1: interval 0.15 -> 0.45. Starts top-left.
    _cardOffset1 = Tween<Offset>(
      begin: const Offset(-40, -45),
      end: const Offset(0, 8),
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.15, 0.45, curve: Curves.easeInQuad),
      ),
    );
    _cardScale1 = Tween<double>(begin: 1.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.15, 0.45, curve: Curves.easeInQuad),
      ),
    );
    _cardRotation1 = Tween<double>(begin: -0.5, end: 2.0 * math.pi).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.15, 0.45, curve: Curves.easeInOutQuad),
      ),
    );
    _cardOpacity1 = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 25),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 5,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 55),
    ]).animate(_ctrl);

    // Card 2: interval 0.3 -> 0.6. Starts top-center.
    _cardOffset2 = Tween<Offset>(
      begin: const Offset(0, -45),
      end: const Offset(0, 8),
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.6, curve: Curves.easeInQuad),
      ),
    );
    _cardScale2 = Tween<double>(begin: 1.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.6, curve: Curves.easeInQuad),
      ),
    );
    _cardRotation2 = Tween<double>(begin: 0.0, end: 3.0 * math.pi).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.6, curve: Curves.easeInOutQuad),
      ),
    );
    _cardOpacity2 = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 25),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 5,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 40),
    ]).animate(_ctrl);

    // Card 3: interval 0.45 -> 0.75. Starts top-right.
    _cardOffset3 = Tween<Offset>(
      begin: const Offset(40, -45),
      end: const Offset(0, 8),
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.75, curve: Curves.easeInQuad),
      ),
    );
    _cardScale3 = Tween<double>(begin: 1.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.75, curve: Curves.easeInQuad),
      ),
    );
    _cardRotation3 = Tween<double>(begin: 0.5, end: 1.5 * math.pi).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.75, curve: Curves.easeInOutQuad),
      ),
    );
    _cardOpacity3 = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 45),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 25),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 5,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 25),
    ]).animate(_ctrl);

    // Bin bounce scale sequence:
    // Starts when card 1 lands (0.45), bounces, card 2 lands (0.60), bounces, card 3 lands (0.75), bounces, and lid shuts (0.88), big bounce.
    _binScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 45),
      // Card 1 impact
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.95), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 1.05), weight: 5),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 5),
      // Card 2 impact
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.95), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 1.05), weight: 5),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 5),
      // Card 3 impact
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.95), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 1.05), weight: 5),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 3),
      // Lid shutting impact
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.90), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: 0.90, end: 1.15), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 0.98), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: 0.98, end: 1.0), weight: 4),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Trash Bin container (Body + Lid)
          Positioned(
            bottom: 6,
            child: ScaleTransition(
              scale: _binScale,
              child: AnimatedBuilder(
                animation: _binScale,
                builder: (context, child) {
                  final glowIntensity = (_binScale.value - 1.0).clamp(0.0, 1.0) * 4.0;
                  return Container(
                    width: 90,
                    height: 90,
                    alignment: Alignment.bottomCenter,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        // Glow background
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: DashboardColors.error.withValues(
                                    alpha: 0.15 + (glowIntensity * 0.15),
                                  ),
                                  blurRadius: 20 + (glowIntensity * 12),
                                  spreadRadius: glowIntensity * 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Trash Bin Body
                        Container(
                          width: 46,
                          height: 48,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(8),
                            ),
                            border: Border.all(
                              color: DashboardColors.error,
                              width: 2.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              3,
                              (index) => Container(
                                width: 2.5,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: DashboardColors.error.withValues(
                                    alpha: 0.4,
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Animated Lid
                        Positioned(
                          bottom: 49,
                          child: AnimatedBuilder(
                            animation: _ctrl,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: _lidOffset.value,
                                child: Transform.rotate(
                                  angle: _lidRotation.value,
                                  origin: const Offset(-20, 0), // hinge on left side
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Handle
                                      Container(
                                        width: 14,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: DashboardColors.error,
                                          borderRadius:
                                              BorderRadius.vertical(
                                            top: Radius.circular(2),
                                          ),
                                        ),
                                      ),
                                      // Lid main bar
                                      Container(
                                        width: 54,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: DashboardColors.error,
                                          borderRadius:
                                              BorderRadius.circular(2.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Card 1
          _buildCardAnimation(_cardOpacity1, _cardOffset1, _cardRotation1, _cardScale1),
          // Card 2
          _buildCardAnimation(_cardOpacity2, _cardOffset2, _cardRotation2, _cardScale2),
          // Card 3
          _buildCardAnimation(_cardOpacity3, _cardOffset3, _cardRotation3, _cardScale3),
        ],
      ),
    );
  }

  Widget _buildCardAnimation(
    Animation<double> opacity,
    Animation<Offset> offset,
    Animation<double> rotation,
    Animation<double> scale,
  ) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        if (opacity.value <= 0.0) return const SizedBox.shrink();
        return Transform.translate(
          offset: offset.value,
          child: Transform.rotate(
            angle: rotation.value,
            child: Transform.scale(
              scale: scale.value,
              child: Opacity(
                opacity: opacity.value,
                child: Container(
                  width: 44,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 28,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 25,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: DashboardColors.error.withValues(
                                  alpha: 0.7,
                                ),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
