import 'dart:async';
import 'package:flutter/material.dart';

class PremiumToast {
  static _PremiumToastWidgetState? _currentState;

  static void show(BuildContext context, String message, {bool isError = false}) {
    dismiss();

    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _PremiumToastWidget(
          message: message,
          isError: isError,
          onStateCreated: (state) {
            _currentState = state;
          },
          onFinished: () {
            entry.remove();
            _currentState = null;
          },
        );
      },
    );

    overlayState.insert(entry);
  }

  static void dismiss() {
    _currentState?.dismissWithAnimation();
  }
}

class _PremiumToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final ValueChanged<_PremiumToastWidgetState> onStateCreated;
  final VoidCallback onFinished;

  const _PremiumToastWidget({
    required this.message,
    required this.isError,
    required this.onStateCreated,
    required this.onFinished,
  });

  @override
  State<_PremiumToastWidget> createState() => _PremiumToastWidgetState();
}

class _PremiumToastWidgetState extends State<_PremiumToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    _autoDismissTimer = Timer(const Duration(milliseconds: 2500), () {
      dismissWithAnimation();
    });
  }

  void dismissWithAnimation() {
    _autoDismissTimer?.cancel();
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onFinished();
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF151827),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isError ? Colors.redAccent.withValues(alpha: 0.3) : const Color(0xFF7C5CFF).withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                      color: widget.isError ? Colors.redAccent : const Color(0xFFA78BFA),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
