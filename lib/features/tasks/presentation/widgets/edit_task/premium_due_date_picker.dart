import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

// ── DETERMINISTIC PSEUDO-RANDOM GENERATOR ────────────────────────────────────
class SeededRandom {
  SeededRandom(this.seed);
  int seed;

  double nextDouble() {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 2147483647.0;
  }
}

// ── NOISE OVERLAY PAINTER ────────────────────────────────────────────────────
class NoisePainter extends CustomPainter {
  const NoisePainter({required this.opacity});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.overlay;

    final points = <Offset>[];
    final random = SeededRandom(1337);

    for (double x = 0; x < size.width; x += 3) {
      for (double y = 0; y < size.height; y += 3) {
        if (random.nextDouble() < 0.15) {
          points.add(Offset(x, y));
        }
      }
    }

    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── HOVER SCALE BUTTON FOR MONTH NAVIGATION ──────────────────────────────────
class HoverScaleButton extends StatefulWidget {
  const HoverScaleButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  State<HoverScaleButton> createState() => _HoverScaleButtonState();
}

class _HoverScaleButtonState extends State<HoverScaleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter:
            (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isHovered = true);
            }),
        onExit:
            (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isHovered = false);
            }),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isHovered ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedOpacity(
              opacity: _isHovered ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: _isHovered ? 0.15 : 0.08,
                    ),
                  ),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── HOVERABLE DURATION ADJUSTMENT CONTAINER ──────────────────────────────────
class _HoverableContainer extends StatefulWidget {
  const _HoverableContainer({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.width,
    this.height,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<_HoverableContainer> createState() => _HoverableContainerState();
}

class _HoverableContainerState extends State<_HoverableContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter:
            (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isHovered = true);
            }),
        onExit:
            (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isHovered = false);
            }),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color:
                  _isHovered
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.05),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              border: Border.all(
                color:
                    _isHovered
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

// ── CALENDAR CELL WIDGET ─────────────────────────────────────────────────────
class _CalendarDayCell extends StatefulWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isMuted,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
    required this.accessibilityLabel,
  });

  final int day;
  final bool isMuted;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;
  final String accessibilityLabel;

  @override
  State<_CalendarDayCell> createState() => _CalendarDayCellState();
}

class _CalendarDayCellState extends State<_CalendarDayCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isHighContrast = MediaQuery.of(context).highContrast;

    return Semantics(
      label: widget.accessibilityLabel,
      selected: isSelected,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter:
            (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isHovered = true);
            }),
        onExit:
            (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isHovered = false);
            }),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Hover background
                  AnimatedOpacity(
                    opacity: _isHovered && !isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Selected state soft blue circle
                  AnimatedScale(
                    scale: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC8D7FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Day Text label
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.black87
                              : widget.isMuted
                              ? (isHighContrast
                                  ? Colors.white54
                                  : Colors.white24)
                              : Colors.white,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Text('${widget.day}'),
                  ),
                  // Subtle dot indicator for Today
                  if (widget.isToday && !isSelected)
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC8D7FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── FOCUS ACTION BUTTON ──────────────────────────────────────────────────────
class _FocusActionButton extends StatefulWidget {
  const _FocusActionButton({required this.onTap, this.isFullWidth = false});

  final VoidCallback onTap;
  final bool isFullWidth;

  @override
  State<_FocusActionButton> createState() => _FocusActionButtonState();
}

class _FocusActionButtonState extends State<_FocusActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color:
            _isHovered
                ? const Color(0xFF2C2C2C)
                : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
          SizedBox(width: 4),
          Text(
            'Focus',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (widget.isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return Semantics(
      label: 'Focus session shortcut, select this date and duration',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter:
            (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isHovered = true);
            }),
        onExit:
            (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isHovered = false);
            }),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isHovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: button,
          ),
        ),
      ),
    );
  }
}

