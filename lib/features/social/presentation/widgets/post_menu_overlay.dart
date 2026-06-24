import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostMenuOverlay extends StatefulWidget {
  final BuildContext triggerContext;
  final LayerLink layerLink;
  final String postId;
  final bool isMe;
  final String currentPrivacy;
  final bool isPinned;
  final bool isArchived;
  final bool isCommentsDisabled;
  final bool isNotificationsDisabled;
  final bool isSaved;
  final bool isHidden;
  final String authorName;
  final String authorAvatarUrl;
  final void Function(String action) onAction;
  final void Function(String privacy) onPrivacyChanged;
  final VoidCallback onClose;

  const PostMenuOverlay({
    super.key,
    required this.triggerContext,
    required this.layerLink,
    required this.postId,
    required this.isMe,
    required this.currentPrivacy,
    required this.isPinned,
    required this.isArchived,
    required this.isCommentsDisabled,
    required this.isNotificationsDisabled,
    required this.isSaved,
    required this.isHidden,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.onAction,
    required this.onPrivacyChanged,
    required this.onClose,
  });

  static OverlayEntry? _currentOverlayEntry;
  static VoidCallback? _onCurrentMenuClosed;

  static void closeCurrentMenu() {
    if (_currentOverlayEntry != null) {
      final entry = _currentOverlayEntry!;
      _currentOverlayEntry = null;
      try {
        entry.remove();
      } catch (_) {}
      _onCurrentMenuClosed?.call();
      _onCurrentMenuClosed = null;
    }
  }

  static void show({
    required BuildContext context,
    required BuildContext triggerContext,
    required LayerLink layerLink,
    required String postId,
    required bool isMe,
    required String currentPrivacy,
    required bool isPinned,
    required bool isArchived,
    required bool isCommentsDisabled,
    required bool isNotificationsDisabled,
    required bool isSaved,
    required bool isHidden,
    required String authorName,
    required String authorAvatarUrl,
    required void Function(String action) onAction,
    required void Function(String privacy) onPrivacyChanged,
    VoidCallback? onClose,
  }) {
    closeCurrentMenu();

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return PostMenuOverlay(
          triggerContext: triggerContext,
          layerLink: layerLink,
          postId: postId,
          isMe: isMe,
          currentPrivacy: currentPrivacy,
          isPinned: isPinned,
          isArchived: isArchived,
          isCommentsDisabled: isCommentsDisabled,
          isNotificationsDisabled: isNotificationsDisabled,
          isSaved: isSaved,
          isHidden: isHidden,
          authorName: authorName,
          authorAvatarUrl: authorAvatarUrl,
          onAction: (action) {
            closeCurrentMenu();
            onAction(action);
          },
          onPrivacyChanged: (privacy) {
            closeCurrentMenu();
            onPrivacyChanged(privacy);
          },
          onClose: () {
            closeCurrentMenu();
          },
        );
      },
    );

    _currentOverlayEntry = overlayEntry;
    _onCurrentMenuClosed = onClose;

    overlayState.insert(overlayEntry);
  }

  @override
  State<PostMenuOverlay> createState() => _PostMenuOverlayState();
}

class _PostMenuOverlayState extends State<PostMenuOverlay> with SingleTickerProviderStateMixin {
  final GlobalKey _visibilityTileKey = GlobalKey();
  final GlobalKey _mainMenuKey = GlobalKey();
  final GlobalKey _submenuKey = GlobalKey();
  bool _showSubmenu = false;
  double _submenuTop = 0;
  double _submenuLeft = 0;

  ScrollableState? _scrollable;
  final ScrollController _menuScrollController = ScrollController();
  late FocusNode _focusNode;

