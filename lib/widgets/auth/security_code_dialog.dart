import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';
import 'package:to_do_app/widgets/auth/verification_failure_dialog.dart';

/// A premium, glassmorphic Security Code Dialog exported from test.html.
/// Shown when clicking "Next" in the email verification dialog.
class SecurityCodeDialog extends StatefulWidget {
  const SecurityCodeDialog({
    super.key,
    required this.email,
    required this.onVerified,
    required this.onBack,
    required this.onResendOtp,
  });

  final String email;
  final FutureOr<String?> Function(String code) onVerified;
  final VoidCallback onBack;
  final VoidCallback onResendOtp;

  @override
  State<SecurityCodeDialog> createState() => _SecurityCodeDialogState();
}

enum VerificationState { initial, loading, success }

class _SecurityCodeDialogState extends State<SecurityCodeDialog> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  Timer? _timer;
  int _secondsRemaining = 59;
  VerificationState _state = VerificationState.initial;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 59;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _verifyIdentity() async {
    if (_state != VerificationState.initial) return;

    // Collect OTP code
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      _showFailureDialog("Please enter all 6 digits of your security key.");
      return;
    }

    setState(() {
      _state = VerificationState.loading;
    });

    try {
      final errorReason = await widget.onVerified(code);
      if (!mounted) return;

      if (errorReason == null) {
        setState(() {
          _state = VerificationState.success;
        });
      } else {
        setState(() {
          _state = VerificationState.initial;
        });
        
        // Clear all inputs
        for (var controller in _controllers) {
          controller.clear();
        }
        // Focus first field
        _focusNodes[0].requestFocus();
        
        // Show failure dialog
        _showFailureDialog(errorReason);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = VerificationState.initial;
      });
      _showFailureDialog(e.toString());
    }
  }

  void _showFailureDialog(String reason) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (context) => VerificationFailureDialog(
        reason: reason,
        onTryAgain: () {
          Navigator.of(context).pop(); // Close failure dialog
        },
      ),
    );
  }

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
              // Left side: Security Illustration
              const _SecurityIllustration(),
              const SizedBox(width: 32),
              
              // Right side: Content and Inputs
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter Security Code",
                      style: getGeistStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: RegisterColors.text,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: getGeistStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: RegisterColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: "We've sent a 6-digit intelligence key to "),
                          TextSpan(
                            text: widget.email,
                            style: getGeistMonoStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: RegisterColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // OTP Input fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return _buildOtpField(index);
                      }),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildVerifyButton(),
                    const SizedBox(height: 12),
                    _buildBackButton(),
                    const SizedBox(height: 20),
                    _buildResendFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 54,
      height: 54,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true), // Inner node just to listen to keys
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_controllers[index].text.isEmpty && index > 0) {
              _controllers[index - 1].clear();
              _focusNodes[index - 1].requestFocus();
              setState(() {});
            }
          }
        },
        child: Focus(
          onFocusChange: (hasFocus) {
            setState(() {});
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _focusNodes[index].hasFocus
                  ? [
                      BoxShadow(
                        color: const Color(0xFFC0C1FF).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            transform: _focusNodes[index].hasFocus
                ? Matrix4.translationValues(0.0, -2.0, 0.0)
                : Matrix4.identity(),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              maxLength: 1,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.text,
              inputFormatters: [
                LengthLimitingTextInputFormatter(1),
              ],
              style: getGeistMonoStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: RegisterColors.text,
              ),
              decoration: InputDecoration(
                counterText: "",
                hintText: "·",
                hintStyle: getGeistMonoStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: RegisterColors.onSurfaceVariant.withOpacity(0.3),
                ),
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: const Color(0x66191F2F),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: RegisterColors.glassStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC0C1FF), width: 1.5),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  if (index < 5) {
                    _focusNodes[index + 1].requestFocus();
                  } else {
                    _focusNodes[index].unfocus();
                    _verifyIdentity();
                  }
                }
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    final bool isSuccess = _state == VerificationState.success;
    final bool isLoading = _state == VerificationState.loading;

    return _VerifyGradientButton(
      state: _state,
      onPressed: _verifyIdentity,
    );
  }

  void _handleResend() {
    _startTimer();
    widget.onResendOtp();
  }

  Widget _buildBackButton() {
    return _BackButton(
      onPressed: widget.onBack,
    );
  }

  Widget _buildResendFooter() {
    final bool canResend = _secondsRemaining == 0;
    
    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: RegisterColors.glassStroke, width: 1),
        ),
      ),
      width: double.infinity,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Didn't receive the key? ",
            style: getGeistStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: RegisterColors.onSurfaceVariant,
            ),
          ),
          MouseRegion(
            cursor: canResend ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
            child: GestureDetector(
              onTap: canResend ? _handleResend : null,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: getGeistStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: canResend ? RegisterColors.primary : RegisterColors.onSurfaceVariant.withOpacity(0.6),
                ),
                child: canResend
                    ? const Text("Resend Key Now", style: TextStyle(decoration: TextDecoration.underline))
                    : RichText(
                        text: TextSpan(
                          style: getGeistStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: RegisterColors.onSurfaceVariant.withOpacity(0.6),
                          ),
                          children: [
                            const TextSpan(text: "Resend in "),
                            TextSpan(
                              text: "00:${_secondsRemaining < 10 ? '0$_secondsRemaining' : _secondsRemaining}",
                              style: getGeistMonoStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: RegisterColors.warningOrange,
                              ),
                            ),
                          ],
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

class _VerifyGradientButton extends StatefulWidget {
  const _VerifyGradientButton({
    required this.state,
    required this.onPressed,
  });

  final VerificationState state;
  final VoidCallback onPressed;

  @override
  State<_VerifyGradientButton> createState() => _VerifyGradientButtonState();
}

class _VerifyGradientButtonState extends State<_VerifyGradientButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = widget.state == VerificationState.success;
    final bool isLoading = widget.state == VerificationState.loading;

    final Color labelColor = (isLoading || isSuccess) ? const Color(0xFF0D1322) : const Color(0xFF131449);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered && !isLoading && !isSuccess ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: isSuccess
                ? const LinearGradient(
                    colors: [RegisterColors.successGreen, RegisterColors.successGreen],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFE1DFFF), Color(0xFFC0C1FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: _isHovered && !isLoading && !isSuccess
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
              onTap: (isLoading || isSuccess) ? null : widget.onPressed,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D1322)),
                          ),
                        )
                      : isSuccess
                          ? Row(
                              key: const ValueKey('success-state'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFF0D1322),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Identity Verified",
                                  style: getGeistStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: labelColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              key: const ValueKey('initial-state'),
                              "Verify Identity",
                              style: getGeistStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: labelColor,
                                letterSpacing: 0.5,
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

class _BackButton extends StatefulWidget {
  const _BackButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 50.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: _isHovered ? const Color(0xFFC0C1FF).withOpacity(0.05) : Colors.transparent,
          border: Border.all(
            color: _isHovered ? RegisterColors.text.withOpacity(0.3) : RegisterColors.glassStroke,
            width: 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: widget.onPressed,
            child: Center(
              child: Text(
                "Back",
                style: getGeistStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? RegisterColors.text : RegisterColors.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityIllustration extends StatefulWidget {
  const _SecurityIllustration();

  @override
  State<_SecurityIllustration> createState() => _SecurityIllustrationState();
}

class _SecurityIllustrationState extends State<_SecurityIllustration> {
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
                  Icons.vpn_key_rounded,
                  color: const Color(0xFFC0C1FF),
                  size: 56,
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
          // Secure Badge positioned on the bottom right of the stack
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: RegisterColors.successGreen,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: RegisterColors.successGreen.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF0D1322),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "SECURE",
                    style: getGeistMonoStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D1322),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
