import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/support/data/support_mock_data.dart';
import 'package:to_do_app/screens/support/widgets/support_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileFAQSection extends StatelessWidget {
  const MobileFAQSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('COMMON QUESTIONS', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: DashboardSpacing.sm),
        for (final faq in SupportMockData.faqs.take(3)) ...[
          SupportFAQTile(faq: faq),
          if (faq != SupportMockData.faqs.take(3).last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
