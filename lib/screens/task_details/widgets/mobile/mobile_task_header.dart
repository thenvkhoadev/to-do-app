import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileTaskHeader extends StatelessWidget {
  const MobileTaskHeader({required this.item, required this.onBack, super.key});
  final TaskBoardItem item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hero gradient background
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 280),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x66321ED2), Color(0xFF121315), Color(0xFF121315)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Opacity(
                  opacity: .15,
                  child: const Icon(Icons.auto_awesome_rounded,
                      size: 120, color: DashboardColors.primary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Pill(
                          label: item.status.name.toUpperCase(),
                          bg: Colors.white.withValues(alpha: .05),
                          border: Colors.white.withValues(alpha: .08),
                          textColor: DashboardColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          label: item.priorityLabel.toUpperCase(),
                          bg: DashboardColors.warning.withValues(alpha: .10),
                          border: DashboardColors.warning.withValues(alpha: .30),
                          textColor: DashboardColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.56,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroButton(
                            label: 'Start Task',
                            icon: Icons.play_arrow_rounded,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        _GlassIconBtn(icon: Icons.edit_outlined),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bg,
    required this.border,
    required this.textColor,
  });
  final String label;
  final Color bg, border, textColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
      );
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: DashboardColors.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: DashboardColors.onPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: DashboardColors.onPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

class _GlassIconBtn extends StatelessWidget {
  const _GlassIconBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: .12),
                width: .5,
              ),
            ),
            child: Icon(icon, color: DashboardColors.onSurface, size: 22),
          ),
        ),
      );
}
