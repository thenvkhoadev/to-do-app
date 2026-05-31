import 'package:flutter/material.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_models.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_glass.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TasksProjectsCard extends StatefulWidget {
  const TasksProjectsCard({required this.item, this.mobile = false, this.onTap, super.key});

  final TasksProjectItem item;
  final bool mobile;
  final VoidCallback? onTap;

  @override
  State<TasksProjectsCard> createState() => _TasksProjectsCardState();
}

class _TasksProjectsCardState extends State<TasksProjectsCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.item.kind == TasksProjectCardKind.add) {
      return _AddProjectTile(
        hovered: _hovered,
        onHover: _setHover,
        onTap: widget.onTap,
      );
    }

    final item = widget.item;
    final mobile = widget.mobile;
    final highlight = item.kind == TasksProjectCardKind.priority;

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
        scale: _pressed ? .985 : (!mobile && _hovered ? 1.01 : 1),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Stack(
          children: [
            TasksProjectsGlass(
              padding: EdgeInsets.all(mobile ? 20 : 24),
              borderColor:
                  highlight
                      ? DashboardColors.primary.withValues(alpha: .4)
                      : null,
              glowColor: highlight ? DashboardColors.primary : null,
              fillAlpha: !mobile && _hovered ? .06 : .03,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Badge(
                        label: item.badge,
                        color: item.accent,
                        mobile: mobile,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.more_vert_rounded,
                        color:
                            _hovered
                                ? DashboardColors.primary
                                : DashboardColors.outline,
                        size: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: mobile ? 12 : 16),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: mobile ? 20 : 24,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: mobile ? 4 : 8),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: mobile ? 14 : 16,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: mobile ? 16 : 24),
                  _Footer(item: item, mobile: mobile),
                ],
              ),
            ),
            if (highlight)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        DashboardColors.primary,
                        DashboardColors.secondary,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  void _setHover(bool value) => setState(() => _hovered = value);
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.mobile,
  });
  final String label;
  final Color color;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: mobile ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: mobile ? 10 : 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.item, required this.mobile});
  final TasksProjectItem item;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return switch (item.kind) {
      TasksProjectCardKind.priority => Row(
        children: [
          _Avatars(size: mobile ? 28 : 32),
          const Spacer(),
          Icon(
            Icons.calendar_month_rounded,
            color: DashboardColors.primary,
            size: mobile ? 16 : 18,
          ),
          const SizedBox(width: 6),
          Text(
            item.metaRight!,
            style: TextStyle(
              color: DashboardColors.primary,
              fontSize: mobile ? 12 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      TasksProjectCardKind.ai => Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: DashboardColors.tertiary,
            size: mobile ? 16 : 18,
          ),
          const SizedBox(width: 6),
          Text(item.metaLeft!, style: _metaStyle(mobile)),
          const Spacer(),
          Icon(
            Icons.attachment_rounded,
            color: DashboardColors.onSurfaceVariant,
            size: mobile ? 16 : 18,
          ),
          const SizedBox(width: 6),
          Text(item.metaRight!, style: _metaStyle(mobile)),
        ],
      ),
      TasksProjectCardKind.review => Row(
        children: [
          Expanded(child: _Progress(value: item.progress ?? 0, mobile: mobile)),
          const SizedBox(width: 16),
          Text(
            '${((item.progress ?? 0) * 100).round()}%',
            style: TextStyle(
              color: DashboardColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: mobile ? 12 : 13,
            ),
          ),
        ],
      ),
      TasksProjectCardKind.urgent => Row(
        children: [
          _SingleAvatar(size: mobile ? 28 : 32),
          const Spacer(),
          Icon(
            Icons.schedule_rounded,
            color: DashboardColors.secondary,
            size: mobile ? 16 : 18,
          ),
          const SizedBox(width: 6),
          Text(
            item.metaRight!,
            style: TextStyle(
              color: DashboardColors.secondary,
              fontSize: mobile ? 12 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      TasksProjectCardKind.research => Row(
        children: [
          Text(item.metaLeft!, style: _metaStyle(mobile)),
          const Spacer(),
          Icon(
            Icons.bar_chart_rounded,
            color: DashboardColors.onSurfaceVariant,
            size: mobile ? 16 : 18,
          ),
        ],
      ),
      TasksProjectCardKind.add => const SizedBox.shrink(),
    };
  }

  TextStyle _metaStyle(bool mobile) => TextStyle(
    color: DashboardColors.onSurfaceVariant,
    fontSize: mobile ? 12 : 13,
    fontWeight: FontWeight.w600,
  );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value, required this.mobile});
  final double value;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: animatedValue,
          minHeight: mobile ? 4 : 6,
          backgroundColor: Colors.white.withValues(alpha: .1),
          valueColor: const AlwaysStoppedAnimation(DashboardColors.primary),
        ),
      ),
    );
  }
}

class _Avatars extends StatelessWidget {
  const _Avatars({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.65,
      height: size,
      child: Stack(
        children: [
          _SingleAvatar(size: size),
          Positioned(left: size - 8, child: _PlusAvatar(size: size)),
        ],
      ),
    );
  }
}

class _SingleAvatar extends StatelessWidget {
  const _SingleAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: DashboardColors.surfaceHighest,
      border: Border.all(color: DashboardColors.background, width: 2),
    ),
  );
}

class _PlusAvatar extends StatelessWidget {
  const _PlusAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: DashboardColors.primary.withValues(alpha: .3),
      border: Border.all(color: DashboardColors.background, width: 2),
    ),
    child: const Text(
      '+3',
      style: TextStyle(
        color: DashboardColors.onSurface,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _AddProjectTile extends StatelessWidget {
  const _AddProjectTile({required this.hovered, required this.onHover, this.onTap});
  final bool hovered;
  final ValueChanged<bool> onHover;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = hovered ? DashboardColors.primary : DashboardColors.outline;
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: TasksProjectsGlass(
          dashed: true,
        borderColor: color.withValues(alpha: .35),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_rounded, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Create New Sub-Project',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
