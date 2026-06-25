import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';
import 'package:to_do_app/widgets/dashboard/mobile_dashboard_widgets.dart';
import 'package:to_do_app/screens/task_details/task_detail_from_id_screen.dart';
import 'package:to_do_app/features/social/presentation/providers/social_providers.dart';
import 'package:to_do_app/features/social/presentation/widgets/photo_viewer_overlay.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.initialIndex = 0, this.taskId});

  final int initialIndex;
  final String? taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoViewer = ref.watch(photoViewerStateProvider);

    return Theme(
      data: DashboardTheme.dark(),
      child: DashboardScaffold(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= DashboardBreakpoints.desktop;

            return Stack(
              children: [
                Positioned.fill(
                  child: isDesktop
                      ? DesktopDashboardLayout(
                          initialIndex: initialIndex,
                          taskId: taskId,
                        )
                      : (taskId != null
                          ? TaskDetailFromIdScreen(taskId: taskId!)
                          : MobileDashboardLayout(initialIndex: initialIndex)),
                ),
                if (photoViewer != null)
                  Positioned(
                    left: isDesktop ? DashboardSpacing.sidebar : 0,
                    top: isDesktop ? 66 : 66 + MediaQuery.paddingOf(context).top,
                    right: 0,
                    bottom: 0,
                    child: PhotoViewerOverlay(
                      key: ValueKey(photoViewer.postId),
                      postId: photoViewer.postId,
                      initialIndex: photoViewer.initialIndex,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

