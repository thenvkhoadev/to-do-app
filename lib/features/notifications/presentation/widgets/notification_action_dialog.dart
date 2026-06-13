import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class NotificationActionDialog extends StatefulWidget {
  final String title;
  final String message;
  final bool isDecline;

  const NotificationActionDialog({
    required this.title,
    required this.message,
    this.isDecline = false,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    bool isDecline = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => NotificationActionDialog(
        title: title,
        message: message,
        isDecline: isDecline,
      ),
    );
  }

  @override
  State<NotificationActionDialog> createState() => _NotificationActionDialogState();
}

class _NotificationActionDialogState extends State<NotificationActionDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeIn,
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
    final themeColor = widget.isDecline ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final glowColor = themeColor.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1322).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: glowColor,
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Beautiful custom icon badge
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeColor.withValues(alpha: 0.15),
                        border: Border.all(
                          color: themeColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        widget.isDecline ? Icons.close_rounded : Icons.check_rounded,
                        color: themeColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.title,
                      style: GoogleFonts.interTight(
                        color: DashboardColors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 12),
                    Text(
                      'Chạm để đóng',
                      style: TextStyle(
                        color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
