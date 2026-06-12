import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/notifications/data/datasource/notification_remote_datasource.dart';
import 'package:to_do_app/features/notifications/data/models/notification_model.dart';

final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(ref.watch(supabaseClientProvider));
});

/// Streams real-time notifications for the authenticated user.
final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(notificationRemoteDataSourceProvider).watchNotifications(user.id);
});

/// Derives the count of unread notifications.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.read).length;
});

/// Local state provider to mute/unmute notification UI visual alerts.
final muteNotificationsProvider = StateProvider<bool>((ref) => false);

/// Actions class to handle notification mutation requests.
class NotificationsActions {
  NotificationsActions(this._ref);

  final Ref _ref;

  NotificationRemoteDataSource get _dataSource =>
      _ref.read(notificationRemoteDataSourceProvider);

  String? get _currentUserId =>
      _ref.read(authControllerProvider).valueOrNull?.id;

  /// Marks a single notification as read.
  Future<void> markAsRead(String id) async {
    await _dataSource.markAsRead(id);
  }

  /// Marks all unread notifications for the user as read.
  Future<void> markAllAsRead() async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _dataSource.markAllAsRead(userId);
  }

  /// Clears all read notifications for the current user.
  Future<void> clearReadNotifications() async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _dataSource.clearReadNotifications(userId);
  }

  /// Deletes a single notification.
  Future<void> deleteNotification(String id) async {
    await _dataSource.deleteNotification(id);
  }

  /// Utility method to generate various mock notifications for developer testing.
  Future<void> generateTestNotifications() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final now = DateTime.now();

    final testNotifications = [
      // Today notifications
      NotificationModel(
        id: '',
        userId: userId,
        title: 'Friend Request',
        body: 'John Doe sent you a friend request.',
        type: 'friend_request',
        read: false,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      NotificationModel(
        id: '',
        userId: userId,
        title: 'Task completed',
        body: 'Project Presentation',
        type: 'task_completed',
        read: false,
        xpAmount: 100,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: '',
        userId: userId,
        title: 'You earned 100 XP',
        body: 'Task Completion Reward',
        type: 'xp_earned',
        read: false,
        xpAmount: 100,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      // Yesterday notifications
      NotificationModel(
        id: '',
        userId: userId,
        title: 'Level Up!',
        body: 'You reached Level 20 - Explorer I',
        type: 'level_up',
        read: true,
        level: 20,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      NotificationModel(
        id: '',
        userId: userId,
        title: '7 Day Streak',
        body: 'Consistency maintained',
        type: 'streak',
        read: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
      ),
      // Earlier notifications
      NotificationModel(
        id: '',
        userId: userId,
        title: 'AI Recommendation',
        body: 'Consider refactoring your task list to optimize productivity.',
        type: 'ai',
        read: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      NotificationModel(
        id: '',
        userId: userId,
        title: 'Reminder',
        body: 'Weekly review is due in 3 hours.',
        type: 'reminder',
        read: true,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      NotificationModel(
        id: '',
        userId: userId,
        title: 'Mentioned',
        body: 'Sarah tagged you in a comment.',
        type: 'mention',
        read: true,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      NotificationModel(
        id: '',
        userId: userId,
        title: 'System Alert',
        body: 'Scheduled system maintenance on Sunday.',
        type: 'system',
        read: true,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
    ];

    for (final notif in testNotifications) {
      await _dataSource.insertNotification(notif);
    }
  }
}

final notificationsActionsProvider = Provider<NotificationsActions>((ref) {
  return NotificationsActions(ref);
});
