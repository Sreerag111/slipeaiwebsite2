import 'package:get/get.dart';
import 'global_error_controller.dart';

class ErrorBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GlobalErrorController>()) {
      Get.put(GlobalErrorController(), permanent: true);
    }
  }
}
