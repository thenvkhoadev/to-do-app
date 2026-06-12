import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';

class TaskHeaderSection extends ConsumerWidget {
  const TaskHeaderSection({
    required this.item,
    required this.onBack,
    required this.title,
    required this.status,
    required this.categoryId,
    required this.tagIds,
    required this.assigneeIds,
    this.aiGenerated = false,
    super.key,
  });

  final TaskBoardItem item;
  final VoidCallback onBack;
  final String title;
  final String status;
  final String? categoryId;
  final List<String> tagIds;
  final List<String> assigneeIds;
  final bool aiGenerated;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(userCategoriesProvider).valueOrNull ?? [];
    final tags = ref.watch(userTagsProvider).valueOrNull ?? [];
    final allUsers = ref.watch(allUsersProvider).valueOrNull ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        if (isDesktop) {
          return _DesktopHeader(
            item: item,
            onBack: onBack,
            formatDate: _formatDate,
            timeAgo: _timeAgo,
            title: title,
            status: status,
            categoryId: categoryId,
            tagIds: tagIds,
            assigneeIds: assigneeIds,
            categories: categories,
            tags: tags,
            allUsers: allUsers,
          );
        }

        return _MobileTabletHeader(
          item: item,
          onBack: onBack,
          formatDate: _formatDate,
          timeAgo: _timeAgo,
          title: title,
          status: status,
          categoryId: categoryId,
          tagIds: tagIds,
          assigneeIds: assigneeIds,
          categories: categories,
          tags: tags,
          allUsers: allUsers,
          isTablet: constraints.maxWidth >= 600,
        );
      },
    );
  }
}

