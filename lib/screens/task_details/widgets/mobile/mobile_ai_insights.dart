import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileAiInsights extends StatelessWidget {
  const MobileAiInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(24),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: .12)),
              left: BorderSide(color: Colors.white.withValues(alpha: .05)),
              right: BorderSide(color: Colors.white.withValues(alpha: .05)),
              bottom: BorderSide(color: Colors.white.withValues(alpha: .05)),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -16,
                right: -16,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DashboardColors.primary.withValues(alpha: .15),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome_rounded,
                          color: DashboardColors.primary, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'AI Insights',
                        style: TextStyle(
                          color: DashboardColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Build analytics cards first to unblock backend integration.',
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  Divider(
                    color: Colors.white.withValues(alpha: .05),
                    height: 20,
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '87%',
                            style: TextStyle(
                              color: DashboardColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Probability',
                            style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text(
                            '92',
                            style: TextStyle(
                              color: DashboardColors.secondary,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Health Score',
                            style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
