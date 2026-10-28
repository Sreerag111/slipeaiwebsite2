import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class BootstrapAuthUseCase {
  const BootstrapAuthUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser?> call() => _repository.getSessionUser();
}

