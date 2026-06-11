import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Smart Dropdown Overlay — shared positioning + arrow connector for all menus
// ─────────────────────────────────────────────────────────────────────────────

const double _kMenuWidth = 280.0;
const double _kSafeEdge = 16.0;
const double _kArrowStemLength = 14.0;
const double _kArrowTipSize = 8.0;
const double _kArrowTotal = _kArrowStemLength + _kArrowTipSize;

enum _Side { below, above, right, left }

class _DropdownLayout {
  const _DropdownLayout({
    required this.menuLeft,
    required this.menuTop,
    required this.arrowStartX,
    required this.arrowStartY,
    required this.arrowEndX,
    required this.arrowEndY,
    required this.side,
  });

  final double menuLeft;
  final double menuTop;
  final double arrowStartX; // global
  final double arrowStartY; // global
  final double arrowEndX;   // global
  final double arrowEndY;   // global
  final _Side side;
}

_DropdownLayout _computeLayout({
  required Rect trigger,
  required Size screen,
  required double menuHeight,
}) {
  const mw = _kMenuWidth;
  final trigCx = trigger.left + trigger.width / 2;
  final trigCy = trigger.top + trigger.height / 2;

  final hasRoomBelow = trigger.bottom + _kArrowTotal + menuHeight < screen.height - _kSafeEdge;
  final hasRoomAbove = trigger.top - _kArrowTotal - menuHeight > _kSafeEdge;
  final hasRoomRight = trigger.right + _kArrowTotal + mw < screen.width - _kSafeEdge;
  final hasRoomLeft = trigger.left - _kArrowTotal - mw > _kSafeEdge;

  final _Side side = hasRoomBelow
      ? _Side.below
      : (hasRoomAbove
          ? _Side.above
          : (hasRoomRight ? _Side.right : (hasRoomLeft ? _Side.left : _Side.below)));

  double left;
  double top;
  double arrowStartX;
  double arrowStartY;
  double arrowEndX;
  double arrowEndY;

  switch (side) {
    case _Side.below:
      left = (trigCx - mw / 2).clamp(_kSafeEdge, screen.width - mw - _kSafeEdge);
      top = trigger.bottom + _kArrowStemLength;
      arrowStartX = trigCx;
      arrowStartY = trigger.bottom;
      arrowEndY = top;
      arrowEndX = trigCx.clamp(left + 20, left + mw - 20);
      break;
    case _Side.above:
      left = (trigCx - mw / 2).clamp(_kSafeEdge, screen.width - mw - _kSafeEdge);
      top = trigger.top - menuHeight - _kArrowTotal;
      if (top < _kSafeEdge) top = _kSafeEdge;
      arrowStartX = trigCx;
      arrowStartY = trigger.top;
      arrowEndY = trigger.top - _kArrowStemLength;
      arrowEndX = trigCx.clamp(left + 20, left + mw - 20);
      break;
    case _Side.right:
      left = trigger.right + _kArrowStemLength;
      top = (trigCy - menuHeight / 2).clamp(_kSafeEdge, screen.height - menuHeight - _kSafeEdge);
      arrowStartX = trigger.right;
      arrowStartY = trigCy;
      arrowEndX = left;
      arrowEndY = trigCy.clamp(top + 20, top + menuHeight - 20);
      break;
    case _Side.left:
      left = trigger.left - mw - _kArrowStemLength;
      top = (trigCy - menuHeight / 2).clamp(_kSafeEdge, screen.height - menuHeight - _kSafeEdge);
      arrowStartX = trigger.left;
      arrowStartY = trigCy;
      arrowEndX = left + mw;
      arrowEndY = trigCy.clamp(top + 20, top + menuHeight - 20);
      break;
  }

  return _DropdownLayout(
    menuLeft: left,
    menuTop: top,
    arrowStartX: arrowStartX,
    arrowStartY: arrowStartY,
    arrowEndX: arrowEndX,
    arrowEndY: arrowEndY,
    side: side,
  );
}

// ── Arrow Painter ─────────────────────────────────────────────────────────────

class _ArrowConnectorPainter extends CustomPainter {
  const _ArrowConnectorPainter({
    required this.start,
    required this.end,
    required this.progress,
    required this.side,
  });

  final Offset start;
  final Offset end;
  final double progress;
  final _Side side;

  bool get _goBelow => side == _Side.below;
  bool get _horizontal => side == _Side.right || side == _Side.left;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final actualEnd = Offset.lerp(start, end, progress)!;

