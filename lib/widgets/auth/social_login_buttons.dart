import 'package:flutter/material.dart';
import 'package:to_do_app/theme/auth_theme.dart';
import 'package:to_do_app/widgets/common/glass_card.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _SocialButton(label: 'Google', icon: _GoogleMark())),
        SizedBox(width: 16),
        Expanded(child: _SocialButton(label: 'GitHub', icon: _GithubMark())),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon});

  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: GlassCard(
        radius: 12,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AuthTextStyles.labelSmall.copyWith(
                      color: AuthColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GithubMark extends StatelessWidget {
  const _GithubMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GithubLogoPainter(
          color: AuthColors.onSurface.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.square;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.12, 1.55, false, paint);
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.5),
      Offset(size.width * 0.95, size.height * 0.5),
      paint,
    );
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.43, 1.25, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.68, 1.05, false, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.73, 1.32, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GithubLogoPainter extends CustomPainter {
  const _GithubLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.50, h * 0.00);
    path.cubicTo(w * 0.22, h * 0.00, 0, h * 0.23, 0, h * 0.52);
    path.cubicTo(0, h * 0.75, w * 0.14, h * 0.94, w * 0.34, h * 1.00);
    path.cubicTo(w * 0.36, h * 1.00, w * 0.37, h * 0.99, w * 0.37, h * 0.97);
    path.lineTo(w * 0.37, h * 0.86);
    path.cubicTo(w * 0.23, h * 0.89, w * 0.20, h * 0.80, w * 0.20, h * 0.80);
    path.cubicTo(w * 0.18, h * 0.74, w * 0.13, h * 0.72, w * 0.13, h * 0.72);
    path.cubicTo(w * 0.08, h * 0.68, w * 0.13, h * 0.68, w * 0.13, h * 0.68);
    path.cubicTo(w * 0.19, h * 0.69, w * 0.22, h * 0.75, w * 0.22, h * 0.75);
    path.cubicTo(w * 0.27, h * 0.84, w * 0.35, h * 0.81, w * 0.37, h * 0.80);
    path.cubicTo(w * 0.38, h * 0.76, w * 0.40, h * 0.74, w * 0.42, h * 0.72);
    path.cubicTo(w * 0.31, h * 0.71, w * 0.19, h * 0.67, w * 0.19, h * 0.46);
    path.cubicTo(w * 0.19, h * 0.40, w * 0.21, h * 0.35, w * 0.25, h * 0.31);
    path.cubicTo(w * 0.25, h * 0.29, w * 0.22, h * 0.22, w * 0.26, h * 0.14);
    path.cubicTo(w * 0.26, h * 0.14, w * 0.31, h * 0.12, w * 0.42, h * 0.20);
    path.cubicTo(w * 0.47, h * 0.19, w * 0.53, h * 0.19, w * 0.58, h * 0.20);
    path.cubicTo(w * 0.69, h * 0.12, w * 0.74, h * 0.14, w * 0.74, h * 0.14);
    path.cubicTo(w * 0.78, h * 0.22, w * 0.75, h * 0.29, w * 0.75, h * 0.31);
    path.cubicTo(w * 0.79, h * 0.35, w * 0.81, h * 0.40, w * 0.81, h * 0.46);
    path.cubicTo(w * 0.81, h * 0.67, w * 0.69, h * 0.71, w * 0.58, h * 0.72);
    path.cubicTo(w * 0.61, h * 0.75, w * 0.62, h * 0.79, w * 0.62, h * 0.85);
    path.lineTo(w * 0.62, h * 0.97);
    path.cubicTo(w * 0.62, h * 0.99, w * 0.64, h * 1.00, w * 0.66, h * 1.00);
    path.cubicTo(w * 0.86, h * 0.94, w, h * 0.75, w, h * 0.52);
    path.cubicTo(w, h * 0.23, w * 0.78, 0, w * 0.50, 0);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GithubLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
