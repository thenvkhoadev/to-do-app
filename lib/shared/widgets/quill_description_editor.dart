import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

/// A reusable rich-text description editor backed by flutter_quill.
/// Saves to Supabase `tasks` table on focus-lost.
class QuillDescriptionEditor extends StatefulWidget {
  const QuillDescriptionEditor({
    required this.taskId,
    required this.initialText,
    this.minHeight = 100,
    this.maxHeight = 300,
    this.showLabel = false,
    super.key,
  });

  final String taskId;
  final String initialText;
  final double minHeight;
  final double maxHeight;
  final bool showLabel;

  @override
  State<QuillDescriptionEditor> createState() =>
      _QuillDescriptionEditorState();
}

class _QuillDescriptionEditorState extends State<QuillDescriptionEditor> {
  late final quill.QuillController _ctrl;
  final FocusNode _focusNode = FocusNode();
  bool _saving = false;
  final Map<String, quill.Attribute> _explicitActive = {};
  int? _lastToggledOffset;

  @override
  void initState() {
    super.initState();
    _ctrl = quill.QuillController(
      document: widget.initialText.trim().isEmpty
          ? quill.Document()
          : _docFromText(widget.initialText),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _ctrl.addListener(_onSelectionChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  quill.Document _docFromText(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return quill.Document.fromJson(decoded);
        }
      } catch (_) {}
    }
    final doc = quill.Document();
    if (trimmed.isNotEmpty) doc.insert(0, trimmed);
    return doc;
  }

