import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class CollaboratorItem {
  final String id;
  final String name;
  final String? avatarUrl;
  final String initials;
  final Color color;
  final bool isOnline;

  const CollaboratorItem({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.initials,
    required this.color,
    required this.isOnline,
  });
}

typedef CollaboratorOnChanged = Future<void> Function(CollaboratorItem item, bool isSelected);

class CollaboratorAssignDialog extends StatefulWidget {
  final String title;
  final List<CollaboratorItem> collaborators;
  final Set<String> initialSelectedIds;
  final CollaboratorOnChanged onChanged;
  final VoidCallback? onDone;

  const CollaboratorAssignDialog({
    this.title = 'Assign Collaborators',
    required this.collaborators,
    required this.initialSelectedIds,
    required this.onChanged,
    this.onDone,
    super.key,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Assign Collaborators',
    required List<CollaboratorItem> collaborators,
    required Set<String> initialSelectedIds,
    required CollaboratorOnChanged onChanged,
    VoidCallback? onDone,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => CollaboratorAssignDialog(
        title: title,
        collaborators: collaborators,
        initialSelectedIds: initialSelectedIds,
        onChanged: onChanged,
        onDone: onDone,
      ),
    );
  }

  @override
  State<CollaboratorAssignDialog> createState() => _CollaboratorAssignDialogState();
}

class _CollaboratorAssignDialogState extends State<CollaboratorAssignDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnimation;
  final Set<String> _selectedIds = {};
  final Set<String> _loadingIds = {};
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleCollaborator(CollaboratorItem item) async {
    if (_loadingIds.contains(item.id)) return;

    final isSelected = _selectedIds.contains(item.id);
    final targetVal = !isSelected;

    setState(() {
      _loadingIds.add(item.id);
    });

    try {
      await widget.onChanged(item, targetVal);
      if (mounted) {
        setState(() {
          if (targetVal) {
            _selectedIds.add(item.id);
          } else {
            _selectedIds.remove(item.id);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật collaborator: $e'),
            backgroundColor: DashboardColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingIds.remove(item.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCollaborators = widget.collaborators.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: 360,
                constraints: const BoxConstraints(maxHeight: 520),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0F1D).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.65),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: DashboardColors.primary.withValues(alpha: 0.1),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header section
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DashboardColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.group_add_rounded,
                              color: DashboardColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: GoogleFonts.interTight(
                                    color: DashboardColors.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Đã chọn ${_selectedIds.length}/${widget.collaborators.length}',
                                  style: TextStyle(
                                    color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: const TextStyle(
                            color: DashboardColors.onSurface,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm thành viên...',
                            hintStyle: TextStyle(
                              color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.5),
                              size: 18,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchCtrl.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.5),
                                      size: 16,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),

                    const Divider(color: Colors.white10, height: 1),

                    // Collaborator list
                    Flexible(
                      child: filteredCollaborators.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'Không tìm thấy thành viên nào'
                                    : 'Không có thành viên nào',
                                style: const TextStyle(
                                  color: DashboardColors.onSurfaceVariant,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: filteredCollaborators.length,
                              itemBuilder: (context, index) {
                                final item = filteredCollaborators[index];
                                final isSelected = _selectedIds.contains(item.id);
                                final isLoading = _loadingIds.contains(item.id);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: InkWell(
                                    onTap: () => _toggleCollaborator(item),
                                    borderRadius: BorderRadius.circular(16),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? DashboardColors.primary.withValues(alpha: 0.08)
                                            : Colors.white.withValues(alpha: 0.02),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? DashboardColors.primary.withValues(alpha: 0.4)
                                              : Colors.white.withValues(alpha: 0.05),
                                          width: 1.2,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: DashboardColors.primary.withValues(alpha: 0.08),
                                                  blurRadius: 10,
                                                  spreadRadius: 1,
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          // Avatar with pulsing glow when selected
                                          Stack(
                                            children: [
                                              AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? item.color
                                                        : Colors.transparent,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor: item.color.withValues(alpha: 0.18),
                                                  backgroundImage: (item.avatarUrl != null && item.avatarUrl!.isNotEmpty)
                                                      ? NetworkImage(item.avatarUrl!)
                                                      : null,
                                                  child: (item.avatarUrl != null && item.avatarUrl!.isNotEmpty)
                                                      ? null
                                                      : Text(
                                                          item.initials,
                                                          style: TextStyle(
                                                            color: item.color,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w900,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              if (item.isOnline)
                                                const Positioned(
                                                  bottom: 1,
                                                  right: 1,
                                                  child: _PulseGreenDot(),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          // Name and status text
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: GoogleFonts.inter(
                                                    color: isSelected ? Colors.white : DashboardColors.onSurface,
                                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  item.isOnline ? 'Đang hoạt động' : 'Ngoại tuyến',
                                                  style: TextStyle(
                                                    color: item.isOnline
                                                        ? const Color(0xFF10B981)
                                                        : DashboardColors.onSurfaceVariant.withValues(alpha: 0.5),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Checkbox or loading spinner
                                          if (isLoading)
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(DashboardColors.primary),
                                              ),
                                            )
                                          else
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? DashboardColors.primary
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? DashboardColors.primary
                                                      : Colors.white30,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      size: 14,
                                                      color: Colors.black,
                                                    )
                                                  : null,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    const Divider(color: Colors.white10, height: 1),

                    // Actions block
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DashboardColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: DashboardColors.primary.withValues(alpha: 0.35),
                          ),
                          onPressed: () {
                            if (widget.onDone != null) {
                              widget.onDone!();
                            }
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Hoàn thành',
                            style: GoogleFonts.interTight(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseGreenDot extends StatefulWidget {
  const _PulseGreenDot();

  @override
  State<_PulseGreenDot> createState() => _PulseGreenDotState();
}

class _PulseGreenDotState extends State<_PulseGreenDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.35).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _scale,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: 0.45),
            ),
          ),
        ),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}
