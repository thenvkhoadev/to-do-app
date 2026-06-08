import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

// ── Option model ──────────────────────────────────────────────────────────────

class FilterOption {
  const FilterOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.count,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final int? count;
}

// ── Main widget ───────────────────────────────────────────────────────────────

class ModernFilterDropdown extends StatefulWidget {
  const ModernFilterDropdown({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.footer,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<FilterOption> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final String? footer;

  @override
  State<ModernFilterDropdown> createState() => _ModernFilterDropdownState();
}

class _ModernFilterDropdownState extends State<ModernFilterDropdown>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  bool _hover = false;
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _closeOverlay();
    _ctrl.dispose();
    super.dispose();
  }

  FilterOption get _selectedOption =>
      widget.options.firstWhere((o) => o.value == widget.selected,
          orElse: () => widget.options.first);

  bool get _isActive => widget.selected != widget.options.first.value;

  void _toggle() => _open ? _close() : _openOverlay();

  void _openOverlay() {
    _overlay = _buildOverlay();
    Overlay.of(context).insert(_overlay!);
    _ctrl.forward();
    setState(() => _open = true);
  }

  void _close() {
    _ctrl.reverse().then((_) {
      _closeOverlay();
      if (mounted) setState(() => _open = false);
    });
  }

  void _closeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _select(String value) {
    widget.onSelected(value);
    _close();
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 6),
              child: Material(
                color: Colors.transparent,
                child: _DropdownPanel(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  options: widget.options,
                  selected: widget.selected,
                  footer: widget.footer,
                  scaleAnim: _scale,
                  opacityAnim: _opacity,
                  onSelect: _select,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opt = _selectedOption;
    final active = _isActive;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? DashboardColors.primary.withValues(alpha: _hover ? .16 : .10)
                  : _hover
                      ? Colors.white.withValues(alpha: .06)
                      : Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active
                    ? DashboardColors.primary.withValues(alpha: _open ? .5 : .35)
                    : _open || _hover
                        ? Colors.white.withValues(alpha: .22)
                        : Colors.white.withValues(alpha: .12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(opt.icon, size: 14, color: opt.color),
                const SizedBox(width: 7),
                Text(
                  '${widget.title}: ',
                  style: TextStyle(
                    color: (active ? opt.color : DashboardColors.onSurface)
                        .withValues(alpha: .75),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  opt.label,
                  style: TextStyle(
                    color: active ? opt.color : DashboardColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(width: 5),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: active ? opt.color : DashboardColors.onSurface,
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

// ── Dropdown panel ────────────────────────────────────────────────────────────

class _DropdownPanel extends StatelessWidget {
  const _DropdownPanel({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.scaleAnim,
    required this.opacityAnim,
    required this.onSelect,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<FilterOption> options;
  final String selected;
  final Animation<double> scaleAnim;
  final Animation<double> opacityAnim;
  final ValueChanged<String> onSelect;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scaleAnim,
      builder: (_, child) => Opacity(
        opacity: opacityAnim.value,
        child: Transform.scale(
          scale: scaleAnim.value,
          alignment: Alignment.topLeft,
          child: child,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 252,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF111B35)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .35),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                decoration: TextDecoration.none,
                fontFamily: 'Inter',
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PanelHeader(title: title, subtitle: subtitle),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: .06),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: options
                            .map((opt) => _DropdownItem(
                                  option: opt,
                                  isSelected: opt.value == selected,
                                  onTap: () => onSelect(opt.value),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (footer != null) ...[
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: .06),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                      child: Text(
                        footer!,
                        style: const TextStyle(
                          color: Color(0x61FFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Panel header ──────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0x80FFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
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
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final FilterOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;
    final opt = widget.option;
    final iconColor = active
        ? DashboardColors.primary
        : const Color(0xFFA7B1D1);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? const Color(0x1F7C5CFF)
                : _hover
                    ? Colors.white.withValues(alpha: .05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? const Color(0x407C5CFF)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                active ? Icons.check_rounded : opt.icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  opt.label,
                  style: TextStyle(
                    color: active ? DashboardColors.primary : Colors.white,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              if (opt.count != null)
                Container(
                  constraints: const BoxConstraints(minWidth: 28),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? DashboardColors.primary.withValues(alpha: .15)
                        : Colors.white.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? DashboardColors.primary.withValues(alpha: .25)
                          : Colors.white.withValues(alpha: .08),
                    ),
                  ),
                  child: Text(
                    '${opt.count}',
                    style: TextStyle(
                      color: active
                          ? DashboardColors.primary
                          : const Color(0xFFA7B1D1),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
