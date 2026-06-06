import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DesktopFocusForecast extends ConsumerWidget {
  const DesktopFocusForecast({required this.item, super.key});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueDateStr = item.dueDate != null
        ? '${item.dueDate!.day.toString().padLeft(2, '0')} '
            '${_month(item.dueDate!.month)} '
            '${item.dueDate!.year}'
        : '—';
    final dueTrailing = item.dueDate != null ? _timeLeft(item.dueDate!) : null;

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

    // Fallback if the database has no assignees yet
    if (assignees.isEmpty && item.assignee.isNotEmpty) {
      assignees.add(UserProfileModel(
        id: 'fallback',
        email: '',
        fullName: item.assignee,
      ));
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
      children: [
        // Priority card
        _SideCard(
          borderColor: DashboardColors.error,
          label: 'PRIORITY',
          value: item.priorityLabel.toUpperCase(),
        ),
        const SizedBox(height: 16),
        // Due date card
        _SideCard(
          borderColor: DashboardColors.primary,
          label: 'DUE DATE',
          value: dueDateStr,
          trailing: dueTrailing,
        ),
        const SizedBox(height: 16),
        // Focus forecast card
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
                gradient: const LinearGradient(
                  colors: [Color(0x14292A2B), Color(0x141F2021)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text(
                        'FOCUS FORECAST',
                        style: TextStyle(
                          color: DashboardColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.flare_rounded,
                          color: DashboardColors.secondary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Best productivity window today:',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '14:00 – 16:00',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Based on your historical circadian rhythm and current cognitive load.',
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Assignees & Tags
        _AssigneesTagsCard(
          taskId: item.id,
          allUsers: allUsers,
          assignees: assignees,
          tags: displayTags,
          ownerId: item.userId,
          creatorName: item.creatorName,
        ),
      ],
    );
  }

  static String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  static String? _timeLeft(DateTime due) {
    final diff = due.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h Left';
    if (diff.inHours > 0) return '${diff.inHours}h Left';
    return '${diff.inMinutes}m Left';
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({
    required this.borderColor,
    required this.label,
    required this.value,
    this.trailing,
  });
  final Color borderColor;
  final String label, value;
  final String? trailing;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: .08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            color: DashboardColors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (trailing != null) ...[
                          const Spacer(),
                          Text(
                            trailing!,
                            style: const TextStyle(
                              color: DashboardColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Colored left accent bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _AssigneesTagsCard extends ConsumerWidget {
  const _AssigneesTagsCard({
    required this.taskId,
    required this.allUsers,
    required this.assignees,
    required this.tags,
    required this.ownerId,
    required this.creatorName,
  });

  final String taskId;
  final List<UserProfileModel> allUsers;
  final List<UserProfileModel> assignees;
  final List<TagModel> tags;
  final String? ownerId;
  final String? creatorName;

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

  void _showAssigneeDialog(
    BuildContext context,
    WidgetRef ref,
    String taskId,
    List<UserProfileModel> allUsers,
    List<UserProfileModel> currentAssignees,
  ) {
    final initialSelectedIds = currentAssignees.map((u) => u.id).toSet();
    final selectedIds = Set<String>.from(initialSelectedIds);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: DashboardColors.surfaceLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: DashboardColors.outlineVariant.withValues(alpha: .3),
                ),
              ),
              title: const Text(
                'Assign Collaborators',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                ),
              ),
              content: SizedBox(
                width: 320,
                child: allUsers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No workspace users found',
                          style: TextStyle(color: DashboardColors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: allUsers.length,
                        itemBuilder: (context, index) {
                          final user = allUsers[index];
                          final isSelected = selectedIds.contains(user.id);
                          final initials = _getInitials(user);
                          final userColor = _getUserColor(user.id);
                          final hasImage = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

                          return CheckboxListTile(
                            activeColor: DashboardColors.primary,
                            checkboxShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            secondary: CircleAvatar(
                              radius: 16,
                              backgroundColor: userColor.withValues(alpha: .18),
                              backgroundImage: hasImage ? NetworkImage(user.avatarUrl!) : null,
                              child: hasImage
                                  ? null
                                  : Text(
                                      initials,
                                      style: TextStyle(
                                        color: userColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                            title: Text(
                              user.fullName ?? user.username ?? user.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: DashboardColors.onSurface,
                                fontSize: 14,
                              ),
                            ),
                            value: isSelected,
                            onChanged: (val) async {
                              final supabase = ref.read(supabaseClientProvider);
                              try {
                                if (val == true) {
                                  await supabase.from('task_assignees').insert({
                                    'task_id': taskId,
                                    'user_id': user.id,
                                  });
                                  setDialogState(() {
                                    selectedIds.add(user.id);
                                  });
                                } else {
                                  await supabase
                                      .from('task_assignees')
                                      .delete()
                                      .eq('task_id', taskId)
                                      .eq('user_id', user.id);
                                  setDialogState(() {
                                    selectedIds.remove(user.id);
                                  });
                                }
                                ref.invalidate(taskAssigneeIdsProvider(taskId));
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update assignment: $e')),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: DashboardColors.onSurfaceVariant),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerUser = allUsers.firstWhere(
      (u) => u.id == ownerId,
      orElse: () => UserProfileModel(
        id: ownerId ?? '',
        email: '',
        fullName: creatorName ?? 'Owner',
      ),
    );

    final displayAssignees = assignees.where((u) => u.id != ownerUser.id).toList();
    final maxVisible = 2;
    final visibleAssignees = displayAssignees.take(maxVisible).toList();
    final hasMore = displayAssignees.length > maxVisible;
    final moreCount = displayAssignees.length - maxVisible;

    final List<({UserProfileModel user, String role})> visibleItems = [];
    visibleItems.add((user: ownerUser, role: 'Owner'));
    for (final u in visibleAssignees) {
      visibleItems.add((user: u, role: 'Assignee'));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OWNER & ASSIGNEES',
                  style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (int i = 0; i < visibleItems.length; i++)
                    Transform.translate(
                      offset: Offset(i * -8.0, 0),
                      child: Builder(builder: (context) {
                        final p = visibleItems[i];
                        final user = p.user;
                        final role = p.role;
                        final initials = _getInitials(user);
                        final color = _getUserColor(user.id);
                        final hasImage = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
                        return Tooltip(
                          message: '$role\n${user.fullName ?? user.username ?? user.email}',
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: color.withValues(alpha: .18),
                            backgroundImage: hasImage ? NetworkImage(user.avatarUrl!) : null,
                            child: hasImage
                                ? null
                                : Text(
                                    initials,
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w900),
                                  ),
                          ),
                        );
                      }),
                    ),
                  if (hasMore)
                    Transform.translate(
                      offset: Offset(visibleItems.length * -8.0, 0),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: DashboardColors.surfaceHighest,
                        child: Text('+$moreCount',
                            style: const TextStyle(
                                color: DashboardColors.onSurface,
                                fontSize: 10,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAssigneeDialog(
                      context,
                      ref,
                      taskId,
                      allUsers.where((u) => u.id != ownerUser.id).toList(),
                      assignees,
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .12),
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                        color: Colors.white.withValues(alpha: .03),
                      ),
                      child: const Icon(Icons.person_add_rounded,
                          color: DashboardColors.onSurfaceVariant, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('TAGS',
                  style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1)),
              const SizedBox(height: 12),
              if (tags.isEmpty)
                const Text(
                  'No tags assigned',
                  style: TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
                    final colors = _getTagColors(tag);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.$1,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colors.$2.withValues(alpha: .3)),
                      ),
                      child: Text(
                        tag.name.toUpperCase(),
                        style: TextStyle(
                            color: colors.$2,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
