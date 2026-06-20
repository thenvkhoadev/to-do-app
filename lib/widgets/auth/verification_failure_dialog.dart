import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';

/// A premium, glassmorphic Verification Failed Dialog.
/// Dismissing it returns the user to the underlying OTP dialog to try again.
class VerificationFailureDialog extends StatelessWidget {
  const VerificationFailureDialog({
    super.key,
    required this.reason,
    required this.onTryAgain,
  });

  final String reason;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: Failure Icon
              const _CinematicFailureIcon(),
              const SizedBox(width: 32),
              
              // Right side: Content & Action
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Verification Failed",
                      style: getGeistStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          reason,
                          style: getGeistStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: RegisterColors.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _TryAgainButton(
                      label: "Try Again",
                      onPressed: onTryAgain,
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

class _CinematicFailureIcon extends StatefulWidget {
  const _CinematicFailureIcon();

  @override
  State<_CinematicFailureIcon> createState() => _CinematicFailureIconState();
}

class _CinematicFailureIconState extends State<_CinematicFailureIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Red radial glow background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: _isHovered ? 136 : 120,
            height: _isHovered ? 136 : 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: RegisterColors.errorRed.withOpacity(0.15),
                  blurRadius: 50,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
          
          // Icon ring with gradient filling
          AnimatedScale(
            scale: _isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: RegisterColors.errorRed.withOpacity(0.3),
                  width: 2.0,
                ),
                gradient: RadialGradient(
                  colors: [
                    RegisterColors.errorRed.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline_rounded,
                  color: RegisterColors.errorRed,
                  size: 56,
                  shadows: [
                    Shadow(
                      color: RegisterColors.errorRed.withOpacity(0.4),
                      blurRadius: 15,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TryAgainButton extends StatefulWidget {
  const _TryAgainButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_TryAgainButton> createState() => _TryAgainButtonState();
}

class _TryAgainButtonState extends State<_TryAgainButton> {
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
          height: 54.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: _isHovered ? RegisterColors.errorRed.withOpacity(0.15) : Colors.transparent,
            border: Border.all(
              color: _isHovered ? RegisterColors.errorRed : RegisterColors.errorRed.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: RegisterColors.errorRed.withOpacity(0.1),
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
                    color: _isHovered ? Colors.white : RegisterColors.errorRed,
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
