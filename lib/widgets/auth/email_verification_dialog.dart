import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';

/// A premium, glassmorphic email verification dialog exported from test.html.
/// Uses the existing [GlassCard] and brand theme styles for a cohesive appearance.
class EmailVerificationDialog extends StatelessWidget {
  const EmailVerificationDialog({
    super.key,
    required this.onNext,
    required this.onChangeEmail,
  });

  final VoidCallback onNext;
  final VoidCallback onChangeEmail;

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
              // Left side: Illustration
              const _MailIllustration(),
              const SizedBox(width: 32),
              
              // Right side: Content & Action buttons
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Verify Your Email",
                      style: getGeistStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: RegisterColors.text,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We've sent a verification code to your email address. Please check your inbox and continue to verify your account.",
                      style: getGeistStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: RegisterColors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _GradientButton(
                      label: "NEXT",
                      icon: Icons.arrow_forward,
                      onPressed: onNext,
                    ),
                    const SizedBox(height: 12),
                    _SecondaryButton(
                      label: "Change Email",
                      onPressed: onChangeEmail,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          "NEXUS_AUTH_V2.0",
                          style: getGeistMonoStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: RegisterColors.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: RegisterColors.glassStroke,
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

class _MailIllustration extends StatefulWidget {
  const _MailIllustration();

  @override
  State<_MailIllustration> createState() => _MailIllustrationState();
}

class _MailIllustrationState extends State<_MailIllustration> {
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
          // Purple/blue radial glow background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: _isHovered ? 144 : 128,
            height: _isHovered ? 144 : 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC0C1FF).withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Circle Container
          AnimatedScale(
            scale: _isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: const Color(0xFF2F3445), // bg-surface-container-highest
                shape: BoxShape.circle,
                border: Border.all(
                  color: RegisterColors.glassStroke,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC0C1FF).withOpacity(0.15), // shadow-nebula-glow
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.mail_outline_rounded,
                  color: const Color(0xFFC0C1FF),
                  size: 64,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFC0C1FF).withOpacity(0.4),
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

class _GradientButton extends StatefulWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
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
          height: 56.0,
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
                      color: const Color(0xFFC0C1FF).withOpacity(0.3),
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
                      color: const Color(0xFF292B5E),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  AnimatedSlide(
                    offset: _isHovered ? const Offset(0.15, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      color: const Color(0xFF292B5E),
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

class _SecondaryButton extends StatefulWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          hoverColor: const Color(0xFFC0C1FF).withOpacity(0.15), // hover:bg-nebula-glow
          onTap: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: getGeistStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: _isHovered ? RegisterColors.text : RegisterColors.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}
