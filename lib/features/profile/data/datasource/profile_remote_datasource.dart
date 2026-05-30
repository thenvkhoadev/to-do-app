import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._client);

  final SupabaseClient _client;

  Stream<UserProfileModel?> watchProfile(String userId) {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? null : UserProfileModel.fromJson(rows.first));
  }

  Future<void> updateSettings(
    String userId, {
    String? themeMode,
    bool? notificationsEnabled,
    bool? privacyMode,
  }) async {
    final patch = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (themeMode != null) patch['theme_mode'] = themeMode;
    if (notificationsEnabled != null) {
      patch['notifications_enabled'] = notificationsEnabled;
    }
    if (privacyMode != null) patch['privacy_mode'] = privacyMode;

    await _client.from('users').update(patch).eq('id', userId);
  }

  Future<void> updateProfileInfo(
    String userId, {
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    final patch = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (fullName != null) patch['full_name'] = fullName;
    if (username != null) patch['username'] = username;
    if (bio != null) patch['bio'] = bio;
    if (avatarUrl != null) patch['avatar_url'] = avatarUrl;

    await _client.from('users').update(patch).eq('id', userId);
  }
}
