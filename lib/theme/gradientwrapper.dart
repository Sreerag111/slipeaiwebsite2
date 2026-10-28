import 'package:flutter/material.dart';
import 'package:plagiarism_checker/theme/app_theme.dart';

class GradientWrapper extends StatelessWidget {
  final Widget child;

  const GradientWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return SweepGradient(
          colors: [
            AppTheme.accent,
            Colors.purple,
            Colors.pink,
            Colors.orange,
            AppTheme.accent,
          ],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
