import 'package:flutter/material.dart';
import 'package:plagiarism_checker/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plagiarism_checker/theme/app_text_styles.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final String title;
  final String price;
  final bool isSelected;
  final bool showBadge;
  final String badgeText;
  final VoidCallback onTap;
  final bool showDivider;

  const SubscriptionPlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.isSelected,
    this.showBadge = false,
    this.badgeText = 'Best Deal',
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Radio button circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      width: isSelected ? 6 : 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Plan Title
                Text(
                  title,
                  style: AppTextStyles.titleSmallW600.copyWith(
                    color: Colors.white,
                  ),
                ),

                // Optional Pill Badge (Best Deal)
                if (showBadge) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accent],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onAccent,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Price
                Text(
                  price,
                  style: AppTextStyles.titleSmallBold,
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.06),
              indent: 16,
              endIndent: 16,
            ),
        ],
      ),
    );
  }
}
