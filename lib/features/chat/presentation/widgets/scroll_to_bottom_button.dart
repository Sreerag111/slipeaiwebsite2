import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/theme_controller.dart';

class ScrollToBottomButton extends StatelessWidget {
  const ScrollToBottomButton(
      {super.key, required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return Positioned(
        bottom: 16,
        right: 16,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1F1F1F)
                  : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.12 : 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.05 : 0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 22,
            ),
          ),
        ),
      );
    });
  }
}
