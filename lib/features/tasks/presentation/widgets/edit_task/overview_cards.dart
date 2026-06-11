import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskOverviewCards extends StatelessWidget {
  const TaskOverviewCards({
    required this.item,
    required this.isMobile,
    super.key,
  });

  final TaskBoardItem item;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      final priorityStr = switch (item.priority) {
        TaskBoardPriority.urgent => 'Urgent',
        TaskBoardPriority.high => 'High',
        TaskBoardPriority.medium => 'Medium',
        TaskBoardPriority.low => 'Low',
        TaskBoardPriority.done => 'Medium',
      };

      return GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 0,
        childAspectRatio: 1.0,
        children: [
          _OverviewCard(
            icon: Icons.priority_high_rounded,
            label: 'Priority',
            value: priorityStr,
            color: DashboardColors.error,
            isMobile: true,
          ),
          _OverviewCard(
            icon: Icons.stars_rounded,
            label: 'XP',
            value: '1,200',
            color: const Color(0xFFF59E0B), // warning
            isMobile: true,
            shimmer: true,
          ),
          _OverviewCard(
            icon: Icons.bolt_rounded,
            label: 'AI Score',
            value: '94',
            color: const Color(0xFF3DD7FF), // tertiary-container
            isMobile: true,
          ),
        ],
      );
    }

    // Desktop
    final priorityStr = switch (item.priority) {
      TaskBoardPriority.urgent => 'URGENT',
      TaskBoardPriority.high => 'HIGH',
      TaskBoardPriority.medium => 'MEDIUM',
      TaskBoardPriority.low => 'LOW',
      TaskBoardPriority.done => 'MEDIUM',
    };

    final priorityColor = switch (item.priority) {
      TaskBoardPriority.urgent || TaskBoardPriority.high => DashboardColors.error,
      TaskBoardPriority.medium => DashboardColors.warning,
      _ => DashboardColors.tertiary,
    };

    final xpVal = switch (item.priority) {
      TaskBoardPriority.urgent => '+100 XP',
      TaskBoardPriority.high => '+50 XP',
      TaskBoardPriority.medium => '+20 XP',
      _ => '+10 XP',
    };

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 24,
      mainAxisSpacing: 0,
      childAspectRatio: 2.5,
      children: [
        _OverviewCard(
          icon: Icons.error_rounded,
          label: 'Priority',
          value: priorityStr,
          color: priorityColor,
          isMobile: false,
          valuePrefixIcon: Icons.priority_high_rounded,
        ),
        _OverviewCard(
          icon: Icons.stars_rounded,
          label: 'XP Reward',
          value: xpVal,
          color: DashboardColors.primary,
          isMobile: false,
          shimmer: true,
        ),
        _OverviewCard(
          icon: Icons.analytics_rounded,
          label: 'AI Score',
          value: '92%',
          color: DashboardColors.success,
          isMobile: false,
        ),
      ],
    );
  }
}

class _OverviewCard extends StatefulWidget {
  const _OverviewCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isMobile,
    this.valuePrefixIcon,
    this.shimmer = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isMobile;
  final IconData? valuePrefixIcon;
  final bool shimmer;

  @override
  State<_OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends State<_OverviewCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController? _shimmerController;

  @override
  void initState() {
    super.initState();
    if (widget.shimmer) {
      _shimmerController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat();
    } else {
      _shimmerController = null;
    }
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              color: widget.color,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.value,
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isHovered
              ? widget.color.withValues(alpha: 0.3)
              : const Color.fromRGBO(255, 255, 255, 0.08),
          width: 1,
        ),
        boxShadow: [
          if (_isHovered)
            BoxShadow(
              color: widget.color.withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 0,
            ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label.toUpperCase(),
                      style: const TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.valuePrefixIcon != null) ...[
                          Icon(
                            widget.valuePrefixIcon,
                            color: widget.color,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            widget.value,
                            style: TextStyle(
                              color: widget.color,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 24,
                ),
              ),
            ],
          ),
          if (widget.shimmer && _shimmerController != null)
            AnimatedBuilder(
              animation: _shimmerController!,
              builder: (context, child) {
                return Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: const [
                            Colors.transparent,
                            Color.fromRGBO(255, 255, 255, 0.05),
                            Colors.transparent,
                          ],
                          stops: [
                            _shimmerController!.value - 0.2,
                            _shimmerController!.value,
                            _shimmerController!.value + 0.2,
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        child: cardContent,
      ),
    );
  }
}
