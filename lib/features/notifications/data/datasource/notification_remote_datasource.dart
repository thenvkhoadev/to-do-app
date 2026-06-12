import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/notifications/data/models/notification_model.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Streams real-time notifications for the given [userId], ordered by newest first.
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => NotificationModel.fromJson(r)).toList());
  }

  /// One-shot fetch of the most recent notifications for the given [userId].
  Future<List<NotificationModel>> fetchNotifications(String userId, {int limit = 50}) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((r) => NotificationModel.fromJson(r)).toList();
  }

  /// Marks a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  /// Marks all unread notifications as read.
  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
  }

  /// Clears all read notifications from the database.
  Future<void> clearReadNotifications(String userId) async {
    await _client
        .from('notifications')
        .delete()
        .eq('user_id', userId)
        .eq('read', true);
  }

  /// Deletes a single notification by [notificationId].
  Future<void> deleteNotification(String notificationId) async {
    await _client
        .from('notifications')
        .delete()
        .eq('id', notificationId);
  }

  /// Inserts a notification record. Used to insert client-side notifications (AI, System, Mentions, etc.).
  Future<void> insertNotification(NotificationModel notification) async {
    final json = notification.toJson();
    // Remove ID if empty so database handles gen_random_uuid()
    if (notification.id.isEmpty) {
      json.remove('id');
    }
    await _client.from('notifications').insert(json);
  }
}
