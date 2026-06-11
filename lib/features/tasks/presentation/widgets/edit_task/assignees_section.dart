import 'package:flutter/material.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/collaborator_assign_dialog.dart';

class TaskAssigneesSection extends StatelessWidget {
  const TaskAssigneesSection({
    required this.assigneeIds,
    required this.allUsers,
    required this.onAddAssignee,
    required this.onRemoveAssignee,
    required this.isMobile,
    super.key,
  });

  final List<String> assigneeIds;
  final List<UserProfileModel> allUsers;
  final ValueChanged<String> onAddAssignee;
  final ValueChanged<String> onRemoveAssignee;
  final bool isMobile;

  String _getInitials(UserProfileModel user) {
    final name = (user.fullName?.trim().isNotEmpty == true)
        ? user.fullName!
        : (user.username?.trim().isNotEmpty == true)
            ? user.username!
            : user.email;
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getUserColor(String userId) {
    final colors = [
      DashboardColors.primary,
      DashboardColors.secondary,
      DashboardColors.tertiary,
      Colors.greenAccent,
      Colors.orangeAccent,
    ];
    final index = userId.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final assignedUsers = allUsers.where((u) => assigneeIds.contains(u.id)).toList();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ASSIGNEES',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${assigneeIds.length} Assigned',
                style: const TextStyle(
                  color: DashboardColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Row of avatars + add button
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                ...assignedUsers.map((user) {
                  final color = _getUserColor(user.id);
                  final initials = _getInitials(user);
                  final hasImage = user.avatarUrl?.isNotEmpty == true;

                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Tooltip(
                          message: user.fullName ?? user.email,
                          child: GestureDetector(
                            onTap: () => onRemoveAssignee(user.id),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: color.withValues(alpha: 0.15),
                              backgroundImage: hasImage ? NetworkImage(user.avatarUrl!) : null,
                              child: hasImage
                                  ? null
                                  : Text(
                                      initials,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        // Online indicator (for simulation)
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: DashboardColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: DashboardColors.surfaceLow, width: 2),
                            ),
                          ),
                        ),
                        // Mini remove badge
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 8, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                // Add Assignee Button
                GestureDetector(
                  onTap: () => _openCollaboratorAssignDialog(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08), style: BorderStyle.solid),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: DashboardColors.onSurfaceVariant, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCollaboratorAssignDialog(BuildContext context) {
    final collaborators = allUsers.map((m) {
      final name = (m.fullName?.trim().isNotEmpty == true)
          ? m.fullName!
          : (m.username?.trim().isNotEmpty == true)
              ? m.username!
              : m.email;
      final initials = _getInitials(m);
      final color = _getUserColor(m.id);
      return CollaboratorItem(
        id: m.id,
        name: name,
        avatarUrl: m.avatarUrl,
        initials: initials,
        color: color,
        isOnline: true,
      );
    }).toList();

    final initialSelectedIds = assigneeIds.toSet();

    CollaboratorAssignDialog.show(
      context,
      collaborators: collaborators,
      initialSelectedIds: initialSelectedIds,
      onChanged: (item, isSelected) async {
        if (isSelected) {
          onAddAssignee(item.id);
        } else {
          onRemoveAssignee(item.id);
        }
      },
    );
  }
}
