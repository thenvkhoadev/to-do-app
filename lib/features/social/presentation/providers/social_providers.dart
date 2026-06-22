import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/social/data/datasources/social_remote_datasource.dart';
import 'package:to_do_app/features/social/data/models/friendship_model.dart';

final socialRemoteDataSourceProvider = Provider<SocialRemoteDataSource>((ref) {
  return SocialRemoteDataSource(ref.watch(supabaseClientProvider));
});

final friendshipsStreamProvider = StreamProvider<List<Friendship>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(socialRemoteDataSourceProvider).watchFriendships(user.id);
});

final friendsListProvider = Provider<List<UserProfileModel>>((ref) {
  final friendships = ref.watch(friendshipsStreamProvider).valueOrNull ?? [];
  return friendships
      .where((f) => f.status == FriendshipStatus.friends)
      .map((f) => f.otherUser)
      .toList();
});

class PendingRequests {
  final List<Friendship> received;
  final List<Friendship> sent;
  const PendingRequests({required this.received, required this.sent});
}

final pendingRequestsProvider = Provider<PendingRequests>((ref) {
  final friendships = ref.watch(friendshipsStreamProvider).valueOrNull ?? [];
  final received =
      friendships.where((f) => f.status == FriendshipStatus.pendingReceived).toList();
  final sent =
      friendships.where((f) => f.status == FriendshipStatus.pendingSent).toList();
  return PendingRequests(received: received, sent: sent);
});

final userSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedUsersProvider = FutureProvider<List<UserProfileModel>>((ref) async {
  final query = ref.watch(userSearchQueryProvider).trim().toLowerCase();
  final allUsers = ref.watch(allUsersProvider).valueOrNull ?? [];
  final currentUser = ref.watch(authControllerProvider).valueOrNull;

  if (currentUser == null) return [];
  if (query.isEmpty) {
    return allUsers.where((u) => u.id != currentUser.id).toList();
  }

  return allUsers.where((user) {
    if (user.id == currentUser.id) return false;
    final fullName = (user.fullName ?? '').toLowerCase();
    final username = (user.username ?? '').toLowerCase();
    final email = user.email.toLowerCase();
    return fullName.contains(query) ||
        username.contains(query) ||
        email.contains(query);
  }).toList();
});

final friendshipStatusProvider =
    Provider.family<FriendshipStatus, String>((ref, otherUserId) {
  final friendships = ref.watch(friendshipsStreamProvider).valueOrNull ?? [];
  final match = friendships.where((f) => f.otherUser.id == otherUserId);
  if (match.isEmpty) return FriendshipStatus.none;
  return match.first.status;
});

final socialActionLoadingProvider =
    StateProvider<Map<String, bool>>((ref) => {});

final suggestedFriendsProvider = Provider<List<UserProfileModel>>((ref) {
  final allUsers = ref.watch(allUsersProvider).valueOrNull ?? [];
  final myProfile = ref.watch(userProfileProvider).valueOrNull;
  final friendships = ref.watch(friendshipsStreamProvider).valueOrNull ?? [];
  final currentUser = ref.watch(authControllerProvider).valueOrNull;

  if (currentUser == null || myProfile == null) return [];

  final relatedUserIds = friendships.map((f) => f.otherUser.id).toSet();
  relatedUserIds.add(currentUser.id);

  final mySkills =
      myProfile.coreTech.map((s) => s.toLowerCase().trim()).toSet();

  final suggestions = <UserProfileModel>[];
  for (final user in allUsers) {
    if (relatedUserIds.contains(user.id)) continue;

    final userSkills =
        user.coreTech.map((s) => s.toLowerCase().trim()).toSet();
    final intersection = mySkills.intersection(userSkills);
    if (intersection.isNotEmpty) {
      suggestions.add(user);
    }
  }

  if (suggestions.isEmpty) {
    return allUsers
        .where((u) => !relatedUserIds.contains(u.id))
        .take(5)
        .toList();
  }

  return suggestions;
});
