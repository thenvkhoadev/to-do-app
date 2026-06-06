import 'dart:convert';

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
