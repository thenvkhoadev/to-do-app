import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/xp/presentation/providers/xp_providers.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kToastWidth = 320.0;
const _kToastSpacing = 14.0; // gap between stacked toasts
const _kToastHeight = 112.0; // normal toast rendered height
const _kToastHeightBonus = 134.0; // toast with lucky bonus row
const _kNavbarHeight = 64.0; // top navbar height
const _kTopPad = 16.0; // padding below navbar

// ── Single XP toast tile ──────────────────────────────────────────────────────

class _XpToastTile extends StatefulWidget {
  const _XpToastTile({
    required this.notification,
    required this.expiresAt,
    required this.onDone,
  });

  final XpNotification notification;
  final DateTime expiresAt;
  final ValueChanged<bool> onDone;

  @override
  State<_XpToastTile> createState() => _XpToastTileState();
}

class _XpToastTileState extends State<_XpToastTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  Timer? _stayTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
    _scheduleAutoDismiss();
  }

  @override
  void didUpdateWidget(covariant _XpToastTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _scheduleAutoDismiss();
    }
  }

  void _scheduleAutoDismiss() {
    _stayTimer?.cancel();
    final remaining = widget.expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _exit();
      return;
    }
    _stayTimer = Timer(remaining, _exit);
  }

  void _exit() {
    if (!mounted) return;
    _stayTimer?.cancel();
    _ctrl.duration = const Duration(milliseconds: 200);
    _slide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -1.0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.reverse().then((_) {
      if (mounted) widget.onDone(false);
    });
  }

  void _dismissBySwipe() {
    _stayTimer?.cancel();
    widget.onDone(true);
  }

  @override
  void dispose() {
    _stayTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Dismissible(
          key: ValueKey('dismiss-${widget.notification.id}'),
          direction: DismissDirection.startToEnd,
          resizeDuration: null,
          onDismissed: (_) => _dismissBySwipe(),
          child: Material(
            type: MaterialType.transparency,
            child: _ToastBody(notification: widget.notification),
          ),
        ),
      ),
    );
  }
}

// ── Overlay widget — stacks toasts, newest below current ─────────────────────

