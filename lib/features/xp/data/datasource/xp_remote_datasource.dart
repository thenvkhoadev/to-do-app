import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/xp/data/models/xp_log_model.dart';
import 'package:to_do_app/features/xp/domain/xp_leveling.dart';

class XpRemoteDataSource {
  XpRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Stream of xp_logs for [userId], newest first. Reacts to realtime inserts.
  Stream<List<XpLogModel>> watchXpLogs(String userId) {
    return _client
        .from('xp_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => XpLogModel.fromJson(r)).toList());
  }

  /// One-shot fetch of the most recent [limit] xp_logs for [userId].
  Future<List<XpLogModel>> fetchXpLogs(String userId, {int limit = 50}) async {
    final data = await _client
        .from('xp_logs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((r) => XpLogModel.fromJson(r)).toList();
  }

  /// XP earned today for [userId].
  Future<int> fetchXpToday(String userId) async {
    final start = DateTime.now().toUtc().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    final data = await _client
        .from('xp_logs')
        .select('xp_gained')
        .eq('user_id', userId)
        .gte('created_at', start.toIso8601String());
    return (data as List).fold<int>(
      0,
      (sum, r) => sum + (r['xp_gained'] as int? ?? 0),
    );
  }

  /// XP earned this week (last 7 days) for [userId].
  Future<int> fetchXpThisWeek(String userId) async {
    final start = DateTime.now().toUtc().subtract(const Duration(days: 7));
    final data = await _client
        .from('xp_logs')
        .select('xp_gained')
        .eq('user_id', userId)
        .gte('created_at', start.toIso8601String());
    return (data as List).fold<int>(
      0,
      (sum, r) => sum + (r['xp_gained'] as int? ?? 0),
    );
  }

  /// XP earned this month (last 30 days) for [userId].
  Future<int> fetchXpThisMonth(String userId) async {
    final start = DateTime.now().toUtc().subtract(const Duration(days: 30));
    final data = await _client
        .from('xp_logs')
        .select('xp_gained')
        .eq('user_id', userId)
        .gte('created_at', start.toIso8601String());
    return (data as List).fold<int>(
      0,
      (sum, r) => sum + (r['xp_gained'] as int? ?? 0),
    );
  }

  /// Insert an XP log entry and update users.total_xp + current_xp directly.
  /// Used for actions without a DB trigger (task creation = 2 XP, subtask done = 5 XP).
  Future<void> awardXp({
    required String userId,
    String? taskId,
    required int xpGained,
    required String reason,
  }) async {
    // Insert log — trg_update_user_level fires and recalculates level
    await _client.from('xp_logs').insert({
      'user_id': userId,
      if (taskId != null) 'task_id': taskId,
      'xp_gained': xpGained,
      'reason': reason,
    });
    // Fetch current XP then increment (no trigger covers total_xp for these actions)
    final row =
        await _client
            .from('users')
            .select('total_xp')
            .eq('id', userId)
            .single();
    final newTotal = (row['total_xp'] as int? ?? 0) + xpGained;
    final levelState = xpProgressFromTotalXp(newTotal);
    final rankState = xpRankForLevel(levelState.level);
    await _client
        .from('users')
        .update({
          'total_xp': newTotal,
          'current_xp': levelState.xpIntoLevel,
          'level': levelState.level,
          'next_level_xp': levelState.nextLevelXp,
          'rank_name': rankState.name,
          'rank_division': rankState.division,
          'rank_title': rankState.title,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Deduct XP when a subtask is unchecked. Deletes the matching xp_log,
  /// decrements total_xp/current_xp, recalculates level.
  /// Returns the old level so caller can detect level-down.
  Future<int> deductXp({
    required String userId,
    required String taskId,
    required int xpToDeduct,
    required String reason,
  }) async {
    // Remove the most recent matching log for this task+reason
    final logs = await _client
        .from('xp_logs')
        .select('id')
        .eq('user_id', userId)
        .eq('task_id', taskId)
        .eq('reason', reason)
        .order('created_at', ascending: false)
        .limit(1);
    if ((logs as List).isNotEmpty) {
      await _client.from('xp_logs').delete().eq('id', logs.first['id']);
    }
    // Fetch current values
    final row =
        await _client
            .from('users')
            .select('total_xp, current_xp, level')
            .eq('id', userId)
            .single();
    final oldLevel = row['level'] as int? ?? row['llevel'] as int? ?? 1;
    final newTotal = ((row['total_xp'] as int? ?? 0) - xpToDeduct).clamp(
      0,
      999999,
    );
    final levelState = xpProgressFromTotalXp(newTotal);
    final rankState = xpRankForLevel(levelState.level);
    await _client
        .from('users')
        .update({
          'total_xp': newTotal,
          'current_xp': levelState.xpIntoLevel,
          'level': levelState.level,
          'next_level_xp': levelState.nextLevelXp,
          'rank_name': rankState.name,
          'rank_division': rankState.division,
          'rank_title': rankState.title,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);
    return oldLevel;
  }
}
