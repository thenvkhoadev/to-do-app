import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/social/data/models/friendship_model.dart';

class SocialRemoteDataSource {
  SocialRemoteDataSource(this._client);

  final SupabaseClient _client;

  Stream<List<Friendship>> watchFriendships(String userId) {
    return _client
        .from('friendships')
        .stream(primaryKey: ['id'])
        .asyncMap((rows) async {
      if (rows.isEmpty) return <Friendship>[];

      final otherUserIds = rows.map((row) {
        final uId = row['user_id'] as String;
        final fId = row['friend_id'] as String;
        return uId == userId ? fId : uId;
      }).toSet().toList();

      if (otherUserIds.isEmpty) return <Friendship>[];

      final usersData = await _client
          .from('users')
          .select()
          .inFilter('id', otherUserIds);

      final profilesMap = {
        for (final row in usersData)
          row['id'].toString(): Map<String, dynamic>.from(row)
      };

      final friendshipsList = <Friendship>[];
      for (final row in rows) {
        final uId = row['user_id'] as String;
        final fId = row['friend_id'] as String;
        final otherId = uId == userId ? fId : uId;

        final otherUserJson = profilesMap[otherId];
        if (otherUserJson == null) continue;

        final enrichedRow = Map<String, dynamic>.from(row);
        if (uId == userId) {
          enrichedRow['receiver'] = otherUserJson;
        } else {
          enrichedRow['sender'] = otherUserJson;
        }

        friendshipsList.add(Friendship.fromJson(enrichedRow, userId));
      }
      return friendshipsList;
    });
  }

  Future<void> sendFriendRequest(String userId, String friendId) async {
    await _client.from('friendships').insert({
      'user_id': userId,
      'friend_id': friendId,
      'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String userId, String friendId) async {
    await _client
        .from('friendships')
        .update({
          'status': 'friends',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)');
  }

  Future<void> deleteFriendship(String userId, String friendId) async {
    await _client
        .from('friendships')
        .delete()
        .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)');
  }

  Future<void> blockUser(String userId, String friendId) async {
    final existing = await _client
        .from('friendships')
        .select()
        .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)')
        .maybeSingle();

    if (existing != null) {
      final id = existing['id'];
      await _client.from('friendships').update({
        'user_id': userId,
        'friend_id': friendId,
        'status': 'blocked',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } else {
      await _client.from('friendships').insert({
        'user_id': userId,
        'friend_id': friendId,
        'status': 'blocked',
      });
    }
  }

  Future<void> unblockUser(String userId, String friendId) async {
    await _client
        .from('friendships')
        .delete()
        .eq('user_id', userId)
        .eq('friend_id', friendId)
        .eq('status', 'blocked');
  }
}
