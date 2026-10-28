import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/firebase_auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/bootstrap_auth_use_case.dart';
import '../../domain/usecases/google_sign_in_use_case.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/register_use_case.dart';
import '../../domain/usecases/update_profile_use_case.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthLocalDataSource>()) {
      Get.lazyPut<AuthLocalDataSource>(
        () => AuthLocalDataSource(Get.find()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AuthRemoteDataSource>()) {
      Get.lazyPut<AuthRemoteDataSource>(
        () => FirebaseAuthRemoteDataSource(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AuthRepository>()) {
      Get.lazyPut<AuthRepository>(
        () => AuthRepositoryImpl(
          remoteDataSource: Get.find<AuthRemoteDataSource>(),
          localDataSource: Get.find<AuthLocalDataSource>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<BootstrapAuthUseCase>()) {
      Get.lazyPut(
        () => BootstrapAuthUseCase(Get.find<AuthRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => LoginUseCase(Get.find<AuthRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => RegisterUseCase(Get.find<AuthRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => UpdateProfileUseCase(Get.find<AuthRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => LogoutUseCase(Get.find<AuthRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => GoogleSignInUseCase(Get.find<AuthRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AuthController>()) {
      Get.put(
        AuthController(
          bootstrapAuthUseCase: Get.find<BootstrapAuthUseCase>(),
          loginUseCase: Get.find<LoginUseCase>(),
          registerUseCase: Get.find<RegisterUseCase>(),
          updateProfileUseCase: Get.find<UpdateProfileUseCase>(),
          logoutUseCase: Get.find<LogoutUseCase>(),
          googleSignInUseCase: Get.find<GoogleSignInUseCase>(),
        ),
        permanent: true,
      );
    }
  }
}
