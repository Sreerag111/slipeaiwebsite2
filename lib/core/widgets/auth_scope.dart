import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';

class AuthScope extends StatelessWidget {
  const AuthScope({
    super.key,
    required this.child,
  });

  final Widget child;

  static AuthController of(BuildContext context) => Get.find<AuthController>();

  @override
  Widget build(BuildContext context) => child;
}
