import 'package:to_do_app/features/auth/domain/entities/app_user.dart';
import 'package:to_do_app/features/auth/domain/repository/auth_repository.dart';

class SignUpUseCase {
  SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      username: username,
    );
  }
}
