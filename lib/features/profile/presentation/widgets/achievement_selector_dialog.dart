import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/features/achievements/domain/achievement.dart';
import 'package:to_do_app/features/achievements/widgets/badge_widget.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

Future<Achievement?> showAchievementSelectorDialog({
  required BuildContext context,
  required List<Achievement> achievements,
  required String? selectedAchievementId,
}) {
  return showDialog<Achievement>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    builder: (_) => AchievementSelectorDialog(
      achievements: achievements,
      selectedAchievementId: selectedAchievementId,
    ),
  );
}

Future<List<Achievement>?> showAchievementMultiSelectorDialog({
  required BuildContext context,
  required List<Achievement> achievements,
  required List<String> selectedAchievementIds,
}) {
  return showDialog<List<Achievement>>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    builder: (_) => AchievementSelectorDialog.multi(
      achievements: achievements,
      selectedAchievementIds: selectedAchievementIds,
    ),
  );
}

class AchievementSelectorDialog extends StatefulWidget {
  const AchievementSelectorDialog({
    required this.achievements,
    required this.selectedAchievementId,
    super.key,
  })  : selectedAchievementIds = const [],
        multiSelect = false;

  const AchievementSelectorDialog.multi({
    required this.achievements,
    required this.selectedAchievementIds,
    super.key,
  })  : selectedAchievementId = null,
        multiSelect = true;

  final List<Achievement> achievements;
  final String? selectedAchievementId;
  final List<String> selectedAchievementIds;
  final bool multiSelect;

  @override
  State<AchievementSelectorDialog> createState() => _AchievementSelectorDialogState();
}

enum _AchievementSelectorTab { all, unlocked, rare, legendary }

