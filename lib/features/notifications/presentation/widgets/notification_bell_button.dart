import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:to_do_app/features/notifications/presentation/widgets/facebook_notification_dropdown.dart';
import 'package:to_do_app/features/notifications/presentation/widgets/notification_list_view.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class NotificationBellButton extends ConsumerStatefulWidget {
  const NotificationBellButton({super.key});

  @override
  ConsumerState<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends ConsumerState<NotificationBellButton>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // Shake animation: rotates bell slightly left and right
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -0.25), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -0.25, end: 0.25), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 0.25, end: -0.15), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -0.15, end: 0.15), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 0.15, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    // Glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _glowController.dispose();
    _audioPlayer.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _triggerNewNotificationEffects() async {
    // 1. Shake Bell
    _shakeController.forward(from: 0.0);

    // 2. Glow effect pulse
    _glowController.forward(from: 0.0).then((_) => _glowController.reverse());

    // 3. Play soft audio sound hook (if not muted)
    final isMuted = ref.read(muteNotificationsProvider);
    if (!isMuted && defaultTargetPlatform != TargetPlatform.windows) {
      try {
        await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-84.wav'));
      } catch (e) {
        debugPrint('Audio playback error: $e');
      }
    }
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1000;
    final width = isTablet ? 380.0 : 440.0;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible dismiss barrier
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeDropdown,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            width: width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 12),
              child: FacebookNotificationDropdown(
                width: width,
                onClose: _closeDropdown,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    // Listen to changes to trigger animations & sounds dynamically
    ref.listen<int>(unreadNotificationsCountProvider, (previous, next) {
      if (previous != null && next > previous) {
        _triggerNewNotificationEffects();
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedBuilder(
        animation: Listenable.merge([_shakeAnimation, _glowAnimation]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: _glowAnimation.value > 0
                  ? [
                      BoxShadow(
                        color: DashboardColors.primary.withValues(alpha: 0.6),
                        blurRadius: _glowAnimation.value,
                        spreadRadius: _glowAnimation.value / 4,
                      ),
                    ]
                  : [],
            ),
            child: Transform.rotate(
              angle: _shakeAnimation.value,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        if (isMobile) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              height: MediaQuery.of(context).size.height * 0.9,
                              decoration: const BoxDecoration(
                                color: Color(0xff0F172A),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(28),
                                  topRight: Radius.circular(28),
                                ),
                              ),
                              child: const ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(28),
                                  topRight: Radius.circular(28),
                                ),
                                child: NotificationListView(isFullScreen: false),
                              ),
                            ),
                          );
                        } else {
                          _toggleDropdown();
                        }
                      },
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          _isOpen ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [DashboardColors.primary, DashboardColors.secondary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DashboardColors.primary.withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        alignment: Alignment.center,
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
