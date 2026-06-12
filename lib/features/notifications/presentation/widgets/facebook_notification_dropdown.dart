import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/notifications/presentation/widgets/notification_list_view.dart';

class FacebookNotificationDropdown extends StatefulWidget {
  const FacebookNotificationDropdown({
    required this.onClose,
    required this.width,
    super.key,
  });

  final VoidCallback onClose;
  final double width;

  @override
  State<FacebookNotificationDropdown> createState() => _FacebookNotificationDropdownState();
}

class _FacebookNotificationDropdownState extends State<FacebookNotificationDropdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _animateClose() async {
    await _animationController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: widget.width,
                height: 700,
                decoration: BoxDecoration(
                  color: const Color(0xff0F172A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: NotificationListView(
                  onClose: _animateClose,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
