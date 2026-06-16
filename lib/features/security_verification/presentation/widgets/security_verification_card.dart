import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_result.dart';
import 'package:to_do_app/features/security_verification/presentation/widgets/verification_checkbox.dart';
import 'package:to_do_app/features/security_verification/presentation/widgets/verification_dialog.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';

class SecurityVerificationCard extends StatefulWidget {
  const SecurityVerificationCard({
    required this.onChanged,
    this.initialResult,
    super.key,
  });

  final ValueChanged<ChallengeResult?> onChanged;
  final ChallengeResult? initialResult;

  @override
  State<SecurityVerificationCard> createState() => _SecurityVerificationCardState();
}

class _SecurityVerificationCardState extends State<SecurityVerificationCard> {
  VerificationCheckboxState _state = VerificationCheckboxState.idle;
  ChallengeResult? _result;
  Timer? _timer;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _result = widget.initialResult;
    if (_result?.verified == true) {
      _state = VerificationCheckboxState.success;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startVerification() async {
    if (_state == VerificationCheckboxState.loading) return;
    setState(() {
      _state = VerificationCheckboxState.loading;
      _result = null;
    });
    widget.onChanged(null);

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final result = await VerificationDialog.show(context);
      if (!mounted) return;
      setState(() {
        _result = result;
        _state = result?.verified == true
            ? VerificationCheckboxState.success
            : VerificationCheckboxState.failed;
      });
      widget.onChanged(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final verified = _state == VerificationCheckboxState.success;
    final failed = _state == VerificationCheckboxState.failed;
    final borderColor = verified
        ? const Color(0xFF34C759)
        : failed
            ? const Color(0xFFEF4444)
            : _hovered
                ? const Color(0xFF2F80ED)
                : const Color(0xFF1B2A44);

    return Semantics(
      container: true,
      label: 'Security check. I am not a robot.',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(minHeight: 92),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xCC081120),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  if (_hovered && !verified)
                    BoxShadow(
                      color: const Color(0xFF2F80ED).withValues(alpha: 0.18),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  if (verified)
                    BoxShadow(
                      color: const Color(0xFF34C759).withValues(alpha: 0.18),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Row(
                children: [
                  VerificationCheckbox(state: _state, onPressed: _startVerification),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _state == VerificationCheckboxState.loading ? null : _startVerification,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: getGeistStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: RegisterColors.text,
                          height: 1.15,
                        ),
                        child: Text(
                          verified
                              ? "Tôi không phải là người máy"
                              : failed
                                  ? "Xác minh thất bại. Thử lại"
                                  : _state == VerificationCheckboxState.loading
                                      ? "Đang xác minh..."
                                      : "Tôi không phải là người máy",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const _RecaptchaBranding(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecaptchaBranding extends StatelessWidget {
  const _RecaptchaBranding();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.cached_rounded,
              color: Color(0xFF4A90E2),
              size: 26,
            ),
            const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 10,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'reCAPTCHA',
          style: getGeistStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.55),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Bảo mật - Điều khoản',
          style: getGeistStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.35),
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
