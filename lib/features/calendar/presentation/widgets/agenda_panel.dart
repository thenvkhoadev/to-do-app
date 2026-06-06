import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AgendaPanelEvent {
  const AgendaPanelEvent({
    required this.start,
    required this.title,
    this.taskId,
    this.subtitle,
    this.color,
    this.durationMinutes = 30,
    this.status = 'Scheduled',
    this.priority = 'Medium',
    this.type = 'Task',
  });

  final DateTime start;
  final String title;
  final String? taskId;
  final String? subtitle;
  final Color? color;
  final int durationMinutes;
  final String status;
  final String priority;
  final String type;
}

class AgendaPanel extends StatefulWidget {
  const AgendaPanel({
    required this.date,
    this.events = const [],
    this.aiSuggestion,
    this.onAcceptSuggestion,
    this.onDismissSuggestion,
    this.isLoading = false,
    this.errorMessage,
    this.onHideAgenda,
    this.onCreateTask,
    this.onEventTap,
    this.physics,
    super.key,
  });

  final DateTime date;
  final List<AgendaPanelEvent> events;
  final String? aiSuggestion;
  final VoidCallback? onAcceptSuggestion;
  final VoidCallback? onDismissSuggestion;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onHideAgenda;
  final VoidCallback? onCreateTask;
  final ValueChanged<AgendaPanelEvent>? onEventTap;
  final ScrollPhysics? physics;

  @override
  State<AgendaPanel> createState() => _AgendaPanelState();
}

