import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/core/router/auth_refresh_listenable.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/ai/presentation/screens/ai_screen.dart';
import 'package:to_do_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:to_do_app/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:to_do_app/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:to_do_app/screens/analytics/analytics_screen.dart';
import 'package:to_do_app/screens/dashboard/dashboard_screen.dart';
import 'package:to_do_app/screens/settings/settings_screen.dart';
import 'package:to_do_app/screens/support/support_screen.dart';
import 'package:to_do_app/screens/home.dart';
import 'package:to_do_app/screens/sign_in_page.dart';
import 'package:to_do_app/screens/sign_up_page.dart';
import 'package:to_do_app/screens/task_details/task_detail_from_id_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final refreshListenable = AuthRefreshListenable(client);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final signedIn = client.auth.currentSession != null;
      final location = state.matchedLocation;
      final publicRoutes = {'/splash', '/', '/login', '/signup'};

      if (location == '/splash') return signedIn ? '/home' : '/';
      if (!signedIn && !publicRoutes.contains(location)) return '/login';
      if (signedIn &&
          (location == '/' || location == '/login' || location == '/signup')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/', builder: (_, __) => const Home()),
      GoRoute(path: '/login', builder: (_, __) => const SignInPage()),
      GoRoute(path: '/signup', builder: (_, __) => const SignUpPage()),
      GoRoute(path: '/home', builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: '/tasks',
        builder:
            (_, state) => TasksScreen(
              openNewTask: state.uri.queryParameters['newTask'] == '1',
              searchQuery: state.uri.queryParameters['search'],
            ),
      ),
      GoRoute(path: '/ai', builder: (_, __) => const AiScreen()),
      GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const DashboardScreen(initialIndex: 7),
      ),
      GoRoute(
        path: '/task-detail/:id',
        builder:
            (_, state) =>
                TaskDetailFromIdScreen(taskId: state.pathParameters['id']!),
      ),
    ],
  );
});
