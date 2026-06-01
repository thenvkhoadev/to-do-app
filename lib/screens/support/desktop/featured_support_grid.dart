import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/support/data/support_mock_data.dart';
import 'package:to_do_app/screens/support/widgets/support_shared_widgets.dart';

class FeaturedSupportGrid extends StatelessWidget {
  const FeaturedSupportGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1080
                ? 3
                : constraints.maxWidth >= 720
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: SupportMockData.categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: DashboardSpacing.md,
            mainAxisSpacing: DashboardSpacing.md,
            childAspectRatio: columns == 1 ? 2.4 : (columns == 2 ? 1.55 : 1.05),
          ),
          itemBuilder:
              (context, index) => SupportCategoryCard(
                category: SupportMockData.categories[index],
              ),
        );
      },
    );
  }
}
