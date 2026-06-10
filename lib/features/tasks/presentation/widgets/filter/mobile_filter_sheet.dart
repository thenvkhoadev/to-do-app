import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_categories_grid.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_date_range_mobile.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_priority_tabs.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_status_chips.dart';

class MobileFilterSheet extends StatefulWidget {
  const MobileFilterSheet({
    required this.initialState,
    required this.onApply,
    super.key,
  });

  final FilterState initialState;
  final ValueChanged<FilterState> onApply;

  static Future<FilterState?> show(
    BuildContext context, {
    required FilterState initialState,
  }) {
    return showModalBottomSheet<FilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder:
          (sheetContext) => MobileFilterSheet(
            initialState: initialState,
            onApply: (state) => Navigator.pop(sheetContext, state),
          ),
    );
  }

  @override
  State<MobileFilterSheet> createState() => _MobileFilterSheetState();
}

class _MobileFilterSheetState extends State<MobileFilterSheet> {
  late FilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return DraggableScrollableSheet(
      initialChildSize: .92,
      maxChildSize: .95,
      minChildSize: .50,
      builder:
          (_, scrollController) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xBF121315),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(
                    top: BorderSide(color: Color(0x26FFFFFF)),
                    left: BorderSide(color: Color(0x14FFFFFF)),
                    right: BorderSide(color: Color(0x14FFFFFF)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 40,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF46464F),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Row(
                        children: [
                          const Text(
                            'Filter Tasks',
                            style: TextStyle(
                              color: Color(0xFFE1DFFF),
                              fontSize: 24,
                              height: 1.3,
                              letterSpacing: -.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Material(
                            color: Colors.white.withValues(alpha: .03),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .08),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFFC7C5D0),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: .08),
                      height: 24,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            const SizedBox(height: 32),
                            FilterPriorityTabs(
                              selected: _state.selectedPriorities,
                              onChanged:
                                  (v) => setState(
                                    () =>
                                        _state = _state.copyWith(
                                          selectedPriorities: v,
                                        ),
                                  ),
                            ),
                            const SizedBox(height: 32),
                            FilterCategoriesGrid(
                              selected: _state.selectedCategoryIds,
                              onChanged:
                                  (v) => setState(
                                    () =>
                                        _state = _state.copyWith(
                                          selectedCategoryIds: v,
                                        ),
                                  ),
                            ),
                            const SizedBox(height: 32),
                            FilterDateRangeMobile(
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
                            SizedBox(height: mq.viewInsets.bottom + 16),
                          ],
                        ),
                      ),
                    ),
                    _Footer(
                      onApply: () => widget.onApply(_state),
                      onReset: () => setState(() => _state = _state.reset()),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onApply, required this.onReset});
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      24,
      16,
      24,
      MediaQuery.of(context).padding.bottom + 16,
    ),
    decoration: const BoxDecoration(
      color: Color(0x800D0E0F),
      border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFE1DFFF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x4DC0C1FF), blurRadius: 20),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onApply,
              child: const SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(
                        color: Color(0xFF131449),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onReset,
          child: const Text(
            'Reset All',
            style: TextStyle(
              color: Color(0xFFC7C5D0),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
