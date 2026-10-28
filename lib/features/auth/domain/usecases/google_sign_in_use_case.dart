import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class GoogleSignInUseCase {
  const GoogleSignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call() {
    return _repository.signInWithGoogle();
  }
}
