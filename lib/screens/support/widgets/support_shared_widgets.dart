import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/support/models/support_models.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart' as dashboard;

class SupportSearchBar extends StatelessWidget {
  const SupportSearchBar({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return dashboard.GlassCard(
      glowColor: DashboardColors.primary,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 6 : 8,
      ),
      radius: compact ? DashboardRadii.lg : 22,
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: DashboardColors.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: const TextStyle(color: DashboardColors.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText:
                    compact
                        ? 'Search support...'
                        : 'Search the help center, FAQs, or AI commands...',
                hintStyle: TextStyle(
                  color: DashboardColors.onSurfaceVariant.withValues(
                    alpha: .58,
                  ),
                ),
              ),
            ),
          ),
          if (!compact)
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: DashboardColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Search',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ),
    );
  }
}

class SupportSectionTitle extends StatelessWidget {
  const SupportSectionTitle({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class SupportCategoryCard extends StatelessWidget {
  const SupportCategoryCard({
    required this.category,
    this.compact = false,
    super.key,
  });

  final SupportCategory category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return dashboard.GlassCard(
        padding: const EdgeInsets.all(18),
        radius: DashboardRadii.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(category.icon, color: category.color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              category.label,
              style: TextStyle(
                color: category.color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.title,
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ],
        ),
      );
    }

    return dashboard.AnimatedHoverCard(
      glowColor: category.color,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(category.icon, color: category.color, size: 29),
          ),
          const SizedBox(height: 22),
          Text(
            category.title,
            style: const TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            category.description,
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (category.links.isNotEmpty) ...[
            const SizedBox(height: 22),
            for (final link in category.links)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        link,
                        style: const TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class SupportFAQTile extends StatelessWidget {
  const SupportFAQTile({required this.faq, super.key});

  final SupportFAQ faq;

  @override
  Widget build(BuildContext context) {
    return dashboard.GlassCard(
      padding: EdgeInsets.zero,
      radius: DashboardRadii.lg,
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
            iconColor: DashboardColors.primary,
            collapsedIconColor: DashboardColors.onSurfaceVariant,
            title: Text(
              faq.question,
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            children: [
              Text(
                faq.answer,
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SupportGlowContainer extends StatelessWidget {
  const SupportGlowContainer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          colors: [
            DashboardColors.surfaceHigh.withValues(alpha: .8),
            DashboardColors.background,
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.primary.withValues(alpha: .16),
            blurRadius: 60,
          ),
        ],
      ),
      child: child,
    );
  }
}

class SupportTextField extends StatelessWidget {
  const SupportTextField({
    required this.label,
    this.maxLines = 1,
    this.hint,
    super.key,
  });

  final String label;
  final int maxLines;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          style: const TextStyle(color: DashboardColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: DashboardColors.onSurfaceVariant.withValues(alpha: .55),
            ),
            filled: true,
            fillColor: DashboardColors.surfaceContainer.withValues(alpha: .75),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: .10),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: DashboardColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
