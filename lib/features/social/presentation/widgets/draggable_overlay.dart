import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dio/dio.dart';
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
    this.onDoubleTap,
    required this.onUpdate,
    required this.onDelete,
  });

  final MusicOverlay overlay;
  final double canvasWidth;
  final double canvasHeight;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
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

  int _currentPosSec = 0;
  Timer? _timer;
  List<Map<String, dynamic>>? _lyrics;

  @override
  void initState() {
    super.initState();
    _currentPosSec = widget.overlay.startTimeSec;
    _loadRealLyrics();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _currentPosSec++;
          if (_currentPosSec >= widget.overlay.startTimeSec + 15) {
            _currentPosSec = widget.overlay.startTimeSec;
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant DraggableMusicOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay.startTimeSec != widget.overlay.startTimeSec) {
      _currentPosSec = widget.overlay.startTimeSec;
    }
    if (oldWidget.overlay.title != widget.overlay.title ||
        oldWidget.overlay.artist != widget.overlay.artist) {
      _loadRealLyrics();
    }
  }

  Future<void> _loadRealLyrics() async {
    final res = await fetchRealLyrics(widget.overlay.title, widget.overlay.artist);
    if (mounted) {
      setState(() {
        _lyrics = res;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    final int layoutStyle = widget.overlay.layoutStyle;

    // Style 6: Only music -> render nothing on canvas
    if (layoutStyle == 6) {
      return const SizedBox.shrink();
    }

    final double posX = widget.overlay.x * widget.canvasWidth;
    final double posY = widget.overlay.y * widget.canvasHeight;
    final double scale = widget.overlay.scale;

    // Dimensions based on chosen style layout
    double baseWidth = 150;
    double baseHeight = 160;

    if (layoutStyle == 1) {
      baseWidth = 180;
      baseHeight = 64;
    } else if (layoutStyle == 2) {
      baseWidth = 180;
      baseHeight = 44;
    } else if (layoutStyle == 3) {
      baseWidth = 100;
      baseHeight = 120;
    } else if (layoutStyle == 4) {
      // Centered scrolling lyrics
      baseWidth = 220;
      baseHeight = 100;
    } else if (layoutStyle == 5) {
      // Typewriter bold lyrics
      baseWidth = 220;
      baseHeight = 60;
    } else if (layoutStyle == 6) {
      // Only music mode card representation in editor
      baseWidth = 110;
      baseHeight = 70;
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
    } else if (layoutStyle == 4) {
      // Centered scrolling lyrics
      final lyrics = _lyrics ?? getLyricsForSong(widget.overlay.title, widget.overlay.artist);
      final relativeSec = _currentPosSec - widget.overlay.startTimeSec;
      int activeIndex = 0;
      for (int i = 0; i < lyrics.length; i++) {
        if (relativeSec >= lyrics[i]['time']) {
          activeIndex = i;
        }
      }
      cardChild = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (offset) {
          final index = activeIndex - 1 + offset;
          final isCurrent = offset == 1;
          if (index < 0 || index >= lyrics.length) {
            return SizedBox(height: (isCurrent ? 24 : 18) * scale);
          }
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 1.0 * scale),
            child: SizedBox(
              height: (isCurrent ? 24 : 18) * scale,
              child: Center(
                child: Text(
                  lyrics[index]['text'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.white30,
                    fontSize: (isCurrent ? 14 : 11) * scale,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          );
        }),
      );
    } else if (layoutStyle == 5) {
      // Typewriter bold lyrics
      final lyrics = _lyrics ?? getLyricsForSong(widget.overlay.title, widget.overlay.artist);
      final relativeSec = _currentPosSec - widget.overlay.startTimeSec;
      int activeIndex = 0;
      for (int i = 0; i < lyrics.length; i++) {
        if (relativeSec >= lyrics[i]['time']) {
          activeIndex = i;
        }
      }
      final currentLine = lyrics[activeIndex]['text'] as String;
      cardChild = Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 12 * scale),
        child: Text(
          currentLine,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.yellowAccent,
            fontSize: 16 * scale,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
          ),
        ),
      );
    } else if (layoutStyle == 6) {
      // Only music mode editor placeholder
      cardChild = const SizedBox.shrink();
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

    const double padding = 20.0;
    final double outerW = w + padding * 2;
    final double outerH = h + padding * 2;

    return Positioned(
      left: posX - (w / 2) - padding,
      top: posY - (h / 2) - padding,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: SizedBox(
          width: outerW,
          height: outerH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Music Card Container with Drag Gestures wrapping only the card
              Positioned(
                left: padding,
                top: padding,
                width: w,
                height: h,
                child: GestureDetector(
                  onTap: widget.onTap,
                  onDoubleTap: widget.onDoubleTap,
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: (layoutStyle == 4 || layoutStyle == 5) ? null : const Color(0xE61A1A1A),
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
                ),
              ),

              // Delete button top-right
              if (showBorder)
                Positioned(
                  top: padding - 10,
                  right: padding - 10,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        debugPrint('Delete button clicked');
                        widget.onDelete();
                      },
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
                  bottom: padding - 10,
                  left: padding + (w / 2) - 10,
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
                // Top Left (NW)
                _buildCornerHandle(
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  left: padding - 10,
                  top: padding - 10,
                  w: w,
                  h: h,
                  baseWidth: baseWidth,
                ),
                // Bottom Right (SE)
                _buildCornerHandle(
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  left: padding + w - 10,
                  top: padding + h - 10,
                  w: w,
                  h: h,
                  baseWidth: baseWidth,
                ),
                // Bottom Left (SW)
                _buildCornerHandle(
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  left: padding - 10,
                  top: padding + h - 10,
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

const Map<String, List<Map<String, dynamic>>> mockLyricsMap = {
  'duyên âm': [
    {'time': 0, 'text': 'Thiên duyên tiền định, em chớ lo phiền'},
    {'time': 3, 'text': 'Gặp nhau là nợ, xa nhau là duyên'},
    {'time': 6, 'text': 'Duyên âm dang dở, ai khóc ai cười'},
    {'time': 9, 'text': 'Thương người đi trước, tiễn người đi sau'},
    {'time': 12, 'text': 'Đời này có duyên, gặp nhau lần nữa'},
    {'time': 15, 'text': 'Thiên duyên tiền định, em chớ lo phiền'},
  ],
  'son tung': [
    {'time': 0, 'text': 'Chúng ta không thuộc về nhau'},
    {'time': 3, 'text': 'Mọi duyên tình nay cũng đã phai màu'},
    {'time': 6, 'text': 'Hãy xóa đi những ký ức ngày hôm qua'},
    {'time': 9, 'text': 'Để cả hai được tự do cất bước rời xa'},
    {'time': 12, 'text': 'Chúng ta không thuộc về nhau'},
    {'time': 15, 'text': 'Chúng ta không thuộc về nhau'},
  ],
  'ngot': [
    {'time': 0, 'text': 'Em dạo này có còn đi xem xiếc thú?'},
    {'time': 3, 'text': 'Có còn mua trà sữa mỗi chiều thứ tư?'},
    {'time': 6, 'text': 'Anh dạo này cũng khác đi nhiều lắm'},
    {'time': 9, 'text': 'Chỉ có nỗi nhớ em vẫn nguyên vẹn sâu thẳm'},
    {'time': 12, 'text': 'Em dạo này thế nào rồi?'},
    {'time': 15, 'text': 'Có còn đi xem xiếc thú không?'},
  ],
};

List<Map<String, dynamic>> getLyricsForSong(String title, String artist) {
  final cleanTitle = title.toLowerCase().trim();
  for (final entry in mockLyricsMap.entries) {
    if (cleanTitle.contains(entry.key)) {
      return entry.value;
    }
  }
  
  // Generic fallback lyrics based on title and artist
  return [
    {'time': 0, 'text': '🎵 Đang phát: $title'},
    {'time': 3, 'text': '🎤 Ca sĩ: $artist'},
    {'time': 6, 'text': '✨ Giai điệu tuyệt vời từ Story Music'},
    {'time': 9, 'text': '💖 Đang sẻ chia cảm xúc cùng mọi người'},
    {'time': 12, 'text': '🌟 Thưởng thức bản nhạc này thôi nào!'},
    {'time': 15, 'text': '🎵 Đang phát: $title'},
  ];
}

String cleanSearchTerm(String term) {
  String cleaned = term.replaceAll(RegExp(r'\([^)]*\)'), '');
  cleaned = cleaned.replaceAll(RegExp(r'\[[^\]]*\]'), '');
  cleaned = cleaned.replaceAll(RegExp(r'\b(feat\.|ft\.|remix|official|lyric|video|audio)\b', caseSensitive: false), '');
  cleaned = cleaned.replaceAll(RegExp(r'\s*-\s*'), ' ');
  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
  return cleaned.trim();
}

final Map<String, List<Map<String, dynamic>>> _lyricsCache = {};

Future<List<Map<String, dynamic>>> fetchRealLyrics(String title, String artist) async {
  final cacheKey = '${title.toLowerCase().trim()} - ${artist.toLowerCase().trim()}';
  if (_lyricsCache.containsKey(cacheKey)) {
    return _lyricsCache[cacheKey]!;
  }

  try {
    final dio = Dio();
    final cleanTitle = cleanSearchTerm(title);
    final cleanArtist = cleanSearchTerm(artist);

    final response = await dio.get(
      'https://lrclib.net/api/lookup',
      queryParameters: {
        'artist_name': cleanArtist.isNotEmpty ? cleanArtist : artist,
        'track_name': cleanTitle.isNotEmpty ? cleanTitle : title,
      },
      options: Options(
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final syncedLyrics = response.data['syncedLyrics'] as String?;
      if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
        final lines = syncedLyrics.split('\n');
        final List<Map<String, dynamic>> parsed = [];
        for (final line in lines) {
          final regExp = RegExp(r'\[(\d+):(\d+)\.(\d+)\](.*)');
          final match = regExp.firstMatch(line);
          if (match != null) {
            final min = int.parse(match.group(1)!);
            final sec = int.parse(match.group(2)!);
            final text = match.group(4)!.trim();
            if (text.isNotEmpty) {
              parsed.add({
                'time': min * 60 + sec,
                'text': text,
              });
            }
          }
        }
        if (parsed.isNotEmpty) {
          _lyricsCache[cacheKey] = parsed;
          return parsed;
        }
      }

      final plainLyrics = response.data['plainLyrics'] as String?;
      if (plainLyrics != null && plainLyrics.isNotEmpty) {
        final lines = plainLyrics.split('\n').where((l) => l.trim().isNotEmpty).toList();
        final List<Map<String, dynamic>> parsed = [];
        for (int i = 0; i < lines.length; i++) {
          parsed.add({
            'time': (i * 2.5).toInt(),
            'text': lines[i].trim(),
          });
        }
        if (parsed.isNotEmpty) {
          _lyricsCache[cacheKey] = parsed;
          return parsed;
        }
      }
    }
  } catch (e) {
    debugPrint('Error fetching real lyrics from LRCLIB: $e');
  }

  final localFallback = getLyricsForSong(title, artist);
  _lyricsCache[cacheKey] = localFallback;
  return localFallback;
}
