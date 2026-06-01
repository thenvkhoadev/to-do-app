import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/support/data/support_mock_data.dart';
import 'package:to_do_app/screens/support/widgets/support_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class ProactiveSupportSection extends StatelessWidget {
  const ProactiveSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SupportSectionTitle(
          title: 'Proactive Support',
          subtitle:
              'We identified these trending questions from users like you.',
          trailing: Text(
            'View all FAQs →',
            style: TextStyle(
              color: DashboardColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: DashboardSpacing.md),
        for (final faq in SupportMockData.faqs.take(3)) ...[
          SupportFAQTile(faq: faq),
          if (faq != SupportMockData.faqs.take(3).last)
            const SizedBox(height: 12),
        ],
      ],
    );
  }
}
