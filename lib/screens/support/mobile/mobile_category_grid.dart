import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/support/data/support_mock_data.dart';
import 'package:to_do_app/screens/support/widgets/support_shared_widgets.dart';

class MobileCategoryGrid extends StatelessWidget {
  const MobileCategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: DashboardSpacing.sm,
        mainAxisSpacing: DashboardSpacing.sm,
        childAspectRatio: .92,
      ),
      itemBuilder:
          (context, index) => SupportCategoryCard(
            category: SupportMockData.categories[index],
            compact: true,
          ),
    );
  }
}
