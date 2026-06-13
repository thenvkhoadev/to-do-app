import 'package:flutter/material.dart';
import 'design_system.dart';
import 'animated_float.dart';

class FloatingXpCard extends StatelessWidget {
  const FloatingXpCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedFloat(
      delay: const Duration(milliseconds: 1500),
      child: GlassCard(
        padding: const EdgeInsets.all(24.0),
        borderRadius: 16.0,
        child: SizedBox(
          width: 288.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: LandingColors.primary.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: LandingColors.primary.withValues(alpha: 0.30),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.military_tech,
                      color: LandingColors.primary,
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LVL 42',
                          style: getLandingGeistStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.w600,
                            color: LandingColors.textPrimary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '2,450 / 3,000 XP',
                          style: getLandingGeistStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: LandingColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(3.0),
                child: Container(
                  height: 6.0,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: LandingColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFC0C1FF),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
