import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/haptics/app_haptics.dart';
import '../../theme/theme_controller.dart';
import 'app_review_service.dart';

/// Opens the client-specified rating bottom sheet.
Future<void> showAppReviewBottomSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => const AppReviewBottomSheet(),
    );

/// Alias so existing trigger callers continue to work seamlessly.
Future<void> showAppReviewDialog(BuildContext context) =>
    showAppReviewBottomSheet(context);

enum _ReviewStep {
  initialQuestion,
  greatRating,
  needsImprovement,
}

class AppReviewBottomSheet extends StatefulWidget {
  const AppReviewBottomSheet({super.key});

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.paceai.paceai';
  static const String _marketUri = 'market://details?id=com.paceai.paceai';
  static const String _supportEmail = 'paceai.support@gmail.com';

  @override
  State<AppReviewBottomSheet> createState() => _AppReviewBottomSheetState();
}

class _AppReviewBottomSheetState extends State<AppReviewBottomSheet> {
  _ReviewStep _currentStep = _ReviewStep.initialQuestion;

  Future<void> _launchPlayStore() async {
    Navigator.of(context, rootNavigator: true).pop();
    await AppReviewService.instance.markAsReviewed();

    try {
      if (Platform.isAndroid) {
        final market = Uri.parse(AppReviewBottomSheet._marketUri);
        if (await canLaunchUrl(market)) {
          await launchUrl(market, mode: LaunchMode.externalApplication);
          return;
        }
      }
      final web = Uri.parse(AppReviewBottomSheet._playStoreUrl);
      if (await canLaunchUrl(web)) {
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[AppReviewBottomSheet] Could not launch store review: $e');
    }
  }

  Future<void> _sendFeedback() async {
    Navigator.of(context, rootNavigator: true).pop();
    try {
      final emailUri = Uri(
        scheme: 'mailto',
        path: AppReviewBottomSheet._supportEmail,
        queryParameters: {
          'subject': 'Slipe AI App Feedback',
        },
      );
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      debugPrint('[AppReviewBottomSheet] Could not open email feedback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      final safeBottom = MediaQuery.of(context).padding.bottom;

      // Color scheme based on client specifications:
      // In light mode: BG white, Primary button black, Secondary button light grey.
      // In dark mode: BG dark, Primary button white, Secondary button dark grey.
      final sheetBg = isDark ? const Color(0xFF18181B) : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black;
      final closeIconColor = isDark ? Colors.white38 : Colors.black38;

      final primaryBtnBg = isDark ? Colors.white : Colors.black;
      final primaryBtnText = isDark ? Colors.black : Colors.white;

      final secondaryBtnBg =
          isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5);
      final secondaryBtnText =
          isDark ? const Color(0xFFE4E4E7) : const Color(0xFF18181B);

      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, safeBottom > 0 ? safeBottom + 12 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip: 'Close',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        AppHaptics.tap();
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: closeIconColor,
                      ),
                    ),
                  ),

                  // Top Pink Heart Icon
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 20),
                    child: Image.asset(
                      'assets/icons/rating_heart.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Animated Content depending on the step
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _buildCurrentStep(
                      step: _currentStep,
                      textColor: textColor,
                      primaryBtnBg: primaryBtnBg,
                      primaryBtnText: primaryBtnText,
                      secondaryBtnBg: secondaryBtnBg,
                      secondaryBtnText: secondaryBtnText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCurrentStep({
    required _ReviewStep step,
    required Color textColor,
    required Color primaryBtnBg,
    required Color primaryBtnText,
    required Color secondaryBtnBg,
    required Color secondaryBtnText,
  }) {
    switch (step) {
      case _ReviewStep.initialQuestion:
        return Column(
          key: const ValueKey('step_question'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How do you feel about\nSlipeAI?',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 28),

            // "Great" Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  AppHaptics.tap();
                  setState(() => _currentStep = _ReviewStep.greatRating);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBtnBg,
                  foregroundColor: primaryBtnText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'Great',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // "Needs improvement" Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  AppHaptics.tap();
                  setState(() => _currentStep = _ReviewStep.needsImprovement);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryBtnBg,
                  foregroundColor: secondaryBtnText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'Needs improvement',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );

      case _ReviewStep.greatRating:
        return Column(
          key: const ValueKey('step_great'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Thanks for using our app!\nYour rating helps us improve\nand provide new features.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),

            // Direct button to move to Play Store (no stars, per client request)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  AppHaptics.tap();
                  _launchPlayStore();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBtnBg,
                  foregroundColor: primaryBtnText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'Rate on Google Play',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Dismiss option
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  AppHaptics.tap();
                  Navigator.of(context, rootNavigator: true).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: secondaryBtnText,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  'Maybe Later',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );

      case _ReviewStep.needsImprovement:
        return Column(
          key: const ValueKey('step_needs_improvement'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We’d love to hear from you!\nTell us what we can improve.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),

            // "Send Feedback" Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  AppHaptics.tap();
                  _sendFeedback();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBtnBg,
                  foregroundColor: primaryBtnText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'Send Feedback',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Dismiss option
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  AppHaptics.tap();
                  Navigator.of(context, rootNavigator: true).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: secondaryBtnText,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
