import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';

enum TurnstileState { idle, loading, success }

class TurnstileWidget extends StatefulWidget {
  const TurnstileWidget({
    required this.onVerified,
    this.initialVerified = false,
    super.key,
  });

  final ValueChanged<bool> onVerified;
  final bool initialVerified;

  @override
  State<TurnstileWidget> createState() => _TurnstileWidgetState();
}

class _TurnstileWidgetState extends State<TurnstileWidget>
    with SingleTickerProviderStateMixin {
  late TurnstileState _state;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initialVerified ? TurnstileState.success : TurnstileState.idle;
  }

  void _handleTap() {
    if (_state == TurnstileState.loading) return;

    if (_state == TurnstileState.success) {
      setState(() {
        _state = TurnstileState.idle;
      });
      widget.onVerified(false);
    } else {
      setState(() {
        _state = TurnstileState.loading;
      });

      // Simulate the secure browser telemetry checks (1.5 seconds)
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _state == TurnstileState.loading) {
          setState(() {
            _state = TurnstileState.success;
          });
          widget.onVerified(true);
        }
      });
    }
  }

  Widget _buildStatusIndicator() {
    switch (_state) {
      case TurnstileState.idle:
        return Container(
          width: 24.0,
          height: 24.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(
              color: _isHovered ? Colors.white38 : Colors.white24,
              width: 1.5,
            ),
          ),
        );
      case TurnstileState.loading:
        return const SizedBox(
          width: 20.0,
          height: 20.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)), // Cloudflare Blue
          ),
        );
      case TurnstileState.success:
        return Container(
          width: 24.0,
          height: 24.0,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x3310B981), // Green glow
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF10B981), // Cloudflare green check
            size: 18.0,
          ),
        );
    }
  }

  String _getStatusText() {
    switch (_state) {
      case TurnstileState.idle:
        return 'Verify you are human';
      case TurnstileState.loading:
        return 'Verifying...';
      case TurnstileState.success:
        return 'Success';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          height: 65.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1524), // Official Turnstile dark background
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: _state == TurnstileState.success
                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                  : (Colors.white.withValues(alpha: 0.1)),
              width: 1.0,
            ),
            boxShadow: [
              if (_state == TurnstileState.success)
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  blurRadius: 12.0,
                  spreadRadius: 1.0,
                ),
            ],
          ),
          child: Row(
            children: [
              // Left side: Status Box/Indicator
              _buildStatusIndicator(),
              const SizedBox(width: 16.0),

              // Middle: Status Label
              Expanded(
                child: Text(
                  _getStatusText(),
                  style: getGeistStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: _state == TurnstileState.success
                        ? const Color(0xFF10B981)
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),

              // Right side: Cloudflare Turnstile branding
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.string(
                        _cloudflareLogoSvg,
                        width: 16.0,
                        height: 16.0,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'Turnstile',
                        style: getGeistStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    'Privacy • Terms',
                    style: getGeistMonoStyle(
                      fontSize: 8.0,
                      fontWeight: FontWeight.w400,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Cloudflare orange logo SVG
const String _cloudflareLogoSvg = '''
<svg viewBox="0 0 24 24" fill="#F38020" xmlns="http://www.w3.org/2000/svg">
  <path d="M7.7 18.5h7.6c.3 0 .6-.1.8-.2l2.3-1.6c.4-.3.5-.9.2-1.3-.3-.4-.9-.5-1.3-.2l-2.1 1.5H7.7c-.5 0-.9-.4-.9-.9 0-.5.4-.9.9-.9h4.3c.4 0 .8-.2.9-.6.2-.4.1-.9-.2-1.2l-2-2.1c-.2-.2-.5-.3-.8-.3H7.7c-1.5 0-2.7-1.2-2.7-2.7 0-1.5 1.2-2.7 2.7-2.7h8.8c.3 0 .6-.1.8-.3L19.4 5c.4-.3.5-.9.2-1.3-.3-.4-.9-.5-1.3-.2l-1.8 1.4H7.7c-2.5 0-4.5 2-4.5 4.5 0 2.1 1.4 3.9 3.4 4.3v.1c-1.3.6-2.2 2-2.2 3.5 0 2.6 2.1 4.7 4.7 4.7" />
  <path d="M22.5 13.9c-.3-.4-.9-.5-1.3-.2l-2.1 1.5h-2.3c.2-.5.3-1 .3-1.6 0-2.5-2-4.5-4.5-4.5h-.7c-.3 0-.6-.1-.8-.3l-2-2.1c-.4-.4-1-.4-1.4 0-.4.4-.4 1 0 1.4l1.9 2h1.6c1.5 0 2.7 1.2 2.7 2.7v.1c-2 0-3.6 1.6-3.6 3.6 0 .5.1 1 .3 1.4h4.7c2.5 0 4.5-2 4.5-4.5 0-.2-.1-.4-.2-.5" />
</svg>
''';
