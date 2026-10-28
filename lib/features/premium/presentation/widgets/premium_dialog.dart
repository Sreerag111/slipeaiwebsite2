import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plagiarism_checker/theme/app_text_styles.dart';
import '../../../../core/ads/admob_service.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/theme_controller.dart';
import '../controllers/premium_controller.dart';
import '../pages/premium_screen.dart';

Future<void> showPremiumDialog(
  BuildContext context, {
  String initialPlanId = 'monthly',
  bool offerRewardedImage = false,
  String? rewardedEnhancement,
  bool offerRewardedSave = false,
  Widget? mediaPreview,
  Future<void> Function()? onRewardedImageGranted,
}) =>
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => PremiumDialog(
        initialPlanId: initialPlanId,
        offerRewardedImage: offerRewardedImage,
        rewardedEnhancement: rewardedEnhancement,
        offerRewardedSave: offerRewardedSave,
        mediaPreview: mediaPreview,
        onRewardedImageGranted: onRewardedImageGranted,
      ),
    );

class PremiumDialog extends StatefulWidget {
  const PremiumDialog({
    this.initialPlanId = 'monthly',
    this.offerRewardedImage = false,
    this.rewardedEnhancement,
    this.offerRewardedSave = false,
    this.mediaPreview,
    this.onRewardedImageGranted,
    super.key,
  });

  final String initialPlanId;
  final bool offerRewardedImage;
  final String? rewardedEnhancement;
  final bool offerRewardedSave;
  final Widget? mediaPreview;
  final Future<void> Function()? onRewardedImageGranted;

  @override
  State<PremiumDialog> createState() => _PremiumDialogState();
}

class _PremiumDialogState extends State<PremiumDialog> {
  bool _isLoadingRewardedAd = false;
  String? _adStatusMessage;

  Future<void> _watchAdAndContinue() async {
    if (_isLoadingRewardedAd) return;
    setState(() {
      _isLoadingRewardedAd = true;
      _adStatusMessage = null;
    });
    debugPrint('[AdMob] media dialog: rewarded button tapped '
        'save=${widget.offerRewardedSave} enhancement=${widget.rewardedEnhancement}');

    try {
      final result = await AdMobService.instance.showRewardedAd();
      debugPrint('[AdMob] media dialog result: $result');
      if (!mounted) return;

      if (result == RewardedAdResult.earned) {
        final controller = Get.find<PremiumController>();
        if (widget.offerRewardedSave) {
          // A save reward is used immediately by the supplied callback. It
          // must not create an image or enhancement generation credit.
        } else if (widget.rewardedEnhancement != null) {
          await controller.claimRewardedEnhancementCredit(
            isVideo: widget.rewardedEnhancement == 'video',
          );
        } else {
          await controller.claimRewardedImageCredit();
        }
        debugPrint('[AdMob] media dialog: reward ready '
            'save=${widget.offerRewardedSave}');
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        await widget.onRewardedImageGranted?.call();
        return;
      }

      final message = result == RewardedAdResult.dismissed
          ? 'Watch the complete ad to continue.'
          : 'No ad is available right now. Tap again to retry.';

      if (mounted) {
        setState(() => _adStatusMessage = message);
        showTopSnackBar(
          context,
          message,
          rootOverlay: true,
        );
      }
    } catch (error) {
      debugPrint('[AdMob] image reward activation failed: $error');
      if (mounted) {
        const errorMsg = 'Could not load an ad. Please try again.';
        setState(() => _adStatusMessage = errorMsg);
        showTopSnackBar(
          context,
          errorMsg,
          rootOverlay: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingRewardedAd = false);
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
        final isDark = ThemeController.instance.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.black;
        final mutedColor = isDark ? Colors.white60 : Colors.black54;
        final showRewardedImage = widget.offerRewardedImage ||
            widget.rewardedEnhancement != null ||
            widget.offerRewardedSave;
        final isEnhancement = widget.rewardedEnhancement != null;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: isDark ? const Color(0xFF171717) : Colors.white,
            surfaceTintColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.mediaPreview != null)
                      Stack(
                        children: [
                          widget.mediaPreview!,
                          Positioned(
                            top: 8,
                            left: 8,
                            child: IconButton(
                              tooltip: 'Close',
                              onPressed: () =>
                                  Navigator.of(context, rootNavigator: true)
                                      .pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          tooltip: 'Close',
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.06),
                            foregroundColor: textColor,
                          ),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset('assets/logo/new_logo.png'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      widget.offerRewardedSave
                          ? 'Save your result'
                          : showRewardedImage
                              ? (isEnhancement
                                  ? 'Keep enhancing'
                                  : 'Keep creating')
                              : 'More with Slipe AI',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleLargeBold
                          .copyWith(color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.offerRewardedSave
                          ? 'Watch an ad for one save.'
                          : showRewardedImage
                              ? (isEnhancement
                                  ? 'Watch an ad to enhance your ${widget.rewardedEnhancement}.'
                                  : 'Watch an ad for one more image.')
                              : 'Unlock unlimited creativity.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        height: 1.5,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (showRewardedImage) ...[
                      if (_adStatusMessage != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.amber.withValues(alpha: 0.12)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.amber.withValues(alpha: 0.35)
                                  : Colors.orange.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: isDark
                                    ? Colors.amberAccent
                                    : Colors.orange.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _adStatusMessage!,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.amberAccent
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              _isLoadingRewardedAd ? null : _watchAdAndContinue,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: AppTheme.onAccent,
                            disabledBackgroundColor: AppTheme.accent,
                            disabledForegroundColor:
                                AppTheme.onAccent.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 16),
                            shape: const StadiumBorder(),
                            side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      _isLoadingRewardedAd
                                          ? 'Loading Ad…'
                                          : widget.offerRewardedSave
                                              ? 'Save'
                                              : (isEnhancement
                                                  ? 'Enhance'
                                                  : 'Create Image'),
                                      style: AppTextStyles.titleLargeBold
                                          .copyWith(
                                              color: AppTheme.onAccent,
                                              fontSize: 19),
                                    ),
                                    const SizedBox(height: 3),
                                    Text('Watch an Ad',
                                        style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.onAccent
                                                .withValues(alpha: 0.7))),
                                  ],
                                ),
                              ),
                              _isLoadingRewardedAd
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.onAccent))
                                  : const Icon(Icons.chevron_right_rounded,
                                      size: 26),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoadingRewardedAd
                            ? null
                            : () {
                                final navigator =
                                    Navigator.of(context, rootNavigator: true);
                                navigator.pop();
                                PremiumScreen.open(navigator.context,
                                    initialPlanId: widget.initialPlanId);
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 17),
                          shape: const StadiumBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Remove Ads & Limits',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: AppTheme.accent,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('UPGRADE',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.onAccent)),
                            ),
                          ],
                        ),
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
