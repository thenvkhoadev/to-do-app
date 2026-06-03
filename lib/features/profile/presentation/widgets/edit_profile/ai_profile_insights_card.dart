import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class AiProfileInsightsCard extends StatelessWidget {
  const AiProfileInsightsCard({
    required this.onApplySuggestions,
    super.key,
  });

  final VoidCallback onApplySuggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // AI Recommendation Banner
        EditProfileGlassCard(
          borderColor: EditProfileColors.primary.withValues(alpha: 0.2),
          backgroundColor: EditProfileColors.primary.withValues(alpha: 0.05),
          child: Stack(
            children: [
              Positioned(
                top: -10,
                right: -10,
                child: Opacity(
                  opacity: 0.15,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 80,
                    color: EditProfileColors.primary,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.psychology, color: EditProfileColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AI OPTIMIZER RECOMMENDATION',
                        style: TextStyle(
                          color: EditProfileColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Boost your discoverability by 42%',
                    style: TextStyle(
                      color: EditProfileColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our neural engine suggests adding your "Cloud Architecture" skills and syncing your GitHub account. This will help match you with high-precision Deep Work squads.',
                    style: TextStyle(
                      color: EditProfileColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onApplySuggestions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EditProfileColors.primary.withValues(alpha: 0.2),
                      foregroundColor: EditProfileColors.primary,
                      elevation: 0,
                      side: BorderSide(color: EditProfileColors.primary.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Apply All Suggestions', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // AI Focus Insights Row/Grid
        EditProfileGlassCard(
          borderColor: EditProfileColors.primary.withValues(alpha: 0.2),
          backgroundColor: EditProfileColors.primary.withValues(alpha: 0.05),
          child: Row(
            children: [
              const Icon(Icons.insights, color: EditProfileColors.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'AI Focus Insights',
                      style: TextStyle(color: EditProfileColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Optimization analytics for your current flow cycle.',
                      style: TextStyle(color: EditProfileColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'PEAK WINDOW',
                        style: TextStyle(color: EditProfileColors.textOutline, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '09:00 - 11:30',
                        style: TextStyle(color: EditProfileColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'CONSISTENCY',
                        style: TextStyle(color: EditProfileColors.textOutline, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '94%',
                        style: TextStyle(color: EditProfileColors.success, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
