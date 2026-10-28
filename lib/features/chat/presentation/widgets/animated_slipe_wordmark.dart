import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../theme/app_text_styles.dart';

class AnimatedSlipeWordmark extends StatelessWidget {
  const AnimatedSlipeWordmark({super.key, this.fontSize = 30});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      'Slipe AI',
      textAlign: TextAlign.center,
      style: AppTextStyles.displaySmall.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: dark ? Colors.white : Colors.black,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          delay: 1200.ms,
          duration: 3500.ms,
          color: dark ? Colors.black : Colors.white,
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .slideY(
          begin: 0,
          end: -0.04,
          duration: 3500.ms,
          curve: Curves.easeInOutSine,
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}
