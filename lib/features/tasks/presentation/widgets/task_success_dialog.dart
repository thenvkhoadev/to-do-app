import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskDeploySuccessDialog extends StatefulWidget {
  final String taskTitle;
  const TaskDeploySuccessDialog({required this.taskTitle, super.key});

  static Future<void> show(BuildContext context, String taskTitle) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => TaskDeploySuccessDialog(taskTitle: taskTitle),
    );
  }

  @override
  State<TaskDeploySuccessDialog> createState() => _TaskDeploySuccessDialogState();
}

class _TaskDeploySuccessDialogState extends State<TaskDeploySuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
    HapticFeedback.mediumImpact();
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
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 340,
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1322).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: DashboardColors.primary.withValues(alpha: 0.12),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _DeployAnimation(),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Deploy Thành Công',
                          style: GoogleFonts.interTight(
                            color: DashboardColors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Công việc "${widget.taskTitle}" đã được kích hoạt thành công vào Workspace của bạn.',
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
                        const _PulseText(),
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

class DraftSavedSuccessDialog extends StatefulWidget {
  final String taskTitle;
  const DraftSavedSuccessDialog({required this.taskTitle, super.key});

  static Future<void> show(BuildContext context, String taskTitle) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => DraftSavedSuccessDialog(taskTitle: taskTitle),
    );
  }

  @override
  State<DraftSavedSuccessDialog> createState() => _DraftSavedSuccessDialogState();
}

