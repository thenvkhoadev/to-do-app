import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FloatingAIButton extends StatefulWidget {
  const FloatingAIButton({this.addIcon = false, super.key});

  final bool addIcon;

  @override
  State<FloatingAIButton> createState() => _FloatingAIButtonState();
}

class _FloatingAIButtonState extends State<FloatingAIButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 58,
        height: 58,
        transform: Matrix4.diagonal3Values(
          _hovered ? 1.08 : 1.0,
          _hovered ? 1.08 : 1.0,
          1,
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [DashboardColors.primary, DashboardColors.secondary],
          ),
          boxShadow: [
            BoxShadow(
              color: DashboardColors.primary.withValues(
                alpha: _hovered ? .55 : .36,
              ),
              blurRadius: _hovered ? 34 : 24,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            child: Icon(
              widget.addIcon ? Icons.add_rounded : Icons.bolt_rounded,
              color: DashboardColors.onPrimary,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