    // Stem gradient
    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: _horizontal
            ? (side == _Side.right ? Alignment.centerLeft : Alignment.centerRight)
            : (_goBelow ? Alignment.topCenter : Alignment.bottomCenter),
        end: _horizontal
            ? (side == _Side.right ? Alignment.centerRight : Alignment.centerLeft)
            : (_goBelow ? Alignment.bottomCenter : Alignment.topCenter),
        colors: [
          Colors.white.withValues(alpha: .45),
          Colors.white.withValues(alpha: .15),
        ],
      ).createShader(Rect.fromPoints(start, actualEnd));

    // Glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = Colors.white.withValues(alpha: .10 * progress);

    canvas.drawLine(start, actualEnd, glowPaint);
    canvas.drawLine(start, actualEnd, stemPaint);

    // Diamond tip at end
    if (progress > 0.7) {
      final tipProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      final tipSize = _kArrowTipSize * tipProgress;
      final tipPath = Path()
        ..moveTo(actualEnd.dx, actualEnd.dy - tipSize / 2)
        ..lineTo(actualEnd.dx + tipSize / 2, actualEnd.dy)
        ..lineTo(actualEnd.dx, actualEnd.dy + tipSize / 2)
        ..lineTo(actualEnd.dx - tipSize / 2, actualEnd.dy)
        ..close();

      canvas.drawPath(
        tipPath,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
          ..color = Colors.white.withValues(alpha: .15 * tipProgress),
      );
      canvas.drawPath(
        tipPath,
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF071224).withValues(alpha: tipProgress)
          ..strokeWidth = 1,
      );
      canvas.drawPath(
        tipPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: .45 * tipProgress),
      );
    }
  }

  @override
  bool shouldRepaint(_ArrowConnectorPainter old) =>
      old.progress != progress || old.start != start || old.end != end || old.side != side;
}

// ── Animated overlay entry ────────────────────────────────────────────────────

class _SmartDropdownRoute extends PopupRoute<void> {
  _SmartDropdownRoute({
    required this.trigger,
    required this.menuBuilder,
    required this.screenSize,
  });

  final Rect trigger;
  final Widget Function(BuildContext context) menuBuilder;
  final Size screenSize;

  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => false;
  @override
  String? get barrierLabel => null;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 180);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return _SmartDropdownOverlay(
      trigger: trigger,
      animation: animation,
      screenSize: screenSize,
      menuBuilder: menuBuilder,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class _SmartDropdownOverlay extends StatefulWidget {
  const _SmartDropdownOverlay({
    required this.trigger,
    required this.animation,
    required this.screenSize,
    required this.menuBuilder,
  });

  final Rect trigger;
  final Animation<double> animation;
  final Size screenSize;
  final Widget Function(BuildContext context) menuBuilder;

  @override
  State<_SmartDropdownOverlay> createState() => _SmartDropdownOverlayState();
}

class _SmartDropdownOverlayState extends State<_SmartDropdownOverlay> {
  double _menuHeight = 300.0;
  final _menuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _menuKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && mounted) {
        setState(() => _menuHeight = box.size.height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = _computeLayout(
      trigger: widget.trigger,
      screen: widget.screenSize,
      menuHeight: _menuHeight,
    );

    final goBelow = layout.side == _Side.below;

    final arrowAnim = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    final menuAnim = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    );

    void dismiss() => Navigator.of(context, rootNavigator: true).pop();

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) { dismiss(); return null; }),
        },
        child: Focus(
          autofocus: true,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                // Arrow connector (non-interactive, painter only)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: arrowAnim,
                      builder: (_, __) => CustomPaint(
                        painter: _ArrowConnectorPainter(
                          start: Offset(layout.arrowStartX, layout.arrowStartY),
                          end: Offset(layout.arrowEndX, layout.arrowEndY),
                          progress: arrowAnim.value,
                          side: layout.side,
                        ),
                      ),
                    ),
                  ),
                ),
                // Full-screen barrier — sits above arrow, below menu
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: dismiss,
                    child: const SizedBox.expand(),
                  ),
                ),
                // Menu — topmost, absorbs its own taps
                Positioned(
                  left: layout.menuLeft,
                  top: layout.menuTop,
                  child: AnimatedBuilder(
                    animation: menuAnim,
                    builder: (ctx, child) => Opacity(
                      opacity: menuAnim.value,
                      child: Transform.scale(
                        scale: 0.95 + 0.05 * menuAnim.value,
                        alignment: goBelow ? Alignment.topCenter : Alignment.bottomCenter,
                        child: child,
                      ),
                    ),
                    child: SmartMenuContainer(
                      child: KeyedSubtree(
                        key: _menuKey,
                        child: widget.menuBuilder(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Show a smart dropdown anchored to [triggerKey]'s render box.
Future<void> showSmartDropdown({
  required BuildContext context,
  required GlobalKey triggerKey,
  required Widget Function(BuildContext context) menuBuilder,
}) async {
  final renderBox =
      triggerKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final topLeft = renderBox.localToGlobal(Offset.zero);
  final trigger = topLeft & renderBox.size;
  final screenSize = MediaQuery.sizeOf(context);

  await Navigator.of(context, rootNavigator: true).push(
    _SmartDropdownRoute(
      trigger: trigger,
      menuBuilder: menuBuilder,
      screenSize: screenSize,
    ),
  );
}

// ── Glass Menu Container ──────────────────────────────────────────────────────

class SmartMenuContainer extends StatelessWidget {
  const SmartMenuContainer({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: _kMenuWidth,
          decoration: BoxDecoration(
            color: const Color(0xFF071224).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 80,
                offset: const Offset(0, 25),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
