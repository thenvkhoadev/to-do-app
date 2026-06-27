import 'package:flutter/material.dart';
import 'package:to_do_app/features/social/presentation/providers/story_state_providers.dart';

// Text Overlay Widget (image14)
class DraggableTextOverlayWidget extends StatefulWidget {
  const DraggableTextOverlayWidget({
    super.key,
    required this.overlay,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.isSelected,
    required this.onTap,
    required this.onUpdate,
    required this.onDelete,
  });

  final TextOverlay overlay;
  final double canvasWidth;
  final double canvasHeight;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(TextOverlay updated) onUpdate;
  final VoidCallback onDelete;

  @override
  State<DraggableTextOverlayWidget> createState() => _DraggableTextOverlayWidgetState();
}

class _DraggableTextOverlayWidgetState extends State<DraggableTextOverlayWidget> {
  bool _isHovering = false;
  bool _isDragging = false;
  bool _isEditing = false;

  // High-precision local drag coordinates for smooth movement
  double? _dragX;
  double? _dragY;

  // Distance-based corner resize parameters
  double _initialDragDist = 1.0;
  double _initialScale = 1.0;

  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.overlay.text);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _isEditing = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant DraggableTextOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay.text != widget.overlay.text && _textController.text != widget.overlay.text) {
      _textController.text = widget.overlay.text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onResizeStart(Offset globalPosition, double w, double h) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset localCenter = Offset(w / 2, h / 2);
    final Offset globalCenter = renderBox.localToGlobal(localCenter);
    _initialDragDist = (globalPosition - globalCenter).distance;
    _initialScale = widget.overlay.scale;
  }

  void _onResizeUpdate(Offset globalPosition, double w, double h, double baseWidth, double minScale, double maxScale) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset localCenter = Offset(w / 2, h / 2);
    final Offset globalCenter = renderBox.localToGlobal(localCenter);
    final double currentDist = (globalPosition - globalCenter).distance;
    if (_initialDragDist > 0) {
      final double newScale = (_initialScale * (currentDist / _initialDragDist)).clamp(minScale, maxScale);
      widget.onUpdate(widget.overlay.copyWith(scale: newScale));
    }
  }

  Widget _buildCornerHandle({
    required MouseCursor cursor,
    required double left,
    required double top,
    required double w,
    required double h,
    required double baseWidth,
    double minScale = 0.5,
    double maxScale = 2.5,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (details) {
          _onResizeStart(details.globalPosition, w, h);
        },
        onPanUpdate: (details) {
          _onResizeUpdate(details.globalPosition, w, h, baseWidth, minScale, maxScale);
        },
        child: MouseRegion(
          cursor: cursor,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
              ],
              border: Border.all(color: const Color(0xFF7C5CFF), width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.open_in_full,
                color: Color(0xFF7C5CFF),
                size: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double posX = widget.overlay.x * widget.canvasWidth;
    final double posY = widget.overlay.y * widget.canvasHeight;
    final double scale = widget.overlay.scale;

    // Approximate size of text box
    const double baseWidth = 180;
    const double baseHeight = 60;
    final double w = baseWidth * scale;
    final double h = baseHeight * scale;

    final showBorder = widget.isSelected || _isHovering || _isDragging;

    return Positioned(
      left: posX - (w / 2),
      top: posY - (h / 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: GestureDetector(
          onTap: () {
            widget.onTap();
            setState(() {
              _isEditing = true;
            });
            _focusNode.requestFocus();
          },
          onPanStart: (details) {
            widget.onTap();
            _dragX = widget.overlay.x * widget.canvasWidth;
            _dragY = widget.overlay.y * widget.canvasHeight;
            setState(() {
              _isDragging = true;
            });
          },
          onPanUpdate: (details) {
            if (_dragX == null || _dragY == null) return;
            _dragX = _dragX! + details.delta.dx;
            _dragY = _dragY! + details.delta.dy;

            final double newX = (_dragX! / widget.canvasWidth).clamp(0.05, 0.95);
            final double newY = (_dragY! / widget.canvasHeight).clamp(0.05, 0.95);
            widget.onUpdate(widget.overlay.copyWith(x: newX, y: newY));
          },
          onPanEnd: (_) {
            setState(() {
              _isDragging = false;
              _dragX = null;
              _dragY = null;
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The Text Container
              Container(
                width: w,
                height: h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: showBorder
                      ? Border.all(
                          color: Colors.white.withValues(alpha: .6),
                          width: 1.5,
                          style: BorderStyle.none, // Painted dashed border instead
                        )
                      : null,
                ),
                child: CustomPaint(
                  painter: showBorder ? DashedBorderPainter(color: Colors.white.withValues(alpha: .6)) : null,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _isEditing
                          ? TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              textAlign: TextAlign.center,
                              maxLines: null,
                              cursorColor: widget.overlay.color,
                              style: TextStyle(
                                color: widget.overlay.color,
                                fontSize: 20 * scale,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              onChanged: (val) {
                                widget.onUpdate(widget.overlay.copyWith(text: val));
                              },
                            )
                          : Text(
                              widget.overlay.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: widget.overlay.color,
                                fontSize: 20 * scale,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // Delete Handle [x] at top-left
              if (showBorder)
                Positioned(
                  top: -10,
                  left: -10,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xE6000000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ),

              // Floating Move Icon at bottom center of the border
              if (showBorder)
                Positioned(
                  bottom: -10,
                  left: (w / 2) - 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xE6000000),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Icon(Icons.open_with, color: Colors.white, size: 11),
                  ),
                ),

              // Corner Resize Handles
              if (showBorder) ...[
                // Top Right (NE)
                _buildCornerHandle(
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  left: w - 10,
                  top: -10,
                  w: w,
                  h: h,
                  baseWidth: baseWidth,
                ),
                // Bottom Right (SE)
                _buildCornerHandle(
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  left: w - 10,
                  top: h - 10,
                  w: w,
                  h: h,
                  baseWidth: baseWidth,
                ),
                // Bottom Left (SW)
                _buildCornerHandle(
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  left: -10,
                  top: h - 10,
                  w: w,
                  h: h,
                  baseWidth: baseWidth,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Music Card Overlay Widget (image18)
class DraggableMusicOverlayWidget extends StatefulWidget {
  const DraggableMusicOverlayWidget({
    super.key,
    required this.overlay,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.isSelected,
    required this.onTap,
    required this.onUpdate,
    required this.onDelete,
  });

  final MusicOverlay overlay;
  final double canvasWidth;
  final double canvasHeight;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(MusicOverlay updated) onUpdate;
  final VoidCallback onDelete;

  @override
  State<DraggableMusicOverlayWidget> createState() => _DraggableMusicOverlayWidgetState();
}

class _DraggableMusicOverlayWidgetState extends State<DraggableMusicOverlayWidget> {
  bool _isHovering = false;
  bool _isDragging = false;

  // High-precision local drag coordinates for smooth movement
  double? _dragX;
  double? _dragY;

  // Distance-based corner resize parameters
  double _initialDragDist = 1.0;
  double _initialScale = 1.0;

  void _onResizeStart(Offset globalPosition, double w, double h) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset localCenter = Offset(w / 2, h / 2);
    final Offset globalCenter = renderBox.localToGlobal(localCenter);
    _initialDragDist = (globalPosition - globalCenter).distance;
    _initialScale = widget.overlay.scale;
  }

  void _onResizeUpdate(Offset globalPosition, double w, double h, double baseWidth, double minScale, double maxScale) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset localCenter = Offset(w / 2, h / 2);
    final Offset globalCenter = renderBox.localToGlobal(localCenter);
    final double currentDist = (globalPosition - globalCenter).distance;
    if (_initialDragDist > 0) {
      final double newScale = (_initialScale * (currentDist / _initialDragDist)).clamp(minScale, maxScale);
      widget.onUpdate(widget.overlay.copyWith(scale: newScale));
    }
  }

  Widget _buildCornerHandle({
    required MouseCursor cursor,
    required double left,
    required double top,
    required double w,
    required double h,
    required double baseWidth,
    double minScale = 0.5,
    double maxScale = 2.0,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (details) {
          _onResizeStart(details.globalPosition, w, h);
        },
        onPanUpdate: (details) {
          _onResizeUpdate(details.globalPosition, w, h, baseWidth, minScale, maxScale);
        },
        child: MouseRegion(
          cursor: cursor,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
              ],
              border: Border.all(color: const Color(0xFF7C5CFF), width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.open_in_full,
                color: Color(0xFF7C5CFF),
                size: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double posX = widget.overlay.x * widget.canvasWidth;
    final double posY = widget.overlay.y * widget.canvasHeight;
    final double scale = widget.overlay.scale;

    // Dimensions based on chosen style layout
    double baseWidth = 150;
    double baseHeight = 160;
    final int layoutStyle = widget.overlay.layoutStyle;

    if (layoutStyle == 1) {
      baseWidth = 180;
      baseHeight = 64;
    } else if (layoutStyle == 2) {
      baseWidth = 180;
      baseHeight = 44;
    } else if (layoutStyle == 3) {
      baseWidth = 100;
      baseHeight = 120;
    }

    final double w = baseWidth * scale;
    final double h = baseHeight * scale;

    final showBorder = widget.isSelected || _isHovering || _isDragging;

    // Render child matching layoutStyle choice
    Widget cardChild;
    if (layoutStyle == 1) {
      // Horizontal Card
      cardChild = Container(
        color: const Color(0xE61A1A1A),
        padding: EdgeInsets.all(8 * scale),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6 * scale),
              child: Image.network(
                widget.overlay.coverUrl,
                width: 48 * scale,
                height: 48 * scale,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48 * scale,
                  height: 48 * scale,
                  color: Colors.grey.shade800,
                  child: Icon(Icons.music_note_rounded, color: Colors.white70, size: 20 * scale),
                ),
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.overlay.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 12 * scale, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    widget.overlay.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 10 * scale),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (layoutStyle == 2) {
      // Minimal Horizontal Banner
      cardChild = Container(
        color: const Color(0xE61A1A1A),
        padding: EdgeInsets.symmetric(horizontal: 10 * scale),
        child: Row(
          children: [
            Icon(Icons.music_note_rounded, color: const Color(0xFF7C5CFF), size: 16 * scale),
            SizedBox(width: 6 * scale),
            Expanded(
              child: Text(
                '${widget.overlay.title} • ${widget.overlay.artist}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 11 * scale, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    } else if (layoutStyle == 3) {
      // Circular / CD vinyl style
      cardChild = Column(
        children: [
          Container(
            width: 80 * scale,
            height: 80 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: ClipOval(
              child: Image.network(
                widget.overlay.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade900,
                  child: Icon(Icons.music_note_rounded, color: Colors.white70, size: 30 * scale),
                ),
              ),
            ),
          ),
          SizedBox(height: 6 * scale),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4 * scale),
            ),
            child: Text(
              widget.overlay.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 10 * scale, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    } else {
      // Style 0 (Default vertical card)
      cardChild = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover Art
          Expanded(
            child: Container(
              color: Colors.grey.shade900,
              child: Image.network(
                widget.overlay.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.music_note_rounded,
                  color: Colors.white24,
                  size: 40 * scale,
                ),
              ),
            ),
          ),
          // Text Row
          Container(
            color: const Color(0xA6000000),
            padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 6 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.overlay.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.music_note_rounded, color: Colors.white70, size: 10 * scale),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        widget.overlay.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10 * scale,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Positioned(
      left: posX - (w / 2),
      top: posY - (h / 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: GestureDetector(
          onTap: widget.onTap,
          onPanStart: (details) {
            widget.onTap();
            _dragX = widget.overlay.x * widget.canvasWidth;
            _dragY = widget.overlay.y * widget.canvasHeight;
            setState(() {
              _isDragging = true;
            });
          },
          onPanUpdate: (details) {
            if (_dragX == null || _dragY == null) return;
            _dragX = _dragX! + details.delta.dx;
            _dragY = _dragY! + details.delta.dy;

            final double newX = (_dragX! / widget.canvasWidth).clamp(0.1, 0.9);
            final double newY = (_dragY! / widget.canvasHeight).clamp(0.1, 0.9);
            widget.onUpdate(widget.overlay.copyWith(x: newX, y: newY));
          },
          onPanEnd: (_) {
            setState(() {
              _isDragging = false;
              _dragX = null;
              _dragY = null;
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Music Card Container
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: CustomPaint(
                  painter: showBorder ? DashedBorderPainter(color: Colors.white.withValues(alpha: .7)) : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11 * scale),
                    child: cardChild,
                  ),
                ),
              ),

              // Delete button top-left
              if (showBorder)
                Positioned(
                  top: -10,
                  left: -10,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xE6000000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ),

              // Floating Move Icon at bottom center of the border (except circular style, or show centered)
              if (showBorder)
                Positioned(
                  bottom: -10,
                  left: (w / 2) - 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xE6000000),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Icon(Icons.open_with, color: Colors.white, size: 11),
                  ),
                ),

              // Corner Resize Handles
              if (showBorder) ...[
                // Top Right (NE)
                _buildCornerHandle(
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  left: w - 10,
                  top: -10,
                  w: w,
                  h: h,
                  baseWidth: baseWidth,
                ),
                // Bottom Right (SE)
                _buildCornerHandle(
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  left: w - 10,
                  top: h - 10,
                  w: w,
                  h: h,
                  baseWidth: baseWidth,
                ),
                // Bottom Left (SW)
                _buildCornerHandle(
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  left: -10,
                  top: h - 10,
                  w: w,
                  h: h,
                  baseWidth: baseWidth,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for dashed borders
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5;
    const double dashSpace = 3;

    // Draw top
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }

    // Draw right
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width, startY), Offset(size.width, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }

    // Draw bottom
    startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height), Offset(startX + dashWidth, size.height), paint);
      startX += dashWidth + dashSpace;
    }

    // Draw left
    startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
