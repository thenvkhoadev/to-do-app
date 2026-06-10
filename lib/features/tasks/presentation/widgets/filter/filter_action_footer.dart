import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterActionFooter extends StatelessWidget {
  const FilterActionFooter({
    required this.onReset,
    required this.onApply,
    super.key,
  });

  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      decoration: BoxDecoration(
        color: const Color(0x800D0E0F),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: .10)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FooterButton(
              label: 'Reset All',
              onTap: onReset,
              outlined: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _FooterButton(
              label: 'Apply Filters',
              onTap: onApply,
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final bg = outlined ? Colors.transparent : const Color(0xFFE1DFFF);
    final fg = outlined ? DashboardColors.onSurface : const Color(0xFF131449);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border:
              outlined
                  ? Border.all(
                    color: const Color(0xFF46464F).withValues(alpha: .30),
                  )
                  : null,
          boxShadow:
              outlined
                  ? null
                  : const [
                    BoxShadow(
                      color: Color(0x33E1DFFF),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: fg, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
