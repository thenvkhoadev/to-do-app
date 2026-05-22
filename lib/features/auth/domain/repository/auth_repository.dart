import 'package:to_do_app/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? currentUser();
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  });
  Future<void> signOut();
}
