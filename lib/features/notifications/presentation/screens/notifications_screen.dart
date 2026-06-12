import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/features/notifications/presentation/widgets/notification_list_view.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({this.embeddedInDashboard = false, super.key});

  final bool embeddedInDashboard;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    if (embeddedInDashboard) {
      return Column(
        children: [
          const DesktopTopbar(),
          Expanded(
            child: Center(
              child: Container(
                width: isMobile ? double.infinity : 600,
                height: size.height * 0.82,
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xff0F172A).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                  child: NotificationListView(
                    isFullScreen: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff090D16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Notification Center',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: isMobile,
      ),
      body: Center(
        child: Container(
          width: isMobile ? double.infinity : 600,
          height: isMobile ? double.infinity : size.height * 0.82,
          margin: isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 24),
          decoration: isMobile
              ? null
              : BoxDecoration(
                  color: const Color(0xff0F172A).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
          child: const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(28)),
            child: NotificationListView(
              isFullScreen: true,
            ),
          ),
        ),
      ),
    );
  }
}
