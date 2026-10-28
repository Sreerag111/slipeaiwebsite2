import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/theme_controller.dart';

class ActionCards extends StatelessWidget {
  const ActionCards({
    super.key,
    required this.onFocusMode,
    required this.onCreateImage,
    required this.onComingSoon,
    required this.onCompanionMode,
    required this.onPhotoEnhance,
    required this.onVideoEnhance,
  });

  final VoidCallback onFocusMode;
  final VoidCallback onCreateImage;
  final VoidCallback onComingSoon;
  final VoidCallback onCompanionMode;
  final VoidCallback onPhotoEnhance;
  final VoidCallback onVideoEnhance;

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'AI Photo Enhancer',
        'icon': Icons.auto_fix_high_rounded,
        'onTap': onPhotoEnhance,
      },
      {
        'title': 'AI Video Enhancer',
        'icon': Icons.movie_filter_outlined,
        'onTap': onVideoEnhance,
      },
      {
        'title': 'Create Images',
        'iconAsset': 'assets/icons/image.png',
        'onTap': onCreateImage,
      },
      {
        'title': 'Companion Mode',
        'iconAsset': 'assets/icons/companion_mode.png',
        'onTap': onCompanionMode,
      },
      {
        'title': 'Create Memes',
        'icon': Icons.sentiment_satisfied_alt_rounded,
        'onTap': onComingSoon,
      },
      {
        'title': 'Focus Mode',
        'iconAsset': 'assets/icons/focus_mode.png',
        'onTap': onFocusMode,
      },
    ];

    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final cardBg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
      final cardBorder =
          isDark ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1);
      final iconColor = isDark ? Colors.grey : Colors.black;
      final textColor = isDark ? AppTheme.textSecondary : Colors.black;

      return SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
          physics: const BouncingScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(
            width: 8,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final iconAsset = item['iconAsset'] as String?;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: item['onTap'] as VoidCallback,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: cardBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (iconAsset != null)
                        Image.asset(
                          iconAsset,
                          width: 24,
                          height: 24,
                          color: iconColor,
                          colorBlendMode: BlendMode.srcIn,
                        )
                      else
                        Icon(
                          item['icon'] as IconData,
                          color: iconColor,
                          size: 24,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        item['title'] as String,
                        style: AppTextStyles.microNumber.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
