import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/glass_container.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskSearchField extends StatelessWidget {
  const TaskSearchField({this.desktop = false, super.key});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 999,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 16 : 14, vertical: 0),
      opacity: desktop ? .035 : .025,
      child: SizedBox(
        height: desktop ? 44 : 54,
        width: desktop ? 390 : double.infinity,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 14,
                ),
                cursorColor: DashboardColors.primary,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: DashboardColors.onSurfaceVariant,
                    size: 20,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: desktop ? 34 : 32,
                    minHeight: desktop ? 44 : 54,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText:
                      desktop
                          ? 'Search tasks, docs, or intelligence...'
                          : 'Search tasks or ask AI...',
                  hintStyle: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                onSubmitted: (value) {
                  final query = value.trim();
                  if (query.isEmpty) return;
                  context.go('/tasks?search=${Uri.encodeComponent(query)}');
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: .06)),
              ),
              child: Text(
                desktop ? '/' : '⌘ K',
                style: const TextStyle(
                  color: DashboardColors.outline,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
