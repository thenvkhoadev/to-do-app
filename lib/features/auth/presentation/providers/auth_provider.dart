import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:to_do_app/features/auth/data/repository/auth_repository_impl.dart';
import 'package:to_do_app/features/auth/domain/entities/app_user.dart';
import 'package:to_do_app/features/auth/domain/repository/auth_repository.dart';
import 'package:to_do_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:to_do_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:to_do_app/features/auth/domain/usecases/sign_up_usecase.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(authServiceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
      return AuthController(
        repository: ref.watch(authRepositoryProvider),
        signInUseCase: SignInUseCase(ref.watch(authRepositoryProvider)),
        signUpUseCase: SignUpUseCase(ref.watch(authRepositoryProvider)),
        signOutUseCase: SignOutUseCase(ref.watch(authRepositoryProvider)),
      );
    });

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController({
    required AuthRepository repository,
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
  }) : _repository = repository,
       _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       _signOutUseCase = signOutUseCase,
       super(AsyncValue.data(repository.currentUser())) {
    _authSub = _repository.authStateChanges().listen((user) {
      if (!mounted) return;
      state = AsyncValue.data(user);
    });
  }

  final AuthRepository _repository;
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  late final StreamSubscription<AppUser?> _authSub;

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _signInUseCase(email: email, password: password),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _signUpUseCase(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
      ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _signOutUseCase();
    state = AsyncValue.data(_repository.currentUser());
  }
}
