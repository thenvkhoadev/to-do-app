import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/streak/data/models/streak_day_model.dart';

class StreakRemoteDataSource {
  StreakRemoteDataSource(this._client);

  final SupabaseClient _client;

  Stream<List<StreakDayModel>> watchStreakDays(String userId) {
    return _client
        .from('user_streak_days')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('active_date', ascending: false)
        .map((rows) => rows.map(StreakDayModel.fromJson).toList());
  }

  Future<void> updateUserStreak(String activityType) async {
    final now = DateTime.now();
    final localDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    await _client.rpc(
      'update_user_streak',
      params: {
        'p_activity_type': activityType,
        'p_client_date': localDateStr,
      },
    );
  }
}