// ── DESKTOP SINGLE ROW HEADER ────────────────────────────────────────────────

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.item,
    required this.onBack,
    required this.formatDate,
    required this.timeAgo,
    required this.title,
    required this.status,
    required this.categoryId,
    required this.tagIds,
    required this.assigneeIds,
    required this.categories,
    required this.tags,
    required this.allUsers,
  });

  final TaskBoardItem item;
  final VoidCallback onBack;
  final String Function(DateTime?) formatDate;
  final String Function(DateTime?) timeAgo;
  final String title;
  final String status;
  final String? categoryId;
  final List<String> tagIds;
  final List<String> assigneeIds;
  final List<CategoryModel> categories;
  final List<TagModel> tags;
  final List<UserProfileModel> allUsers;

  @override
  Widget build(BuildContext context) {
    final backButton = SizedBox(
      width: 48,
      child: _HoverBackButton(onTap: onBack),
    );

    final titleWidget = Expanded(
      flex: 3,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );

    final createdWidget = Expanded(
      flex: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: Colors.white60,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              formatDate(item.createdAt),
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final updatedWidget = Expanded(
      flex: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 14,
            color: Colors.white60,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Updated ${timeAgo(item.updatedAt)}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final pct = (item.progress * 100).round();
    final progressWidget = Expanded(
      flex: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$pct%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: item.progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: DashboardColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final statusWidget = _buildStatusBadge();

    final category =
        categoryId == null
            ? null
            : categories.firstWhere(
              (c) => c.id == categoryId,
              orElse: () => const CategoryModel(id: '', userId: '', name: ''),
            );
    final showCategory = category != null && category.name.isNotEmpty;

    final taskTags = tags.where((t) => tagIds.contains(t.id)).toList();
    final showTags = taskTags.isNotEmpty;

    final assignedUsers =
        allUsers.where((u) => assigneeIds.contains(u.id)).toList();
    final showAssignees = assignedUsers.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xF20F172A), Color(0xF2020617)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              backButton,
              const SizedBox(width: 20),
              titleWidget,
              const SizedBox(width: 20),
              createdWidget,
              const SizedBox(width: 20),
              updatedWidget,
              const SizedBox(width: 20),
              progressWidget,
              const SizedBox(width: 24),
              statusWidget,
              if (showCategory) ...[
                const SizedBox(width: 16),
                _buildCategoriesList(category),
              ],
              if (showTags) ...[
                const SizedBox(width: 16),
                _buildTagsList(taskTags),
              ],
              if (showAssignees) ...[
                const SizedBox(width: 16),
                _buildAssigneeAvatars(assignedUsers),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final (color, label) = switch (status) {
      'draft' => (const Color(0xFF8B5CF6), 'DRAFT'),
      'todo' => (const Color(0xFF3B82F6), 'TO DO'),
      'in_progress' => (const Color(0xFFF59E0B), 'IN PROGRESS'),
      'done' || 'completed' => (const Color(0xFF22C55E), 'COMPLETED'),
      _ => (const Color(0xFF3B82F6), 'TO DO'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCategoriesList(CategoryModel category) {
    return _ChipWidget(text: category.name, type: _ChipType.category);
  }

  Widget _buildTagsList(List<TagModel> taskTags) {
    final visibleTags = taskTags.take(2).toList();
    final extraCount = taskTags.length - 2;

    return Wrap(
      spacing: 6,
      children: [
        for (final tag in visibleTags)
          _ChipWidget(text: tag.name, type: _ChipType.tag),
        if (extraCount > 0)
          _ChipWidget(
            text: '+$extraCount',
            type: _ChipType.tag,
            isNumber: true,
          ),
      ],
    );
  }

  Widget _buildAssigneeAvatars(List<UserProfileModel> assignedUsers) {
    const double avatarSize = 28.0;
    const double overlap = 8.0;

    final visibleUsers = assignedUsers.take(4).toList();
    final hasMore = assignedUsers.length > 4;
    final extraCount = assignedUsers.length - 4;

    return SizedBox(
      height: avatarSize,
      width:
          (visibleUsers.length * (avatarSize - overlap)) +
          overlap +
          (hasMore ? avatarSize - overlap : 0),
      child: Stack(
        children: [
          for (int i = 0; i < visibleUsers.length; i++)
            Positioned(
              left: i * (avatarSize - overlap),
              child: Tooltip(
                message: visibleUsers[i].fullName ?? visibleUsers[i].email,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0F172A),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Builder(
                      builder: (context) {
                        final user = visibleUsers[i];
                        String initials = '?';
                        final name = user.fullName ?? '';
                        if (name.isNotEmpty) {
                          final parts = name.split(' ');
                          initials =
                              parts.length >= 2
                                  ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                                  : parts[0][0].toUpperCase();
                        } else if (user.email.isNotEmpty) {
                          initials = user.email[0].toUpperCase();
                        }

                        final colors = [
                          DashboardColors.primary,
                          DashboardColors.secondary,
                          DashboardColors.tertiary,
                          Colors.greenAccent,
                          Colors.orangeAccent,
                        ];
                        final color =
                            colors[user.id.hashCode.abs() % colors.length];
                        final hasImage = user.avatarUrl?.isNotEmpty == true;

                        return CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          backgroundImage:
                              hasImage ? NetworkImage(user.avatarUrl!) : null,
                          child:
                              hasImage
                                  ? null
                                  : Text(
                                    initials,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          if (hasMore)
            Positioned(
              left: visibleUsers.length * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F172A),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$extraCount',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── TABLET / MOBILE RESPONSIVE CARD ──────────────────────────────────────────

class _MobileTabletHeader extends StatelessWidget {
  const _MobileTabletHeader({
    required this.item,
    required this.onBack,
    required this.formatDate,
    required this.timeAgo,
    required this.title,
    required this.status,
    required this.categoryId,
    required this.tagIds,
    required this.assigneeIds,
    required this.categories,
    required this.tags,
    required this.allUsers,
    required this.isTablet,
  });

  final TaskBoardItem item;
  final VoidCallback onBack;
  final String Function(DateTime?) formatDate;
  final String Function(DateTime?) timeAgo;
  final String title;
  final String status;
  final String? categoryId;
  final List<String> tagIds;
  final List<String> assigneeIds;
  final List<CategoryModel> categories;
  final List<TagModel> tags;
  final List<UserProfileModel> allUsers;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final pct = (item.progress * 100).round();

    final statusWidget = _buildStatusBadge();
    final backButton = _HoverBackButton(onTap: onBack);

    final titleWidget = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );

    final dateChips = Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 12,
              color: Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              formatDate(item.createdAt),
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 12,
              color: Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              'Updated ${timeAgo(item.updatedAt)}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ],
    );

    final progressWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$pct%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 80,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: item.progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: DashboardColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );

    Widget? categoriesWidget;
    if (categoryId != null) {
      final category = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => const CategoryModel(id: '', userId: '', name: ''),
      );
      if (category.name.isNotEmpty) {
        categoriesWidget = _ChipWidget(
          text: category.name,
          type: _ChipType.category,
        );
      }
    }

    final taskTags = tags.where((t) => tagIds.contains(t.id)).toList();
    Widget? tagsWidget;
    if (taskTags.isNotEmpty) {
      final visibleTags = taskTags.take(2).toList();
      final extraTags = taskTags.length - 2;
      tagsWidget = Wrap(
        spacing: 6,
        children: [
          for (final tag in visibleTags)
            _ChipWidget(text: tag.name, type: _ChipType.tag),
          if (extraTags > 0)
            _ChipWidget(
              text: '+$extraTags',
              type: _ChipType.tag,
              isNumber: true,
            ),
        ],
      );
    }

    final assignedUsers =
        allUsers.where((u) => assigneeIds.contains(u.id)).toList();
    Widget? assigneesWidget;
    if (assignedUsers.isNotEmpty) {
      const double avatarSize = 24.0;
      const double overlap = 6.0;
      final visibleUsers = assignedUsers.take(4).toList();
      final hasMoreAvatars = assignedUsers.length > 4;
      final extraAvatars = assignedUsers.length - 4;

      assigneesWidget = SizedBox(
        height: avatarSize,
        width:
            (visibleUsers.length * (avatarSize - overlap)) +
            overlap +
            (hasMoreAvatars ? avatarSize - overlap : 0),
        child: Stack(
          children: [
            for (int i = 0; i < visibleUsers.length; i++)
              Positioned(
                left: i * (avatarSize - overlap),
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0F172A),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Builder(
                      builder: (context) {
                        final user = visibleUsers[i];
                        String initials = '?';
                        final name = user.fullName ?? '';
                        if (name.isNotEmpty) {
                          final parts = name.split(' ');
                          initials =
                              parts.length >= 2
                                  ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                                  : parts[0][0].toUpperCase();
                        } else if (user.email.isNotEmpty) {
                          initials = user.email[0].toUpperCase();
                        }

                        final colors = [
                          DashboardColors.primary,
                          DashboardColors.secondary,
                          DashboardColors.tertiary,
                          Colors.greenAccent,
                          Colors.orangeAccent,
                        ];
                        final color =
                            colors[user.id.hashCode.abs() % colors.length];
                        final hasImage = user.avatarUrl?.isNotEmpty == true;

                        return CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          backgroundImage:
                              hasImage ? NetworkImage(user.avatarUrl!) : null,
                          child:
                              hasImage
                                  ? null
                                  : Text(
                                    initials,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            if (hasMoreAvatars)
              Positioned(
                left: visibleUsers.length * (avatarSize - overlap),
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0F172A),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '+$extraAvatars',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xF20F172A), Color(0xF2020617)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  backButton,
                  const SizedBox(width: 12),
                  Expanded(child: titleWidget),
                  const SizedBox(width: 12),
                  statusWidget,
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [dateChips, progressWidget],
              ),
              if (categoriesWidget != null ||
                  tagsWidget != null ||
                  assigneesWidget != null) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (categoriesWidget != null) categoriesWidget,
                    if (tagsWidget != null) tagsWidget,
                    if (assigneesWidget != null) assigneesWidget,
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final (color, label) = switch (status) {
      'draft' => (const Color(0xFF8B5CF6), 'DRAFT'),
      'todo' => (const Color(0xFF3B82F6), 'TO DO'),
      'in_progress' => (const Color(0xFFF59E0B), 'IN PROGRESS'),
      'done' || 'completed' => (const Color(0xFF22C55E), 'COMPLETED'),
      _ => (const Color(0xFF3B82F6), 'TO DO'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── SUBCOMPONENTS ────────────────────────────────────────────────────────────

enum _ChipType { category, tag }

class _ChipWidget extends StatefulWidget {
  const _ChipWidget({
    required this.text,
    required this.type,
    this.isNumber = false,
  });
  final String text;
  final _ChipType type;
  final bool isNumber;

  @override
  State<_ChipWidget> createState() => _ChipWidgetState();
}

class _ChipWidgetState extends State<_ChipWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isTag = widget.type == _ChipType.tag;
    final color = isTag ? DashboardColors.secondary : DashboardColors.primary;

    return MouseRegion(
      onEnter:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = true);
          }),
      onExit:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = false);
          }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              _isHovered
                  ? color.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                _isHovered
                    ? color.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            color:
                widget.isNumber ? color : (_isHovered ? color : Colors.white70),
            fontSize: 11,
            fontWeight: widget.isNumber ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _HoverBackButton extends StatefulWidget {
  const _HoverBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = true);
          }),
      onExit:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = false);
          }),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _isHovered ? 0.08 : 0.04),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Center(
            child: Icon(Icons.arrow_back, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
