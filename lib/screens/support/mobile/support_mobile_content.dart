import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/support/mobile/mobile_category_grid.dart';
import 'package:to_do_app/screens/support/mobile/mobile_faq_section.dart';
import 'package:to_do_app/screens/support/mobile/mobile_support_actions.dart';
import 'package:to_do_app/screens/support/mobile/mobile_support_header.dart';
import 'package:to_do_app/screens/support/mobile/support_mobile_bottom_navigation.dart';
import 'package:to_do_app/screens/support/widgets/support_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class SupportMobileContent extends StatelessWidget {
  const SupportMobileContent({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 92)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(DashboardSpacing.md, 0, DashboardSpacing.md, 136),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      Text('How can we help?', style: TextStyle(color: DashboardColors.onSurface, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                      SizedBox(height: 8),
                      Text('Search our documentation or reach out.', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 16)),
                      SizedBox(height: DashboardSpacing.md),
                      SupportSearchBar(compact: true),
                      SizedBox(height: DashboardSpacing.lg),
                      MobileCategoryGrid(),
                      SizedBox(height: DashboardSpacing.lg),
                      MobileFAQSection(),
                      SizedBox(height: DashboardSpacing.lg),
                      MobileSupportActions(),
                      SizedBox(height: DashboardSpacing.xl),
                      _SupportStatusFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: MobileSupportHeader()),
        Positioned(left: 0, right: 0, bottom: 0, child: SupportMobileBottomNavigation(bottomInset: bottomInset)),
      ],
    );
  }
}

class _SupportStatusFooter extends StatelessWidget {
  const _SupportStatusFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: DashboardColors.primary, shape: BoxShape.circle)), const SizedBox(width: 8), const Text('AI Core Online & Responsive', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontWeight: FontWeight.w800, fontSize: 12))]),
        const SizedBox(height: 7),
        const Text('Average response time: 0.4s', textAlign: TextAlign.center, style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12)),
      ],
    );
  }
}