class _AchievementSelectorDialogState extends State<AchievementSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  _AchievementSelectorTab _tab = _AchievementSelectorTab.all;
  final Set<String> _selectedIds = {};
  final Set<String> _initialSelectedIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.multiSelect) {
      _selectedIds.addAll(
        widget.selectedAchievementIds.where((id) => _achievementById(id)?.isUnlocked == true),
      );
    } else {
      final selected = _achievementById(widget.selectedAchievementId);
      final selectedId = selected?.isUnlocked == true
          ? selected!.id
          : _firstUnlockedAchievementId();
      if (selectedId != null) _selectedIds.add(selectedId);
    }
    _initialSelectedIds.addAll(_selectedIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Achievement? _achievementById(String? id) {
    if (id == null) return null;
    for (final achievement in widget.achievements) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }

  String? _firstUnlockedAchievementId() {
    for (final achievement in widget.achievements) {
      if (achievement.isUnlocked) return achievement.id;
    }
    return null;
  }

  Achievement? get _selectedAchievement => _selectedIds.isEmpty ? null : _achievementById(_selectedIds.first);

  List<Achievement> get _selectedAchievements {
    final selected = <Achievement>[];
    for (final achievement in widget.achievements) {
      if (_selectedIds.contains(achievement.id) && achievement.isUnlocked) {
        selected.add(achievement);
      }
    }
    return selected;
  }

  bool get _selectionChanged {
    return _selectedIds.length != _initialSelectedIds.length ||
        !_selectedIds.containsAll(_initialSelectedIds);
  }

  String get _actionLabel {
    if (widget.multiSelect) {
      return _selectedIds.length > _initialSelectedIds.length
          ? 'Add Achievement'
          : 'Update Achievement';
    }
    return 'Replace Achievement';
  }

  bool get _canApply {
    if (!_selectionChanged) return false;
    if (widget.multiSelect) return true;
    return _selectedAchievement?.isUnlocked == true;
  }

  List<Achievement> get _filteredAchievements {
    final query = _searchController.text.trim().toLowerCase();
    return widget.achievements.where((achievement) {
      final matchesTab = switch (_tab) {
        _AchievementSelectorTab.all => true,
        _AchievementSelectorTab.unlocked => achievement.isUnlocked,
        _AchievementSelectorTab.rare => _isRare(achievement.rarity),
        _AchievementSelectorTab.legendary => _isLegendary(achievement.rarity),
      };
      if (!matchesTab) return false;
      if (query.isEmpty) return true;
      return achievement.name.toLowerCase().contains(query) ||
          achievement.category.toLowerCase().contains(query) ||
          achievement.rarity.label.toLowerCase().contains(query) ||
          achievement.description.toLowerCase().contains(query);
    }).toList();
  }

  bool _isRare(AchievementRarity rarity) {
    return {
      AchievementRarity.gold,
      AchievementRarity.diamond,
      AchievementRarity.elite,
      AchievementRarity.master,
    }.contains(rarity);
  }

  bool _isLegendary(AchievementRarity rarity) {
    return {
      AchievementRarity.challenger,
      AchievementRarity.grandmaster,
      AchievementRarity.supreme,
      AchievementRarity.legend,
      AchievementRarity.immortal,
      AchievementRarity.mythic,
    }.contains(rarity);
  }

  void _apply() {
    if (widget.multiSelect) {
      Navigator.of(context).pop(_selectedAchievements);
      return;
    }

    final selected = _selectedAchievement;
    if (selected == null || !selected.isUnlocked) return;
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 640;
    final selected = _selectedAchievement;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 24 : 32,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.95 + value * 0.05,
              child: child,
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              width: isMobile ? size.width * 0.9 : 720,
              constraints: BoxConstraints(
                maxHeight: isMobile ? size.height * 0.8 : 600,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF121423).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 80,
                    offset: const Offset(0, 30),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _DialogHeader(
                    title: widget.multiSelect ? 'Select Achievements' : 'Select Achievement',
                    subtitle: widget.multiSelect
                        ? 'Choose unlocked achievements to show on your profile'
                        : 'Choose an unlocked achievement to showcase',
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Column(
                      children: [
                        _SearchField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        _FilterTabs(
                          selected: _tab,
                          onSelected: (tab) => setState(() => _tab = tab),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildGrid(),
                    ),
                  ),
                  _DialogActions(
                    label: _actionLabel,
                    canApply: _canApply,
                    onCancel: () => Navigator.of(context).pop(),
                    onApply: _apply,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final achievements = _filteredAchievements;
    if (achievements.isEmpty) {
      return const Center(
        child: Text(
          'No achievements found.',
          style: TextStyle(color: DashboardColors.onSurfaceVariant),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 4 : constraints.maxWidth >= 360 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return _AchievementSelectorCard(
              achievement: achievement,
              selected: _selectedIds.contains(achievement.id),
              onTap: achievement.isUnlocked
                  ? () => setState(() {
                        if (widget.multiSelect) {
                          if (_selectedIds.contains(achievement.id)) {
                            _selectedIds.remove(achievement.id);
                          } else {
                            _selectedIds.add(achievement.id);
                          }
                        } else {
                          _selectedIds
                            ..clear()
                            ..add(achievement.id);
                        }
                      })
                  : null,
            );
          },
        );
      },
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA78BFA).withValues(alpha: 0.28),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Close',
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              color: DashboardColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: DashboardColors.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search achievements',
          hintStyle: const TextStyle(color: DashboardColors.onSurfaceVariant),
          prefixIcon: const Icon(Icons.search_rounded, color: DashboardColors.onSurfaceVariant, size: 20),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFC084FC)),
          ),
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelected});

  final _AchievementSelectorTab selected;
  final ValueChanged<_AchievementSelectorTab> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (_AchievementSelectorTab.all, 'All'),
      (_AchievementSelectorTab.unlocked, 'Unlocked'),
      (_AchievementSelectorTab.rare, 'Rare'),
      (_AchievementSelectorTab.legendary, 'Legendary'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs) ...[
            _FilterChipButton(
              label: tab.$2,
              active: selected == tab.$1,
              onTap: () => onSelected(tab.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)])
              : null,
          color: active ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? const Color(0xFFC084FC).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : DashboardColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AchievementSelectorCard extends StatelessWidget {
  const _AchievementSelectorCard({
    required this.achievement,
    required this.selected,
    required this.onTap,
  });

  final Achievement achievement;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = achievement.rarity.color;
    final selectable = onTap != null;

    return MouseRegion(
      cursor: selectable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: achievement.isUnlocked ? 0.05 : 0.025),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFFC084FC)
                  : Colors.white.withValues(alpha: 0.1),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? color.withValues(alpha: 0.28)
                    : Colors.black.withValues(alpha: 0.16),
                blurRadius: selected ? 24 : 12,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: achievement.isUnlocked ? 1 : 0.4,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    BadgeWidget(
                      rarity: achievement.rarity,
                      icon: achievement.icon,
                      svgName: achievement.svgName,
                      size: 44,
                      isLocked: !achievement.isUnlocked,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      achievement.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      achievement.isUnlocked ? achievement.rarity.label : 'Locked',
                      style: TextStyle(
                        color: achievement.isUnlocked ? color : DashboardColors.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    ],
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  ),
                ),
              if (!achievement.isUnlocked)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, color: Colors.white70, size: 13),
                          SizedBox(width: 5),
                          Text(
                            'Locked',
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
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

class _AchievementPreview extends StatelessWidget {
  const _AchievementPreview({required this.achievement, this.compact = false});

  final Achievement? achievement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final achievement = this.achievement;
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: achievement == null
          ? const Center(
              child: Text(
                'Select an unlocked achievement',
                textAlign: TextAlign.center,
                style: TextStyle(color: DashboardColors.onSurfaceVariant),
              ),
            )
          : TweenAnimationBuilder<double>(
              key: ValueKey(achievement.id),
              tween: Tween(begin: 0.8, end: 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Column(
                mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Selected Preview',
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 18),
                  BadgeWidget(
                    rarity: achievement.rarity,
                    icon: achievement.icon,
                    svgName: achievement.svgName,
                    size: compact ? 64 : 80,
                    isLocked: !achievement.isUnlocked,
                  ),
                  SizedBox(height: compact ? 10 : 18),
                  Text(
                    achievement.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${achievement.rarity.label} · ${achievement.category}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: achievement.rarity.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 12),
                    Text(
                      achievement.description,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    if (achievement.unlockedAt != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Unlocked ${DateFormat('d MMM yyyy').format(achievement.unlockedAt!)}',
                        style: const TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}

class _MultiAchievementPreview extends StatelessWidget {
  const _MultiAchievementPreview({required this.achievements, this.compact = false});

  final List<Achievement> achievements;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Text(
            '${achievements.length} Selected',
            style: const TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Premium Achievements',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          SizedBox(
            height: compact ? 72 : 170,
            child: achievements.isEmpty
                ? const Center(
                    child: Text(
                      'No achievements selected',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: DashboardColors.onSurfaceVariant),
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final achievement in achievements)
                          Tooltip(
                            message: achievement.name,
                            child: BadgeWidget(
                              rarity: achievement.rarity,
                              icon: achievement.icon,
                              svgName: achievement.svgName,
                              size: compact ? 34 : 40,
                              isLocked: false,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.label,
    required this.canApply,
    required this.onCancel,
    required this.onApply,
  });

  final String label;
  final bool canApply;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(color: DashboardColors.onSurfaceVariant),
            ),
          ),
          if (canApply) ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: onApply,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.28),
                      blurRadius: 22,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
