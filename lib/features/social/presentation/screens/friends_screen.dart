import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/features/social/presentation/widgets/user_card.dart';
import 'package:to_do_app/features/social/presentation/screens/friend_profile_screen.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  UserProfileModel? _selectedProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedProfile != null) {
      return FriendProfileScreen(
        profile: _selectedProfile!,
        onBack: () => setState(() => _selectedProfile = null),
      );
    }

    final friends = ref.watch(friendsListProvider);
    final pending = ref.watch(pendingRequestsProvider);
    final suggestions = ref.watch(suggestedFriendsProvider);
    final searchedUsersAsync = ref.watch(searchedUsersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const DesktopTopbar(),
          // Tabs header
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: DashboardColors.primary,
                labelColor: DashboardColors.primary,
                unselectedLabelColor: DashboardColors.outline,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Bạn bè'),
                  Tab(text: 'Lời mời'),
                  Tab(text: 'Gợi ý'),
                  Tab(text: 'Tìm bạn'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Friends List Tab
                _buildFriendsTab(friends),
                // Friend Requests Tab
                _buildRequestsTab(pending),
                // Suggested Friends Tab
                _buildSuggestionsTab(suggestions),
                // Find Friends (Search) Tab
                _buildSearchTab(searchedUsersAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(List<UserProfileModel> friends) {
    if (friends.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'Chưa có bạn bè',
        subtitle:
            'Hãy tìm kiếm và kết nối với những người khác để chia sẻ hoạt động và cùng nhau tiến bộ.',
        actionLabel: 'Tìm bạn bè ngay',
        onAction: () => _tabController.animateTo(3),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.76,
      ),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return UserCard(
          user: friend,
          onTap: () => setState(() => _selectedProfile = friend),
        );
      },
    );
  }

  Widget _buildRequestsTab(PendingRequests pending) {
    if (pending.received.isEmpty && pending.sent.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mail_outline_rounded,
        title: 'Hộp thư trống',
        subtitle: 'Bạn không có lời mời kết bạn nào đang chờ xử lý.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (pending.received.isNotEmpty) ...[
          const Text(
            'Lời mời đã nhận',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.76,
            ),
            itemCount: pending.received.length,
            itemBuilder: (context, index) {
              final req = pending.received[index];
              return UserCard(
                user: req.otherUser,
                onTap: () => setState(() => _selectedProfile = req.otherUser),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
        if (pending.sent.isNotEmpty) ...[
          const Text(
            'Lời mời đã gửi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.76,
            ),
            itemCount: pending.sent.length,
            itemBuilder: (context, index) {
              final req = pending.sent[index];
              return UserCard(
                user: req.otherUser,
                onTap: () => setState(() => _selectedProfile = req.otherUser),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionsTab(List<UserProfileModel> suggestions) {
    if (suggestions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'Không có gợi ý',
        subtitle: 'Chưa tìm thấy người dùng phù hợp với kỹ năng của bạn.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.76,
      ),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final sugg = suggestions[index];
        return UserCard(
          user: sugg,
          onTap: () => setState(() => _selectedProfile = sugg),
        );
      },
    );
  }

  Widget _buildSearchTab(AsyncValue<List<UserProfileModel>> searchedUsersAsync) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: DashboardColors.surfaceLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .06)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                icon: Icon(Icons.search_rounded, color: DashboardColors.outline),
                hintText: 'Tìm kiếm theo tên, username hoặc email...',
                hintStyle: TextStyle(color: DashboardColors.outline),
                border: InputBorder.none,
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: DashboardColors.outline,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(userSearchQueryProvider.notifier).state =
                                '';
                          },
                        )
                        : null,
              ),
              style: const TextStyle(color: DashboardColors.onSurface),
              onChanged: (val) {
                ref.read(userSearchQueryProvider.notifier).state = val;
                setState(() {});
              },
            ),
          ),
        ),
        Expanded(
          child: searchedUsersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Không tìm thấy kết quả',
                  subtitle:
                      'Thử thay đổi từ khoá tìm kiếm của bạn để có kết quả tốt hơn.',
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.76,
                ),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return UserCard(
                    user: user,
                    onTap: () => setState(() => _selectedProfile = user),
                  );
                },
              );
            },
            loading:
                () => const Center(
                  child: CircularProgressIndicator(
                    color: DashboardColors.primary,
                  ),
                ),
            error:
                (e, _) => Center(
                  child: Text(
                    'Đã xảy ra lỗi: $e',
                    style: const TextStyle(color: DashboardColors.error),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: DashboardColors.outline),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DashboardColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DashboardColors.outline,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                GradientButton(label: actionLabel, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
