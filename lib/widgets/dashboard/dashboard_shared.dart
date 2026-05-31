import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DashboardBackground extends StatelessWidget {
  const DashboardBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: ColoredBox(color: DashboardColors.background),
        ),
        const Positioned(
          top: -170,
          right: -150,
          child: GlowOrb(size: 520, color: DashboardColors.primary),
        ),
        const Positioned(
          bottom: -160,
          left: -150,
          child: GlowOrb(size: 520, color: DashboardColors.secondary),
        ),
        Positioned(
          top: 260,
          left: MediaQuery.sizeOf(context).width * .38,
          child: const GlowOrb(
            size: 320,
            color: DashboardColors.tertiary,
            opacity: .08,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class GlowOrb extends StatelessWidget {
  const GlowOrb({
    required this.size,
    required this.color,
    this.opacity = .12,
    super.key,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .92, end: 1.04),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      builder:
          (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity),
              blurRadius: 150,
              spreadRadius: 70,
            ),
          ],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(DashboardSpacing.lg),
    this.radius = DashboardRadii.xl,
    this.glowColor,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? glowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .035),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
            boxShadow: [
              BoxShadow(
                color: (glowColor ?? Colors.black).withValues(
                  alpha: glowColor == null ? .16 : .16,
                ),
                blurRadius: glowColor == null ? 22 : 34,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class AnimatedHoverCard extends StatefulWidget {
  const AnimatedHoverCard({
    required this.child,
    this.glowColor,
    this.padding = const EdgeInsets.all(DashboardSpacing.lg),
    super.key,
  });

  final Widget child;
  final Color? glowColor;
  final EdgeInsetsGeometry padding;

  @override
  State<AnimatedHoverCard> createState() => _AnimatedHoverCardState();
}

class _AnimatedHoverCardState extends State<AnimatedHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: DashboardDurations.normal,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        child: GlassCard(
          padding: widget.padding,
          glowColor: _hovered ? widget.glowColor : null,
          child: widget.child,
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.expanded = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(DashboardRadii.full),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              DashboardColors.primaryContainer,
              DashboardColors.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(DashboardRadii.full),
          boxShadow: [
            BoxShadow(
              color: DashboardColors.primary.withValues(alpha: .22),
              blurRadius: 28,
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(DashboardRadii.full),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DashboardBackground(child: SafeArea(top: false, child: child)),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning, Alex',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your productivity cycle is in its peak phase. You have completed 4 focus blocks today.',
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 18,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            const DeepWorkPill(),
          ],
        ),
      ],
    );
  }
}

class DeepWorkPill extends StatelessWidget {
  const DeepWorkPill({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: DashboardRadii.full,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .45, end: 1),
            duration: const Duration(seconds: 2),
            builder:
                (context, value, child) =>
                    Opacity(opacity: value, child: child),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DashboardColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: DashboardColors.primary.withValues(alpha: .7),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'DEEP WORK ACTIVE',
            style: TextStyle(
              color: DashboardColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.label,
    this.icon,
    this.color = DashboardColors.onSurfaceVariant,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
      ],
    );
  }
}

class ProfileNavigationScope extends InheritedWidget {
  const ProfileNavigationScope({
    required this.onProfileSelected,
    required super.child,
    super.key,
  });

  final VoidCallback onProfileSelected;

  static VoidCallback? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ProfileNavigationScope>()
        ?.onProfileSelected;
  }

  @override
  bool updateShouldNotify(ProfileNavigationScope oldWidget) =>
      onProfileSelected != oldWidget.onProfileSelected;
}

/// Lets embedded panes (e.g. the profile) switch dashboard sections
/// (New Task / Projects board) without losing the dashboard shell.
class SectionNavigationScope extends InheritedWidget {
  const SectionNavigationScope({
    required this.onNewTask,
    required this.onProjects,
    required super.child,
    super.key,
  });

  final VoidCallback onNewTask;
  final VoidCallback onProjects;

  static SectionNavigationScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SectionNavigationScope>();
  }

  @override
  bool updateShouldNotify(SectionNavigationScope oldWidget) =>
      onNewTask != oldWidget.onNewTask || onProjects != oldWidget.onProjects;
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    this.radius = 18,
    this.onTap,
    this.showUsername = true,
    super.key,
  });

  final double radius;
  final VoidCallback? onTap;
  final bool showUsername;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final label =
        (metadata?['username'] ?? metadata?['full_name'] ?? user?.email ?? 'A')
            .toString();
    final avatarUrl =
        (metadata?['avatar_url'] ?? metadata?['avatarUrl'] ?? '')
            .toString()
            .trim();
    final initial =
        label.trim().isEmpty ? '?' : label.characters.first.toUpperCase();
    final canShowUsername =
        showUsername && MediaQuery.sizeOf(context).width >= 390;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: DashboardColors.surfaceHigh,
      backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
      child:
          avatarUrl.isEmpty
              ? Text(
                initial,
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: radius * .78,
                  fontWeight: FontWeight.w800,
                ),
              )
              : null,
    );

    final content =
        canShowUsername
            ? Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
              decoration: BoxDecoration(
                color: DashboardColors.surfaceHigh.withValues(alpha: .62),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  avatar,
                  const SizedBox(width: 9),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DashboardColors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
            : avatar;

    return Tooltip(
      message: 'Open profile',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap:
              onTap ??
              ProfileNavigationScope.maybeOf(context) ??
              () => context.go('/profile'),
          child: content,
        ),
      ),
    );
  }
}

class CircularScore extends StatelessWidget {
  const CircularScore({
    required this.value,
    required this.label,
    this.size = 176,
    super.key,
  });

  final double value;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder:
          (context, animated, _) => SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: animated,
                    strokeWidth: size * .055,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: .06),
                    valueColor: const AlwaysStoppedAnimation(
                      DashboardColors.primary,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(animated * 100).round()}%',
                      style: TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: size * .24,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: DashboardColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}

class AnalyticsBars extends StatelessWidget {
  const AnalyticsBars({
    this.values = const [.4, .65, .85, .5, .9, .2, .15],
    this.labels = const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'],
    super.key,
  });

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: values[i]),
                          duration: Duration(milliseconds: 600 + i * 70),
                          curve: Curves.easeOutCubic,
                          builder:
                              (context, value, _) => FractionallySizedBox(
                                heightFactor: value,
                                child: AnimatedContainer(
                                  duration: DashboardDurations.normal,
                                  decoration: BoxDecoration(
                                    color:
                                        i == 2 || i == 4
                                            ? DashboardColors.primary
                                            : Colors.white.withValues(
                                              alpha: .06,
                                            ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10),
                                    ),
                                    boxShadow:
                                        i == 2 || i == 4
                                            ? [
                                              BoxShadow(
                                                color: DashboardColors.primary
                                                    .withValues(alpha: .34),
                                                blurRadius: 16,
                                              ),
                                            ]
                                            : null,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      labels[i],
                      style: TextStyle(
                        color:
                            i == 2
                                ? DashboardColors.primary
                                : DashboardColors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
