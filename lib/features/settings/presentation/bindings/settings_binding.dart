import 'package:get/get.dart';

import '../controllers/companion_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CompanionController>()) {
      Get.lazyPut(CompanionController.new, fenix: true);
    }
  }
}
