import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plagiarism_checker/theme/app_text_styles.dart';
import '../../../../theme/app_theme.dart';

class PremiumFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color glowColor;

  const PremiumFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.glowColor = const Color(0xFF7C3AED),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: glowColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: glowColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: glowColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Title & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.captionDesc,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
