import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/core/router/auth_refresh_listenable.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/ai/presentation/screens/ai_screen.dart';
import 'package:to_do_app/features/auth/presentation/screens/login_screen.dart';
import 'package:to_do_app/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:to_do_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:to_do_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:to_do_app/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:to_do_app/features/home/presentation/screens/app_shell.dart';
import 'package:to_do_app/features/home/presentation/screens/home_dashboard_screen.dart';
import 'package:to_do_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:to_do_app/features/tasks/presentation/screens/tasks_screen.dart';

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
      final publicRoutes = {'/splash', '/onboarding', '/login', '/signup'};

      if (location == '/splash') return signedIn ? '/home' : '/onboarding';
      if (!signedIn && !publicRoutes.contains(location)) return '/login';
      if (signedIn && (location == '/login' || location == '/signup' || location == '/onboarding')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeDashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/tasks', builder: (context, state) => const TasksScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/ai', builder: (context, state) => const AiScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});
