import 'dart:math';
import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';

class TurnstileChallenge extends StatefulWidget {
  const TurnstileChallenge({required this.onTokenChanged, super.key});

  final ValueChanged<String?> onTokenChanged;

  @override
  State<TurnstileChallenge> createState() => _TurnstileChallengeState();
}

class _TurnstileChallengeState extends State<TurnstileChallenge> {
  late int _num1;
  late int _num2;
  late String _operator;
  late int _correctAnswer;
  final TextEditingController _controller = TextEditingController();
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _generateChallenge();
    _controller.addListener(_onAnswerChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _notifyToken(String? token) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onTokenChanged(token);
        }
      });
    }
  }

  void _generateChallenge() {
    final rand = Random();
    _num1 = rand.nextInt(9) + 1; // 1-9
    _num2 = rand.nextInt(9) + 1; // 1-9
    _operator = '+';
    _correctAnswer = _num1 + _num2;
    _controller.clear();
    _isCorrect = false;
    _notifyToken(null);
  }

  void _onAnswerChanged() {
    final val = _controller.text.trim();
    if (val == _correctAnswer.toString()) {
      if (!_isCorrect) {
        setState(() {
          _isCorrect = true;
        });
        // Token format: "num1+num2=answer"
        _notifyToken('$_num1$_operator$_num2=$_correctAnswer');
      }
    } else {
      if (_isCorrect) {
        setState(() {
          _isCorrect = false;
        });
        _notifyToken(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0x990D1322),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: RegisterColors.glassStroke, width: 1.0),
      ),
      child: Row(
        children: [
          // Left: Security Icon with soft glow
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: RegisterColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: _isCorrect
                    ? RegisterColors.successGreen.withValues(alpha: 0.3)
                    : RegisterColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              _isCorrect ? Icons.verified_user_rounded : Icons.shield_rounded,
              color: _isCorrect ? RegisterColors.successGreen : RegisterColors.primary,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 14.0),

          // Middle: Challenge Question
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECURITY CHECK',
                  style: getGeistStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: _isCorrect
                        ? RegisterColors.successGreen
                        : RegisterColors.primary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _isCorrect ? 'Verification complete' : 'What is $_num1 + $_num2 ?',
                  style: getGeistStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: _isCorrect
                        ? RegisterColors.successGreen
                        : RegisterColors.text,
                  ),
                ),
              ],
            ),
          ),

          // Right: Input field or Success Checkmark
          if (_isCorrect)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: RegisterColors.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: RegisterColors.successGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: RegisterColors.successGreen,
                    size: 16.0,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    'Passed',
                    style: getGeistStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: RegisterColors.successGreen,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text Field for Answer
                SizedBox(
                  width: 70.0,
                  height: 40.0,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: getGeistMonoStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: RegisterColors.text,
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: const Color(0x33FFFFFF),
                      hintText: '?',
                      hintStyle: getGeistStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: RegisterColors.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: RegisterColors.glassStroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: RegisterColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // Reload Button
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20.0),
                  color: RegisterColors.onSurfaceVariant,
                  tooltip: 'New question',
                  onPressed: _generateChallenge,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
