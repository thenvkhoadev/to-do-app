import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileFocusForecast extends StatelessWidget {
  const MobileFocusForecast({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x26C0C1FF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x33C0C1FF)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DashboardColors.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: DashboardColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Focus Forecast',
                    style: TextStyle(
                      color: DashboardColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '14:00 - 16:00 High Productivity Window',
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
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