// ── MAIN PREMIUM DATE PICKER ENTRY POINT ─────────────────────────────────────
class PremiumDueDatePicker extends StatefulWidget {
  const PremiumDueDatePicker({
    required this.value,
    required this.onChanged,
    this.durationMinutes,
    this.onDurationChanged,
    super.key,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final int? durationMinutes;
  final ValueChanged<int>? onDurationChanged;

  @override
  State<PremiumDueDatePicker> createState() => _PremiumDueDatePickerState();
}

class _PremiumDueDatePickerState extends State<PremiumDueDatePicker> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _hovered = false;

  bool get _isOpen => _overlay != null;

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  Future<void> _open() async {
    HapticFeedback.selectionClick();
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      final picked = await showModalBottomSheet<DateTime>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.58),
        builder:
            (context) => _CalendarSheet(
              initialValue: widget.value,
              onClear: () => widget.onChanged(null),
              durationMinutes: widget.durationMinutes,
              onDurationChanged: widget.onDurationChanged,
            ),
      );
      if (mounted && picked != null) widget.onChanged(picked);
      return;
    }

    _overlay = OverlayEntry(
      builder:
          (context) => _CalendarOverlay(
            layerLink: _layerLink,
            initialValue: widget.value,
            durationMinutes: widget.durationMinutes,
            onDurationChanged: widget.onDurationChanged,
            onSelected: (value) {
              widget.onChanged(value);
              _close();
            },
            onDismiss: _close,
          ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value;
    final dateText =
        selected == null
            ? 'No due date'
            : DateFormat('MMM d, yyyy').format(selected);
    final quickText = _quickLabel(selected);

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter:
            (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _hovered = true);
            }),
        onExit:
            (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _hovered = false);
            }),
        child: GestureDetector(
          onTap: _toggle,
          child: AnimatedScale(
            scale: _isOpen ? 0.99 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minHeight: 50),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF11151E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      _hovered || _isOpen
                          ? const Color(0xFF2F6BFF)
                          : const Color(0xFF232A3A),
                  width: _hovered || _isOpen ? 1.3 : 1.0,
                ),
                boxShadow:
                    _hovered || _isOpen
                        ? [
                          BoxShadow(
                            color: const Color(
                              0xFF2F6BFF,
                            ).withValues(alpha: 0.18),
                            blurRadius: 20,
                          ),
                        ]
                        : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B7FFF).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF8FA4FF),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Due Date',
                          style: TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          dateText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DashboardColors.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.055),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          quickText,
                          style: const TextStyle(
                            color: Color(0xFFB8C4E8),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 3),
                        AnimatedRotation(
                          turns: _isOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(
                            Icons.expand_more_rounded,
                            color: Color(0xFFB8C4E8),
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _quickLabel(DateTime? date) {
    if (date == null) return 'Today +';
    final today = _dateOnly(DateTime.now());
    final value = _dateOnly(date);
    final diff = value.difference(today).inDays;
    return switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => '+$diff d',
    };
  }
}

// ── CALENDAR OVERLAY ─────────────────────────────────────────────────────────
class _CalendarOverlay extends StatefulWidget {
  const _CalendarOverlay({
    required this.layerLink,
    required this.initialValue,
    required this.onSelected,
    required this.onDismiss,
    this.durationMinutes,
    this.onDurationChanged,
  });

  final LayerLink layerLink;
  final DateTime? initialValue;
  final ValueChanged<DateTime?> onSelected;
  final VoidCallback onDismiss;
  final int? durationMinutes;
  final ValueChanged<int>? onDurationChanged;

  @override
  State<_CalendarOverlay> createState() => _CalendarOverlayState();
}

class _CalendarOverlayState extends State<_CalendarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..forward();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _dismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 58),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOutCubic,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOutCubic,
                ),
              ),
              alignment: Alignment.topLeft,
              child: _CalendarPopover(
                initialValue: widget.initialValue,
                onSelected: widget.onSelected,
                onDismiss: _dismiss,
                durationMinutes: widget.durationMinutes,
                onDurationChanged: widget.onDurationChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── CALENDAR SHEET (MOBILE BOTTOM SHEET WRAPPER) ─────────────────────────────
class _CalendarSheet extends StatelessWidget {
  const _CalendarSheet({
    required this.initialValue,
    required this.onClear,
    this.durationMinutes,
    this.onDurationChanged,
  });

  final DateTime? initialValue;
  final VoidCallback onClear;
  final int? durationMinutes;
  final ValueChanged<int>? onDurationChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _CalendarPopover(
          initialValue: initialValue,
          onSelected: (value) => Navigator.of(context).pop(value),
          onClear: () {
            onClear();
            Navigator.of(context).pop();
          },
          onDismiss: () => Navigator.of(context).pop(),
          durationMinutes: durationMinutes,
          onDurationChanged: onDurationChanged,
        ),
      ),
    );
  }
}

