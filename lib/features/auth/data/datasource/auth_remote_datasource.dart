import 'package:to_do_app/core/services/auth_service.dart';
import 'package:to_do_app/features/auth/data/models/app_user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._authService);

  final AuthService _authService;

  Stream<AppUserModel?> authStateChanges() {
    return _authService.authStateChanges.map((state) {
      final user = state.session?.user;
      return user == null ? null : AppUserModel.fromSupabaseUser(user);
    });
  }

  AppUserModel? currentUser() {
    final user = _authService.currentUser;
    return user == null ? null : AppUserModel.fromSupabaseUser(user);
  }

  Future<AppUserModel> signIn({required String email, required String password}) async {
    final response = await _authService.signIn(email: email, password: password);
    final user = response.user;
    if (user == null) throw StateError('Signin completed without user.');
    return AppUserModel.fromSupabaseUser(user);
  }

  Future<AppUserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    final response = await _authService.signUp(
      email: email,
      password: password,
      fullName: fullName,
      username: username,
    );
    final user = response.user;
    if (user == null) throw StateError('Signup completed without user.');
    return AppUserModel.fromSupabaseUser(user);
  }

  Future<void> signOut() => _authService.signOut();
}
