import 'package:to_do_app/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:to_do_app/features/auth/domain/entities/app_user.dart';
import 'package:to_do_app/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AppUser?> authStateChanges() {
    return _remoteDataSource.authStateChanges().map((user) => user?.toEntity());
  }

  @override
  AppUser? currentUser() => _remoteDataSource.currentUser()?.toEntity();

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    return (await _remoteDataSource.signIn(
      email: email,
      password: password,
    )).toEntity();
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    return (await _remoteDataSource.signUp(
      email: email,
      password: password,
      fullName: fullName,
      username: username,
    )).toEntity();
  }

  @override
  Future<void> signOut() => _remoteDataSource.signOut();
}
