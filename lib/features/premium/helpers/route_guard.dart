import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../presentation/controllers/premium_controller.dart';
import '../presentation/pages/premium_screen.dart';
import '../presentation/widgets/premium_dialog.dart';

class RouteGuard {
  static PremiumController get _controller => Get.find<PremiumController>();

  /// Checks if the user is premium.
  /// If yes, executes [onPassed].
  /// If no, shows the premium dialog, which redirects to the Premium Subscription Page.
  static void runGuarded(BuildContext context,
      {required VoidCallback onPassed}) {
    if (_controller.isPremium.value) {
      onPassed();
    } else {
      showPremiumDialog(context);
    }
  }

  /// Checks if premium. If yes, returns true. If no, navigates to premium screen and returns false.
  static bool checkAndRedirect(BuildContext context) {
    if (_controller.isPremium.value) {
      return true;
    } else {
      PremiumScreen.open(context);
      return false;
    }
  }
}
