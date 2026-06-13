import 'package:flutter/material.dart';
import 'design_system.dart';

class AiCommandBar extends StatelessWidget {
  const AiCommandBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isFocused = ValueNotifier<bool>(false);

    return Focus(
      onFocusChange: (hasFocus) {
        isFocused.value = hasFocus;
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: isFocused,
        builder: (context, focused, _) {
          return GlassCard(
            borderRadius: 9999.0,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            borderColor: focused
                ? const Color(0x99C0C1FF) // active-glow border
                : LandingColors.glassBorder,
            boxShadow: [
              BoxShadow(
                color: focused
                    ? const Color(0xFFC0C1FF).withValues(alpha: 0.30)
                    : Colors.black.withValues(alpha: 0.37),
                blurRadius: focused ? 24.0 : 32.0,
                spreadRadius: focused ? 2.0 : 0.0,
                offset: const Offset(0, 8),
              ),
            ],
            child: Row(
              children: [
                // Spark Icon
                const Icon(
                  Icons.auto_awesome,
                  color: LandingColors.primary,
                  size: 20.0,
                ),
                const SizedBox(width: 12.0),
                
                // Input TextField
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ask Nexus anything...',
                      hintStyle: getLandingGeistStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: LandingColors.textSecondary.withValues(alpha: 0.50),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: getLandingGeistStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w400,
                      color: LandingColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),

                // Submit Button
                PressableScale(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: LandingColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Color(0xFF131449),
                      size: 20.0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
