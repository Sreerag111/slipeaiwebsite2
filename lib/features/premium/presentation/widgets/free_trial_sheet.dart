import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plagiarism_checker/theme/app_text_styles.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/premium_controller.dart';

class FreeTrialSheet extends StatefulWidget {
  final String selectedPlan; // 'monthly' or legacy ID 'max' (yearly)
  final String planPrice;

  const FreeTrialSheet({
    super.key,
    required this.selectedPlan,
    required this.planPrice,
  });

  static Future<void> show(
    BuildContext context, {
    required String selectedPlan,
    required String planPrice,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FreeTrialSheet(
        selectedPlan: selectedPlan,
        planPrice: planPrice,
      ),
    );
  }

  @override
  State<FreeTrialSheet> createState() => _FreeTrialSheetState();
}

class _FreeTrialSheetState extends State<FreeTrialSheet> {
  bool _enableAutoPay = true;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PremiumController>();
    final colors = context.colors;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: colors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.2),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Crown / Gift Icon
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: AppTheme.onAccent,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              '7-Day Free Trial',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium
                  .copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Enjoy 7 days of full premium access for ₹0 today.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmallSecondary
                  .copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Trial Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.cardElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trial Duration',
                          style: AppTextStyles.captionMuted
                              .copyWith(color: colors.textMuted),
                        ),
                        Text(
                          '7 Days Free Access',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹0',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Auto-Pay Feature Checkbox Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.cardElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _enableAutoPay ? AppTheme.accent : colors.border,
                  width: _enableAutoPay ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _enableAutoPay,
                    activeColor: AppTheme.accent,
                    checkColor: AppTheme.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _enableAutoPay = val ?? true;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable Auto-Pay Feature',
                          style: AppTextStyles.bodySmallBold.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Auto-renews at ${widget.planPrice}'
                          '${widget.selectedPlan == 'max' ? '/year' : '/month'} '
                          'after 7 days.',
                          style: AppTextStyles.captionMuted
                              .copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Disclosure text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _enableAutoPay
                    ? 'With Auto-Pay enabled, your payment plan will automatically start after 7 days unless cancelled.'
                    : 'Auto-Pay is off. Your trial will expire after 7 days without automatic renewal.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: colors.textMuted,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  controller.activateFreeTrial(
                    enableAutoPay: _enableAutoPay,
                    planId: widget.selectedPlan,
                    context: context,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Confirm & Start 7-Day Trial',
                  style: AppTextStyles.titleSmallBold
                      .copyWith(color: AppTheme.onAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
