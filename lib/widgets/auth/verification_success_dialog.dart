import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';

/// A premium, glassmorphic Verification Successful Dialog exported from test.html.
/// Displayed when the OTP verification completes successfully in SecurityCodeDialog.
class VerificationSuccessDialog extends StatelessWidget {
  const VerificationSuccessDialog({
    super.key,
    required this.onContinue,
  });

  final VoidCallback onContinue;

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
              // Left side: Success Icon
              const _CinematicSuccessIcon(),
              const SizedBox(width: 32),
              
              // Right side: Content & Action
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Verification Successful",
                      style: getGeistStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: getGeistStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: RegisterColors.onSurfaceVariant,
                          height: 1.45,
                        ),
                        children: [
                          const TextSpan(text: "Your identity has been confirmed. You're now ready to unlock your full productivity potential with "),
                          TextSpan(
                            text: "Nexus AI",
                            style: getGeistStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: RegisterColors.primary,
                            ),
                          ),
                          const TextSpan(text: "."),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ContinueGradientButton(
                      label: "Continue to Sign In",
                      icon: Icons.arrow_forward,
                      onPressed: onContinue,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: RegisterColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "SECURITY HANDSHAKE: COMPLETE",
                          style: getGeistMonoStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: RegisterColors.onSurfaceVariant.withOpacity(0.6),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
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

class _CinematicSuccessIcon extends StatefulWidget {
  const _CinematicSuccessIcon();

  @override
  State<_CinematicSuccessIcon> createState() => _CinematicSuccessIconState();
}

class _CinematicSuccessIconState extends State<_CinematicSuccessIcon> {
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
          // Radial glow background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: _isHovered ? 144 : 128,
            height: _isHovered ? 144 : 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: RegisterColors.successGreen.withOpacity(0.15),
                  blurRadius: 60,
                  spreadRadius: 8,
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
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: RegisterColors.successGreen.withOpacity(0.3),
                  width: 2.0,
                ),
                gradient: RadialGradient(
                  colors: [
                    RegisterColors.successGreen.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.check_circle,
                  color: RegisterColors.successGreen,
                  size: 64,
                  shadows: [
                    Shadow(
                      color: RegisterColors.successGreen.withOpacity(0.4),
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

class _ContinueGradientButton extends StatefulWidget {
  const _ContinueGradientButton({
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  State<_ContinueGradientButton> createState() => _ContinueGradientButtonState();
}

class _ContinueGradientButtonState extends State<_ContinueGradientButton> {
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
          height: 60.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: const LinearGradient(
              colors: [Color(0xFFE1DFFF), Color(0xFFC0C1FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFC0C1FF).withOpacity(0.4),
                      blurRadius: 20.0,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    style: getGeistStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF131449),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  AnimatedSlide(
                    offset: _isHovered ? const Offset(0.15, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      color: const Color(0xFF131449),
                      size: 20,
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
