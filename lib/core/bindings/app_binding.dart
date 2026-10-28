import 'package:get/get.dart';

import '../../theme/theme_controller.dart';
import '../config/app_config_data_source.dart';
import '../error/error_binding.dart';
import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/chat/presentation/bindings/chat_binding.dart';
import '../../features/history/presentation/bindings/history_binding.dart';
import '../../features/settings/presentation/bindings/settings_binding.dart';
import '../../features/premium/presentation/bindings/premium_binding.dart';
import '../../features/meme/presentation/bindings/meme_binding.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    ErrorBinding().dependencies();

    if (!Get.isRegistered<AppConfigDataSource>()) {
      Get.put(const AppConfigDataSource(), permanent: true);
    }

    AuthBinding().dependencies();
    ChatBinding().dependencies();
    HistoryBinding().dependencies();
    SettingsBinding().dependencies();
    PremiumBinding().dependencies();
    MemeBinding().dependencies();
    Get.put(ThemeController(), permanent: true);
  }
}
