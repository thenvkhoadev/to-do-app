import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/support/desktop/contact_support_section.dart';
import 'package:to_do_app/screens/support/desktop/featured_support_grid.dart';
import 'package:to_do_app/screens/support/desktop/hero_support_section.dart';
import 'package:to_do_app/screens/support/desktop/proactive_support_section.dart';
import 'package:to_do_app/screens/support/desktop/support_footer.dart';
import 'package:to_do_app/screens/support/desktop/support_header.dart';

class SupportDesktopContent extends StatelessWidget {
  const SupportDesktopContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SupportHeader(),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: DashboardSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: DashboardSpacing.desktopMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HeroSupportSection(),
                          FeaturedSupportGrid(),
                          SizedBox(height: DashboardSpacing.xl),
                          ProactiveSupportSection(),
                          SizedBox(height: DashboardSpacing.xl),
                          ContactSupportSection(),
                          SizedBox(height: DashboardSpacing.lg),
                          SupportFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