class XpNotificationOverlay extends ConsumerStatefulWidget {
  const XpNotificationOverlay({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<XpNotificationOverlay> createState() =>
      _XpNotificationOverlayState();
}

class _XpNotificationOverlayState extends ConsumerState<XpNotificationOverlay> {
  // Active toasts currently visible on screen (max 5).
  final List<_ActiveToast> _active = [];

  void _onToastDone(String id, bool swiped) {
    ref.read(xpNotificationQueueProvider.notifier).remove(id);
    if (!mounted) return;
    setState(() {
      final removedIndex = _active.indexWhere((t) => t.notification.id == id);
      if (removedIndex == -1) return;
      _active.removeAt(removedIndex);
      if (swiped) {
        for (var i = removedIndex; i < _active.length; i++) {
          _active[i] = _active[i].shortenedBy(const Duration(seconds: 5));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(xpNotificationQueueProvider);

    // Add any queued items not yet active (cap at 5 visible; oldest evicted).
    // Lifetime = 5s × (position when arriving). New ones inherit a longer
    // deadline; existing toasts keep their original deadline (no reset).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final activeIds = _active.map((t) => t.notification.id).toSet();
      bool changed = false;
      for (final n in queue) {
        if (!activeIds.contains(n.id)) {
          final position = _active.length + 1;
          _active.add(
            _ActiveToast(
              notification: n,
              expiresAt: DateTime.now().add(Duration(seconds: 5 * position)),
            ),
          );
          changed = true;
        }
      }
      while (_active.length > 5) {
        _active.removeAt(0);
        changed = true;
      }
      if (changed && mounted) setState(() {});
    });

    final topBase =
        MediaQuery.of(context).padding.top + _kNavbarHeight + _kTopPad;

    return Stack(
      children: [
        widget.child,
        // Render toasts stacked top-right, newest on top
        for (int i = 0; i < _active.length; i++)
          () {
            final t = _active[i];
            return _PositionedToast(
              key: ValueKey(t.notification.id),
              notification: t.notification,
              expiresAt: t.expiresAt,
              topOffset: _computeTop(i, topBase),
              onDone: (swiped) => _onToastDone(t.notification.id, swiped),
            );
          }(),
      ],
    );
  }

  /// Toast 0 sits just below the navbar. Each subsequent toast sits below
  /// the previous one. Heights matched to actual rendered layout.
  double _computeTop(int index, double base) {
    double offset = base;
    for (int i = 0; i < index; i++) {
      final n = _active[i].notification;
      final height = n.hasLuckyBonus ? _kToastHeightBonus : _kToastHeight;
      offset += height + _kToastSpacing;
    }
    return offset;
  }
}

class _ActiveToast {
  const _ActiveToast({required this.notification, required this.expiresAt});

  final XpNotification notification;
  final DateTime expiresAt;

  _ActiveToast shortenedBy(Duration duration) {
    return _ActiveToast(
      notification: notification,
      expiresAt: expiresAt.subtract(duration),
    );
  }
}

// ── Positioned toast wrapper ──────────────────────────────────────────────────

class _PositionedToast extends StatelessWidget {
  const _PositionedToast({
    super.key,
    required this.notification,
    required this.expiresAt,
    required this.topOffset,
    required this.onDone,
  });

  final XpNotification notification;
  final DateTime expiresAt;
  final double topOffset;
  final ValueChanged<bool> onDone;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      right: 24,
      top: topOffset,
      width: _kToastWidth,
      child: _XpToastTile(
        notification: notification,
        expiresAt: expiresAt,
        onDone: onDone,
      ),
    );
  }
}

// ── Toast body ────────────────────────────────────────────────────────────────

class _ToastBody extends StatefulWidget {
  const _ToastBody({required this.notification});
  final XpNotification notification;

  @override
  State<_ToastBody> createState() => _ToastBodyState();
}

class _ToastBodyState extends State<_ToastBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countCtrl;
  late final Animation<int> _countAnim;

  @override
  void initState() {
    super.initState();
    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _countAnim = IntTween(
      begin: 0,
      end: widget.notification.xpGained,
    ).animate(CurvedAnimation(parent: _countCtrl, curve: Curves.easeOutCubic));
    _countCtrl.forward();
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  ({IconData icon, Color color}) _iconFor(XpNotification n) {
    if (n.hasLuckyBonus || n.priority == 'bonus' || n.reason == 'Lucky Bonus') {
      return (icon: Icons.casino_rounded, color: const Color(0xFF67E8F9));
    }
    if (n.reason == 'Task Created') {
      return (icon: Icons.add_task_rounded, color: const Color(0xFFB794F6));
    }
    if (n.reason == 'Subtask Completed') {
      return (icon: Icons.task_alt_rounded, color: const Color(0xFF67E8F9));
    }
    if (n.priority == 'urgent') {
      return (
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFFFD166),
      );
    }
    if (n.priority == 'high') {
      return (
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF8A5C),
      );
    }
    if (n.priority == 'medium') {
      return (icon: Icons.flash_on_rounded, color: const Color(0xFFB794F6));
    }
    if (n.priority == 'low') {
      return (icon: Icons.eco_rounded, color: const Color(0xFF7BD389));
    }
    return (icon: Icons.auto_awesome_rounded, color: const Color(0xFFB794F6));
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final iconData = _iconFor(n);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: _kToastWidth,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1226).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 50,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(iconData.icon, color: iconData.color, size: 22),
                  const SizedBox(width: 10),
                  AnimatedBuilder(
                    animation: _countAnim,
                    builder:
                        (_, __) => ShaderMask(
                          shaderCallback:
                              (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFB794F6),
                                  Color(0xFF7B6CF6),
                                  Color(0xFF67E8F9),
                                ],
                              ).createShader(bounds),
                          child: Text(
                            '+${_countAnim.value} XP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                n.reason,
                style: const TextStyle(
                  color: Color(0xFFE2E5F4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(n.createdAt),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
