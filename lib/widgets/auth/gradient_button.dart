import 'package:flutter/material.dart';
import 'package:to_do_app/theme/auth_theme.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: AuthColors.primaryContainer.withValues(alpha: 0.24), blurRadius: 24)],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: onPressed == null
                    ? [AuthColors.outlineVariant, AuthColors.outlineVariant.withValues(alpha: 0.7)]
                    : const [AuthColors.primaryContainer, AuthColors.secondaryContainer],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 56, minWidth: double.infinity),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      label,
                      style: AuthTextStyles.headlineMedium.copyWith(
                        color: AuthColors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
