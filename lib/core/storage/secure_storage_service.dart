import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('SecureStorage read error: $e');
      await _handleCorruption();
      return null;
    }
  }

  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      debugPrint('SecureStorage readAll error: $e');
      await _handleCorruption();
      return {};
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('SecureStorage write error: $e');
      await _handleCorruption();
      // Retry once after clearing
      try {
        await _storage.write(key: key, value: value);
      } catch (_) {}
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('SecureStorage delete error: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('SecureStorage clear error: $e');
      await _handleCorruption();
    }
  }

  // Deletes the corrupt Windows DPAPI storage file and re-initializes
  Future<void> _handleCorruption() async {
    if (!Platform.isWindows) return;
    try {
      await _storage.deleteAll();
    } catch (_) {
      // If deleteAll also fails, try to delete the file directly
      try {
        final appData = Platform.environment['APPDATA'];
        if (appData != null) {
          final candidates = [
            '$appData\\com.example\\nexus ai\\flutter_secure_storage.dat',
            '$appData\\com.example.nexusai\\flutter_secure_storage.dat',
          ];
          for (final path in candidates) {
            final file = File(path);
            if (await file.exists()) {
              await file.delete();
              debugPrint('Deleted corrupt secure storage file: $path');
            }
          }
        }
      } catch (e) {
        debugPrint('Could not delete corrupt storage file: $e');
      }
    }
  }
}

const secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  wOptions: WindowsOptions(),
);
