import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/settings/models/settings_models.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart' as dashboard;

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name =
        (user?.userMetadata?['username'] ??
                user?.userMetadata?['full_name'] ??
                user?.email?.split('@').first ??
                'Alex')
            .toString();
    final email = user?.email ?? 'alex@taskflow.ai';

    return dashboard.GlassCard(
      glowColor: DashboardColors.primary,
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -60,
            child: Icon(
              Icons.settings_suggest_rounded,
              size: compact ? 130 : 180,
              color: DashboardColors.primary.withValues(alpha: .07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const dashboard.ProfileAvatar(radius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            color: DashboardColors.onSurface,
                            fontSize: compact ? 28 : 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.7,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure your workspace and AI performance parameters.',
                          style: TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: compact ? 13 : 15,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .045),
                  borderRadius: BorderRadius.circular(DashboardRadii.md),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .06),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: DashboardColors.onSurface,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email,
                            style: const TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!compact)
                      const dashboard.GradientButton(
                        label: 'Save Changes',
                        icon: Icons.check_rounded,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle({
    required this.title,
    this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: DashboardColors.primary, size: 22),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class IntegrationCard extends StatelessWidget {
  const IntegrationCard({required this.integration, super.key});

  final SettingsIntegration integration;

  @override
  Widget build(BuildContext context) {
    return dashboard.AnimatedHoverCard(
      glowColor: integration.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: integration.color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  integration.icon,
                  color: integration.color,
                  size: 26,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.open_in_new_rounded,
                color: DashboardColors.onSurfaceVariant.withValues(alpha: .55),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            integration.title,
            style: const TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Text(
              integration.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      integration.connected
                          ? const Color(0xFF22C55E)
                          : DashboardColors.outlineVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  integration.status,
                  style: TextStyle(
                    color:
                        integration.connected
                            ? const Color(0xFF22C55E)
                            : DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                integration.buttonText,
                style: TextStyle(
                  color:
                      integration.connected
                          ? DashboardColors.primary
                          : DashboardColors.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ToggleSettingTile extends StatefulWidget {
  const ToggleSettingTile({required this.option, super.key});

  final SettingsToggleOption option;

  @override
  State<ToggleSettingTile> createState() => _ToggleSettingTileState();
}

class _ToggleSettingTileState extends State<ToggleSettingTile> {
  late bool enabled = widget.option.enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(DashboardRadii.md),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: DashboardColors.primary.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              widget.option.icon,
              color: DashboardColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.option.title,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.option.subtitle,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: enabled,
            activeThumbColor: DashboardColors.primary,
            activeTrackColor: DashboardColors.primary.withValues(alpha: .32),
            onChanged: (value) => setState(() => enabled = value),
          ),
        ],
      ),
    );
  }
}

class SecurityActionCard extends StatelessWidget {
  const SecurityActionCard({required this.action, super.key});

  final SettingsActionOption action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(DashboardRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(DashboardRadii.md),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .045),
            borderRadius: BorderRadius.circular(DashboardRadii.md),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: Row(
            children: [
              Icon(action.icon, color: action.color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.subtitle,
                      style: TextStyle(
                        color:
                            action.color == DashboardColors.primary
                                ? DashboardColors.primary
                                : DashboardColors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DashboardColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppearanceOptionTile extends StatelessWidget {
  const AppearanceOptionTile({
    required this.title,
    required this.icon,
    required this.selected,
    super.key,
  });

  final String title;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: DashboardDurations.normal,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            selected
                ? DashboardColors.primaryContainer.withValues(alpha: .12)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(DashboardRadii.md),
        border: Border.all(
          color:
              selected
                  ? DashboardColors.primary.withValues(alpha: .35)
                  : Colors.transparent,
        ),
        boxShadow:
            selected
                ? [
                  BoxShadow(
                    color: DashboardColors.primary.withValues(alpha: .16),
                    blurRadius: 20,
                  ),
                ]
                : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color:
                selected
                    ? DashboardColors.primary
                    : DashboardColors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color:
                    selected
                        ? DashboardColors.onSurface
                        : DashboardColors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (selected)
            const Icon(
              Icons.check_circle_rounded,
              color: DashboardColors.primary,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class AiOptimizationCard extends StatelessWidget {
  const AiOptimizationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return dashboard.GlassCard(
      glowColor: DashboardColors.primary,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -45,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DashboardColors.primary.withValues(alpha: .18),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'AI Optimization',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'NEXUS AI is 94% trained on your workflow.',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: .94),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder:
                    (context, value, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(DashboardRadii.full),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 7,
                        backgroundColor: DashboardColors.surfaceContainer,
                        color: DashboardColors.primary,
                      ),
                    ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Refining context...',
                      style: TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '94%',
                    style: TextStyle(
                      color: DashboardColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const dashboard.GradientButton(
                label: 'Retrain Model',
                icon: Icons.auto_awesome_rounded,
                expanded: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SupportLinkTile extends StatelessWidget {
  const SupportLinkTile({required this.link, super.key});

  final SettingsSupportLink link;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            children: [
              Icon(
                link.icon,
                color: DashboardColors.onSurfaceVariant,
                size: 19,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  link.title,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DashboardColors.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
