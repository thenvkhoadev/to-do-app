import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/core/router/auth_refresh_listenable.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/ai/presentation/screens/ai_screen.dart';
import 'package:to_do_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:to_do_app/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:to_do_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:to_do_app/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:to_do_app/screens/blank_page.dart';
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

      if (location == '/splash') return signedIn ? '/home' : '/';
      if (!signedIn && !publicRoutes.contains(location)) return '/login';
      if (signedIn && (location == '/' || location == '/login' || location == '/signup')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/', builder: (context, state) => const Home()),
      GoRoute(path: '/login', builder: (context, state) => const SignInPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
      GoRoute(path: '/home', builder: (context, state) => const BlankPage()),
      GoRoute(path: '/tasks', builder: (context, state) => const TasksScreen()),
      GoRoute(path: '/ai', builder: (context, state) => const AiScreen()),
      GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    ],
  );
});
