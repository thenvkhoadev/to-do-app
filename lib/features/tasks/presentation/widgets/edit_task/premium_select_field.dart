import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class PremiumSelectItem {
  const PremiumSelectItem({
    required this.value,
    required this.label,
    required this.color,
    this.icon,
    this.iconText,
  });

  final String value;
  final String label;
  final Color color;
  final IconData? icon;
  final String? iconText;
}

// ── Trigger button ────────────────────────────────────────────────────────────

class PremiumSelectField extends StatefulWidget {
  const PremiumSelectField({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.sectionHeader,
    this.hint = 'Select...',
    this.searchable = false,
    super.key,
  });

  final List<PremiumSelectItem> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String sectionHeader;
  final String hint;
  final bool searchable;

  @override
  State<PremiumSelectField> createState() => _PremiumSelectFieldState();
}

class _PremiumSelectFieldState extends State<PremiumSelectField> {
  final _triggerKey = GlobalKey();
  bool _hovered = false;
  OverlayEntry? _overlay;

  PremiumSelectItem? get _selected =>
      widget.items.where((i) => i.value == widget.value).firstOrNull;

  void _open() {
    if (_overlay != null) {
      _close();
      return;
    }
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    _overlay = OverlayEntry(
      builder: (ctx) => _DropdownOverlay(
        triggerOffset: offset,
        triggerSize: size,
        items: widget.items,
        selectedValue: widget.value,
        sectionHeader: widget.sectionHeader,
        searchable: widget.searchable,
        onSelected: (val) {
          _close();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onChanged(val);
          });
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
    final selected = _selected;
    final isOpen = _overlay != null;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          Future.microtask(() {
            if (mounted) setState(() => _hovered = true);
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          Future.microtask(() {
            if (mounted) setState(() => _hovered = false);
          });
        }
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: _triggerKey,
        onTap: _open,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered || isOpen
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.015),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOpen
                  ? DashboardColors.primary.withValues(alpha: 0.5)
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color.fromRGBO(255, 255, 255, 0.08),
              width: isOpen ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selected != null) ...[
                // Glow dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: selected.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: selected.color.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (selected.iconText != null && selected.iconText!.trim().isNotEmpty) ...[
                  Text(selected.iconText!, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                ] else if (selected.icon != null) ...[
                  Icon(selected.icon, size: 15, color: Colors.white.withValues(alpha: 0.55)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    selected.label,
                    style: const TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Text(
                    widget.hint,
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.expand_more_rounded,
                  color: DashboardColors.onSurfaceVariant,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Overlay ───────────────────────────────────────────────────────────────────

class _DropdownOverlay extends StatefulWidget {
  const _DropdownOverlay({
    required this.triggerOffset,
    required this.triggerSize,
    required this.items,
    required this.selectedValue,
    required this.sectionHeader,
    required this.searchable,
    required this.onSelected,
    required this.onDismiss,
  });

  final Offset triggerOffset;
  final Size triggerSize;
  final List<PremiumSelectItem> items;
  final String? selectedValue;
  final String sectionHeader;
  final bool searchable;
  final ValueChanged<String?> onSelected;
  final VoidCallback onDismiss;

  @override
  State<_DropdownOverlay> createState() => _DropdownOverlayState();
}

class _DropdownOverlayState extends State<_DropdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _focusedIndex = -1;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<PremiumSelectItem> get _filtered {
    if (_query.isEmpty) return widget.items;
    return widget.items
        .where((i) => i.label.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  void _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final screenH = MediaQuery.of(context).size.height;
    final spaceBelow = screenH - widget.triggerOffset.dy - widget.triggerSize.height - 8;
    final spaceAbove = widget.triggerOffset.dy - 8;
    final showBelow = spaceBelow >= 200 || spaceBelow >= spaceAbove;
    final menuH = (filtered.length * 52.0 + (widget.searchable ? 58 : 0) + 60).clamp(120.0, 360.0);
    final top = showBelow
        ? widget.triggerOffset.dy + widget.triggerSize.height + 6
        : widget.triggerOffset.dy - menuH - 6;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (e) {
        if (e is! KeyDownEvent) return;
        if (e.logicalKey == LogicalKeyboardKey.escape) { _dismiss(); return; }
        if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() => _focusedIndex = (_focusedIndex + 1).clamp(0, filtered.length - 1));
        } else if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() => _focusedIndex = (_focusedIndex - 1).clamp(0, filtered.length - 1));
        } else if (e.logicalKey == LogicalKeyboardKey.enter && _focusedIndex >= 0) {
          widget.onSelected(filtered[_focusedIndex].value);
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: top,
            left: widget.triggerOffset.dx,
            width: widget.triggerSize.width.clamp(280.0, 360.0),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                alignment: showBelow ? Alignment.topCenter : Alignment.bottomCenter,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF141A28), Color(0xFF0F1523)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF283041)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                            BoxShadow(
                              color: DashboardColors.primary.withValues(alpha: 0.06),
                              blurRadius: 60,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.searchable)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                              child: SizedBox(
                                height: 42,
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (v) => setState(() => _query = v),
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                                    prefixIcon: Icon(Icons.search_rounded, size: 16, color: Colors.white.withValues(alpha: 0.35)),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.04),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                            child: Text(
                              widget.sectionHeader.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          if (filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No results found',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                              ),
                            )
                          else
                            ...filtered.asMap().entries.map((e) => _DropdownItem(
                              item: e.value,
                              isSelected: e.value.value == widget.selectedValue,
                              isFocused: e.key == _focusedIndex,
                              onTap: () => widget.onSelected(e.value.value),
                            )),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dropdown item ─────────────────────────────────────────────────────────────

class _DropdownItem extends StatefulWidget {
  const _DropdownItem({
    required this.item,
    required this.isSelected,
    required this.isFocused,
    required this.onTap,
  });

  final PremiumSelectItem item;
  final bool isSelected;
  final bool isFocused;
  final VoidCallback onTap;

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || widget.isFocused;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          Future.microtask(() {
            if (mounted) setState(() => _hovered = true);
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          Future.microtask(() {
            if (mounted) setState(() => _hovered = false);
          });
        }
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          transform: Matrix4.translationValues(0, active ? -1 : 0, 0),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0x18FFFFFF)
                : active
                    ? const Color(0x14FFFFFF)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: widget.isSelected
                ? Border.all(color: DashboardColors.primary.withValues(alpha: 0.35))
                : active
                    ? Border.all(color: Colors.white.withValues(alpha: 0.06))
                    : null,
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: widget.item.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.item.color.withValues(alpha: active ? 0.7 : 0.4),
                      blurRadius: active ? 12 : 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (widget.item.iconText != null && widget.item.iconText!.trim().isNotEmpty) ...[
                Text(widget.item.iconText!, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
              ] else if (widget.item.icon != null) ...[
                Icon(widget.item.icon, size: 15, color: Colors.white.withValues(alpha: 0.55)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    color: widget.isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(Icons.check_rounded, size: 16, color: DashboardColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
