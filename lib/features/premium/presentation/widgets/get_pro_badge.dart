import 'package:flutter/material.dart';

import '../../../../theme/app_text_styles.dart';
import '../pages/premium_screen.dart';

class GetProBadge extends StatelessWidget {
  const GetProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: () => PremiumScreen.open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (dark ? Colors.white : Colors.black)
                  .withValues(alpha: dark ? 0.12 : 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: (dark ? Colors.white : Colors.black)
                  .withValues(alpha: dark ? 0.05 : 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, color: foreground, size: 16),
            const SizedBox(width: 6),
            Text('Upgrade',
                style: AppTextStyles.labelMedium.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }
}
