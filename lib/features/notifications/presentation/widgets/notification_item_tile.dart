import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/features/notifications/data/models/notification_model.dart';
import 'package:to_do_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class NotificationItemTile extends ConsumerStatefulWidget {
  const NotificationItemTile({
    required this.notification,
    this.onTap,
    super.key,
  });

  final NotificationModel notification;
  final VoidCallback? onTap;

  @override
  ConsumerState<NotificationItemTile> createState() => _NotificationItemTileState();
}

class _NotificationItemTileState extends ConsumerState<NotificationItemTile> {
  bool _isHovered = false;

  IconData _getIcon() {
    switch (widget.notification.type) {
      case 'task_completed':
        return Icons.task_alt_rounded;
      case 'task_assigned':
        return Icons.assignment_ind_rounded;
      case 'xp_earned':
        return Icons.auto_awesome_rounded;
      case 'level_up':
        return Icons.workspace_premium_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'ai':
        return Icons.psychology_alt_rounded;
      case 'reminder':
        return Icons.alarm_rounded;
      case 'mention':
        return Icons.alternate_email_rounded;
      case 'friend_request':
        return Icons.person_add_rounded;
      case 'system':
      default:
        return Icons.info_outline_rounded;
    }
  }

  LinearGradient _getGradient() {
    switch (widget.notification.type) {
      case 'xp_earned':
        return const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)], // Golden
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'level_up':
        return const LinearGradient(
          colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)], // Purple
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'streak':
        return const LinearGradient(
          colors: [Color(0xFFF87171), Color(0xFFEF4444)], // Red/Orange Glow
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'ai':
        return const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)], // Blue AI
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'task_completed':
      case 'task_assigned':
        return const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF059669)], // Green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'reminder':
        return const LinearGradient(
          colors: [Color(0xFFF472B6), Color(0xFFEC4899)], // Pink
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'mention':
        return const LinearGradient(
          colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)], // Teal
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF9CA3AF), Color(0xFF4B5563)], // Grey
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, h:mm a').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final actions = ref.read(notificationsActionsProvider);

    // Styling helpers
    final unreadBg = Colors.white.withValues(alpha: 0.05);
    final readBg = Colors.transparent;
    final activeBg = _isHovered 
        ? Colors.white.withValues(alpha: 0.09) 
        : (n.read ? readBg : unreadBg);

    // Build quick actions row if applicable
    Widget? quickActions;
    if (!n.read) {
      if (n.type == 'task_completed' || n.type == 'task_assigned') {
        quickActions = Row(
          children: [
            _QuickActionButton(
              label: 'Open Task',
              onPressed: () {
                actions.markAsRead(n.id);
                if (n.taskId != null && n.taskId!.isNotEmpty) {
                  final scope = ProfileNavigationScope.maybeOf(context);
                  if (scope != null) {
                    scope.onTaskSelected?.call(n.taskId!);
                  } else {
                    context.go('/task-detail/${n.taskId}');
                  }
                }
              },
            ),
            const SizedBox(width: 8),
            _QuickActionButton(
              label: 'View Details',
              isSecondary: true,
              onPressed: () {
                actions.markAsRead(n.id);
                if (n.taskId != null && n.taskId!.isNotEmpty) {
                  final scope = ProfileNavigationScope.maybeOf(context);
                  if (scope != null) {
                    scope.onTaskSelected?.call(n.taskId!);
                  } else {
                    context.go('/task-detail/${n.taskId}');
                  }
                }
              },
            ),
          ],
        );
      } else if (n.type == 'friend_request') {
        quickActions = Row(
          children: [
            _QuickActionButton(
              label: 'Accept',
              onPressed: () {
                actions.markAsRead(n.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Friend request accepted!')),
                );
              },
            ),
            const SizedBox(width: 8),
            _QuickActionButton(
              label: 'Dismiss',
              isSecondary: true,
              onPressed: () {
                actions.deleteNotification(n.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Friend request dismissed.')),
                );
              },
            ),
          ],
        );
      } else if (n.type == 'reminder') {
        quickActions = Row(
          children: [
            _QuickActionButton(
              label: 'Snooze',
              onPressed: () {
                actions.markAsRead(n.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Snoozed for 1 hour.')),
                );
              },
            ),
            if (n.taskId != null && n.taskId!.isNotEmpty) ...[
              const SizedBox(width: 8),
              _QuickActionButton(
                label: 'Open Task',
                isSecondary: true,
                onPressed: () {
                  actions.markAsRead(n.id);
                  final scope = ProfileNavigationScope.maybeOf(context);
                  if (scope != null) {
                    scope.onTaskSelected?.call(n.taskId!);
                  } else {
                    context.go('/task-detail/${n.taskId}');
                  }
                },
              ),
            ],
          ],
        );
      } else if (n.type == 'xp_earned' || n.type == 'level_up') {
        quickActions = Row(
          children: [
            _QuickActionButton(
              label: 'View Progress',
              onPressed: () {
                actions.markAsRead(n.id);
                final scope = ProfileNavigationScope.maybeOf(context);
                if (scope != null) {
                  scope.onProfileSelected();
                } else {
                  context.go('/profile');
                }
              },
            ),
          ],
        );
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (!n.read) {
            actions.markAsRead(n.id);
          }
          if (widget.onTap != null) {
            widget.onTap!();
          }
          final scope = ProfileNavigationScope.maybeOf(context);
          if (scope != null) {
            if (n.taskId != null && n.taskId!.isNotEmpty) {
              scope.onTaskSelected?.call(n.taskId!);
            } else if (n.type == 'xp_earned' || n.type == 'level_up') {
              scope.onProfileSelected();
            }
          } else {
            if (n.taskId != null && n.taskId!.isNotEmpty) {
              context.go('/task-detail/${n.taskId}');
            } else if (n.type == 'xp_earned' || n.type == 'level_up') {
              context.go('/profile');
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: activeBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          transform: _isHovered
              ? (Matrix4.translationValues(0.0, -1.0, 0.0) * Matrix4.diagonal3Values(1.01, 1.01, 1.0))
              : Matrix4.identity(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon or Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: n.type == 'friend_request' ? null : _getGradient(),
                  color: n.type == 'friend_request' ? DashboardColors.surfaceHigh : null,
                ),
                child: Center(
                  child: Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Body Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              color: DashboardColors.onSurface,
                              fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(n.createdAt),
                          style: TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                    if (n.xpAmount != null || n.level != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (n.type == 'level_up' 
                                  ? const Color(0xFF7C3AED) 
                                  : const Color(0xFFF59E0B))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          n.type == 'level_up' ? 'Level ${n.level}' : '+${n.xpAmount} XP',
                          style: TextStyle(
                            color: n.type == 'level_up' 
                                ? const Color(0xFFA78BFA) 
                                : const Color(0xFFFBBF24),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (quickActions != null) ...[
                      const SizedBox(height: 8),
                      quickActions,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Status Indicator Dot (Facebook style blue dot)
              Align(
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: n.read ? Colors.transparent : const Color(0xFF1877F2), // Facebook Blue
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

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = widget.isSecondary 
        ? Colors.white.withValues(alpha: 0.08) 
        : const Color(0xFF1877F2); // Facebook blue for primary action
    final hover = widget.isSecondary 
        ? Colors.white.withValues(alpha: 0.15) 
        : const Color(0xFF1565C0);
    
    final textColor = widget.isSecondary 
        ? DashboardColors.onSurface 
        : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _isHovered ? hover : primary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSecondary 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : Colors.transparent,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
