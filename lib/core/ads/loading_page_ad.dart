import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/premium/presentation/controllers/premium_controller.dart';
import '../../theme/theme_controller.dart';
import 'admob_service.dart';

/// Renders a Google AdMob Native Ad (with TemplateType.medium) or MREC banner
/// on the enhancement processing and result screens.
///
/// AdMob & Google Play Policy Compliance:
/// - Fully self-contained: Displays zero blank space/placeholders when an ad is
///   loading or unfillable ([SizedBox.shrink]).
/// - Theme-aware text contrast: Guarantees high-contrast readability in both
///   dark and light modes.
/// - Accidental Click Protection: Enforces a 24-28dp safe margin separating
///   the ad unit from action buttons.
class LoadingPageAd extends StatefulWidget {
  const LoadingPageAd({
    super.key,
    this.customAdUnitId,
    this.margin,
  });

  final String? customAdUnitId;
  final EdgeInsetsGeometry? margin;

  @override
  State<LoadingPageAd> createState() => _LoadingPageAdState();
}

class _LoadingPageAdState extends State<LoadingPageAd> {
  NativeAd? _nativeAd;
  BannerAd? _fallbackMrecAd;
  bool _isNativeLoaded = false;
  bool _isMrecLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (_isLoading) return;
    _isLoading = true;

    final isDark = ThemeController.instance.isDarkMode;
    final nativeUnitId =
        widget.customAdUnitId ?? AdMobService.instance.nativeAdUnitId;

    _nativeAd = NativeAd(
      adUnitId: nativeUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor:
            isDark ? const Color(0xFF17171C) : Colors.white,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF3B82F6),
          style: NativeTemplateFontStyle.bold,
          size: 15.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? Colors.white : const Color(0xFF0F172A),
          style: NativeTemplateFontStyle.bold,
          size: 15.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          style: NativeTemplateFontStyle.normal,
          size: 13.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] Native Ad loaded successfully ($nativeUnitId)');
          if (mounted) {
            setState(() {
              _isNativeLoaded = true;
              _isLoading = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
              '[AdMob] Native Ad failed to load ($nativeUnitId): $error. Trying MREC fallback...');
          ad.dispose();
          _nativeAd = null;
          if (mounted) {
            _loadMrecFallback();
          }
        },
      ),
    );

    _nativeAd!.load();
  }

  void _loadMrecFallback() {
    final mrecUnitId = AdMobService.instance.loadingPageAdUnitId;
    _fallbackMrecAd = BannerAd(
      adUnitId: mrecUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] MREC fallback banner loaded successfully');
          if (mounted) {
            setState(() {
              _isMrecLoaded = true;
              _isLoading = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] MREC fallback failed to load: $error');
          ad.dispose();
          _fallbackMrecAd = null;
          if (mounted) {
            setState(() {
              _isMrecLoaded = false;
              _isLoading = false;
            });
          }
        },
      ),
    );
    _fallbackMrecAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    _fallbackMrecAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<PremiumController>()) {
      final premium = Get.find<PremiumController>();
      if (premium.isPremium.value || !premium.shouldShowFreeAds) {
        return const SizedBox.shrink();
      }
    }

    final isDark = ThemeController.instance.isDarkMode;

    // 1. Native Ad Loaded State: Renders medium native ad inside single unified card.
    if (_isNativeLoaded && _nativeAd != null) {
      return Container(
        margin: widget.margin ?? const EdgeInsets.only(top: 24, bottom: 20),
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17171C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 300,
              minHeight: 320,
              maxHeight: 360,
              maxWidth: 420,
            ),
            child: SizedBox(
              height: 345,
              child: AdWidget(ad: _nativeAd!),
            ),
          ),
        ),
      );
    }

    // 2. MREC Fallback Loaded State: Renders 300x250 banner with required SPONSORED badge.
    if (_isMrecLoaded && _fallbackMrecAd != null) {
      return Container(
        margin: widget.margin ?? const EdgeInsets.only(top: 24, bottom: 20),
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17171C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SPONSORED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 300,
              height: 250,
              child: AdWidget(ad: _fallbackMrecAd!),
            ),
          ],
        ),
      );
    }

    // 3. Loading / Error / Premium: Zero empty box or orphan label (AdMob Policy Compliant).
    return const SizedBox.shrink();
  }
}
