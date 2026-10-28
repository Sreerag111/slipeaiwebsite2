import 'package:flutter/material.dart';
import 'package:plagiarism_checker/theme/app_theme.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class EnhancementLoadingIndicator extends StatelessWidget {
  const EnhancementLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : const Color(0xFF141820);
    return Container(
      color: (dark ? Colors.black : Colors.white).withValues(alpha: 0.86),
      child: Center(
        child: LoadingAnimationWidget.flickr(
          leftDotColor: foreground,
          rightDotColor: AppTheme.accent,
          size: 54,
        ),
      ),
    );
  }
}
