import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';

/// A premium, glassmorphic message dialog to replace standard SnackBars.
class AuthMessageDialog extends StatelessWidget {
  const AuthMessageDialog({
    super.key,
    required this.message,
    this.title = 'Notice',
    this.buttonText = 'Close',
    this.isError = true,
    this.onDismiss,
  });

  final String message;
  final String title;
  final String buttonText;
  final bool isError;
  final VoidCallback? onDismiss;

  /// Helper to show this dialog quickly
  static Future<void> show({
    required BuildContext context,
    required String message,
    String title = 'Notice',
    String buttonText = 'Close',
    bool isError = true,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) => AuthMessageDialog(
        message: message,
        title: title,
        buttonText: buttonText,
        isError: isError,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = isError ? RegisterColors.errorRed : RegisterColors.secondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Ring with Radial Glow
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeColor.withValues(alpha: 0.3),
                        width: 2.0,
                      ),
                      gradient: RadialGradient(
                        colors: [
                          themeColor.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                        color: themeColor,
                        size: 40,
                        shadows: [
                          Shadow(
                            color: themeColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                title,
                style: getGeistStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Message Body
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    message,
                    style: getGeistStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: RegisterColors.onSurfaceVariant,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              
              // Dismiss Button
              _AnimatedDismissButton(
                label: buttonText,
                color: themeColor,
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onDismiss != null) {
                    onDismiss!();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedDismissButton extends StatefulWidget {
  const _AnimatedDismissButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_AnimatedDismissButton> createState() => _AnimatedDismissButtonState();
}

class _AnimatedDismissButtonState extends State<_AnimatedDismissButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 50.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: _isHovered ? widget.color.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: _isHovered ? widget.color : widget.color.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.1),
                      blurRadius: 12.0,
                      spreadRadius: 1.0,
                    )
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: widget.onPressed,
              child: Center(
                child: Text(
                  widget.label,
                  style: getGeistStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                    color: _isHovered ? Colors.white : widget.color,
                    letterSpacing: 1.2,
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
