import 'package:flutter/material.dart';
import 'package:to_do_app/theme/auth_theme.dart';
import 'package:to_do_app/widgets/auth/privacy_policy_dialog.dart';

class FooterLinks extends StatelessWidget {
  const FooterLinks({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Already have an account?',
              style: AuthTextStyles.bodyMedium.copyWith(
                color: AuthColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: onLogin,
              style: TextButton.styleFrom(
                foregroundColor: AuthColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Log in',
                style: AuthTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AuthColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _FooterLink(label: 'Privacy Policy'),
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AuthColors.outlineVariant.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            const _FooterLink(label: 'Terms of Service'),
          ],
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (label == 'Privacy Policy') {
          showDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.72),
            builder: (context) => const PrivacyPolicyDialog(),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          style: AuthTextStyles.labelSmall.copyWith(
            color: AuthColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