  @override
  void didUpdateWidget(QuillDescriptionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskId != widget.taskId) {
      _ctrl.document = widget.initialText.trim().isEmpty
          ? quill.Document()
          : _docFromText(widget.initialText);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onSelectionChanged);
    _focusNode.removeListener(_onFocusChanged);
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) _save();
    setState(() {});
  }

  void _onSelectionChanged() {
    if (!mounted) return;
    final sel = _ctrl.selection;
    if (!sel.isValid) return;
    final offset = sel.start;
    if (sel.isCollapsed) {
      if (_lastToggledOffset != null && offset == _lastToggledOffset) {
        // reapply explicit attrs at cursor
        for (final attr in _explicitActive.values) {
          final style = _ctrl.getSelectionStyle();
          final has = style.containsKey(attr.key) &&
              style.attributes[attr.key]?.value == true;
          if (!has) _ctrl.formatSelection(attr);
        }
      } else {
        _explicitActive.clear();
        _syncActiveFromStyle();
        _lastToggledOffset = offset;
      }
    } else {
      _explicitActive.clear();
      _syncActiveFromStyle();
      _lastToggledOffset = offset;
    }
    setState(() {});
  }

  void _syncActiveFromStyle() {
    final style = _ctrl.getSelectionStyle();
    for (final attr in [quill.Attribute.bold, quill.Attribute.italic]) {
      if (style.containsKey(attr.key) &&
          style.attributes[attr.key]?.value == true) {
        _explicitActive[attr.key] = attr;
      }
    }
  }

  Future<void> _save() async {
    final plain = _ctrl.document.toPlainText().trim();
    if (plain == widget.initialText.trim()) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from('tasks')
          .update({'description': plain.isEmpty ? null : plain})
          .eq('id', widget.taskId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save description: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleFormat(quill.Attribute attr) {
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
    final sel = _ctrl.selection;
    if (!sel.isValid) return;
    _lastToggledOffset = sel.start;

    if (sel.isCollapsed) {
      // expand to word
      final plain = _ctrl.document.toPlainText();
      final cursor = sel.start;
      int start = cursor, end = cursor;
      while (start > 0 && _isWordChar(plain[start - 1])) start--;
      while (end < plain.length && _isWordChar(plain[end])) end++;
      if (start != end) {
        _ctrl.updateSelection(
          TextSelection(baseOffset: start, extentOffset: end),
          quill.ChangeSource.local,
        );
      }
    }

    final style = _ctrl.getSelectionStyle();
    final isActive = style.containsKey(attr.key) &&
        style.attributes[attr.key]?.value == true;
    if (isActive) {
      _explicitActive.remove(attr.key);
      _ctrl.formatSelection(quill.Attribute.clone(attr, null));
    } else {
      _explicitActive[attr.key] = attr;
      _ctrl.formatSelection(attr);
    }
  }

  bool _isWordChar(String c) => RegExp(r'[\wÀ-ɏ]').hasMatch(c);

  Future<void> _insertLink() async {
    final urlCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final sel = _ctrl.selection;
    if (sel.isValid && !sel.isCollapsed) {
      labelCtrl.text =
          _ctrl.document.getPlainText(sel.start, sel.end - sel.start);
    }
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardColors.surfaceLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: DashboardColors.outlineVariant.withValues(alpha: .3)),
        ),
        title: Text('Insert Link',
            style: GoogleFonts.interTight(
                fontWeight: FontWeight.w700,
                color: DashboardColors.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: labelCtrl,
                style: const TextStyle(color: DashboardColors.onSurface),
                decoration: const InputDecoration(labelText: 'Label')),
            const SizedBox(height: 12),
            TextField(
                controller: urlCtrl,
                style: const TextStyle(color: DashboardColors.onSurface),
                decoration: const InputDecoration(
                    labelText: 'URL', hintText: 'https://'),
                keyboardType: TextInputType.url),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style:
                      TextStyle(color: DashboardColors.onSurfaceVariant))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.primaryContainer),
            onPressed: () {
              final url = urlCtrl.text.trim();
              final label = labelCtrl.text.trim();
              if (url.isNotEmpty) {
                final s = _ctrl.selection;
                if (s.isValid && !s.isCollapsed) {
                  _ctrl.formatSelection(quill.LinkAttribute(url));
                } else {
                  final insertText = label.isNotEmpty ? label : url;
                  _ctrl.document
                      .insert(s.isValid ? s.start : 0, insertText);
                  final ns = TextSelection(
                    baseOffset: s.isValid ? s.start : 0,
                    extentOffset:
                        (s.isValid ? s.start : 0) + insertText.length,
                  );
                  _ctrl.updateSelection(ns, quill.ChangeSource.local);
                  _ctrl.formatSelection(quill.LinkAttribute(url));
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Insert',
                style: TextStyle(color: DashboardColors.onPrimary)),
          ),
        ],
      ),
    );
    urlCtrl.dispose();
    labelCtrl.dispose();
  }

  void _insertBullet() {
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
    final style = _ctrl.getSelectionStyle();
    final currentList = style.attributes[quill.Attribute.list.key]?.value;
    if (currentList == 'bullet') {
      _ctrl.formatSelection(quill.Attribute.clone(quill.Attribute.list, null));
    } else {
      _ctrl.formatSelection(const quill.ListAttribute('bullet'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _ctrl.getSelectionStyle();
    final isBold = style.containsKey(quill.Attribute.bold.key) &&
        style.attributes[quill.Attribute.bold.key]?.value == true;
    final isItalic = style.containsKey(quill.Attribute.italic.key) &&
        style.attributes[quill.Attribute.italic.key]?.value == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        Row(
          children: [
            _FormatBtn(
              icon: Icons.format_bold_rounded,
              isSelected: isBold,
              tooltip: 'Bold',
              onTap: () => _toggleFormat(quill.Attribute.bold),
            ),
            const SizedBox(width: 8),
            _FormatBtn(
              icon: Icons.format_italic_rounded,
              isSelected: isItalic,
              tooltip: 'Italic',
              onTap: () => _toggleFormat(quill.Attribute.italic),
            ),
            const SizedBox(width: 8),
            _FormatBtn(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Bullet list',
              onTap: _insertBullet,
            ),
            const SizedBox(width: 8),
            _FormatBtn(
              icon: Icons.link_rounded,
              tooltip: 'Link',
              onTap: _insertLink,
            ),
            const Spacer(),
            if (_saving)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: DashboardColors.surfaceHighest),
        const SizedBox(height: 10),
        // Editor
        quill.QuillEditor.basic(
          controller: _ctrl,
          focusNode: _focusNode,
          config: quill.QuillEditorConfig(
            minHeight: widget.minHeight,
            maxHeight: widget.maxHeight,
            placeholder: 'Add a description...',
            customStyles: quill.DefaultStyles(
              paragraph: quill.DefaultTextBlockStyle(
                GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                  color: DashboardColors.onSurface,
                ),
                quill.HorizontalSpacing.zero,
                quill.VerticalSpacing.zero,
                quill.VerticalSpacing.zero,
                null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormatBtn extends StatefulWidget {
  const _FormatBtn({
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.tooltip = '',
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final String tooltip;

  @override
  State<_FormatBtn> createState() => _FormatBtnState();
}

class _FormatBtnState extends State<_FormatBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? DashboardColors.primary.withValues(alpha: .18)
                  : _hovered
                      ? Colors.white.withValues(alpha: .06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.isSelected
                    ? DashboardColors.primary.withValues(alpha: .4)
                    : Colors.white.withValues(alpha: .06),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: widget.isSelected
                  ? DashboardColors.primary
                  : DashboardColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
