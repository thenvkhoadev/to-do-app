import 'package:flutter/material.dart';
import 'design_system.dart';

class FooterSection extends StatelessWidget {
  final double width;

  const FooterSection({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final isMobile = width < 768;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: LandingColors.surfaceContainerLowest, // Matches bg-surface-container-lowest
        border: Border(
          top: BorderSide(
            color: LandingColors.glassBorder,
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24.0,
        48.0,
        24.0,
        isMobile ? 120.0 : 24.0, // Extra bottom padding on mobile for bottom navigation bar
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440.0),
          child: isMobile ? _buildMobileFooter() : _buildDesktopFooter(),
        ),
      ),
    );
  }

  Widget _buildDesktopFooter() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand & Copyright
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nexus AI',
                style: getLandingGeistStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w900,
                  color: LandingColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                '© 2024 Nexus AI. Boundless Focus.',
                style: getLandingGeistStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                  color: LandingColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Product Link column
        Expanded(
          child: _buildLinkColumn(
            'Product',
            ['Features', 'Intelligence', 'Pricing'],
          ),
        ),

        // Company Link column
        Expanded(
          child: _buildLinkColumn(
            'Company',
            ['About', 'Security', 'LinkedIn'],
          ),
        ),

        // Resources Link column
        Expanded(
          child: _buildLinkColumn(
            'Resources',
            ['GitHub', 'Documentation', 'Status'],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand & Copyright
        Text(
          'Nexus AI',
          style: getLandingGeistStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w900,
            color: LandingColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          '© 2024 Nexus AI. Boundless Focus.',
          style: getLandingGeistStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w400,
            color: LandingColors.textSecondary.withValues(alpha: 0.60),
          ),
        ),
        const SizedBox(height: 32.0),

        // Links Row (2 columns on mobile)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLinkColumn(
                'Product',
                ['Features', 'Pricing', 'Intelligence'],
              ),
            ),
            Expanded(
              child: _buildLinkColumn(
                'Company',
                ['About', 'Career', 'Contact'],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkColumn(String header, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header.toUpperCase(),
          style: getLandingGeistStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: LandingColors.secondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16.0),
        ...links.map((link) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: HoverBuilder(
              builder: (context, isHovered) {
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {},
                    child: Text(
                      link,
                      style: getLandingGeistStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: isHovered ? LandingColors.tertiary : LandingColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
