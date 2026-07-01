import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/core/router/auth_refresh_listenable.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/core/workspace/workspace_provider.dart';
import 'package:to_do_app/features/ai/presentation/screens/ai_screen.dart';
import 'package:to_do_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:to_do_app/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:to_do_app/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:to_do_app/screens/analytics/analytics_screen.dart';
import 'package:to_do_app/screens/dashboard/dashboard_screen.dart';
import 'package:to_do_app/screens/support/support_screen.dart';
import 'package:to_do_app/screens/home.dart';
import 'package:to_do_app/screens/sign_in_page.dart';
import 'package:to_do_app/screens/sign_up_page.dart';

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

      if (!signedIn) {
        if (!publicRoutes.contains(location)) {
          return '/login';
        }
        return null;
      }

      // If signed in, handle root & auth paths redirection:
      if (location == '/splash' || location == '/' || location == '/login' || location == '/signup') {
        final currentWorkspace = ref.read(activeWorkspaceProvider);
        return currentWorkspace == Workspace.social ? '/social/feed' : '/task/home';
      }

      // Translate legacy paths to workspace-prefixed paths
      if (location == '/home') {
        final currentWorkspace = ref.read(activeWorkspaceProvider);
        return currentWorkspace == Workspace.social ? '/social/feed' : '/task/home';
      }
      if (location == '/tasks') {
        return '/task/tasks';
      }
      if (location == '/ai') {
        return '/task/ai';
      }
      if (location == '/calendar') {
        return '/task/calendar';
      }
      if (location == '/analytics') {
        return '/task/analytics';
      }
      if (location == '/settings') {
        final currentWorkspace = ref.read(activeWorkspaceProvider);
        return currentWorkspace == Workspace.social ? '/social/settings' : '/task/settings';
      }
      if (location == '/profile') {
        final currentWorkspace = ref.read(activeWorkspaceProvider);
        return currentWorkspace == Workspace.social ? '/social/profile' : '/task/profile';
      }
      if (location == '/notifications') {
        final currentWorkspace = ref.read(activeWorkspaceProvider);
        return currentWorkspace == Workspace.social ? '/social/notifications' : '/task/notifications';
      }
      if (location == '/feed') {
        return '/social/feed';
      }
      if (location == '/friends') {
        return '/social/friends';
      }
      if (location == '/messages') {
        return '/social/messages';
      }
      if (location.startsWith('/task-detail/')) {
        final id = state.pathParameters['id'];
        return '/task/task-detail/$id';
      }

      // Synchronize workspace provider based on active route
      if (location.startsWith('/social/')) {
        if (ref.read(activeWorkspaceProvider) != Workspace.social) {
          Future.microtask(() {
            ref.read(activeWorkspaceProvider.notifier).setWorkspace(Workspace.social);
          });
        }
      } else if (location.startsWith('/task/')) {
        if (ref.read(activeWorkspaceProvider) != Workspace.task) {
          Future.microtask(() {
            ref.read(activeWorkspaceProvider.notifier).setWorkspace(Workspace.task);
          });
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/',
        pageBuilder: (_, state) => _transitionPage(state, const Home()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) => _transitionPage(state, const SignInPage()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (_, state) => _transitionPage(state, const SignUpPage()),
      ),
      // Task Workspace Routes
      GoRoute(
        path: '/task/home',
        pageBuilder:
            (_, state) => _transitionPage(state, const DashboardScreen(initialIndex: 0)),
      ),
      GoRoute(
        path: '/task/tasks',
        pageBuilder:
            (_, state) => _transitionPage(
              state,
              TasksScreen(
                openNewTask: state.uri.queryParameters['newTask'] == '1',
                searchQuery: state.uri.queryParameters['search'],
              ),
            ),
      ),
      GoRoute(
        path: '/task/ai',
        pageBuilder: (_, state) => _transitionPage(state, const AiScreen()),
      ),
      GoRoute(
        path: '/task/calendar',
        pageBuilder:
            (_, state) => _transitionPage(state, const CalendarScreen()),
      ),
      GoRoute(
        path: '/task/analytics',
        pageBuilder:
            (_, state) => _transitionPage(state, const AnalyticsScreen()),
      ),
      GoRoute(
        path: '/task/archived',
        pageBuilder:
            (_, state) => _transitionPage(state, const DashboardScreen(initialIndex: 9)),
      ),
      GoRoute(
        path: '/task/settings',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 5)),
      ),
      GoRoute(
        path: '/task/support',
        pageBuilder: (context, state) {
          final isDesktop = MediaQuery.sizeOf(context).width >= 1200;
          return _transitionPage(
            state,
            isDesktop
                ? const DashboardScreen(initialIndex: 6)
                : const SupportScreen(),
          );
        },
      ),
      GoRoute(
        path: '/task/profile',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 7)),
      ),
      GoRoute(
        path: '/task/notifications',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 11)),
      ),
      GoRoute(
        path: '/task/achievements',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 10)),
      ),
      GoRoute(
        path: '/task/task-detail/:id',
        pageBuilder:
            (_, state) => _transitionPage(
              state,
              DashboardScreen(
                initialIndex: -1,
                taskId: state.pathParameters['id'],
              ),
            ),
      ),

      // Social Workspace Routes
      GoRoute(
        path: '/social/feed',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 12)),
      ),
      GoRoute(
        path: '/social/friends',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 13)),
      ),
      GoRoute(
        path: '/social/messages',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 14)),
      ),
      GoRoute(
        path: '/social/stories',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 15)),
      ),
      GoRoute(
        path: '/social/notifications',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 11)),
      ),
      GoRoute(
        path: '/social/profile',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 7)),
      ),
      GoRoute(
        path: '/social/settings',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 5)),
      ),

      // Legacy Routes (preserved to prevent GoRouter matching crashes; will redirect)
      GoRoute(
        path: '/home',
        pageBuilder:
            (_, state) => _transitionPage(state, const DashboardScreen()),
      ),
      GoRoute(
        path: '/tasks',
        pageBuilder:
            (_, state) => _transitionPage(
              state,
              TasksScreen(
                openNewTask: state.uri.queryParameters['newTask'] == '1',
                searchQuery: state.uri.queryParameters['search'],
              ),
            ),
      ),
      GoRoute(
        path: '/ai',
        pageBuilder: (_, state) => _transitionPage(state, const AiScreen()),
      ),
      GoRoute(
        path: '/calendar',
        pageBuilder:
            (_, state) => _transitionPage(state, const CalendarScreen()),
      ),
      GoRoute(
        path: '/analytics',
        pageBuilder:
            (_, state) => _transitionPage(state, const AnalyticsScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 5)),
      ),
      GoRoute(
        path: '/support',
        pageBuilder: (context, state) {
          final isDesktop = MediaQuery.sizeOf(context).width >= 1200;
          return _transitionPage(
            state,
            isDesktop
                ? const DashboardScreen(initialIndex: 6)
                : const SupportScreen(),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 7)),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 11)),
      ),
      GoRoute(
        path: '/achievements',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 10)),
      ),
      GoRoute(
        path: '/feed',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 12)),
      ),
      GoRoute(
        path: '/friends',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 13)),
      ),
      GoRoute(
        path: '/messages',
        pageBuilder:
            (_, state) =>
                _transitionPage(state, const DashboardScreen(initialIndex: 14)),
      ),
      GoRoute(
        path: '/task-detail/:id',
        pageBuilder:
            (_, state) => _transitionPage(
              state,
              DashboardScreen(
                initialIndex: -1,
                taskId: state.pathParameters['id'],
              ),
            ),
      ),
    ],
  );
});

CustomTransitionPage<void> _transitionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 210),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.018, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.992,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        ),
      );
    },
  );
}
