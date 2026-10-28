import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/premium_repository.dart';
import '../../data/repositories/premium_repository_impl.dart';
import '../controllers/premium_controller.dart';

class PremiumBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PremiumRepository>()) {
      Get.lazyPut<PremiumRepository>(
        () => PremiumRepositoryImpl(Get.find<SharedPreferences>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<PremiumController>()) {
      Get.put<PremiumController>(
        PremiumController(repository: Get.find<PremiumRepository>()),
        permanent: true,
      );
    }
  }
}
