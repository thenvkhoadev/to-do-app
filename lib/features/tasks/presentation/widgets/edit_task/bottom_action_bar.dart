import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskBottomActionBar extends StatefulWidget {
  const TaskBottomActionBar({
    required this.onSave,
    required this.onCancel,
    required this.onDelete,
    required this.isMobile,
    this.isSaving = false,
    super.key,
  });

  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final bool isMobile;
  final bool isSaving;

  @override
  State<TaskBottomActionBar> createState() => _TaskBottomActionBarState();
}

class _TaskBottomActionBarState extends State<TaskBottomActionBar> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: DashboardColors.surface.withValues(alpha: 0.85),
          border: const Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: DashboardColors.onSurface,
                  side: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: widget.isSaving ? null : widget.onSave,
                icon: widget.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF292B5E)),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(widget.isSaving ? 'Saving...' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE1DFFF),
                  foregroundColor: const Color(0xFF292B5E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Desktop: floating bar
    return Center(
      child: Container(
        width: 600,
        height: 72,
        margin: const EdgeInsets.only(bottom: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: DashboardColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Delete button
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_rounded, color: DashboardColors.onSurfaceVariant, size: 18),
                    label: const Text('Delete Task', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: DashboardColors.onSurfaceVariant,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(Colors.red.withValues(alpha: 0.08)),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: widget.onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: DashboardColors.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      // Pulsing Save Changes button
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: DashboardColors.primaryContainer.withValues(alpha: 0.2),
                                  blurRadius: _pulseAnimation.value,
                                  spreadRadius: _pulseAnimation.value / 2,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: ElevatedButton(
                          onPressed: widget.isSaving ? null : widget.onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC0C1FF),
                            foregroundColor: const Color(0xFF292B5E),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            elevation: 8,
                          ),
                          child: widget.isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF292B5E)),
                                )
                              : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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
