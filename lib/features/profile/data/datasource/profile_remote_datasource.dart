import 'package:flutter/foundation.dart';
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
        .asyncMap((rows) async {
      if (rows.isEmpty) return null;
      final userData = Map<String, dynamic>.from(rows.first);
      // Normalise llevel → level in case DB has the typo column name
      if (!userData.containsKey('level')) {
        userData['level'] = userData['llevel'] ?? 1;
      }
      try {
        final prefsRes = await _client
            .from('user_preferences')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        userData['user_preferences'] = prefsRes;
      } catch (_) {}
      return UserProfileModel.fromJson(userData);
    });
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

  Future<void> updateShowcaseAchievement(
    String userId,
    String achievementId,
  ) async {
    await _client.from('users').update({
      'showcase_achievement_id': achievementId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateShowcaseAchievements(
    String userId,
    List<String> achievementIds,
  ) async {
    await _client.from('users').update({
      'showcase_achievement_ids': achievementIds,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateProfileInfo(
    String userId, {
    String? fullName,
    String? username,
    String? bio,
    String? occupation,
    String? avatarUrl,
    String? coverUrl,
    List<String>? coreTech,
    String? locationNode,
    String? preferredTimezone,
  }) async {
    final patch = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (fullName != null) patch['full_name'] = fullName;
    if (username != null) patch['username'] = username;
    if (bio != null) patch['bio'] = bio;
    if (occupation != null) patch['occupation'] = occupation;
    if (avatarUrl != null) patch['avatar_url'] = avatarUrl;
    if (coverUrl != null) patch['cover_url'] = coverUrl;
    if (coreTech != null) patch['core_tech'] = coreTech;

    await _client.from('users').update(patch).eq('id', userId);

    if (locationNode != null || preferredTimezone != null) {
      final prefsPatch = <String, dynamic>{
        'user_id': userId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (locationNode != null) prefsPatch['location_node'] = locationNode;
      if (preferredTimezone != null) prefsPatch['preferred_timezone'] = preferredTimezone;

      // Upsert preferences
      await _client.from('user_preferences').upsert(
        prefsPatch,
        onConflict: 'user_id',
      );
    }
  }

  Future<String?> uploadAvatar(String userId, Uint8List fileBytes, {String? fileName}) async {
    try {
      final name = fileName ?? 'avatar_$userId${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$name';

      await _client.storage.from('avatars').uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final imageUrl = _client.storage.from('avatars').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      throw Exception(e.toString());
    }
  }

  Future<String?> uploadCoverPhoto(String userId, Uint8List fileBytes, {String? fileName}) async {
    try {
      final name = fileName ?? 'cover_$userId${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$name';

      await _client.storage.from('covers').uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final imageUrl = _client.storage.from('covers').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading cover photo: $e');
      throw Exception(e.toString());
    }
  }
}
