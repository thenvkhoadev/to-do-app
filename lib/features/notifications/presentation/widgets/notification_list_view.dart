import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/features/notifications/data/models/notification_model.dart';
import 'package:to_do_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:to_do_app/features/notifications/presentation/widgets/notification_item_tile.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class NotificationListView extends ConsumerStatefulWidget {
  const NotificationListView({
    this.onClose,
    this.isFullScreen = false,
    super.key,
  });

  final VoidCallback? onClose;
  final bool isFullScreen;

  @override
  ConsumerState<NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends ConsumerState<NotificationListView> {
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Selected tab values: 'all', 'unread', 'mentions', 'tasks', 'xp', 'system'
  String _selectedTab = 'all';

  // Selected detailed dropdown filter: 'all', 'unread', 'read', 'xp', 'tasks', 'level', 'streak', 'ai', 'system'
  String _selectedFilter = 'all';
  bool _showOptions = false;
  bool _showFilterMenu = false;

  final List<Map<String, String>> _tabs = const [
    {'id': 'all', 'label': 'All'},
    {'id': 'unread', 'label': 'Unread'},
    {'id': 'mentions', 'label': 'Mentions'},
    {'id': 'tasks', 'label': 'Tasks'},
    {'id': 'xp', 'label': 'XP'},
    {'id': 'system', 'label': 'System'},
  ];

  final List<Map<String, String>> _filters = const [
    {'id': 'all', 'label': 'All Notifications'},
    {'id': 'unread', 'label': 'Unread Only'},
    {'id': 'read', 'label': 'Read Only'},
    {'id': 'xp', 'label': 'XP Rewards'},
    {'id': 'tasks', 'label': 'Task Completed'},
    {'id': 'level', 'label': 'Level Ups'},
    {'id': 'streak', 'label': 'Streaks'},
    {'id': 'ai', 'label': 'AI Insights'},
    {'id': 'system', 'label': 'System Alerts'},
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.trim().toLowerCase();
      });
    });
  }

  List<NotificationModel> _filterNotifications(List<NotificationModel> rawList) {
    return rawList.where((notif) {
      // 1. Search Query filter
      if (_searchQuery.isNotEmpty) {
        final titleMatch = notif.title.toLowerCase().contains(_searchQuery);
        final bodyMatch = notif.body.toLowerCase().contains(_searchQuery);
        if (!titleMatch && !bodyMatch) return false;
      }

      // 2. Horizontal Tab Filter
      switch (_selectedTab) {
        case 'unread':
          if (notif.read) return false;
          break;
        case 'mentions':
          if (notif.type != 'mention') return false;
          break;
        case 'tasks':
          if (notif.type != 'task_completed' && notif.type != 'task_assigned') return false;
          break;
        case 'xp':
          if (notif.type != 'xp_earned' && notif.type != 'level_up' && notif.type != 'streak') return false;
          break;
        case 'system':
          if (notif.type != 'system') return false;
          break;
      }

      // 3. Detailed Dropdown Filter
      switch (_selectedFilter) {
        case 'unread':
          if (notif.read) return false;
          break;
        case 'read':
          if (!notif.read) return false;
          break;
        case 'xp':
          if (notif.type != 'xp_earned') return false;
          break;
        case 'tasks':
          if (notif.type != 'task_completed' && notif.type != 'task_assigned') return false;
          break;
        case 'level':
          if (notif.type != 'level_up') return false;
          break;
        case 'streak':
          if (notif.type != 'streak') return false;
          break;
        case 'ai':
          if (notif.type != 'ai') return false;
          break;
        case 'system':
          if (notif.type != 'system') return false;
          break;
      }

      return true;
    }).toList();
  }

  Map<String, List<NotificationModel>> _groupNotifications(List<NotificationModel> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<NotificationModel>> groups = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (final notif in list) {
      final notifDate = DateTime(notif.createdAt.year, notif.createdAt.month, notif.createdAt.day);
      if (notifDate.isAtSameMomentAs(today)) {
        groups['Today']!.add(notif);
      } else if (notifDate.isAtSameMomentAs(yesterday)) {
        groups['Yesterday']!.add(notif);
      } else {
        groups['Earlier']!.add(notif);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(notificationsStreamProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final actions = ref.read(notificationsActionsProvider);
    final isMuted = ref.watch(muteNotificationsProvider);

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    unreadCount > 0 ? 'Notifications ($unreadCount)' : 'Notifications',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showOptions ? Icons.close_rounded : Icons.more_horiz_rounded,
                      color: _showOptions ? DashboardColors.primary : Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _showOptions = !_showOptions;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Live Search input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: TextField(
                  onChanged: _onSearchChanged,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: DashboardColors.onSurfaceVariant),
                    prefixIconConstraints: BoxConstraints(minWidth: 38, minHeight: 40),
                    hintText: 'Search notifications...',
                    hintStyle: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),

            // Live detailed type filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detailed Filter',
                    style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showFilterMenu = !_showFilterMenu;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _filters.firstWhere((f) => f['id'] == _selectedFilter)['label']!,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: DashboardColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Facebook-style tabs / pills
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tabs.length,
                  itemBuilder: (context, index) {
                    final tab = _tabs[index];
                    final isSelected = _selectedTab == tab['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTab = tab['id']!;
                          });
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF1877F2) // Facebook Blue
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(
                              tab['label']!,
                              style: TextStyle(
                                color: isSelected ? Colors.white : DashboardColors.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Scrollable List Content
            Expanded(
              child: stream.when(
                data: (rawList) {
                  final filtered = _filterNotifications(rawList);
                  if (filtered.isEmpty) {
                    return const _EmptyState();
                  }

                  final grouped = _groupNotifications(filtered);

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, gIndex) {
                      final groupName = grouped.keys.elementAt(gIndex);
                      final items = grouped[groupName]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                            child: Text(
                              groupName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ...items.map(
                            (notif) => NotificationItemTile(
                              key: ValueKey('tile-${notif.id}'),
                              notification: notif,
                              onTap: () {
                                if (widget.onClose != null) widget.onClose!();
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const _SkeletonLoader(),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Error loading notifications: $err',
                      style: const TextStyle(color: DashboardColors.error, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Footer (view all notifications)
            if (!widget.isFullScreen) ...[
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
                child: TextButton(
                  onPressed: () {
                    if (widget.onClose != null) widget.onClose!();
                    context.go('/notifications');
                  },
                  child: const Center(
                    child: Text(
                      'View All Notifications',
                      style: TextStyle(
                        color: Color(0xFF1877F2), // Facebook Blue
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_showOptions || _showFilterMenu) ...[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  _showOptions = false;
                  _showFilterMenu = false;
                });
              },
              child: const SizedBox.expand(),
            ),
          ),
        ],
        if (_showOptions)
          Positioned(
            top: 50,
            right: 16,
            width: 220,
            child: _buildOptionsMenu(context, actions, isMuted),
          ),
        if (_showFilterMenu)
          Positioned(
            top: 175,
            right: 16,
            width: 200,
            child: _buildFilterMenu(context),
          ),
      ],
    );
  }

  Widget _buildFilterMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _filters.map((filter) {
          final isSelected = filter['id'] == _selectedFilter;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = filter['id']!;
                  _showFilterMenu = false;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        filter['label']!,
                        style: TextStyle(
                          color: isSelected ? DashboardColors.primary : Colors.white,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_rounded, size: 16, color: DashboardColors.primary),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptionsMenu(BuildContext context, NotificationsActions actions, bool isMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // slate-800
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionsMenuItem(
            icon: Icons.done_all_rounded,
            label: 'Mark all as read',
            onTap: () async {
              setState(() {
                _showOptions = false;
              });
              await actions.markAllAsRead();
            },
          ),
          _buildOptionsMenuItem(
            icon: Icons.delete_sweep_rounded,
            label: 'Clear read notifications',
            onTap: () async {
              setState(() {
                _showOptions = false;
              });
              await actions.clearReadNotifications();
            },
          ),
          _buildOptionsMenuItem(
            icon: isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            label: isMuted ? 'Unmute alerts' : 'Mute alerts',
            onTap: () {
              setState(() {
                _showOptions = false;
              });
              ref.read(muteNotificationsProvider.notifier).state = !isMuted;
            },
          ),
          _buildOptionsMenuItem(
            icon: Icons.build_rounded,
            label: 'Generate Test Data',
            iconColor: Colors.amber,
            textColor: Colors.amber,
            onTap: () async {
              setState(() {
                _showOptions = false;
              });
              await actions.generateTestNotifications();
            },
          ),
          _buildOptionsMenuItem(
            icon: Icons.settings_rounded,
            label: 'Notification settings',
            onTap: () {
              setState(() {
                _showOptions = false;
              });
              if (widget.onClose != null) widget.onClose!();
              context.go('/settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor ?? Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              color: DashboardColors.onSurfaceVariant,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "You're all caught up.",
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLoader extends StatefulWidget {
  const _SkeletonLoader();

  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<_SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: child,
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
