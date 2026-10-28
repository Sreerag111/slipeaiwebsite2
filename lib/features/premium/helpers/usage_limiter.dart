import 'package:get/get.dart';
import '../presentation/controllers/premium_controller.dart';

class UsageLimiter {
  static PremiumController get _controller => Get.find<PremiumController>();

  static bool canSendChat() {
    return _controller.canSendChat();
  }

  static bool canGenerateImage() {
    return _controller.canGenerateImage();
  }

  static bool canGenerateMeme() {
    return _controller.canGenerateMeme();
  }

  static bool isPremium() {
    return _controller.isPremium.value;
  }

  static int getRemainingChats() {
    if (_controller.isPremium.value) return 999999;
    return (10 - _controller.chatCount.value).clamp(0, 10);
  }

  static int getRemainingImages() {
    if (_controller.isPremium.value) return 999999;
    return (1 - _controller.imageGenerationCount.value).clamp(0, 1);
  }

  static int getRemainingMemes() {
    if (_controller.isPremium.value) return 999999;
    return (1 - _controller.memeCount.value).clamp(0, 1);
  }
}
