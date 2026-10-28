import 'package:get/get.dart';
import '../../data/repositories/meme_repository_impl.dart';
import '../controllers/meme_controller.dart';

class MemeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MemeRepositoryImpl>()) {
      Get.lazyPut<MemeRepositoryImpl>(() => MemeRepositoryImpl());
    }
    if (!Get.isRegistered<MemeController>()) {
      Get.lazyPut<MemeController>(
        () => MemeController(repository: Get.find<MemeRepositoryImpl>()),
      );
    }
  }
}
