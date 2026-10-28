import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call(AppUser user) => _repository.updateProfile(user);
}

