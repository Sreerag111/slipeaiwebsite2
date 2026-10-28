import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plagiarism_checker/theme/app_text_styles.dart';
import '../../../../theme/app_theme.dart';

class ComparisonTable extends StatelessWidget {
  const ComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('AI Chats', '10 total', 'Unlimited'),
      ('Image Generation', '1 total', 'Unlimited'),
      ('AI Photo Enhancer', 'Preview only', 'Unlimited saves'),
      ('AI Video Enhancer', 'Preview only', 'Unlimited saves'),
      ('Photo/File Upload', '3 files limit', 'Unlimited'),
      ('Companion Mode', 'Locked', 'Unlocked'),
      ('Live Screen', 'Locked', 'Unlocked'),
      ('Meme Creation', 'Coming soon', 'Coming soon'),
      ('Profile Lookup', 'Locked', 'Unlocked'),
      ('AI Text Selection Lookup', 'Locked', 'Unlocked'),
      ('AI Connectors', 'Locked', 'Unlocked'),
      ('AI Keyboard', 'Locked', 'Unlocked'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Feature',
                    style: AppTextStyles.microLabel.copyWith(
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Free',
                    style: AppTextStyles.microLabel.copyWith(
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Premium',
                    style: AppTextStyles.microLabel.copyWith(
                      color: AppTheme.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.white.withValues(alpha: 0.04),
              height: 1,
            ),
            itemBuilder: (_, index) {
              final row = rows[index];
              final isPremiumValue = row.$2 == 'Locked';
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Feature Name
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.$1,
                        style: AppTextStyles.labelMedium,
                      ),
                    ),
                    // Free Value
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          if (isPremiumValue)
                            const Icon(Icons.lock_outline_rounded,
                                size: 13, color: AppTheme.danger)
                          else
                            const Icon(Icons.check_rounded,
                                size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              row.$2,
                              style: AppTextStyles.captionMuted.copyWith(
                                color: isPremiumValue
                                    ? AppTheme.danger
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Premium Value
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 14, color: AppTheme.success),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              row.$3,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