  late AnimationController _menuAnimationController;
  late Animation<double> _menuFadeAnimation;
  late Animation<double> _menuScaleAnimation;
  late Animation<Offset> _menuSlideAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _menuFadeAnimation = CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeOutCubic,
    );

    _menuScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _menuSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _setupScrollListener();
    });

    _menuAnimationController.forward();
  }

  @override
  void dispose() {
    _scrollable?.position.removeListener(_onScroll);
    _menuScrollController.dispose();
    _focusNode.dispose();
    _menuAnimationController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    if (!mounted) return;
    _scrollable = Scrollable.maybeOf(widget.triggerContext);
    _scrollable?.position.addListener(_onScroll);
  }

  void _onScroll() {
    // Scroll automatically closes the menu
    _closeMenu();
  }

  void _closeMenu() {
    _menuAnimationController.reverse().then((_) {
      widget.onClose();
    });
  }

  void _calculateSubmenuPosition() {
    if (!mounted) return;
    final tileRenderBox = _visibilityTileKey.currentContext?.findRenderObject() as RenderBox?;
    final mainMenuRenderBox = _mainMenuKey.currentContext?.findRenderObject() as RenderBox?;
    if (tileRenderBox != null && mainMenuRenderBox != null) {
      final tilePosition = tileRenderBox.localToGlobal(Offset.zero);
      final menuPosition = mainMenuRenderBox.localToGlobal(Offset.zero);
      final screenSize = MediaQuery.of(context).size;

      double left = menuPosition.dx + 320 + 8;
      if (left + 260 > screenSize.width) {
        left = menuPosition.dx - 260 - 8;
      }

      setState(() {
        _submenuTop = tilePosition.dy;
        _submenuLeft = left;
      });
    }
  }

  void _onPrivacyClick() {
    if (_showSubmenu) {
      setState(() {
        _showSubmenu = false;
      });
      return;
    }

    setState(() {
      _showSubmenu = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateSubmenuPosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final mainMenuCard = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C5CFF).withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: -5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            key: _mainMenuKey,
            decoration: BoxDecoration(
              color: const Color(0xE6151827),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF7C5CFF).withOpacity(0.16),
                width: 1,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: Scrollbar(
                controller: _menuScrollController,
                child: SingleChildScrollView(
                  controller: _menuScrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: widget.authorAvatarUrl.isNotEmpty
                                  ? NetworkImage(widget.authorAvatarUrl)
                                  : null,
                              backgroundColor: Colors.grey.shade800,
                              child: widget.authorAvatarUrl.isEmpty
                                  ? const Icon(Icons.person, size: 16, color: Colors.white54)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.authorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  Text(
                                    widget.isMe ? 'Bài viết của bạn' : 'Bài viết',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 4),
                      if (widget.isMe) ...[
                        PostMenuItem(
                          icon: Icons.edit_outlined,
                          label: 'Chỉnh sửa bài viết',
                          onTap: () => widget.onAction('edit'),
                        ),
                        PostMenuItem(
                          icon: widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          label: widget.isPinned ? 'Bỏ ghim bài viết' : 'Ghim bài viết',
                          onTap: () => widget.onAction('pin'),
                        ),
                        PostMenuItem(
                          icon: widget.isArchived ? Icons.archive : Icons.archive_outlined,
                          label: widget.isArchived ? 'Bỏ lưu trữ' : 'Lưu trữ',
                          description: 'Ẩn khỏi feed, vẫn lưu lại',
                          onTap: () => widget.onAction('archive'),
                        ),
                        const Divider(color: Colors.white10),
                        PostMenuItem(
                          key: _visibilityTileKey,
                          icon: widget.currentPrivacy == 'private'
                              ? Icons.lock_outlined
                              : widget.currentPrivacy == 'friends'
                                  ? Icons.people_outline
                                  : Icons.public,
                          label: 'Ai có thể xem',
                          description: 'Thay đổi đối tượng xem bài',
                          onTap: _onPrivacyClick,
                          trailing: const Icon(Icons.chevron_right, color: Colors.white38, size: 16),
                        ),
                        PostMenuItem(
                          icon: widget.isCommentsDisabled ? Icons.comment_outlined : Icons.comments_disabled_outlined,
                          label: widget.isCommentsDisabled ? 'Bật bình luận' : 'Tắt bình luận',
                          onTap: () => widget.onAction('toggle_comment'),
                        ),
                        PostMenuItem(
                          icon: widget.isNotificationsDisabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                          label: widget.isNotificationsDisabled ? 'Bật thông báo bài này' : 'Tắt thông báo bài này',
                          onTap: () => widget.onAction('turn_off_notification'),
                        ),
                        const Divider(color: Colors.white10),
                        PostMenuItem(
                          icon: Icons.add_task_outlined,
                          label: 'Gắn vào Task',
                          description: 'Liên kết bài viết với task',
                          onTap: () => widget.onAction('link_task'),
                        ),
                        PostMenuItem(
                          icon: Icons.bar_chart_rounded,
                          label: 'Xem thống kê',
                          description: 'Lượt xem, react, reach',
                          onTap: () => widget.onAction('insights'),
                        ),
                        const Divider(color: Colors.white10),
                        PostMenuItem(
                          icon: Icons.delete_outline_rounded,
                          label: 'Xóa bài viết',
                          isDestructive: true,
                          onTap: () => widget.onAction('delete'),
                        ),
                      ] else ...[
                        PostMenuItem(
                          icon: widget.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          label: widget.isSaved ? 'Bỏ lưu bài viết' : 'Lưu bài viết',
                          description: 'Thêm vào danh sách đã lưu',
                          onTap: () => widget.onAction('save'),
                        ),
                        PostMenuItem(
                          icon: Icons.link_rounded,
                          label: 'Sao chép liên kết',
                          onTap: () => widget.onAction('copy_link'),
                        ),
                        const Divider(color: Colors.white10),
                        PostMenuItem(
                          icon: Icons.visibility_off_outlined,
                          label: 'Ẩn bài viết này',
                          description: 'Không hiện lại bài này trên feed',
                          onTap: () => widget.onAction('hide'),
                        ),
                        PostMenuItem(
                          icon: Icons.do_not_disturb_alt_outlined,
                          label: 'Bớt hiển thị của ${widget.authorName}',
                          description: 'Giảm tần suất bài từ người này',
                          onTap: () => widget.onAction('snooze'),
                        ),
                        const Divider(color: Colors.white10),
                        PostMenuItem(
                          icon: Icons.add_task_outlined,
                          label: 'Lưu thành Task',
                          description: 'Tạo task mới từ bài viết này',
                          onTap: () => widget.onAction('save_as_task'),
                        ),
                        const Divider(color: Colors.white10),
                        PostMenuItem(
                          icon: Icons.flag_outlined,
                          label: 'Báo cáo bài viết',
                          isDestructive: true,
                          iconColor: Colors.orangeAccent,
                          onTap: () => widget.onAction('report'),
                        ),
                        PostMenuItem(
                          icon: Icons.block_rounded,
                          label: 'Chặn ${widget.authorName}',
                          isDestructive: true,
                          onTap: () => widget.onAction('block'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          _closeMenu();
        }
      },
      child: Stack(
        children: [
          // Dismiss tap barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          
          if (!isMobile) ...[
            // Desktop context menu anchored to LayerLink
            Positioned(
              width: 320,
              child: CompositedTransformFollower(
                link: widget.layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: const Offset(0, 8),
                child: FadeTransition(
                  opacity: _menuFadeAnimation,
                  child: ScaleTransition(
                    scale: _menuScaleAnimation,
                    alignment: Alignment.topRight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Arrow pointing up to trigger middle dot
                        const Positioned(
                          top: -13,
                          right: 11,
                          child: MenuPointer(),
                        ),
                        mainMenuCard,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Sub Menu (Desktop)
            if (_showSubmenu)
              Positioned(
                left: _submenuLeft,
                top: _submenuTop,
                width: 260,
                child: VisibilitySubMenu(
                  key: _submenuKey,
                  currentPrivacy: widget.currentPrivacy,
                  onPrivacyChanged: widget.onPrivacyChanged,
                ),
              ),
          ] else ...[
            // Mobile bottom sheet style sliding up from bottom center
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: FadeTransition(
                      opacity: _menuFadeAnimation,
                      child: SlideTransition(
                        position: _menuSlideAnimation,
                        child: mainMenuCard,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Sub Menu (Mobile)
            if (_showSubmenu)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: VisibilitySubMenu(
                        key: _submenuKey,
                        currentPrivacy: widget.currentPrivacy,
                        onPrivacyChanged: widget.onPrivacyChanged,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class PostMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final VoidCallback onTap;
  final bool isDestructive;
  final Color? iconColor;
  final Widget? trailing;
  final bool isSelected;

  const PostMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    required this.onTap,
    this.isDestructive = false,
    this.iconColor,
    this.trailing,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = isDestructive ? (iconColor ?? Colors.redAccent) : Colors.white;

    final selectedBgColor = const Color(0xFF7C5CFF).withOpacity(0.15);
    final selectedIconColor = const Color(0xFF7C5CFF);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withOpacity(0.06),
          splashColor: Colors.white.withOpacity(0.02),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.transparent 
                        : (isDestructive
                            ? itemColor.withOpacity(0.12)
                            : Colors.white.withOpacity(0.07)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon, 
                    color: isSelected 
                        ? selectedIconColor 
                        : (isDestructive ? itemColor : Colors.white70), 
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : itemColor,
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          description!,
                          style: TextStyle(
                            color: isSelected ? Colors.white.withOpacity(0.5) : Colors.white38,
                            fontSize: 11,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VisibilitySubMenu extends StatefulWidget {
  final String currentPrivacy;
  final void Function(String privacy) onPrivacyChanged;

  const VisibilitySubMenu({
    super.key,
    required this.currentPrivacy,
    required this.onPrivacyChanged,
  });

  @override
  State<VisibilitySubMenu> createState() => _VisibilitySubMenuState();
}

class _VisibilitySubMenuState extends State<VisibilitySubMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<double>(
      begin: 10.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C5CFF).withOpacity(0.12),
              blurRadius: 30,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: -5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xE6151827),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF7C5CFF).withOpacity(0.16),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Ai có thể xem bài viết này?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 4),
                  PostMenuItem(
                    icon: Icons.public,
                    label: 'Công khai',
                    description: 'Tất cả mọi người',
                    isSelected: widget.currentPrivacy == 'public',
                    onTap: () => widget.onPrivacyChanged('public'),
                  ),
                  PostMenuItem(
                    icon: Icons.people_outline,
                    label: 'Bạn bè',
                    description: 'Chỉ danh sách bạn bè',
                    isSelected: widget.currentPrivacy == 'friends',
                    onTap: () => widget.onPrivacyChanged('friends'),
                  ),
                  PostMenuItem(
                    icon: Icons.lock_outline,
                    label: 'Chỉ mình tôi',
                    description: 'Không ai khác nhìn thấy',
                    isSelected: widget.currentPrivacy == 'private',
                    onTap: () => widget.onPrivacyChanged('private'),
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

class _MenuPointerPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  _MenuPointerPainter({
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, size.height + 2) // extend down to overlap menu border
      ..lineTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height + 2)
      ..close();

    canvas.drawPath(path, fillPaint);

    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _MenuPointerPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor || oldDelegate.borderColor != borderColor;
  }
}

class MenuPointer extends StatelessWidget {
  const MenuPointer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(26, 13),
      painter: _MenuPointerPainter(
        fillColor: const Color(0xE6151827),
        borderColor: const Color(0xFF7C5CFF).withOpacity(0.16),
      ),
    );
  }
}

