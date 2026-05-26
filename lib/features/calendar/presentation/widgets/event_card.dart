import 'package:flutter/material.dart';

class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.category,
    this.participants = const [],
    this.location,
    this.onTap,
    super.key,
  });

  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final String? category;
  final List<String> participants;
  final String? location;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 260;
        final tight = constraints.maxHeight < 150;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 1),
          duration: const Duration(milliseconds: 140),
          builder:
              (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
          child: Card(
            elevation: 0,
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: onTap,
              hoverColor: color.withValues(alpha: .08),
              splashColor: color.withValues(alpha: .12),
              highlightColor: color.withValues(alpha: .10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.all(
                  tight
                      ? 8
                      : compact
                      ? 12
                      : 16,
                ),
                decoration: _glass(context, color),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!tight) ...[
                      _CategoryRow(category: category ?? 'Event', color: color),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MetaRow(
                      icon: Icons.schedule_rounded,
                      label: '${_time(startTime)} - ${_time(endTime)}',
                    ),
                    if (!tight && location != null) ...[
                      const SizedBox(height: 8),
                      _MetaRow(
                        icon: Icons.location_on_rounded,
                        label: location!,
                      ),
                    ],
                    if (!tight && participants.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _Participants(names: participants, compact: compact),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.color});

  final String category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white60),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Participants extends StatelessWidget {
  const _Participants({required this.names, required this.compact});

  final List<String> names;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visible = names.take(compact ? 3 : 5).toList();
    final overflow = names.length - visible.length;

    return Row(
      children: [
        for (final name in visible)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: CircleAvatar(
              radius: compact ? 12 : 14,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                _initials(name),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        if (overflow > 0)
          Text(
            '+$overflow',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

BoxDecoration _glass(BuildContext context, Color color) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.surface.withValues(alpha: .58),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: color.withValues(alpha: .45)),
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: .14),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _initials(String value) {
  final parts =
      value
          .trim()
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}
