import 'dart:ui';

import 'package:flutter/material.dart';

class AchievementPlusButton extends StatefulWidget {
  const AchievementPlusButton({required this.onTap, this.compact = false, super.key});

  final VoidCallback onTap;
  final bool compact;

  @override
  State<AchievementPlusButton> createState() => _AchievementPlusButtonState();
}

class _AchievementPlusButtonState extends State<AchievementPlusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visualSize = widget.compact ? 32.0 : 36.0;
    final targetSize = widget.compact ? 44.0 : 48.0;
    final scale = _pressed ? 0.9 : (_hovered ? 1.15 : _pulseScale.value);

    return Tooltip(
      message: 'Select achievement',
      child: Semantics(
        button: true,
        label: 'Select achievement to showcase',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: SizedBox(
              width: targetSize,
              height: targetSize,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return AnimatedScale(
                      scale: scale,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: child,
                    );
                  },
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: visualSize,
                        height: visualSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: const Color(0xFFA078FF).withValues(
                              alpha: _hovered ? 0.85 : 0.5,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC084FC).withValues(
                                alpha: _hovered ? 0.45 : 0.24,
                              ),
                              blurRadius: _hovered ? 24 : 16,
                              spreadRadius: _hovered ? 3 : 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFFC084FC),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
