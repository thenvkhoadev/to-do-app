import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskBottomActionBar extends StatefulWidget {
  const TaskBottomActionBar({
    required this.onSave,
    required this.onCancel,
    required this.onDelete,
    required this.isMobile,
    this.isSaving = false,
    this.isTablet = false,
    super.key,
  });

  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final bool isMobile;
  final bool isTablet;
  final bool isSaving;

  @override
  State<TaskBottomActionBar> createState() => _TaskBottomActionBarState();
}

enum _SaveState { idle, saving, saved }

class _TaskBottomActionBarState extends State<TaskBottomActionBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  _SaveState _saveState = _SaveState.idle;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.9),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Cubic(0.16, 1, 0.3, 1), // ultra-smooth ease-out
      ),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(TaskBottomActionBar old) {
    super.didUpdateWidget(old);
    if (!old.isSaving && widget.isSaving) {
      setState(() => _saveState = _SaveState.saving);
    } else if (old.isSaving &&
        !widget.isSaving &&
        _saveState == _SaveState.saving) {
      setState(() => _saveState = _SaveState.saved);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saveState = _SaveState.idle);
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_saveState != _SaveState.idle) return;
    widget.onSave();
  }

  Widget _buildSaveButton({required bool fullWidth}) {
    final Widget label = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (_saveState) {
        _SaveState.saving => const Row(
            key: ValueKey('saving'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'SAVING...',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        _SaveState.saved => Row(
            key: const ValueKey('saved'),
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, val, child) => Transform.rotate(
                  angle: (1.0 - val) * 0.4,
                  child: Transform.scale(
                    scale: val,
                    child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'SAVED',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        _SaveState.idle => const Text(
            'Save Changes',
            key: ValueKey('idle'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
              color: Colors.white,
            ),
          ),
      },
    );

    final Color bgStart = _saveState == _SaveState.saved
        ? const Color(0xFF10B981)
        : const Color(0xFF8B5CF6);
    final Color bgEnd = _saveState == _SaveState.saved
        ? const Color(0xFF059669)
        : const Color(0xFF6366F1);

    return _HoverButton(
      onTap: _handleSave,
      builder: (hovered, pressed) {
        final double lift = hovered && !pressed && _saveState == _SaveState.idle ? -2.0 : 0;
        final double scale = pressed ? 0.96 : (hovered && _saveState == _SaveState.idle ? 1.03 : 1.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, lift, 0)
            ..scaleByDouble(scale, scale, scale, 1.0),
          width: fullWidth ? double.infinity : 138,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hovered && _saveState == _SaveState.idle
                  ? [const Color(0xFFA78BFA), const Color(0xFF4F46E5)]
                  : [bgStart, bgEnd],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: (_saveState == _SaveState.saved 
                        ? const Color(0xFF10B981) 
                        : const Color(0xFF8B5CF6))
                    .withValues(alpha: hovered ? 0.45 : 0.25),
                blurRadius: hovered ? 18 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: label),
        );
      },
    );
  }

  Widget _buildCancelButton() {
    return _HoverButton(
      onTap: widget.onCancel,
      builder: (hovered, pressed) {
        final double scale = pressed ? 0.96 : (hovered ? 1.02 : 1.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.identity()..scaleByDouble(scale, scale, scale, 1.0),
          width: 80,
          height: 40,
          decoration: BoxDecoration(
            color: hovered 
                ? Colors.white.withValues(alpha: 0.08) 
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: hovered 
                  ? Colors.white.withValues(alpha: 0.16) 
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: const Center(
            child: Text(
              'Cancel',
              style: TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton({bool iconOnly = false}) {
    return _HoverButton(
      onTap: widget.onDelete,
      builder: (hovered, pressed) {
        final double scale = pressed ? 0.96 : (hovered ? 1.02 : 1.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.identity()..scaleByDouble(scale, scale, scale, 1.0),
          padding: iconOnly
              ? const EdgeInsets.all(10)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: hovered
                ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: hovered
                  ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
          ),
          child: iconOnly
              ? const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: hovered ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Delete Task',
                      style: TextStyle(
                        color: hovered ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildUnsavedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.65 * _pulseAnimation.value),
                    blurRadius: 7.0 * _pulseAnimation.value,
                    spreadRadius: 2.0 * _pulseAnimation.value,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'UNSAVED CHANGES',
            style: TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.isMobile ? _buildMobile() : _buildDesktop(),
      ),
    );
  }

  Widget _buildMobile() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF090D1A).withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: _buildUnsavedBadge()),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDeleteButton(iconOnly: true),
                  const SizedBox(width: 10),
                  Expanded(child: _buildCancelButton()),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSaveButton(fullWidth: true)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktop() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Stack(
              children: [
                Container(
                  height: 64,
                  constraints: const BoxConstraints(
                    minWidth: 480,
                    maxWidth: 640,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B18).withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 35,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.04),
                        blurRadius: 40,
                        spreadRadius: -4,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Left Side: Delete & Unsaved indicator
                      _buildDeleteButton(),
                      const SizedBox(width: 10),
                      Container(
                        height: 18,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      const SizedBox(width: 12),
                      _buildUnsavedBadge(),
                      
                      const Spacer(),
                      
                      // Right Side: Action buttons
                      if (!widget.isTablet) ...[
                        _buildCancelButton(),
                        const SizedBox(width: 10),
                      ],
                      _buildSaveButton(fullWidth: false),
                    ],
                  ),
                ),
                // Premium light streak reflection highlight at the top edge center
                Positioned(
                  top: 0,
                  left: 64,
                  right: 64,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFC0C1FF).withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverButton extends StatefulWidget {
  const _HoverButton({required this.onTap, required this.builder});

  final Widget Function(bool hovered, bool pressed) builder;
  final VoidCallback onTap;

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          Future.microtask(() {
            if (mounted) setState(() => _hovered = true);
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          Future.microtask(() {
            if (mounted) setState(() => _hovered = false);
          });
        }
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: widget.builder(_hovered, _pressed),
      ),
    );
  }
}
