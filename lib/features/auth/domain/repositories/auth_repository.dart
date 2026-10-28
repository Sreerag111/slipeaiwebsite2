import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getSessionUser();

  Future<AppUser> login({
    required String email,
    required String password,
  });

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUser> updateProfile(AppUser user);

  Future<void> logout();

  Future<AppUser> signInWithGoogle();
}

