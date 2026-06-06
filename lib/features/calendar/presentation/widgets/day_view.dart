import 'package:flutter/material.dart';

class DayCalendarEvent {
  const DayCalendarEvent({
    required this.start,
    required this.end,
    required this.title,
    this.taskId,
    this.subtitle,
    this.color,
    this.category,
    this.location,
    this.participants = const [],
  });

  final DateTime start;
  final DateTime end;
  final String title;
  final String? taskId;
  final String? subtitle;
  final Color? color;
  final String? category;
  final String? location;
  final List<String> participants;
}

class DayView extends StatelessWidget {
  const DayView({
    required this.date,
    this.events = const [],
    this.onEventTap,
    super.key,
  });

  final DateTime date;
  final List<DayCalendarEvent> events;
  final ValueChanged<DayCalendarEvent>? onEventTap;

  static const _hourHeight = 64.0;
  static const _timeWidth = 52.0;

  @override
  Widget build(BuildContext context) {
    final dayEvents =
        events.where((e) => _sameDay(e.start, date)).toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 720;
        final hPad = desktop ? 24.0 : 12.0;
        final contentWidth = constraints.maxWidth - _timeWidth - hPad * 2;

        // Build overlap groups
        final groups = _buildOverlapGroups(dayEvents);

        return Container(
          padding: EdgeInsets.all(hPad),
          decoration: _glass(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DayHeader(date: date),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: 24 * _hourHeight,
                    child: Stack(
                      children: [
                        _Grid(
                          hourHeight: _hourHeight,
                          timeWidth: _timeWidth,
                        ),
                        // Render each overlap group
                        for (final group in groups)
                          for (int i = 0; i < group.length; i++)
                            _EventBlock(
                              event: group[i],
                              hourHeight: _hourHeight,
                              timeWidth: _timeWidth,
                              colIndex: i,
                              colCount: group.length,
                              contentWidth: contentWidth,
                              onTap: onEventTap == null
                                  ? null
                                  : () => onEventTap!(group[i]),
                            ),
                        if (_sameDay(date, DateTime.now()))
                          _NowLine(
                            hourHeight: _hourHeight,
                            left: _timeWidth,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Groups events that overlap in time so they can be rendered side by side.
  List<List<DayCalendarEvent>> _buildOverlapGroups(
    List<DayCalendarEvent> sorted,
  ) {
    if (sorted.isEmpty) return [];

    final groups = <List<DayCalendarEvent>>[];
    List<DayCalendarEvent> current = [sorted.first];
    DateTime groupEnd = sorted.first.end;

    for (int i = 1; i < sorted.length; i++) {
      final event = sorted[i];
      if (event.start.isBefore(groupEnd)) {
        // Overlaps with current group
        current.add(event);
        if (event.end.isAfter(groupEnd)) groupEnd = event.end;
      } else {
        groups.add(current);
        current = [event];
        groupEnd = event.end;
      }
    }
    groups.add(current);
    return groups;
  }
}

// ── Day header ───────────────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isToday = _sameDay(date, DateTime.now());
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _weekdayFull(date),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day} ${_monthFull(date)} ${date.year}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .55),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: primary.withValues(alpha: .35)),
            ),
            child: Text(
              'TODAY',
              style: TextStyle(
                color: primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Hour grid ─────────────────────────────────────────────────────────────────

class _Grid extends StatelessWidget {
  const _Grid({required this.hourHeight, required this.timeWidth});

  final double hourHeight;
  final double timeWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var hour = 0; hour < 24; hour++)
          SizedBox(
            height: hourHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: timeWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: .35),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: .07),
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

// ── Event block (overlap-aware) ───────────────────────────────────────────────

class _EventBlock extends StatefulWidget {
  const _EventBlock({
    required this.event,
    required this.hourHeight,
    required this.timeWidth,
    required this.colIndex,
    required this.colCount,
    required this.contentWidth,
    this.onTap,
  });

  final DayCalendarEvent event;
  final double hourHeight;
  final double timeWidth;
  final int colIndex;
  final int colCount;
  final double contentWidth;
  final VoidCallback? onTap;

  @override
  State<_EventBlock> createState() => _EventBlockState();
}

class _EventBlockState extends State<_EventBlock> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final color = e.color ?? Theme.of(context).colorScheme.primary;

    final startFrac = e.start.hour + e.start.minute / 60.0;
    final durationMin = e.end.difference(e.start).inMinutes.clamp(15, 1440);
    final durationFrac = durationMin / 60.0;
    final isShort = durationMin < 35;

    final colW = (widget.contentWidth - (widget.colCount - 1) * 4) / widget.colCount;
    final left = widget.timeWidth + widget.colIndex * (colW + 4);
    final top = startFrac * widget.hourHeight;
    final height = (durationFrac * widget.hourHeight - 3).clamp(28.0, double.infinity);

    return Positioned(
      top: top,
      left: left,
      width: colW,
      height: height,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedScale(
          scale: _hovered ? 1.012 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: BoxDecoration(
                color: color.withValues(alpha: _hovered ? .16 : .10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: .22)),
                boxShadow: _hovered
                    ? [BoxShadow(color: color.withValues(alpha: .12), blurRadius: 12, offset: const Offset(0, 4))]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left accent strip
                    Container(width: 3, color: color),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(6, isShort ? 4 : 6, 6, isShort ? 4 : 6),
                        child: isShort
                            ? _CompactContent(event: e, color: color)
                            : _FullContent(event: e, color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Compact card (< 35 min) ───────────────────────────────────────────────────

class _CompactContent extends StatelessWidget {
  const _CompactContent({required this.event, required this.color});
  final DayCalendarEvent event;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${_t(event.start)}-${_t(event.end)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .55),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Full card (>= 35 min) ─────────────────────────────────────────────────────

class _FullContent extends StatelessWidget {
  const _FullContent({required this.event, required this.color});
  final DayCalendarEvent event;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${_t(event.start)} – ${_t(event.end)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .55),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (event.subtitle != null && event.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            event.subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .40),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Now line ──────────────────────────────────────────────────────────────────

class _NowLine extends StatelessWidget {
  const _NowLine({required this.hourHeight, required this.left});
  final double hourHeight;
  final double left;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final color = Theme.of(context).colorScheme.tertiary;
    return Positioned(
      top: (now.hour + now.minute / 60.0) * hourHeight - 1,
      left: left - 6,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Container(height: 1.5, color: color.withValues(alpha: .7)),
          ),
        ],
      ),
    );
  }
}

// ── Glass container ───────────────────────────────────────────────────────────

BoxDecoration _glass(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.surface.withValues(alpha: .58),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.white.withValues(alpha: .08)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .22),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
    ],
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _t(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _weekdayFull(DateTime d) => const [
      'Monday','Tuesday','Wednesday','Thursday',
      'Friday','Saturday','Sunday',
    ][d.weekday - 1];

String _monthFull(DateTime d) => const [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December',
    ][d.month - 1];