class _DraftSavedSuccessDialogState extends State<DraftSavedSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
    HapticFeedback.lightImpact();
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
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 340,
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1322).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: DashboardColors.secondary.withValues(alpha: 0.12),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _DraftSaveAnimation(),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Đã Lưu Bản Nháp',
                          style: GoogleFonts.interTight(
                            color: DashboardColors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Bản nháp "${widget.taskTitle}" đã được lưu trữ an toàn trong danh sách nháp của bạn.',
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
                        const _PulseText(),
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

class _DeployAnimation extends StatefulWidget {
  const _DeployAnimation();

  @override
  State<_DeployAnimation> createState() => _DeployAnimationState();
}

class _DeployAnimationState extends State<_DeployAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Rocket / Task Card launch path
  late final Animation<Offset> _cardOffset;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;

  // Star spark animation
  late final Animation<double> _sparkleScale;

  // Checkmark circle zoom
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Rocket/Card launches: starts 0.1, disappears at 0.6
    _cardOffset = Tween<Offset>(
      begin: const Offset(0, 30),
      end: const Offset(0, -70),
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.6, curve: Curves.easeInCubic),
      ),
    );

    _cardScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 0.3), weight: 70),
    ]).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.6, curve: Curves.easeInOut),
      ),
    );

    _cardOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.6, curve: Curves.linear),
      ),
    );

    // Check circle pops up at 0.55 -> 0.85
    _checkScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 55),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 20,
      ),
    ]).animate(_ctrl);

    // Sparkles animate around 0.6 -> 1.0
    _sparkleScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 0.0), weight: 20),
    ]).animate(_ctrl);

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
      height: 120,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing launch track
          Positioned(
            bottom: 15,
            child: Container(
              width: 80,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  BoxShadow(
                    color: DashboardColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Glowing Aura background behind checkbox
          Positioned(
            child: ScaleTransition(
              scale: _checkScale,
              child: Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.primary.withValues(alpha: 0.25),
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Central Checkbox that stays
          Positioned(
            child: ScaleTransition(
              scale: _checkScale,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8083FF),
                      Color(0xFFC0C1FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFF0F1322),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.primary.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Color(0xFF1000A9),
                  size: 26,
                ),
              ),
            ),
          ),

          // Sparkles around
          for (int i = 0; i < 4; i++)
            Positioned(
              left: 100 + 40 * math.cos(i * math.pi / 2 + math.pi / 4),
              top: 60 + 40 * math.sin(i * math.pi / 2 + math.pi / 4),
              child: ScaleTransition(
                scale: _sparkleScale,
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFDDB7FF),
                  size: 14,
                ),
              ),
            ),

          // Launching card
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              if (_cardOpacity.value <= 0.01) return const SizedBox.shrink();
              return Transform.translate(
                offset: _cardOffset.value,
                child: Transform.scale(
                  scale: _cardScale.value,
                  child: Opacity(
                    opacity: _cardOpacity.value,
                    child: Container(
                      width: 48,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DashboardColors.primary.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 4,
                            width: 18,
                            decoration: BoxDecoration(
                              color: DashboardColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2.5,
                            width: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2.5,
                            width: 22,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
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

class _DraftSaveAnimation extends StatefulWidget {
  const _DraftSaveAnimation();

  @override
  State<_DraftSaveAnimation> createState() => _DraftSaveAnimationState();
}

class _DraftSaveAnimationState extends State<_DraftSaveAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Folder open/tilt flap animation
  late final Animation<double> _folderFlapRotation;

  // Draft paper card slide into folder
  late final Animation<Offset> _paperOffset;
  late final Animation<double> _paperScale;
  late final Animation<double> _paperOpacity;

  // Lock / Check overlay animation
  late final Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Flap starts open (slightly tilted), shuts tight around 0.55 -> 0.8
    _folderFlapRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: -0.3, end: -0.3), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: -0.3, end: 0.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // Paper starts high, lands inside at 0.55
    _paperOffset = Tween<Offset>(
      begin: const Offset(0, -42),
      end: const Offset(0, 10),
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.55, curve: Curves.easeIn),
      ),
    );

    _paperScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.72), weight: 70),
    ]).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.55, curve: Curves.easeIn),
      ),
    );

    _paperOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    // Save check badge pops up 0.7 -> 0.95
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 70),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.25).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 12,
      ),
    ]).animate(_ctrl);

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
      height: 120,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow Background
          Positioned(
            child: ScaleTransition(
              scale: _badgeScale,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.secondary.withValues(alpha: 0.2),
                      blurRadius: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // File Cabinet / Folder Backing
          Positioned(
            bottom: 22,
            child: Container(
              width: 76,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DashboardColors.secondary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -6,
                    left: 8,
                    child: Container(
                      width: 24,
                      height: 10,
                      decoration: BoxDecoration(
                        color: DashboardColors.secondary.withValues(alpha: 0.35),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sliding Draft Paper Card
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              if (_paperOpacity.value <= 0.02) return const SizedBox.shrink();
              return Transform.translate(
                offset: _paperOffset.value,
                child: Transform.scale(
                  scale: _paperScale.value,
                  child: Opacity(
                    opacity: _paperOpacity.value,
                    child: Container(
                      width: 42,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2638),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 3,
                            width: 14,
                            decoration: BoxDecoration(
                              color: DashboardColors.secondary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 2,
                            width: 26,
                            decoration: BoxDecoration(
                              color: Colors.white30,
                              borderRadius: BorderRadius.circular(0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 22,
                            decoration: BoxDecoration(
                              color: Colors.white30,
                              borderRadius: BorderRadius.circular(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Folder Front Flap (animated rotation tilt)
          Positioned(
            bottom: 22,
            child: AnimatedBuilder(
              animation: _folderFlapRotation,
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.003) // Perspective
                    ..rotateX(_folderFlapRotation.value),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 76,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E1738),
                          const Color(0xFF0F0B1E).withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                      border: Border(
                        left: BorderSide(color: DashboardColors.secondary.withValues(alpha: 0.6), width: 1.8),
                        right: BorderSide(color: DashboardColors.secondary.withValues(alpha: 0.6), width: 1.8),
                        bottom: BorderSide(color: DashboardColors.secondary.withValues(alpha: 0.6), width: 1.8),
                        top: BorderSide(color: DashboardColors.secondary.withValues(alpha: 0.6), width: 1.5),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: DashboardColors.secondary.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Checkmark / Lock Badge Overlay on final save
          Positioned(
            bottom: 14,
            right: 48,
            child: ScaleTransition(
              scale: _badgeScale,
              child: Container(
                decoration: BoxDecoration(
                  color: DashboardColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F1322),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.success.withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.black,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseText extends StatefulWidget {
  const _PulseText();

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

    _opacity = Tween<double>(begin: 0.35, end: 0.95).animate(
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
        'Chạm vào bất kỳ để đóng',
        style: TextStyle(
          color: DashboardColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class TaskDuplicateSuccessDialog extends StatefulWidget {
  final String taskTitle;
  const TaskDuplicateSuccessDialog({required this.taskTitle, super.key});

  static Future<void> show(BuildContext context, String taskTitle) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => TaskDuplicateSuccessDialog(taskTitle: taskTitle),
    );
  }

  @override
  State<TaskDuplicateSuccessDialog> createState() => _TaskDuplicateSuccessDialogState();
}

class _TaskDuplicateSuccessDialogState extends State<TaskDuplicateSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
    HapticFeedback.mediumImpact();
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
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 340,
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1322).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: DashboardColors.success.withValues(alpha: 0.12),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _DuplicateAnimation(),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Nhân Bản Thành Công',
                          style: GoogleFonts.interTight(
                            color: DashboardColors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Công việc "${widget.taskTitle}" đã được nhân bản thành công.',
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
                        const _PulseText(),
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

class _DuplicateAnimation extends StatefulWidget {
  const _DuplicateAnimation();

  @override
  State<_DuplicateAnimation> createState() => _DuplicateAnimationState();
}

class _DuplicateAnimationState extends State<_DuplicateAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Card 1 animations (first card zooms in, then slides left and tilts)
  late final Animation<Offset> _card1Offset;
  late final Animation<double> _card1Scale;
  late final Animation<double> _card1Opacity;
  late final Animation<double> _card1Rotation;

  // Card 2 animations (appears from Card 1, slides right and tilts)
  late final Animation<Offset> _card2Offset;
  late final Animation<double> _card2Scale;
  late final Animation<double> _card2Opacity;
  late final Animation<double> _card2Rotation;

  // Medallion/Badge in the center zooms in at the end
  late final Animation<double> _badgeScale;

  // Sparkles animations
  late final Animation<double> _sparkleScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Timeline:
    // 0.0 -> 0.35: Card 1 zooms in at center.
    // 0.35 -> 0.65: Card 1 slides left and tilts left; Card 2 fades in and slides right and tilts right.
    // 0.55 -> 0.85: Badge zooms in at center.
    // 0.65 -> 0.95: Sparkles pop.

    _card1Scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 0.9).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.9),
        weight: 35,
      ),
    ]).animate(_ctrl);

    _card1Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 75),
    ]).animate(_ctrl);

    _card1Offset = TweenSequence<Offset>([
      TweenSequenceItem(tween: ConstantTween<Offset>(Offset.zero), weight: 35),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(-28, 6)).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween<Offset>(const Offset(-28, 6)), weight: 35),
    ]).animate(_ctrl);

    _card1Rotation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 35),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.1).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(-0.1), weight: 35),
    ]).animate(_ctrl);

    // Card 2 (duplicate copy) sequence
    _card2Scale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 35),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.1).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 0.9).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.9), weight: 15),
    ]).animate(_ctrl);

    _card2Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 45),
    ]).animate(_ctrl);

    _card2Offset = TweenSequence<Offset>([
      TweenSequenceItem(tween: ConstantTween<Offset>(Offset.zero), weight: 35),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(28, 6)).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween<Offset>(const Offset(28, 6)), weight: 35),
    ]).animate(_ctrl);

    _card2Rotation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 35),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.1).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.1), weight: 35),
    ]).animate(_ctrl);

    // Badge zoom
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 55),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.25).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 20,
      ),
    ]).animate(_ctrl);

    // Sparkles
    _sparkleScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 65),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.2), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 0.0), weight: 20),
    ]).animate(_ctrl);

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
      height: 120,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing green backdrop
          Positioned(
            child: ScaleTransition(
              scale: _badgeScale,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.success.withValues(alpha: 0.22),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sparkles around
          for (int i = 0; i < 4; i++)
            Positioned(
              left: 120 + 48 * math.cos(i * math.pi / 2 + math.pi / 4),
              top: 60 + 48 * math.sin(i * math.pi / 2 + math.pi / 4),
              child: ScaleTransition(
                scale: _sparkleScale,
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFD1FAE5),
                  size: 14,
                ),
              ),
            ),

          // Card 1 (Original / Left)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              if (_card1Opacity.value <= 0.01) return const SizedBox.shrink();
              return Transform.translate(
                offset: _card1Offset.value,
                child: Transform.scale(
                  scale: _card1Scale.value,
                  child: Transform.rotate(
                    angle: _card1Rotation.value,
                    child: Opacity(
                      opacity: _card1Opacity.value,
                      child: _buildMiniCard(isOriginal: true),
                    ),
                  ),
                ),
              );
            },
          ),

          // Card 2 (Duplicate / Right)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              if (_card2Opacity.value <= 0.01) return const SizedBox.shrink();
              return Transform.translate(
                offset: _card2Offset.value,
                child: Transform.scale(
                  scale: _card2Scale.value,
                  child: Transform.rotate(
                    angle: _card2Rotation.value,
                    child: Opacity(
                      opacity: _card2Opacity.value,
                      child: _buildMiniCard(isOriginal: false),
                    ),
                  ),
                ),
              );
            },
          ),

          // Success Central Medallion
          Positioned(
            child: ScaleTransition(
              scale: _badgeScale,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF34D399),
                      Color(0xFF059669),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFF0F1322),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.success.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.control_point_duplicate_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard({required bool isOriginal}) {
    return Container(
      width: 48,
      height: 54,
      decoration: BoxDecoration(
        color: isOriginal ? const Color(0xFF1E2638) : const Color(0xFF242F4D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOriginal
              ? Colors.white.withValues(alpha: 0.22)
              : DashboardColors.success.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: 18,
            decoration: BoxDecoration(
              color: isOriginal ? DashboardColors.primary : DashboardColors.success,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2.5,
            width: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2.5,
            width: 22,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

class ArchiveConfirmDialog extends StatelessWidget {
  final String taskTitle;
  const ArchiveConfirmDialog({required this.taskTitle, super.key});

  static Future<bool?> show(BuildContext context, String taskTitle) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => ArchiveConfirmDialog(taskTitle: taskTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1322).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: DashboardColors.secondary.withValues(alpha: 0.1),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DashboardColors.secondary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: DashboardColors.secondary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.archive_outlined,
                  color: DashboardColors.secondary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Lưu Trữ Công Việc?',
                style: GoogleFonts.interTight(
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Công việc "$taskTitle" sẽ được lưu trữ và không hiển thị trong bảng chính.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DashboardColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Lưu trữ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class DeleteConfirmDialog extends StatelessWidget {
  final String taskTitle;
  final int? count;
  const DeleteConfirmDialog({required this.taskTitle, this.count, super.key});

  static Future<bool?> show(BuildContext context, String taskTitle, {int? count}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => DeleteConfirmDialog(taskTitle: taskTitle, count: count),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText = count != null ? 'Xóa $count công việc?' : 'Xóa Công Việc?';
    final descText = count != null
        ? 'Bạn có chắc chắn muốn xóa $count công việc đã chọn trong cột "$taskTitle" không? Hành động này không thể hoàn tác.'
        : 'Bạn có chắc chắn muốn xóa công việc "$taskTitle" không? Hành động này không thể hoàn tác.';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1322).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: DashboardColors.error.withValues(alpha: 0.1),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DashboardColors.error.withValues(alpha: 0.15),
                  border: Border.all(
                    color: DashboardColors.error.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: DashboardColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                titleText,
                style: GoogleFonts.interTight(
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                descText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DashboardColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Xóa',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class ArchiveSuccessDialog extends StatefulWidget {
  final String taskTitle;
  const ArchiveSuccessDialog({required this.taskTitle, super.key});

  static Future<void> show(BuildContext context, String taskTitle) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => ArchiveSuccessDialog(taskTitle: taskTitle),
    );
  }

  @override
  State<ArchiveSuccessDialog> createState() => _ArchiveSuccessDialogState();
}

class _ArchiveSuccessDialogState extends State<ArchiveSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
    HapticFeedback.mediumImpact();
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
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 340,
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1322).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: DashboardColors.secondary.withValues(alpha: 0.12),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _ArchiveAnimation(),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Lưu Trữ Thành Công',
                          style: GoogleFonts.interTight(
                            color: DashboardColors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Công việc "${widget.taskTitle}" đã được đưa vào kho lưu trữ của bạn.',
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
                        const _PulseText(),
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

class _ArchiveAnimation extends StatefulWidget {
  const _ArchiveAnimation();

  @override
  State<_ArchiveAnimation> createState() => _ArchiveAnimationState();
}

class _ArchiveAnimationState extends State<_ArchiveAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Folder open/tilt flap animation
  late final Animation<double> _folderFlapRotation;

  // Archive paper card slide into archive drawer
  late final Animation<Offset> _paperOffset;
  late final Animation<double> _paperScale;
  late final Animation<double> _paperOpacity;

  // Lock / Check overlay animation
  late final Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Flap starts open (slightly tilted), shuts tight around 0.55 -> 0.8
    _folderFlapRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: -0.3, end: -0.3), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: -0.3, end: 0.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // Paper starts high, lands inside at 0.55
    _paperOffset = Tween<Offset>(
      begin: const Offset(0, -42),
      end: const Offset(0, 10),
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.55, curve: Curves.easeIn),
      ),
    );

    _paperScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.72), weight: 70),
    ]).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.55, curve: Curves.easeIn),
      ),
    );

    _paperOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    // Save check badge pops up 0.7 -> 0.95
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 70),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.25).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 12,
      ),
    ]).animate(_ctrl);

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
      height: 120,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow Background
          Positioned(
            child: ScaleTransition(
              scale: _badgeScale,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.secondary.withValues(alpha: 0.2),
                      blurRadius: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // File Drawer Backing
          Positioned(
            bottom: 22,
            child: Container(
              width: 76,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DashboardColors.secondary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -6,
                    left: 8,
                    child: Container(
                      width: 24,
                      height: 10,
                      decoration: BoxDecoration(
                        color: DashboardColors.secondary.withValues(alpha: 0.35),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sliding Paper Card
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              if (_paperOpacity.value <= 0.02) return const SizedBox.shrink();
              return Transform.translate(
                offset: _paperOffset.value,
                child: Transform.scale(
                  scale: _paperScale.value,
                  child: Opacity(
                    opacity: _paperOpacity.value,
                    child: Container(
                      width: 42,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2638),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 3,
                            width: 14,
                            decoration: BoxDecoration(
                              color: DashboardColors.secondary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 2,
                            width: 26,
                            decoration: BoxDecoration(
                              color: Colors.white30,
                              borderRadius: BorderRadius.circular(0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 22,
                            decoration: BoxDecoration(
                              color: Colors.white30,
                              borderRadius: BorderRadius.circular(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Drawer Front Flap (animated rotation tilt)
          Positioned(
            bottom: 22,
            child: AnimatedBuilder(
              animation: _folderFlapRotation,
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.003) // Perspective
                    ..rotateX(_folderFlapRotation.value),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 76,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E1738),
                          const Color(0xFF0F0B1E).withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                      border: Border(
                        left: BorderSide(color: DashboardColors.secondary.withValues(alpha: 0.6), width: 1.8),
                        right: BorderSide(color: DashboardColors.secondary.withValues(alpha: 0.6), width: 1.8),
                        bottom: BorderSide(color: DashboardColors.secondary.withValues(alpha: 0.6), width: 1.8),
                        top: BorderSide(color: DashboardColors.secondary.withValues(alpha: 0.6), width: 1.5),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.archive_rounded,
                        color: DashboardColors.secondary,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Badge Overlay
          Positioned(
            bottom: 14,
            right: 48,
            child: ScaleTransition(
              scale: _badgeScale,
              child: Container(
                decoration: BoxDecoration(
                  color: DashboardColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F1322),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.success.withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.black,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskTransitionSuccessDialog extends StatefulWidget {
  final String taskTitle;
  final TaskBoardStatus fromStatus;
  final TaskBoardStatus toStatus;

  const TaskTransitionSuccessDialog({
    required this.taskTitle,
    required this.fromStatus,
    required this.toStatus,
    super.key,
  });

  static Future<void> show(
    BuildContext context,
    String taskTitle,
    TaskBoardStatus fromStatus,
    TaskBoardStatus toStatus,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => TaskTransitionSuccessDialog(
        taskTitle: taskTitle,
        fromStatus: fromStatus,
        toStatus: toStatus,
      ),
    );
  }

  @override
  State<TaskTransitionSuccessDialog> createState() => _TaskTransitionSuccessDialogState();
}

class _TaskTransitionSuccessDialogState extends State<TaskTransitionSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _getTransitionInfo(widget.taskTitle, widget.fromStatus, widget.toStatus);

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 340,
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1322).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: info.themeColor.withValues(alpha: 0.12),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TransitionAnimation(
                    fromStatus: widget.fromStatus,
                    toStatus: widget.toStatus,
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          info.title,
                          style: GoogleFonts.interTight(
                            color: DashboardColors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          info.message,
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
                        const _PulseText(),
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

class _TransitionAnimation extends StatefulWidget {
  final TaskBoardStatus fromStatus;
  final TaskBoardStatus toStatus;

  const _TransitionAnimation({
    required this.fromStatus,
    required this.toStatus,
  });

  @override
  State<_TransitionAnimation> createState() => _TransitionAnimationState();
}

class _TransitionAnimationState extends State<_TransitionAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Left node scale/fade
  late final Animation<double> _leftScale;
  late final Animation<double> _leftOpacity;

  // Connecting path beam position (0.0 to 1.0)
  late final Animation<double> _beamPosition;
  late final Animation<double> _beamOpacity;

  // Right node scale/fade
  late final Animation<double> _rightScale;
  late final Animation<double> _rightOpacity;
  late final Animation<double> _rightGlow;

  // Sparkles/Confetti scale
  late final Animation<double> _sparkleScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _leftScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 0.85).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.85),
        weight: 55,
      ),
    ]).animate(_ctrl);

    _leftOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 85),
    ]).animate(_ctrl);

    _beamPosition = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.22, 0.65, curve: Curves.easeIn),
      ),
    );

    _beamOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 22),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 30),
    ]).animate(_ctrl);

    _rightScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 55),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]).animate(_ctrl);

    _rightOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 30),
    ]).animate(_ctrl);

    _rightGlow = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 65),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.4), weight: 15),
    ]).animate(_ctrl);

    _sparkleScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 70),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.2), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 0.0), weight: 15),
    ]).animate(_ctrl);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fromColor = widget.fromStatus.displayColor;
    final toColor = widget.toStatus.displayColor;
    final fromIcon = widget.fromStatus.displayIcon;
    final toIcon = widget.toStatus.displayIcon;

    return SizedBox(
      height: 120,
      width: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing Aura behind the target status (right side)
          Positioned(
            left: 155,
            child: AnimatedBuilder(
              animation: _rightGlow,
              builder: (context, child) {
                return Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: toColor.withValues(alpha: 0.22 * _rightGlow.value),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Dash line representing status path
          Positioned(
            left: 55,
            right: 55,
            child: SizedBox(
              height: 2,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                itemBuilder: (context, index) {
                  return Container(
                    width: 6,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    color: Colors.white.withValues(alpha: 0.15),
                  );
                },
              ),
            ),
          ),

          // Traveling beam/particle
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              if (_beamOpacity.value <= 0.01) return const SizedBox.shrink();
              final leftPos = 40.0 + (140.0 * _beamPosition.value);
              return Positioned(
                left: leftPos,
                child: Opacity(
                  opacity: _beamOpacity.value,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Color.lerp(fromColor, toColor, _beamPosition.value),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.lerp(fromColor, toColor, _beamPosition.value)!
                              .withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Sparkles around target status
          for (int i = 0; i < 5; i++)
            Positioned(
              left: 173 + 46 * math.cos(i * 2 * math.pi / 5 + math.pi / 10),
              top: 35 + 46 * math.sin(i * 2 * math.pi / 5 + math.pi / 10),
              child: ScaleTransition(
                scale: _sparkleScale,
                child: Icon(
                  Icons.star_rounded,
                  color: Color.lerp(toColor, Colors.white, 0.4),
                  size: 14,
                ),
              ),
            ),

          // Left Node (From Status)
          Positioned(
            left: 20,
            child: FadeTransition(
              opacity: _leftOpacity,
              child: ScaleTransition(
                scale: _leftScale,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B30),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: fromColor.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: fromColor.withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    fromIcon,
                    color: fromColor.withValues(alpha: 0.85),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Right Node (To Status)
          Positioned(
            left: 168,
            child: FadeTransition(
              opacity: _rightOpacity,
              child: ScaleTransition(
                scale: _rightScale,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        toColor,
                        toColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0F1322),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: toColor.withValues(alpha: 0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    toIcon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransitionInfo {
  final String title;
  final String message;
  final Color themeColor;
  final IconData icon;

  const _TransitionInfo({
    required this.title,
    required this.message,
    required this.themeColor,
    required this.icon,
  });
}

_TransitionInfo _getTransitionInfo(String title, TaskBoardStatus from, TaskBoardStatus to) {
  if (from == TaskBoardStatus.draft) {
    if (to == TaskBoardStatus.todo) {
      return _TransitionInfo(
        title: 'Kích Hoạt Công Việc',
        message: 'Công việc "$title" đã chuyển từ bản nháp sang To-Do và sẵn sàng thực hiện.',
        themeColor: const Color(0xFF5B8CFF),
        icon: Icons.flag_rounded,
      );
    } else if (to == TaskBoardStatus.inProgress) {
      return _TransitionInfo(
        title: 'Bắt Đầu Thực Hiện',
        message: 'Công việc "$title" đã được kích hoạt trực tiếp từ bản nháp và bắt đầu thực hiện.',
        themeColor: const Color(0xFFFFB020),
        icon: Icons.bolt_rounded,
      );
    }
  } else if (from == TaskBoardStatus.todo) {
    if (to == TaskBoardStatus.inProgress) {
      return _TransitionInfo(
        title: 'Bắt Đầu Thực Hiện',
        message: 'Bắt đầu tiến trình thực hiện cho công việc "$title".',
        themeColor: const Color(0xFFFFB020),
        icon: Icons.bolt_rounded,
      );
    }
  } else if (from == TaskBoardStatus.inProgress) {
    if (to == TaskBoardStatus.todo) {
      return _TransitionInfo(
        title: 'Tạm Dừng Công Việc',
        message: 'Đã tạm dừng và đưa công việc "$title" trở lại hàng đợi To-Do.',
        themeColor: const Color(0xFFFF9500),
        icon: Icons.pause_rounded,
      );
    }
  }

  return _TransitionInfo(
    title: 'Cập Nhật Trạng Thái',
    message: 'Trạng thái của công việc "$title" đã được cập nhật thành công.',
    themeColor: DashboardColors.primary,
    icon: Icons.swap_horiz_rounded,
  );
}

class TaskCompleteSuccessDialog extends StatefulWidget {
  final String taskTitle;
  const TaskCompleteSuccessDialog({required this.taskTitle, super.key});

  static Future<void> show(BuildContext context, String taskTitle) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => TaskCompleteSuccessDialog(taskTitle: taskTitle),
    );
  }

  @override
  State<TaskCompleteSuccessDialog> createState() => _TaskCompleteSuccessDialogState();
}

class _TaskCompleteSuccessDialogState extends State<TaskCompleteSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
    HapticFeedback.mediumImpact();
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
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 340,
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1322).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: DashboardColors.primary.withValues(alpha: 0.12),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _CompleteAnimation(),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Hoàn Thành Công Việc!',
                          style: GoogleFonts.interTight(
                            color: DashboardColors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Chúc mừng bạn đã hoàn thành xuất sắc công việc "${widget.taskTitle}".',
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
                        const _PulseText(),
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

class _CompleteAnimation extends StatefulWidget {
  const _CompleteAnimation();

  @override
  State<_CompleteAnimation> createState() => _CompleteAnimationState();
}

class _CompleteAnimationState extends State<_CompleteAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _checkScale;
  late final Animation<double> _trophyScale;
  late final Animation<double> _trophyOpacity;
  late final Animation<double> _confettiScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _checkScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.25).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 0.75).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.75),
        weight: 35,
      ),
    ]).animate(_ctrl);

    _trophyScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 35),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 30,
      ),
    ]).animate(_ctrl);

    _trophyOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 45),
    ]).animate(_ctrl);

    _confettiScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.3), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 0.0), weight: 30),
    ]).animate(_ctrl);

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
      height: 120,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            child: ScaleTransition(
              scale: _trophyScale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.primary.withValues(alpha: 0.22),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),
          for (int i = 0; i < 6; i++)
            Positioned(
              left: 120 + 52 * math.cos(i * math.pi / 3 + math.pi / 6),
              top: 60 + 52 * math.sin(i * math.pi / 3 + math.pi / 6),
              child: ScaleTransition(
                scale: _confettiScale,
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFE699),
                  size: 14,
                ),
              ),
            ),
          Positioned(
            left: 55,
            top: 45,
            child: ScaleTransition(
              scale: _checkScale,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DashboardColors.success.withValues(alpha: 0.15),
                  border: Border.all(
                    color: DashboardColors.success,
                    width: 2.5,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: DashboardColors.success,
                  size: 26,
                ),
              ),
            ),
          ),
          ScaleTransition(
            scale: _trophyScale,
            child: Opacity(
              opacity: _trophyOpacity.value,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFF0F1322),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFF6A4000),
                  size: 34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

