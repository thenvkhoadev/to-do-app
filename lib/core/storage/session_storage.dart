import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/core/constants/app_constants.dart';
import 'package:to_do_app/core/storage/secure_storage_service.dart';

class SessionStorage {
  SessionStorage(this._storage);

  final SecureStorageService _storage;

  Future<void> saveSession(Session session) async {
    await _storage.write(AppConstants.accessTokenKey, session.accessToken);
    await _storage.write(
      AppConstants.refreshTokenKey,
      session.refreshToken ?? '',
    );
    await _storage.write(
      AppConstants.tokenExpiryKey,
      '${session.expiresAt ?? 0}',
    );
    await _storage.write(AppConstants.userIdKey, session.user.id);
  }

  Future<String?> readAccessToken() =>
      _storage.read(AppConstants.accessTokenKey);

  Future<void> clearSession() async {
    await _storage.delete(AppConstants.accessTokenKey);
    await _storage.delete(AppConstants.refreshTokenKey);
    await _storage.delete(AppConstants.tokenExpiryKey);
    await _storage.delete(AppConstants.userIdKey);
  }
}
