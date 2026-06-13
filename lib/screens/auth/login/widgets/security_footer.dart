import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/login/theme/login_theme.dart';

class SecurityFooter extends StatelessWidget {
  const SecurityFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildItem(Icons.lock_person_outlined, 'AES-256 ENCRYPTED'),
          _buildDivider(),
          _buildItem(Icons.verified_user_outlined, 'SOC2 TYPE II'),
          _buildDivider(),
          _buildItem(Icons.shield_outlined, 'PCI COMPLIANT'),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.0, color: LoginColors.onSurfaceVariant),
        const SizedBox(width: 8.0),
        Text(
          text,
          style: getLoginGeistStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: LoginColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 16.0,
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: LoginColors.glassStroke,
            width: 1.0,
          ),
        ),
      ),
    );
  }
}
