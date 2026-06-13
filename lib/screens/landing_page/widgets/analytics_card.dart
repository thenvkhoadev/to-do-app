import 'package:flutter/material.dart';
import 'design_system.dart';

class AnalyticsCard extends StatelessWidget {
  const AnalyticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (context, isHovered) {
        return GlassCard(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              // Left side (Text content)
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Deep Analytics',
                        style: getLandingGeistStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.w600,
                          color: LandingColors.textPrimary,
                          letterSpacing: -0.48,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Visualize your progress with high-density data charts that track cognitive load and output quality.',
                        style: getLandingGeistStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w400,
                          color: LandingColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16.0),

              // Right side (Interactive Bar Chart)
              Expanded(
                flex: 1,
                child: Container(
                  height: 160.0,
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(isHovered ? 0.60 : 0.40, opacity: 0.20, delayMs: 0),
                      _buildBar(isHovered ? 0.80 : 0.60, opacity: 0.40, delayMs: 75),
                      _buildBar(isHovered ? 0.70 : 0.90, opacity: 0.60, delayMs: 100),
                      _buildBar(isHovered ? 0.90 : 0.50, opacity: 0.40, delayMs: 150),
                      _buildBar(isHovered ? 0.50 : 0.70, opacity: 0.20, delayMs: 200),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(double fillFactor, {required double opacity, required int delayMs}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight;
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          tween: Tween<double>(begin: fillFactor, end: fillFactor),
          builder: (context, val, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              width: 16.0,
              height: maxHeight * val,
              decoration: BoxDecoration(
                color: LandingColors.primary.withValues(alpha: opacity),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
