import 'dart:convert';
import 'package:flutter/material.dart';

/// Parses a description string, which may be encoded as a Quill Delta JSON list,
/// and returns its plain-text representation.
String parseDescriptionToPlainText(String? description) {
  if (description == null || description.isEmpty) return '';
  final trimmed = description.trim();
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final item in decoded) {
          if (item is Map && item.containsKey('insert')) {
            final insertVal = item['insert'];
            if (insertVal is String) {
              buffer.write(insertVal);
            }
          }
        }
        return buffer.toString().trim();
      }
    } catch (_) {
      // Fallback to raw string if it's not valid JSON
    }
  }
  return description;
}

/// Builds a rich text widget that renders basic formatting (bold, italic, underline, link, bullet)
/// from a Quill Delta JSON string. Falls back to a normal Text widget if the input is not JSON.
Widget buildRichTextDescription(String? description, TextStyle baseStyle, {int? maxLines}) {
  if (description == null || description.isEmpty) {
    return Text(
      '',
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      style: baseStyle,
    );
  }
  final trimmed = description.trim();
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        // Split ops into lines, each line is a list of inline spans + optional bullet flag
        final lines = <_DeltaLine>[];
        var currentSpans = <InlineSpan>[];
        var currentIsBullet = false;

        for (final op in decoded) {
          if (op is! Map || !op.containsKey('insert')) continue;
          final insertVal = op['insert'];
          if (insertVal is! String) continue;

          final attrs = op['attributes'] as Map?;
          final isBold = attrs != null && attrs['bold'] == true;
          final isItalic = attrs != null && attrs['italic'] == true;
          final isUnderline = attrs != null && attrs['underline'] == true;
          final hasLink = attrs != null && attrs.containsKey('link');
          final isBulletNewline = attrs != null && attrs['list'] == 'bullet';

          // A newline op with list:bullet marks the end of a bullet line
          if (insertVal == '\n') {
            lines.add(_DeltaLine(spans: List.from(currentSpans), isBullet: currentIsBullet || isBulletNewline));
            currentSpans = [];
            currentIsBullet = false;
            continue;
          }

          // Split inline text on newlines to preserve line breaks
          final parts = insertVal.split('\n');
          for (int i = 0; i < parts.length; i++) {
            final part = parts[i];
            if (part.isNotEmpty) {
              currentSpans.add(TextSpan(
                text: part,
                style: baseStyle.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration: TextDecoration.combine([
                    if (isUnderline) TextDecoration.underline,
                    if (hasLink) TextDecoration.underline,
                  ]),
                  color: hasLink ? const Color(0xFF2196F3) : null,
                ),
              ));
            }
            // Each split after the first means a new line
            if (i < parts.length - 1) {
              lines.add(_DeltaLine(spans: List.from(currentSpans), isBullet: currentIsBullet));
              currentSpans = [];
              currentIsBullet = false;
            }
          }
        }

        // Flush remaining spans
        if (currentSpans.isNotEmpty) {
          lines.add(_DeltaLine(spans: currentSpans, isBullet: currentIsBullet));
        }

        // Remove trailing empty lines
        while (lines.isNotEmpty && lines.last.spans.isEmpty) {
          lines.removeLast();
        }

        if (lines.isEmpty) {
          return Text('', style: baseStyle);
        }

        // If maxLines == 1 or only one line, use RichText directly
        if (maxLines == 1 || lines.length == 1) {
          final allSpans = <InlineSpan>[];
          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.isBullet) {
              allSpans.add(TextSpan(text: '• ', style: baseStyle));
            }
            allSpans.addAll(line.spans);
            if (i < lines.length - 1) {
              allSpans.add(TextSpan(text: ' ', style: baseStyle));
            }
          }
          return RichText(
            text: TextSpan(children: allSpans),
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
          );
        }

        // Multi-line: build a Column of RichText rows, respecting maxLines
        final visibleLines = maxLines != null && lines.length > maxLines
            ? lines.sublist(0, maxLines)
            : lines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: visibleLines.map((line) {
            final rowSpans = <InlineSpan>[];
            if (line.isBullet) {
              rowSpans.add(TextSpan(text: '• ', style: baseStyle));
            }
            rowSpans.addAll(line.spans);
            return RichText(
              text: TextSpan(children: rowSpans),
              maxLines: 1,
              overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
            );
          }).toList(),
        );
      }
    } catch (_) {}
  }

  return Text(
    description,
    maxLines: maxLines,
    overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    style: baseStyle,
  );
}

class _DeltaLine {
  const _DeltaLine({required this.spans, required this.isBullet});
  final List<InlineSpan> spans;
  final bool isBullet;
}