class _AgendaPanelState extends State<AgendaPanel> {
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildProductivityScore() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  value: 0.87,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  color: const Color(0xff22C55E),
                  strokeWidth: 5,
                ),
              ),
              const Text(
                '87%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'PRODUCTIVITY',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '+150 XP today',
                  style: TextStyle(
                    color: Color(0xff22C55E),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayFocusBlock(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FOCUS BLOCK',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xff8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lens_blur_rounded,
                  color: Color(0xff8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Deep Work Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '09:00 - 11:00 • Highest Impact Task',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Focus Session started! Get ready to focus.'),
                  backgroundColor: Color(0xff8B5CF6),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff8B5CF6),
                    Color(0xff6366F1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Start Focus Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI INSIGHTS',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          Icons.warning_amber_rounded,
          'Deadline Alert',
          '2 tasks may miss deadline',
          const Color(0xffEF4444),
        ),
        const SizedBox(height: 8),
        _buildInsightCard(
          Icons.speed_rounded,
          'Workload Analysis',
          'Workload is 15% above normal',
          const Color(0xffF97316),
        ),
        const SizedBox(height: 8),
        _buildInsightCard(
          Icons.auto_awesome_rounded,
          'Suggested Focus',
          'Complete API Integration first',
          const Color(0xff6366F1),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
      IconData icon, String title, String text, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasks() {
    final upcoming = [
      {'day': 'Tomorrow', 'task': 'Design System'},
      {'day': 'Friday', 'task': 'Testing Sprint'},
      {'day': 'Monday', 'task': 'Release v1.0'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UPCOMING',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: ScrollConfiguration(
            behavior: MouseDragScrollBehavior(),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: upcoming.length,
              itemBuilder: (context, index) {
                final item = upcoming[index];
                return Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['day']!,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['task']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.8,
          children: [
            _buildActionButton(context, Icons.add_rounded, 'Task', () {
              widget.onCreateTask?.call();
            }),
            _buildActionButton(context, Icons.lens_blur_rounded, 'Focus', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Focus dashboard launched.')),
              );
            }),
            _buildActionButton(context, Icons.auto_awesome_rounded, 'AI Gen',
                () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI optimizing suggestions...')),
              );
            }),
            _buildActionButton(context, Icons.sync_rounded, 'Sync', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calendars synced successfully.')),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white60, size: 14),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiScheduleAssistant(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xff8B5CF6).withValues(alpha: 0.06),
            const Color(0xff6366F1).withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xff8B5CF6).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xffC0C1FF), size: 14),
              const SizedBox(width: 8),
              const Text(
                'AI SCHEDULE ASSISTANT',
                style: TextStyle(
                  color: Color(0xffC0C1FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'You have 3 free focus blocks today.',
            style: TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          const Text(
            'Recommended: 13:00 - 15:00',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Schedules optimized automatically!'),
                  backgroundColor: Color(0xff6366F1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xff6366F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  '⚡ Auto Schedule',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xff10B981).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.done_all_rounded,
            color: Color(0xff10B981),
            size: 32,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '🎉 All tasks completed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Enjoy your day.',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('New roadmap plan optimized by AI!')),
            );
          },
          icon: const Icon(Icons.auto_awesome_rounded, size: 14),
          label: const Text('Generate New Plan'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: DashboardColors.error, size: 36),
              const SizedBox(height: 12),
              Text(
                widget.errorMessage!,
                style:
                    const TextStyle(color: DashboardColors.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final hasEvents = widget.events.isNotEmpty;

    return SingleChildScrollView(
      physics: widget.physics ?? const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '✨ AI AGENDA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${widget.events.length} Tasks Today',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProductivityScore(),
          const SizedBox(height: 16),
          _buildTodayFocusBlock(context),
          const SizedBox(height: 24),
          const Text(
            'TODAY\'S TIMELINE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          if (!hasEvents)
            _buildEmptyState(context)
          else
            Column(
              children: [
                for (int i = 0; i < widget.events.length; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 24),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.events[i].color ??
                                  const Color(0xff6366F1),
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.events[i].color ??
                                          const Color(0xff6366F1))
                                      .withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          if (i < widget.events.length - 1)
                            Container(
                              width: 2,
                              height: 84,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    widget.events[i].color ??
                                        const Color(0xff6366F1),
                                    widget.events[i + 1].color ??
                                        const Color(0xff6366F1),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatTime(widget.events[i].start),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _TimelineCard(
                              event: widget.events[i],
                              onTap: () =>
                                  widget.onEventTap?.call(widget.events[i]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          const SizedBox(height: 24),
          _buildAiInsights(),
          const SizedBox(height: 24),
          _buildUpcomingTasks(),
          const SizedBox(height: 24),
          _buildQuickActions(context),
          const SizedBox(height: 24),
          _buildAiScheduleAssistant(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatefulWidget {
  const _TimelineCard({
    required this.event,
    this.onTap,
  });

  final AgendaPanelEvent event;
  final VoidCallback? onTap;

  @override
  State<_TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<_TimelineCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final color = event.color ?? const Color(0xff6366F1);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(left: 4, top: 4, bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _isHovered ? 0.05 : 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? color.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Transform.scale(
            scale: _isHovered ? 1.02 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: color, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildGlassChip(
                      event.priority.toUpperCase(),
                      const Color(0xffF97316),
                    ),
                    _buildGlassChip(
                      '${event.durationMinutes ~/ 60}h Estimate',
                      const Color(0xff06B6D4),
                    ),
                    _buildGlassChip(
                      event.status == 'completed' || event.status == 'Completed'
                          ? 'Completed'
                          : 'Progress 45%',
                      const Color(0xff22C55E),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class SelectDateAgendaPrompt extends StatefulWidget {
  const SelectDateAgendaPrompt({
    this.compact = false,
    this.onHideAgenda,
    this.onCreateTask,
    super.key,
  });

  final bool compact;
  final VoidCallback? onHideAgenda;
  final VoidCallback? onCreateTask;

  @override
  State<SelectDateAgendaPrompt> createState() => _SelectDateAgendaPromptState();
}

class _SelectDateAgendaPromptState extends State<SelectDateAgendaPrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: .96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(widget.compact ? 24 : 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: .055),
              primary.withValues(alpha: .07),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(color: primary.withValues(alpha: .10), blurRadius: 30),
          ],
        ),
        child: Stack(
          children: [
            if (widget.onHideAgenda != null)
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  onPressed: widget.onHideAgenda,
                  icon: const Icon(Icons.close_fullscreen_rounded),
                  tooltip: 'Hide agenda',
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: widget.compact ? 62 : 78,
                    height: widget.compact ? 62 : 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: .12),
                      border: Border.all(color: primary.withValues(alpha: .26)),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: primary,
                      size: widget.compact ? 30 : 38,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Select a date',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a day from the calendar\nto view tasks and events.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white60,
                        height: 1.45,
                      ),
                ),
                if (widget.onCreateTask != null) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: widget.onCreateTask,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Task'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 10,
                      shadowColor: primary.withValues(alpha: .35),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
