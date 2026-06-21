import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:win32_registry/win32_registry.dart';

class DeepLinkService {
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();
  static final DeepLinkService _instance = DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  void init() {
    // 1. Đăng ký Registry trên Windows
    _registerWindowsProtocol();

    // 2. Lắng nghe deep link khi ứng dụng đang chạy (hoặc chạy ngầm)
    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });

    // 3. Xử lý deep link khi khởi động ứng dụng lần đầu (Cold Start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleUri(uri);
      }
    });
  }

  void handleUri(Uri uri) => _handleUri(uri);

  void _handleUri(Uri uri) {
    debugPrint('Received Deep Link: $uri');
    if (uri.scheme == 'com.example.to_do_app' &&
        uri.host == 'login-callback') {
      try {
        Supabase.instance.client.auth.getSessionFromUrl(uri);
        debugPrint('Successfully parsed session from deep link URL');
      } catch (e) {
        debugPrint('Error parsing session from deep link: $e');
      }
    }
  }

  void _registerWindowsProtocol() {
    if (!kIsWeb && Platform.isWindows) {
      try {
        final exePath = Platform.resolvedExecutable;
        final protocol = 'com.example.to_do_app';
        final keyPath = 'Software\\Classes\\$protocol';
        
        debugPrint('Registering custom URI protocol on Windows: $protocol');
        final key = Registry.currentUser.createKey(keyPath);
        key.createValue(const RegistryValue.string('', 'URL:com.example.to_do_app Protocol'));
        key.createValue(const RegistryValue.string('URL Protocol', ''));
        
        final commandKey = key.createKey('shell\\open\\command');
        commandKey.createValue(RegistryValue.string('', '"$exePath" "%1"'));
        debugPrint('Registry protocol registered successfully at Command: "$exePath" "%1"');
      } catch (e) {
        debugPrint('Warning: Could not register Windows custom protocol: $e');
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
