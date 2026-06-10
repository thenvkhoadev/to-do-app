import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/xp/presentation/providers/xp_providers.dart';
import 'package:to_do_app/features/xp/presentation/widgets/xp_level_card.dart'
    show xpLevelTitle;

class LevelDownModal extends ConsumerWidget {
  const LevelDownModal({super.key, required this.newLevel});
  final int newLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(levelDownProvider.notifier).dismiss(),
      child: Material(
        color: Colors.black54,
        child: Center(
          child: _LevelDownCard(
            newLevel: newLevel,
            onDismiss: () => ref.read(levelDownProvider.notifier).dismiss(),
          ),
        ),
      ),
    );
  }
}

class _LevelDownCard extends StatefulWidget {
  const _LevelDownCard({required this.newLevel, required this.onDismiss});
  final int newLevel;
  final VoidCallback onDismiss;

  @override
  State<_LevelDownCard> createState() => _LevelDownCardState();
}

class _LevelDownCardState extends State<_LevelDownCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _opacity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1626).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⬇️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text(
                    'LEVEL DOWN',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Level ${widget.newLevel}',
                    style: const TextStyle(
                      color: Color(0xFFF5F7FF),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    xpLevelTitle(widget.newLevel),
                    style: const TextStyle(
                      color: Color(0xFFA8B2D1),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Subtask was unchecked',
                    style: TextStyle(
                      color: Color(0xFFA8B2D1),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'Understood',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
