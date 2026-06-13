import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/login/theme/login_theme.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        gradient: const LinearGradient(
          colors: [LoginColors.primary, LoginColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: LoginColors.secondary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: loading ? null : onPressed,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(LoginColors.background),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: getLoginGeistStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: LoginColors.background,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 8.0),
                        Icon(
                          icon,
                          color: LoginColors.background,
                          size: 20.0,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
