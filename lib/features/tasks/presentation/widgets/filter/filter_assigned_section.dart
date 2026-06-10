import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterAssignedSection extends ConsumerStatefulWidget {
  const FilterAssignedSection({
    required this.selectedUserId,
    required this.unassignedOnly,
    required this.onUserChanged,
    required this.onUnassignedChanged,
    this.selectedAssigneeIds = const {},
    this.specialFilters = const {},
    this.onAssigneeIdsChanged,
    this.onSpecialFiltersChanged,
    super.key,
  });

  final String? selectedUserId;
  final bool unassignedOnly;
  final ValueChanged<String?> onUserChanged;
  final ValueChanged<bool> onUnassignedChanged;
  final Set<String> selectedAssigneeIds;
  final Set<AssigneeSpecialFilter> specialFilters;
  final ValueChanged<Set<String>>? onAssigneeIdsChanged;
  final ValueChanged<Set<AssigneeSpecialFilter>>? onSpecialFiltersChanged;

  @override
  ConsumerState<FilterAssignedSection> createState() =>
      _FilterAssignedSectionState();
}

class _FilterAssignedSectionState
    extends ConsumerState<FilterAssignedSection> {
  static const _initialLimit = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final users =
        ref.watch(allUsersProvider).valueOrNull ?? const <UserProfileModel>[];
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? const [];
    final currentUserId =
        ref.watch(authControllerProvider).valueOrNull?.id;

    final counts = <String, int>{};
    for (final task in tasks) {
      for (final userId in task.assigneeIds) {
        counts[userId] = (counts[userId] ?? 0) + 1;
      }
    }

    final effectiveSelected = {
      ...widget.selectedAssigneeIds,
      if (widget.selectedUserId != null) widget.selectedUserId!,
    };
    final effectiveSpecial = {
      ...widget.specialFilters,
      if (widget.unassignedOnly) AssigneeSpecialFilter.unassigned,
    };

    final visibleUsers =
        _expanded ? users : users.take(_initialLimit).toList();
    final hasMore = users.length > _initialLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentUserId != null) ...[
          _SpecialRow(
            label: 'Assigned To Me',
            count: tasks
                .where((t) => t.assigneeIds.contains(currentUserId))
                .length,
            active: effectiveSpecial
                .contains(AssigneeSpecialFilter.assignedToMe),
            onTap: () => _toggleSpecial(
                AssigneeSpecialFilter.assignedToMe, effectiveSpecial),
          ),
          _SpecialRow(
            label: 'Created By Me',
            count:
                tasks.where((t) => t.userId == currentUserId).length,
            active: effectiveSpecial
                .contains(AssigneeSpecialFilter.createdByMe),
            onTap: () => _toggleSpecial(
                AssigneeSpecialFilter.createdByMe, effectiveSpecial),
          ),
        ],
        _SpecialRow(
          label: 'Unassigned',
          count: tasks.where((t) => t.assigneeIds.isEmpty).length,
          active:
              effectiveSpecial.contains(AssigneeSpecialFilter.unassigned),
          onTap: () {
            final next =
                Set<AssigneeSpecialFilter>.from(effectiveSpecial);
            next.contains(AssigneeSpecialFilter.unassigned)
                ? next.remove(AssigneeSpecialFilter.unassigned)
                : next.add(AssigneeSpecialFilter.unassigned);
            widget.onSpecialFiltersChanged?.call(next);
            widget.onUnassignedChanged(
                next.contains(AssigneeSpecialFilter.unassigned));
          },
        ),
        if (users.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final user in visibleUsers)
            _AssigneeRow(
              user: user,
              count: counts[user.id] ?? 0,
              checked: effectiveSelected.contains(user.id),
              onTap: () {
                final next = Set<String>.from(effectiveSelected);
                next.contains(user.id)
                    ? next.remove(user.id)
                    : next.add(user.id);
                widget.onAssigneeIdsChanged?.call(next);
                widget.onUserChanged(
                    next.length == 1 ? next.first : null);
              },
            ),
          if (hasMore)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: DashboardColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _expanded
                          ? 'Show less'
                          : 'Show ${users.length - _initialLimit} more',
                      style: const TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  void _toggleSpecial(
      AssigneeSpecialFilter filter,
      Set<AssigneeSpecialFilter> current) {
    final next = Set<AssigneeSpecialFilter>.from(current);
    next.contains(filter) ? next.remove(filter) : next.add(filter);
    widget.onSpecialFiltersChanged?.call(next);
  }
}

class _SpecialRow extends StatelessWidget {
  const _SpecialRow({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? DashboardColors.secondaryContainer
                    .withValues(alpha: .12)
                : DashboardColors.surfaceLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? DashboardColors.secondary.withValues(alpha: .35)
                  : Colors.white.withValues(alpha: .08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                active
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: active
                    ? DashboardColors.secondary
                    : DashboardColors.onSurfaceVariant,
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '($count)',
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
}

class _AssigneeRow extends StatelessWidget {
  const _AssigneeRow({
    required this.user,
    required this.count,
    required this.checked,
    required this.onTap,
  });

  final UserProfileModel user;
  final int count;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = (user.fullName?.trim().isNotEmpty ?? false)
        ? user.fullName!.trim()
        : ((user.username?.trim().isNotEmpty ?? false)
            ? user.username!.trim()
            : user.email);
    final initial =
        name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: checked
              ? Colors.white.withValues(alpha: .03)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: checked
                ? Colors.white.withValues(alpha: .14)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: DashboardColors.secondaryContainer
                  .withValues(alpha: .25),
              backgroundImage: user.avatarUrl == null
                  ? null
                  : NetworkImage(user.avatarUrl!),
              child: user.avatarUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: DashboardColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '($count)',
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
