import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';

enum FriendshipStatus {
  none,
  pendingSent,
  pendingReceived,
  friends,
  blocked,
}

class Friendship {
  final String id;
  final String userId;
  final String friendId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfileModel otherUser;

  const Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.otherUser,
  });

  factory Friendship.fromJson(Map<String, dynamic> json, String currentUserId) {
    final String userIdVal = json['user_id']?.toString() ?? '';
    final String friendIdVal = json['friend_id']?.toString() ?? '';
    final String dbStatus = json['status']?.toString() ?? 'pending';

    FriendshipStatus resolvedStatus = FriendshipStatus.none;
    if (dbStatus == 'friends') {
      resolvedStatus = FriendshipStatus.friends;
    } else if (dbStatus == 'blocked') {
      resolvedStatus = FriendshipStatus.blocked;
    } else if (dbStatus == 'pending') {
      if (userIdVal == currentUserId) {
        resolvedStatus = FriendshipStatus.pendingSent;
      } else {
        resolvedStatus = FriendshipStatus.pendingReceived;
      }
    }

    final Map<String, dynamic> senderJson = json['sender'] != null
        ? Map<String, dynamic>.from(json['sender'])
        : {};
    final Map<String, dynamic> receiverJson = json['receiver'] != null
        ? Map<String, dynamic>.from(json['receiver'])
        : {};

    UserProfileModel otherUserResolved;
    if (userIdVal == currentUserId) {
      otherUserResolved = UserProfileModel.fromJson(receiverJson);
    } else {
      otherUserResolved = UserProfileModel.fromJson(senderJson);
    }

    return Friendship(
      id: json['id']?.toString() ?? '',
      userId: userIdVal,
      friendId: friendIdVal,
      status: resolvedStatus,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      otherUser: otherUserResolved,
    );
  }
}
