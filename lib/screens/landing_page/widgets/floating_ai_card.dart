import 'package:flutter/material.dart';
import 'design_system.dart';
import 'animated_float.dart';

class FloatingAiCard extends StatelessWidget {
  const FloatingAiCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedFloat(
      delay: Duration.zero,
      child: GlassCard(
        padding: const EdgeInsets.all(24.0),
        borderRadius: 16.0,
        child: SizedBox(
          width: 256.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Insights',
                    style: getLandingGeistStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: LandingColors.secondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Icon(
                    Icons.bolt,
                    color: LandingColors.secondary,
                    size: 20.0,
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text(
                '"Focus is peaking. You\'re 40% more productive during 9AM - 11AM blocks."',
                style: getLandingGeistStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                  color: LandingColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
