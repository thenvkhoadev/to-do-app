import 'package:flutter/material.dart';
import 'package:to_do_app/theme/auth_theme.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        LogoMark(size: compact ? 32 : 40, iconSize: compact ? 20 : 24, radius: compact ? 8 : 12),
        SizedBox(width: compact ? 8 : 12),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [AuthColors.onSurface, AuthColors.onSurface.withValues(alpha: 0.7)],
          ).createShader(bounds),
          child: Text(
            'TaskFlow AI',
            style: compact
                ? AuthTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.4)
                : AuthTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, required this.size, required this.iconSize, required this.radius});

  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AuthColors.primary, AuthColors.secondary],
        ),
        boxShadow: [BoxShadow(color: AuthColors.primary.withValues(alpha: 0.2), blurRadius: 18)],
      ),
      child: Icon(Icons.bolt_rounded, color: AuthColors.background, size: iconSize),
    );
  }
}
