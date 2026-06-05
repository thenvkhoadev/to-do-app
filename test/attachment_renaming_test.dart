import 'package:flutter_test/flutter_test.dart';
import 'package:diacritic/diacritic.dart';

String sanitizeFileName(String fileName) {
  final parts = fileName.split('.');
  if (parts.length < 2) {
    return removeDiacritics(fileName)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
  final extension = parts.removeLast();
  final name = parts.join('.');
  final normalized = removeDiacritics(name)
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return normalized.isEmpty ? 'file.$extension' : '$normalized.$extension';
}

void main() {
  group('Professional File Upload Sanitizer Tests', () {
    test('Example 1: Mẫu thực tập tốt nghiệp (1).docx', () {
      expect(
        sanitizeFileName('Mẫu thực tập tốt nghiệp (1).docx'),
        equals('mau-thuc-tap-tot-nghiep-1.docx'),
      );
    });

    test('Example 2: Đồ Án Flutter Cuối Kỳ.pdf', () {
      expect(
        sanitizeFileName('Đồ Án Flutter Cuối Kỳ.pdf'),
        equals('do-an-flutter-cuoi-ky.pdf'),
      );
    });

    test('Example 3: Báo cáo thực tập - Final Version.docx', () {
      expect(
        sanitizeFileName('Báo cáo thực tập - Final Version.docx'),
        equals('bao-cao-thuc-tap-final-version.docx'),
      );
    });
  });
}
