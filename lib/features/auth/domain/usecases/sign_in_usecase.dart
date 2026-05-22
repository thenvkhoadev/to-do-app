import 'package:to_do_app/features/auth/domain/entities/app_user.dart';
import 'package:to_do_app/features/auth/domain/repository/auth_repository.dart';

class SignInUseCase {
  SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) {
    return _repository.signIn(email: email, password: password);
  }
}