// ── REDESIGNED PREMIUM CALENDAR POPOVER WIDGET ────────────────────────────────
class _CalendarPopover extends StatefulWidget {
  const _CalendarPopover({
    required this.initialValue,
    required this.onSelected,
    required this.onDismiss,
    this.onClear,
    this.durationMinutes,
    this.onDurationChanged,
  });

  final DateTime? initialValue;
  final ValueChanged<DateTime?> onSelected;
  final VoidCallback onDismiss;
  final VoidCallback? onClear;
  final int? durationMinutes;
  final ValueChanged<int>? onDurationChanged;

  @override
  State<_CalendarPopover> createState() => _CalendarPopoverState();
}

class _CalendarPopoverState extends State<_CalendarPopover> {
  final _naturalController = TextEditingController();
  late DateTime _visibleMonth;
  DateTime? _selected;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 30);
  int _focusDuration = 30;
  bool _showQuickPanel = false;

  late final ScrollController _scrollController;
  static const double _monthBlockHeight = 284.0;

  DateTime get _startDate =>
      DateTime(DateTime.now().year - 2, DateTime.now().month);

  int _indexOfDate(DateTime date) {
    final start = _startDate;
    final diff = (date.year - start.year) * 12 + date.month - start.month;
    return diff.clamp(0, 119);
  }

  DateTime _dateOfIndex(int index) {
    final start = _startDate;
    return DateTime(start.year, start.month + index);
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue ?? DateTime.now();
    _selected = widget.initialValue;
    _visibleMonth = DateTime(initial.year, initial.month);
    _time =
        widget.initialValue == null
            ? _time
            : TimeOfDay(
              hour: widget.initialValue!.hour,
              minute: widget.initialValue!.minute,
            );
    _focusDuration = widget.durationMinutes ?? 30;

    final initialIndex = _indexOfDate(_visibleMonth);
    _scrollController = ScrollController(
      initialScrollOffset: initialIndex * _monthBlockHeight,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final index = (_scrollController.offset / _monthBlockHeight).round();
    final monthDate = _dateOfIndex(index);
    if (monthDate.month != _visibleMonth.month ||
        monthDate.year != _visibleMonth.year) {
      setState(() {
        _visibleMonth = monthDate;
      });
    }
  }

  void _scrollToMonth(int delta) {
    if (!_scrollController.hasClients) return;
    final targetIndex = _indexOfDate(_visibleMonth) + delta;
    _scrollController.animateTo(
      targetIndex * _monthBlockHeight,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _naturalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    double popoverWidth;
    double borderRadius;

    if (screenWidth > 1200) {
      popoverWidth = 340; // compact width
      borderRadius = 24;
    } else if (screenWidth >= 600) {
      popoverWidth = 320;
      borderRadius = 24;
    } else {
      popoverWidth = screenWidth - 32;
      borderRadius = 20;
    }

    return KeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKeyEvent: _handleKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobileOrTablet = isMobile || isTablet;

          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    // Container with premium dark-glass styling
                    Container(
                      width: popoverWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadius),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF242424), Color(0xFF1B1B1B)],
                        ),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          const BoxShadow(
                            color: Colors.black54,
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFF6E8BFF,
                            ).withValues(alpha: 0.12),
                            blurRadius: 60,
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── Header Layout ──
                                _header(),
                                const SizedBox(height: 12),
                                const Divider(
                                  color: Colors.white10,
                                  thickness: 1,
                                ),

                                // ── Advanced Options Collapsible Panel ──
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOutCubic,
                                  child:
                                      _showQuickPanel
                                          ? Column(
                                            children: [
                                              const SizedBox(height: 12),
                                              _naturalInput(),
                                              const SizedBox(height: 12),
                                              _quickActions(),
                                              const SizedBox(height: 12),
                                              _timeRow(),
                                              const SizedBox(height: 12),
                                              const Divider(
                                                color: Colors.white10,
                                                thickness: 1,
                                              ),
                                            ],
                                          )
                                          : const SizedBox.shrink(),
                                ),

                                // ── Month Header Layout ──
                                const SizedBox(height: 10),
                                _monthHeader(),
                                const SizedBox(height: 14),

                                // ── Weekdays Row ──
                                _weekHeader(),
                              ],
                            ),
                          ),
                          // ── Vertical Scrollable Month List ──
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 280,
                                ),
                                child: ScrollConfiguration(
                                  behavior: ScrollConfiguration.of(
                                    context,
                                  ).copyWith(scrollbars: false),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    controller: _scrollController,
                                    itemCount: 120, // 10 years range
                                    itemBuilder: (context, index) {
                                      final monthDate = _dateOfIndex(index);
                                      return _monthBlock(monthDate);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // ── Bottom Toolbar ──
                          _bottomToolbar(isMobileOrTablet),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(borderRadius),
                          child: const CustomPaint(
                            painter: NoisePainter(opacity: 0.03),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Header showing selected date & dropdown menu button
  Widget _header() {
    final dateText = DateFormat(
      'EEEE, MMMM d',
    ).format(_selected ?? DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            dateText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Semantics(
          label: 'Toggle quick selections and time picker options',
          button: true,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() => _showQuickPanel = !_showQuickPanel);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: AnimatedRotation(
                  turns: _showQuickPanel ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Month navigation & Month/Year title
  Widget _monthHeader() {
    final monthText = DateFormat('MMMM yyyy').format(_visibleMonth);
    return Row(
      children: [
        Expanded(
          child: Text(
            monthText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        HoverScaleButton(
          icon: Icons.keyboard_arrow_up_rounded,
          semanticLabel: 'Previous month',
          onTap: () => _scrollToMonth(-1),
        ),
        const SizedBox(width: 6),
        HoverScaleButton(
          icon: Icons.keyboard_arrow_down_rounded,
          semanticLabel: 'Next month',
          onTap: () => _scrollToMonth(1),
        ),
      ],
    );
  }

  Widget _naturalInput() {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _naturalController,
        onSubmitted: _parseNatural,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Type date... today, tomorrow, next monday',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.34),
            fontSize: 11,
          ),
          prefixIcon: Icon(
            Icons.bolt_rounded,
            color: Colors.white.withValues(alpha: 0.38),
            size: 15,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.045),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _weekHeader() {
    const days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Row(
      children:
          days
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _monthBlock(DateTime monthDate) {
    final monthText = DateFormat('MMMM yyyy').format(monthDate);
    return SizedBox(
      height: _monthBlockHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              monthText,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 240, child: _calendarGrid(monthDate)),
        ],
      ),
    );
  }

  Widget _calendarGrid(DateTime monthDate) {
    final first = DateTime(monthDate.year, monthDate.month, 1);
    final start = first.subtract(Duration(days: first.weekday % 7));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final date = start.add(Duration(days: index));
        final muted = date.month != monthDate.month;
        final isSelected = _selected != null && _sameDate(date, _selected!);
        final isToday = _sameDate(date, DateTime.now());

        final accessibilityLabel =
            '${date.day} ${DateFormat('MMMM yyyy').format(date)}'
            '${isToday ? ", today" : ""}${isSelected ? ", selected" : ""}';

        return _CalendarDayCell(
          day: date.day,
          isMuted: muted,
          isSelected: isSelected,
          isToday: isToday,
          onTap: () => setState(() => _selected = _withTime(date)),
          accessibilityLabel: accessibilityLabel,
        );
      },
    );
  }

  Widget _quickActions() {
    final today = _dateOnly(DateTime.now());
    final weekend = today.add(
      Duration(days: (DateTime.saturday - today.weekday) % 7),
    );
    final actions = <String, DateTime?>{
      'Today': today,
      'Tomorrow': today.add(const Duration(days: 1)),
      'This Weekend': weekend,
      'Next Week': today.add(const Duration(days: 7)),
      'No Due Date': null,
    };
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children:
          actions.entries.map((entry) {
            return _HoverableContainer(
              borderRadius: BorderRadius.circular(999),
              semanticLabel: 'Quick option: select ${entry.key}',
              onTap:
                  () => setState(() {
                    _selected =
                        entry.value == null ? null : _withTime(entry.value!);
                    if (entry.value != null) {
                      final targetIndex = _indexOfDate(entry.value!);
                      _scrollController.jumpTo(targetIndex * _monthBlockHeight);
                    }
                  }),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    color: Color(0xFFD8E0F7),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _timeRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Time Block Options',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Due target hour',
                style: TextStyle(color: Colors.white30, fontSize: 9),
              ),
            ],
          ),
        ),
        _HoverableContainer(
          borderRadius: BorderRadius.circular(999),
          semanticLabel: 'Open time picker',
          onTap: _pickTime,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFF8FA4FF),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _time.format(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomToolbar(bool isMobileOrTablet) {
    final durationWidget = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _HoverableContainer(
          width: 36,
          height: 36,
          borderRadius: BorderRadius.circular(10),
          semanticLabel: 'Decrease duration by 15 minutes',
          onTap: () {
            setState(() {
              _focusDuration = (_focusDuration - 15).clamp(15, 480);
            });
          },
          child: const Icon(
            Icons.remove_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$_focusDuration mins',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        _HoverableContainer(
          width: 36,
          height: 36,
          borderRadius: BorderRadius.circular(10),
          semanticLabel: 'Increase duration by 15 minutes',
          onTap: () {
            setState(() {
              _focusDuration = (_focusDuration + 15).clamp(15, 480);
            });
          },
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
        ),
      ],
    );

    final focusButton = _FocusActionButton(
      isFullWidth: isMobileOrTablet,
      onTap: () {
        if (widget.onDurationChanged != null) {
          widget.onDurationChanged!(_focusDuration);
        }
        widget.onSelected(_selected);
      },
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child:
          isMobileOrTablet
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  durationWidget,
                  const SizedBox(height: 12),
                  focusButton,
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [durationWidget, focusButton],
              ),
    );
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss();
      return;
    }

    final baseDate = _selected ?? DateTime.now();
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowUp => -7,
      LogicalKeyboardKey.arrowDown => 7,
      _ => 0,
    };

    if (delta != 0) {
      setState(() {
        _selected = _withTime(baseDate.add(Duration(days: delta)));
        final targetIndex = _indexOfDate(_selected!);
        _scrollController.jumpTo(targetIndex * _monthBlockHeight);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (widget.onDurationChanged != null) {
        widget.onDurationChanged!(_focusDuration);
      }
      widget.onSelected(_selected);
    }
  }

  void _parseNatural(String raw) {
    final text = raw.trim().toLowerCase();
    final today = _dateOnly(DateTime.now());
    DateTime? parsed;
    if (text == 'today') parsed = today;
    if (text == 'tomorrow') parsed = today.add(const Duration(days: 1));
    if (text == 'next week') parsed = today.add(const Duration(days: 7));
    final inDays = RegExp(r'^in (\d+) days?$').firstMatch(text);
    if (inDays != null)
      parsed = today.add(Duration(days: int.parse(inDays.group(1)!)));
    final nextWeekday = RegExp(
      r'^next (monday|tuesday|wednesday|thursday|friday|saturday|sunday)$',
    ).firstMatch(text);
    if (nextWeekday != null)
      parsed = _nextWeekday(today, nextWeekday.group(1)!);
    if (parsed != null) {
      setState(() {
        _selected = _withTime(parsed!);
        final targetIndex = _indexOfDate(_selected!);
        _scrollController.jumpTo(targetIndex * _monthBlockHeight);
      });
    }
  }

  DateTime _nextWeekday(DateTime from, String day) {
    final target =
        const {
          'monday': 1,
          'tuesday': 2,
          'wednesday': 3,
          'thursday': 4,
          'friday': 5,
          'saturday': 6,
          'sunday': 7,
        }[day]!;
    var diff = target - from.weekday;
    if (diff <= 0) diff += 7;
    return from.add(Duration(days: diff));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF5B7FFF),
                surface: Color(0xFF111827),
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  DateTime _withTime(DateTime date) =>
      DateTime(date.year, date.month, date.day, _time.hour, _time.minute);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
