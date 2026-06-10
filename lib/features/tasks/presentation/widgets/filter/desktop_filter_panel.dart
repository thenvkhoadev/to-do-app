import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_action_footer.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_categories_list.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_date_range_desktop.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_priority_grid.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_status_chips.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DesktopFilterPanel extends StatefulWidget {
  const DesktopFilterPanel({
    required this.initialState,
    required this.onApply,
    required this.onClose,
    super.key,
  });

  final FilterState initialState;
  final ValueChanged<FilterState> onApply;
  final VoidCallback onClose;

  @override
  State<DesktopFilterPanel> createState() => _DesktopFilterPanelState();
}

class _DesktopFilterPanelState extends State<DesktopFilterPanel>
    with SingleTickerProviderStateMixin {
  late FilterState _state;
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              width: 400,
              decoration: const BoxDecoration(
                color: Color(0xB30D0E0F),
                border: Border(left: BorderSide(color: Color(0x14FFFFFF))),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 50,
                    offset: Offset(-10, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _Header(onClose: _dismiss),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          FilterStatusChips(
                            selected: _state.selectedStatuses,
                            onChanged:
                                (v) => setState(
                                  () =>
                                      _state = _state.copyWith(
                                        selectedStatuses: v,
                                      ),
                                ),
                          ),
                          const SizedBox(height: 40),
                          FilterPriorityGrid(
                            selected: _state.selectedPriorities,
                            onChanged:
                                (v) => setState(
                                  () =>
                                      _state = _state.copyWith(
                                        selectedPriorities: v,
                                      ),
                                ),
                          ),
                          const SizedBox(height: 40),
                          FilterCategoriesList(
                            selected: _state.selectedCategoryIds,
                            onChanged:
                                (v) => setState(
                                  () =>
                                      _state = _state.copyWith(
                                        selectedCategoryIds: v,
                                      ),
                                ),
                          ),
                          const SizedBox(height: 40),
                          FilterDateRangeDesktop(
                            preset: _state.datePreset,
                            startDate: _state.startDate,
                            endDate: _state.endDate,
                            onPresetChanged:
                                (preset) => setState(
                                  () =>
                                      _state = _state.copyWith(
                                        datePreset: preset,
                                      ),
                                ),
                            onRangeChanged:
                                (start, end) => setState(
                                  () =>
                                      _state = _state.copyWith(
                                        startDate: start,
                                        endDate: end,
                                        datePreset: DateRangePreset.custom,
                                      ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FilterActionFooter(
                    onReset: () => setState(() => _state = _state.reset()),
                    onApply: () => widget.onApply(_state),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
    child: Row(
      children: [
        const Icon(
          Icons.filter_list_rounded,
          color: Color(0xFFE1DFFF),
          size: 24,
        ),
        const SizedBox(width: 12),
        const Text(
          'Filter Tasks',
          style: TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 24,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onClose,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.close_rounded,
                color: Color(0xFFC7C5D0),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
