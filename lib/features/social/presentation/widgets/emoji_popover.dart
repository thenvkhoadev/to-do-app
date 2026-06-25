import 'package:flutter/material.dart';

class EmojiPopover extends StatefulWidget {
  const EmojiPopover({
    super.key,
    required this.onEmojiSelected,
    required this.onClose,
    this.arrowOffset = 24.0, // pixels from right side
    this.isArrowTop = false,
  });

  final ValueChanged<String> onEmojiSelected;
  final VoidCallback onClose;
  final double arrowOffset;
  final bool isArrowTop;

  @override
  State<EmojiPopover> createState() => _EmojiPopoverState();
}

class _EmojiPopoverState extends State<EmojiPopover> {
  int _activeCategoryIndex = 0;
  final List<String> _recentEmojis = ['🤣', '🤔', '😢'];

  static const List<Map<String, dynamic>> _categories = [
    {
      'icon': Icons.access_time_rounded,
      'title': 'Đã dùng gần đây',
      'emojis': ['🤣', '🤔', '😢', '👍', '❤️', '🔥', '👏', '😂', '🎉', '🙌'],
    },
    {
      'icon': Icons.sentiment_satisfied_alt_rounded,
      'title': 'Mặt cười và hình người',
      'emojis': [
        '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😇', '😉', '😊', '😋', '😌', '😍', '🥰', '😘',
        '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '😎', '🥸', '🤩', '🥳', '😏', '😒',
        '😞', '😔', '😟', '😕', '🙁', '☹️', '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡',
        '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🫣', '🤗', '🫡', '🤔', '🤭', '🤫',
        '🤥', '😶', '😐', '😑', '😬', '🫨', '🫠', '🙄', '😯', '😦', '😧', '😮', '😲', '🥱', '😴', '🤤',
        '😪', '😮‍💨', '😵', '😵‍💫', '🫥', '🤐', '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '😈', '👿', '👹'
      ],
    },
    {
      'icon': Icons.pets_rounded,
      'title': 'Động vật và thiên nhiên',
      'emojis': [
        '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔',
        '🐧', '🐦', '🦆', '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜',
        '🕷', '🕸', '🦂', '🐢', '🐍', '🦎', '🐙', '🦑', '🦞', '🦀', '🐬', '🐳', '🐋', '🦈', '🐊', '🐅',
        '🐆', '🦓', '🦍', '🦧', '🐘', '🦛', '🦏', '🐪', '🐫', '🦒', '🦘', '🐃', '🐂', '🐄', '🐎', '🐖',
        '🐏', '🐑', '🐐', '🦌', '🐕', '🐈', '🐓', '🦃', ' peacock', 'swan', 'flamingo', 'dove', 'rabbit',
        '🌱', '🌿', '🍀', '🍁', '🍂', '🍃', '🌹', '🌷', '🌸', '🌼', '🌻', '🌞', '🌙', '⭐️', '⚡️', '🔥'
      ],
    },
    {
      'icon': Icons.fastfood_rounded,
      'title': 'Ẩm thực',
      'emojis': [
        '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍒', '🍑', '🥭', '🍍', '🥥', '猕', '🍅',
        '茄', '🥑', '🥦', '🥬', '🥒', '🌶', '🌽', '🥕', '🥔', '🍠', '🥐', '🥯', '🍞', '🥖', '🧀', '🍖',
        '🍗', '🥩', '🥓', '🍔', '🍟', '🍕', '🌭', '🥪', '🌮', '🌯', '🥚', '🍳', '🥘', '🍲', '🥗', ' popcorn',
        ' Bento', '煎饺', '🍨', '🍩', '🍪', '🎂', '🍰', '🍫', '🍬', '🍭', '☕️', '🍵', '🍶', '🍺', '🍻', '🍷'
      ],
    },
    {
      'icon': Icons.sports_soccer_rounded,
      'title': 'Hoạt động',
      'emojis': [
        '⚽️', '🏀', '🏈', '⚾️', '🥎', '🎾', '🏐', '🏉', '🎱', '🪀', '🏓', '🏸', '🏒', '🏑', '🏏', '⛳️',
        '🏹', '🎣', '🥊', '🥋', '🛹', '🛼', '🏋️', '🤸', '🧗', '🚴', '🚵', '🏆', '🥇', '🥈', '🥉', '🏅',
        '🎗', '🎫', '🎟', '🎪', '🤹', '🎭', '🎨', '🎬', '🎤', '🎧', '🎼', '🎹', '🥁', '🎷', '🎺', '🎸'
      ],
    },
    {
      'icon': Icons.beach_access_rounded,
      'title': 'Du lịch và địa điểm',
      'emojis': [
        '🚗', '🚕', '🚙', '🚌', '🏎', '🚓', '🚑', '🚒', '🚐', '🚚', '🚜', '🛵', '🚲', '🛴', '🚋', '🚄',
        '🚂', '✈️', '🛫', '🛬', '🚀', '🛸', '⛵️', '🚢', '⚓️', '🗺', '🗿', '🗽', '🗼', '🏰', '🏯', '🎡',
        '🎢', '🎠', '⛱', '🏖', 'Is', '🏜', '🌋', '⛰', '🏕', '⛺️', '🏠', '🏡', '🏢', '🏥', '🏦', '🏨'
      ],
    },
    {
      'icon': Icons.lightbulb_outline_rounded,
      'title': 'Đồ vật',
      'emojis': [
        '⌚️', '📱', '💻', 'keyboard', '🖱', '🖨', '☎️', '📺', '📻', '🎙', '🧭', '⏰', '⌛️', '⏳', '💡',
        'flashlight', '🕯', '💵', '💴', '💶', '💷', '💳', '💎', '⚖️', '🔧', '🔨', '⚒', '⛏', '🪓', '⚙️',
        '⛓', '🔫', '💣', '🛡', '🚬', '⚰️', '🔮', '🧿', '💈', '🔭', '🔬', '🩹', '💊', '💉', '🧹', '🔑'
      ],
    },
    {
      'icon': Icons.alternate_email_rounded,
      'title': 'Biểu tượng',
      'emojis': [
        '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
        '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉', '☯️', '☸️', '♈️', '♉️', '♊️', '♋️', '♌️', '♍️', '♎️',
        '♏️', '♐️', '♑️', '♒️', '♓️', '🆘', '❌', '⭕️', '🚫', '💯', '🚾', '⚠️', '🌐', '💤', '🌀', '🔔'
      ],
    },
    {
      'icon': Icons.flag_rounded,
      'title': 'Lá cờ',
      'emojis': [
        '🏁', '🚩', '🏳️', '🏳️‍🌈', '🏴‍☠️', '🇻🇳', '🇺🇸', '🇯🇵', '🇰🇷', '🇨🇳', '🇬🇧', '🇫🇷', '🇩🇪', '🇷🇺', '🇨🇦', '🇦🇺',
        '🇸🇬', '🇹🇭', '🇮🇩', '🇲🇾', '🇵🇭', '🇰🇭', '🇱🇦', '🇲🇲', '🇮🇳', '🇧🇷', '🇪🇸', '🇮🇹', '🇨🇭', '🇳🇱', '🇸🇪', '🇿🇦'
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeTitle = _categories[_activeCategoryIndex]['title'] as String;
    final List<String> emojis = List<String>.from(_categories[_activeCategoryIndex]['emojis'] as List);

    final arrow = Padding(
      padding: EdgeInsets.only(right: widget.arrowOffset),
      child: CustomPaint(
        size: const Size(16, 8),
        painter: _TrianglePainter(
          color: const Color(0xFF242526),
          pointingUp: widget.isArrowTop,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.isArrowTop) arrow,
        // Content Card
        Container(
          width: 320,
          height: 340,
          decoration: BoxDecoration(
            color: const Color(0xFF242526),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activeTitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: widget.onClose,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.close_rounded, size: 16, color: Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Recent Emojis (Always show recent row if not on the recent tab itself or show it anyway)
              if (_activeCategoryIndex != 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đã dùng gần đây',
                        style: TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: _recentEmojis.map((emoji) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onEmojiSelected(emoji),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Text(emoji, style: const TextStyle(fontSize: 22)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
              ],

              // Emojis Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: emojis.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemBuilder: (context, index) {
                    final emoji = emojis[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onEmojiSelected(emoji),
                        borderRadius: BorderRadius.circular(6),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(color: Colors.white10, height: 1),

              // Category Selector Tabs
              Container(
                height: 42,
                color: const Color(0xFF1C1D1E),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = index == _activeCategoryIndex;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _activeCategoryIndex = index;
                          });
                        },
                        child: Container(
                          width: 320 / 7.5, // dynamically size slightly
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected ? const Color(0xFF1877F2) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            size: 18,
                            color: isSelected ? const Color(0xFF1877F2) : Colors.white38,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (!widget.isArrowTop) arrow,
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.color, this.pointingUp = false});

  final Color color;
  final bool pointingUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (pointingUp) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointingUp != pointingUp;
}
