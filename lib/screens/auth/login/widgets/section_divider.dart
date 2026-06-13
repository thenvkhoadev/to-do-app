import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/login/theme/login_theme.dart';

class SectionDivider extends StatelessWidget {
  const SectionDivider({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: LoginColors.glassStroke,
            height: 1.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            text,
            style: getLoginGeistStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: LoginColors.outline,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: LoginColors.glassStroke,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
