import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/collaborator_assign_dialog.dart';

class MobileAssignees extends ConsumerWidget {
  const MobileAssignees({required this.item, super.key});
  final TaskBoardItem item;

  Color _parseTagColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) {
      return const Color(0xFF60A5FA); // default blue
    }
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF60A5FA);
    }
  }

  (Color, Color) _getTagColors(TagModel tag) {
    if (tag.color != null && tag.color!.isNotEmpty) {
      final parsed = _parseTagColor(tag.color);
      return (parsed.withValues(alpha: .12), parsed);
    }
    final lower = tag.name.toLowerCase();
    
    // Check some common tags to keep them visually distinct
    if (lower.contains('flutter') || lower.contains('dart')) {
      return (const Color(0x1A3B82F6), const Color(0xFF60A5FA)); // Blue
    }
    if (lower.contains('dashboard') || lower.contains('design') || lower.contains('ui')) {
      return (const Color(0x1AA855F7), const Color(0xFFC084FC)); // Purple
    }
    if (lower.contains('ux') || lower.contains('research') || lower.contains('accessibility')) {
      return (const Color(0x1A14B8A6), const Color(0xFF2DD4BF)); // Teal
    }
    if (lower.contains('intern') || lower.contains('ops') || lower.contains('finance')) {
      return (const Color(0x1AF97316), const Color(0xFFFB923C)); // Orange
    }
    if (lower.contains('architecture') || lower.contains('aws') || lower.contains('cloud')) {
      return (const Color(0x1AEF4444), const Color(0xFFF87171)); // Red
    }

    // Default fallback based on hashcode
    final colors = [
      (const Color(0x1A3B82F6), const Color(0xFF60A5FA)), // Blue
      (const Color(0x1AA855F7), const Color(0xFFC084FC)), // Purple
      (const Color(0x1A14B8A6), const Color(0xFF2DD4BF)), // Teal
      (const Color(0x1AF97316), const Color(0xFFFB923C)), // Orange
      (const Color(0x1AEF4444), const Color(0xFFF87171)), // Red
    ];
    final index = tag.name.hashCode.abs() % colors.length;
    return colors[index];
  }

  String _getInitials(UserProfileModel user) {
    final name = user.fullName ?? user.username ?? user.email;
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.isNotEmpty) {
      final lastWord = parts.last.trim();
      if (lastWord.isNotEmpty) {
        return lastWord[0].toUpperCase();
      }
    }
    return '?';
  }

  Color _getUserColor(String userId) {
    final colors = [
      DashboardColors.primary,
      DashboardColors.secondary,
      DashboardColors.tertiary,
      DashboardColors.outline,
    ];
    final index = userId.hashCode.abs() % colors.length;
    return colors[index];
  }

  void _showAssigneeDialog(
    BuildContext context,
    WidgetRef ref,
    String taskId,
    List<UserProfileModel> allUsers,
    List<UserProfileModel> currentAssignees,
  ) {
    final initialSelectedIds = currentAssignees.map((u) => u.id).toSet();

    final collaborators = allUsers.map((u) {
      final name = u.fullName ?? u.username ?? u.email;
      final initials = _getInitials(u);
      final color = _getUserColor(u.id);
      return CollaboratorItem(
        id: u.id,
        name: name,
        avatarUrl: u.avatarUrl,
        initials: initials,
        color: color,
        isOnline: true,
      );
    }).toList();

    CollaboratorAssignDialog.show(
      context,
      collaborators: collaborators,
      initialSelectedIds: initialSelectedIds,
      onChanged: (item, isSelected) async {
        final supabase = ref.read(supabaseClientProvider);
        if (isSelected) {
          await supabase.from('task_assignees').insert({
            'task_id': taskId,
            'user_id': item.id,
          });
        } else {
          await supabase
              .from('task_assignees')
              .delete()
              .eq('task_id', taskId)
              .eq('user_id', item.id);
        }
        ref.invalidate(taskAssigneeIdsProvider(taskId));
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allUsers = ref.watch(allUsersProvider).valueOrNull ?? [];
    final assignees = <UserProfileModel>[];

    final assigneeIdsAsync = ref.watch(taskAssigneeIdsProvider(item.id));
    assigneeIdsAsync.whenOrNull(
      data: (uids) {
        for (final uid in uids) {
          final user = allUsers.firstWhere(
            (u) => u.id == uid,
            orElse: () => UserProfileModel(id: uid, email: ''),
          );
          if (user.fullName != null || user.username != null || user.email.isNotEmpty) {
            assignees.add(user);
          }
        }
      },
    );

    // Fallback if the database has no assignees yet or is loading/offline, but the task has assignee initials
    if (assignees.isEmpty && item.assignee.isNotEmpty) {
      assignees.add(UserProfileModel(
        id: 'fallback',
        email: '',
        fullName: item.assignee,
      ));
    }

    final ownerUser = allUsers.firstWhere(
      (u) => u.id == item.userId,
      orElse: () => UserProfileModel(
        id: item.userId ?? '',
        email: '',
        fullName: item.creatorName ?? 'Owner',
      ),
    );

    final displayAssignees = assignees.where((u) => u.id != ownerUser.id).toList();
    final maxVisibleAssignees = 2;
    final visibleAssignees = displayAssignees.take(maxVisibleAssignees).toList();
    final hasMore = displayAssignees.length > maxVisibleAssignees;
    final moreCount = displayAssignees.length - maxVisibleAssignees;

    final List<({UserProfileModel user, String role})> visibleItems = [];
    visibleItems.add((user: ownerUser, role: 'Owner'));
    for (final u in visibleAssignees) {
      visibleItems.add((user: u, role: 'Assignee'));
    }

    final tagIdsAsync = ref.watch(taskTagIdsProvider(item.id));
    final allTags = ref.watch(userTagsProvider).valueOrNull ?? [];
    final taskTags = <TagModel>[];
    tagIdsAsync.whenOrNull(
      data: (tids) {
        for (final tid in tids) {
          final tag = allTags.firstWhere(
            (t) => t.id == tid,
            orElse: () => TagModel(id: '', name: '', userId: ''),
          );
          if (tag.name.isNotEmpty) {
            taskTags.add(tag);
          }
        }
      },
    );

    final List<TagModel> displayTags;
    if (taskTags.isEmpty && (tagIdsAsync.isLoading || tagIdsAsync.value == null)) {
      displayTags = item.tags.map((name) {
        final existing = allTags.firstWhere(
          (t) => t.name.toLowerCase() == name.toLowerCase(),
          orElse: () => TagModel(id: '', name: name, userId: ''),
        );
        return existing;
      }).toList();
    } else {
      displayTags = taskTags;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Owner & Assignees
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Owner & Assignees',
                  style: TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (int i = 0; i < visibleItems.length; i++)
                      Transform.translate(
                        offset: Offset(i * -10.0, 0),
                        child: Builder(builder: (context) {
                          final p = visibleItems[i];
                          final user = p.user;
                          final role = p.role;
                          final initials = _getInitials(user);
                          final color = _getUserColor(user.id);
                          final hasImage = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
                          return Tooltip(
                            message: '$role\n${user.fullName ?? user.username ?? user.email}',
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DashboardColors.surface,
                                border: Border.all(
                                  color: DashboardColors.surface,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withValues(alpha: .18),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: hasImage
                                    ? Image.network(
                                        user.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            initials,
                                            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          initials,
                                          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }),
                      ),
                    if (hasMore)
                      Transform.translate(
                        offset: Offset(visibleItems.length * -10.0, 0),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: DashboardColors.surface,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+$moreCount',
                              style: const TextStyle(
                                color: DashboardColors.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Transform.translate(
                      offset: Offset((visibleItems.length + (hasMore ? 1 : 0)) * -10.0, 0),
                      child: GestureDetector(
                        onTap: () => _showAssigneeDialog(
                          context,
                          ref,
                          item.id,
                          allUsers.where((u) => u.id != ownerUser.id).toList(),
                          assignees,
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .03),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .12),
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: DashboardColors.primary, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Estimate
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Estimate',
                  style: TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.estimate.isNotEmpty ? item.estimate : '—',
                  style: const TextStyle(
                    color: DashboardColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.01,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Tags
        if (displayTags.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No tags assigned',
              style: TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayTags.map((tag) {
              final colors = _getTagColors(tag);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.$1,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.$2.withValues(alpha: .30),
                  ),
                ),
                child: Text(
                  tag.name,
                  style: TextStyle(
                    color: colors.$2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
