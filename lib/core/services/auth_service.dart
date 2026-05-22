import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/core/storage/session_storage.dart';

class AuthService {
  AuthService(this._client, this._sessionStorage);

  final SupabaseClient _client;
  final SessionStorage _sessionStorage;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    final session = response.session;
    if (session != null) await _sessionStorage.saveSession(session);
    return response;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'username': username},
    );
    final session = response.session;
    final user = response.user;
    if (session != null) await _sessionStorage.saveSession(session);
    if (user != null) await _upsertUserProfile(user, fullName, username);
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await _sessionStorage.clearSession();
  }

  Future<void> syncSession() async {
    final session = _client.auth.currentSession;
    if (session != null) await _sessionStorage.saveSession(session);
  }

  Future<void> _upsertUserProfile(User user, String fullName, String username) {
    return _client.from('users').upsert({
      'id': user.id,
      'email': user.email,
      'username': username,
      'full_name': fullName,
      'tier': 'free',
      'role': 'user',
      'focus_score': 82,
      'streak_days': 7,
      'total_tasks': 0,
      'completed_tasks': 0,
      'focus_hours': 0,
      'deep_work_percent': 62,
      'admin_percent': 18,
      'learning_percent': 20,
      'theme_mode': 'dark',
      'notifications_enabled': true,
      'privacy_mode': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
