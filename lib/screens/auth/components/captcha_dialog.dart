import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';

class CaptchaDialog extends StatefulWidget {
  const CaptchaDialog({required this.onSuccess, super.key});

  final VoidCallback onSuccess;

  static void show(BuildContext context, VoidCallback onSuccess) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      barrierDismissible: true,
      builder: (_) => CaptchaDialog(onSuccess: onSuccess),
    );
  }

  @override
  State<CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<CaptchaDialog>
    with SingleTickerProviderStateMixin {
  double _sliderOffset = 0.0;
  bool _isVerified = false;
  bool _closing = false;

  late final AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _resetSlider() {
    _resetAnimation = Tween<double>(
      begin: _sliderOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutBack,
    ))
      ..addListener(() {
        setState(() {
          _sliderOffset = _resetAnimation.value;
        });
      });
    _resetController.reset();
    _resetController.forward();
  }

  void _handleSuccess() {
    setState(() {
      _isVerified = true;
    });
    
    // Auto close after 600ms of success presentation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && !_closing) {
        _closing = true;
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const double thumbWidth = 56.0;
    const double trackHeight = 56.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
            child: Container(
              width: 380.0,
              padding: const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                color: const Color(0xEC0D1322), // Deep glass dark
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: RegisterColors.glassStroke,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40.0,
                    spreadRadius: 5.0,
                  ),
                  if (_isVerified)
                    BoxShadow(
                      color: RegisterColors.successGreen.withValues(alpha: 0.15),
                      blurRadius: 30.0,
                      spreadRadius: 2.0,
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title bar with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isVerified ? 'Verification Passed' : 'Security Check',
                        style: getGeistStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                          color: _isVerified
                              ? RegisterColors.successGreen
                              : RegisterColors.text,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                          size: 20.0,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    _isVerified
                        ? 'Successfully verified as a human visitor.'
                        : 'Drag the slider to the right to verify you are not a machine.',
                    style: getGeistStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                      color: RegisterColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // Captcha slider track
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxOffset = constraints.maxWidth - thumbWidth;

                      return Container(
                        height: trackHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0x99050811),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: _isVerified
                                ? RegisterColors.successGreen.withValues(alpha: 0.4)
                                : RegisterColors.glassStroke,
                            width: 1.0,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // "Slide to verify" text indicator
                            if (!_isVerified)
                              Opacity(
                                opacity: (1.0 - (_sliderOffset / maxOffset))
                                    .clamp(0.1, 1.0),
                                child: Text(
                                  'Slide to verify',
                                  style: getGeistStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                    color: RegisterColors.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              )
                            else
                              Text(
                                'VERIFIED',
                                style: getGeistStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w700,
                                  color: RegisterColors.successGreen,
                                  letterSpacing: 1.5,
                                ),
                              ),

                            // Draggable thumb container
                            Positioned(
                              left: _sliderOffset,
                              top: 0.0,
                              bottom: 0.0,
                              child: GestureDetector(
                                onHorizontalDragUpdate: _isVerified
                                    ? null
                                    : (details) {
                                        setState(() {
                                          _sliderOffset = (_sliderOffset +
                                                  details.delta.dx)
                                              .clamp(0.0, maxOffset);
                                        });
                                      },
                                onHorizontalDragEnd: _isVerified
                                    ? null
                                    : (details) {
                                        if (_sliderOffset >= maxOffset * 0.95) {
                                          setState(() {
                                            _sliderOffset = maxOffset;
                                          });
                                          _handleSuccess();
                                        } else {
                                          _resetSlider();
                                        }
                                      },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  width: thumbWidth,
                                  margin: const EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    gradient: _isVerified
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFFE4F222),
                                              Color(0xFFB0C400)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : const LinearGradient(
                                            colors: [
                                              Color(0xFFE1DFFF),
                                              Color(0xFFC0C1FF)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isVerified
                                            ? RegisterColors.successGreen
                                                .withValues(alpha: 0.4)
                                            : RegisterColors.secondary
                                                .withValues(alpha: 0.25),
                                        blurRadius: 8.0,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isVerified
                                        ? Icons.check_rounded
                                        : Icons.double_arrow_rounded,
                                    color: const Color(0xFF131449),
                                    size: 24.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
