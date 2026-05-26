import 'package:flutter/material.dart';

class AgendaPanelEvent {
  const AgendaPanelEvent({
    required this.start,
    required this.title,
    this.subtitle,
    this.color,
  });

  final DateTime start;
  final String title;
  final String? subtitle;
  final Color? color;
}

class AgendaPanel extends StatelessWidget {
  const AgendaPanel({
    required this.date,
    this.events = const [],
    this.aiSuggestion,
    this.onAcceptSuggestion,
    this.onDismissSuggestion,
    super.key,
  });

  final DateTime date;
  final List<AgendaPanelEvent> events;
  final String? aiSuggestion;
  final VoidCallback? onAcceptSuggestion;
  final VoidCallback? onDismissSuggestion;

  @override
  Widget build(BuildContext context) {
    final dayEvents =
        events.where((event) => _sameDay(event.start, date)).toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AgendaHeader(date: date),
          const SizedBox(height: 24),
          _AiOptimizationCard(
            text:
                aiSuggestion ??
                'You have a 3-hour deep work gap. Should I auto-schedule your high-priority tasks?',
            onAccept: onAcceptSuggestion,
            onDismiss: onDismissSuggestion,
          ),
          const SizedBox(height: 28),
          if (dayEvents.isEmpty)
            const _EmptyAgenda()
          else
            _AgendaTimeline(events: dayEvents),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_circle_rounded),
            label: const Text('Quick Add Event'),
          ),
        ],
      ),
    );
  }
}

class _AgendaHeader extends StatelessWidget {
  const _AgendaHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Agenda',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dateLabel(date),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.white60),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.today_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _AiOptimizationCard extends StatelessWidget {
  const _AiOptimizationCard({
    required this.text,
    this.onAccept,
    this.onDismiss,
  });

  final String text;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: .18),
            secondary.withValues(alpha: .12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(color: primary.withValues(alpha: .12), blurRadius: 28),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            bottom: -42,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: .08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'AI OPTIMIZATION',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                text,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: onAccept ?? () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8083FF),
                      foregroundColor: Colors.white,
                      shadowColor: const Color(
                        0xFF8083FF,
                      ).withValues(alpha: .45),
                      elevation: 10,
                    ),
                    child: const Text('Optimize'),
                  ),
                  OutlinedButton(
                    onPressed: onDismiss ?? () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDDB7FF),
                      backgroundColor: const Color(
                        0xFFDDB7FF,
                      ).withValues(alpha: .12),
                      side: BorderSide(
                        color: const Color(0xFFDDB7FF).withValues(alpha: .35),
                      ),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgendaTimeline extends StatelessWidget {
  const _AgendaTimeline({required this.events});

  final List<AgendaPanelEvent> events;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 11,
          top: 8,
          bottom: 0,
          child: Container(
            width: 1,
            color: Colors.white.withValues(alpha: .12),
          ),
        ),
        Column(
          children: [
            for (var index = 0; index < events.length; index++) ...[
              _TimelineEntry(event: events[index], active: index == 1),
              if (index == 1) const _TimelineGap(label: 'Lunch Break'),
            ],
          ],
        ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.event, required this.active});

  final AgendaPanelEvent event;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color =
        active
            ? Theme.of(context).colorScheme.primary
            : event.color ?? Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -40,
            top: 6,
            child: _TimelineDot(color: color, active: active),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    _time(event.start),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: active ? color : Colors.white60,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: color.withValues(alpha: active ? .24 : .10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _AgendaCard(event: event, color: color, active: active),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color:
            active
                ? color.withValues(alpha: .20)
                : Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: active ? color : Colors.white24, width: 2),
      ),
      child:
          active
              ? Center(
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              )
              : null,
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({
    required this.event,
    required this.color,
    required this.active,
  });

  final AgendaPanelEvent event;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            active
                ? color.withValues(alpha: .06)
                : Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              active
                  ? color.withValues(alpha: .22)
                  : Colors.white.withValues(alpha: .08),
        ),
        boxShadow:
            active
                ? [
                  BoxShadow(
                    color: color.withValues(alpha: .10),
                    blurRadius: 22,
                  ),
                ]
                : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (active)
                      Icon(Icons.auto_awesome_rounded, color: color, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.subtitle ?? '${_time(event.start)} event',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white60,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineGap extends StatelessWidget {
  const _TimelineGap({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 24),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white38,
          fontStyle: FontStyle.italic,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Text(
        'No events scheduled',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dateLabel(DateTime date) =>
    '${_weekday(date)}, ${date.day}/${date.month}/${date.year}';

String _weekday(DateTime date) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
