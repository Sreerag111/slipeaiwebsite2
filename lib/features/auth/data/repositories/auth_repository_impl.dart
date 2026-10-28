import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<AppUser?> getSessionUser() async {
    final cachedUser = _localDataSource.getCachedUser();
    final token = _localDataSource.getSessionToken();
    final session = await _remoteDataSource.getSessionUser(
      token: token,
      cachedUser: cachedUser,
    );

    if (session == null) {
      await _localDataSource.clearSession();
      return null;
    }

    await _localDataSource.saveSession(
      user: session.user,
      token: session.token,
    );
    return session.user;
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final session = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    await _localDataSource.saveSession(
      user: session.user,
      token: session.token,
    );
    return session.user;
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final session = await _remoteDataSource.register(
      name: name,
      email: email,
      password: password,
    );
    await _localDataSource.saveSession(
      user: session.user,
      token: session.token,
    );
    return session.user;
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    final token = _localDataSource.getSessionToken();
    final updatedUser = await _remoteDataSource.updateProfile(
      user: AppUserModel.fromEntity(user),
      token: token,
    );
    await _localDataSource.saveSession(
      user: updatedUser,
      token: token,
    );
    return updatedUser;
  }

  @override
  Future<void> logout() async {
    final token = _localDataSource.getSessionToken();
    await _remoteDataSource.logout(token: token);
    await _localDataSource.clearSession();
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final session = await _remoteDataSource.signInWithGoogle();
    await _localDataSource.saveSession(
      user: session.user,
      token: session.token,
    );
    return session.user;
  }
}

